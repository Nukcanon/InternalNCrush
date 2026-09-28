"""Two real ENet peers validate replication and authoritative bot controls."""
from pathlib import Path
import os,subprocess,time
project=Path(__file__).resolve().parents[1]
out=project.parent/'validation/bot-network';out.mkdir(parents=True,exist_ok=True)
base=[os.environ.get('GODOT','godot'),'--headless','--path',str(project),'--script','res://tests/network_bot_settings.gd','--','--no-save-profile','--no-update-check']
flags=getattr(subprocess,'CREATE_NO_WINDOW',0)
with (out/'host.log').open('w',encoding='utf-8') as log:
    host=subprocess.Popen(base+['--bot-host'],stdout=log,stderr=subprocess.STDOUT,creationflags=flags)
    try:
        time.sleep(2)
        guest=subprocess.run(base,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=40,creationflags=flags)
        (out/'guest.log').write_text(guest.stdout+guest.stderr,encoding='utf-8')
        assert guest.returncode==0 and 'BOT_NETWORK_PASS' in guest.stdout,guest.stdout+guest.stderr
        assert host.poll() is None,'Host failed'
    finally:
        if host.poll() is None:host.terminate()
        host.wait(timeout=10)
assert 'ERROR' not in (out/'guest.log').read_text(encoding='utf-8')
assert 'ERROR' not in (out/'host.log').read_text(encoding='utf-8')
print('BOT_NETWORK_PASS')
