# brain.md — skylight-cli v0.2.0 (EXPERIMENTAL)

> **Status:** AXPress-Click funktioniert. 22 Issues offen. Nicht production-ready.

## Klick-Mechanismus
AXUIElementPerformAction(element, kAXPressAction) — CGEventPostToPid ist TOT auf Chrome 148/macOS 26.

## Voraussetzung: Chrome Accessibility
VoiceOver 1x kurz starten -> Chrome aktiviert AX-Tree -> VoiceOver stoppen -> Tree bleibt.

## Architektur
skylight-cli ist der ACT-Layer: playstealth-cli (HIDE) -> skylight-cli (ACT) -> unmask-cli (SENSE)

## Commands (alle funktionsfaehig)
screenshot, click, hold, list-elements, get-window-state

## NIEMALS
--x/--y Koordinaten raten, CGEventPostToPid (TOT), cua-driver (ersetzt)
