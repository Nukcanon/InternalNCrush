# Environment art sources

Original map layouts, procedural architecture, weapons, equipment, material
shaders and modifications are maintained in this repository.

The following selected assets are distributed under CC0:

- [Poly Haven textures](https://polyhaven.com/license): brick wall, rock wall,
  cobblestone floor, wood planks, concrete floor, mud, plaster, sandstone,
  rusty corrugated iron, painted concrete and mossy sandstone. Exact asset IDs,
  download URLs, source checksums and conversions are recorded in
  `assets/textures/world/SOURCES.json`.
- [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial):
  containers and tanks.
- [Kenney Car Kit](https://kenney.nl/assets/car-kit): sedan, taxi and van.
- [Kenney Nature Kit](https://kenney.nl/assets/nature-kit): oak, pine and rock.
- [Kenney Watercraft Kit](https://kenney.nl/assets/watercraft-kit): small fishing
  boat and tug.

Each selected model pack retains its license and archive checksum under
`assets/models/<pack>/`. Scale, placement, collision and material integration
are performed by the game's build tools. Web and Windows use the same gameplay
silhouettes; Web uses smaller world textures.

Character anatomy provenance is in `assets/human/CREDITS.md`. No DEADSHOT game
files or proprietary Counter-Strike map/texture files are included.
