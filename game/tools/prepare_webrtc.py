"""Pinned official Godot WebRTC binary dependency. Never fetches at game runtime."""
from pathlib import Path
import argparse
import hashlib
import io
import urllib.request
import urllib.error
import time
import zipfile

URL='https://github.com/godotengine/webrtc-native/releases/download/1.2.1-stable/godot-extension-webrtc_native.zip'
SHA256='f37d03da03da3ff0d092542a04586644f889135cb7a1c3566ad57513203a553b'
DEST=Path(__file__).resolve().parents[1]/'addons/webrtc_native'
LIBS=[f'libwebrtc_native.{platform}.template_{kind}.x86_64.{ext}' for platform,ext in [('windows','dll'),('linux','so')] for kind in ['debug','release']]

def prepare(archive=None):
    if archive:
        data=Path(archive).read_bytes()
    else:
        for attempt in range(3):
            try:
                with urllib.request.urlopen(URL,timeout=90) as response:data=response.read()
                break
            except (urllib.error.URLError,TimeoutError):
                if attempt==2:raise
                time.sleep(2**attempt)
    if hashlib.sha256(data).hexdigest()!=SHA256:raise SystemExit('WebRTC archive checksum mismatch')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for name in LIBS:
            member=next(n for n in z.namelist() if n.endswith('/lib/'+name))
            p=DEST/'lib'/name;p.parent.mkdir(parents=True,exist_ok=True);content=z.read(member)
            if not p.exists() or hashlib.sha256(p.read_bytes()).digest()!=hashlib.sha256(content).digest():p.write_bytes(content)
    print('WEBRTC_READY official 1.2.1 / Windows + Linux x86_64 / SHA256 verified')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--archive');args=p.parse_args();prepare(args.archive)
