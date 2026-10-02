"""1.5 maps: authored 4 m blueprints -> district specs + baked district data.

Every map is drawn as a character grid (tools/maps/blueprints_v15.py). One
cell is CELL metres square. Regular (team) maps are drawn as their bottom half
only; the top half is the half-turn image, so both teams get exactly the same
routes, heights and cover. Defusal maps are drawn whole.

Legend (walkable cells):
  .  street / open ground          ,  plaza paving (second ground surface)
  :  covered room (ceiling at ROOM_CEILING, building mass above)
  ^  raised terrace (+RAISE, retaining wall and parapet on open edges)
  v  sunken passage (SINK, retaining wall, railing on the ground side)
  /  stairs (direction found from the two levels it joins)
  S N  team spawns (regular: S bottom, N top)   T D  attack / defend spawns
  A B C  objectives (regular: A/B half-turn partners, C centre; defusal: A/B sites)
  cover on ground cells: c crates  b barrier  s sandbags  k vehicle  o container
                         p pillar  w low wall  t tree  n stall/bench  r rubble  f fountain/feature
  cover in covered rooms: 1 crates  2 low wall  3 pillar  4 machine  5 table  6 pallets
Non-walkable:
  #  building block      H  tall landmark block      ~  water (railed)
  space / x  outside; within RING cells of the playable area it becomes a tall
  boundary building, beyond that nothing is built at all.
"""
import json, math, gzip, sys
from pathlib import Path
from shapely.geometry import box, Polygon, LineString, Point
from shapely.ops import unary_union
from shapely import constrained_delaunay_triangles
from tile_faces import tiled_triangles
import blueprints_v15 as BP

ROOT = Path(__file__).resolve().parents[3]
ARENAS = ROOT / 'game/assets/arenas'
OUT = ARENAS / 'districts'
CELL = 4.0
# A 4 m stair cell climbs 2.0 m: gentle enough for the bots' 2 m navigation
# grid (1.1 m per sample), far above a jump (0.82 m).
RAISE = 2.0
SINK = -2.0
ROOM_CEILING = 3.6
PARAPET = 0.95
PILLAR_SIDE = 0.42   # 1.4.5: square pillars under the building mass over covered-room openings
PILLAR_INSET = 0.21  # flush in the opening's corner (deeper, it closed 4 m passages for bots)
PARAPET_T = 0.25
WATER_Y = -0.7
# 1.4.6 (the user): deep water is 2 m or more and deadly; nothing between
# 0.5 m and 2 m; shallow water (0.5 m at most) is safe and walkable.
WATER_BED = -2.9          # deep: 2.2 m under the surface
SHALLOW_SURFACE = -0.02
SHALLOW_BAND = -0.24      # a step a walker climbs by itself (Actor.STEP_HEIGHT .28)
STOREY = 3.1
RING = 2
INDOOR = set(':123456')
GROUND = set('.,SNTDABC') | set('cbskopwtnrf') | INDOOR
COVER = set('cbskopwtnrf123456')
WALK = GROUND | set('^v/=')   # '=' shallow water (walkable, 1.4.6)
BLOCK = set('#H')
MARK_MIRROR = {'S': 'N', 'N': 'S', 'A': 'B', 'B': 'A'}


def expand(bp):
    rows = [r.rstrip('\n') for r in bp['rows']]
    width = max(len(r) for r in rows)
    rows = [r.ljust(width) for r in rows]
    if bp.get('symmetric'):
        top = [''.join(MARK_MIRROR.get(ch, ch) for ch in reversed(r)) for r in reversed(rows)]
        rows = top + rows
    return [list(r) for r in rows]


