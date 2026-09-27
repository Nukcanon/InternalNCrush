# Internal N Crush 1.2.7 — published; post-publication tests

The user explicitly requested publishing first, then continuing remaining tests.
Windows/Web/NAS release 1.2.7 and the live website are published. Do not restore
1.1.x, the 1.2.3 recovery branch, or the older 1.2.6 source as the working baseline.

- Runtime/tag: `75ffb19e0a448d74303fdc4705f4bd2aa33b9d68` / `internal-n-crush-v1.2.7`.
- Website install: `a7246bff370dae77d17a624903512adad38b97a1`.
- Release: https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.2.7
- Live: https://nukcanon.github.io/nukcanon/internal-n-crush.html
- Read `VALIDATION_V127.md` and `PUBLICATION_STATUS.json` for current evidence.
- `VISUAL_REWORK_V127_PARTIAL.md` and all sections below are historical, not current release status.

## Current implementation and limits

Cache revision 131; distinct optional level combinations; narrower corridors;
CC0 themed materials and props; two-sided surfaces; supported decks and stairs;
brighter lighting with bounded high-quality spotlights and sun shadows; shared
operator anatomy with reduced Web geometry; hair fitting, weapon-shell and hand
shading changes; red map close button; 180-second bounded weapon drops.

49 functional groups and 490 graph routes pass, with all 32 native/Web collision
signatures equal. Exact Windows ZIP passes four rendered/connection scenarios.
The release was intentionally made public before remaining extended tests.
Record those results in VALIDATION_V127.md when finished.

Do not claim a complete AAA art overhaul, zero stutters, no leaks under all
conditions, or measured Intel/mobile performance. Short native runs still have
long frames; shutdown texture warnings persist. Intel 10–11th-gen integrated GPUs
and physical smartphones are unavailable here. The Web download is now 94.65 MB.

Preserve published assets/tag; runtime fixes require a new version, not silent
replacement of the public 1.2.7 packages. Work branch: work/v1.2.7-visual-readability.
Recovery branch: work/v1.2.3-stability-20260927. The public lobby endpoint is still
unconfigured pending owner service deployment. Source repo and site repo remain
separate; fetch before modifying and preserve unrelated output/ files.

# Historical 1.2.6 record — superseded by 1.2.7

The requested enlarged-map, map-viewer, capture-feedback and louder-announcer update is implemented and published. The user authorized deployment. Do not restart the old 1.2.6 partial work or restore 1.1.x files.

