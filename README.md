# Internal N Crush 1.2.8

Continued from the published 1.2.2 source and the preserved 1.2.3 recovery branch. See [release notes](RELEASE_NOTES_V128.md), [validation](VALIDATION_V127.md), and [publication status](PUBLICATION_STATUS.json) for changes and exact delivery status.

Windows / Web tactical FPS with six operators, 31 competitive arenas and a four-level outdoor practice range. Godot 4.4.1. The player hosting a room runs the authoritative game; the lightweight lobby only provides room discovery and WebRTC signaling.

| Directory | Purpose |
|---|---|
| [game/](game/README.md) | Shared gameplay/physics/tests and detailed Windows assets; Web graphics are baked separately |
| [windows/](windows/README.md) | Windows launcher, export and packaged-EXE validation |
| [web/](web/README.md) | Single-thread browser export for GitHub Pages, mobile touch controls |
| [nas/](nas/README.md) | Linux/NAS Docker setup wizard, HTTPS proxy and operations |
| [services/directory/](services/directory/README.md) | Lightweight Python room directory; no game processes |
| [services/cloudflare-directory/](services/cloudflare-directory/README.md) | Optional free Workers/SQLite Durable Object deployment |
| services/matchmaker/ | Legacy 1.0.x dedicated-room allocator, retained for reference; not used by the new deployment |
| .github/workflows/ | Build and validation automation |

[Play / download](https://nukcanon.github.io/nukcanon/internal-n-crush.html) · [Releases](https://github.com/Nukcanon/InternalNCrush/releases) · [Handoff](CODEX_HANDOFF.md) · [Publication status](PUBLICATION_STATUS.json)

Windows LAN uses local UDP discovery. Browser LAN and mixed Windows/Web rooms use the WebRTC-compatible lobby, scoped to the same external network address. Internet rooms use the same encrypted transport. Restrictive NAT may require an operator-provided TURN server. GitHub Pages hosts static game files, not a live room directory. Cloudflare deployment requires the owner's account; an unverified server address is never filled in automatically.

The browser detects mobile/coarse touch devices and enables floating movement, aim, fire, reload and ability controls. Desktop uses keyboard/mouse. Real-device and WAN results are recorded separately from local tests in the handoff.

Source was moved from `Nukcanon/nukcanon/games/relaystrike` to this repository's `game/`. Historical filenames and wire compatibility tokens are preserved where needed. Asset origins and licenses are included; no MakeHuman application code is shipped.

요청별 반영 내용과 남은 범위: [1.2.3 한국어 확인표](V123_REQUEST_AUDIT.md).

1.2.4 추가 요청과 확인 범위: [한국어 확인표](V124_REQUEST_AUDIT.md) · [성능·안정성 측정 설명](PERFORMANCE_V124_KO.md).
