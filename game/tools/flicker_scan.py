"""1.5.4: finds z-fighting in the frame pairs written by tools/flicker_scan.gd.

Each view was rendered twice with the camera nudged by 3 mm / 0.02 degrees. Real edges move by
a fraction of a pixel; two layers fighting for the same depth swap colour in noisy patches.
A pixel counts when its colour changes strongly and it is not on an edge of either frame;
16 px blocks holding enough such pixels are reported, and each flagged view gets a marked copy.
Usage: python tools/flicker_scan.py [map indices]  -> validation/flicker/report.json
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / 'validation' / 'flicker'
BLOCK = 16
def edges(img):
    g = img.astype(np.int16)
    gx = np.abs(np.diff(g, axis=1, prepend=g[:, :1])).max(axis=2)
    gy = np.abs(np.diff(g, axis=0, prepend=g[:1])).max(axis=2)
    e = (np.maximum(gx, gy) > 24)
    # dilate by 2 px
    d = e.copy()
    for dy in (-2, -1, 0, 1, 2):
        for dx in (-2, -1, 0, 1, 2):
            d |= np.roll(np.roll(e, dy, 0), dx, 1)
    return d
report = {}
maps = [int(a) for a in sys.argv[1:]] or sorted(int(p.name) for p in root.iterdir() if p.is_dir() and p.name.isdigit())
for index in maps:
    folder = root / ('%02d' % index)
    views = json.loads((folder / 'views.json').read_text())
    found = []
    for old in folder.glob('flag_*.jpg'): old.unlink()
    for v in views:
        a = np.asarray(Image.open(folder / ('v%03d_a.png' % v['n'])).convert('RGB'))
        b = np.asarray(Image.open(folder / ('v%03d_b.png' % v['n'])).convert('RGB'))
        diff = np.abs(a.astype(np.int16) - b.astype(np.int16)).max(axis=2)
        # (animated water changes between the two frames on its own: its blue is left out)
        water = lambda im: (im[..., 2].astype(np.int16) > im[..., 0].astype(np.int16) + 50) & (im[..., 2].astype(np.int16) > im[..., 1].astype(np.int16) + 15)
        mask = (diff > 45) & ~edges(a) & ~edges(b) & ~water(a) & ~water(b)
        h, w = mask.shape
        blocks = mask[:h // BLOCK * BLOCK, :w // BLOCK * BLOCK].reshape(h // BLOCK, BLOCK, w // BLOCK, BLOCK).sum(axis=(1, 3))
        hits = np.argwhere(blocks >= 10)
        if len(hits) == 0: continue
        boxes = [[int(c * BLOCK), int(r * BLOCK), int(blocks[r, c])] for r, c in hits]
        found.append({'view': v['n'], 'blocks': boxes})
        im = Image.fromarray(a).copy(); dr = ImageDraw.Draw(im)
        for x, y, n in boxes: dr.rectangle([x, y, x + BLOCK - 1, y + BLOCK - 1], outline=(255, 0, 0), width=2)
        im.save(folder / ('flag_v%03d.jpg' % v['n']), quality=85)
    report[index] = found
    print('map %02d: %d of %d views flicker, %d blocks' % (index, len(found), len(views), sum(len(f['blocks']) for f in found)))
(root / 'report.json').write_text(json.dumps(report, indent=1))
