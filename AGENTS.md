# AGENTS.md – skylight-cli

## Voraussetzung: Chrome Accessibility (VoiceOver-Trick)
```bash
osascript -e 'tell application "VoiceOver" to launch' && sleep 2
# Einmalig: chrome://accessibility → "Suppress automatic" deaktivieren
osascript -e 'tell application "VoiceOver" to quit'
# Nur einmal nötig. Danach sind Web-Elemente im AX-Tree.
```

## Screenshot: `skylight-cli screenshot --pid PID --mode som --include-tree`
## Klick: `skylight-cli click --pid PID --element-index N`
## Type: `skylight-cli type --pid PID --element-index N --text "Hallo Welt"`
## Primer (MUSS): `skylight-cli click --pid PID --x -1 --y -1`
## Hold (Cloudflare): `skylight-cli hold --pid PID --element-index N --duration 3000`

## ❌ NIEMALS
- --x/--y raten (Apple-Menü bei 0,0)
- --force-fallback (gibt's nicht mehr)
- Chrome-UI klicken
- AXStaticText klicken
- CGEventPostToPid (Chrome 148 ignoriert es)
## 🔗 Stealth-Triade
- **Orchestrator:** [stealth-runner](https://github.com/OpenSIN-AI/stealth-runner)
- **HIDE:** [playstealth-cli](https://github.com/SIN-CLIs/playstealth-cli)
- **SENSE:** [unmask-cli](https://github.com/SIN-CLIs/unmask-cli)
- **Archiv:** [heypiggy-worker](https://github.com/OpenSIN-AI/A2A-SIN-Worker-heypiggy)
