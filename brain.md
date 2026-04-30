# brain.md — skylight-cli v0.2.1

> **macOS CLI für Screenshots + Klicks via Accessibility API (AXPress)**

## Klick-Mechanismus
```swift
AXUIElementPerformAction(element, kAXPressAction as CFString)
```
CGEventPostToPid ist TOT auf Chrome 148/macOS 26. Nur AXPress funktioniert.

## Voraussetzung: Chrome Accessibility
VoiceOver 1× kurz starten → Chrome aktiviert AX-Tree → VoiceOver stoppen → Tree bleibt.
Kein `--force-renderer-accessibility` Flag nötig (crasht Chrome auf macOS 26).

## Architektur
skylight-cli ist der ACT-Layer der Stealth-Triade:
- `playstealth-cli` (HIDE) → `skylight-cli` (ACT) → `unmask-cli` (SENSE)

## Commands
- `screenshot --pid PID --mode som --include-tree`
- `click --pid PID --element-index N`
- `hold --pid PID --element-index N --duration 3000`
- `list-elements --pid PID`
- `get-window-state --pid PID`

## NIEMALS
- `--x`/`--y` Koordinaten raten
- `CGEventPostToPid` — ignoriert von Chrome 148
- `cua-driver` — ersetzt
