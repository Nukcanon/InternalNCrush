# Latest: 1.3.5 — hitch fixes, public lobby cleanup, bot seat handover

Read `RELEASE_NOTES_V135.md` and `PUBLICATION_STATUS.json`. Sessions now use git from GitHub Desktop (`%LOCALAPPDATA%/GitHubDesktop/app-*/resources/app/git/cmd/git.exe`) and `.tools/gh` (logged in as Nukcanon).

- Hitches: held gadget/grip assemblies were rebuilt procedurally on every gadget selection (70–170 ms on every peer). `GadgetVisual`/`HeldGrip` now cache packed templates; `VisualWarmup` prepares current players' items outside combat; `Construction.prepare` builds outline meshes at map load. Render-only work (`render_update`) runs in `_process` once per frame when the engine drives physics (tests that disable physics processing still get it inline). Periodic reliable full sync sends the deflated bytes (`full_state_packed`). Measure with `game/tests/run_render_hitch.py` (+ `INC_PROFILE=1` for section costs) and `run_network_hitch.py`. Intel iGPU still unmeasured.
- Lobby: no same-network rooms; `RoomFilters.build` = search row (button/Enter) + four equal filters; `ui.quick_join_dialog` (Enter/Esc via `menu_key`); `RoomFilters.row_style` alternates rows. `menu_key` leaves Enter to a focused LineEdit.
- Bots: `TeamBalance.admit` frees a bot seat for each arriving person (balance/replacement bots first; any bot when full). LAN discovery `count` and WebRTC status `players` report people only (`bots` separately).
- Lobby worker: rooms grouped by the session's game version; `MIN_GAME_VERSION` in `services/cloudflare-directory/wrangler.jsonc` blocks older clients. `.github/workflows/deploy-lobby.yml` deploys on main pushes touching that folder (repo secrets CLOUDFLARE_API_TOKEN/ACCOUNT_ID). New game versions need no worker change.
- Site: `.github/internal-n-crush-release.json` (version/sha256/source_commit) drives `update-internal-n-crush.yml`; it installs play/, page links (template `.github/internal-n-crush-page.html`) and `internal-n-crush-version.json` (in-game update prompt). The installer is no longer pinned to 1.3.0.
- Functional suite: all groups pass. Outdated expectations from the 1.3.2–1.3.3 approved balance/UI were updated; real fixes: ANCHOR box magazine chamber, objective marker placement guard, PULSE pose sockets.

---

# Historical: 1.3.3 Windows Escape crash hotfix — work ended

Windows source `d01b920d3e459ac7e3ec3d15648bfe7ef5e1d10f` replaces the Windows ZIP in release `internal-n-crush-v1.3.3`. Native confirmation dialogs now have one Escape handler and defer window closing until input dispatch completes. Targeted native dialog lifetime checks: 20/20. Web remains at source `39bc10e`, build `2620a7173a72`; no web rebuild or deployment for this hotfix.

The user explicitly requested only this crash fix be published, all other checks skipped, and all work ended. Public lobby deployment/cross-play investigation is unfinished; default lobby URL remains empty. Temporary local directory/web servers and the test browser were stopped. Do not describe a zero-configuration public lobby as deployed. See PUBLICATION_STATUS.json for exact artifact hashes and verification limits.

---

# Latest same-version release: cursor ownership, MENDER and ammunition updates

Source `3dccae0`: alternating gray row cards, centered participant rows, expanding result list, PULSE/FOLD partial-reload exit delay with unchanged full-reload times, shotgun reserves 50 and rocket reserves 20, MONOLITH total 24 and SCOUT total 36, MENDER 80 RPM with PULSE reload, native cursor ownership and menu keyboard fixes, automatic ammo salvage and 10% owned consumable gadget refill. Native/Web exported; Windows pointer regression passed 11 checks. PUBLICATION_STATUS.json has current source and assets.

# Latest same-version release: roster, voting and shell reloads

