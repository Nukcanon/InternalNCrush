# Art provenance — 1.0.4

Operator anatomy is derived from CC0 MakeHuman mesh/target data. Weapons, tactical gear, first-person articulated hands, props, architecture, icons and procedural animation are original source-generated assets. Model baking uses Godot; Blender is not required. References to Deadshot, XIII, Counter-Strike and Overwatch indicate design direction, not copied assets.

The following new raster assets were generated with the OpenAI image generation tool through the **imagegen skill**, 2026-09-24. Mode: new image, no reference images, one output per prompt, copied unchanged into assets/textures/. The material shader supplies world projection and tint; the particle renderer supplies animation. No hand-painted or licensed third-party origin is claimed. Godot imports mipmaps for both assets. Existing audio/font licenses remain in their respective notices.

## field_materials_v103.png

Path: `assets/textures/field_materials_v103.png`. 2048×2048 requested; actual delivered file 1254×1254, retained unchanged.

Exact prompt:

```text
Use case: stylized-concept. Asset type: production albedo material atlas for a stylized realistic tactical FPS, 2048x2048 square. Create an exact 2 by 2 grid with no margins, no divider, no text, each quadrant is one flat orthographic seamless tileable material sample, evenly lit with no baked lighting or perspective. Top left: weathered pale gray concrete plaster, fine pores and small chips, subtle warm mottling and faint water stains. Top right: desaturated gray painted steel with fine scratches, little edge wear, not corrugated. Bottom left: desaturated medium gray timber planks with convincing varied wood grain, subtle knots, narrow dark board gaps, planks run vertically. Bottom right: dark neutral asphalt and fine mineral aggregate with gentle dusty wear. Cohesive sophisticated realistic hand painted comic game material finish, tangible tactile materials, restrained values, no large conspicuous cracks or objects, no logos, no ambient shadows. Each tile fills exactly one quarter. Entire atlas usable as neutral luminance detail multiplied by game colors.
```

## smoke_particle_v103.png

Path: `assets/textures/smoke_particle_v103.png`. 1024×1024 requested; actual delivered file 1254×1254, transparent sprite.

Exact prompt:

```text
Use case: stylized-concept. Asset type: single VFX smoke particle sprite for real-time game rendering. One isolated turbulent billowing white-gray dust/smoke puff on a truly transparent background, square 1024x1024. Entire cloud fits within central 85% with soft wispy irregular perimeter that fades smoothly into genuine transparency. Rich layered swirls, small turbulent lobes, fine vapor wisps, dense luminous central mass, gently shaded lower creases. Realistic high quality cinematic smoke texture with a subtly hand-painted cartoon finish, desaturated neutral colors so it can be tinted for dust and explosion fire. Orthographic front view, no ground, no scene, no text, no frame, no hard spherical edge, no uniform circle, no black background. Preserve alpha in the delivered image.
```

## 1.0.4 anatomy and fonts

See [full anatomy provenance](../assets/human/CREDITS.md) and [CC0](../assets/human/source/LICENSE.ASSETS.md). Upstream revision `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`; original OBJ and male/female adult targets are preserved with SHA-256 hashes. No MakeHuman AGPL application code is included. `tools/bake_human.py` retargets and clothes the source; Godot bakes 15-bone skinning and distance LODs. This is a real mesh replacement, not a reskin of the old capsule face.

Rajdhani SemiBold (Latin/UI numerals) and Do Hyeon (Korean display text) are bundled from the official Google Fonts repository under SIL OFL. Exact URLs and SHA-256 hashes: [font manifest](../assets/fonts/manifest.json); license texts are alongside the fonts and in the Windows ZIP. Noto Sans KR remains a fallback.

This update introduces no new AI-generated raster imagery; the two textures above remain the unchanged 1.0.3 assets.
