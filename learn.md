# learn.md — KRITISCHE Learnings für skylight-cli

## 🔑 IMMER element-index, NIE Koordinaten!

**FALSCH**: `skylight-cli click --x 500 --y 300` — Koordinaten raten.
**RICHTIG**: `skylight-cli click --pid X --element-index Y` — AX-Accessibility.
→ Chrome-Fenster verschiebt sich, Layout ändert sich. Koordinaten sind unstable.

## 🔑 Index NACH Page-Transition neu scannen!

Nach jedem Klick: neue Seite → neues DOM → **neue Indices**.
**FALSCH**: Cached Index 42 von der alten Seite.
**RICHTIG**: Nach jedem Klick `skylight-cli list-elements --pid X` → neuen Index finden.

## 🔑 skylight-cli NUR für Hauptfenster!

**FALSCH**: skylight-cli nach Google OAuth Klick (Popup geöffnet).
**PROBLEM**: skylight-cli cached NUR das Hauptfenster. Popup-Elemente sind unsichtbar.
**RICHTIG**: `cua-driver call get_window_state '{"pid":X,"window_id":W}'` für Popups.

→ Siehe `stealth-runner/docs/TOOL-ROLES.md`

## 🔑 Chrome PID muss stabil sein

Nach Page-Transition: gleiche PID. Nach Tab-Wechsel: gleiche PID.
Aber nach `playstealth launch`: neue PID → neu scannen.

## 🔑 Screenshot modes: som > raw für API

`som` mode (Semantic Overlay): komprimiert, 67KB JPEG.
`raw` mode: volle Auflösung, 300KB+ PNG → API-Timeout.
→ SOM für Omni Vision, RAW nur für Debug.

## 🔑 TextField vs Button — unterschiedliche Indices!

Ein Button bei Index 42 und ein TextField bei Index 42 sind **nicht dasselbe**.
Immer `list-elements` nutzen um den richtigen Index für den richtigen Element-Typ zu finden.

## 🔑 hold für Slider/Dropdown

Slider-Questions (Skala 1-10) → `hold` statt `click`:
```bash
skylight-cli hold --pid $PID --element-index 30
```
→ Zieht den Slider, wartet auf release.

## 🔑 VoiceOver Accessibility aktivieren (EINMALIG)

Falls `list-elements` leer zurückgibt:
```bash
osascript -e 'tell application "VoiceOver" to launch' && sleep 2
osascript -e 'tell application "VoiceOver" to quit'
```
Oder: `chrome://accessibility` → "Suppress automatic" deaktivieren.

## 🔑 AXWebArea Title = Page-Identifier

Das erste Element mit `AXWebArea` in path zeigt den Seitentitel:
- "HeyPiggy" → Dashboard
- "PureSpectrum" → Externer Survey-Panel
- "Toluna" → Externer Survey-Panel
- "Google" → OAuth Popup

→ In state speichern → an Omni prompt übergeben.

## 🔑 list-elements ist teuer (bei häufigem Aufruf)

Jeder list-elements Call braucht ~200-500ms.
In LiveEye: nur wenn Motion-Detection high/mid.
In Step: nach jedem click → neu scannen (nötig).
→ Nicht in loop ohne Grund aufrufen.