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
