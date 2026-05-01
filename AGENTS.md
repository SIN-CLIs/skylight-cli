# AGENTS.md – skylight-cli

**ACT** component of Stealth Quad: AXUIElementPerformAction via macOS Accessibility API.
NUR `--element-index` – keine Koordinaten, keine Mausbewegung.

## CLI
```bash
skylight-cli screenshot --pid <PID> --mode som --output /tmp/step.png
skylight-cli list-elements --pid <PID>
skylight-cli click --pid <PID> --element-index <N>
skylight-cli type --pid <PID> --element-index <N> --text "wert"
skylight-cli hold --pid <PID> --element-index <N> --duration 3000
```

## Primer (MUSS vor jedem Klick)
```bash
skylight-cli click --pid <PID> --x -1 --y -1
```

## 🔗 Stealth-Quad
- **Orchestrator:** [stealth-runner](https://github.com/OpenSIN-AI/stealth-runner)
- **HIDE:** [playstealth-cli](https://github.com/SIN-CLIs/playstealth-cli)
- **SENSE:** [unmask-cli](https://github.com/SIN-CLIs/unmask-cli)
- **VERIFY:** [screen-follow](https://github.com/SIN-CLIs/screen-follow)
- **Vision:** NVIDIA Nemotron 3 Nano Omni → liefert element_index via NIM API

## ❌ NIEMALS
- `--x`/`--y` raten (Apple-Menü bei 0,0!)
- `pgrep Chrome` – Nutzer-Chrome stören
- webauto-nodriver – BANNED
- Ohne Primer klicken

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
