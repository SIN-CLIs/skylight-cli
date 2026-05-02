# commands.md — skylight-cli CLI-Befehle

## Installation & Voraussetzung

```bash
# Binary (bereits installiert)
which skylight-cli
# → /Users/jeremy/.local/bin/skylight-cli

# Voraussetzung: Chrome Accessibility aktivieren (EINMALIG)
osascript -e 'tell application "VoiceOver" to launch' && sleep 2
osascript -e 'tell application "VoiceOver" to quit'
# Falls keine Elemente: chrome://accessibility → "Suppress automatic" deaktivieren
```

## ⚠️ WICHTIG: skylight-cli NUR für Hauptfenster!

skylight-cli cached NUR das **Hauptfenster**.
Für **Popups** (Google OAuth, Consent) → cua-driver nutzen!

→ Siehe `stealth-runner/docs/TOOL-ROLES.md`

## chrome_pid finden

```bash
# Isolierte Chrome-Instanz
playstealth launch --url 'https://heypiggy.com/?page=dashboard'
PID=$!  # oder:

# Bestehende Chrome PID
PID=$(pgrep -f "Google Chrome.app/Contents/MacOS/Google Chrome$" | head -1)
echo "Chrome PID=$PID"
```

## Screenshot (schnellster Read)

```bash
# SOM mode (Semantic Overlay — komprimiert)
skylight-cli screenshot --pid $PID --mode som --output /tmp/page.png

# RAW mode (volle Auflösung)
skylight-cli screenshot --pid $PID --mode raw --output /tmp/page_raw.png

# Mini mode (thumbnail)
skylight-cli screenshot --pid $PID --mode mini --output /tmp/page_mini.png
```

## Elements scannen (Interaktions-Vorbereitung)

```bash
# Alle interagierbaren Elements
skylight-cli list-elements --pid $PID

# Elemente mit Label filtern
skylight-cli list-elements --pid $PID | python3 -c "
import json,sys
for e in json.load(sys.stdin)['elements']:
    l=e.get('label','')
    if 'Umfrage' in l or '€' in l or 'starten' in l:
        print(f'[{e[\"index\"]}] {e[\"role\"]}: {l[:80]}')
"

# Nur Buttons und Links
skylight-cli list-elements --pid $PID | python3 -c "
import json,sys
for e in json.load(sys.stdin)['elements']:
    if e.get('role','') in ('AXButton','AXLink'):
        print(f'[{e[\"index\"]}] {e.get(\"label\",\"\")[:60]}')
"
```

## Klicken (NUR element-index — NIEMALS Koordinaten!)

```bash
# Klick auf Button/Link (element-index aus list-elements)
skylight-cli click --pid $PID --element-index 42

# WICHTIG: Index nach Page-Transition neu scannen!
# Nach jedem Klick → neue Seite → neue Indices!
```

## Text eintippen (TextField/TextArea)

```bash
# Text in Eingabefeld eintippen
skylight-cli type --pid $PID --element-index 55 --text "München"

# WICHTIG: Erst list-elements, dann type!
# TextField-Index ≠ Button-Index
```

## Hold (Drag-Function für Slider/Dropdown)

```bash
# Element halten (für Slider oder Dropdown)
skylight-cli hold --pid $PID --element-index 30
# → Hält das Element, wartet auf release
```

## Page Detection (welche Seite?)

```bash
# Aktuelle URL
skylight-cli current-url --pid $PID

# Page-Typ erkennen (aus AXWebArea label)
skylight-cli list-elements --pid $PID | python3 -c "
import json,sys
data=json.load(sys.stdin)
for e in data.get('elements',[]):
    if 'AXWebArea' in e.get('path',''):
        print(f'Title: {e.get(\"label\",\"\")[:100]}')
"
```

## Workflow: Survey starten (komplettes Beispiel)

```bash
PID=$(pgrep -f "Google Chrome.app/Contents/MacOS/Google Chrome$" | head -1)

# 1. Dashboard scannen
echo "=== Dashboard Elements ==="
skylight-cli list-elements --pid $PID | python3 -c "
import json,sys
for e in json.load(sys.stdin)['elements']:
    l=e.get('label','')
    if 'AXWebArea' in e.get('path',''):
        print(f'Title: {l[:80]}')
    elif e.get('role') in ('AXButton','AXLink'):
        print(f'  [{e[\"index\"]}] {e[\"role\"]}: {l[:60]}')
"

# 2. Survey klicken (Index 42 = "Umfrage starten")
skylight-cli click --pid $PID --element-index 42
sleep 3

# 3. Neuer Tab: URL prüfen
skylight-cli current-url --pid $PID

# 4. Neue Elements scannen (Page gewechselt!)
skylight-cli list-elements --pid $PID | python3 -c "
import json,sys
for e in json.load(sys.stdin)['elements']:
    if e.get('role') in ('AXButton','AXLink','AXRadioButton','AXTextField'):
        print(f'[{e[\"index\"]}] {e[\"role\"]}: {e.get(\"label\",\"\")[:60]}')
"
```

## Integration mit Stealth-Quad

```bash
# Mit stealth-runner step orchestrator
PYTHONPATH=~/dev/stealth-runner python3 runner/step.py "https://heypiggy.com/?page=dashboard"

# Mit live-eye (Omni Vision)
PYTHONPATH=~/dev/stealth-runner python3 runner/live_eye.py

# Mit cua-driver (Popups)
cua-driver serve &
cua-driver call list_windows '{}'
```