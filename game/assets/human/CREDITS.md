# Human anatomy source

The operator anatomy in 1.1.0 is derived from the MakeHuman Community base mesh
and adult male/female shape targets, released as **CC0 1.0 Universal**.

- Project: https://github.com/makehumancommunity/makehuman
- Pinned revision: `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`
- Original geometry: `makehuman/data/3dobjs/base.obj`
- Shape data: `makehuman/data/targets/macrodetails/caucasian-{male,female}-young.target`
  and `universal-{male,female}-young-averagemuscle-averageweight.target`
- Upstream license explanation: https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md
- CC0 text is preserved in `source/LICENSE.ASSETS.md`. Data hashes are in `manifest.json`.

MakeHuman contributors authored the original mesh/targets. The game ships no
MakeHuman application code. The upstream application's AGPL code license is
separate from its CC0 graphical assets.

Game modifications: retarget to the 15-joint operator rig; garment surface
relaxation, fabric allowance and folds; class height/width variants; authored
skin weights, skin/lip/scalp colors, textile/skin shading, eyes and tactical gear.
The repository includes original data and `tools/bake_human.py` for an offline,
standard-library rebuild. `male.json` and `female.json` contain only the derived
anatomical surface and weights. The playable characters are clothed.

## 1.2.4 anatomical finishing

Nine additional **CC0** shape-data files from the same pinned MakeHuman revision
are recorded individually in `source/face-morphs-v124.json` with source URLs and
SHA-256 hashes. They refine the under-chin/neck volume, jaw projection, female
oval face, chin proportions, mouth corners and eyelids. They are applied **only
by the offline baker**: no runtime target loading or additional animation bones.
The shared body/shoulder rig is retained below the neckline. The neckline is cut
into the existing surface so skin and cloth no longer interpolate across a face.
Native faces use the existing CC0 male/female diffuse maps below, capped to
512px on import and shared across roles. Only luminance detail is combined with
the muted vertex palette. Web strips both maps and keeps its paint shader.

## Skin textures in 1.1.0

Four UV-aligned diffuse textures come from the official MakeHuman Community **CC0 system assets** pack, with original archive paths and SHA-256 values in `textures/origin.json`. This includes young Caucasian male/female, young African male and young Asian female skins. Upstream material metadata is preserved in `textures/upstream-materials.txt`. The game desaturates/redness-corrects these textures and combines them with original clothing and equipment materials.

The microdetail atlas `../textures/operator_materials_v11.png` was generated with OpenAI image generation for this project on 2026-09-24; prompt and use are recorded beside it in `operator_materials_v11.provenance.json`. It contains skin, ripstop, glove leather and hair swatches, not a third-party photographed person. Geometry remains the CC0-derived rigged mesh. Eyes, hats, gear, garment shading and first-person arm/hand geometry are original game work.
