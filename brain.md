# brain.md — skylight-cli

## skylight-cli
Stateless macOS CLI for stealth browser automation.
Part of the SIN-CLIs stealth triad:
```
unmask-cli (sense) → playstealth-cli (think) → skylight-cli (act)
```

## Core Features
- Screenshot with Set-of-Marks (SoM) overlay
- Click by element-index or label (no cursor stealing via CGEventPostToPid)
- Window state inspection (AX tree, URL, geometry)
- Primer click for Chromium user-activation gate
- JSON stdout contract with exit codes 0-5

## Integration
- Used by stealth-runner via StealthExecutor
- Replaces CDP-based bridge in A2A-SIN-Worker-heypiggy
- See GitHub Epic #41 for v1.0 roadmap

## Version: 0.2.0
## Minimum macOS: 12.0+
## Language: Swift 5.9+

## Update: Issue #76 Gaps geschlossen

### Gap #3 Fixed: AX-Tree-Kollaps (`2ea1ee6`)
- Private SPI `_AXObserverAddNotificationAndCheckRemote` aus HIServices.framework
- Verhindert, dass Blink den AX-Tree pausiert wenn Fenster verdeckt ist
- `enrollAXTreeWakeup(pid:)` in `AXElementFinder.swift`

### Gap #2 Fixed: OCR-Grounding (`f7b1f31`)
- Neue Datei: `OCRGrounding.swift` — Apple Vision `VNRecognizeTextRequest`
- Neuer Mode: `skylight-cli screenshot --mode ocr`
- Drei-Schicht-Resilienz: SoM → Grid → OCR
- Revision 3 (SOTA): `VNRecognizeTextRequestRevision3`

## Docs: fix.md + issues.md
- fix.md: 8 Bugs behoben (Tabelle aller Fixes mit Commits)
- issues.md: Alle Issues per Repo (Tabelle mit Status)

## v0.2.0 Build Status
- Compiled: `swift build -c release` ✅
- Installed: `~/.local/bin/skylight-cli`
- 90+ AX elements found on HeyPiggy.com
- Web content detection: AXWebArea, AXStaticText, AXButton, AXLink
