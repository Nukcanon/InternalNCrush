"""Headless host with seven bots plus one rendered client; prints spike summary."""
import os,subprocess,sys,tempfile,time
from pathlib import Path

project=Path(__file__).resolve().parents[1]
godot=os.environ.get('GODOT','godot')
extra=sys.argv[1:]
with tempfile.TemporaryDirectory(prefix='inc-rhitch-') as directory:
    control=Path(directory)
    server_log=(control/'server.log').open('w',encoding='utf-8');client_log=(control/'client.log').open('w',encoding='utf-8')
    server=subprocess.Popen([godot,'--headless','--path',str(project),'--script','res://tests/render_hitch_probe.gd','--','--label=server',f'--control={directory}'],stdout=server_log,stderr=subprocess.STDOUT)
    client=None
    try:
        deadline=time.monotonic()+120
        while not (control/'server.ready').exists():
            assert server.poll() is None and time.monotonic()<deadline,'server not ready'
            time.sleep(.1)
        client=subprocess.Popen([godot,'--path',str(project),*extra,'--script','res://tests/render_hitch_probe.gd','--','--label=client',f'--control={directory}','--no-save-profile'],stdout=client_log,stderr=subprocess.STDOUT)
        client.wait(timeout=160);server.wait(timeout=30)
    finally:
        for p in [server,client]:
            if p and p.poll() is None:p.kill()
        server_log.close();client_log.close()
        for name in ['server.log','client.log']:
            text=(control/name).read_text(encoding='utf-8',errors='replace')
            lines=[l for l in text.splitlines() if 'HITCH' in l or 'SCRIPT ERROR' in l]
            print(name,'\n'.join(l for l in lines if 'HITCH_SPIKE ' not in l))
            print('\n'.join([l[:400] for l in lines if 'HITCH_SPIKE ' in l][:12]))
