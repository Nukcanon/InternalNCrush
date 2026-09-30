"""Grip fields (1.4.2): signed distance to each weapon's real surface around
its grips, so hands lie on and fingers wrap the actual model instead of a box
approximation (HeroIK / GripField).

Steps (run from the repository root):
  godot --headless --path game --script res://tools/bake_grip_fields.gd -- export
  python game/tools/bake_grip_fields.py [weapon ids...]
  godot --headless --path game --script res://tools/bake_grip_fields.gd -- pack

Each weapon gets one axis-aligned box per hand (GunModel space, metres),
centred on that hand's grip marker, so markers may be retuned without a new
bake. Distances are quantised to int8 in UNIT metres, negative inside the
model; inside/outside is the generalised winding number, so overlapping closed
parts of a model are handled.
"""
import json
import math
import sys
import time
from pathlib import Path

import numpy as np

WORK = Path(__file__).resolve().parents[2] / 'validation' / 'grip_fields'
HALF = np.array([.095, .13, .145])
CELL = .0065
UNIT = .0004  # metres per int8 step (+-50.8 mm)
CLAMP = 127 * UNIT
WINDING_REACH = .30  # triangles further than this from the box barely change the winding


def closest_distance(p, a, b, c):
    """Distance from points p (M,3) to triangles (K,3) a,b,c -> (M,K)."""
    ab = b - a
    ac = c - a
    ap = p[:, None, :] - a[None]
    bp = p[:, None, :] - b[None]
    cp = p[:, None, :] - c[None]
    d1 = np.einsum('mkj,kj->mk', ap, ab)
    d2 = np.einsum('mkj,kj->mk', ap, ac)
    d3 = np.einsum('mkj,kj->mk', bp, ab)
    d4 = np.einsum('mkj,kj->mk', bp, ac)
    d5 = np.einsum('mkj,kj->mk', cp, ab)
    d6 = np.einsum('mkj,kj->mk', cp, ac)
    va = d3 * d6 - d5 * d4
    vb = d5 * d2 - d1 * d6
    vc = d1 * d4 - d3 * d2

    def safe(x):
        return np.where(np.abs(x) < 1e-15, 1e-15, x)
    denom = safe(va + vb + vc)
    q = a[None] + ab[None] * (vb / denom)[..., None] + ac[None] * (vc / denom)[..., None]
    m = (va <= 0) & ((d4 - d3) >= 0) & ((d5 - d6) >= 0)
    t = np.clip((d4 - d3) / safe((d4 - d3) + (d5 - d6)), 0, 1)
    q = np.where(m[..., None], b[None] + (c - b)[None] * t[..., None], q)
    m = (vb <= 0) & (d2 >= 0) & (d6 <= 0)
    t = np.clip(d2 / safe(d2 - d6), 0, 1)
    q = np.where(m[..., None], a[None] + ac[None] * t[..., None], q)
    m = (vc <= 0) & (d1 >= 0) & (d3 <= 0)
    t = np.clip(d1 / safe(d1 - d3), 0, 1)
    q = np.where(m[..., None], a[None] + ab[None] * t[..., None], q)
    q = np.where(((d6 >= 0) & (d5 <= d6))[..., None], c[None], q)
    q = np.where(((d3 >= 0) & (d4 <= d3))[..., None], b[None], q)
    q = np.where(((d1 <= 0) & (d2 <= 0))[..., None], a[None], q)
    return np.linalg.norm(p[:, None, :] - q, axis=2)


def winding(p, a, b, c):
    """Generalised winding number of points p (M,3) for the triangle soup."""
    A = a[None] - p[:, None, :]
    B = b[None] - p[:, None, :]
    C = c[None] - p[:, None, :]
    la = np.linalg.norm(A, axis=2)
    lb = np.linalg.norm(B, axis=2)
    lc = np.linalg.norm(C, axis=2)
    num = np.einsum('mkj,mkj->mk', A, np.cross(B, C))
    den = la * lb * lc + np.einsum('mkj,mkj->mk', A, B) * lc + np.einsum('mkj,mkj->mk', A, C) * lb + np.einsum('mkj,mkj->mk', B, C) * la
    return (2. * np.arctan2(num, den)).sum(axis=1) / (4. * math.pi)


