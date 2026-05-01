# fix.md — Alle Bugs gefixed (Experimental)

| # | Bug | Symptom | Fix | Commit |
|---|-----|---------|-----|--------|
| 1 | cua-driver | Agent nutzt altes Tool | Entfernt | efd363f |
| 2 | open -na Chrome | Kein Stealth | playstealth-cli launch | efd363f |
| 3 | AXStaticText click | Keine Navigation | Nur interaktive Rollen | efd363f |
| 4 | Kein Vision vor Klick | Blindes Raten | VisionClient | efd363f |
| 5 | Kein unmask-cli | Keine Verification | verify_stealth() | 77581cf |
| 6 | ask_vision() hängt | Keine Koordinaten | ask_vision_text() | 0b72d2e |
| 7 | Lesezeichen-Klicks | Chrome-UI | validate_click_coordinates() | 987e862 |
| 8 | AX-Tree-Kollaps | 0 Elemente | _AXObserverAddNotification | 2ea1ee6 |
| 9 | Canvas UIs | 70-80% Präzision | VNRecognizeTextRequest | f7b1f31 |
| 10 | hold fehlt | Turnstile unlösbar | Hold.swift | Hold.swift |
| 11 | LICENSE fehlt | Rechtlich | MIT LICENSE | - |
| 12 | XCTest Target | Keine Unit Tests | Package.swift + Tests | 6752562 |

## Status: 22 Issues offen. AXPress-Click funktioniert. Nicht production-ready.
