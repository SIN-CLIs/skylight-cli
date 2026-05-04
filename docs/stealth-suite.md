# Stealth-Triade — How `skylight-cli` Fits Into The 3-CLI Ecosystem

> **TL;DR:** This repo is one of three sibling CLIs. Each is intentionally narrow. The orchestrator (a separate "brain" repo) composes them. If you are tempted to add a feature here that overlaps with one of the others, stop and put it where it belongs.

---

## The Three CLIs

| Repo | Role | "Body part" analogy | Talks to |
|---|---|---|---|
| `playstealth-cli` | Launches/configures Chromium with anti-fingerprint patches, returns a PID | **Spine** (posture, infrastructure) | Chromium internals, OS-level browser flags |
| **`skylight-cli` (this repo)** | Captures windows, walks AX tree, posts mouse events to a PID | **Hand** (motor control) | Window Server (private SkyLight API), Accessibility API |
| `unmask-cli` | Probes detection surfaces (TLS JA3, headers, JS challenges, IP reputation), returns a risk JSON | **Eyes** (sensory check) | External services + browser via CDP |

The brain (orchestrator) wires them together. The CLIs do not call each other.

---

## Communication Model

Every CLI:
1. Is invoked as a **single-shot subprocess** (no daemons).
2. Reads arguments from `argv`.
3. Reads (optional) bytes from stdin.
4. Prints **exactly one JSON object** to stdout.
5. Exits with a **stable code** (0=ok, 2=bad-args, 3=not-found, 4=io, 5=timeout).
6. Logs human-readable diagnostics to **stderr** (not stdout).

The orchestrator is the only thing that mutates state across CLIs (e.g., passes the PID returned by `playstealth-cli` into `skylight-cli`).

```
┌──────────────────────────────────────────────────────────────────┐
│                     Orchestrator (brain)                         │
│                                                                  │
│  step 1: PID = playstealth-cli launch --profile=ghost-42         │
│  step 2: state = skylight-cli get-window-state --pid $PID        │
│  step 3: risk = unmask-cli probe --pid $PID                      │
│  step 4: if risk.score < threshold: continue, else abort         │
│  step 5: shot = skylight-cli screenshot --pid $PID --mode som    │
│  step 6: ask LLM (with shot) → returns "click index 7"           │
│  step 7: skylight-cli click --pid $PID --element-index 7         │
│  step 8: goto step 5 until task complete                         │
└──────────────────────────────────────────────────────────────────┘
```

---

## Strict Boundaries

### `playstealth-cli` owns
- Browser launch flags (`--user-data-dir`, `--disable-blink-features`, etc.)
- User-Agent / Client Hints / Accept-Language overrides
- Canvas/WebGL/Audio fingerprint mitigation
- Proxy / VPN routing
- Persistent profile storage (`--state-dir`)
- Keyboard input via CDP `Input.dispatchKeyEvent` (proper IME)

### `skylight-cli` (this repo) owns
- macOS native window enumeration
- Accessibility tree walking
- Set-of-Marks overlays / grid fallback
- Mouse event injection per-PID (private SkyLight)
- Screenshot of a single window (CGImage → PNG)

### `unmask-cli` owns
- TLS fingerprint inspection (JA3/JA4)
- Header order audit
- JS-side detector probes (Cloudflare, PerimeterX, DataDome, hCaptcha)
- IP reputation and ASN classification
- Cookie/storage inventory

### Nobody owns
- LLM calls → orchestrator
- Retry policy → orchestrator
- Survey-specific logic → orchestrator
- Cost / budget tracking → orchestrator
- Session storage / "what task am I on" → orchestrator

---

## Why Three CLIs (And Not One Mega-Tool)

**Independent failure domains.** SkyLight crashing must not take down the fingerprint mask. A bad TLS probe must not leave the browser in a half-launched state.

**Independent OS surfaces.**
- `playstealth-cli` is mostly Chromium / Node-land; cross-platform candidate.
- `skylight-cli` is macOS-only and links private frameworks.
- `unmask-cli` is mostly network-land + headless Chrome; cross-platform candidate.

Mixing them means one OS bind locks all three.

**Independent release cadence.** SkyLight needs revalidation on each macOS update. Stealth patches change weekly with Chromium. Detection probes change daily with anti-bot vendor updates. Coupling release schedules creates friction.

**Composability.** The orchestrator can call `skylight-cli` from a Slack bot use-case, or call `unmask-cli` from a security audit, without dragging in the others.

---

## Concrete Cross-CLI Workflow Example

Filling a survey:

```bash
# Brain spawns playstealth, gets PID
PID=$(playstealth-cli launch --profile=ghost-42 --proxy=$P --json | jq .pid)

# Brain checks risk before doing anything
risk=$(unmask-cli probe --pid $PID --url https://surveys.example.com)
[ "$(echo $risk | jq .score)" -lt 30 ] || exit 1

# Brain navigates (still via playstealth's CDP, NOT via skylight)
playstealth-cli navigate --pid $PID --url https://surveys.example.com/start

# Brain waits for a known DOM marker via skylight's AX walker
skylight-cli wait-for-selector --pid $PID --label "Begin survey" --timeout 30

# Brain takes SoM shot, asks LLM
shot=$(skylight-cli screenshot --pid $PID --mode som --include-tree --out /tmp/q1.png)
plan=$(llm "What should I click? Image at /tmp/q1.png. Elements: $(echo $shot | jq .elements)")

# Brain executes
skylight-cli click --pid $PID --element-index $(echo $plan | jq .index)
```

Note: the brain decides to use `playstealth-cli navigate` for URL changes (CDP-driven, no synthetic clicks needed) and uses `skylight-cli` only when there's no DOM-level handle. **Optimal stealth = use the most-direct API for each step.**

---

## Anti-Patterns (across the suite)

- ❌ Implementing keyboard typing in `skylight-cli`. Belongs in `playstealth-cli`.
- ❌ Implementing window screenshot in `playstealth-cli` (it already has one via CDP, but the cropping logic for SoM lives here).
- ❌ Implementing a "did I get blocked" check in `skylight-cli`. That's `unmask-cli`'s job.
- ❌ A shared library imported by all three. Code duplication is fine; coupling is not.
- ❌ Sharing state on disk between CLIs. Pass everything via stdin/argv/stdout.

---

## What Belongs In The Orchestrator (`OpenCode`)

Anything that requires *memory across CLI invocations*:
- "Last screenshot was at 12:01:03; if 30s have passed without progress, replan."
- "We've clicked the same SoM index twice and nothing changed; something is wrong."
- "User-agent says iPhone but window aspect ratio doesn't match — abort."

Anything that requires *external network calls*:
- LLM calls, vector DB lookups, KV store, telemetry.

Anything that requires *human config*:
- Profile registry, proxy pool, account credentials.

---

## Versioning Across The Triade

Each CLI has its own SemVer. The orchestrator pins exact git SHAs (until each CLI hits 1.0). Breaking JSON-shape changes in any CLI = major bump = orchestrator must explicitly upgrade.

The suite does NOT have a coordinated meta-version. Treat each CLI like an independent vendor library.

---

## Where Each Repo Lives

- `playstealth-cli`: `Hannahmana/playstealth-cli` (separate repo, not in this v0 chat)
- `skylight-cli`: `Hannahmana/skylight-cli` (this repo, this chat)
- `unmask-cli`: `Hannahmana/unmask-cli` (separate repo)
- Orchestrator: `Hannahmana/OpenCode` (separate repo, "the brain")

If you find code from one in the wrong repo, that is a bug — open a PR to move it.
