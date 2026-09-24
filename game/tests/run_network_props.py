"""Server physics, interpolated client state and a client joining after the shot."""
import os,socket,subprocess,tempfile,time
from pathlib import Path

project=Path(__file__).resolve().parents[1]
with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as probe:
    probe.bind(('127.0.0.1',max(1024,min(65533,int(os.environ.get('INC_TEST_PORT','27888'))))))
base=[os.environ.get('GODOT','godot'),'--headless','--path',str(project),'--max-fps','60','--script','res://tests/network_props.gd','--']
with tempfile.TemporaryDirectory(prefix='inc-props-') as folder:
    barrier=Path(folder);processes=[];outputs=[]
    def start(label):
        output=(barrier/(label+'.log')).open('w',encoding='utf-8');outputs.append(output)
        processes.append(subprocess.Popen(base+[f'--label={label}',f'--barrier={folder}'],stdout=output,stderr=subprocess.STDOUT))
    try:
        start('server');time.sleep(1.);start('early');time.sleep(7.);start('late')
        deadline=time.monotonic()+30
        while not (barrier/'server.ok').exists():
            assert all(p.poll() is None for p in processes),'Prop probe exited before barrier'
            assert time.monotonic()<deadline,'Prop sync barrier timed out'
            time.sleep(.1)
        (barrier/'release').write_text('done',encoding='utf-8')
        for p in processes:p.wait(timeout=12)
        assert all(p.returncode==0 for p in processes)
        for output in outputs:output.flush()
        assert not any('ERROR' in path.read_text(encoding='utf-8',errors='replace') for path in barrier.glob('*.log'))
        print('NETWORK_PROPS_OK authoritative impact; early client; late join; graceful cleanup')
    finally:
        for p in processes:
            if p.poll() is None:p.terminate()
        for p in processes:
            try:p.wait(timeout=5)
            except subprocess.TimeoutExpired:p.kill();p.wait(timeout=5)
        for output in outputs:output.close()
        for path in barrier.glob('*.log'):
            print(path.name,'\n'.join(line for line in path.read_text(encoding='utf-8',errors='replace').splitlines() if any(key in line for key in ['PROP_','ERROR','Error'])))
