# 1.2.8 material/district hotfix

The displayed game version remains **1.2.8**. The hotfix has its own source
commit and build identifier; the original 1.2.8 release remains recoverable.

## Changes

- Complete four-sided window frames; separated glazing/shutter/frame depths;
  removed overlapping old facade details and disconnected ivy rectangles.
- 40 window designs, 30 trees, 200 additional small props, and 100 original
  building texture tiles. Small props are grouped on supporting tables and
  counters; the catalogue count is not a claim that every prop appears per map.
- Distinct building-lot finishes and stepped roof heights. Indoor layouts,
  including library, vault and server centre, have ceilings and attached lights.
- Prop footprint/height validation rejects furnishings intersecting architecture.
  Tree placement excludes entrances, main routes, objectives and furnishings.
- Actual normal-map sampling in map, prop, character, hand and equipment
  shaders. Effects follow automatic quality; low disables micro-normal effects,
  high enables sun shadows, nearby pooled lights and antialiasing. No automatic
  output-resolution changes. Native default/reset now uses automatic quality.
- Web retains all tactical geometry/collision and omits only small decorative
  items and window bevels. Building atlas reduced to 680px in Web; native1360px.
- Automatic switches update shader uniforms and registered scene targets,
  avoiding replacement of every material in the scene. Light slots remain capped.
- Bots open doors encountered along movement rays, including while looking
  toward a combat target. They no longer treat a closed doorway as a wall.
- Fallback map geometry JSON is losslessly compressed in exported packs.

## Validation and limits

32 native/Web collision signatures matched in the candidate. Route graph:
508/508; physical traversal:26/26; room routes:8/8. Mobile layout and map pinch
regressions passed. 270 new design meshes imported and rendered. Actual GL
shader compilation and low/medium/high output were checked on RTX4080SUPER.

Pre-publication candidate:12 rendered rounds/deaths/replays passed. A slowly
growing tracer MeshInstance pool was identified and changed to reuse expired
entries before allocating. The 72,000-shot / 1,800-healing-update resource
regression passed with stable node/resource counts; native and Web 24-cycle rendered soaks passed with stable post-warm-up counts. Prior shutdown warnings
for two256px GLES textures are tracked separately from live gameplay growth.

Physical Intel10–11-generation integrated graphics and mobile devices are not
available in this environment. No measured FPS claim for those devices is made.
Final release hashes, deployment verification and post-publication results are
recorded in PUBLICATION_STATUS.json and the handoff document.

Functional suite: all 49 groups passed across the full run and focused reruns.
The two initial failures were obsolete manual/automatic graphics assumptions.
Sun shadows use four cascades, bounded distance and higher precision atlases;
low/medium presets do not allocate a full shadow atlas.

## Published validation

Published as `internal-n-crush-v1.2.8-hotfix.1`, unchanged game version1.2.8.
Live Pages PCK SHA256 matched the packaged file. Both download links target
the hotfix release. Native24 and Web24 repeated round/death/replay cycles passed.
After warm-up native nodes/resources stayed2537/1088, Web2541/1014; Web WASM
capacity stayed100466688 bytes. Web heap fluctuated111–147MB with collection.
Initial frame spikes remain; one later Web sample reached92.8ms. This is not
a zero-stutter or zero-leak guarantee. RTX4080SUPER results cannot establish
Intel integrated-GPU or physical-phone performance.

Fixed-camera render-only benchmark:1280x720, actor physics paused, RTX4080SUPER.

|Map / actors|Quality|Mean ms|P99 ms|Draw calls|
|---|---|---:|---:|---:|
|17 / 8|low|0.830|1.691|260|
|17 / 8|medium|0.836|1.612|271|
|17 / 8|medium_shadow|0.887|1.439|412|
|17 / 8|high|0.933|1.556|412|
|0 / 32|low|0.822|1.321|384|
|0 / 32|medium|0.865|1.411|392|
|0 / 32|medium_shadow|0.938|1.457|499|
|0 / 32|high|1.021|1.530|504|
