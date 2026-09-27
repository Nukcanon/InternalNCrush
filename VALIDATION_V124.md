# 1.2.4 native finish and stability validation

Baseline: published 1.2.3 runtime `19386e693a45134b2f8a69ecbe4d5b28ea800ae6`, main handoff `d53a241`. This is a new patch; the 1.2.3 assets are immutable. Native and Web baking remain separate; the economy timing and launcher changes below apply to both.

## Identified issues and fixes

- Native neck triangles had discrete atlas IDs but still interpolated **vertex colors** between skin and shirt. The offline baker now cuts the neckline, and each resulting face has one material category. The separate centered collar intersected the rear of the off-center anatomical neck; it is removed and replaced by a bound edge on the cloth itself.
- The male/female head blend started inside the chin, retaining male underside volume below a shortened female face. Preserve common torso/shoulders below the neckline and use a continuous female head blend above it. Pinned CC0 MakeHuman neck/jaw/mouth/eyelid shape data is baked offline. No additional bones. Two existing CC0 face maps are importer-capped to 512 px and shared (at most 2.67 MiB total uncompressed RGBA with mipmaps); Web removes both maps. Body triangles: 26,756 → 27,142 (+0.76%).
- Eye geometry inherited the cloth atlas category when merged into the GPU-skinned body. Eye surfaces now use clean skin/eye shading.
- Rebuilding every first-person hand uploaded identical loft meshes repeatedly. A bounded 128-entry immutable geometry cache now shares them, while each articulated finger keeps its own pose material.
- Every explosion allocated 24 quad meshes and 24 materials; random debris dimensions also churned geometry caches. Reuse eight explosion instances, one shared quad and three fixed debris shapes. Tactical smoke fields and damage/visibility rules remain unchanged.

## Crash evidence

The Windows Application event log has an access violation (`c0000005`, engine offset `0x29247fc`) on 2026-09-27 03:16 KST in the user's **1.2.2** executable. A WER summary exists, but its temporary dump is absent; it does not establish whether the cause was a heap leak, a resource lifetime defect or an engine/driver fault. Do not claim this historical crash has been conclusively diagnosed or repaired. Only game-specific event metadata is documented here, not unrelated system data.

## Validation in progress

- New native finish/resource regression: 181/181. Forty warmed hand rebuilds reuse the exact same mesh; roughly 0.32–0.48 ms per hand in the headless fixture. Thirty batches of eight explosions keep the resource counter constant at 101 in that fixture. Leaving frees the pool and its decorative physics bodies.
- Final build, rendered pose/face review, longer Windows soak and public artifact verification will be recorded below after completion. No universal FPS, crash-free or reference-equivalent art claim.

## Asset policy and references

Use CC0 or verified redistributable source assets, retopologize/bake offline, preserve the existing rig and material count, cap textures/physics bodies, use distance LOD and shared instances, and validate before publication. Large source assets are not runtime assets. Detailed source URLs and hashes: `game/assets/human/source/face-morphs-v124.json` and `manifest.json`.

