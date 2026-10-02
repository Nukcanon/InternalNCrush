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

## Skin textures in 1.1.0

Four UV-aligned diffuse textures come from the official MakeHuman Community **CC0 system assets** pack, with original archive paths and SHA-256 values in `textures/origin.json`. This includes young Caucasian male/female, young African male and young Asian female skins. Upstream material metadata is preserved in `textures/upstream-materials.txt`. The game desaturates/redness-corrects these textures and combines them with original clothing and equipment materials.

The microdetail atlas `../textures/operator_materials_v11.png` was generated with OpenAI image generation for this project on 2026-09-24; prompt and use are recorded beside it in `operator_materials_v11.provenance.json`. It contains skin, ripstop, glove leather and hair swatches, not a third-party photographed person. Geometry remains the CC0-derived rigged mesh. Eyes, hats, gear, garment shading and first-person arm/hand geometry are original game work.
