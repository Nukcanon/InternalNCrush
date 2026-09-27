"""Convert explicitly downloaded CC0 diffuse maps; never fetch at game runtime.

Usage: python import_world_textures.py <download-directory>
Source files and authoritative URLs are recorded beside the shipped textures.
"""
import hashlib, json, sys
from pathlib import Path
from PIL import Image

source = Path(sys.argv[1])
out = Path(__file__).resolve().parents[1] / 'assets/textures/world'
assets = {
    'brick': ('brick', 'brick_wall_001'),
    'stone': ('rock_wall_02', 'rock_wall_02'),
    'paving': ('cobblestone_floor_01', 'cobblestone_floor_01'),
    'wood': ('wood_planks', 'wood_planks'),
    'concrete': ('concrete_floor_02', 'concrete_floor_02'),
    'earth': ('brown_mud_02', 'brown_mud_02'),
    'plaster': ('white_plaster_rough_01', 'white_plaster_rough_01'),
    'sandstone': ('large_sandstone_blocks', 'large_sandstone_blocks'),
    'rust': ('rusty_corrugated_iron', 'rusty_corrugated_iron'),
    'painted': ('painted_concrete', 'painted_concrete'),
    'moss': ('mossy_sandstone', 'mossy_sandstone'),
}
manifest = []
for target, (download, asset) in assets.items():
    original = source / (download + '-source.jpg')
    metadata = json.loads((source / (download + '-files.json')).read_text())
    diffuse = next(key for key in metadata if 'diff' in key.lower())
    entry = metadata[diffuse]['1k']['jpg']
    raw = original.read_bytes()
    assert hashlib.md5(raw).hexdigest() == entry['md5'], asset
    # Shared readable base material; no displacement or extra normal-map pass.
    Image.open(original).convert('RGB').resize((512,512), Image.Resampling.LANCZOS).save(out / (target+'.png'), optimize=True)
    settings=out/(target+'.png.import')
    if not settings.exists():
        settings.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\nsource_file="res://assets/textures/world/'+target+'.png"\n\n[params]\ncompress/mode=0\nmipmaps/generate=true\n')
    manifest.append({'file':target+'.png', 'asset':asset,
        'source':'https://polyhaven.com/a/'+asset, 'download':entry['url'],
        'source_sha256':hashlib.sha256(raw).hexdigest(),
        'license':'CC0-1.0', 'license_url':'https://polyhaven.com/license',
        'modification':'Diffuse only, resized to 512x512; Web build downsamples.'})
(out/'SOURCES.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
print('Imported', len(manifest), 'verified CC0 textures')
