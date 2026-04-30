# AGENTS.md — Entry Point For Any Agent

> **If you are an LLM, coding agent, or human operator and this is the first file you read in this repository: read me completely before doing anything else.**
> Estimated read time: 3 minutes. After reading this file you will know what this repo is, what it is NOT, and where to look next.

---

## TL;DR (read this first)

- **What this repo is:** `skylight-cli` — a macOS-only command-line tool written in Swift that captures windows, walks the Accessibility (AX) tree, draws Set-of-Marks overlays, and clicks on UI elements **inside a target process** (per-PID), without using a visible cursor.
- **What this repo is NOT:** Not an AI agent. Not an orchestrator. Not a survey filler. Not a browser launcher. Not a fingerprint-stealth tool.
- **Where the brain lives:** In a separate repo (`OpenCode` / agent-suite). This CLI is one of three "hands": `skylight-cli` (this repo) + `playstealth-cli` (browser launching) + `unmask-cli` (detection checks). See `docs/stealth-triade.md`.
- **Primary consumer:** A Python orchestrator that spawns this binary, parses stdout JSON, and decides what to do next.
- **Build:** `swift build -c release` on macOS 12+. Output binary at `.build/release/skylight`.
- **Output contract:** Every command prints exactly one JSON object to stdout, even on error. Exit codes are stable.

---

## Decision Tree: Why Are You Here?

| Your goal | Read this next |
|---|---|
| "I want to understand the system" | `docs/architecture.md` |
| "I want to know the design philosophy / why decisions were made" | `docs/brain.md` |
| "I just took over from another agent, what's the state?" | `docs/handoff.md` |
| "Something broke, I am stuck, I am looping" | `docs/recovery-mode.md` |
| "How does this CLI relate to playstealth-cli and unmask-cli?" | `docs/stealth-triade.md` |
| "What did the previous session do?" | `docs/sessions/session-01.md` |
| "I want to add a feature / fix a bug" | This file (Section: "How To Make Changes") |
| "I want to call the CLI" | `README.md` (usage) + Section "Output Contract" below |

---

## Hard Rules (do not violate)

1. **Stdout is JSON-only.** Never print logs, banners, or human text to stdout. Use stderr for diagnostics. The orchestrator parses stdout with `json.loads()` and breaks if it sees anything else.
2. **One command, one JSON object.** No streaming, no multiple JSON documents per invocation.
3. **Exit codes are a contract** (see Section "Exit Codes"). Do not invent new ones without updating this file.
4. **Never call private SkyLight symbols statically.** All SkyLight access goes through `dlopen` in `Sources/skylight/SkyLightClicker.swift`. Static linking against `SkyLight.framework` ships a binary Apple will reject and breaks notarization.
5. **No business logic in this repo.** No survey questions, no LLM prompts, no "is this a captcha" heuristics. That belongs in the orchestrator (`OpenCode`).
6. **No external runtime dependencies.** SPM target stays dependency-free. We rely only on Apple system frameworks (AppKit, ApplicationServices, CoreGraphics, ImageIO).
7. **macOS 12+ only.** Do not add `#available` guards for older OS. We assume Monterey or newer.
8. **Never log user content.** AX labels can contain personal info. Do not write them to files outside the JSON response the caller asked for.

---

## Output Contract

Every successful invocation prints:

```json
{
  "status": "ok",
  "command": "<screenshot|click|wait-for-selector|get-window-state|list-elements>",
  "...": "command-specific fields"
}
```

Every error prints:

```json
{
  "status": "error",
  "code": "<machine-readable code>",
  "message": "<human-readable message>"
}
```

The orchestrator MUST be able to decide next steps from `status` and `code` alone. Do not rely on `message` for branching.

---

## Exit Codes

| Code | Meaning | When |
|---|---|---|
| 0 | Success | `status == "ok"` |
| 1 | Internal error | Unexpected exception, programmer error |
| 2 | Bad arguments | Missing/invalid flag, unknown subcommand |
| 3 | Element / window not found | PID has no usable window, index out of range |
| 4 | I/O or click rejection | Cannot write PNG, SkyLight rejected event |
| 5 | Timeout | `wait-for-selector` deadline exceeded |

The orchestrator should map these to retry strategies:
- `2`: do not retry, the prompt to the LLM was wrong, fix the call site.
- `3`: re-screenshot first (window may have closed/moved), then retry once.
- `4`: fall back to `playstealth-cli` keyboard nav or report failure.
- `5`: page never loaded what we expected; ask LLM to re-plan.

---

## How To Make Changes

1. Read `docs/architecture.md` to find the right file.
2. Read `docs/brain.md` to confirm your change matches the design intent.
3. Edit. Build with `swift build`. The build will fail loudly if you broke the contract.
4. Update the JSON shape? Update this file's "Output Contract" section AND `README.md` example output.
5. Add a new exit code? Update the "Exit Codes" table here.
6. Commit. Append a note to `docs/handoff.md` so the next agent knows.
7. If you closed a session, append a `docs/sessions/session-NN.md` summary.

---

## File Map

```
skylight-cli/
├── AGENTS.md                  # you are here
├── README.md                  # human-facing usage docs
├── Package.swift              # SPM manifest, macOS 12+, no deps
├── Sources/skylight/
│   ├── main.swift             # entry, dispatches subcommands
│   ├── CLI.swift              # subcommand implementations
│   ├── WindowCapture.swift    # CGWindowList → CGImage + frame
│   ├── AXElementFinder.swift  # recursive AX tree walker
│   ├── SoMOverlay.swift       # Set-of-Marks badges + grid fallback
│   ├── SkyLightClicker.swift  # dlopen → CGEventPostToPid + fallbacks
│   └── Utils.swift            # ArgParser, Output.json, errors, PNG writer
└── docs/
    ├── architecture.md        # how parts fit together
    ├── brain.md               # principles & decision log
    ├── handoff.md             # current state for next agent
    ├── recovery-mode.md       # when stuck, do this
    ├── stealth-triade.md      # this CLI in the 3-CLI ecosystem
    └── sessions/
        └── session-01.md      # session log
```

---

## Anti-Patterns (do NOT do these)

- ❌ Adding a Python script to this repo. The orchestrator lives elsewhere.
- ❌ Adding a SwiftUI app. This is a CLI. No GUI.
- ❌ Calling `CGEvent.post(.cghidEventTap, …)` as the primary path. That moves the visible cursor and defeats the entire point. Only allowed as a logged fallback inside `SkyLightClicker.swift`.
- ❌ Using `osascript` / AppleScript bridge. We bypass the scripting layer on purpose.
- ❌ Using `accessibility-cli`, `cliclick`, or other shell-out helpers. We are the helper.
- ❌ Assuming the foreground window is the right window. Always look up by PID + layer 0 + min size, see `WindowCapture.swift`.
- ❌ Returning partial JSON, multiple JSONs, or pretty-printed JSON with trailing newlines that contain extra structure. One object, one newline at end, done.

---

## Quick Sanity Test (run after any change)

```bash
swift build -c release
PID=$(pgrep -n "Google Chrome")
.build/release/skylight get-window-state --pid $PID | jq .
.build/release/skylight screenshot --pid $PID --mode som --include-tree --dry-run | jq '.elements | length'
```

Expected: both commands exit 0 and produce valid JSON. If either fails, read `docs/recovery-mode.md`.
