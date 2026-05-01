# handoff.md – skylight-cli
## Architektur
Swift 5.9+ (SPM), AXPress (Accessibility API), CGEvent.post fallback.
Build: swift build -c release | Install: cp .build/release/skylight /usr/local/bin/skylight-cli
## Voraussetzungen
macOS ≥ 13, SIP deaktiviert, Accessibility für Terminal, VoiceOver 1x starten (Cmd+F5)
## Offene Issues
22 open (#43-#75). Subcommands: scroll, drag, hover, double-click.
