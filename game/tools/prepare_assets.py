"""Rebuild licensed sample-based audio and fetch the redistributable OFL font for build machines."""
from pathlib import Path
import urllib.request, hashlib, math, random, wave, struct
assets=Path(__file__).resolve().parents[1]/'assets'
(assets/'audio').mkdir(parents=True,exist_ok=True)
import runpy
runpy.run_path(str(Path(__file__).with_name('build_audio.py')))
font=assets/'Korean.ttf'
if not font.exists():
 font.write_bytes(urllib.request.urlopen('https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/Variable/TTF/Subset/NotoSansKR-VF.ttf',timeout=60).read())
expected=(assets/'FONT_SHA256.txt').read_text().strip()
if hashlib.sha256(font.read_bytes()).hexdigest()!=expected:raise SystemExit('Font checksum differs: inspect upstream change before rebuilding.')
print('Audio and Korean font ready; no runtime downloads required.')
import json
for entry in json.loads((assets/'fonts/manifest.json').read_text()):
 path=assets/'fonts'/entry['name']
 if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
  raise SystemExit('Bundled tactical font is missing or changed: '+entry['name'])
for entry in json.loads((assets/'human/manifest.json').read_text()):
 path=assets/'human'/entry['path']
 if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
  raise SystemExit('Bundled anatomical source is missing or changed: '+entry['path'])
