# Internal N Crush 1.2.6 — published, 2026-09-27

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
