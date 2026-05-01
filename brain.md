# brain.md - Systemwissen (2026-05-01)

## skylight-cli Kern
- **Tech:** Swift, macOS Accessibility API (AXUIElementPerformAction)
- **Primer:** `skylight-cli click --pid <PID> --x -1 --y -1` (Chromium user-activation gate)
- **NUR `--element-index`** – keine Mauskoordinaten!
- **Output:** Ein JSON-Objekt pro Befehl auf stdout
- **Fehler:** Exit-Codes 0-5, JSON auf stderr

## Integration
- playstealth-cli → Chrome mit PID
- stealth-runner → orchestriert via LiveOmniMonitor
- Nemotron Omni → liefert element_index via NIM API

## Graphify
- 120 nodes, 19 communities
- `graphify update .` nach Code-Änderungen
