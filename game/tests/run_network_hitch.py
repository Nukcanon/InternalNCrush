"""Host plus seven LAN clients; prints frame-gap and snapshot-cost summaries."""
import os,subprocess,tempfile,time
from pathlib import Path

project=Path(__file__).resolve().parents[1]
base=[os.environ.get('GODOT','godot'),'--headless','--path',str(project),'--script','res://tests/network_hitch_probe.gd','--']
with tempfile.TemporaryDirectory(prefix='inc-hitch-') as directory:
    control=Path(directory);processes=[];files=[]
    def launch(label):
        output=(control/(label+'.log')).open('w',encoding='utf-8');files.append(output)
        processes.append(subprocess.Popen(base+[f'--label={label}',f'--control={directory}'],stdout=output,stderr=subprocess.STDOUT))
    try:
        launch('server');deadline=time.monotonic()+120
        while not (control/'server.ready').exists():
            assert processes[0].poll() is None and time.monotonic()<deadline,'server not ready'
            time.sleep(.1)
        for i in range(7):launch(str(i));time.sleep(.5)
        for p in processes:p.wait(timeout=150)
    finally:
        for p in processes:
            if p.poll() is None:p.kill()
        for f in files:f.close()
        for path in sorted(control.glob('*.log')):
            text=path.read_text(encoding='utf-8',errors='replace')
            print(path.name,'\n'.join(l for l in text.splitlines() if 'HITCH' in l or 'ERROR' in l or 'SCRIPT' in l))