Source `adbd03f`: shared paired roster rows, host team/bot management, 15-second kick vote with 9/0 keys, chamber ammo pips, per-shell PULSE/FOLD reloads, mobile map button and surface contrast. Native/Web exported; no additional gameplay tests requested. PUBLICATION_STATUS.json has current source and assets.

# Latest approved update (same 1.3.2)

Source `8da1489`: Restored full detailed cover assemblies with tier paint/depth; compact paired team cells with visible single-line names; important notices visible over menus; armor gauge maximum remains 75. Published native/Web; exports completed, no gameplay tests by request. Latest includes weapon range changes: ANCHOR 75–160 m, BASTION 85–180 m; shotguns x3/x2.5; ordinary rifles/SMGs/pistols/medic carbine x2/x1.9; snipers/DMRs x1.1. Native cursor capture now checks open menus and window focus, including respawn while Alt-Tabbed. Current links in PUBLICATION_STATUS.json. Older entries below remain historical.

# Latest approved update (same 1.3.2)

Source `d8862fd`: QUAD/COMET balance, three separate assault plates, tier-colored cover thickness, passive gadget HUD, uniform human/bot team rows and separated combat/menu notifications. Published native/Web; exports completed, no gameplay tests by request. Current links in PUBLICATION_STATUS.json. Older entries below remain historical.

# Latest publication: 1.3.2 same-version update

Source `9e781e5` is deployed. Web: https://nukcanon.github.io/nukcanon/play/?build=800346d668c1 . See PUBLICATION_STATUS.json and docs/V132_HOTFIX.md. Latest UI and ARC updates exported and published; additional game tests explicitly skipped by user. Earlier test results below are historical. Version-history Word document delivered locally under artifacts/version-history (36 release entries, 30 pages).

---

# Latest publication: 1.3.1 (2026-09-28)

Source `0bb5cce` is published on main and in release `internal-n-crush-v1.3.1`. Website: https://nukcanon.github.io/nukcanon/play/?build=91550bc6ec27 . Current evidence is in `PUBLICATION_STATUS.json`, `docs/COMBAT_AUDIO_REFRESH.md`, and `docs/v131-performance.json`; older notes below are historical. Arena cache revision is 141. User-approved MP3 vocal alternatives are included; default setting remains off. Do not replace them with the rejected shouting take. No public directory endpoint or Intel iGPU hardware result is claimed.

---

# Published 1.3 — current checkpoint

1.3 is live. Runtime source `ba0da924851739a9a7aec1e34c18ce47271419b1`, release `internal-n-crush-v1.3.0`, public Web build `e777495bdc55`. Read `V13_VALIDATION.md`, `PUBLICATION_STATUS.json` and `RELEASE_NOTES_V13.md` before older notes below.

Added 40 ceiling + 40 roof + 20 soffit finishes and paired normals; straight material boundaries; roof/terrain seams; original scopes/reticles; browser lock-state sync; pending-settings confirmation; knife/pistol room rules. All 32 geometry audits pass; final spawn filtering removes dressing-obstructed candidates. Native/Web 24-cycle probes pass with bounded resources. See measured frame costs and remaining startup spikes / shutdown warnings in the validation report. Physical Intel/mobile and ordinary-browser Alt+Tab checks remain unavailable. Full CI 36375283761 passed, including all 52 functional groups, 32-client capacity, network lifecycle/props/rotation, touch/WebRTC and Windows/Web exports. Targeted rendering, publication hashes and 24-round probes also passed.

Do not overwrite unrelated `output/` or `game/tools/inspect_character_source.py`. All older sections are historical, not current completion claims.

---

# Published 1.2.8 material hotfix — current checkpoint

Source build `61ef2b4be90332b9df1b11fa7144ab165ffa41ce`; release
`internal-n-crush-v1.2.8-hotfix.1`. Native and Web are published and Pages
checksums verified. Read `PUBLICATION_STATUS.json` and `HOTFIX_V128_MATERIALS.md`
for exact validation and limitations. Prior sections below are historical.

