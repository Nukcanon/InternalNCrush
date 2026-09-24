"""Validate a GitHub Pages-compatible single-thread export and record checksums."""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'web/build'
version=re.search(r'config/version="([^"]+)"',(ROOT/'game/project.godot').read_text()).group(1)
for name in ['index.html','index.js','index.wasm','index.pck']:
    p=BUILD/name
    assert p.is_file() and p.stat().st_size>0,name
    assert p.stat().st_size<100*1024*1024,'Individual Pages/Git file too large: '+name
html=(BUILD/'index.html').read_text(encoding='utf-8')
assert 'const GODOT_THREADS_ENABLED = false' in html,'Threads would require COOP/COEP unavailable on Pages'
assert '$GODOT_' not in html,'Unexpanded shell placeholder'
licenses=BUILD/'licenses';licenses.mkdir(exist_ok=True)
for source in [ROOT/'game/LICENSE.txt',ROOT/'game/GODOT_LICENSE.txt',ROOT/'game/assets/human/CREDITS.md',ROOT/'game/assets/human/source/LICENSE.ASSETS.md',ROOT/'game/assets/FONT_LICENSE.txt',ROOT/'game/assets/fonts/rajdhani-OFL.txt',ROOT/'game/assets/fonts/dohyeon-OFL.txt',ROOT/'game/assets/AUDIO_KENNEY_LICENSE.txt',ROOT/'game/assets/AUDIO_Q009_LICENSE.txt']:
    shutil.copy2(source,licenses/source.name)
metadata={'version':version,'threads':False,'transport':'WebRTC','touch':'coarse-pointer/mobile detection; landscape','files':[]}
for p in sorted(BUILD.rglob('*')):
    if p.is_file() and p.name!='build.json':metadata['files'].append({'path':p.relative_to(BUILD).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(BUILD/'build.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
print('WEB_PACKAGE_OK',version,'bytes=',sum(v['bytes'] for v in metadata['files']))
