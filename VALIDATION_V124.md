# 1.2.4 native finish and stability validation

Baseline: published 1.2.3 runtime `19386e693a45134b2f8a69ecbe4d5b28ea800ae6`, main handoff `d53a241`. This is a new patch; the 1.2.3 assets are immutable. Gameplay is unchanged; Native and Web baking remain separate.

## Identified issues and fixes

- Native neck triangles had discrete atlas IDs but still interpolated **vertex colors** between skin and shirt. The offline baker now cuts the neckline, and each resulting face has one material category. The separate centered collar intersected the rear of the off-center anatomical neck; it is removed and replaced by a bound edge on the cloth itself.
- The male/female head blend started inside the chin, retaining male underside volume below a shortened female face. Preserve common torso/shoulders below the neckline and use a continuous female head blend above it. Pinned CC0 MakeHuman neck/jaw/mouth/eyelid shape data is baked offline. No additional bones. Two existing CC0 face maps are importer-capped to 512 px and shared (at most 2.67 MiB total uncompressed RGBA with mipmaps); Web removes both maps. Body triangles: 26,756 → 26,960 (+0.76%).
- Eye geometry inherited the cloth atlas category when merged into the GPU-skinned body. Eye surfaces now use clean skin/eye shading.
- Rebuilding every first-person hand uploaded identical loft meshes repeatedly. A bounded 128-entry immutable geometry cache now shares them, while each articulated finger keeps its own pose material.
- Every explosion allocated 24 quad meshes and 24 materials; random debris dimensions also churned geometry caches. Reuse eight explosion instances, one shared quad and three fixed debris shapes. Tactical smoke fields and damage/visibility rules remain unchanged.

## Crash evidence

The Windows Application event log has an access violation (`c0000005`, engine offset `0x29247fc`) on 2026-09-27 03:16 KST in the user's **1.2.2** executable. A WER summary exists, but its temporary dump is absent; it does not establish whether the cause was a heap leak, a resource lifetime defect or an engine/driver fault. Do not claim this historical crash has been conclusively diagnosed or repaired. Only game-specific event metadata is documented here, not unrelated system data.

## Validation in progress

- New native finish/resource regression: 147/147. Forty warmed hand rebuilds reuse the exact same mesh; roughly 0.32–0.48 ms per hand in the headless fixture. Thirty batches of eight explosions keep the resource counter constant at 68 in that fixture. Leaving frees the pool and its decorative physics bodies.
- Final build, rendered pose/face review, longer Windows soak and public artifact verification will be recorded below after completion. No universal FPS, crash-free or reference-equivalent art claim.

## Asset policy and references

Use CC0 or verified redistributable source assets, retopologize/bake offline, preserve the existing rig and material count, cap textures/physics bodies, use distance LOD and shared instances, and validate before publication. Large source assets are not runtime assets. Detailed source URLs and hashes: `game/assets/human/source/face-morphs-v124.json` and `manifest.json`.

- [Godot 4.4 mesh LOD](https://docs.godotengine.org/en/4.4/tutorials/3d/mesh_lod.html)
- [Godot stutter guidance](https://docs.godotengine.org/en/latest/tutorials/rendering/jitter_stutter.html): Compatibility can still compile shaders on first visibility; Forward+/Mobile pipeline precompilation guarantees do not apply to this renderer.
- [Godot 4.4 pipeline compilation](https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html)
