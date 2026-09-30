"""Fetch the CC0 ambientCG materials used by 1.5 world surfaces and bake them
into single-channel detail maps (game/assets/textures/detail/<slot>.png).

Only relief is kept: the colour map becomes high-passed luminance and the
normal map is baked into a fixed top-left emboss. The result is levelled to a
mean of 0.5 so the game's own palette colours are modulated by it (joints,
grain, ridges) and the source photograph itself is not reused.
Sources are downloaded to ../.tools/ambientcg (outside the repository).
"""
import io, json, sys, urllib.request, zipfile
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
CACHE = ROOT.parent / '.tools/ambientcg'
OUT = ROOT / 'game/assets/textures/detail'
UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
# slot: (ambientCG asset id, luminance weight, emboss weight)
SLOTS = {
    'asphalt': ('Asphalt031', 1.0, .4), 'concrete': ('Concrete042A', 1.0, .5), 'paving': ('PavingStones146', .8, .8),
    'cobble': ('PavingStones151', .8, .8), 'setts': ('PavingStones070', .7, .9), 'sand': ('Ground054', .8, .6),
    'dirt': ('Ground079S', .8, .6), 'gravel': ('Gravel023', .8, .7), 'grass': ('Grass004', .8, .5),
    'steel_floor': ('DiamondPlate008D', .4, 1.2), 'wood_floor': ('WoodFloor041', 1.0, .5), 'planks': ('Planks037A', 1.0, .6),
    'tiles_white': ('Tiles107', .8, .8), 'tiles_stone': ('Tiles141', .9, .6), 'brick_red': ('Bricks101', .9, .7),
    'brick_yellow': ('Bricks105', .9, .7), 'brick_old': ('Bricks097', .9, .7), 'stone_wall': ('Bricks075A', .8, .8),
    'plaster': ('Plaster001', 1.2, .5), 'concrete_wall': ('Concrete048', 1.0, .6), 'corrugated': ('CorrugatedSteel005', .5, 1.2),
    'rock': ('Rock051', .8, .8), 'roof_tiles': ('RoofingTiles012A', .7, 1.0), 'rust': ('Metal022', 1.0, .3)}
SIZE = 1024
# Sources with large stains keep only their finer grain (high-pass divisor).
HIGHPASS = {'Concrete042A': 64, 'Concrete048': 40, 'Plaster001': 32, 'Metal022': 32}
LIGHT = np.array([-.45, .55, .70]) / np.linalg.norm([-.45, .55, .70])


def download(asset):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / (asset + '_1K-JPG.zip')
    if not path.exists():
        url = 'https://ambientcg.com/get?file=%s_1K-JPG.zip' % asset
        path.write_bytes(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120).read())
    return path


def highpass(img, radius):
    arr = np.asarray(img, dtype=np.float32)
    low = np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32)
    return arr - low


def detail(asset, lum_weight, emboss_weight):
    with zipfile.ZipFile(download(asset)) as z:
        names = z.namelist()
        read = lambda suffix: next((Image.open(io.BytesIO(z.read(n))) for n in names if n.endswith(suffix)), None)
        colour, normal = read('_Color.jpg'), read('_NormalGL.jpg')
    grey = colour.convert('L').resize((SIZE, SIZE), Image.LANCZOS)
    # Large-scale lighting drift removed so repeats do not show blotches.
    lum = highpass(grey, SIZE / HIGHPASS.get(asset, 16))
    lum /= max(1., lum.std())
    total = lum * lum_weight
    if normal is not None:
        n = np.asarray(normal.convert('RGB').resize((SIZE, SIZE), Image.LANCZOS), dtype=np.float32) / 127.5 - 1.
        shade = n @ LIGHT
        shade = shade - shade.mean()
        total += shade / max(1e-3, shade.std()) * emboss_weight
    total /= max(1e-3, total.std())
    out = np.clip(128 + total * 30., 0, 255).astype(np.uint8)
    return Image.fromarray(out, 'L')


def main(slots):
    OUT.mkdir(parents=True, exist_ok=True)
    for slot in slots:
        asset, lum, emboss = SLOTS[slot]
        detail(asset, lum, emboss).save(OUT / (slot + '.png'), optimize=True)
        print('DETAIL', slot, asset, (OUT / (slot + '.png')).stat().st_size // 1024, 'KB')
    sources = [{'file': k + '.png', 'asset': v[0], 'source': 'https://ambientcg.com/view?id=' + v[0], 'license': 'CC0-1.0',
                'license_url': 'https://docs.ambientcg.com/license/',
                'modification': 'Colour luminance high-passed and mixed with a baked NormalGL emboss into one grey relief channel, levelled, 1024 px; tinted in game by map palettes.'}
               for k, v in SLOTS.items()]
    (OUT / 'SOURCES.json').write_text(json.dumps(sources, indent=1))


if __name__ == '__main__':
    main(sys.argv[1:] or list(SLOTS))