- Runtime/tag: `5d035e5586950741134bb54ba870f9f116fd96f6` / `internal-n-crush-v1.2.6`.
- [Windows / Web / NAS downloads](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.2.6).
- [Live page](https://nukcanon.github.io/nukcanon/internal-n-crush.html) / [Play](https://nukcanon.github.io/nukcanon/play/?build=11033e84d72c).
- Website runtime installation: `59a5d2563a292b064213b21eebdfc5ff8d24f7e2`; subsequent `8ac9690d906ed959f6a847a72003dca0a6e04e68` only corrects the Escape-key guide to 게임 메뉴.
- `PUBLICATION_STATUS.json` contains exact asset hashes, CI IDs and measured limits. `VALIDATION_V126.md` records the test evidence. `VALIDATION_V126_PARTIAL.md` is historical and superseded.

## Implemented in this release

31 competitive maps now have wider connected corridors, rooms, alternative routes, stairs/ramps and upper/lower levels. Exactly one rectangular footprint remains per capacity (map indices 0, 2, 8, 13, 25). General sizes: 6-player 96×108m, 8-player 120×120m, 16-player 240×240m, 32-player 360×360m. Defusal: 8-player 128×160m, 12-player 228×276m. Practice expands to 240×240m with its elevated routes preserved. Names use ordinary Korean location names.

The map viewer is available below host/bot map selection, in the equipment header, alongside the scoreboard and inside 게임 메뉴. It supports layer selection, pan, wheel/pinch zoom and a close button alongside the layer controls. Random maps show their candidates. Records remain visible. Footer actions have matching dimensions, and the free-equipment information stays in the money-box region.

Native district dressing adds building fronts, industrial doors, vehicles, boats, trees, ceilings and complete doorway rooms. Small pushable props avoid principal paths, spawns, sites and ramps. Web simplifies materials and decoration while preserving exactly the same collision geometry. Ramp corner heights and two invalid auxiliary objective positions were corrected after physical-route tests exposed them.

Capture has participant-scaled speed (1/1.5/2/2.5×), contested pause, configurable base duration (default 5 seconds), bottom-up letter/arrow fill, progress HUD and a subtle team-color floor overlay. Authoritative network announcements cover each team/site. Eleven offline-generated female voice clips replace the old announcements; gain is +10dB with bounded playback queue and output limiting. Audio provenance/license is included; no voice model runs in the game.

## Validation completed

- Final-source CI `36314671336`: all 47 functional groups, 32-client capacity, independent clients, lifecycle/late-start, movable props, rotation, touch and WebRTC; Windows/Web exports and draft packaging.
- Server CI `36315362584`: Docker Linux/TLS and Worker HTTP/WebSocket contracts. The version argument in the validation workflow was corrected separately; this does not change packaged runtime code.
- 372 objective/elevation graph routes, 21 physical vertical destinations, 48 defusal spawn exits, 32 identical native/Web collision maps, 13 contact/mantle/push assertions, 28 capture assertions.
- Exact CI Windows ZIP: practice, training and two ENet host/client variants passed, plus packaged WebRTC connection (`players=2`, `ping=7`, `snapshots=58`). The archive has 22 files including voice attribution.
- Exact Web archive: all file hashes/source pin checked; actual Chromium menu, bot combat, equipment footer and game-menu map inspected. Live Pages loads WEB / v1.2.6 with no observed startup errors. Public package/PCK audit `36316707421` passed.
- Native/Web candidate exports each completed 24 round/death/killcam cycles with no assertion failure. Warm native resources stayed at 876; Web at 823 and WASM at 100,466,688 bytes. See the validation document for measurement context.

## Limits — do not turn goals into claims

Intel 10–11th-gen iGPU, GTX960 and physical-phone performance has not been measured. Tests used RTX 4080 SUPER / Ryzen 9 7900. Short native samples still include 239–245ms maximum frames, and known GL texture warnings remain at shutdown. No multi-hour leak-free or universally stutter-free guarantee. The original 1.2.2 c0000005 crash lacks its dump and has no proven root cause. Art remains stylized; competitive balance still requires human play statistics. External multi-PC NAT/TURN is unverified.

The public lobby service still needs owner Cloudflare deployment/login; its default address remains empty. Docker/NAS and Worker implementations are tested, but GitHub Pages only hosts static game files. Do not invent a public lobby endpoint.

## Development invariants and locations

Source: `D:/python_workplace/InternalNCrush/InternalNCrush`; website: sibling `site-repository`. Fetch both remotes before work and preserve other changes. The recovery branch `work/v1.2.3-stability-20260927` must not be overwritten. Continue current main; 1.2.5 (`7a51e15`) and its documents are history.

Native `game/` and Web `web/staging/game/` share gameplay but use separately baked graphics. Never copy Web models back into native assets. `ArenaCache.REVISION` is 126. Authoring/bake tools live in `game/tools/maps/`; district specifications/data are tracked under `game/assets/arenas/`. CI rebakes both sets and compares collision signatures. Partial bakes merge signature manifests. Web retains bounded sparse GL handles and does not automatically lower resolution.

Release evidence is under ignored `validation/public-v126`, `validation/windows-v126-ci`, `validation/webrtc-v126-package`, `validation/public-web-v126` and `validation/v126-*`. Prior map-review bundles in ignored `output/` are review artifacts, not current runtime. Do not accidentally commit generated validation outputs or test entrypoints into production exports.
