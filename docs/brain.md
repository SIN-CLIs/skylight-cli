# Brain — Design Principles & Decision Log

> **TL;DR:** This file records *why* the code is the way it is. If you are about to "improve" something and you don't know why it was done that way, read the matching decision below first. If your improvement still makes sense afterward, do it AND append a new decision entry.

---

## Core Principles

### 1. The CLI is a hand, not a brain.
This binary executes single, atomic operations. It does not loop, does not decide, does not call out to networks. The orchestrator is the brain. If you find yourself wanting to add a `--retry`, `--llm-fallback`, or `--smart-mode` flag, you are leaking brain logic into the hand. Stop and put it in the orchestrator.

### 2. Stdout is sacred.
Stdout carries the contract between us and the orchestrator. One JSON object per invocation, no exceptions. Every print, log, banner, debug output goes to stderr. The moment we let ourselves print "Loaded SkyLight ✓" to stdout for "convenience," we break every downstream parser.

### 3. Stable exit codes are stable.
The orchestrator branches on exit code. Inventing new ones — or worse, reusing old ones with different meanings — is a backwards-incompatible change. Treat the table in `AGENTS.md` as a public API.

### 4. Privates frameworks are accessed via dlopen, never via header.
Two reasons:
1. **Apple notarization rejects** binaries that statically reference private symbols. We want this thing to be redistributable eventually.
2. **Resilience to symbol removal.** If a future macOS removes `CGEventPostToPid`, we get a clean nil from `dlsym` and can fall back gracefully. A static link would crash on launch.

### 5. The window is whatever has the largest layer-0 frame for that PID.
Not "frontmost," not "key window," not "first match." Browsers create dozens of helper windows (autofill popups, drag images, devtools detached panels, status indicators). The visible content window is reliably the largest layer-0 window. This is documented in `WindowCapture.swift` and tested against Chrome, Edge, Brave, Arc, and Safari.

### 6. AX tree first, grid second.
The AX tree gives us semantic labels — gold for an LLM. But it fails on canvas-rendered apps, Flutter web, Unity WebGL, and many React-native-web frames. So we always offer `--mode grid` as the no-AX-needed fallback. The orchestrator can decide which to use based on the element count returned by `--mode som`.

### 7. Every click gets a primer, unless explicitly disabled.
Chromium has a user-activation gate: synthetic clicks without a recent "real" interaction are treated as untrusted and silently ignored by some elements (especially `<input type=file>`, autoplay, fullscreen). The primer is a throwaway click 1px outside the window origin. It costs nothing and unlocks 90% of edge cases.

### 8. Reading-order sort is not optional.
SoM badges are useless if the numbers don't roughly correspond to where a human would look. Numbering top-to-bottom, left-to-right within Y-bands of 20px matches how every multimodal LLM "reads" a screenshot. Get this wrong and the LLM picks the wrong badge.

---

## Decision Log

### D-001 — Swift Package Manager, not Xcode project
**Date:** session-01
**Decision:** Use SPM (`Package.swift`), not an `.xcodeproj`.
**Why:** Reproducible builds in CI, no merge conflicts in `project.pbxproj`, no Xcode required for users. The orchestrator can build us in a Linux→macOS cross-compile pipeline (future).
**Trade-off:** No Interface Builder. Acceptable, we have no UI.

### D-002 — No external Swift dependencies
**Date:** session-01
**Decision:** `dependencies: []` in `Package.swift`.
**Why:** Every dep is a supply-chain risk and a build-time cost. We need argv parsing, JSON serialization, image I/O, and AX — all in the standard library or system frameworks. There is no compelling third-party gain.
**Trade-off:** Hand-rolled `ArgParser` (~80 lines). Cheap.
**Reconsider if:** We need YAML config or HTTP client. Even then, prefer adding to the orchestrator instead.

### D-003 — `dlopen` SkyLight, prefer `CGEventPostToPid`
**Date:** session-01
**Decision:** Load `SkyLight.framework` at runtime, prefer `CGEventPostToPid`, fall back to `SLPSPostEventRecordTo`, last resort `CGEvent.post`.
**Why:**
- `CGEventPostToPid` is the most stable private symbol. Present in macOS 12, 13, 14, 15.
- `SLPSPostEventRecordTo` is more invasive (bypasses some focus checks) but the symbol signature has changed across versions.
- Static linking is rejected by notarization. dlopen survives both notarization and symbol removal.
**Trade-off:** Runtime crashes are caught only when called, not at link time. Acceptable for a CLI; we test on every supported macOS version.

### D-004 — Primer click at `(origin.x-1, origin.y-1)`, not `(-1, -1)`
**Date:** session-01
**Decision:** Primer offset is relative to the target window, not the global screen.
**Why:** A global `(-1, -1)` lands on the menu bar on multi-monitor setups, or off-screen entirely with negative-coordinate displays. `(origin-1)` always lands just outside the target window — never inside it, never on a different app.
**Trade-off:** Requires resolving the window before the primer. ~5ms cost.