def box_field(tris, centre, back=0.):
    # `back`: extra reach toward the stock (+z) — third-person support hands
    # slide back along long guns to where the arm reaches.
    lo = centre - HALF
    size = 2 * HALF + np.array([0., 0., back])
    dims = np.ceil(size / CELL).astype(int) + 1
    zs, ys, xs = np.meshgrid(*(lo[i] + np.arange(dims[i]) * CELL for i in (2, 1, 0)), indexing='ij')
    pts = np.stack([xs.ravel(), ys.ravel(), zs.ravel()], axis=1)  # x fastest
    tmin = tris.min(axis=1)
    tmax = tris.max(axis=1)
    near = np.all((tmax >= lo - CLAMP) & (tmin <= lo + size + CLAMP), axis=1)
    reach = np.all((tmax >= lo - WINDING_REACH) & (tmin <= lo + size + WINDING_REACH), axis=1)
    an, bn, cn = (tris[near, i] for i in range(3))
    aw, bw, cw = (tris[reach, i] for i in range(3))
    dist = np.full(len(pts), CLAMP)
    wind = np.zeros(len(pts))
    step = max(64, int(1_000_000 // max(1, reach.sum())))
    for s in range(0, len(pts), step):
        chunk = pts[s:s + step]
        if len(an):
            dist[s:s + step] = np.minimum(np.nan_to_num(closest_distance(chunk, an, bn, cn), nan=CLAMP).min(axis=1), CLAMP)
        if len(aw):
            wind[s:s + step] = np.nan_to_num(winding(chunk, aw, bw, cw))
    signed = np.where(np.abs(wind) > .5, -dist, dist)
    grid = np.clip(np.round(signed / UNIT), -127, 127).astype(np.int8)
    return grid, dims, lo, int(near.sum()), int(reach.sum())


def bake_one(job):
    wid, name, flat, origin = job
    tris = np.array(flat, dtype=np.float64).reshape(-1, 3, 3)
    area = np.linalg.norm(np.cross(tris[:, 1] - tris[:, 0], tris[:, 2] - tris[:, 0]), axis=1)
    tris = tris[area > 1e-10]
    grid, dims, lo, used, reach = box_field(tris, np.array(origin), .30 if name == 'L' else 0.)
    file = f'{wid}_{name}.bin'
    (WORK / file).write_bytes(grid.tobytes())
    print(f'{wid:>14} {name} tris {len(tris):5d} near {used:5d} winding {reach:5d} inside {int((grid < 0).sum()):6d}', flush=True)
    return wid, name, {'file': file, 'dims': [int(d) for d in dims], 'origin': lo.tolist(), 'cell': CELL, 'unit': UNIT}


def main():
    from multiprocessing import Pool
    data = json.loads((WORK / 'export.json').read_text())
    only = set(sys.argv[1:])
    index_path = WORK / 'fields.json'
    index = json.loads(index_path.read_text()) if only and index_path.exists() else {}
    started = time.time()
    jobs = [(wid, name, entry['tris'], side['origin']) for wid, entry in data.items() if not only or wid in only
            for name, side in entry['sides'].items()]
    # One field per process (numpy releases no GIL for this mix of work).
    with Pool(processes=max(1, min(len(jobs), 16))) as pool:
        for wid, name, entry in pool.imap_unordered(bake_one, jobs):
            index.setdefault(wid, {})[name] = entry
    index_path.write_text(json.dumps(index))
    print(f'GRIP_FIELDS {sum(len(v) for v in index.values())} fields in {time.time() - started:.0f}s')


if __name__ == '__main__':
    main()
