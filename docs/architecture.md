# Architecture

> **TL;DR:** `skylight-cli` is a thin Swift binary that does four things: (1) find a window for a given PID, (2) capture it as a CGImage, (3) walk the AX tree to find clickable elements, (4) post mouse events directly to that PID via the private SkyLight framework. Everything else (LLM calls, retry loops, survey logic) lives in the orchestrator.

---

## System Boundary Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator (Python, lives in OpenCode repo) — "the brain"    │
│  - Spawns subprocesses                                          │
│  - Parses JSON from stdout                                      │
│  - Decides what to do next (uses Llama 4 Scout via Cloudflare)  │
└────────┬────────────────────┬──────────────────────┬────────────┘
         │ subprocess          │ subprocess           │ subprocess
         ▼                     ▼                      ▼
   playstealth-cli        skylight-cli           unmask-cli
   (this repo IS NOT      (this repo IS this)    (other repo)
    this one)
   - launches Chrome      - captures window      - probes detection
   - fingerprint mask     - SoM overlay          - identity checks
   - returns PID          - clicks via SkyLight  - returns risk JSON
                          - returns JSON
```

This CLI knows nothing about the other two. They communicate only through the orchestrator.

---

## Module-Level View (inside this repo)

```
                ┌──────────────┐
   argv ──────► │  main.swift  │  parses subcommand, dispatches
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │   CLI.swift  │  one function per subcommand
                └──┬───┬───┬───┘
       ┌───────────┘   │   └────────────────┐
       ▼               ▼                    ▼
┌─────────────┐ ┌───────────────┐   ┌──────────────────┐
│WindowCapture│ │AXElementFinder│   │ SkyLightClicker  │
│  (CGWindow- │ │ (AXUIElement- │   │ (dlopen private  │
│   List API) │ │  CopyAttribut)│   │  framework)      │
└──────┬──────┘ └───────┬───────┘   └──────────────────┘
       │                │
       └────────┬───────┘
                ▼
       ┌────────────────┐
       │  SoMOverlay    │  draws badges/grid on CGImage
       └────────────────┘

Cross-cutting:
- Utils.swift  → ArgParser, Output.json, CLIError, PNGWriter
```

---

## Data Flow For A Typical Click

The orchestrator wants to click "Continue" in a survey. Sequence:

```
1. Orchestrator: spawn `skylight screenshot --pid 1234 --mode som --include-tree`
   ├─ main.swift          → routes to CLI.screenshot
   ├─ WindowCapture       → CGWindowListCopyWindowInfo(pid=1234, layer=0)
   │                        returns {windowID, frame, CGImage}
   ├─ AXElementFinder     → AXUIElementCreateApplication(1234)
   │                        recursive walk, filter by frame ⊆ window
   │                        sort by reading order (Y bands → X)
   ├─ SoMOverlay          → draws numbered badges on CGImage
   ├─ PNGWriter           → writes /tmp/shot.png
   └─ Output.json         → {status, file, elements: [...]}

2. Orchestrator: send PNG + JSON to Llama 4 Scout
   LLM returns: {"action": "click", "element_index": 7}

3. Orchestrator: spawn `skylight click --pid 1234 --element-index 7`
   ├─ main.swift          → routes to CLI.click
   ├─ WindowCapture       → re-resolves window (window may have moved)
   ├─ AXElementFinder     → re-walks tree, gets elements[7]
   ├─ SkyLightClicker     → dlopen SkyLight.framework
   │                        primer click at (origin.x-1, origin.y-1)
   │                        real click via CGEventPostToPid(pid=1234)
   └─ Output.json         → {status, point, used_fallback: false}
