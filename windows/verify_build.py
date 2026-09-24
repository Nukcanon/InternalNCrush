"""Verify a Windows release ZIP using its own EXE, including graphical networking.

Run on Windows with an available desktop/GPU. The test uses a separate port,
does not save player settings, and stops only processes that it started.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--zip', required=True, type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--port', type=int, default=32888)
    args = parser.parse_args()
    if sys.platform != 'win32':
        parser.error('This checks native Windows execution; run it on Windows.')
    if not 1024 <= args.port <= 65533:
        parser.error('Port must be between 1024 and 65533.')
    if not re.fullmatch(r'[0-9a-f]{40}', args.source_commit):
        parser.error('Provide the exact 40-character build source commit.')
    archive = args.zip.resolve()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    destination = output / 'unpacked'

    def endpoints(pid=None):
        selector = f'-OwningProcess {pid}' if pid is not None else f'-LocalPort {args.port}'
        command = (f'Get-NetUDPEndpoint {selector} -ErrorAction SilentlyContinue | '
                   f'Where-Object LocalPort -eq {args.port} | Select-Object -ExpandProperty LocalPort')
        return subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', command],
                              capture_output=True, text=True,
                              creationflags=subprocess.CREATE_NO_WINDOW).stdout.strip()

    if endpoints():
        parser.error(f'Port {args.port} is already in use; choose another --port.')
    with zipfile.ZipFile(archive) as package:
        names = package.namelist()
        assert package.testzip() is None and len(names) == 21, 'Release ZIP integrity or manifest mismatch'
        assert all((destination / name).resolve().is_relative_to(destination) for name in names)
        package.extractall(destination)
    binary = destination / 'InternalNCrush/InternalNCrush.exe'
    assert binary.read_bytes()[:2] == b'MZ'
    assert binary.with_suffix('.pck').read_bytes()[:4] == b'GDPC'
    checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / 'SHA256SUMS.txt').write_text(f'{checksum}  {archive.name}\n', encoding='utf-8')
    result = {'bytes': archive.stat().st_size, 'sha256': checksum, 'files': len(names),
              'source_commit': args.source_commit, 'native_runs': []}
    env = os.environ.copy()
    env['INC_TEST_PORT'] = str(args.port)
    common = ['--no-save-profile', '--no-update-check']

    def stop(process):
        if process.poll() is None:
            subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], capture_output=True,
                           creationflags=subprocess.CREATE_NO_WINDOW)
            process.wait(timeout=15)

    def launch(arguments, log):
        return subprocess.Popen([str(binary), '--log-file', str(log)] + arguments,
                                cwd=binary.parent, env=env, creationflags=subprocess.CREATE_NO_WINDOW)

    def inspect(process, mode, log, capture):
        try:
            code = process.wait(timeout=120)
        except subprocess.TimeoutExpired:
            stop(process)
            raise
        content = log.read_text(encoding='utf-8', errors='replace')
        errors = sorted(set(line for line in content.splitlines()
                            if 'ERROR' in line and 'Texture with GL ID' not in line))
        assert code == 0 and capture.exists() and 'TEST_EXIT' in content, (mode, code, content[-1600:])
        assert not errors, (mode, errors[:8])
        record = {'mode': mode, 'exit': code,
                  'test_exit': [line for line in content.splitlines() if 'TEST_EXIT' in line],
                  'known_shutdown_texture_warning': 'Texture with GL ID' in content}
        result['native_runs'].append(record)
        print('WINDOWS_EXE_OK', record, flush=True)
        return content

    for mode in ['practice', 'training']:
        log, capture = output / f'windows-{mode}.log', output / f'windows-{mode}.png'
        inspect(launch(['--', f'--{mode}', f'--capture={capture}', '--quit-test'] + common, log),
                mode, log, capture)
    for host_mode in ['headless', 'window']:
        host_log = output / f'windows-network-{host_mode}-host.log'
        host = launch((['--headless'] if host_mode == 'headless' else []) +
                      ['--', '--host-test', '--nick=VERIFY_HOST'] + common, host_log)
        try:
            deadline = time.monotonic() + 40
            # Headless release logs are buffered until exit. Read the owning
            # process's socket, not stdout; IPv6 ENet can also allow IPv4 bind probes.
            while not endpoints(host.pid):
                assert host.poll() is None and time.monotonic() < deadline, 'Host readiness timed out'
                time.sleep(.25)
            mode = f'network-client-{host_mode}-host'
            log, capture = output / f'windows-{mode}.log', output / f'windows-{mode}.png'
            content = inspect(launch(['--', '--connect=127.0.0.1', '--nick=VERIFY_CLIENT',
                                      f'--capture={capture}', '--quit-test'] + common, log),
                              mode, log, capture)
            assert 'TEST_EXIT players=2 phase=combat' in content, content[-1600:]
        finally:
            stop(host)
    result['windows_exe_loopback_connection'] = True
    (output / 'verification.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print('WINDOWS_PACKAGE_VERIFIED', checksum, flush=True)


if __name__ == '__main__':
    main()
