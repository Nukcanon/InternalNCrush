"""Build the NAS compose package and verify real HTTPS/WSS with a disposable CA."""
from pathlib import Path
import contextlib
import os
import ssl
import subprocess
import urllib.request
import urllib.error

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'validation/docker-v11';OUT.mkdir(parents=True,exist_ok=True)
# localhost activates Caddy's internal test CA. No production trust is changed.
env=dict(os.environ,DOMAIN='localhost',ACME_EMAIL='ci@example.com',BIND_IP='127.0.0.1',HTTP_PORT='18080',HTTPS_PORT='18443',CADDY_CONFIG='Caddyfile')
base=['docker','compose','-p','inc-directory-ci','-f','nas/compose.yaml']
def compose(*args,**kwargs):return subprocess.run(base+list(args),cwd=ROOT,env=env,check=True,**kwargs)
try:
    compose('config','--quiet');compose('up','-d','--build','--wait','--wait-timeout','180')
    compose('exec','-T','gateway','caddy','validate','--config','/etc/caddy/Caddyfile')
    ca=OUT/'root.crt';compose('cp','gateway:/data/caddy/pki/authorities/local/root.crt',str(ca))
    context=ssl.create_default_context(cafile=str(ca));url='https://localhost:18443'
    with urllib.request.urlopen(url+'/health',context=context,timeout=10) as response:assert b'directory-only' in response.read()
    for target,ctx in [(url,None),('https://127.0.0.1:18443',context)]:
        try:urllib.request.urlopen(target+'/health',context=ctx,timeout=10);raise AssertionError('Untrusted certificate or hostname accepted')
        except urllib.error.URLError as error:
            # Caddy may reject an unknown SNI before sending any certificate.
            # The trusted positive request above must succeed; neither negative
            # case may establish TLS. Unknown-CA still requires cert rejection.
            assert isinstance(error.reason,ssl.SSLCertVerificationError if ctx is None else ssl.SSLError),error
    # Scoped CA environment applies only to this disposable test child.
    scoped=dict(env,SSL_CERT_FILE=str(ca))
    subprocess.run(['python','services/directory/check_live.py',url],cwd=ROOT,env=scoped,check=True,timeout=60)
    info=compose('exec','-T','directory','python','-c',"import os; print(os.getuid()); assert os.getuid()==10001; assert not os.path.exists('/usr/local/bin/godot')",capture_output=True,text=True)
    print(info.stdout);print('DOCKER_DIRECTORY_TLS_PASS nonroot HTTPS WSS no game runtime; unknown CA/hostname rejected')
finally:
    with (OUT/'compose.log').open('w') as log:
        with contextlib.suppress(Exception):compose('logs','--no-color',stdout=log,stderr=subprocess.STDOUT)
    # Delete only this test's containers and isolated TLS certificate volumes.
    with contextlib.suppress(Exception):compose('down','-v','--remove-orphans')