class Map:
    def __init__(self, index, bp):
        self.index = index
        self.bp = bp
        self.g = expand(bp)
        self.h = len(self.g)
        self.w = len(self.g[0])
        self.W = self.w * CELL
        self.H = self.h * CELL
        self.ox = self.W / 2
        self.oz = self.H / 2
        self.indoor = bool(bp.get('indoor'))
        self.symmetric = bool(bp.get('symmetric'))
        self.hall = float(bp.get('hall', 7.2 if not any('^' in ''.join(r) for r in self.g) else 9.6))
        self.problems = []
        self.ring_cells()
        self.levels()
        self.augment_cover()

    def augment_cover(self):
        """Open ground without cover nearby gets a cover piece (crates, barrier,
        low wall; covered rooms get furniture). Corridors stay clear: a piece
        only goes where at least three sides are open, never next to stairs,
        spawns or objectives. Regular maps add pieces in half-turn pairs."""
        choices = self.bp.get('fill', ['c', 'b', 'w'])
        indoor_choices = self.bp.get('fill_indoor', ['1', '2'])
        def has_cover(r, c, radius):
            return any(self.at(r + dr, c + dc) in COVER for dr in range(-radius, radius + 1) for dc in range(-radius, radius + 1))
        def near(r, c, chars, radius):
            return any(self.at(r + dr, c + dc) in chars for dr in range(-radius, radius + 1) for dc in range(-radius, radius + 1))
        def eligible(r, c):
            ch = self.at(r, c)
            if ch not in '.,:^v':
                return False
            # Spawn exits stay clear; objectives and stairs only need their
            # neighbouring cells free (sites get cover around them, as in CS).
            if near(r, c, 'SNTD', 2) or near(r, c, 'ABC/', 1):
                return False
            sides = sum(self.walk(r + dr, c + dc) for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)])
            if sides < 3:
                return False
            open_cells = sum(self.walk(r + dr, c + dc) for dr in range(-2, 3) for dc in range(-2, 3))
            # Two-cell lanes take cover against one wall (8 m lane keeps 4+ m).
            need = 10 if sides == 3 else 12
            # Pieces two cells apart in open plazas, three apart elsewhere.
            return open_cells >= need and not has_cover(r, c, 1) and (open_cells >= 19 or not has_cover(r, c, 2))
        order = sorted(((r, c) for r in range(self.h) for c in range(self.w)), key=lambda p: ((p[0] * 73856093) ^ (p[1] * 19349663) ^ (self.index * 83492791)) % 2147483647)
        added = 0
        for r, c in order:
            if self.symmetric and self.canonical(r, c) != (r, c):
                continue
            pair = [(r, c)] + ([self.mirror(r, c)] if self.symmetric and self.mirror(r, c) != (r, c) else [])
            if not all(eligible(*p) for p in pair):
                continue
            if self.symmetric and len(pair) == 2 and abs(pair[0][0] - pair[1][0]) + abs(pair[0][1] - pair[1][1]) < 3:
                continue
            pick = (r * 7 + c * 3 + self.index) % 97  # same piece on both sides
            for pr, pc in pair:
                base = self.g[pr][pc]
                if base == ':':
                    self.g[pr][pc] = indoor_choices[pick % len(indoor_choices)]
                else:
                    self.g[pr][pc] = choices[pick % len(choices)]
                    if base in '^v':
                        self.level[pr, pc] = self.base_level(base)
                added += 1
        self.augmented = added

    # --- grid helpers -------------------------------------------------------
    def at(self, r, c):
        if 0 <= r < self.h and 0 <= c < self.w:
            return self.g[r][c]
        return ' '

    def walk(self, r, c):
        return self.at(r, c) in WALK

    def cells(self, chars):
        return [(r, c) for r in range(self.h) for c in range(self.w) if self.g[r][c] in chars]

    def centre(self, r, c):
        return ((c + .5) * CELL, (r + .5) * CELL)

    def mirror(self, r, c):
        return (self.h - 1 - r, self.w - 1 - c)

    def canonical(self, r, c):
        return min((r, c), self.mirror(r, c)) if self.symmetric else (r, c)

    def ring_cells(self):
        # Void near the playable area becomes a boundary building ('R').
        seen = [[self.g[r][c] in WALK or self.g[r][c] == '~' for c in range(self.w)] for r in range(self.h)]
        # 1.4.6: shallow and deep water never touch - a strip of land (or a
        # building) always lies between them, so the safe and the deadly water
        # are never confused.
        for r in range(self.h):
            for c in range(self.w):
                if self.g[r][c] == '=' and any(self.at(r + dr, c + dc) == '~' for dr in (-1, 0, 1) for dc in (-1, 0, 1)):
                    self.problems.append('shallow water touches deep water at %d,%d' % (r, c))
        for r in range(self.h):
            for c in range(self.w):
                if self.g[r][c] not in ' x':
                    continue
                near = any(seen[r + dr][c + dc] for dr in range(-RING, RING + 1) for dc in range(-RING, RING + 1)
                           if 0 <= r + dr < self.h and 0 <= c + dc < self.w)
                self.g[r][c] = 'R' if near else ' '

    # --- levels and stairs ----------------------------------------------------
    def base_level(self, ch):
        return RAISE if ch == '^' else SINK if ch == 'v' else SHALLOW_BAND if ch == '=' else 0.

    def levels(self):
        self.level = {}
        self.stairs = {}
        for r, c in self.cells(WALK - {'/'}):
            self.level[r, c] = self.base_level(self.g[r][c])
        # Markers and cover take the level of the terrace or trench around them.
        placed = set('SNTDABC') | COVER
        seen = set()
        for start in self.cells(placed):
            if start in seen:
                continue
            region, stack = [start], [start]
            seen.add(start)
            while stack:
                a = stack.pop()
                for d in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                    b = (a[0] + d[0], a[1] + d[1])
                    if b not in seen and self.at(*b) in placed:
                        seen.add(b)
                        region.append(b)
                        stack.append(b)
            votes = {'up': 0, 'down': 0, 'ground': 0}
            for a in region:
                for d in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                    b = (a[0] + d[0], a[1] + d[1])
                    ch = self.at(*b)
                    if ch in WALK and ch != '/' and ch not in placed:
                        votes['up' if ch == '^' else 'down' if ch == 'v' else 'ground'] += 1
            # Majority of the surrounding floor (ties stay on the ground).
            best = max(votes, key=lambda key: (votes[key], key == 'ground'))
            if votes[best] > 0 and best != 'ground':
                for a in region:
                    self.level[a] = RAISE if best == 'up' else SINK
        for r, c in self.cells('/'):
            found = None
            for (dr, dc) in [(0, 1), (1, 0)]:
                # Run of stair cells along this axis and the levels at its ends.
                a, b = (r, c), (r, c)
                while self.at(a[0] - dr, a[1] - dc) == '/':
                    a = (a[0] - dr, a[1] - dc)
                while self.at(b[0] + dr, b[1] + dc) == '/':
                    b = (b[0] + dr, b[1] + dc)
                lo = (a[0] - dr, a[1] - dc)
                hi = (b[0] + dr, b[1] + dc)
                if lo in self.level and hi in self.level and abs(self.level[lo] - self.level[hi]) > .5:
                    n = (b[0] - a[0]) * dr + (b[1] - a[1]) * dc + 1
                    k = (r - a[0]) * dr + (c - a[1]) * dc
                    y0, y1 = self.level[lo], self.level[hi]
                    cand = (dr, dc, y0 + (y1 - y0) * k / n, y0 + (y1 - y0) * (k + 1) / n)
                    if found:
                        self.problems.append('ambiguous stairs at %d,%d' % (r, c))
                    found = cand
            if not found:
                self.problems.append('stairs without two levels at %d,%d' % (r, c))
                found = (0, 1, 0., 0.)
            self.stairs[r, c] = found
            self.level[r, c] = (found[2] + found[3]) / 2

    def height_at(self, r, c, x, z):
        """Walk height inside cell (r,c) at world x,z."""
        if (r, c) in self.stairs:
            dr, dc, y0, y1 = self.stairs[r, c]
            t = ((x / CELL) - c) if dc else ((z / CELL) - r)
            return y0 + (y1 - y0) * min(1., max(0., t))
        return self.level.get((r, c), 0.)

    # --- block heights ----------------------------------------------------------
    def block_heights(self):
        self.top = {}
        for r in range(self.h):
            for c in range(self.w):
                ch = self.g[r][c]
                if ch not in 'R#H' and ch not in INDOOR:
                    continue
                cr, cc = self.canonical(r, c)
                lot = (cr // 3, cc // 3)
                v = (lot[0] * 17 + lot[1] * 31 + self.index * 11) % 3
                if self.indoor:
                    self.top[r, c] = self.hall
                elif ch == 'R':
                    self.top[r, c] = 12.4 + v * 1.6
                elif ch == 'H':
                    self.top[r, c] = 16.0 + v * 1.6
                elif ch == '#':
                    self.top[r, c] = 7.2 + [0., 1.6, 3.1][v]
                else:
                    self.top[r, c] = 0.
        # Covered rooms: the building above takes the height of its neighbours.
        for r, c in self.cells(INDOOR):
            around = [self.top.get((r + dr, c + dc), 0.) for dr in (-1, 0, 1) for dc in (-1, 0, 1)]
            self.top[r, c] = max([t for t in around if t > 0] + [7.2 if not self.indoor else self.hall])
        # Nothing standing on a terrace sees over a nearby roof.
        for r, c in self.cells('^'):
            for dr in range(-2, 3):
                for dc in range(-2, 3):
                    key = (r + dr, c + dc)
                    if key in self.top and self.g[key[0]][key[1]] in 'R#H':
                        self.top[key] = max(self.top[key], RAISE + 4.6)
        if self.symmetric:
            for (r, c), t in list(self.top.items()):
                m = self.mirror(r, c)
                if m in self.top:
                    self.top[r, c] = self.top[m] = max(t, self.top[m])

    # --- lots (one building per lot for facade style/colour) ---------------------
    def lots(self):
        self.lot = {}
        self.lot_style = {}
        comp = {}
        n = 0
        for r in range(self.h):
            for c in range(self.w):
                if (self.g[r][c] in 'R#H' or self.g[r][c] in INDOOR) and (r, c) not in comp:
                    stack = [(r, c)]
                    comp[r, c] = n
                    while stack:
                        a = stack.pop()
                        for d in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                            b = (a[0] + d[0], a[1] + d[1])
                            if b not in comp and (self.at(*b) in 'R#H' or self.at(*b) in INDOOR) and (self.at(*b) in INDOOR) == (self.at(*a) in INDOOR):
                                comp[b] = n
                                stack.append(b)
                    n += 1
        styles = self.bp.get('styles') or [None]
        for (r, c), k in comp.items():
            cr, cc = self.canonical(r, c)
            lot = (k * 7919 + (cr // 3) * 131 + (cc // 3) * 17) % 9973
            if self.symmetric:
                mk = comp.get(self.mirror(r, c), k)
                lot = (min(k, mk) * 7919 + (cr // 3) * 131 + (cc // 3) * 17) % 9973
            self.lot[r, c] = lot
            self.lot_style[r, c] = styles[lot % len(styles)]


def triangles(poly):
    for p in polys(poly):
        try:
            parts = constrained_delaunay_triangles(p).geoms
        except Exception:
            clean = p.buffer(0)
            parts = [t for q in polys(clean) for t in constrained_delaunay_triangles(q).geoms]
        for t in parts:
            yield list(t.exterior.coords)[:3]


def polys(g):
    if g.is_empty:
        return []
    if g.geom_type == 'Polygon':
        return [g]
    return [p for part in getattr(g, 'geoms', []) for p in polys(part)]


def rings(p):
    return [list(p.exterior.coords)] + [list(h.coords) for h in p.interiors]


def build(index):
    bp = BP.MAPS[index]
    m = Map(index, bp)
    m.block_heights()
    m.lots()
    if m.problems:
        raise SystemExit('map %d: %s' % (index, '; '.join(m.problems[:8])))
    ox, oz = m.ox, m.oz
    groups = {}
    surfaces = []
    seen = set()
    boats, open_quays = place_boats(m)

    def emit(points, kind):
        sig = tuple(sorted(tuple(round(v, 4) for v in p) for p in points))
        if (sig, kind) in seen:
            return
        seen.add((sig, kind))
        for tx, tz, tri in tiled_triangles(points, ox, oz):
            rounded = [[round(x - ox, 4), round(y, 4), round(z - oz, 4)] for x, y, z in tri]
            groups.setdefault((tx, tz, kind), []).extend(rounded)

    def floor(poly, y_of, kind, layer=None, plane=None):
        for p in polys(poly):
            if layer:
                surfaces.append({'rings': [[[round(x - ox, 4), round(z - oz, 4)] for x, z in ring] for ring in rings(p)],
                                 'plane': plane, 'layer': layer})
            for a, b, c in triangles(p):
                if (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]) < 0:
                    b, c = c, b
                emit([(a[0], y_of(*a), a[1]), (b[0], y_of(*b), b[1]), (c[0], y_of(*c), c[1])], kind)

    def ceiling(poly, y, kind):
        for p in polys(poly):
            for a, b, c in triangles(p):
                if (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]) > 0:
                    b, c = c, b
                emit([(a[0], y, a[1]), (b[0], y, b[1]), (c[0], y, c[1])], kind)

    def wall(u, v, low_u, low_v, top_u, top_v, kind):
        # Normal to the left of u->v (the side the wall is seen from).
        if top_u - low_u < .005 and top_v - low_v < .005:
            return
        emit([(v[0], low_v, v[1]), (u[0], low_u, u[1]), (v[0], top_v, v[1])], kind)
        emit([(u[0], low_u, u[1]), (u[0], top_u, u[1]), (v[0], top_v, v[1])], kind)

    # --- walk surfaces -------------------------------------------------------------
    flat = {}
    for (r, c), y in m.level.items():
        if (r, c) in m.stairs or m.g[r][c] == '=':
            continue  # (shallow water draws its own stepped bed below)
        ch = m.g[r][c]
        kind = 'upper' if y > .1 else 'lower' if y < -.1 else ('plaza' if ch == ',' else 'indoor' if ch in INDOOR else 'ground')
        if ch not in '.,' and ch not in INDOOR and kind == 'ground':
            # Cover and markers sit on the paving around them.
            near = [m.at(r + d[0], c + d[1]) for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]]
            if near.count(',') > near.count('.'):
                kind = 'plaza'
        flat.setdefault((round(y, 3), kind), []).append(box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
    for (y, kind), boxes in flat.items():
        layer = 'upper' if y > .1 else 'lower' if y < -.1 else 'ground'
        floor(unary_union(boxes), lambda x, z, y=y: y, kind, layer, [0, 0, y])
    for (r, c), (dr, dc, y0, y1) in m.stairs.items():
        x0, z0, x1, z1 = c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL
        slope = (y1 - y0) / CELL
        mid_y = (y0 + y1) / 2
        if dc:
            plane = [slope, 0, mid_y - slope * ((c + .5) * CELL - ox)]
        else:
            plane = [0, slope, mid_y - slope * ((r + .5) * CELL - oz)]
        ramp = box(x0, z0, x1, z1)
        floor(ramp, lambda x, z, r=r, c=c: m.height_at(r, c, x, z), 'stair_ramp', 'upper', plane)
        # Visible treads (no collision) just above the smooth walking ramp.
        steps = max(1, math.ceil(abs(y1 - y0) / .18))
        for k in range(steps):
            t0, t1 = k / steps, (k + 1) / steps
            ya, yb = y0 + (y1 - y0) * t0, y0 + (y1 - y0) * t1
            topy = max(ya, yb) + .012
            if dc:
                a0, a1 = x0 + CELL * t0, x0 + CELL * t1
                tread = box(a0, z0, a1, z1)
                edge = a0 if yb > ya else a1
                riser = [(edge, z0), (edge, z1)]
            else:
                a0, a1 = z0 + CELL * t0, z0 + CELL * t1
                tread = box(x0, a0, x1, a1)
                edge = a0 if yb > ya else a1
                riser = [(x0, edge), (x1, edge)]
            floor(tread, lambda x, z, topy=topy: topy, 'stair_detail')
            # One riser face: world surfaces render both sides (cull_disabled), and a
            # second, reversed copy on the same plane z-fought under dynamic light.
            wall(riser[0], riser[1], min(ya, yb), min(ya, yb), topy, topy, 'stair_detail')

    # --- edges: retaining walls, parapets, building walls, fronts -------------------------
    fronts = []
    units = {}
    openings = []
    solid_points = set()  # corners touched by a building wall (they carry the mass above)
    rail_push = {}  # corner -> push (x, z) off the parapets inside the cell at that corner

    def rail_edge(u, v, d):
        n = (-d[1], -d[0])  # into the walkable cell, where the parapet's thickness lies
        for p in (u, v):
            key = (round(p[0], 3), round(p[1], 3))
            push = rail_push.setdefault(key, set())
            push.add(n)

    def edge_points(r, c, d):
        # Cell edge in direction d, as (u, v) with the cell (walkable side) on the left.
        x0, z0, x1, z1 = c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL
        # Facade convention (DistrictFacade): the street normal is (-dz, dx) of u->v.
        return {(0, 1): ((x1, z0), (x1, z1)), (0, -1): ((x0, z1), (x0, z0)),
                (1, 0): ((x1, z1), (x0, z1)), (-1, 0): ((x0, z0), (x1, z0))}[d]

    for r in range(m.h):
        for c in range(m.w):
            if not m.walk(r, c):
                continue
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                nr, nc = r + d[0], c + d[1]
                u, v = edge_points(r, c, d)
                # Edge heights on the walkable side (stairs slope along their axis).
                hu = m.height_at(r, c, u[0] + (-.001 if d == (0, 1) else .001 if d == (0, -1) else 0), u[1] + (-.001 if d == (1, 0) else .001 if d == (-1, 0) else 0))
                hv = m.height_at(r, c, v[0] + (-.001 if d == (0, 1) else .001 if d == (0, -1) else 0), v[1] + (-.001 if d == (1, 0) else .001 if d == (-1, 0) else 0))
                other = m.at(nr, nc)
                if other in WALK:
                    ou = m.height_at(nr, nc, u[0] + (.001 if d == (0, 1) else -.001 if d == (0, -1) else 0), u[1] + (.001 if d == (1, 0) else -.001 if d == (-1, 0) else 0))
                    ov = m.height_at(nr, nc, v[0] + (.001 if d == (0, 1) else -.001 if d == (0, -1) else 0), v[1] + (.001 if d == (1, 0) else -.001 if d == (-1, 0) else 0))
                    if ou > hu + .05 or ov > hv + .05:
                        continue  # the higher cell draws the drop
                    if abs(ou - hu) < .05 and abs(ov - hv) < .05:
                        continue
                    if other == '=' and m.g[r][c] != '=':
                        # 1.4.6: the bank of shallow water is one low step (no
                        # parapet): walk straight in and out.
                        wall(v, u, ov, ou, hv, hu, 'shallowbed')
                        continue
                    # This side is higher: retaining wall down to the neighbour, and a
                    # parapet on top unless this is a stair flight's side.
                    rail = (r, c) not in m.stairs and (nr, nc) not in m.stairs
                    wall(v, u, ov, ou, hv + (PARAPET if rail else 0), hu + (PARAPET if rail else 0), 'wall')
                    if rail:
                        parapet(emit, wall, u, v, d, hu, hv)
                        rail_edge(u, v, d)
                    # Covered room ceilings end at walls; an indoor edge to open ground
                    # under a ceiling carries the building above its opening.
                    continue
                if other == '~':
                    if (r, c, d) in open_quays:
                        # 1.4.6: a boat lies alongside here - an open quay edge
                        # (a yellow-and-black curb stone, no parapet) to board it.
                        wall(v, u, WATER_BED, WATER_BED, hv, hu, 'wall')
                        continue
                    wall(v, u, WATER_BED, WATER_BED, hv + PARAPET, hu + PARAPET, 'wall')
                    rail_edge(u, v, d)
                    parapet(emit, wall, u, v, d, hu, hv)
                    continue
                if other in 'R#H' or other in INDOOR:
                    top = m.top.get((nr, nc), 7.2)
                    if m.g[r][c] in INDOOR and other in INDOOR:
                        continue
                    if other in INDOOR:
                        continue  # the covered room draws its own opening
                    wall(u, v, hu, hv, top, top, 'wall')
                    solid_points.add((round(u[0], 3), round(u[1], 3)))
                    solid_points.add((round(v[0], 3), round(v[1], 3)))
                    flags = 1 if m.g[r][c] in INDOOR else 0
                    front_top = ROOM_CEILING if m.g[r][c] in INDOOR else top
                    units.setdefault((m.lot.get((nr, nc), 0), d, round(hu, 3) if (r, c) not in m.stairs else None, front_top, flags, m.lot_style.get((nr, nc))), []).append((u, v, hu, hv, r, c))
                    continue
            # Covered rooms: ceiling over the room, building mass above openings.
            if m.g[r][c] in INDOOR:
                for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                    nr, nc = r + d[0], c + d[1]
                    if m.at(nr, nc) in WALK and m.at(nr, nc) not in INDOOR:
                        u, v = edge_points(r, c, d)
                        top = m.top.get((r, c), 7.2)
                        # Seen from the open side: the wall faces away from the room.
                        wall(v, u, ROOM_CEILING, ROOM_CEILING, top, top, 'wall')
                        wall(u, v, ROOM_CEILING - .25, ROOM_CEILING - .25, ROOM_CEILING, ROOM_CEILING, 'trim')
                        fronts.append(front(m, v, u, 0., 0., ROOM_CEILING, top, m.lot.get((r, c), 0), 2, m.lot_style.get((r, c))))
                        # 1.4.5: the mass above an opening stands on pillars at
                        # both ends of the opening (one per cell corner, just
                        # inside the room), not in the air (DistrictDressing
                        # draws `supports`).
                        openings.append((u, v, (-d[1], -d[0]), m.level.get((r, c), 0.)))  # room side (x, z)

    # 1.4.5: the building mass over covered-room openings never hangs in the
    # air. Where an opening ends at a wall, that wall carries it; a pillar
    # stands only at corners with no wall beneath (between two openings of a
    # long front, or at a room corner open on two sides), inside the room
    # under the mass, so it never meets a wall.
    pillars = []
    ends = {}
    for u, v, inward, level in openings:
        for p in (u, v):
            key = (round(p[0], 3), round(p[1], 3))
            ends.setdefault(key, []).append((inward, level))
    for (px, pz), uses in ends.items():
        if (px, pz) in solid_points:
            continue
        inward_x = sum(i[0] for i, _ in uses)
        inward_z = sum(i[1] for i, _ in uses)
        sx = PILLAR_INSET * (1 if inward_x > 0 else -1 if inward_x < 0 else 0)
        sz = PILLAR_INSET * (1 if inward_z > 0 else -1 if inward_z < 0 else 0)
        x, z = px + sx, pz + sz
        # clear of any parapet meeting this corner (its thickness lies inside the cell)
        for n in rail_push.get((px, pz), ()):
            along = sx * n[0] + sz * n[1]
            if along < 0:
                continue  # that parapet is in a neighbouring cell, not under this pillar
            if along == 0:
                # centred on the parapet's line: step wholly off it
                x += n[0] * (PARAPET_T + PILLAR_SIDE / 2 + .02)
                z += n[1] * (PARAPET_T + PILLAR_SIDE / 2 + .02)
                continue
            x += n[0] * (PARAPET_T + .02)
            z += n[1] * (PARAPET_T + .02)
        level = uses[0][1]
        entry = [round(x - ox, 4), round(z - oz, 4), ROOM_CEILING - .02, round(level, 4), PILLAR_SIDE]
        if not any(math.dist(entry[:2], q[:2]) < .3 for q in pillars):  # a room's outer corner: one pillar
            pillars.append(entry)

    # Fronts: merge collinear unit edges of one lot into pieces of up to 12 m.
    for key, pieces in units.items():
        lot, d, hu_key, top, flags, style = key
        pieces.sort(key=lambda p: (p[0][0] * abs(d[0]) + p[0][1] * abs(d[1]), p[0][1] * abs(d[0]) + p[0][0] * abs(d[1])))
        run = []
        for piece in pieces + [None]:
            if piece and run and math.dist(run[-1][1], piece[0]) < .01 and len(run) < 3 and hu_key is not None:
                run.append(piece)
                continue
            if run:
                u, v = run[0][0], run[-1][1]
                fronts.append(front(m, u, v, run[0][2], run[-1][3], 0., top, lot, flags, style))
            run = [piece] if piece else []

    # Roofs, ceilings and building steps.
    if not m.indoor:
        tops = {}
        for (r, c), t in m.top.items():
            if t > 0:
                tops.setdefault(round(t, 3), []).append(box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
        for t, boxes in tops.items():
            floor(unary_union(boxes), lambda x, z, t=t: t, 'roof')
        for (r, c), t in m.top.items():
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                o = (r + d[0], c + d[1])
                ot = m.top.get(o, 0.)
                if 0 < ot < t - .01 and (m.at(*o) in 'R#H' or m.at(*o) in INDOOR):
                    u, v = edge_points(r, c, d)
                    wall(v, u, ot, ot, t, t, 'wall')
        rooms = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in m.cells(INDOOR)]) if m.cells(INDOOR) else Polygon()
        ceiling(rooms, ROOM_CEILING, 'ceiling')
    else:
        walkable = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for (r, c) in m.level if m.g[r][c] not in INDOOR])
        ceiling(walkable, m.hall, 'ceiling')
        rooms = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in m.cells(INDOOR)]) if m.cells(INDOOR) else Polygon()
        ceiling(rooms, ROOM_CEILING, 'ceiling')

    # Water: surface and bed.
    water_cells = m.cells('~')
    water = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in water_cells]) if water_cells else Polygon()
    if water_cells:
        floor(water, lambda x, z: WATER_BED, 'waterbed')
        floor(water, lambda x, z: WATER_Y, 'water')
        for r, c in water_cells:
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                o = m.at(r + d[0], c + d[1])
                if o in 'R#H':
                    u, v = edge_points(r, c, d)
                    top = m.top.get((r + d[0], c + d[1]), 7.2)
                    wall(u, v, WATER_BED, WATER_BED, top, top, 'wall')
                    fronts.append(front(m, u, v, WATER_Y, WATER_Y, 0., top - WATER_Y, m.lot.get((r + d[0], c + d[1]), 0), 8, m.lot_style.get((r + d[0], c + d[1]))))

    # 1.4.6 shallow water: one flat sandy bed .24 m down (the user: the depth
    # never changes inside a pool; the bank is a step a walker climbs by
    # itself), a clear surface over it, and a walk surface for the bots.
    shallow_cells = m.cells('=')
    shallow = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in shallow_cells]) if shallow_cells else Polygon()
    if shallow_cells:
        floor(shallow, lambda x, z: SHALLOW_BAND, 'shallowbed')
        floor(shallow, lambda x, z: SHALLOW_SURFACE, 'water_shallow')
        for p in polys(shallow):
            surfaces.append({'rings': [[[round(x - ox, 4), round(z - oz, 4)] for x, z in ring] for ring in rings(p)],
                             'plane': [0, 0, SHALLOW_BAND], 'layer': 'lower'})

    # --- objectives, spawns, cover, trees -------------------------------------------------
    def marker(ch):
        cells = m.cells(ch)
        if not cells:
            return None
        xs = [m.centre(r, c) for r, c in cells]
        return (sum(p[0] for p in xs) / len(xs), sum(p[1] for p in xs) / len(xs))

    defusal = bp['mode'] == 'defusal'
    if defusal:
        spawns = [marker('T'), marker('D')]
        targets = [marker('A'), marker('B')]
    else:
        spawns = [marker('S'), marker('N')]
        targets = [marker('A'), marker('C'), marker('B')]
    if None in spawns or None in targets:
        raise SystemExit('map %d: missing spawn/objective markers' % index)

    props = []
    trees = []
    kinds = bp.get('props', {})
    for r, c in sorted(m.cells(COVER)):
        if m.symmetric and m.canonical(r, c) != (r, c):
            continue
        for rr, cc in ([(r, c), m.mirror(r, c)] if m.symmetric and m.mirror(r, c) != (r, c) else [(r, c)]):
            ch = m.g[rr][cc]
            x, z = m.centre(rr, cc)
            y = m.level.get((rr, cc), 0.)
            if ch == 't':
                trees.append([round(x - ox, 4), round(z - oz, 4), y])
                continue
            yaw, offset = cover_pose(m, rr, cc, ch)
            kind = kinds.get(ch) or DEFAULT_KINDS[ch]
            if isinstance(kind, list):
                cr, cc2 = m.canonical(rr, cc)
                kind = kind[(cr * 7 + cc2 * 13) % len(kind)]
            shift, partners = CLUSTERS.get(kind, (0., []))
            for dx, dz, dyaw, part in [(shift, 0., 0., kind)] + partners:
                # Local (dx, dz) turned by the piece's yaw (Godot: +Y rotation).
                wx = dx * math.cos(yaw) + dz * math.sin(yaw)
                wz = -dx * math.sin(yaw) + dz * math.cos(yaw)
                props.append([round(x + offset[0] + wx - ox, 4), round(z + offset[1] + wz - oz, 4), y, round(yaw + dyaw, 5), part])
    decor_count = len(props)
    props += wall_decor(m, index)
    props += water_safety(m, open_quays, props, spawns, targets)
    m.decor_count = len(props) - decor_count

    # Loose (movable) props against walls on quiet ground, in partner pairs.
    # Every map gets 6-10 (barrels, crates, cones), spread at least 3 cells apart,
    # against one wall and away from spawns and objectives. Cramped maps take a
    # second pass: two cells apart, room cells and corners allowed.
    loose = []
    taken = []
    doors = place_doors(m, spawns, targets)
    candidates =sorted(m.cells('.,:'), key=lambda p: ((p[0] * 5 + p[1] * 3 + index) % 9, p))
    passes = [(3, '.,', False), (2, '.,:', True)]
    for r, c, (spacing, allowed, corners) in [(r, c, p) for p in passes for r, c in candidates]:
        if len(loose) >= 10 or (corners and len(loose) >= 6):
            continue
        if m.g[r][c] not in allowed or (r, c) in taken:
            continue
        if m.symmetric and m.canonical(r, c) != (r, c):
            continue
        walls = [d for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] if m.at(r + d[0], c + d[1]) in 'R#H']
        corner = len(walls) == 2 and walls[0][0] != -walls[1][0] and walls[0][1] != -walls[1][1]
        if not (len(walls) == 1 or (corners and corner)) or any(max(abs(r - tr), abs(c - tc)) < spacing for tr, tc in taken):
            continue
        if any(m.at(r + dr, c + dc) in COVER for dr in range(-1, 2) for dc in range(-1, 2)) and not corners:
            continue
        if m.g[r][c] in COVER:
            continue
        x, z = m.centre(r, c)
        d = walls[0]
        x += d[1] * 1.2
        z += d[0] * 1.2
        if min(math.dist((x, z), p) for p in spawns + targets) < 9:
            continue
        # Wall decor shares these cells: never drop a physics prop inside one.
        if any(math.dist((x - ox, z - oz), (p[0], p[1])) < 2.2 for p in props):
            continue
        # (1.4.6) never where a door leaf swings
        if any(math.dist((x - ox, z - oz), (dd[0], dd[1])) < 3.2 for dd in doors):
            continue
        taken.append((r, c))
        loose.append([round(x - ox, 4), round(z - oz, 4), m.level.get((r, c), 0.)])
        if m.symmetric:
            mr, mc = m.mirror(r, c)
            taken.append((mr, mc))
            mx, mz = m.centre(mr, mc)
            loose.append([round(mx - d[1] * 1.2 - ox, 4), round(mz - d[0] * 1.2 - oz, 4), m.level.get((mr, mc), 0.)])

    # --- routes for bots and the plan preview --------------------------------------------------
    paths = routes(m, spawns, targets, defusal)
    goals = []
    for region in polys(unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in m.cells('^v')]) if m.cells('^v') else Polygon()):
        p = region.representative_point()
        r, c = int(p.y // CELL), int(p.x // CELL)
        goals.append([round(p.x - ox, 4), m.level.get((r, c), 0.), round(p.y - oz, 4)])
    lights = []
    for region in polys(unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in m.cells(INDOOR)]) if m.cells(INDOOR) else Polygon()):
        p = region.representative_point()
        lights.append([round(p.x - ox, 4), ROOM_CEILING, round(p.y - oz, 4)])

    walk_poly = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for (r, c) in m.level])
    outline = max(polys(walk_poly.buffer(.3, join_style=2)), key=lambda p: p.area)
    border = [[round(x - ox, 4), round(z - oz, 4)] for x, z in outline.exterior.coords]

    def centred(p):
        return [round(p[0] - ox, 4), round(p[1] - oz, 4)]

    def level_at(p):
        return m.level.get((int(p[1] // CELL), int(p[0] // CELL)), 0.)

    data = {'index': index, 'name': bp['name'], 'dimensions': [m.W, m.H], 'room_ceiling_lights': lights,
            'rectangle': False, 'removed_sliver_islands': [], 'surfaces': surfaces,
            'groups': [{'kind': key[2], 'origin': [key[0] * 24 + 12, 0, key[1] * 24 + 12], 'vertices': v} for key, v in groups.items()],
            'border': [border], 'spawns': [centred(p) for p in spawns], 'targets': [centred(p) for p in targets],
            'goals': goals, 'corridor_m': CELL, 'capacity': bp['capacity'],
            'props': props, 'trees': trees, 'ceiling_height': m.hall if m.indoor else 0., 'loose_props': loose,
            'facades': [], 'fronts': fronts, 'street_height': 7.2, 'storey': STOREY, 'supports': pillars,
            'terrain': None, 'elevated_crossing': bool(m.cells('^')),
            'spawn_heights': [level_at(p) for p in spawns], 'target_heights': [level_at(p) for p in targets],
            'water': [[centred(p) for p in q.exterior.coords] for q in polys(water)] if water_cells else [],
            'vehicles': [], 'boats': boats, 'doors': doors, 'water_kind': bp.get('water_kind', 'river'), 'water_height': WATER_Y,
            'shallow': [[centred(p) for p in q.exterior.coords] for q in polys(shallow)] if shallow_cells else [], 'shallow_height': SHALLOW_SURFACE,
            'open_quays': [[round(x - ox, 4), round(z - oz, 4), round(x2 - ox, 4), round(z2 - oz, 4)] for x, z, x2, z2 in quay_lines(m, open_quays)],
            'water_gates': [[round(g[0] - ox, 4), round(g[1] - oz, 4), round(g[2] - ox, 4), round(g[3] - oz, 4)] + list(g[4:]) for g in water_gates(m)],
            'water_boat': [], 'version': 15, 'grid': [''.join(row) for row in m.g], 'cell': CELL}
    spec = {'paths': [[list(p) for p in path] for path in paths], 'upper_path': [], 'lower_path': [], 'id': index + 1,
            'name': bp['name'], 'capacity': bp['capacity'], 'dimensions': [m.W, m.H], 'rectangle': False,
            'identity': bp['identity'], 'floor': [], 'border': [], 'upper': [], 'lower': [], 'stairs': [],
            'spawns': list(map(list, spawns)), 'targets': list(map(list, targets)), 'corridor_m': CELL, 'side_corridor_m': CELL,
            'rooms': len(m.cells(':')), 'connected': True, 'mode': '설치/해체' if defusal else '일반전', 'ceiling_rooms': [],
            'terrain': None, 'elevated_crossing': bool(m.cells('^')), 'terraces': bool(m.cells('^')), 'sunken': bool(m.cells('v')),
            'authored_revision': 150, 'upper_height': RAISE,
            'lower_height': SINK, 'composition': 'authored_blueprint', 'stairs_enabled': True, 'previous_name': bp['name']}
    return m, data, spec


def front(m, u, v, y0, y1, frm, top, lot, flags, style):
    ox, oz = m.ox, m.oz
    f = [round(u[0] - ox, 4), round(u[1] - oz, 4), round(v[0] - ox, 4), round(v[1] - oz, 4), round(y0, 4), round(y1, 4), frm, round(top, 4), lot, flags]
    if style:
        f.append(style)
    return f


def parapet(emit, wall, u, v, d, hu, hv):
    # Inner face and cap of a parapet standing on the higher (left) side of u->v.
    nx, nz = -d[1], -d[0]  # into the walkable cell
    # Caps of perpendicular parapets share their corner square: lift the ones
    # running along z by 4 mm so the corner never z-fights.
    top = PARAPET + (.004 if abs(v[0] - u[0]) < 1e-6 else 0.)
    iu = (u[0] + nx * PARAPET_T, u[1] + nz * PARAPET_T)
    iv = (v[0] + nx * PARAPET_T, v[1] + nz * PARAPET_T)
    wall(u, v, 0, 0, 0, 0, 'trim')
    emit([(iv[0], hv, iv[1]), (iu[0], hu, iu[1]), (iv[0], hv + top, iv[1])], 'trim')
    emit([(iu[0], hu, iu[1]), (iu[0], hu + top, iu[1]), (iv[0], hv + top, iv[1])], 'trim')
    emit([(u[0], hu + top, u[1]), (v[0], hv + top, v[1]), (iu[0], hu + top, iu[1])], 'trim')
    emit([(v[0], hv + top, v[1]), (iv[0], hv + top, iv[1]), (iu[0], hu + top, iu[1])], 'trim')


DEFAULT_KINDS = {'c': 'crate_stack', 'b': 'barrier_single', 's': 'sacktrench', 'k': 'vehicle_hatch', 'o': 'container_small', 'p': 'pillar',
                 'w': 'low_wall', 'n': 'bench', 'r': 'rock_pile', 'f': 'fountain', '1': 'crate_stack', '2': 'low_wall', '3': 'pillar',
                 '4': 'transformer', '5': 'workbench', '6': 'pallet_load'}


# Cover clusters: the main piece shifts along its length and partners stand
# beside it, so one cover cell reads as a 3-4 m group of mixed heights (a low
# wall ending in a column, crates beside a pallet, an L of sandbags).
# kind: (main shift along local x, [(dx, dz, dyaw, partner kind), ...]) in the
# piece frame (x along the cover, +z away from the wall it hugs).
CLUSTERS = {
    'crate_stack': (-.6, [(.95, .05, 0., 'pallet_load')]),
    'barrier_single': (-.45, [(1.4, 0., 0., 'gastank')]),
    'low_wall': (-.25, [(1.35, 0., 0., 'pillar')]),
    'sacktrench': (-.2, [(1.35, .7, math.pi / 2, 'sacktrench_small')]),
    'container_small': (-.3, [(2.05, .7, .3, 'crate')]),  # 1.4.5: clear of the container (1.55 sank into it)
    'pallet_load': (-.7, [(.7, 0., 0., 'cardboardboxes_3')]),
    'fruit_crates': (-.6, [(1.3, 0., 0., 'cask_pair')]),
    'fish_crates': (-.6, [(1.3, 0., 0., 'cask_pair')]),
    'cask_pair': (-.8, [(1.05, 0., 0., 'crate_stack')]),
}
MAP_STYLE = ["harbour", "shipyard", "steelmill", "lab", "desert", "canal", "station", "oldtown", "garage", "hillside",
             "orchard", "power", "plaza", "logistics", "testlab", "derelict", "highrise", "market", "quarry", "fortress",
             "nuclear", "aqueduct", "library", "wreckyard", "monastery", "furnace", "greenhouse", "vault", "coastal_base", "server",
             "mountain_fort", "range"]
# Wall-side dressing per map style (shallow pieces; streets keep their width).
DECOR = {
    'oldtown': ['streetlight', 'planter', 'bench', 'trashcontainer', 'bike_rack', 'pots'],
    'hillside': ['planter', 'pots', 'bench', 'streetlight', 'cask_pair'],
    'canal': ['bollards', 'bench', 'streetlight', 'bike_rack', 'planter'],
    'plaza': ['bench', 'planter', 'streetlight', 'cafe_table', 'planter'],
    'market': ['fruit_crates', 'cask_pair', 'trashcontainer', 'cardboardboxes_2', 'streetlight'],
    'station': ['bench', 'sign', 'trashcontainer', 'streetlight', 'luggage', 'planter'],
    'harbour': ['bollards', 'cask_pair', 'fish_crates', 'pallet_load', 'streetlight'],
    'shipyard': ['gastank', 'cable_drum', 'pallet_load', 'barrier_single', 'streetlight'],
    'logistics': ['pallet_load', 'cardboardboxes_4', 'trashcontainer', 'cardboardboxes_2', 'streetlight'],
    'desert': ['gastank', 'sacktrench_small', 'sign', 'crate'],
    'orchard': ['fruit_crates', 'cask_pair', 'fence_long', 'hay_bale'],
    'quarry': ['woodplanks_stack', 'cable_drum', 'gastank', 'rock_pile'],
    'fortress': ['cask_pair', 'weapon_rack', 'hay_bale', 'crate'],
    'mountain_fort': ['cask_pair', 'weapon_rack', 'crate', 'rock_pile'],
    'monastery': ['bench', 'planter', 'pots', 'cask_pair'],
    'aqueduct': ['planter', 'bench', 'pots', 'cask_pair', 'streetlight'],
    'nuclear': ['drums', 'gastank', 'sign', 'cable_drum', 'barrier_single'],
    'wreckyard': ['debris_tires', 'pallet_broken', 'gastank', 'woodplanks_stack'],
    'furnace': ['ingots', 'gastank', 'cable_drum', 'pallet_load'],
    'greenhouse': ['planter_long', 'potting_bench', 'pots', 'planter_long'],
    'coastal_base': ['sacktrench_small', 'gastank', 'sign', 'crate'],
    'range': ['target_stand', 'trafficcone', 'crate', 'pallet_load'],
    'steelmill': ['ingots', 'gastank', 'cable_drum', 'pallet_load'],
    'lab': ['cabinet', 'desk', 'lab_bench'],
    'garage': ['tool_chest', 'workbench', 'debris_tires', 'gastank', 'cardboardboxes_2'],
    'power': ['cabinet', 'cable_drum', 'gastank', 'transformer'],
    'testlab': ['cabinet', 'lab_bench', 'desk'],
    'derelict': ['debris_tires', 'pallet_broken', 'cardboardboxes_4', 'woodplanks_stack'],
    'highrise': ['planter', 'cabinet', 'sofa_small', 'desk'],
    'library': ['bookcase', 'globe', 'reading_table', 'bookcase'],
    'vault': ['deposit_block', 'money_cart', 'crate'],
    'server': ['server_block', 'cabinet', 'cable_drum'],
}
ROOM_DECOR = ['cardboardboxes_2', 'crate', 'cabinet', 'cardboardboxes_4', 'gastank']


def wall_decor(m, index):
    """Shallow dressing against building walls: one piece every few wall cells
    of open streets and rooms, never in one-cell corridors, near stairs,
    spawns, objectives or next to cover. Regular maps place half-turn pairs."""
    style = MAP_STYLE[index] if index < len(MAP_STYLE) else 'oldtown'
    outdoor_list = DECOR.get(style, ROOM_DECOR)
    keep_clear = set('SNTDABC/')
    out = []
    for r in range(m.h):
        for c in range(m.w):
            if m.symmetric and m.canonical(r, c) != (r, c):
                continue
            ch = m.g[r][c]
            if ch not in '.,:':
                continue
            walls = [d for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] if m.at(r + d[0], c + d[1]) in 'R#H']
            if len(walls) != 1:
                continue
            d = walls[0]
            if not m.walk(r - d[0], c - d[1]) or not m.walk(r - 2 * d[0], c - 2 * d[1]):
                continue  # corridor: keep the lane clear
            if any(m.at(r + dr, c + dc) in keep_clear for dr in range(-2, 3) for dc in range(-2, 3)):
                continue
            if any(m.at(r + dr, c + dc) in COVER for dr in range(-1, 2) for dc in range(-1, 2)):
                continue
            if ((r * 73856093) ^ (c * 19349663) ^ (index * 83492791)) % 3:
                continue
            room = ch == ':' and not m.indoor
            choices = ROOM_DECOR if room else outdoor_list
            kind = choices[(r * 5 + c * 11 + index) % len(choices)]
            for rr, cc, dd in [(r, c, d)] + ([(*m.mirror(r, c), (-d[0], -d[1]))] if m.symmetric and m.mirror(r, c) != (r, c) else []):
                x, z = m.centre(rr, cc)
                x += dd[1] * 1.45
                z += dd[0] * 1.45
                yaw = math.atan2(-dd[1], -dd[0])  # local x along the wall, +z to the street
                out.append([round(x - m.ox, 4), round(z - m.oz, 4), m.level.get((rr, cc), 0.), round(yaw, 5), kind])
    return out


# 1.4.6 boats (the user): deep water carries boats that suit the map, moored
# alongside a quay so they can be boarded (BoatModels: deck flush with the
# quay, the parapet open where the boat lies). Sizes: (length, beam) metres.
BOAT_SIZES = {'narrowboat': (11.0, 2.3), 'houseboat': (9.0, 3.4), 'launch': (6.5, 2.4), 'fishing': (9.0, 3.2), 'tug': (8.0, 3.4),
              'lighter': (12.0, 4.2), 'patrol': (9.5, 3.0), 'workboat': (6.0, 2.4), 'wreck': (9.0, 3.2), 'punt': (4.5, 1.5)}
BOAT_TYPES = {'canal': ['narrowboat', 'houseboat', 'launch'], 'oldtown': ['narrowboat', 'launch', 'houseboat'], 'market': ['narrowboat', 'houseboat'],
              'harbour': ['fishing', 'tug', 'lighter'], 'logistics': ['lighter', 'tug', 'workboat'], 'shipyard': ['tug', 'lighter', 'fishing'],
              'coastal_base': ['patrol', 'launch', 'lighter'], 'desert': ['patrol', 'workboat'], 'wreckyard': ['wreck', 'fishing'],
              'nuclear': ['workboat'], 'power': ['workboat'], 'greenhouse': ['punt'], 'orchard': ['punt'], 'aqueduct': ['narrowboat', 'punt'],
              'hillside': ['launch', 'punt']}


def place_boats(m):
    """Boats in the deep water ('~'): the largest that fits each straight run
    of water, with a margin to every wall, lying along the run beside a quay
    (walkable ground cells at level 0) where there is one. Regular maps place
    half-turn pairs. Returns (boats, open quay edges)."""
    style = MAP_STYLE[m.index] if m.index < len(MAP_STYLE) else 'harbour'
    types = BOAT_TYPES.get(style, ['launch', 'workboat'])
    taken = set()
    boats, open_quays = [], set()
    water = set(m.cells('~'))
    if not water:
        return boats, open_quays
    def quay_cell(r, c):
        return m.at(r, c) in '.,' and abs(m.level.get((r, c), 1.) ) < .01 and (r, c) not in m.stairs
    candidates = []
    for (r, c) in sorted(water):
        for along in [(0, 1), (1, 0)]:
            across = (along[1], along[0])
            for thick in (3, 2, 1):
                for run in range(8, 1, -1):
                    cells = [(r + across[0] * t + along[0] * k, c + across[1] * t + along[1] * k) for k in range(run) for t in range(thick)]
                    if not all(p in water for p in cells):
                        continue
                    length, beam = run * CELL - 1.4, thick * CELL - 1.6
                    fit = [t for t in types if BOAT_SIZES[t][0] <= length and BOAT_SIZES[t][1] <= beam]
                    if not fit:
                        continue
                    # quay along one long side (the middle cell(s) of the run)
                    mid = [run // 2] if run % 2 else [run // 2 - 1, run // 2]
                    sides = []
                    for side, t in ((-1, -1), (1, thick)):
                        q = [(r + across[0] * t + along[0] * k, c + across[1] * t + along[1] * k) for k in mid]
                        if all(quay_cell(*p) for p in q):
                            sides.append((side, q))
                    candidates.append((-(len(sides) > 0), -run * thick, r, c, along, thick, run, fit, sides))
                    break
    candidates.sort(key=lambda x: x[:4])
    placed = 0
    for _, _, r, c, along, thick, run, fit, sides in candidates:
        if placed >= (4 if m.symmetric else 3):
            break
        across = (along[1], along[0])
        cells = [(r + across[0] * t + along[0] * k, c + across[1] * t + along[1] * k) for k in range(run) for t in range(thick)]
        mirrored = [m.mirror(*p) for p in cells] if m.symmetric else []
        if any(p in taken for p in cells + mirrored) or (m.symmetric and set(cells) & set(mirrored)):
            continue
        kind = fit[(r * 7 + c * 3 + m.index) % len(fit)]
        L, B = BOAT_SIZES[kind]
        # centre of the run; against the quay side when there is one
        x0, z0 = c * CELL, r * CELL
        xs = [p[1] for p in cells]; zs = [p[0] for p in cells]
        cx = (min(xs) + max(xs) + 1) * CELL / 2
        cz = (min(zs) + max(zs) + 1) * CELL / 2
        side, quay = sides[0] if sides else (0, [])
        if not side:
            # (the user) a boat nobody can board lies out of jumping reach:
            # 4.5 m and more of open water to any walkable ground
            hull = box(cx - (L / 2 if along == (0, 1) else B / 2), cz - (B / 2 if along == (0, 1) else L / 2),
                       cx + (L / 2 if along == (0, 1) else B / 2), cz + (B / 2 if along == (0, 1) else L / 2))
            if any(hull.distance(box(wc * CELL, wr * CELL, (wc + 1) * CELL, (wr + 1) * CELL)) < 4.5 for wr, wc in m.level):
                continue
        # an even run: centre the boat on one quay cell when it still fits, so the
        # 4 m opening lies along the boat's straight middle
        if run % 2 == 0 and L + 1.4 + CELL <= run * CELL:
            cx += along[1] * CELL / 2
            cz += along[0] * CELL / 2
            quay = quay[1:]
        if side:
            # hull side .15 m off the quay wall
            shift = (thick * CELL / 2 - B / 2 - .15) * side
            cx += across[1] * shift
            cz += across[0] * shift
        yaw = 0. if along == (0, 1) else math.pi / 2
        # local +z of the boat (Godot: Basis(UP, yaw) * (0,0,1) = (sin, 0, cos))
        lz = (math.sin(yaw), math.cos(yaw))
        q = (across[1] * side, across[0] * side)
        gap = (1 if lz[0] * q[0] + lz[1] * q[1] > 0 else -1) if side else 0
        for (pr, pc), dd in [((p[0], p[1]), (-across[0] * side, -across[1] * side)) for p in quay]:
            open_quays.add((pr, pc, dd))
        boats.append([round(cx - m.ox, 4), round(cz - m.oz, 4), round(WATER_Y, 4), round(yaw, 5), kind, bool(side), gap])
        taken.update(cells)
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                taken.update((p[0] + dr, p[1] + dc) for p in cells)
        placed += 1
        if m.symmetric:
            mr, mc = m.mirror(r, c)
            mx, mz = m.W - cx, m.H - cz
            boats.append([round(mx - m.ox, 4), round(mz - m.oz, 4), round(WATER_Y, 4), round(yaw + math.pi, 5), kind, bool(side), gap])
            for (pr, pc), dd in [((p[0], p[1]), (-across[0] * side, -across[1] * side)) for p in quay]:
                mp = m.mirror(pr, pc)
                open_quays.add((mp[0], mp[1], (-dd[0], -dd[1])))
            taken.update(mirrored)
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    taken.update((p[0] + dr, p[1] + dc) for p in mirrored)
            placed += 1
    return boats, open_quays


def water_safety(m, open_quays, props, spawns, targets):
    """(the user) In front of deadly (deep) water: a few drowning warning signs
    and lifebuoy stands on the quay, against the parapet - never many: at most
    one of each per stretch of water (and its half-turn partner)."""
    out = []
    water = set(m.cells('~'))
    if not water:
        return out
    seen = set()
    comps = []
    for cell in sorted(water):
        if cell in seen:
            continue
        comp, stack = [], [cell]
        seen.add(cell)
        while stack:
            a = stack.pop()
            comp.append(a)
            for d in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                b = (a[0] + d[0], a[1] + d[1])
                if b in water and b not in seen:
                    seen.add(b)
                    stack.append(b)
        comps.append(comp)
    taken = {'warning_sign': [], 'lifebuoy_stand': []}
    # (the user) warning signs at least 30 m apart - never too many
    spacing = {'warning_sign': 30., 'lifebuoy_stand': 30.}
    def quay_spots(comp, relaxed):
        spots = []
        for r, c in comp:
            for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                qr, qc = r - d[0], c - d[1]   # quay cell, water lies in direction d from it
                if m.at(qr, qc) not in '.,' or abs(m.level.get((qr, qc), 0. if relaxed else 1.)) > .01 or (qr, qc, d) in open_quays:
                    continue
                if not relaxed and any(m.at(qr + dr, qc + dc) in COVER | set('SNTDABC/') for dr in (-1, 0, 1) for dc in (-1, 0, 1)):
                    continue
                spots.append((qr, qc, d))
        spots.sort(key=lambda s: ((s[0] * 7 + s[1] * 13 + m.index) % 17, s))
        return spots

    for comp in comps:
        if m.symmetric and all(m.canonical(*p) != p for p in comp):
            continue  # its partner places the pair
        # 1.4.6: every stretch of deadly water gets its sign and lifebuoy - where
        # the quay is crowded (cover, an objective), the second pass takes any
        # free spot along it (still clear of props, spawns and targets).
        for relaxed in (False, True):
          spots = quay_spots(comp, relaxed)
          for kind in ['warning_sign', 'lifebuoy_stand']:
            if relaxed and any(math.dist(t, m.centre(r, c)) < CELL * 2.5 for r, c in comp for t in taken[kind]):
                continue  # this stretch already has one
            for qr, qc, d in spots:
                x, z = m.centre(qr, qc)
                # against the parapet (its .25 m thickness), beside the cell centre
                x += d[1] * (CELL / 2 - .62) + (d[0] * (.9 if kind == 'warning_sign' else -.9))
                z += d[0] * (CELL / 2 - .62) + (d[1] * (.9 if kind == 'warning_sign' else -.9))
                if any(math.dist((x, z), t) < spacing[kind] for t in taken[kind]) or any(math.dist((x, z), t) < 3.5 for k2 in taken for t in taken[k2]):
                    continue
                if any(math.dist((x - m.ox, z - m.oz), (p[0], p[1])) < 1.6 for p in props):
                    continue
                if min(math.dist((x, z), p) for p in spawns + targets) < 6:
                    continue
                yaw = math.atan2(d[1], d[0]) + math.pi  # facing the street (away from the water)
                pairs = [(x, z, yaw)]
                if m.symmetric:
                    pairs.append((m.W - x, m.H - z, yaw + math.pi))
                for px, pz, pyaw in pairs:
                    out.append([round(px - m.ox, 4), round(pz - m.oz, 4), 0., round(pyaw, 5), kind])
                    taken[kind].append((px, pz))
                if kind == 'lifebuoy_stand':
                    break  # one lifebuoy per stretch of water; signs repeat every 30 m along it
    return out


def water_gates(m):
    """1.4.6 (the user: water must lead somewhere - out of the map, to the sea,
    or into a drain - and nobody may leave through it). Barred openings in the
    walls round the water, as world segments [x, z, x2, z2, nx, nz, bed, top,
    kind] (n: from the water into the wall):
      'outlet'  where deep water meets the map's outer wall (it flows on out
                of the map, to the sea or the next canal): a tall barred arch;
      'culvert' where a canal stops at a crossing and goes on beyond it (the
                water passes under the street): a low barred opening;
      'drain'   the ends of a pool that leads nowhere else, and the ends of a
                shallow ditch along the outer wall: a barred drain."""
    dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)]

    def outside(r, c):
        return m.at(r, c) in ' R' or not (0 <= r < m.h and 0 <= c < m.w)

    def perimeter(r, c, dr, dc):
        a = m.at(r + dr, c + dc)
        return outside(r + dr, c + dc) or (a == '#' and outside(r + 2 * dr, c + 2 * dc))

    def side(r, c, dr, dc):
        x0, z0, x1, z1 = c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL
        return {(0, 1): (x1, z0, x1, z1), (0, -1): (x0, z0, x0, z1), (1, 0): (x0, z1, x1, z1), (-1, 0): (x0, z0, x1, z0)}[(dr, dc)]

    out = []
    for ch in '~=':
        deep = ch == '~'
        cells = set(m.cells(ch))
        seen = set()
        for cell in sorted(cells):
            if cell in seen:
                continue
            comp, st = [], [cell]
            seen.add(cell)
            while st:
                a = st.pop()
                comp.append(a)
                for d in dirs:
                    b = (a[0] + d[0], a[1] + d[1])
                    if b in cells and b not in seen:
                        seen.add(b)
                        st.append(b)
            if m.symmetric and all(m.canonical(*p) != p for p in comp):
                continue  # (its half-turn partner adds the mirrored pair)
            gates = []
            rs = [r for r, c in comp]
            cs = [c for r, c in comp]
            long_rows = max(rs) - min(rs) >= max(cs) - min(cs)
            for r, c in comp:
                for dr, dc in dirs:
                    if (r + dr, c + dc) in cells:
                        continue
                    if perimeter(r, c, dr, dc):
                        if deep:
                            gates.append((r, c, dr, dc, 'outlet', WATER_BED, 1.7))
                        continue  # (a shallow ditch drains at its ends, below)
                    if deep:
                        # water of the same canal again 1-3 cells straight on: it runs under the crossing
                        if any((r + dr * k, c + dc * k) in cells for k in (2, 3, 4)):
                            gates.append((r, c, dr, dc, 'culvert', WATER_BED, -.06))
            if not deep:
                # a ditch along the outer wall: one drain at each end (in the wall)
                ends = sorted(comp, key=lambda p: (p[0], p[1]))
                for r, c in {ends[0], ends[-1]}:
                    for dr, dc in dirs:
                        if (r + dr, c + dc) not in cells and perimeter(r, c, dr, dc):
                            if not any(g[0] == r and g[1] == c for g in gates):
                                gates.append((r, c, dr, dc, 'drain', SHALLOW_BAND, .95))
                            break
            elif not any(g[4] == 'outlet' for g in gates) and not any(g[4] == 'culvert' for g in gates):
                # a pool that leads nowhere: drains at both ends of its long axis
                axis = [(1, 0), (-1, 0)] if long_rows else [(0, 1), (0, -1)]
                for dr, dc in axis:
                    far = max(comp, key=lambda p: p[0] * dr + p[1] * dc)
                    row = [p for p in comp if (p[0] * dr + p[1] * dc) == (far[0] * dr + far[1] * dc)]
                    mid = sorted(row)[len(row) // 2]
                    gates.append((mid[0], mid[1], dr, dc, 'drain', WATER_BED, -.06))
            # A canal along the outer wall leaves it through ONE barred arch (the
            # middle of each run of wall, at most two cells wide), not bars all along.
            outlets = [g for g in gates if g[4] == 'outlet']
            keep = []
            for d in set((g[2], g[3]) for g in outlets):
                line = sorted((g for g in outlets if (g[2], g[3]) == d), key=lambda g: (g[0], g[1]))
                runs, run = [], []
                for g in line:
                    if run and abs(g[0] - run[-1][0]) + abs(g[1] - run[-1][1]) == 1 and (g[0] == run[-1][0] or g[1] == run[-1][1]):
                        run.append(g)
                    else:
                        if run:
                            runs.append(run)
                        run = [g]
                if run:
                    runs.append(run)
                for run in runs:
                    mid = len(run) // 2
                    keep += run if len(run) <= 3 else run[max(0, mid - 1):mid + 1]
            gates = [g for g in gates if g[4] != 'outlet'] + keep
            for r, c, dr, dc, kind, b, t in gates:
                x0, z0, x1, z1 = side(r, c, dr, dc)
                pairs = [(x0, z0, x1, z1, dc, dr)]
                if m.symmetric and not any(m.mirror(*p) in comp for p in comp):
                    pairs.append((m.W - x0, m.H - z0, m.W - x1, m.H - z1, -dc, -dr))
                for px0, pz0, px1, pz1, nx, nz in pairs:
                    out.append((px0, pz0, px1, pz1, nx, nz, b, t, kind))
    return out


def quay_lines(m, open_quays):
    """World segments (x, z, x2, z2) of the open quay edges (a hazard curb)."""
    out = []
    for r, c, d in sorted(open_quays):
        x0, z0, x1, z1 = c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL
        seg = {(0, 1): (x1, z0, x1, z1), (0, -1): (x0, z0, x0, z1), (1, 0): (x0, z1, x1, z1), (-1, 0): (x0, z0, x1, z0)}[d]
        out.append(seg)
    return out


def place_doors(m, spawns, targets, limit=3):
    """Interactive doors (plan entries [x, z, y, yaw, left, right]) across
    one-cell corridors between building blocks, preferring connectors in the
    middle of the map. Regular maps take half-turn pairs; never near spawns,
    objectives, stairs or cover."""
    keep = set('SNTDABC/') | COVER
    found = []
    for r in range(m.h):
        for c in range(m.w):
            if m.symmetric and m.canonical(r, c) != (r, c):
                continue
            if m.g[r][c] not in '.,:':
                continue
            side = BLOCK | {'R', '~'}  # (1.4.6: a quay gate between a wall and the water counts too)
            ns = m.walk(r - 1, c) and m.walk(r + 1, c) and m.at(r, c - 1) in side and m.at(r, c + 1) in side
            ew = m.walk(r, c - 1) and m.walk(r, c + 1) and m.at(r - 1, c) in side and m.at(r + 1, c) in side
            if not (ns or ew):
                continue
            ends = [(r - 1, c), (r + 1, c)] if ns else [(r, c - 1), (r, c + 1)]
            level = m.level.get((r, c), 0.)
            if any(m.g[er][ec] not in '.,:' or abs(m.level.get((er, ec), 0.) - level) > .01 for er, ec in ends):
                continue
            if any(m.at(r + dr, c + dc) in keep for dr in range(-2, 3) for dc in range(-2, 3)):
                continue
            x, z = m.centre(r, c)
            near = min(math.dist((x, z), p) for p in spawns + targets)
            if near < 14:
                continue
            spawn_gap = min(math.dist((x, z), p) for p in spawns)
            found.append((-spawn_gap, (r * 31 + c * 17 + m.index) % 7, r, c, ns))
    found.sort()
    doors, taken = [], []
    for _, _, r, c, ns in found:
        cells = [(r, c)] + ([m.mirror(r, c)] if m.symmetric and m.mirror(r, c) != (r, c) else [])
        if len(doors) + len(cells) > limit:
            continue
        if any(max(abs(r2 - tr), abs(c2 - tc)) < 6 for r2, c2 in cells for tr, tc in taken):
            continue
        for rr, cc in cells:
            x, z = m.centre(rr, cc)
            # The door wall runs along its local X: across a N-S corridor that is world X.
            yaw = 0. if ns else math.pi / 2
            # The wall beside the door reaches the side wall - on a water side it
            # stops at the quay parapet (.25 m inside the cell), never into it.
            left, right = ((rr, cc - 1), (rr, cc + 1)) if ns else ((rr + 1, cc), (rr - 1, cc))
            reach = [CELL / 2 - (.27 if m.at(*s) == '~' else 0.) for s in (left, right)]
            doors.append([round(x - m.ox, 4), round(z - m.oz, 4), m.level.get((rr, cc), 0.), yaw, reach[0], reach[1]])
            taken.append((rr, cc))
    return doors


def cover_pose(m, r, c, ch):
    """Yaw and offset from the cell centre: cover hugs a wall or runs along the lane,
    always leaving a walkable gap."""
    sides = [d for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] if not m.walk(r + d[0], c + d[1])]
    h = (r * 7 + c * 13 + m.index) % 4
    if sides:
        d = sides[h % len(sides)]
        shift = {'c': 1.0, 'b': 1.1, 's': 1.1, 'k': .8, 'o': .6, 'p': 0., 'w': 1.1, 'n': 1.2, 'r': 1.0, 'f': 0.,
                 '1': 1.0, '2': 1.1, '3': 0., '4': .8, '5': 1.0, '6': 1.0}[ch]
        yaw = math.atan2(-d[1], -d[0])  # face away from the wall
        return yaw, (d[1] * shift, d[0] * shift)
    # Open ground: long cover lies across the dominant direction of travel.
    horizontal = m.walk(r, c - 1) and m.walk(r, c + 1)
    vertical = m.walk(r - 1, c) and m.walk(r + 1, c)
    yaw = 0. if horizontal and not vertical else math.pi / 2 if vertical and not horizontal else [0., math.pi / 2][h % 2]
    return yaw, ((h % 3 - 1) * .5, ((h // 2) % 3 - 1) * .5)


def routes(m, spawns, targets, defusal):
    import heapq
    def cell_of(p):
        return (int(p[1] // CELL), int(p[0] // CELL))
    def neighbours(a):
        for d in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
            b = (a[0] + d[0], a[1] + d[1])
            if b in m.level and abs(m.height_at(*a, *m.centre(*a)) - m.height_at(*b, *m.centre(*b))) < 1.6:
                yield b
    def path(a, b, cost):
        dist = {a: 0}
        prev = {}
        heap = [(0, a)]
        while heap:
            dcur, x = heapq.heappop(heap)
            if x == b:
                break
            if dcur > dist[x]:
                continue
            for y in neighbours(x):
                nd = dcur + cost.get(y, 1.)
                if nd < dist.get(y, 1e18):
                    dist[y] = nd
                    prev[y] = x
                    heapq.heappush(heap, (nd, y))
        if b not in dist:
            return []
        out = [b]
        while out[-1] != a:
            out.append(prev[out[-1]])
        return out[::-1]
    def simplify(cells):
        pts = [m.centre(*x) for x in cells]
        keep = [pts[0]]
        for i in range(1, len(pts) - 1):
            a, b, c = keep[-1], pts[i], pts[i + 1]
            if abs((b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])) > 1e-6:
                keep.append(b)
        keep.append(pts[-1])
        return [(round(x, 3), round(z, 3)) for x, z in keep]
    out = []
    cost = {}
    ends = [(spawns[0], spawns[1])] * 3 if not defusal else [(spawns[0], targets[0]), (spawns[0], targets[1]), (spawns[1], targets[0]), (spawns[1], targets[1]), (spawns[0], spawns[1])]
    for a, b in ends:
        cells = path(cell_of(a), cell_of(b), cost)
        if not cells:
            raise SystemExit('map %d: no route between %s and %s' % (m.index, a, b))
        for x in cells[2:-2]:
            cost[x] = cost.get(x, 1.) * 5.
        out.append(simplify(cells))
    if not defusal:
        for t in targets:
            cells = path(cell_of(spawns[0]), cell_of(t), {})
            if not cells:
                raise SystemExit('map %d: objective %s unreachable' % (m.index, t))
    return out


def preview_of(data):
    preview = {k: v for k, v in data.items() if k != 'groups'}
    preview['triangles'] = {key: [] for key in ['ground', 'upper', 'lower']}
    for surface in data['surfaces']:
        poly = Polygon(surface['rings'][0], surface['rings'][1:]).buffer(0)
        for tri in triangles(poly):
            preview['triangles'][surface['layer']].extend(tri)
    return preview


def main(indices):
    specs = json.loads((ARENAS / 'district_specs.json').read_text(encoding='utf-8'))
    for index in indices:
        m, data, spec = build(index)
        OUT.joinpath('map_%02d.json' % index).write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
        OUT.joinpath('map_%02d.json.gz' % index).write_bytes(gzip.compress(json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8'), mtime=0))
        OUT.joinpath('plan_%02d.json' % index).write_text(json.dumps(preview_of(data), ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
        specs[index] = spec
        tris = sum(len(g['vertices']) for g in data['groups']) // 3
        print('V15 %02d %s %dx%d cells, %d fronts, %d props (%d wall decor), %d loose, %d doors, %d trees, %d triangles' % (index, bp_name(index), m.w, m.h, len(data['fronts']), len(data['props']), m.decor_count, len(data['loose_props']), len(data['doors']), len(data['trees']), tris))
    (ARENAS / 'district_specs.json').write_text(json.dumps(specs, ensure_ascii=False), encoding='utf-8')


def bp_name(index):
    return BP.MAPS[index]['name']


if __name__ == '__main__':
    args = [int(a) for a in sys.argv[1:]] or sorted(BP.MAPS)
    main(args)
