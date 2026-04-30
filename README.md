# skylight-cli

Stateless macOS CLI that captures windows, dumps interactive elements (Set-of-Marks)
and clicks via `AXUIElementPerformAction` (Accessibility API) —
**`CGEventPostToPid` does NOT work on Chrome 148/macOS 26.**

**Current Version:** 0.2.1 (AXPress)
**Minimum macOS:** 12.0+  
**Status:** Production-ready (v0.2.0 with enhanced debugging & error handling)

Part of the SIN-CLIs stealth triad:

```
unmask-cli (sense)  ->  playstealth-cli (think)  ->  skylight-cli (act)
```

Each command is atomic, prints a single JSON object on stdout and exits with
a non-zero code on failure. There is no daemon, no MCP server, no shared state.

## Requirements

- macOS 12+
- Swift 5.9+ (`xcode-select --install` is enough; full Xcode is not required)
- Accessibility permission for the binary that runs the CLI
  (System Settings > Privacy & Security > Accessibility)

## Build

```bash
swift build -c release
cp .build/release/skylight /usr/local/bin/skylight-cli
```

## v0.2.0 Features

- ✅ **Debug Logging** — Set `SKL_DEBUG=1` for diagnostic output
- ✅ **Enhanced Errors** — Contextual error fields for orchestrator integration
- ✅ **Safe Type Casting** — Eliminated force_cast warnings
- ✅ **Improved ArgParser** — Validation helpers for argument groups

See [CHANGELOG.md](docs/CHANGELOG.md) for full release notes.

## Quick start

```bash
# Find a Chrome PID
PID=$(pgrep -n "Google Chrome")

# Take a screenshot with Set-of-Marks overlay
skylight-cli screenshot --pid $PID --mode som --out chrome.png --include-tree

# List interactive elements as JSON (feed this to Llama 4 Scout etc.)
skylight-cli list-elements --pid $PID

# Click element 7 (resolved from list-elements / SoM IDs)
skylight-cli click --pid $PID --element-index 7

# Or click by visible label, dry run first
skylight-cli click --pid $PID --label "Continue" --dry-run

# Wait for a selector to appear
skylight-cli wait-for-selector --pid $PID --role AXButton --label "Submit" --timeout 20

# Inspect window geometry (use this before each click to detect window moves)
skylight-cli get-window-state --pid $PID
```

## Output contract

Every command emits a single JSON object on stdout:

```json
{
  "status": "ok",
  "command": "click",
  "pid": 1234,
  "dry_run": false,
  "primer": true,
  "button": "left",
  "point": { "x": 612.0, "y": 410.0 },
  "element_index": 7,
  "element": { "role": "AXButton", "label": "Continue" }
}
```

On failure, JSON goes to **stderr** and the process exits non-zero:

```json
{ "status": "error", "error": "element_not_found", "message": "..." }
```

| Exit | Meaning              |
|------|----------------------|
| 0    | OK                   |
| 1    | Internal error       |
| 2    | Bad arguments        |
| 3    | Element / window not found |
| 4    | IO / click failure   |
| 5    | Timeout              |

## Stealth model

- `click` posts events with `CGEventPostToPid` (resolved at runtime from
  `SkyLight.framework`). The host's physical cursor does not move and the
  target window does not need to be activated.
- A primer click at `(window.origin - 1, window.origin - 1)` ticks Chromium's
  user-activation gate so the real click is treated as trusted. Disable with
  `--no-primer`.
- If `CGEventPostToPid` cannot be resolved (older OS or hardened runtime
  blocks the symbol), the click falls back to `CGEvent.post(tap:.cghidEventTap)`
  which **does** steal the system cursor. The JSON response always includes
  enough state for the orchestrator to detect the fallback path.

## Roadmap

- [ ] `recording start|stop` + `replay-trajectory` (port from cua-driver)
- [ ] `--state-dir` for persistent window-state cache
- [ ] `verify` subcommand that pipes through `unmask-cli`
- [ ] Notarized signed build with `com.apple.security.cs.allow-unsigned-executable-memory`
      so the SkyLight dlopen survives Gatekeeper on locked-down installs

## Repository layout

```
Sources/skylight/
  main.swift            Entry point + command router
  CLI.swift             Subcommand implementations
  WindowCapture.swift   CGWindowListCopyWindowInfo + CGWindowListCreateImage
  AXElementFinder.swift Recursive AX tree walker, returns interactive elements
  SoMOverlay.swift      Renders SoM badges + grid fallback onto CGImage
  SkyLightClicker.swift dlopen bridge to CGEventPostToPid / SLPSPostEventRecordTo
  Utils.swift           Arg parser, JSON output, error model, PNG writer
```
