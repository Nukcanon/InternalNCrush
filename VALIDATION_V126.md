# 1.2.6 validation

Published runtime: `5d035e5586950741134bb54ba870f9f116fd96f6`. Final Windows/Web/NAS archives and live-site delivery have been verified.

## Completed local checks

- All 47 functional groups passed across the complete run and the focused objective rerun. The initial v05/v06 failures revealed invalid auxiliary midpoint objectives on two defusal maps; these were moved onto authored walkable ground and both groups reran successfully (128/128 and 77/77).
- Shared district navigation: 372/372 objective/elevation routes. Physical bot movement: 21/21 ground, basement, upper-floor and practice destinations. Defusal spawn exits: 48/48 across both teams and sides.
- Ramp corner wedges now interpolate vertex heights instead of using one centroid height. This removes the physical step that blocked the old district-7 traversal.
- Native/Web: all 32 baked maps have identical collision triangle data, transforms, spawn points, objectives, walk surfaces and navigation blockers. Separate graphics do not change cover or movement.
- Movement contacts: 13/13 (8/22/28cm curbs, blocked 45cm ledge, six pushable prop types, 1.2m mantle, low-ceiling and 3m-wall rejection). Irregular-map fall recovery: 3/3, followed by 90 grounded movement steps.
- Capture rules and UI: 28/28. Rendered 1280×720 equipment footer, expanded layer map, game menu, score/map view, partial/full capture overlay and settings inspected.
- Bounded resource stress: 72,000 tracers and 1,800 healing updates passed. Burst pool resource count remained constant through 30 bursts.
- Python directory/matchmaker tests: 19/19. Cloudflare policy tests: 3/3. Site installer integrity/regression tests: 7/7.

## Actual rendering and repeated sessions

RTX 4080 SUPER / Ryzen 9 7900, Windows, Godot 4.4.1 Compatibility renderer. These are **not Intel iGPU results**.

- Native exported EXE: 24 rounds/deaths/kill replays, about 240 seconds, exit 0, no session assertion failures. Warm resource count stayed at 876; node count 2513–2657; process private bytes about 663.3MB after warm-up and 662.1MB at exit sampling, peak 675.6MB.
- Web export in Chromium: 24 rounds/deaths/kill replays, about 245 seconds, no session assertion failures. Resource count stayed at 823. WASM capacity remained 100,466,688 bytes throughout; JS heap fluctuated approximately 91.7–115.6MB after warm-up rather than rising monotonically. Warm node count 2571–2648. Later samples averaged about 16.66ms with a 60fps cap; maximum sampled frame after the first three cycles was 25.1ms.
- Native medium, 1280×720, uncapped, 15-second combat samples: 8 players p95 2.83ms / p99 3.65ms; 32 players p95 8.51ms / p99 10.61ms. Approximately 122k/190k visible primitives and 436/628 draw calls in those samples. Maximum frames were 239/245ms: intermittent long frames are **not claimed eliminated**. This short sample cannot establish their cause or guarantee a low-end device frame rate.
- Separate native session warm-up samples still had a maximum 58.9ms frame. Some local resource checks ran concurrently, so these are resource-bound observations, not controlled comparative performance measurements.
- Two 349,524-byte GL texture diagnostics still occur at native shutdown. They did not grow during the repeated session; the underlying shutdown warning is not claimed fixed. No crash occurred in these runs.

Intel 10–11th-gen integrated graphics, GTX 960, physical smartphones, multi-hour play, and external NAT/TURN conditions remain unverified. Competitive balance needs human play statistics. The free public lobby remains an optional owner-deployed service; no unverified public address is inserted.

## Remote build and delivery

- Runtime/tag `5d035e5586950741134bb54ba870f9f116fd96f6` / `internal-n-crush-v1.2.6`, published 2026-09-27 11:43:45 UTC.
- Final-source Windows/Web CI `36314671336` passed all 47 functional groups and network/security checks, then exported both builds. Docker/TLS/Worker CI `36315362584` passed.
- Exact CI Windows ZIP: four native execution/ENet cases and packaged WebRTC passed (`players=2`, `ping=7`, `snapshots=58`). ZIP integrity, 22-file manifest and source commit checked.
- Exact Web ZIP: every listed file hash checked. Actual browser menu, bot match, equipment footer and game-menu map verified. Live Pages visibly reports WEB / v1.2.6; no startup errors observed.
- Site installer `36316683210`, Pages `36316702660` and public package/source/PCK audit `36316707421` passed. Site runtime commit `59a5d2563a292b064213b21eebdfc5ff8d24f7e2`; subsequent `8ac9690` only updates the Escape-key guide (Pages `36316826089` passed).
- Windows ZIP: 110,858,255 bytes; SHA-256 `92611c502f349764dcc86f86e55659e2c37425fde257c0cc06c8b0c5572b70ef`.
- Web ZIP: 56,988,504 bytes; SHA-256 `11033e84d72cfd79a213a4c35d639e63300ce64e834beff9a141a9e1bd175dcf`. Previous 1.2.5 archive was 77,992,669 bytes; archive reduction is not a measured low-end FPS guarantee.
- NAS ZIP: 15,520 bytes; SHA-256 `05fbb83b8ab8eef9378330d6790971f644a1ca514368fda32459b5cb9673ae65`.

[Release](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.2.6) · [Play](https://nukcanon.github.io/nukcanon/play/?build=11033e84d72c). Full machine-readable evidence is in `PUBLICATION_STATUS.json`.
