> ⚠️ HISTORICAL — Pre-AXPress era. CGEventPostToPid outdated. Now: AXPress (AXUIElementPerformAction).

# Changelog

All notable changes to skylight-cli are documented here.

## [0.2.0] — 2026-04-30

### Added
- Debug logging infrastructure via `SKL_DEBUG=1` environment variable
- Enhanced error output with optional context fields for better orchestrator integration
- `ArgParser.requireOneOf()` validation helper for mutually-exclusive argument groups
- Comprehensive Development Plan (docs/DEVELOPMENT_PLAN.md) with phases 1-6 roadmap

### Improved
- Removed force-cast warnings from AXElementFinder.frame(of:) — now uses safe type casting with guard patterns
- Updated CONTRIBUTING.md with debug logging guidance and code style improvements
- Error handling now includes version field in all error JSON responses
- Better error context propagation from internal failures to orchestrator

### Fixed
- AXElementFinder safe casting eliminates potential undefined behavior on malformed AXValue types

### Technical Details
- Version bump: 0.1.0 → 0.2.0
- Minimum macOS: 12.0
- Swift: 5.9+

---

## [0.1.0] — Initial Release

### Added
- Core CLI infrastructure with atomic subcommand dispatch
- `screenshot` — capture window with raw/SoM/grid modes
- `click` — post mouse events via CGEventPostToPid (SkyLight framework)
- `wait-for-selector` — poll for element appearance with timeout
- `get-window-state` — inspect window geometry and title
- `list-elements` — enumerate interactive AX elements
- Set-of-Marks (SoM) overlay rendering with numbered badges
- Fallback grid rendering for canvas-based UIs
- Private SkyLight framework bridge with graceful fallback to CGEvent.post
- Comprehensive error model with semantic exit codes
- JSON I/O contract for orchestrator integration
- Full Accessibility (AX) tree walker with reading-order sorting
- Window capture via CGWindowListCopyWindowInfo

### Architecture
- Pure Swift, zero external dependencies
- Stateless design: each invocation is independent
- No daemon, no long-running processes
- Private API aware with runtime fallbacks

---

## Roadmap

### Phase 2 (Pending)
- `recording start|stop|replay` — capture and replay click sequences

### Phase 3 (Pending)
- `--state-dir` flag for persistent window-state caching
- Element cache to reduce AX tree walk cost on rapid clicks

### Phase 4 (Pending)
- `verify` subcommand for botdetection integration with unmask-cli

### Phase 5 (Pending)
- Notarization + Developer ID code signing
- Entitlements for hardened runtime compatibility

### Phase 6 (Pending)
- Extended AX role support (tables, scroll bars, custom roles)
- Configurable role allow-lists

See docs/DEVELOPMENT_PLAN.md for detailed roadmap.

---

## Version Policy

- Semver (MAJOR.MINOR.PATCH)
- Breaking JSON shape change → bump MAJOR
- New subcommand or field → bump MINOR
- Bug fix, no shape change → bump PATCH
- The orchestrator pins by git SHA until 1.0.0

---

## Testing Notes

All releases are tested against:
- Google Chrome (latest stable)
- Apple Safari (system version)
- Mozilla Firefox (latest stable)
- Canvas-based surveys (grid mode)
- Real Accessibility trees with 100+ elements

Manual test procedure in CONTRIBUTING.md.