Current patch adds200 set-dressing designs,40 windows,30 trees,100 building
materials, normal-map shaders and automatic quality in both versions.
Native/Web24-cycle soaks passed; all49 functional groups passed locally.
Remaining limitations: two native shutdown texture warnings; warm-up/occasional
frame spikes; physical Intel iGPU/mobile testing unavailable. This patch does
not claim completion of the historical character replacement request.
Preserve unrelated `output/` and `game/tools/inspect_character_source.py`.

---

# Active 1.2.8 publication work — latest checkpoint

User authorized publishing before extended performance/soak tests, then reporting measured impact. Branch work/v1.2.8-districts-mobile. The first 32-prop snapshot 1fa10b6 passed CI 36361431769, but subsequent expanded changes require fresh builds and checks.

210 original Blender models are generated: 32 district props, 118 furnished props, 30 transport, 30 doors. Functional doors, sea/river logic, macro material variation and native automatic graphics are implemented locally. Catalogue generation is not placement coverage. Native auto test passes; final map caches are being rebuilt at revision 135 after fixing coastal generation order. Public site remains 1.2.7 until publication is confirmed. Earlier notes below are historical and must not be read as current completion claims.

Remaining: finish final build, basic route/startup verification, publish current packages, then native/Web rendered performance and memory tests. Record exact commit/hashes and device limits. Character replacement is still not integrated. Preserve unrelated output/ and inspect_character_source.py.

---

# Current work: 1.2.8 candidate, not yet published

Work continues on `work/v1.2.8-districts-mobile`. Read
`VALIDATION_V128_PARTIAL.md` and `RELEASE_NOTES_V128.md` first. 32 original Blender
props are built, rendered and integrated; editable sources and inventory are in
`art_source/`. Native/Web final 32-map state and physics signatures match.
31-map navigation check passes 508/508, mobile regression 43/43, gesture and
pinch tests pass. Full functional pass initially found five regressions; all five
were corrected and passed targeted reruns. Native 12-cycle effects stress test
passes, but release packaging, browser soak and hardware limits remain.

Latest user instruction: after finishing the current work, expand to **more than
200 distinct prop types** and place them appropriately. Do not count colour-only
duplicates. Sea maps need recognizable sea/coast and fatal immersion; rivers need
shallow visible water/riverbeds and must not kill players merely for entering.
These additions have not been implemented yet. Existing water uses shallow
interior polygons; do not misrepresent it as a completed sea system.

Additional user instruction: make about **30 vehicle/vessel types** with distinct
sizes and purposes, included in the 200+ catalogue. Use sea-appropriate boats at
coasts/ports and small shallow-draft boats in rivers. Include cars and trucks;
place with plausible scale, waterline and road/berth clearance. Still pending.

Latest steering expands the follow-up to every existing map: reduce obvious
texture repetition, increase environmental colour saturation without obscuring
players, and use purpose-specific floor/wall/door materials per room/district.
Add about **30 door types**, included in 200+, with actual usable doors connecting
interior combat spaces and alternative routes. Do not place decorative doors in
solid walls and imply they are usable. Current quadrant material variations are
not a completed implementation of this broader room-based renewal.

## Published baseline: 1.2.7

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
The release was intentionally made public before extended tests. Those tests now
pass: Windows and Web each completed 24 rendered round/death/killcam cycles; exact
Windows ZIP ENet and WebRTC checks passed. CI 36322990615 passed all 49 functional
groups, 32-client capacity, lifecycle/late-start, props, rotation, touch and RTC
steps; its independent Web rebuild/upload is still in progress at this checkpoint.
Do not call the entire CI workflow successful until its final result is checked.

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

## Latest: 1.3.2 published
Source d4dfca97ed492c8adf12b6afa838e0612089d27c; Pages 8f8eec295b3f37cbdf7029a4c16e33f7ea48d877. Latest user balance is ARC 60→120 DPS. See docs/V132_HOTFIX.md, docs/v132-validation.json, PUBLICATION_STATUS.json. User requested publish first, then checks: completed focused mobile/reload 15, bot 12 (three respawns), combat 59 and 32-player native low/high timing. Public critical hashes and Web v1.3.2 menu verified. No physical mobile/Intel iGPU measured.
