# 1.2.7 publication and validation

Published on 2026-09-27 at the user's explicit request to publish first and
continue remaining tests afterward. Runtime commit:
`75ffb19e0a448d74303fdc4705f4bd2aa33b9d68`.

- Release: https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.2.7
- Page: https://nukcanon.github.io/nukcanon/internal-n-crush.html
- Play: https://nukcanon.github.io/nukcanon/play/?build=995d687615f3
- Website installation commit: `a7246bff370dae77d17a624903512adad38b97a1`.
- Release timestamp: 2026-09-27T13:43:27Z. Site installer 36323407195 and
  Pages 36323429203 succeeded. Live build.json reports version 1.2.7 and the
  exact runtime commit above.

## Implemented

Map cache revision 131 preserves enlarged footprints and one rectangular map per
capacity while narrowing corridors. Competitive maps now use different level
combinations: five ground-only, seven lower-only, seventeen upper-only and two
with both auxiliary levels. Practice retains its own four-level composition.
Supported decks, visible stair treads, indoor wall/ceiling joins and misplaced
lamp rejection address floating or intersecting geometry. Two-sided geometry and
normal correction address reverse-side disappearance. Central capture positions
are placed on valid ground with clearance rather than floating over lower routes.

Eleven CC0 Poly Haven texture sources and selected CC0 Kenney industrial, car,
nature and watercraft assets are accompanied by credits and licenses. Themed
facades, windows, shutters, lamps, vents, banners and foliage add location identity.
Materials are shared and static details batched by tile. Web uses smaller textures
and reduced geometry but shares all gameplay collision surfaces with Windows.

Both editions share operator anatomy; Web reduces body geometry while protecting
face geometry. Native hair follows the scalp; weapon shells use more planar forms;
hand shading was adjusted. This is stylized art, not a claim of AAA/reference parity
or a complete replacement of every pre-existing model.

Ambient light and sunlight are brighter. High quality enables sun shadows and a
bounded pool of four nearby local spotlights; medium has no local-light allocation
and no AA by default. Automatic Web quality does not change rendering resolution.
The map viewer has a red close button at the right. Dropped weapons persist for
180 seconds with a 96-item bound and round cleanup. Turret mint V-braces were removed.

## Completed validation

- 49 functional groups passed across the full run and targeted recheck after
  corrections. Evidence: `validation/v127-functional-all.log` and
  `validation/v127-functional-recheck.log` (the first log contains the corrected
  failures; do not present it alone as a clean run).
- 490/490 objective/elevation graph routes; 16/16 physical vertical destinations;
  48/48 defusal spawn exits. Revision 131 native/Web collision signatures match
  for all 32 maps.
- Effect stress: 72,000 tracer shots and 1,800 healing links; bounded resource
  checks passed. Native finish tests 238/238, bounded burst resources over 30 cycles.
- Drop retention/empty-ammo/bound checks and local-light allocation/recycling checks
  passed. Both sets of 68 baked thumbnails validated.
- Exact published Windows ZIP: integrity, source pin and 27-file manifest checked;
  practice, training, headless-host/client and window-host/client runs all exit 0.
  Evidence: `validation/windows-v127/verification.json`.
- Actual Chromium Web main menu, bot configuration, equipment footer and combat
  entry inspected with no observed startup console errors. Free-equipment text is
  contained in its box and footer action dimensions match.
- Docker/TLS/Worker CI 36322990614 succeeded. Site installer unit tests 7/7.
- Exported WebGL handle table patch checked. Fresh baked art is included in the
  published packages, not merely in source files.

## Performance limits

Measurements use Ryzen 9 7900 / RTX 4080 SUPER, not Intel integrated graphics.
Short native medium 1280x720 samples: 8 players p95 3.047ms, p99 4.461ms,
maximum 172.281ms; 32 players p95 8.538ms, p99 12.216ms, maximum 17.367ms.
The 32-player view had 273 draw calls / 24,065 primitives, versus 628 / 190,190
in the earlier 1.2.6 sample. Views and concurrent work are not a controlled GPU
benchmark; these reductions do not establish an Intel frame-rate guarantee.

A separate 12-cycle native stress run had zero assertions, with resources warming
from 866 to 889 and then stable; static memory approximately 95.37 to 95.64MB.
It still included 317–322ms maximum frames. Intermittent long frames are not
claimed solved. Two 349,524-byte native GL texture warnings persist at shutdown,
even after explicitly clearing model/material caches in a diagnostic run.

Intel 10–11th-gen iGPU, GTX960, physical phones, multi-hour play and external
multi-PC NAT/TURN remain unverified. The historical 1.2.2 crash has no original
dump and no established root cause. Public matchmaking still requires owner
deployment of the service; no invented public address is configured.

The Web ZIP grew from 56,988,504 to 94,646,556 bytes as new art was added.
This release must not be described as a download-size reduction.

## Package hashes

| Package | Bytes | SHA-256 |
|---|---:|---|
| Windows | 150484004 | d56495a91e195ef5192b41fa11b74ccc39d43b5ab2be4b1523f0c07ccb1e24a2 |
| Web | 94646556 | 995d687615f3b55b756e497eccdf04d07b62f89828728e6bd634bd34eac0c3a7 |
| NAS/Linux | 15583 | cd1c0dd3ea3a23ccf37f91f1144aa2c5c66c31bb6a9508f7e64abda0f41c4343 |

Extended rendered-session results are recorded below. The historical
`VISUAL_REWORK_V127_PARTIAL.md` is superseded by this file.

## Post-publication checks

- Exact published Windows WebRTC host/client connected, exchanged 59 snapshots
  (`players=2`, `ping=7`) and disconnected normally. ICE candidate send warnings
  (errno 10051) occurred but did not prevent this loopback connection. This is not
  a verification of external routers or TURN.
- Chromium Web diagnostic export using the same 1.2.7 staged runtime/art completed
  24 rendered round/death/killcam cycles in about 250 seconds, zero assertions.
  Warm resources stayed at 1087; WASM capacity stayed at 100,466,688 bytes.
  JS heap varied between 125.2 and 162.4MB after warm-up and ended at 135.3MB.
  Node count changed from 2580 to 2750 within the test's bound, so this does not
  prove zero long-term accumulation. Warm samples averaged 16.64–27.50ms and
  included a 115.799ms frame; the first cycle was browser-background-throttled
  and is excluded from these timing ranges. Shutdown logged WorkerThreadPool
  allocator, ObjectDB and two remaining-resource diagnostics. Those are not
  claimed fixed. Evidence: `validation/v127-web-soak.jsonl`.
- Exact published Windows EXE completed 24 rendered round/death/killcam cycles
  in 245 seconds, exit 0, zero assertions. Warm resource count was 1201–1210,
  node count 2723–2804. Process private memory measured 683.9MB after warm-up,
  680.3MB at the final sample and 699.8MB at peak. Warm sample averages were
  16.64–16.70ms at a 60fps cap, maximum 50.442ms. Two shutdown texture warnings
  persisted. Evidence: `validation/v127-native-soak.log` and
  `validation/v127-process-memory.json`. This bounded run does not establish
  multi-hour stability or low-end-device performance.

- Source CI 36322990615 completed a clean run of all 49 functional groups,
  32-client capacity, independent clients, lifecycle, movable props, rotation,
  late-start lifecycle, touch and WebRTC tests successfully. Its independent
  Web rebuild/artifact upload is still running at this checkpoint; the entire
  workflow is not yet reported successful. Already-published packages were
  separately exported, hash-checked and executed locally.
