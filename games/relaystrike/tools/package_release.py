"""Package only runtime files and redistribution notices, with no stale build files."""
from pathlib import Path
import argparse
import hashlib
import re
import zipfile

PROJECT = Path(__file__).resolve().parents[1]


def package(build_dir: Path, output_dir: Path) -> Path:
    version = re.search(r'config/version="([^"]+)"', (PROJECT / 'project.godot').read_text()).group(1)
    files = {
        'InternalNCrush.exe': build_dir / 'InternalNCrush.exe',
        'InternalNCrush.pck': build_dir / 'InternalNCrush.pck',
        'StartServer.cmd': PROJECT / 'tools/StartServer.cmd',
        'licenses/GAME_LICENSE.txt': PROJECT / 'LICENSE.txt',
        'licenses/GODOT_LICENSE.txt': PROJECT / 'GODOT_LICENSE.txt',
        'licenses/FONT_LICENSE.txt': PROJECT / 'assets/FONT_LICENSE.txt',
        'licenses/AUDIO_Q009_LICENSE.txt': PROJECT / 'assets/AUDIO_Q009_LICENSE.txt',
        'licenses/AUDIO_KENNEY_LICENSE.txt': PROJECT / 'assets/AUDIO_KENNEY_LICENSE.txt',
        'licenses/SOUND_CREDITS.md': PROJECT / 'SOUND_CREDITS.md',
    }
    for name, source in files.items():
        if not source.is_file() or source.stat().st_size == 0:
            raise SystemExit(f'Missing release input: {name}')
    with files['InternalNCrush.exe'].open('rb') as executable:
        if executable.read(2) != b'MZ':
            raise SystemExit('Expected a Windows executable')
    with files['InternalNCrush.pck'].open('rb') as pack:
        if pack.read(4) != b'GDPC':
            raise SystemExit('Expected a Godot resource pack')
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