### D-005 — Y-band 20px for reading-order sort
**Date:** session-01
**Decision:** Bucket Y coordinates into 20px bands, sort by X within each band.
**Why:** A pure `(y, x)` sort breaks on horizontal toolbars where elements have y-values 1–2px apart but visually form a row. 20px matches typical button height tolerances. Empirically validated on Google Forms, Typeform, SurveyMonkey.
**Reconsider if:** We see misordering on dense UIs. Dynamic banding (use median element height) is the next step.

### D-006 — No `--retry` flag, no internal sleep loops (except `wait-for-selector`)
**Date:** session-01
**Decision:** All retry policy lives in the orchestrator. Exception: `wait-for-selector` polls AX tree every `--poll-ms` until `--timeout`.
**Why:** Retries depend on the budget of the parent task. The CLI cannot know if a click is the 1st or 47th attempt of a flow. The orchestrator owns budgets.
**Why the exception:** `wait-for-selector` is *not* a retry of a failure — it's a synchronization primitive. Otherwise we'd need round-trips of `screenshot → parse → screenshot → parse` from the orchestrator, which is wasteful for a deterministic synchronous wait.

### D-007 — `dry-run` on screenshot AND click
**Date:** session-01
**Decision:** Both subcommands accept `--dry-run`.
**Why:**
- Screenshot dry-run: render SoM, return JSON with element coordinates, do NOT write the PNG. Useful for AX-tree calibration without filesystem writes.
- Click dry-run: resolve the target, return the would-be coordinates, do NOT post the event. Crucial for the orchestrator to validate its own coordinate logic before going live.
**Trade-off:** Doubles surface area for testing. Worth it.

### D-008 — JSON-only stdout, even on error
**Date:** session-01
**Decision:** Errors print `{"status":"error","code":"…","message":"…"}` to stdout, exit non-zero.
**Why:** The orchestrator does `proc = run(cmd); j = json.loads(proc.stdout); branch on j["status"]`. If errors went to stderr, the orchestrator would have to handle two parsers. JSON-only stdout means one parser, branch on `status` field. Exit code is a fast pre-check before parsing.

### D-009 — No emojis, no ANSI colors anywhere
**Date:** session-01
**Decision:** Pure ASCII output, no terminal styling.
**Why:** This binary is consumed by a Python subprocess on a headless server. Color codes mangle JSON parsers and pollute logs. Emojis are worse in JSON: the orchestrator stores logs in Postgres, where some columns have charset constraints.

### D-010 — Window matching: largest layer-0 frame, not foreground
**Date:** session-01
**Decision:** When multiple windows match a PID, return the one with the largest area.
**Why:** "Foreground" depends on focus, which is exactly what we're trying to NOT depend on (we want to click in background windows). "Largest layer-0" is stable across focus changes.
**Reconsider if:** A user has multiple equally-large content windows for the same PID. We add a `--window-id` selector then.

### D-011 — No telemetry, no auto-update, no phone-home
**Date:** session-01
**Decision:** This binary makes zero network calls.
**Why:** Trust + auditability. The orchestrator is the only network-talking layer. If this CLI ever needs to fetch something, it should accept it as a CLI flag instead.

### D-012 — German allowed in commit messages and session logs, English mandatory in code & docs
**Date:** session-01
**Decision:** Source code, doc comments, JSON keys, error messages: English. Session logs and ad-hoc notes: German is OK if that's the operator's working language.
**Why:** Code is shared infra; future contributors may not be German. Logs are operator-personal.

---

## Open Questions (decide later)

- **Q-A:** Should `screenshot --mode som` write the PNG even on dry-run if `--out -` is passed (stdout)? Currently dry-run skips PNG entirely. Pro: enables piping to a viewer. Con: pollutes stdout-as-JSON contract.
- **Q-B:** `wait-for-selector` currently only matches role+label. Add regex on label? Add multiple selectors AND'd together?
- **Q-C:** Add `record` subcommand to capture a sequence of mouse positions for replay? Useful for debugging, tempting scope creep.
- **Q-D:** Codesigning + notarization for distributed binary. Currently ad-hoc only. Track in `handoff.md`.

---

## Anti-Decisions (things we explicitly chose NOT to do)

- **No SwiftUI / no GUI.** Mentioned because new agents tend to add a "small status window." Don't.
- **No daemon mode.** Don't keep a long-running process. Spawn-per-command is the model. Cold start is ~30ms; if that's ever the bottleneck, revisit.
- **No keyboard input.** Typing belongs in `playstealth-cli` via CDP, where we have proper IME and locale handling. Synthetic key events here would re-implement that badly.
- **No screen recording.** macOS screen recording requires ScreenCaptureKit + entitlements + user prompt; that's a separate scope.
- **No multi-monitor coordinate translation as a feature.** `WindowCapture` already returns absolute coordinates; the orchestrator passes them back unchanged. No "monitor 2" flag needed.
