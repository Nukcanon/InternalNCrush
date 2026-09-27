# Historical checkpoint — superseded

1.2.7 is now published. Read VALIDATION_V127.md and PUBLICATION_STATUS.json for current facts. The unreleased status and remaining-work lists below describe earlier checkpoints only.

# 1.2.7 visual rework — PARTIAL, NOT RELEASED

2026-09-27. Branch: `work/v1.2.7-visual-readability`.
Production remains **1.2.6**. Do not describe this branch as a finished art overhaul.
The user now asks us to finish as much as possible; continue implementation and
validation rather than stopping at this checkpoint. Do not restore 1.1.x.

## Latest checkpoint (supersedes older implementation/remaining lists below)

- Cache 130 built in both editions; all 32 collision signatures are identical.
- Real four-slot nearby SpotLight pool on high, no allocated local lights on
  medium. Tests cover camera movement, recycling and low-quality disablement.
  Wall lamp illumination and sun shadows verified in rendered screenshots.
- Selected Kenney cars, nature and watercraft now join industrial GLBs. Full
  credits/licenses are copied into Windows and Web packages.
- Indoor wall height now meets ceilings; facade detail is truly batched into
  spatial tiles. Backface lighting normals are corrected too.
- Web uses HumanModel anatomy with body decimation and protected head triangles
  (~16k near-view triangles/operator, distance LODs). Native scalp triangle
  fitting removes the old forehead protrusion. Weapons have chamfered planar
  receiver/stock shapes; hands and equipment use less crushed dark shading.
- Targeted model/motion/native-finish/graphics tests passed. Full functional
  suite is running. It found a real invalid generated central capture location
  in five defusal layouts; source fixed to choose authored ground paths, but
  cache rebuild and recheck are pending. Old tests that mandated a basement in
  every map are being updated to assert actual authored levels instead.
- Actual character vertical traversal passed 16/16 on the optional-level maps.
- RTX 4080 SUPER/720p/medium benchmark: 32-player view 273 draw calls, 24,065
  primitives, p95 8.54ms, p99 12.22ms, max 17.37ms. 8-player max 172ms still
  needs investigation. These are not Intel or browser measurements.
- Two 349,524-byte OpenGL texture warnings occur at engine shutdown, also in
  the previous published baseline. Do not describe these as proven growing
  in-match leaks or silently disregard them; resource-cycle testing pending.
- Map header now wraps controls on narrow screens, keeping red close at right.
- Source/build versions bumped to 1.2.7 candidate; production remains 1.2.6.

## User's complete active scope

- Rebuild the 3D forms and materials of maps, props, weapons, operators, their
  equipment, first-person arms/hands. DEADSHOT is a visual/readability reference.
  Texture replacement alone is not sufficient. Use original or appropriately
  licensed free assets; the supplied Arca asset-site list is a starting point.
- Preserve recognizable map identities and sizes, but make ground/upper/basement
  routes genuinely different between maps. Keep one rectangular map per capacity.
  Halve excessive passage widths while maintaining real character/bot access.
- Elevated walkways need structural support, beams/columns/buildings and suitable
  railings, not unsupported floating planes. Free map/building kits may be adapted.
- Fix reverse-side invisibility and flicker, distinguish walls/floors/ramps/levels,
  brighten the game and offer actual optional shadows. Medium targets Intel
  10th/11th-generation integrated GPUs. High should improve lighting/detail.
- Web and native should retain similar visual identity; Web may simplify detail.
  Preserve shared gameplay/collision and do not automatically reduce resolution.
- Map-viewer close button at far right in red; remove ugly mint V turret braces;
  dropped guns should remain longer, with bounded resource usage.

## Implemented on this branch

- New shared world material pipeline, mipmapped diffuse textures, directional
  surface mapping and flat geometry normals. Web no longer discards these textures.
  Per-map material palettes; distinct upper/ground/basement surfaces.
- Eleven real CC0 Poly Haven diffuse textures downloaded, source MD5 verified,
  resized to 512px. Web conversion keeps world textures at 256px. Original
  procedural metal/roof tiles remain. Sources and checksums are in
  `game/assets/textures/world/SOURCES.json`; reproducible conversion tool included.
- Selected Kenney City Kit Industrial 2.0 CC0 GLBs, source palette and license
  included. Containers/tanks replace some generic props. Shared silhouettes and
  exact mesh collisions in both editions. Static palette texture is shared.
  This is only an initial subset, NOT all 3D models replaced.
- Additional window frames/shutters, stall counters/posts, lamps/brackets,
  vent cabinets, pipes, hanging banners and sparse opaque foliage geometry.
- Double-sided map rendering/collision; overlapping coplanar route strips unioned
  before triangulation, duplicate reversed wall faces removed, floor-edge fascia.
  Fixed a second flicker cause: `mod(interpolated_height, 4.2)` switched between
  light/dark at floor boundaries due to float rounding. Removed the discontinuity.
- Brighter ambient light/material response, linear tonemapping, real light response
  when enabled. Native high and Web high enable nearby shadows; medium keeps
  shadows off, custom settings can enable them. Shadows visibly verified in a
  native high screenshot, not yet validated on an actual browser GPU.
