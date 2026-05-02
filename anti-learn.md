# anti-learn.md — ANTI-PATTERNS für skylight-cli

## ❌ Koordinaten raten (--x --y)

**FALSCH**:
```bash
skylight-cli click --pid X --x 500 --y 300
```
**PROBLEM**: Chrome-Fenster verschiebt sich, Layout ändert sich, Pixel-Density anders.
**RICHTIG**: `skylight-cli click --pid X --element-index Y`

## ❌ Cached Index über Page-Transition hinweg

**FALSCH**: Index 42 von vorheriger Seite merken → wiederverwenden.
**PROBLEM**: Neue Seite = neues DOM = neue Indices.
**RICHTIG**: Nach jedem Klick neu scannen: `skylight-cli list-elements --pid X`.

## ❌ skylight-cli in Popups

**FALSCH**: `skylight-cli list-elements` nach Google OAuth (Popup offen).
**PROBLEM**: skylight-cli sieht NUR das Hauptfenster. Popup ist unsichtbar.
**RICHTIG**: `cua-driver call get_window_state '{"pid":X,"window_id":W}'` für Popups.

## ❌ Ohne VoiceOver Accessibility nutzen

**FALSCH**: Direkt `list-elements` aufrufen ohne Accessibility-Check.
**PROBLEM**: Leere Liste → kein Klick möglich.
**RICHTIG**:
```bash
osascript -e 'tell application "VoiceOver" to launch' && sleep 2
osascript -e 'tell application "VoiceOver" to quit'
```

## ❌ list-elements in schnellem Loop (ohne Motion Detection)

**FALSCH**: Alle 100ms `list-elements` aufrufen.
**PROBLEM**: ~200-500ms pro Call → 50% CPU verschwendet.
**RICHTIG**: LiveEye Motion Detection → nur bei echter Bewegung neu scannen.

## ❌ RAW mode für Omni Vision

**FALSCH**: `skylight-cli screenshot --mode raw` → 300KB+ PNG an API.
**PROBLEM**: API-Timeout → Vision-Fail.
**RICHTIG**: `skylight-cli screenshot --mode som` → 67KB JPEG → <1s roundtrip.

## ❌ type ohne list-elements davor

**FALSCH**: `skylight-cli type --pid X --element-index 55 --text "München"` (Index nicht verifiziert).
**PROBLEM**: Index zeigt auf Button, nicht TextField → Klick statt Tippen.
**RICHTIG**: Erst `list-elements`, Index verifizieren, dann `type`.

## ❌ hold ohne hold-Support prüfen

**FALSCH**: `skylight-cli hold --pid X --element-index Y` ohne zu wissen ob hold unterstützt.
**PROBLEM**: Manche Elemente unterstützen hold nicht.
**RICHTIG**: Erst `list-elements` → prüfen ob Element `holdable` ist.

## ❌ Blind klicken ohne Vision-Gate

**FALSCH**: `skylight-cli click --pid X --element-index Y` ohne Omni-Prompt davor.
**PROBLEM**: Falsches Element → DQ → Zeit verloren.
**RICHTIG**: Erst `python3 runner/step.py` → Omni sagt Index → execute → verify.