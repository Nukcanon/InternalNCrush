"""Package only runtime files and redistribution notices, with no stale build files."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
import zipfile

PROJECT = Path(__file__).resolve().parents[1]


def validate_native_pack(path: Path):
    """Editor previews cannot catch missing dependencies excluded from exports."""
    with path.open('rb') as pack:
        assert pack.read(4) == b'GDPC', 'Expected a Godot resource pack'
        pack.seek(24)
        base = struct.unpack('<Q', pack.read(8))[0]
        pack.seek(96)
        count = struct.unpack('<I', pack.read(4))[0]
        entries = {}
        for _ in range(count):
            length = struct.unpack('<I', pack.read(4))[0]
            name = pack.read(length).rstrip(b'\0').decode()
            offset, size = struct.unpack('<QQ', pack.read(16))
            pack.read(20)
            entries[name] = (offset + base, size)

        for kind in ('turret', 'cover'):
            for team in range(2):
                assert f'assets/models/device_{kind}{team}.scn' in entries, 'Missing baked deployment geometry'
        for weapon in json.loads((PROJECT / 'assets/weapons.json').read_text(encoding='utf-8')):
            assert f'assets/thumbnails/{weapon}.png.import' in entries, 'Missing equipment thumbnail: ' + weapon
        for gender in ('male', 'female'):
            name = f'assets/human/textures/{gender}.png.import'
            assert name in entries, 'Missing native face import: ' + name
            offset, size = entries[name]
            pack.seek(offset)
            imported = pack.read(size).decode()
            paths = re.findall(r'^path(?:\.[a-z0-9_]+)?="res://([^"\n]+)"', imported, re.M)
            assert paths and all(p in entries for p in paths), 'Missing imported face texture: ' + name


def package(build_dir: Path, output_dir: Path) -> Path:
    version = re.search(r'config/version="([^"]+)"', (PROJECT / 'project.godot').read_text()).group(1)
    files = {
        'InternalNCrush.exe': build_dir / 'InternalNCrush.exe',
        'InternalNCrush.pck': build_dir / 'InternalNCrush.pck',
        'StartServer.cmd': PROJECT / 'tools/StartServer.cmd',
        'licenses/GAME_LICENSE.txt': PROJECT / 'LICENSE.txt',
        'licenses/GODOT_LICENSE.txt': PROJECT / 'GODOT_LICENSE.txt',
        'licenses/FONT_LICENSE.txt': PROJECT / 'assets/FONT_LICENSE.txt',
        'licenses/RAJDHANI_OFL.txt': PROJECT / 'assets/fonts/rajdhani-OFL.txt',
        'licenses/DOHYEON_OFL.txt': PROJECT / 'assets/fonts/dohyeon-OFL.txt',
        'licenses/MAKEHUMAN_CC0.md': PROJECT / 'assets/human/source/LICENSE.ASSETS.md',
        'licenses/MAKEHUMAN_PROVENANCE.md': PROJECT / 'assets/human/CREDITS.md',
        'licenses/AUDIO_Q009_LICENSE.txt': PROJECT / 'assets/AUDIO_Q009_LICENSE.txt',
        'licenses/AUDIO_KENNEY_LICENSE.txt': PROJECT / 'assets/AUDIO_KENNEY_LICENSE.txt',
        'licenses/AUDIO_KOKORO_LICENSE.txt': PROJECT / 'assets/AUDIO_KOKORO_LICENSE.txt',
        'licenses/SOUND_CREDITS.md': PROJECT / 'SOUND_CREDITS.md',
        'licenses/ART_CREDITS.md': PROJECT / 'ART_CREDITS.md',
    }
    library='libwebrtc_native.windows.template_release.x86_64.dll'
    files[library]=build_dir/library
    for notice in sorted((PROJECT/'addons/webrtc_native').glob('LICENSE.*')):
        files['licenses/webrtc/'+notice.name]=notice
    for pack in ['industrial', 'car', 'nature', 'watercraft']:
        files['licenses/art/'+pack+'.txt']=PROJECT/'assets/models'/pack/'LICENSE.txt'
    for name, source in files.items():
        if not source.is_file() or source.stat().st_size == 0:
            raise SystemExit(f'Missing release input: {name}')
    with files['InternalNCrush.exe'].open('rb') as executable:
        if executable.read(2) != b'MZ':
            raise SystemExit('Expected a Windows executable')
    validate_native_pack(files['InternalNCrush.pck'])
    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f'InternalNCrush_Windows_v{version}.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, source in sorted(files.items()):
            entry = zipfile.ZipInfo('InternalNCrush/' + name, (2026, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, source.read_bytes(), compresslevel=9)
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None or len(archive.namelist()) != len(files):
            raise SystemExit('Release archive integrity check failed')
    checksum = hashlib.sha256(output.read_bytes()).hexdigest()
    (output_dir / 'SHA256SUMS.txt').write_text(f'{checksum}  {output.name}\n')
    print(f'RELEASE_OK {output.name}: {len(files)} files, {output.stat().st_size} bytes, sha256={checksum}')
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--build-dir', required=True, type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    package(args.build_dir, args.output_dir)
