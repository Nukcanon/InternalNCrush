# Human anatomy source

The operator anatomy in 1.0.4 is derived from the MakeHuman Community base mesh
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
