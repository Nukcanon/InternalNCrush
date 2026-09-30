"""Give assets/fonts/Symbols.ttf (Noto Sans KR subset: "·", "−", "…", arrows,
shapes) the vertical metrics of DoHyeon, the menu font it falls back from.

Godot lays a text line out with the largest ascent of every font used in it,
so a caption containing "·" (served by Symbols, ascent 1.0 em) sat ~0.2 em
lower than one without (DoHyeon, ascent 0.8 em) — off-centre in its button.
Glyph outlines are untouched. Run once after replacing Symbols.ttf.
"""
from pathlib import Path
from fontTools.ttLib import TTFont

fonts = Path(__file__).resolve().parents[1] / 'assets' / 'fonts'
reference = TTFont(fonts / 'DoHyeon-Regular.ttf')
target_path = fonts / 'Symbols.ttf'
target = TTFont(target_path)
scale = target['head'].unitsPerEm / reference['head'].unitsPerEm
ref_hhea, ref_os2 = reference['hhea'], reference['OS/2']
hhea, os2 = target['hhea'], target['OS/2']
hhea.ascent = round(ref_hhea.ascent * scale)
hhea.descent = round(ref_hhea.descent * scale)
hhea.lineGap = round(ref_hhea.lineGap * scale)
os2.sTypoAscender = round(ref_os2.sTypoAscender * scale)
os2.sTypoDescender = round(ref_os2.sTypoDescender * scale)
os2.sTypoLineGap = round(ref_os2.sTypoLineGap * scale)
os2.usWinAscent = round(ref_os2.usWinAscent * scale)
os2.usWinDescent = round(ref_os2.usWinDescent * scale)
os2.version = max(4, os2.version)  # USE_TYPO_METRICS needs OS/2 version 4
os2.fsSelection |= 1 << 7
target.save(target_path)
print('Symbols.ttf metrics', hhea.ascent, hhea.descent, hhea.lineGap)
