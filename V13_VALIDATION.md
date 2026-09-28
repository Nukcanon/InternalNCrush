# 1.3.0 candidate — not yet published

The published build remains 1.2.8-hotfix.1 until the 1.3.0 release and Pages update are verified.

## Completed implementation / checks

- All 32 maps rebuilt with material-tile clipping, narrow-hole filling, terrain-aligned roof fascia, exterior eaves, room ceilings and original roof/soffit/ceiling atlases.
- Surface audit: 32 maps, 251,766 triangles, zero duplicate triangles, zero degenerate triangles, zero material-tile leaks. Ten indoor maps; 22 outdoor maps contain covered room areas. Indoor maps have no eaves. This numerical audit does not replace visual inspection.
- Captured 96 native high-quality views (three per map), inspected contact sheets and selected full-resolution views. Shadow comparison isolates self-shadowing artifacts; bias .25 / normal bias 1.2 removes the visible test-pattern acne at the inspected location. Additional final visual review remains.
- Initial targeted regressions: arena flow 175/175, room routes 8/8, traversal contact 13/13, physical traversal 26/26, lobby 49/49, Web graphics 19/19, render split 5/5.
- Scope geometry: five weapons, five distinct reticles, ten recessed lenses; actual rendered scope/reticle images inspected.
- Initial restricted-weapon server checks: 16/16. Settings apply/discard checks passed. Final loadout/UI checks passed; network security 40/40, bots 6/6, defusal 52/52, drops passed.
- Directory/NAS Python tests: 12 passed. Cloudflare policy tests passed. No public directory endpoint is configured; do not claim a new lobby service was deployed.

## Required before declaring complete

- Native/Web synchronization completed; all 32 physics signatures match.
- Native mobile settings regression passed. Actual browser graphics change/back confirmation and discard inspected. App browser denies pointer lock and shows the fallback notice: ordinary Chrome/Edge Alt+Tab recapture remains unverified here. Melee replay branch preserves stabbing with no bullet flight; actual replay visual inspection remains.
- Final native and Web exports, package validation, release 1.3.0 and website update, verify public hashes and actual browser loading.
- Post-deployment performance/resource checks; compare to 1.2.8 hotfix baseline. No Intel 10th/11th-gen integrated GPU is available on this RTX 4080 SUPER host; never report physical iGPU verification.
- Two GLES texture cleanup warnings (349,524 bytes each) still occur at native process shutdown. Prior 24-cycle native/Web tests showed stable runtime node/resource counts. Clearing character/material template caches did not remove shutdown warnings; do not describe this as fully fixed.

Unrelated untracked `output/` and `game/tools/inspect_character_source.py` are preserved and are not part of this change.
