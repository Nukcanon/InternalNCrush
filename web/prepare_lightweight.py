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
    project = STAGE / "project.godot"
    project.write_text(project.read_text().replace("[application]", "[application]\nconfig/web_assets=true"))
    # Comic operators/hands no longer load photo atlases. Remove only assets
    # with no runtime references; preserve smoke, all maps and every game mode.
    for folder in ['assets/human/textures']:
        shutil.rmtree(STAGE / folder, ignore_errors=True)
    for suffix in ['', '.import']:
        (STAGE / 'assets' / ('menu_action.ogv' + suffix)).unlink(missing_ok=True)
    # Sequential editor import is inherited from the common project settings.
    converted = []
    for p in (STAGE / 'assets').rglob('*.png'):
        if 'source' in p.parts:
            continue
        with Image.open(p) as source:
            picture = source.convert('RGBA' if 'A' in source.getbands() else 'RGB')
            before = picture.size
            limit = 1920 if 'menu_slides' in p.parts else 192 if 'thumbnails' in p.parts else 128
            picture.thumbnail((limit, limit), Image.Resampling.LANCZOS)
            picture.save(p, optimize=True)
            converted.append({'path': str(p.relative_to(STAGE)), 'before': before, 'after': picture.size})
        imported = Path(str(p) + '.import')
        if imported.exists():
            imported.unlink()
    for p in (STAGE / 'scripts').glob('*.gd'):
        text = p.read_text(encoding='utf-8').replace('res://assets/Korean.ttf', 'res://assets/fonts/DoHyeon-Regular.ttf')
        if p.name=='surface_finish.gd':
            # Strip native-only texture paths from the exported Web project.
            text='extends RefCounted\nclass_name SurfaceFinish\nstatic func human_material(_role:int=0) -> ShaderMaterial:return ToonMaterials.vertex_material()\nstatic func hand_material(color:Color,_kind:int) -> ShaderMaterial:return ToonMaterials.color_material(color)\nstatic func equipment_material() -> ShaderMaterial:return ToonMaterials.vertex_material()\nstatic func world_material() -> ShaderMaterial:return ToonMaterials.vertex_material()\n'+text[text.index('static func material_kind'):text.index('static func equipment_material')]
        if p.name=='human_model.gd':
            # Only the shared loft helper still used for first-person hands.
            text=text.replace('range(3):','range(1):').replace('var t=step/3.','var t=step/1.')
        p.write_text(text, encoding='utf-8')
    # Packed arena labels retain this resource path: provide the smaller font there too.
    shutil.copyfile(STAGE / 'assets/fonts/DoHyeon-Regular.ttf', STAGE / 'assets/Korean.ttf')
    original_import = STAGE / 'assets/Korean.ttf.import'
    if original_import.exists():
        original_import.unlink()
    preset = STAGE / 'export_presets.cfg'
    text = preset.read_text(encoding='utf-8')
    text = text.replace('assets/human/source/*', 'assets/human/source/*,assets/human/male.json,assets/human/female.json,assets/arenas/geometry/*,assets/textures/field_materials_v103.png,assets/textures/operator_materials_v11.png')
    preset.write_text(text, encoding='utf-8')
    (ROOT / 'web/staging/asset_report.json').write_text(json.dumps(converted, indent=2), encoding='utf-8')
    print('LIGHTWEIGHT_WEB_PROJECT', STAGE, 'textures', len(converted))

if __name__ == '__main__':
    main()