- [Godot 4.4 mesh LOD](https://docs.godotengine.org/en/4.4/tutorials/3d/mesh_lod.html)
- [Godot stutter guidance](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html): Compatibility can still compile shaders on first visibility; Forward+/Mobile pipeline precompilation guarantees do not apply to this renderer.
- [Godot 4.4 pipeline compilation](https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html)

## Integrated graphics target and measured long frames

Target hardware supplied by the owner: Intel 10th–11th generation integrated graphics. UHD and Iris Xe differ substantially; use the lower UHD class as the conservative target. Minimum target: 1280×720 low at stable 30 FPS. **Not yet measured on that hardware**; the RTX 4080 SUPER cannot establish this claim.

A rendered 8-player low-quality Windows run reproduced a 201–204 ms frame. CPU instrumentation attributed 163.832 ms to world visual creation when a device first appeared; GPU rendering in adjacent samples was below 1 ms. Isolated exported-EXE reproduction then measured turret mesh assembly at 50–60 ms and construction-edge extraction at 175–179 ms. Both now happen in the offline asset baker. The four bounded scenes are loaded during map setup, preserving independent aiming and collisions. Warmed creation measured 0.05–0.09 ms plus 0.89–1.09 ms for the construction display. First file loads were 3.6–4.9 ms in this machine. This identifies a real CPU stall; it does not attribute every long frame to this one cause.

An empty bot path also bypassed its retry timer, and fully blocked steering reset its retry deadline every tick. Failed paths now back off 0.35–0.47 seconds; blocked movement waits at least 0.25 seconds; at most two route searches begin in one simulation tick. Targeting, firing and authoritative physics retain their update rate. Navigation regressions include leaving spawn, capturing, planting and defusing.

Low quality uses a 2.5 px distance-LOD threshold and bypasses world material texture/mortar calculations. Medium/high preserve them. No automatic resolution change. Unchanged HUD font styles are no longer re-applied every physics tick.

`game/tests/profile_native_v124.gd` is a reproducible 60-second rendered workload. Release executables do not expose Godot static allocation bytes (zero means unavailable); use Windows process private bytes / working set and browser heap/WASM evidence alongside resource counts. Do not call a zero allocation counter proof of no leak.

## Defusal economy and bomb usability

Owner-requested additions: separate large store price (white) and balance (yellow) boxes in the fixed footer; larger in-game white balance; yellow carrier hint replaced by E planting prompt at a site; bomb carried vertically with its lamp facing outward. Default fuse 45 seconds, configurable 30–120 seconds (owner’s contradictory “maximum 2 seconds” interpreted as 2 minutes). Defuse 15 seconds / owned kit 5 seconds, including UI/help/stat graph. Purchases allowed during preparation plus the first 60 combat seconds per round, configurable 0–300 and capped to round duration; zero permits preparation purchases only. The authority enforces alive state, deadline, price and replacement confirmation. LAN/WebRTC/Docker/Worker schemas share both new settings. 52 behavior checks pass; directory 9, allocator 10 and Worker 3 test groups pass locally.

## Latest presentation and input checks

Native finish/HUD cache: 195/195. Kill feed: 19/19, including actual lethal rocket damage after the shooter selects a different weapon, fixed catalogue texture reuse, and all firearm silhouettes. Grip/reload test: 1,063/1,063 across weapons, both hands and reload phases. v1.2.3 integration: 150/150, including B during replay and purchase restriction. Rendered 720p left/right dual pistol, pistol and launcher reload captures and inspection/waist reviews are saved locally under validation/v124. New seams total 27,142 native triangles (+1.44% vs 26,756); 15 bones and material count unchanged.

Launcher review: final 36 m/s (+20%, not the initially proposed +30%). At 10/20/30 m, travel is approximately 0.278/0.556/0.833 s before minor gravity; current direct damage 60, splash 45→15 over 9 m, single-round magazine and 1.8 s reload remain. The broad splash and slower player movement warrant a conservative increase. This is a design judgement, not a competitive win-rate study. Reference: Blizzard's 2024-02-13 Pharah change 35→40 m/s, https://overwatch.blizzard.com/en-us/news/patch-notes/live/2024/2/ .

## Web leak mechanism

The Godot 4.4.1 Emscripten export shares a monotonic GL object ID among arrays and fills each table through that ID. Real browser measurements reproduced 88,476 buffer slots at cycle 0, 862,802 historical IDs by cycle 7, and about 1.86 million by cycle 16, despite only roughly 1,500 live buffers. Audio and JS bridge references were bounded. This matches the mechanism reported in https://github.com/emscripten-core/emscripten/issues/21921 . Baseline runs were stopped after diagnosis, not marked passing.

The package step verifies the exact supported template before replacing tables with sparse numeric maps and deleting dead entries. ID values remain monotonic; zero/null binding is retained. Unknown templates fail the build. The actual exported deletion functions plus syntax/idempotency guards pass 1,920,000 allocation/deletion operations. Diagnostic engine getters, heap probes and test main scenes are never included in public packages.

## Actual Windows candidate soak

A rendered Windows release executable completed 120 death/replay/round/gear/effect cycles in 1,170 s with failures=0, exit=0. Warm samples retained about 2,279–2,281 nodes, 620 resources, 16 loft cache entries, 3 explosion groups and about 97.75 MiB GPU allocation; final combat samples averaged 16.66 ms with a 60 FPS cap. This candidate predates the final presentation/HUD edits and is not mislabeled as the final public ZIP. Windows external private/RSS measurements are recorded below. Renderer was NVIDIA RTX 4080 SUPER; a temporary per-executable power-saving preference did not select the AMD adapter and was restored. Intel hardware is unavailable.

At shutdown, Godot still reports two GL texture objects of 349,524 bytes each (~0.67 MiB total). They do not accumulate across the measured 120 cycles, but this retained shutdown ownership warning is not called fixed. The historical v1.2.2 c0000005 crash remains unproven without its absent dump.


## Final supplemental validation

Native finish/cache 233/233, all-map fixture clearance/attachment and turret label height 545/545, revised decals 49/49, melee 38/38, doors 125/125. Rendered feedback integration 30/30 verifies real character/device/repair contact sounds and privacy filtering; its shutdown emitted four retained 349,524-byte GL texture warnings. No runtime script failures. Native and Web impact marks now use one shared quad without the raised gray rim geometry; existing original shader artwork is retained. New CC0 mixes use the credited Kenney sources, not extracted commercial game assets.

The largest map extents are 200 × 180 m (269.07 m diagonal). A 36 m/s rocket has 360 m horizontal lifetime range before its 10 s airburst; the diagonal takes approximately 7.48 s in unobstructed flight. Gravity/obstacles still limit a level shot and require elevation compensation. This is not a claim of an unobstructed sight line across each arena.

Marker/visibility/HUD-coordinate/shield integration: 160/160. Real rendered native and Web female face reviews revealed and corrected a coarse Web cap intersection during iteration; Web now splits/paints the existing head surface with no separate cap. Native hair is projected onto authored skull triangles only during baking, with 2.5 mm shell offset.
