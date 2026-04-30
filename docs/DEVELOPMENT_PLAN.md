# Development Plan - skylight-cli v0.2.0

## Overview
This document outlines the current feature set and roadmap for `skylight-cli`, a stateless macOS CLI for window capture, element inspection, and stealth mouse event injection.

**Current Version:** 0.2.0  
**Last Updated:** 2026-04-30

---

## Phase 1: Core Infrastructure (Completed ✅)

### Implemented Features
- ✅ **Window Capture** — CGWindowListCopyWindowInfo + CGWindowListCreateImage
- ✅ **AX Element Finder** — Recursive accessibility tree walker with reading-order sort
- ✅ **SoM Overlay** — Set-of-Marks badge rendering + grid fallback
- ✅ **SkyLight Bridge** — dlopen-based private framework loader with fallback to CGEvent.post
- ✅ **CLI Router** — Atomic subcommand dispatch with JSON I/O contract
- ✅ **Error Model** — Consistent error codes + exit codes for orchestrator integration

### Core Commands
1. `screenshot` — Capture window as PNG, optional SoM/grid overlay
2. `click` — Post mouse events via SkyLight without cursor theft
3. `wait-for-selector` — Poll for element appearance with timeout
4. `get-window-state` — Query window geometry + title
5. `list-elements` — Dump interactive AX tree as JSON

### Quality Improvements (v0.2.0)
- ✅ Removed swiftlint force_cast warnings from AXElementFinder
- ✅ Added debug logging infrastructure (SKL_DEBUG env var)
- ✅ Enhanced error output with context fields
- ✅ Improved ArgParser with validation helpers
- ✅ Version bump from 0.1.0 → 0.2.0

---

## Phase 2: Recording & Replay (Pending)

### `recording start|stop|replay`

**Purpose:** Capture and replay click sequences without LLM latency.

**Commands:**
```bash
skylight-cli recording start --pid $PID --out recording.json
skylight-cli recording stop
skylight-cli recording replay --pid $PID --file recording.json
```

**JSON Schema:**
```json
{
  "version": "0.2.0",
  "pid": 1234,
  "window_id": 123,
  "recorded_at": "2026-04-30T15:30:00Z",
  "actions": [
    { "type": "click", "index": 3, "timestamp": 0.0 },
    { "type": "wait", "role": "AXButton", "label": "Next", "timeout": 5.0 },
    { "type": "screenshot", "output": "frame2.png", "mode": "som", "timestamp": 1.5 }
  ]
}
```

**Implementation Notes:**
- Port logic from cua-driver's recording module
- Store relative timestamps (t0 = start)
- Replay respects element index changes (re-resolve each action)
- Dry-run mode for validation before playback

---

## Phase 3: State Caching & Persistence (Pending)

### `--state-dir` flag for all commands

**Purpose:** Optional persistent window-state cache to reduce re-walks on rapid clicks.

**Behavior:**
- `screenshot` / `list-elements` → write `{pid}.json` to state-dir with element cache
- `click` → load cache before re-walk (soft check, re-walk if stale)
- Cache TTL: 100ms (tunable)

**File Structure:**
```
~/.skylight-state/
  1234.json        # window state for PID 1234
  1234_elements.json  # cached AX tree + reading order
```

**Benefits:**
- Reduces AX tree walk cost on rapid sequences
- Improves latency from 100ms+ → 20-30ms per click

---

## Phase 4: Verification & Stealth Hardening (Pending)

### `verify` subcommand

**Purpose:** Run botdetection checks via unmask-cli before/after actions.

```bash
skylight-cli verify --pid $PID --check all --before-click --after-screenshot
```

**Flags:**
- `--check` — all | headers | fingerprint | cursor-position | timing
- `--before-click` — run checks before each click
- `--after-screenshot` — run checks after each screenshot

**Integration:**
- Calls `unmask-cli probe` internally
- Returns risk score + recommendations
- Orchestrator uses to decide retry strategy

---

## Phase 5: Code Signing & Distribution (Pending)

### Notarization + Entitlements

**Current Limitation:**
- dlopen(SkyLight.framework) works in dev, but Gatekeeper may block in distribution
- Hardened runtime prevents unsigned-memory-execute needed for SkyLight

**Solution:**
- Request `com.apple.security.cs.allow-unsigned-executable-memory` entitlement
- Sign binary with Developer ID
- Submit to Apple notarization
- Pin notarization ticket in vendored build

**Build Steps:**
```bash
swift build -c release
codesign --deep --force --sign "Developer ID Application" \
  --entitlements entitlements.plist \
  .build/release/skylight
xcrun stapler staple .build/release/skylight
```

---

## Phase 6: Extended Element Support (Pending)

### Expand AX role allow-list

**Current Roles:**
```swift
kAXButtonRole, kAXLinkRole, kAXCheckBoxRole, kAXRadioButtonRole,
kAXTextFieldRole, kAXTextAreaRole, kAXPopUpButtonRole, kAXMenuButtonRole,
kAXSliderRole, kAXTabGroupRole, kAXComboBoxRole, "AXWebArea", "AXStaticText"
```

**Candidates for Addition:**
- kAXScrollBarRole (for scroll-via-AX)
- kAXMenuItemRole (for context menus)
- kAXCellRole (for data tables)
- Custom roles from React Native Web, Flutter, Electron

**Implementation:**
- Make allow-list configurable via `--roles` flag
- Default to current set (backward compatible)
- Document per-framework role mappings in CONTRIBUTING.md

---

## Roadmap Summary

| Phase | Feature | Complexity | Est. Effort | Status |
|-------|---------|-----------|------------|--------|
| 1 | Core CLI + SoM + SkyLight | High | Done | ✅ Complete |
| 2 | Recording / Replay | Medium | ~2-3 days | 📋 Planned |
| 3 | State Caching | Low | ~1 day | 📋 Planned |
| 4 | Verify + unmask-cli bridge | Medium | ~2 days | 📋 Planned |
| 5 | Notarization | Medium | ~1 day (+ Apple wait) | 📋 Planned |
| 6 | Extended AX roles | Low | ~0.5 days | 📋 Planned |

---

## Testing Strategy

### Unit Tests
- ArgParser validation
- AX element sorting (reading order)
- JSON serialization / sanitization

### Integration Tests
- Real browser screenshots (Chrome, Safari, Firefox)
- Canvas-based survey click (grid mode)
- Element index stability across rapid screenshots

### End-to-End Tests
- Click sequences from orchestrator
- Fallback detection (SkyLight unavailable)
- Window move detection

---

## Known Limitations & TODOs

1. **No XCTest integration yet** — Manual testing only
2. **AX permission check** — CLI exits silently if Accessibility denied (no prompt)
3. **Multi-window handling** — Always picks largest window; no explicit selection
4. **Y-flip complexity** — CGContext flips Y-axis; easy to introduce bugs in SoMOverlay
5. **No timeout on AX walks** — Deep trees could hang the process

---

## Contributing

See CONTRIBUTING.md for coding standards, architecture decisions, and PR process.

### Key Points
- Keep modules <300 LOC each
- One subcommand per CLI.swift function
- No external dependencies (except Foundation + AppKit)
- Always test on real browsers before submitting
- Document new AX roles in this file

---

## References

- [macOS Accessibility API](https://developer.apple.com/accessibility/)
- [CGEvent Documentation](https://developer.apple.com/documentation/coregraphics/cgevent)
- [Window Server Framework](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/WindowServerGuide/)
- [SkyLight.framework](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/SkyLight.rb) (private, reverse-engineered)
