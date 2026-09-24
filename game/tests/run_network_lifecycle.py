"""Real ENet peers with an explicit client/server completion barrier.

LIFECYCLE_STAGGER=1.5 reproduces the old teardown race's late-start condition.
Every client still needs 105 seconds, fresh snapshots, reconnect and population 8.
"""
import os
import socket
import subprocess
import tempfile
import time
from pathlib import Path

project = Path(__file__).resolve().parents[1]
base = [os.environ.get('GODOT', 'godot'), '--headless', '--path', str(project),
        '--max-fps', '20', '--script', 'res://tests/network_lifecycle.gd']
probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    probe.bind(('127.0.0.1', max(1024,min(65533,int(os.environ.get('INC_TEST_PORT','27888'))))))
finally:
    probe.close()
stagger = float(os.environ.get('LIFECYCLE_STAGGER', '.15'))
with tempfile.TemporaryDirectory(prefix='inc-lifecycle-') as directory:
    logs = Path(directory)
    processes, files = [], []
    def launch(name, args):
        output = (logs / (name + '.log')).open('w', encoding='utf-8')
        files.append(output)
        process = subprocess.Popen(base + ['--', '--life-control=' + str(logs)] + args,
                                   stdout=output, stderr=subprocess.STDOUT)
        processes.append(process)
    try:
        launch('server', ['--life-server'])
        time.sleep(2)
        for i in range(8):
            launch(f'client{i}', [f'--life-id={i}'])
            time.sleep(stagger)
        deadline = time.monotonic() + 190
        while not (logs / 'server.ok').exists():
            if any(p.poll() is not None for p in processes):
                raise RuntimeError('Peer exited before the completion barrier')
            if time.monotonic() > deadline:
                raise TimeoutError('Completion barrier not reached')
            time.sleep(.1)
        assert all((logs / f'client{i}.ok').exists() for i in range(8))
        (logs / 'release').write_text('All assertions completed', encoding='utf-8')
        for process in processes:
            process.wait(timeout=15)
        assert all(p.returncode == 0 for p in processes)
        for output in files:
            output.flush()
        assert not any('ERROR' in p.read_text(encoding='utf-8', errors='replace')
                       for p in logs.glob('*.log'))
        print(f'NETWORK_LIFECYCLE_OK 8 peers; 105 seconds each; stagger={stagger}; completion barrier; reconnect + server restart')
    finally:
        for process in processes:
            if process.poll() is None:
                process.terminate()
        for process in processes:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        for output in files:
            output.close()
        for path in sorted(logs.glob('*.log')):
            content = path.read_text(encoding='utf-8', errors='replace')
            print(path.name, '\n'.join(line for line in content.splitlines()
                  if any(k in line for k in ['JOINED', 'LIFECYCLE', 'RESTART', 'ERROR', 'Error'])))
