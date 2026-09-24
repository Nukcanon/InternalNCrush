"""Korean setup wizard, Python standard library only. No remote commands."""
from pathlib import Path
import argparse
import datetime
import json
import re
import shutil
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent

def domain(value):
    value=value.strip().lower()
    if len(value)>253 or not re.fullmatch(r"(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}",value):
        raise ValueError('https:// 없이 실제 도메인만 입력하세요. 예: lobby.example.com')
    return value

def configuration(host, mode, email='', rooms=128):
    host=domain(host)
    if mode not in ['nas','linux']:raise ValueError('설치 대상 오류')
    if mode=='linux' and not re.fullmatch(r'[^\s@=$#]+@[^\s@=$#]+\.[^\s@=$#]+',email):
        raise ValueError('인증서 알림용 이메일 주소가 필요합니다.')
    if not 1<=rooms<=512:raise ValueError('방 수는 1~512입니다.')
    return dict(DOMAIN=host,ACME_EMAIL=email,MAX_ROOMS=str(rooms),
                CADDY_CONFIG='Caddyfile.external' if mode=='nas' else 'Caddyfile',
                BIND_IP='127.0.0.1' if mode=='nas' else '0.0.0.0',
                HTTP_PORT='18080' if mode=='nas' else '80',HTTPS_PORT='18443' if mode=='nas' else '443',
                TURN_URLS='',TURN_SECRET='')

def read_env(path):
    if not path.exists():return {}
    return dict(line.split('=',1) for line in path.read_text(encoding='utf-8-sig').splitlines() if '=' in line and not line.startswith('#'))

def save_config(values, path):
    previous=read_env(path)
    for key in ['TURN_URLS','TURN_SECRET']:
        if previous.get(key):values[key]=previous[key]
    for value in values.values():
        if '\n' in value or '\r' in value:raise ValueError('설정 값에 줄바꿈을 넣을 수 없습니다.')
    if path.exists():shutil.copy2(path,path.with_name('.env.backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')))
    path.write_text('\n'.join(k+'='+v for k,v in values.items())+'\n',encoding='utf-8')

def package(output):
    files=[p for p in ROOT.iterdir() if p.is_file() and (p.suffix in ['.py','.sh','.cmd','.md','.yaml'] or p.name in ['Caddyfile','Caddyfile.external','.env'])]
    source=ROOT.parent/'services/directory'
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as archive:
        for p in files:archive.write(p,'InternalNCrush-NAS/nas/'+p.name)
        for name in ['main.py','requirements.txt','Dockerfile']:
            archive.write(source/name,'InternalNCrush-NAS/services/directory/'+name)

def ask(text,default=''):
    return input(text+(f' [{default}]' if default else '')+': ').strip() or default

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    if args.check:
        values=read_env(ROOT/'.env');host=domain(values.get('DOMAIN',''))
        with urllib.request.urlopen('https://'+host+'/health',timeout=10) as response:data=json.load(response)
        if data.get('role')!='directory-only':raise ValueError('새 방 목록 서버가 아닙니다.')
        print('HTTPS 연결 정상:',data);return
    old=read_env(ROOT/'.env')
    print('\nInternal N Crush — 가벼운 방 목록 서버 설정\n경기는 방장 PC에서 실행됩니다. NAS는 방 목록과 접속 신호만 처리합니다.\n')
    print('1. 시놀로지/NAS · 기존 HTTPS 역방향 프록시\n2. Linux · Caddy 자동 HTTPS (TCP 80/443 필요)')
    choice=ask('설치 대상','1')
    if choice not in ['1','2']:raise ValueError('1 또는 2를 선택하세요.')
    mode='nas' if choice=='1' else 'linux'
    host=domain(ask('로비 도메인',old.get('DOMAIN','')))
    email=ask('인증서 알림 이메일',old.get('ACME_EMAIL','')) if mode=='linux' else ''
    values=configuration(host,mode,email,int(ask('최대 방 수',old.get('MAX_ROOMS','128'))))
    save_config(values,ROOT/'.env')
    if mode=='nas':
        print('\nNAS 역방향 프록시: HTTPS '+host+':443 → HTTP 127.0.0.1:18080')
        print('WebSocket 사용, X-Real-IP를 실제 요청자 IP로 덮어쓰도록 설정하세요.')
    print('\n서버에 이 폴더를 복사한 다음 nas 폴더에서: sh 02_start.sh')
    print('게임 인터넷 로비 주소: https://'+host)
    if ask('업로드용 ZIP도 만들까요? (Y/N)','Y').upper()=='Y':
        output=ROOT/('InternalNCrush-NAS-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip');package(output)
        print('완료:',output);print('.env 설정이 포함됩니다. TURN 비밀키를 사용하면 이 ZIP은 관리자만 보관하세요.')
    if shutil.which('docker') and ask('이 PC에서 Docker 서버를 실행할까요? (Y/N)','N').upper()=='Y':
        subprocess.run(['docker','compose','config','--quiet'],cwd=ROOT,check=True)
        subprocess.run(['docker','compose','up','-d','--build'],cwd=ROOT,check=True)

if __name__=='__main__':
    try:main()
    except (ValueError,OSError,subprocess.CalledProcessError) as error:raise SystemExit('설정 오류: '+str(error))
