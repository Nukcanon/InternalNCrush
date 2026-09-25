"""Two real Godot processes, encrypted WebRTC, player-host authority."""
from pathlib import Path
import os
import subprocess
import sys
import time
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'validation/webrtc-v11'

def main():
    OUT.mkdir(parents=True,exist_ok=True);processes=[];logs=[]
    flags=getattr(subprocess,'CREATE_NO_WINDOW',0)
    url=os.getenv('INC_DIRECTORY_URL','http://127.0.0.1:30880')
    try:
        if not os.getenv('INC_DIRECTORY_URL'):
            log=(OUT/'directory.log').open('w',encoding='utf-8');logs.append(log)
            server=subprocess.Popen([sys.executable,'-m','uvicorn','services.directory.main:app','--host','127.0.0.1','--port','30880','--ws-max-size','24576','--no-access-log'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,creationflags=flags);processes.append(server)
            for _ in range(100):
                try:urllib.request.urlopen(url+'/health',timeout=1);break
                except OSError:time.sleep(.1)
            else:raise RuntimeError('Directory startup failed')
        clients=[]
        for role in ['host','client']:
            log=(OUT/(role+'.log')).open('w',encoding='utf-8');logs.append(log)
            env=dict(os.environ,INC_DIRECTORY_URL=url)
            command=[os.getenv('GODOT','godot'),'--headless','--path',str(ROOT/'game'),'--script','res://tests/network_rtc.gd','--','--rtc-'+role,'--no-save-profile','--no-update-check']
            p=subprocess.Popen(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=flags);processes.append(p);clients.append(p)
        for p in clients:assert p.wait(timeout=120)==0,'WebRTC client process failed'
        for log in logs:log.flush()
        for role in ['host','client']:
            content=(OUT/(role+'.log')).read_text(encoding='utf-8');print(content)
            assert 'RTC_CONNECTED role='+role in content and 'ERROR' not in content,role
        print('WEBRTC_NETWORK_PASS actual host and client, gameplay snapshots, disconnect')
    finally:
        for p in reversed(processes):
            if p.poll() is None:
                if os.name=='nt':subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=flags)
                else:p.terminate()
                p.wait(timeout=10)
        for log in logs:log.close()
        for role in ['directory','host','client']:
            path=OUT/(role+'.log')
            if path.exists():print(role+':\n'+path.read_text(encoding='utf-8',errors='replace'))

if __name__=='__main__':main()
