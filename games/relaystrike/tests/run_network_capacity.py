"""Verify 32 distinct ENet clients can join one dedicated server."""
import os
import subprocess
import tempfile
import time
from pathlib import Path

project = Path(__file__).resolve().parents[1]
base = [os.environ.get('GODOT', 'godot'), '--headless', '--path', str(project), '--max-fps', '20']
with tempfile.TemporaryDirectory(prefix='inc-capacity-') as directory:
    logs = Path(directory)
    files, clients = [], []
    host_log = (logs / 'server.log').open('w')
    server = subprocess.Popen(base + ['--', '--server'], stdout=host_log, stderr=subprocess.STDOUT)
    try:
        time.sleep(2)
        for i in range(32):
            output = (logs / f'client{i}.log').open('w')
            files.append(output)
            clients.append(subprocess.Popen(base + ['--', '--connect=127.0.0.1', f'--nick=CAPACITY_{i:02d}', '--quit-test'], stdout=output, stderr=subprocess.STDOUT))
            time.sleep(.08)
        for client in clients:
            client.wait(timeout=40)
        for output in files:
            output.flush()
        host_log.flush()
        content = (logs / 'server.log').read_text(encoding='utf-8', errors='replace')
        assert 'count=32' in content, content[-2000:]
        assert all(client.returncode == 0 for client in clients)
        for path in logs.glob('*.log'):
            text = path.read_text(encoding='utf-8', errors='replace')
            assert 'ERROR' not in text, (path.name, text[-2000:])
            if path.name != 'server.log':
                assert 'TEST_EXIT players=' in text, (path.name, text[-1000:])
        print('NETWORK_CAPACITY_OK 32 distinct connected clients; all exited without runtime errors')
    finally:
        for process in clients + [server]:
            if process.poll() is None:
                process.terminate()
        for process in clients + [server]:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
        for output in files + [host_log]:
            output.close()
