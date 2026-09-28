# Internal N Crush 1.3 — publication and validation

Published release: https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.3.0

Play: https://nukcanon.github.io/nukcanon/play/?build=e777495bdc55

Build source: `ba0da924851739a9a7aec1e34c18ce47271419b1`. Exact public asset hashes, frame samples and limitations are in `PUBLICATION_STATUS.json`. The public PCK and all five GitHub asset digests were verified. Pages installer run 36375684418 and Pages run 36375710423 passed. The first installer attempt correctly refused a package missing five guide screenshots; the package was repaired and verified before the site update.

## Materials and geometry

- Original ceiling 40, roof 40 and soffit 20 finishes, with paired relief normal atlas. Sources and CC0 manifest: `art_source/roof_textures`; generator: `game/tools/build_roof_textures.py`.
- Automatic quality remains the default. Medium/high use detail normals; low disables them and dynamic shadows. Auto never changes output resolution.
- Material triangles are clipped at straight region boundaries. Terrain-aligned roof fascia, supported columns, narrow-hole cleanup, exterior eaves, room ceilings and indoor High Rise are rebuilt.
- Audit: 32 maps / 251,766 triangles; zero duplicate, degenerate or material-tile-leaking triangles. Native/Web physics signatures match for all 32 maps.
- 96 native high-quality views were captured, with contact sheets and selected full-resolution views reviewed. Some camera positions face walls closely; this is not exhaustive inspection of every possible angle.
- Final spawn validation found candidates obstructed by dressing; these are now filtered after dressing/cache restoration. All 1,007 remaining starts pass clearance; arena routes 201/201.

[Ceiling finishes](docs/v13-review/ceiling-finishes-40.png) · [Market eaves](docs/v13-review/market-eaves.jpg) · [High Rise interior](docs/v13-review/high-rise-interior.jpg)

## Gameplay / UI checks

- Room routes 8/8; contact traversal 13/13; physical traversal 26/26; network security 40/40; bots 6/6; defusal 52/52; melee 38/38; Web graphics 19/19; native/Web render split 5/5; mobile UI passed.
- Knife/pistol rules: 16/16 host-enforcement checks. Actual bots attack successfully under each rule. Gadgets remain usable and skills are disabled.
- Actual melee replay captured and asserted to show no bullet/trail. [Replay](docs/v13-review/melee-replay.jpg).
- Five scope housings / five reticles / ten recessed lenses checked and rendered. [Models](docs/v13-review/scope-models.jpg) · [Reticles](docs/v13-review/scope-reticles.jpg).
- Settings apply/discard and Escape checks passed; actual browser change/back confirmation and discard inspected. A graphics-only Apply preserves pending display values separately.
- Python directory tests: 12 passed; Cloudflare policy passed; site installer integrity: 7 passed.
- Full source CI run 36375283761 is still running at this checkpoint. Targeted checks above passed independently.

## Post-publication performance

Both native and Web completed 24 rounds and 24 kill replays with zero probe failures. Native tail resources stayed at 1,285; Web at 1,214. Web WASM capacity stayed at 100,466,688 bytes. Native private memory after 60 seconds ranged 758.5–785.3 MB and ended at 769.7 MB, without a monotonic round-by-round increase.

Fixed paused-view rendering, 1280×720 on RTX 4080 SUPER:

| Map / quality | Previous mean | 1.3 mean | 1.3 draw calls |
|---|---:|---:|---:|
| 8-player / low | 0.830 ms | 0.725 ms | 279 |
| 8-player / high | 0.933 ms | 0.928 ms | 470 |
| 32-player / low | 0.822 ms | 0.962 ms | 480 |
| 32-player / high | 1.021 ms | 1.192 ms | 655 |

This measures rendering of a fixed scene, not complete match simulation or Intel integrated graphics. Added roof/ceiling geometry increases the large-map rendering workload. Physical Intel iGPU and mobile devices were unavailable.

The first Web workload included a 574.5 ms frame; later sampled spikes reached 95.3 ms. Stable resources do not mean zero frame drops. Native GLES texture cleanup warnings remain at process shutdown (two in fixed rendering, four in replay captures); these are not represented as fixed. The app browser rejects pointer lock, so ordinary Chrome/Edge Alt+Tab recapture remains unverified here. No public directory endpoint is configured; no separate lobby service deployment is claimed.

Unrelated `output/` and `game/tools/inspect_character_source.py` are preserved.
