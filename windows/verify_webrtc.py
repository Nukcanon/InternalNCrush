"""Exercise a packaged EXE/PCK using the external WebRTC integration fixture.

Install services/directory/requirements.txt first. The fixture is external, but
game scripts and resources load from the explicit release PCK, not game/.
"""
import argparse
import importlib.util
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', required=True, type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('validation/webrtc-windows-package'))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    binary = args.exe.resolve()
    pack = binary.with_suffix('.pck')
    if not binary.is_file() or not pack.is_file():
        parser.error('Expected an extracted Windows EXE and its adjacent PCK.')
    original = subprocess.Popen

    class PackProcess(original):
        def __init__(self, command, *positional, **keywords):
            if 'res://tests/network_rtc.gd' in command:
                command = list(command)
                command[0] = str(binary)
                index = command.index('--path')
                del command[index:index + 2]
                command[command.index('--script') + 1] = str(root / 'game/tests/network_rtc.gd')
                command[1:1] = ['--main-pack', str(pack)]
            super().__init__(command, *positional, **keywords)

    spec = importlib.util.spec_from_file_location('pack_rtc_fixture', root / 'game/tests/run_network_rtc.py')
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.OUT = args.output_dir.resolve()
    try:
        subprocess.Popen = PackProcess
        fixture.main()
    finally:
        subprocess.Popen = original
    print('PACKAGED_WINDOWS_WEBRTC_OK', binary, flush=True)


if __name__ == '__main__':
    main()
