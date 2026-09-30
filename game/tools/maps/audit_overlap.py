"""Z-fighting audit for baked district maps: finds coplanar triangles from
different surface groups (or duplicated within one) whose areas overlap, which
flicker in game. Usage: python audit_overlap.py [indices]"""
import gzip, json, sys
from collections import defaultdict
from pathlib import Path
from shapely.geometry import Polygon
from shapely.strtree import STRtree

DISTRICTS = Path(__file__).resolve().parents[2] / 'assets/arenas/districts'


def planes(data):
    buckets = defaultdict(list)
    for g, group in enumerate(data['groups']):
        v = group['vertices']
        for i in range(0, len(v), 3):
            a, b, c = v[i], v[i + 1], v[i + 2]
            u = [b[k] - a[k] for k in range(3)]
            w = [c[k] - a[k] for k in range(3)]
            n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
            length = sum(x * x for x in n) ** .5
            if length < 1e-6:
                continue
            n = [x / length for x in n]
            # Orientation-free plane key (flip so the largest component is positive).
            big = max(range(3), key=lambda k: abs(n[k]))
            if n[big] < 0:
                n = [-x for x in n]
            d = sum(n[k] * a[k] for k in range(3))
            key = (round(n[0], 2), round(n[1], 2), round(n[2], 2), round(d, 3))
            # Project onto the two axes other than the dominant one.
            axes = [k for k in range(3) if k != big]
            poly = Polygon([(p[axes[0]], p[axes[1]]) for p in (a, b, c)])
            buckets[key].append((group['kind'], g, poly))
    return buckets


def audit(index):
    path = DISTRICTS / ('map_%02d.json' % index)
    data = json.loads(path.read_text(encoding='utf-8'))
    found = []
    for key, tris in planes(data).items():
        if len(tris) < 2:
            continue
        polys = [t[2] for t in tris]
        tree = STRtree(polys)
        for i, p in enumerate(polys):
            for j in tree.query(p):
                if j <= i:
                    continue
                area = p.intersection(polys[j]).area
                if area > .02:
                    found.append((round(area, 3), tris[i][0], tris[j][0], key))
    found.sort(reverse=True)
    total = sum(f[0] for f in found)
    print('OVERLAP map %02d: %d pairs, %.2f m2' % (index, len(found), total))
    for f in found[:6]:
        print('   ', f)
    return found


if __name__ == '__main__':
    idx = [int(a) for a in sys.argv[1:]] or list(range(31))
    for i in idx:
        audit(i)
