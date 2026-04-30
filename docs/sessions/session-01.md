> ⚠️ HISTORICAL — Pre-AXPress era. CGEventPostToPid outdated. Now: AXPress (AXUIElementPerformAction).

# Session 01 — Initial Scaffold

**Date:** 2026-04-30
**Operator:** human (DE-speaking)
**Agent:** v0
**Branch:** `v0/larahelosa-7280-780000b6` → targeting `main` of `Hannahmana/skylight-cli`

---

## Goal

Bootstrap a working Swift CLI (`skylight-cli`) that the brain repo (`OpenCode`) can spawn as a subprocess to:
- Capture windows of a target macOS process by PID
- Overlay Set-of-Marks (SoM) badges for LLM-driven UI selection
- Click on AX-tree elements without moving the visible cursor

This is one of three sibling CLIs (see `docs/stealth-triade.md`).

---

## What Was Done

### Code (8 Swift files)
1. `Package.swift` — SPM manifest, macOS 12+, no external dependencies.
2. `Sources/skylight/main.swift` — entry point + subcommand dispatch + `SKYLIGHT_VERSION = "0.1.0"`.
3. `Sources/skylight/CLI.swift` — five subcommands: `screenshot`, `click`, `wait-for-selector`, `get-window-state`, `list-elements`.
4. `Sources/skylight/WindowCapture.swift` — `CGWindowListCopyWindowInfo` with layer-0, min-size 200, largest-frame filter.
5. `Sources/skylight/AXElementFinder.swift` — recursive AX walker, depth 60, role allow-list, reading-order sort (Y-bands of 20px → X).
6. `Sources/skylight/SoMOverlay.swift` — both `applySoM` (badges from elements) and `applyGrid` (uniform fallback for canvas-rendered apps).
7. `Sources/skylight/SkyLightClicker.swift` — `dlopen` of `SkyLight.framework`, primary `CGEventPostToPid`, fallback `SLPSPostEventRecordTo`, last-resort global `CGEvent.post` with `used_fallback` flag.
8. `Sources/skylight/Utils.swift` — `ArgParser`, `Output.json` (sanitizing JSON serializer), `CLIError`, `PNGWriter`.

### Docs (this batch)
- `AGENTS.md` (root) — agent entry point, decision tree, hard rules, output contract, exit codes.
- `docs/architecture.md` — module map, data flow, build/distribution notes.
- `docs/brain.md` — 8 core principles + decision log D-001..D-012 + open questions Q-A..Q-D + anti-decisions.
- `docs/handoff.md` — done/not-done lists, risks, first-action smoke test for next agent.
- `docs/recovery-mode.md` — symptom-driven debugging guide (8 symptoms + catch-all + postmortem template).
- `docs/stealth-triade.md` — how this CLI relates to `playstealth-cli` + `unmask-cli` + `OpenCode`.
- `docs/sessions/session-01.md` — this file.
- Updated `README.md` with usage examples and exit codes.
- Added `.gitignore` for SPM (`.build`, `.swiftpm`, `*.xcodeproj`).

---

## Key Decisions (logged in `docs/brain.md`)

- **D-001** SPM, not Xcode project.
- **D-002** Zero external Swift dependencies.
- **D-003** `dlopen` SkyLight at runtime (not static link), prefer `CGEventPostToPid`.
- **D-004** Primer click at `(window.origin - 1)`, not global `(-1, -1)`.
- **D-005** Reading-order sort uses 20px Y-bands.
- **D-006** No internal retry; orchestrator owns budgets. `wait-for-selector` is the only polling primitive.
- **D-007** `--dry-run` on both `screenshot` and `click`.
- **D-008** JSON-only stdout, even on error.
- **D-009** Pure ASCII, no emojis, no ANSI.
- **D-010** Pick window by largest layer-0 frame, not by foreground state.
- **D-011** Zero network calls from this binary.
- **D-012** English in code & docs; German allowed in session logs.

---

## Bugs Caught During Session

1. **Name clash with Apple's `ImageIO`.** I had defined an `enum ImageIO` for the PNG writer; renamed to `enum PNGWriter` to avoid shadowing the system framework name.
2. **JSON ternary type inference.** Swift refused to infer `[String: Any]` for a dict literal containing a ternary returning `NSNull` vs `String`. Fixed by hoisting the ternary into a `let fileValue: Any = ...` before the dict literal.

Both fixes committed.

---

## What Was Not Done (intentionally)

- **No live test on real hardware.** v0 environment is Linux-only; `swift build` for macOS targets cannot run here. First-run validation is the next agent's job per `docs/handoff.md`.
- **No CI workflow.** Deferred to session-02.
- **No unit tests.** AX/SkyLight code is integration-test territory (needs running app); deferred.
- **No notarization config.** Deferred.
- **No `record` / `replay-trajectory` subcommands.** Deferred per D-006 + Q-C.

---

## Operator Notes

- Operator pasted two GitHub PATs in chat. **Advised them to rotate immediately** — chat history is not safe storage even if they "rotate after." Did not use the tokens; pushed via the existing v0-Git connection.
- Operator's working language is German; concise, no-emoji style preferred.

---

## Hand-off To Session 02

> See `docs/handoff.md` "First Action" — run the smoke test on a real Mac before any further code changes.

If smoke test passes:
1. Tag v0.1.0.
2. Add a GitHub Actions workflow (macos-14 runner) that builds + smoke-tests against `Calculator.app`.
3. Begin integrating with the `OpenCode` orchestrator (separate repo) — supply a mock PID, verify SoM JSON shape matches what the orchestrator's parser expects.

If smoke test fails:
1. Identify the failing symptom in `docs/recovery-mode.md`.
2. If symptom is not listed: document it, log a "Stuck" note here in this file (or open `session-02.md` if a new session), inform the operator before ad-hoc rewriting.

---

## Files Touched This Session

```
Package.swift                                  +24
Sources/skylight/main.swift                    +42
Sources/skylight/CLI.swift                     +259
Sources/skylight/WindowCapture.swift           +80
Sources/skylight/AXElementFinder.swift         +137
Sources/skylight/SoMOverlay.swift              +105
Sources/skylight/SkyLightClicker.swift         +90
Sources/skylight/Utils.swift                   +186
.gitignore                                     +22
README.md                                      +121
AGENTS.md                                      +new
docs/architecture.md                           +new
docs/brain.md                                  +new
docs/handoff.md                                +new
docs/recovery-mode.md                          +new
docs/stealth-triade.md                         +new
docs/sessions/session-01.md                    +new (this file)
```
