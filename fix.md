# fix.md — Alle Bugs gefixed (Experimental, 25 Issues offen)

| # | Bug | Symptom | Fix | Commit |
|---|-----|---------|-----|--------|
| 1 | cua-driver | Agent nutzt altes Tool | Referenzen entfernt | efd363f |
| 2 | open -na Chrome | Kein Stealth | playstealth-cli launch | efd363f |
| 3 | AXStaticText click | Keine Navigation | Nur interaktive Rollen | efd363f |
| 4 | Kein Vision vor Klick | Blindes Raten | VisionClient.get_action() | efd363f |
| 5 | Kein unmask-cli | Keine Verification | verify_stealth() | 77581cf |
| 6 | ask_vision() hängt | Keine Koordinaten | ask_vision_text() intern | 0b72d2e |
| 7 | Lesezeichen-Klicks | Chrome-UI | validate_click_coordinates() | 987e862 |
| 8 | AX-Tree-Kollaps | 0 Elemente | _AXObserverAddNotification | 2ea1ee6 |
| 9 | Canvas UIs | 70-80% Präzision | VNRecognizeTextRequest | f7b1f31 |
| 10 | hold fehlt | Turnstile unlösbar | Hold.swift implementiert | d860e78 |
| 11 | LICENSE fehlt | rechtlich angreifbar | MIT LICENSE committed | — |
| 12 | XCTest Target | keine Unit Tests | Package.swift + Tests | 6752562 |

## Status: 25 Issues offen. AXPress-Click funktioniert. Nicht production-ready.
