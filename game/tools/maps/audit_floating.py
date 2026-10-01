"""Find wall/roof geometry hanging in the air: wall triangles whose bottom is well
above the terrain with no wall, support or ground surface directly beneath, on
every district map. Usage: python audit_floating.py [map indices]"""
from pathlib import Path
import gzip, json, math, sys
import numpy as np
ROOT = Path(__file__).resolve().parents[3]

def load(index):
    p = ROOT / f'game/assets/arenas/districts/map_{index:02d}.json'
    if p.exists(): return json.loads(p.read_text(encoding='utf-8'))
    return json.loads(gzip.decompress((ROOT / f'game/assets/arenas/districts/map_{index:02d}.json.gz').read_bytes()).decode('utf-8'))

def audit(data, index):
    walls = []
    for g in data['groups']:
        if g['kind'] not in ['wall', 'perimeter', 'tunnel', 'quay_edge']: continue
        o = g.get('origin', [0, 0, 0])
        v = np.array(g['vertices'], dtype=float).reshape(-1, 3, 3)
        walls.append(v)
    if not walls: return []
    tris = np.concatenate(walls)
    # Column occupancy: a coarse grid of the lowest wall point per cell.
    cell = 1.0
    lowest = {}
    for t in tris:
        c = t.mean(axis=0)
        key = (math.floor(c[0] / cell), math.floor(c[2] / cell))
        lowest[key] = min(lowest.get(key, 1e9), float(t[:, 1].min()))
    supports = data.get('supports', [])
    ground = {}
    for g in data['groups']:
        if g['kind'] in ['ground', 'floor', 'street', 'terrain', 'upper', 'lower', 'stair_ramp', 'plaza', 'indoor', 'roof', 'trim']:
            o = g.get('origin', [0, 0, 0])
            v = np.array(g['vertices'], dtype=float).reshape(-1, 3, 3)
            for t in v:
                c = t.mean(axis=0); key = (math.floor(c[0] / cell), math.floor(c[2] / cell))
                ground.setdefault(key, []).append(float(t[:, 1].mean()))
    hits = []
    for key, low in lowest.items():
        if low < 1.5: continue
        # anything below within this cell or its neighbours?
        held = False
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                k = (key[0] + dx, key[1] + dz)
                if k in lowest and lowest[k] < low - 1.0: held = True
                for y in ground.get(k, []):
                    if y > low - .6 and y < low + .3: held = True  # a deck at that height carries it
                    if y > low - 1.2: held = True
        for s in supports:
            if abs(s[0] - (key[0] + .5) * cell) < 1.5 and abs(s[1] - (key[1] + .5) * cell) < 1.5: held = True
        if not held: hits.append(((key[0] + .5) * cell, (key[1] + .5) * cell, round(low, 2)))
    return hits

if __name__ == '__main__':
    ids = [int(a) for a in sys.argv[1:]] or list(range(32))
    for i in ids:
        try: data = load(i)
        except FileNotFoundError: continue
        hits = audit(data, i)
        print(i, 'floating-wall cells', len(hits), hits[:8], flush=True)
