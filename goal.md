# goal.md — skylight-cli

## skylight-cli
Stateless macOS CLI for stealth browser automation.
Part of the SIN-CLIs stealth triad:
```
unmask-cli (sense) → playstealth-cli (think) → skylight-cli (act)
```

## Core Features
- Screenshot with Set-of-Marks (SoM) overlay
- Click by element-index or label (via AXPress, CGEventPostToPid broken on Chrome 148)
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
