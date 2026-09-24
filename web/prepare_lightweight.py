"""Create an isolated browser project; never downgrade native release assets."""
from pathlib import Path
import shutil
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'game'
STAGE = ROOT / 'web/staging/game'

def main():
    assert STAGE.resolve().is_relative_to((ROOT / 'web/staging').resolve())
    if STAGE.exists():
        shutil.rmtree(STAGE)
    shutil.copytree(SOURCE, STAGE, ignore=shutil.ignore_patterns('.godot', '*.glb', '*.uid', '__pycache__'))
    converted = []
    for p in (STAGE / 'assets').rglob('*.png'):
        if 'source' in p.parts:
            continue
        with Image.open(p) as source:
            picture = source.convert('RGBA' if 'A' in source.getbands() else 'RGB')
            before = picture.size
            limit = 192 if 'thumbnails' in p.parts else 512
            picture.thumbnail((limit, limit), Image.Resampling.LANCZOS)
            picture.save(p, optimize=True)
            converted.append({'path': str(p.relative_to(STAGE)), 'before': before, 'after': picture.size})
        imported = Path(str(p) + '.import')
        if imported.exists():
            imported.unlink()
    for p in (STAGE / 'scripts').glob('*.gd'):
        text = p.read_text(encoding='utf-8').replace('res://assets/Korean.ttf', 'res://assets/fonts/DoHyeon-Regular.ttf')
        p.write_text(text, encoding='utf-8')
    # Packed arena labels retain this resource path: provide the smaller font there too.
    shutil.copyfile(STAGE / 'assets/fonts/DoHyeon-Regular.ttf', STAGE / 'assets/Korean.ttf')
    original_import = STAGE / 'assets/Korean.ttf.import'
    if original_import.exists():
        original_import.unlink()
    preset = STAGE / 'export_presets.cfg'
    text = preset.read_text(encoding='utf-8')
    text = text.replace('assets/human/source/*"', 'assets/human/source/*,assets/human/male.json,assets/human/female.json,assets/arenas/geometry/*"')
    preset.write_text(text, encoding='utf-8')
    (ROOT / 'web/staging/asset_report.json').write_text(json.dumps(converted, indent=2), encoding='utf-8')
    print('LIGHTWEIGHT_WEB_PROJECT', STAGE, 'textures', len(converted))

if __name__ == '__main__':
    main()
