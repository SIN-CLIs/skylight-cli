# brain.md — skylight-cli v0.2.0 (EXPERIMENTAL)

> **Status:** AXPress-Click funktioniert. 25 Issues offen. Nicht production-ready.
> **Letzter Commit:** `6752562` — XCTest target + Utils/version unit tests

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

## Commands (alle funktionsfähig getestet)
- `screenshot --pid PID --mode som --include-tree`
- `click --pid PID --element-index N`
- `hold --pid PID --element-index N --duration 3000` (Cloudflare Turnstile)
- `list-elements --pid PID`
- `get-window-state --pid PID`

## Bekannte Einschränkungen (25 offene Issues)
- #51: hold command — implementiert, nicht live getestet
- #52: multi-window — mehrere Fenster nicht sauber unterschieden
- #55: SIGINT — kein sauberes Signal-Handling
- #68: OCR hand-vs-brain — Strategie ungeklärt
- #69: Reconcile #3↔#5 — Architekturentscheidung offen
- #70: production-ready-Lüge — Doku behoben durch dieses Update
- #71: CHANGELOG-Sync — fehlt
- #72: handoff.md-Sync — fehlt
- #73: LICENSE — MIT, committed
- #74: v0.2.0 Tag — fehlt
- #75: Brew Tap — fehlt
- #77: Unit Tests (1→15+) — in Planung
- #78 (neu): CodeQL Badge — fehlt

## NIEMALS
- `--x`/`--y` Koordinaten raten
- `CGEventPostToPid` — TOT auf Chrome 148
- `cua-driver` — ersetzt
