# Contributing to skylight-cli

## Architecture Rule (Non-Negotiable)

- **This is a CLI tool, not a server.** Do not add a long-running process, MCP layer, REST API, or any persistent connection.
- **Every execution is one atomic command.** State is stored externally (by the caller, e.g., in a Python orchestrator).
- **The tool must remain stateless.** No database, no config file except those already in macOS.
- **No business logic in this repo.** No survey questions, no LLM prompts, no "is this a captcha" heuristics. That belongs in the orchestrator (`OpenCode`).

---

## How To Add a New Subcommand

1. **Add a case to the `switch command` in `Sources/skylight/main.swift`.**
2. **Create a parser struct in `Sources/skylight/CLI.swift`.**
3. **Implement the logic in a new or existing Swift file under `Sources/skylight/`.**
4. **The new command MUST:**
   - Output JSON on stdout/stderr exactly like existing commands.
   - Use semantic exit codes (pick an unused number from the table below).
   - Support `--pid` if it operates on a window/process.
   - Document itself in `--help` output.
   - Update `CLI_REFERENCE.md` with usage examples.
   - Update `AGENTS.md` if the output contract changes.

---

## Fallback Principle

Click strategy (AXPress primary, CGEvent fallback):

1. **Primary:** `AXUIElementPerformAction(kAXPressAction)` — Accessibility API, invisible.
2. **Fallback:** `CGEvent.post(tap: .cghidEventTap)` — visible cursor, logged as fallback.
3. **Always log the method** in JSON output:
   - `"method":"axpress"` — used Accessibility API
   - `"method":"cgevent"` — used global event (visible cursor)

Example from `SkyLightClicker.swift`:

```swift
if axPress(element: el.axElement) {
    // AXPress succeeded (invisible, preferred)
} else {
    // Fallback: global CGEvent (visible cursor)
    CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, ...).post(tap: .cghidEventTap)
}
}
```

---

## Exit Code Allocation

| Code | Meaning | Used By |
|------|---------|---------|
| 0 | Success | All commands |
| 1 | Internal error | Generic exception handler |
| 2 | Bad arguments / window not found | ArgParser, WindowCapture |
| 3 | Element out of range | `click`, `list-elements` |
| 4 | I/O or click rejection | PNG writer, SkyLightClicker |
| 5 | Timeout | `wait-for-selector` |
| 99 | Accessibility permission missing | AXElementFinder |

**Do not invent new exit codes without updating this table in CONTRIBUTING.md and AGENTS.md.**

---

## Code Style

1. **No external dependencies beyond macOS SDKs and Foundation.**
   - Allowed: AppKit, ApplicationServices, CoreGraphics, ImageIO, QuartzCore
   - Not allowed: SPM packages, CocoaPods, Carthage
2. **Use `guard` for early exits** – never silently continue on missing parameters.
3. **Comments allowed only for explaining non-obvious macOS API quirks.**
4. **Function names are verb-first:** `captureWindow`, `findElement`, `performClick`.
5. **Error types are enum-based,** not stringly-typed. See `Utils.swift` for patterns.
6. **JSON construction uses `[String: Any]` dictionaries,** then `JSONSerialization.data(withJSONObject:)`.
7. **Use safe type casting** – avoid force casts (`as!`). Use `guard let` or `if let` patterns instead.
8. **Enable debug logging** – use `SKLEnvironment.logDebug()` for non-production diagnostics.

### Debug Logging

Enable with `SKL_DEBUG=1`:
```bash
SKL_DEBUG=1 ./.build/release/skylight screenshot --pid $PID 2>&1 | grep DEBUG
```

The `SKLEnvironment` module provides:
```swift
SKLEnvironment.logDebug("AX tree walk starting, max depth: \(maxDepth)")
// Output: [DEBUG] AX tree walk starting, max depth: 60
```

---

## Testing

There is no automated testing framework yet. Manual test procedure:

1. **Build:** `swift build -c release`
2. **Target a test window:**
   ```bash
   PID=$(pgrep -n "Google Chrome")
   .build/release/skylight get-window-state --pid $PID | jq .
   ```
3. **Test screenshot:**
   ```bash
   .build/release/skylight screenshot --pid $PID --mode som --dry-run --out test.png
   # Verify test.png shows numbered badges on buttons/inputs
   ```
4. **Test click (dry-run first):**
   ```bash
   .build/release/skylight click --pid $PID --element-index 0 --dry-run
   # Should output JSON with "dry_run": true
   ```

**Every PR should include:**
- At least one screenshot of `--dry-run` output showing the correct element is targeted.
- A note in `docs/handoff.md` describing what was tested.

---

## Documentation Updates

When you make changes:

| Change Type | Files to Update |
|-------------|-----------------|
| New subcommand | `CLI_REFERENCE.md`, `main.swift` help text |
| New exit code | `AGENTS.md`, `CLI_REFERENCE.md`, this file |
| JSON shape change | `AGENTS.md` ("Output Contract"), `CLI_REFERENCE.md` |
| Architecture change | `docs/architecture.md`, `docs/brain.md` |
| Session complete | `docs/sessions/session-NN.md` |

---

## Git Workflow

**IMPORTANT: Always merge directly to `main`. Never create feature branches.**

```bash
# After making changes
git add .
git commit -m "<concise description>"
git pull origin main --rebase
git push origin main
```

**Commit message format:**
```
<verb> <component>: <what changed>

<optional body explaining why>
```

Examples:
```
add list-elements: new subcommand to enumerate AX elements
fix SkyLightClicker: handle nil window frame gracefully
update AGENTS.md: clarify exit code 99 retry strategy
```

---

## When to Ask for Human Help

- If exit code 99 appears repeatedly: user must grant Accessibility permission to Terminal (or your runner) in System Settings → Privacy & Security → Accessibility.
- If `dlopen` fails on SkyLight: the user's macOS version may be too old (needs 12.0+) or Apple removed the private framework.
- If you are unsure whether a feature belongs in this repo or the orchestrator: read `docs/brain.md` section "Boundary Decision Log".

---

## Anti-Patterns (Do NOT Do These)

- ❌ Adding a Python script to this repo. The orchestrator lives elsewhere.
- ❌ Adding a SwiftUI app. This is a CLI. No GUI.
- ❌ Calling `CGEvent.post(.cghidEventTap, …)` as the primary path. That moves the visible cursor and defeats the entire point.
- ❌ Using `osascript` / AppleScript bridge. We bypass the scripting layer on purpose.
- ❌ Using `accessibility-cli`, `cliclick`, or other shell-out helpers. We are the helper.
- ❌ Assuming the foreground window is the right window. Always look up by PID + layer 0 + min size.
- ❌ Returning partial JSON, multiple JSONs, or pretty-printed JSON with extra structure. One object, one newline at end, done.
- ❌ Creating feature branches. All work goes directly to `main`.