- Main passage widths: 32p 8m, 16p 6m, 8p 4.5m, 6p 3.75m; defusal 8p 4.5m,
  12p 5.5m. Side corridors 2.7m. Bend points no longer all become large rooms.
- `vertical_districts.py` gives 31 maps explicit route segments/heights and removes
  compulsory upper + basement layers. Five maps are ground-only, seven have a
  lower route only, seventeen have an upper route only and two retain both.
  Practice retains its dedicated layout. Nineteen layouts use visible stair
  treads over smooth walking ramps. This first pass still
  needs art-direction/layout review; do not equate unique data with finished maps.
- Ground-connected support posts/caps beneath elevated routes. Not a complete
  structural design yet: continuous beams/abutments/railings need another pass.
- Sparse authored-route navigation samples solve narrow diagonal passages missed
  by the old 2m grid, without making the entire grid four times denser.
- Map-viewer red close button moved to far right. Removed lower mint turret braces.
- Dropped guns last 180s rather than 40s and empty-ammo drops remain. Oldest drops
  removed above 96; existing round cleanup retained. Render-distance limits added.

## Evidence and honest limits

- Godot 4.4.1 import passed. Native 32-arena bake completed.
- Bot route check: **304/304** on the final optional-level layout (cache revision
  128). The earlier 372-check result predates removal of compulsory levels.
- Actual character defusal spawn-exit check: **48/48**.
- Drop retention/expiry/96-object bound test: `DROPS_V127_PASS`.
- Existing Web quality-policy tests: **19/19**.
- Actual native OpenGL screenshots: market facade, underside, imported container,
  high shadows and right-aligned red close button. Web asset-staging screenshots
  used the native OpenGL executable with the Web asset flag, **not a browser**.
- [Market, native high](docs/review-v127/market-high.png)
- [Market, Web asset staging](docs/review-v127/market-web-assets.png)
- [Supported canal deck](docs/review-v127/canal-supports.png)
- [Imported container](docs/review-v127/imported-container.png)
- [Map viewer](docs/review-v127/map-viewer.png)
- Host is RTX 4080 SUPER. No Intel iGPU or real phone was available. No new FPS,
  long-session memory stability, full browser export, Windows packaged executable
  or release claim is made. Previous 1.2.6 results do not validate this branch.

## Must finish before release

1. **Operator/face/body, guns, first-person hands/arms and held gadgets remain
   substantially unchanged.** Obtain/build suitable game-ready assets, integrate
   existing rig/socket/reload/left-hand systems, and review actual gameplay views.
2. Map architecture is still too procedural. Distinct rooms, building masses,
   themed prop sets, roofs/bridges/rails and authored landmarks need further work.
   The support posts and imported containers are a start, not DEADSHOT-level art.
3. Fully inspect every map in both directions and every floor. Run real actor
   routes through upper/basement entrances and around support posts, not only A*.
4. Rebuild caches whenever geometry changes. Native caches have been rebuilt at
   revision 128 after the latest material/stair edits. Cached `.scn` files are
   ignored and not the source of truth; review screenshots build directly.
5. Run native/Web collision signature parity for all maps, remaining functional
   and network suites, and actual Web browser/touch tests. Extend resource-cycle
   and frame-time profiling to the new geometry and narrower-route graph.
6. Check low-end draw calls, mesh/texture memory, loading stalls and resource
   retention. Do not compensate by removing essential map readability.
7. Review map-viewer mobile layout, all turret upgrade levels and dropped gun
   cleanup during actual multiplayer/round transitions.
8. Only then bump the runtime/build/release workflow versions, publish new
   Windows/Web builds and update the site. **Do not publish this WIP as 1.2.6.**

## Rebuild and verify

Use Shapely 2.1 Python for `game/tools/maps/author_districts.py`, then
`game/tools/maps/bake_districts.py`. Import `game` in Godot 4.4.1 and run
`tools/build_arenas.gd`. Run `tools/test_districts.gd`,
`tests/test_spawn_exits.gd`, `tests/test_drops_v127.gd` and
`tests/test_web_graphics.gd`. `tools/review_v127.gd` writes native screenshots.

Run `web/prepare_lightweight.py` with Pillow; import/rebake the resulting
`web/staging/game` separately. It copies the small industrial source models for
baking, preserves gameplay geometry and downsizes world textures. Complete the
normal Web baking/export pipeline before making any browser-runtime claims.

## Latest map identity request

Materials now include plaster, sandstone, corrugated rusty metal, painted
concrete and mossy stone as well as brick, wood and paving. Market stalls/awnings
are restricted to the relevant town/market maps. Town lanterns, industrial strip
lights, ventilation boxes, pipes, banners and sparse ivy have different map
assignments. Small facade details are merged into static spatial tiles; no
per-lamp dynamic light is added on medium. This avoids extra per-object draws
and keeps the native/Web geometry consistent.

Still inspect architectural realism: roofs in some indoor layouts have gaps,
ridge/terrace structures remain too bridge-like, and room silhouettes repeat.
Map 23's generic facade review camera also clips the opposite wall, so its
facade screenshot is NOT evidence of a visually approved map. Do not present
this initial theme pass as the user's complete requested map redesign.
