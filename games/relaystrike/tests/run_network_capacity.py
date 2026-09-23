"""Hold all 32 clients until every peer has a current 32-player snapshot."""
import os,socket,subprocess,tempfile,time
from pathlib import Path

project=Path(__file__).resolve().parents[1]
base=[os.environ.get('GODOT','godot'),'--headless','--path',str(project),'--max-fps','20','--script','res://tests/network_capacity.gd','--']
with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as probe:
    probe.bind(('127.0.0.1',27888))
with tempfile.TemporaryDirectory(prefix='inc-capacity-') as directory:
    control=Path(directory);files=[];processes=[]
    def launch(label):
        output=(control/(label+'.log')).open('w',encoding='utf-8');files.append(output)
        processes.append(subprocess.Popen(base+[f'--label={label}',f'--control={directory}'],stdout=output,stderr=subprocess.STDOUT))
    try:
        launch('server');deadline=time.monotonic()+180
        while not (control/'server.ready').exists():
            assert processes[0].poll() is None and time.monotonic()<deadline,'Server not ready'
            time.sleep(.1)
        for i in range(32):
            launch(str(i))
            # Keep existing clients connected while pacing cold process startup on CI.
            while not (control/f'client{i}.ready').exists():
                assert all(p.poll() is None for p in processes),'Peer left during startup'
                assert time.monotonic()<deadline,f'Client {i} did not finish joining'
                time.sleep(.1)
            time.sleep(float(os.environ.get('CAPACITY_STAGGER','.08')))
        while not (control/'server.ok').exists():
            assert all(p.poll() is None for p in processes),'Peer left before capacity barrier'
            assert time.monotonic()<deadline,'Capacity barrier timeout'
            time.sleep(.1)
        (control/'release').write_text('All 32 clients verified',encoding='utf-8')
        for p in processes:p.wait(timeout=20)
        assert all(p.returncode==0 for p in processes)
        for output in files:output.flush()
        for path in control.glob('*.log'):
            text=path.read_text(encoding='utf-8',errors='replace')
            assert 'ERROR' not in text,(path.name,text[-1500:])
            assert ('CAPACITY_SERVER_OK' if path.name=='server.log' else 'CAPACITY_CLIENT_OK') in text
        print('NETWORK_CAPACITY_OK 32 simultaneous clients; all confirmed fresh 32-player state; completion barrier')
    finally:
        for p in processes:
            if p.poll() is None:p.terminate()
        for p in processes:
            try:p.wait(timeout=5)
            except subprocess.TimeoutExpired:p.kill();p.wait(timeout=5)
        for output in files:output.close()
        for path in sorted(control.glob('*.log')):
            print(path.name,'\n'.join(line for line in path.read_text(encoding='utf-8',errors='replace').splitlines() if any(key in line for key in ['CAPACITY_','ERROR','Error'])))
