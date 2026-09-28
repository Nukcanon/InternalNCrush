# Internal N Crush 1.3.0

- Split architectural triangles at exact district boundaries before choosing materials.
- Remove tiny corridor-union holes that became tall freestanding wall slivers; match support columns to actual deck heights.
- Synchronize browser pointer-lock state after Escape, Alt-Tab and lock errors; a fresh click resumes mouse aiming without firing.
- Replace cylindrical optics with original tapered housings, mount rings, adjustment turrets and recessed blue-coated ocular/objective lenses.
- Add five lightweight vector reticle patterns for SCOUT, MONOLITH, ECHO, LARK and KESTREL.
- Preserve the 1.2.8 material/normal-map hotfix and automatic native/Web quality. Auto never changes resolution.
- Match roof side walls to terrain slope segments, fill narrow leftover islands and remove degenerate/duplicate triangles across all 32 maps.
- Add original 40 roof, 20 soffit and 40 ceiling finishes with paired normal maps; add exterior eaves on roughly 60% of lots, supported side-room ceilings, and a full interior ceiling for High Rise.
- Preserve mipmap import settings in Web builds; tune shadow precision/bias and sunlight exposure against captured high-quality views.
- Prompt to apply or discard pending display/graphics changes when leaving Settings, including Escape.
- Add knife-only and pistol-only rules to bot, LAN and public-room setup. Gadgets remain usable; skills are disabled. Enforce restrictions on the host, loadouts, switching, firing, bot behavior and drops.

Validation and publication are recorded in PUBLICATION_STATUS.json after testing.

Implementation references: [Godot 4.4 lights and shadows](https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html), [Godot 4.4 normal-map materials](https://docs.godotengine.org/en/4.4/tutorials/3d/standard_material_3d.html). New texture artwork is original; no third-party game assets were extracted.
