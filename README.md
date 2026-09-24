# Internal N Crush 1.0.4

Windows tactical FPS with six operators, 31 competitive arenas and an outdoor practice range. Godot 4.4.1, shared authoritative gameplay for LAN and self-hosted internet rooms.

| Platform | Start here | Contents |
|---|---|---|
| Windows players / builds | [windows/](windows/README.md) | Download, launch and local export script |
| Docker Linux / NAS operators | [nas/](nas/README.md) | Compose, Caddy HTTPS/WSS and environment example |
| Shared game source | [game/](game/README.md) | Gameplay, models, arenas and tests |
| Shared lobby service | [services/matchmaker/](services/matchmaker/README.md) | API, allocator and Docker image source |

[Play and download](https://nukcanon.github.io/nukcanon/internal-n-crush.html) · [Releases](https://github.com/Nukcanon/InternalNCrush/releases) · [Request status](game/docs/REQUEST_STATUS.md) · [Validation](game/docs/TEST_REPORT.md) · [Handoff](CODEX_HANDOFF.md)

Source moved from Nukcanon/nukcanon into this dedicated repository. The website keeps its original address. Windows and NAS share gameplay source; they are not independent copies to maintain. A NAS deployment needs an operator-provided domain/server. GitHub Pages does not host live game rooms.

Geometry, animation and audio generators, redistribution notices and [art provenance](game/docs/ART_SOURCES.md) are included. Models and audio are rebuilt by CI.