```

Two screenshots and two AX walks per click is intentional: the window may have moved between calls, and we never trust stale geometry.

---

## Why Each Module Exists

### `main.swift`
Single responsibility: parse `argv[1]` as a subcommand and dispatch. Contains the version constant. Anything else belongs in `CLI.swift`.

### `CLI.swift`
One static function per subcommand. Each function:
1. Parses flags via `ArgParser`.
2. Calls into the worker modules.
3. Builds a JSON dict.
4. Hands off to `Output.json`.

This is the only file an LLM agent should usually touch when adding a new subcommand. Keep functions <50 lines; split into helpers if longer.

### `WindowCapture.swift`
The **only** place we talk to `CGWindowListCopyWindowInfo`. Filters:
- `kCGWindowOwnerPID == pid`
- `kCGWindowLayer == 0` (excludes Dock, menu bar, status icons)
- `width >= 200, height >= 200` (excludes tooltips, shadows, splash sub-windows)
- Picks the largest matching window if multiple (Chrome creates phantom helper windows)

Returns `(CGImage, frame: CGRect, windowID: CGWindowID, title: String, onScreen: Bool)`.

### `AXElementFinder.swift`
The **only** place we use `AXUIElement*` APIs. Steps:
1. `AXUIElementCreateApplication(pid)`
2. Recursive depth-first walk, max depth 60.
3. Keep elements whose frame is inside the window frame and has area > 16 px².
4. Filter by role allow-list: `AXButton`, `AXLink`, `AXCheckBox`, `AXRadioButton`, `AXTextField`, `AXTextArea`, `AXPopUpButton`, `AXMenuItem`, `AXTab`.
5. Sort by reading order: bucket Y into 20 px bands, then sort by X within each band.

The reading-order sort is critical for SoM: the LLM reads the image left-to-right, top-to-bottom, and expects badge `1` to be roughly top-left.

### `SoMOverlay.swift`
Two pure functions on CGImage. `applySoM` draws numbered colored badges based on AX elements. `applyGrid` draws a uniform grid (used when AX tree is empty, e.g., canvas-rendered surveys, Flutter web, some React-native-web apps).

The `applyGrid` mode is the **safety net**. If the AX tree returns nothing useful, the orchestrator switches to grid mode and asks the LLM "click cell B7", then maps back to coordinates.

### `SkyLightClicker.swift`
The dangerous module. Order of attempts:

1. `dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)`
2. `dlsym("CGEventPostToPid")` — preferred, exists on all macOS 12+.
3. `dlsym("SLPSPostEventRecordTo")` — fallback, more invasive but bypasses some sandbox cases.
4. **Last resort:** `CGEvent.post(.cghidEventTap, …)` — moves the visible cursor. Sets `used_fallback: true` in the JSON so the orchestrator knows.

Every click returns `(posted: Bool, skylightLoaded: Bool, usedFallback: Bool)`. The orchestrator uses these flags to detect when SkyLight is unavailable (e.g., on a future macOS where Apple removed the symbol) and switch strategies.

### `Utils.swift`
Three things:
- `ArgParser`: positional + flag parser. No external lib (kept dep-free).
- `Output.json`: serializes via `JSONSerialization`, sanitizes `CGFloat`/`pid_t`, writes one line to stdout.
- `CLIError`: throws-friendly struct that `main.swift` catches and converts to error JSON + exit code.
- `PNGWriter`: thin wrapper over `CGImageDestination` (named to avoid clashing with Apple's `ImageIO` framework).

---

## What Lives Outside This Repo (and why)

| Concern | Where it lives | Why not here |
|---|---|---|
| Llama 4 Scout / LLM prompts | `OpenCode` orchestrator | Model-specific, changes often |
| Browser launching, fingerprinting | `playstealth-cli` | Different OS surface (Chromium internals) |
| Bot-detection probing | `unmask-cli` | Independent identity, no UI access |
| Survey-specific logic | `OpenCode` agent profiles | Business logic, not infrastructure |
| Retry / backoff policies | `OpenCode` orchestrator | Depends on overall task budget |
| Telemetry / cost tracking | `OpenCode` orchestrator | Cross-cutting, not per-CLI |

If you find yourself wanting to add any of the above to this repo: stop. Open a discussion in `OpenCode` instead.

---

## Build & Distribution

- **Build:** `swift build -c release` — produces `.build/release/skylight`.
- **Codesign:** `codesign --force --deep --sign - .build/release/skylight` (ad-hoc) for local; production uses Developer ID + notarization (TODO, see `docs/handoff.md`).
- **Entitlements:** None required at the binary level. The Terminal / parent app needs Accessibility permission (`System Settings → Privacy & Security → Accessibility`).
- **Distribution:** The orchestrator ships this binary as a vendored dependency. No Homebrew tap (yet).

---

## Threading Model

- All commands are synchronous. Each invocation runs to completion on the main thread.
- AX calls are inherently main-thread bound on macOS — no escape from that.
- `wait-for-selector` polls on the main thread with `Thread.sleep`. Acceptable because each invocation is a fresh process; no UI to keep responsive.

If you ever need parallelism (e.g., screenshot two windows at once), spawn two CLI processes in parallel from the orchestrator. Do not add Swift concurrency here.

---

## Versioning

- Semver in `SKYLIGHT_VERSION` constant in `main.swift`.
- Breaking JSON shape change → bump major.
- New subcommand or new field → bump minor.
- Bug fix, no shape change → bump patch.
- The orchestrator pins the version via git SHA, not tag, until we hit 1.0.
