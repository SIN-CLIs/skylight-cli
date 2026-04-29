# Handoff — State Of The Repo

> **TL;DR for the incoming agent:** v0.1 scaffold is complete. All five subcommands (`screenshot`, `click`, `wait-for-selector`, `get-window-state`, `list-elements`) are implemented and compile-clean against macOS 12+. SkyLight integration uses `dlopen` with three fallback layers. Nothing has been live-tested on real hardware yet. Your first job is to run the smoke test in Section "First Action" below.

---

## What Is Done

- [x] SPM scaffold (`Package.swift`, macOS 12+, no deps)
- [x] Subcommand router (`main.swift`)
- [x] `screenshot` — modes: `raw`, `som`, `grid`; flags: `--out`, `--grid-step`, `--include-tree`, `--dry-run`
- [x] `click` — targeting via `--element-index | --x/--y | --label`; flags: `--button`, `--no-primer`, `--dry-run`
- [x] `wait-for-selector` — flags: `--role`, `--label`, `--timeout`, `--poll-ms`
- [x] `get-window-state` — minimal, returns frame + windowID + title + onScreen
- [x] `list-elements` — full AX tree dump as JSON
- [x] `WindowCapture` — layer-0 + min-size + largest-area filter
- [x] `AXElementFinder` — recursive walk, depth 60, role allow-list, reading-order sort
- [x] `SoMOverlay` — both `applySoM` and `applyGrid`
- [x] `SkyLightClicker` — dlopen + `CGEventPostToPid` primary + `SLPSPostEventRecordTo` fallback + `CGEvent.post` last resort with `used_fallback` flag
- [x] `Utils` — `ArgParser`, `Output.json` (stable JSON sanitizer), `CLIError`, `PNGWriter`
- [x] `.gitignore` for SPM (.build, .swiftpm, *.xcodeproj)
- [x] `README.md` — usage, exit codes, install
- [x] `AGENTS.md` — agent entry point at root
- [x] `docs/architecture.md` — module map + data flow
- [x] `docs/brain.md` — principles + decision log (D-001 through D-012)
- [x] `docs/recovery-mode.md` — when stuck
- [x] `docs/stealth-triade.md` — how this CLI fits with playstealth-cli + unmask-cli
- [x] `docs/sessions/session-01.md` — this session's work log

---

## What Is NOT Done

- [ ] **Live test on real hardware.** Nothing has been run on a Mac. We don't know if the dlopen path actually finds the symbols. **This is the first thing the next agent must do.**
- [ ] **Codesign + notarization.** Currently ad-hoc sign only. Production needs Developer ID and notarytool integration. See `docs/recovery-mode.md` if you hit signing failures.
- [ ] **CI workflow.** No `.github/workflows/build.yml` yet. Should at minimum: `swift build -c release` on macos-14 runner, run a smoke test (`get-window-state` against the dev server's own PID), upload binary artifact.
- [ ] **Recording / replay subcommands.** Mentioned in the original brief, deferred per Decision D-006. Open question Q-C in `brain.md`.
- [ ] **`--state-dir` / persistent profiles.** Not in scope for this CLI; lives in `playstealth-cli`. Confirm with `docs/stealth-triade.md`.
- [ ] **Multi-window-per-PID disambiguation.** We pick "largest layer-0." If a user has two equally-large content windows, behavior is undefined-but-deterministic. Add `--window-id` flag if/when this becomes a problem.
- [ ] **SwiftLint config.** Not added. Repo is small enough not to need one yet.
- [ ] **Unit tests.** No tests written. AX/SkyLight code is hard to unit-test (needs a real running app). Integration test against `Calculator.app` is the realistic minimum.
- [ ] **Tag a v0.1 release on GitHub.** Once smoke test passes.

---

## Known Risks / Watch Items

1. **`SLPSPostEventRecordTo` signature drift.** The symbol exists across macOS 12/13/14/15 but I have not verified the calling convention is identical. If the fallback path crashes, comment it out and rely solely on `CGEventPostToPid` until verified.
2. **`AXIsProcessTrustedWithOptions` UX.** First run will trigger the macOS Accessibility prompt for the parent terminal/app. Document this clearly in the orchestrator's onboarding. The CLI itself does not prompt — it just fails with code 4 if perms are missing. *This is intentional.* Headless systems should not pop GUI dialogs.
3. **Reading-order on RTL UIs.** Y-band-then-X breaks on Arabic/Hebrew. We don't currently flip. Acceptable for English/German workloads. Track as Q-E if needed.
4. **Chromium DPI mismatch on Retina + scaled displays.** `CGWindowList` returns logical points; `CGImage` is in physical pixels. We currently do NOT divide by `backingScaleFactor`. **Test this on a Retina display before production.** If badges land off-target, this is the cause.
5. **Two AX walks per click.** Once for screenshot, once for click execution. Unavoidable since the window may have moved. Cost is ~10–30ms per walk on typical pages. Don't try to "optimize" by caching across processes — different process, different state.

---

## First Action For The Next Agent

```bash
# On a real Mac (macOS 12+) with Accessibility permission for Terminal:
git pull
cd skylight-cli
swift build -c release

# Pick any GUI app
open -a "Calculator"
PID=$(pgrep -n "Calculator")

# Smoke test 1: window state
.build/release/skylight get-window-state --pid $PID | jq .
# Expect: status=ok, frame with sane width/height

# Smoke test 2: AX tree
.build/release/skylight list-elements --pid $PID | jq '.count'
# Expect: > 5 (Calculator has ~17 buttons)

# Smoke test 3: dry-run click on element 0
.build/release/skylight click --pid $PID --element-index 0 --dry-run | jq .
# Expect: status=ok, dry_run=true, point with sane x/y

# Smoke test 4: REAL click (Calculator's "1" button is usually low-numbered)
# WARNING: this will actually click. Make sure you accept that.
.build/release/skylight click --pid $PID --element-index 0 | jq .
# Expect: status=ok, the Calculator should register a button press

# Smoke test 5: SoM screenshot
.build/release/skylight screenshot --pid $PID --mode som --out /tmp/calc.png
open /tmp/calc.png
# Expect: PNG with numbered badges on every button
```

If any of those fail, **stop**, open `docs/recovery-mode.md`, and follow the matching diagnosis.

---

## Branch / Commit State

- Working branch: `v0/larahelosa-7280-780000b6` (the v0 chat branch)
- Default branch: `main`
- Last commit (session-01): `feat: scaffold skylight-cli v0.1 (Swift + SkyLight.framework)`
- Open PR: not yet — open one against `main` after smoke test passes.

---

## Communication Channels

- **Operator:** the human who started this. Speaks German, prefers concise answers, does not want emojis in code.
- **Sibling repos:** `playstealth-cli`, `unmask-cli`, `OpenCode` (orchestrator). See `docs/stealth-triade.md`.
- **Issues / questions:** append to `docs/sessions/session-NN.md` for the current session, then push.

---

## Hand-off Checklist For YOUR Successor

When YOU finish a session, before you stop:

1. [ ] Update this file's "What Is Done" / "What Is NOT Done" sections.
2. [ ] If you decided something non-trivial, append a new entry `D-NNN` to `docs/brain.md`.
3. [ ] If you got stuck and worked around it, document the workaround in `docs/recovery-mode.md`.
4. [ ] Append a `docs/sessions/session-NN.md` (increment N) summarizing your session.
5. [ ] Commit. Push. Make sure CI is green (once CI exists).
6. [ ] Leave a short "next agent: do X first" note at the top of this file's "First Action" section.
