"""Two separate ENet processes: queued loadout, elimination, respawn, firing."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

project = Path(__file__).resolve().parents[1]
base = [os.environ.get('GODOT', 'godot'), '--headless', '--path', str(project), '--max-fps', '30', '--script', 'tests/network_probe.gd']
with tempfile.TemporaryFile(mode='w+') as out:
    server = subprocess.Popen(base + ['--', '--probe-server'], stdout=out, stderr=subprocess.STDOUT)
    try:
        time.sleep(1)
        result = subprocess.run(base, capture_output=True, text=True, timeout=25)
        print(result.stdout, result.stderr)
        assert result.returncode == 0 and 'PROBE_RESPAWN_SHOT' in result.stdout, 'Network respawn/firing failed'
        assert 'SCRIPT ERROR' not in result.stdout and 'ERROR:' not in result.stdout, 'Runtime error'
    finally:
        server.terminate()
        server.wait(timeout=5)
        out.seek(0)
        print(out.read())
