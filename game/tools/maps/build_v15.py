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
PILLAR_INSET = 0.36  # just inside the opening's corner (1.5.4, the user: from .21 - its cap ran into the opening's trim strip; deeper, it closed 4 m passages for bots)
PARAPET_T = 0.25
# 1.5.0 (the user): deep water is fenced by 1.7 m iron bars on a low curb - a
# move + jump (0.82 m) plus a mantle (0.8 m in the air) no longer clears it.
CURB = 0.15
RAILING = 1.7
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


SIGHT_BLOCK = set('#RH^')


def corner_spawns(m, g0, teams, at, cells, visible, mirrored, gap=4, carve=False):
    """1.5.4: the spawn spot search (see relocate_spawns). Returns (grid, label) or None.
    gap: the least distance (cells) from an objective (small maps retry with 3).
    carve: (the user: widen the space where a spawn moves) the row of building on the
    map's outer side of a spot may be opened up to make the spawn's room."""
    import copy
    H, W = len(g0), len(g0[0])
    floor = '.,' + (':' if m.indoor else '')
    objectives = [(r, c) for r in range(H) for c in range(W) if g0[r][c] in 'ABC']
    def spots(ch, rows):
        out = []
        for r in rows:
            for c in range(W - 1):
                quad = [(r, c), (r, c + 1), (r + 1, c), (r + 1, c + 1)]
                opened = []
                if not all(at(g0, rr, cc) in floor + ch for rr, cc in quad):
                    # the outer row (toward the map's edge on this side) may be building, opened up
                    outer = r + 1 if r >= H // 2 else r
                    inner = r if outer == r + 1 else r + 1
                    if not (carve and all(at(g0, inner, cc) in floor + ch for cc in (c, c + 1)) and all(at(g0, outer, cc) in floor + ch + '#' for cc in (c, c + 1))
                            and all(at(g0, outer + (1 if outer == r + 1 else -1), cc) in '#R ' for cc in (c, c + 1))):
                        continue
                    opened = [(outer, cc) for cc in (c, c + 1) if at(g0, outer, cc) == '#']
                if any(max(abs(rr - orr), abs(cc - occ)) < gap for rr, cc in quad for orr, occ in objectives):
                    continue
                room = sum(1 for dr in range(-1, 3) for dc in range(-1, 3) if at(g0, r + dr, c + dc) in floor + 'cbswtn' + ch or (r + dr, c + dc) in opened)
                if room < (7 if carve else 12):
                    continue  # (room to respawn: most of the 4x4 cells round it open)
                out.append((r, c, room, opened))
        return out
    def place(g, ch, r, c, opened=()):
        h = copy.deepcopy(g)
        for rr, cc in cells(g, ch):
            h[rr][cc] = ','
        for rr, cc in opened:
            h[rr][cc] = ','
        for rr, cc in ((r, c), (r, c + 1), (r + 1, c), (r + 1, c + 1)):
            h[rr][cc] = ch
        return h
    def corner(r, c, low):
        # nearness to the map's outer edge on the team's side and to a side wall
        depth = (r + 1) / (H - 1) if low else 1 - r / (H - 1)
        return depth + abs((c + 1) - W / 2) / (W / 2)
    if m.symmetric:
        ch = teams[0]
        rows = range(H // 2, H - 1)
        best = None
        for r, c, room, opened in spots(ch, rows):
            if abs((c + 1) - W / 2) < W * .2 or r + 1 < H * .68:
                continue  # (toward a side and out at its own end, not in the middle: the middle lines up with the other spawn)
            h = mirrored(place(g0, ch, r, c, opened))
            if visible(h):
                continue
            score = corner(r, c, True) + room * .02
            if best is None or score > best[0]:
                best = (score, h, 'corner %d,%d%s' % (r, c, ' opened' if opened else ''))
        return (best[1], best[2]) if best else None
    # defusal: each team keeps to the third of the map on its own side
    a, b = cells(g0, teams[0]), cells(g0, teams[1])
    if not a or not b:
        return None
    ra = sum(r for r, _ in a) / len(a); rb = sum(r for r, _ in b) / len(b)
    ca = sum(c for _, c in a) / len(a); cb = sum(c for _, c in b) / len(b)
    vertical = abs(ra - rb) >= abs(ca - cb)
    def own(team_r, team_c, r, c):
        if vertical:
            return (r < H / 3) if team_r < H / 2 else (r >= 2 * H / 3 - 1)
        return (c < W / 3) if team_c < W / 2 else (c >= 2 * W / 3 - 1)
    def side_score(team_r, team_c, r, c):
        if vertical:
            depth = (1 - r / (H - 1)) if team_r < H / 2 else (r + 1) / (H - 1)
            return depth + abs((c + 1) - W / 2) / (W / 2)
        depth = (1 - c / (W - 1)) if team_c < W / 2 else (c + 1) / (W - 1)
        return depth + abs((r + 1) - H / 2) / (H / 2)
    ca_spots = [s for s in spots(teams[0], range(H - 1)) if own(ra, ca, s[0], s[1])]
    cb_spots = [s for s in spots(teams[1], range(H - 1)) if own(rb, cb, s[0], s[1])]
    ca_spots.sort(key=lambda s: -(side_score(ra, ca, s[0], s[1]) + s[2] * .02))
    cb_spots.sort(key=lambda s: -(side_score(rb, cb, s[0], s[1]) + s[2] * .02))
    for sa in ca_spots[:40]:
        h1 = place(g0, teams[0], sa[0], sa[1], sa[3])
        for sb in cb_spots[:40]:
            h2 = place(h1, teams[1], sb[0], sb[1], sb[3])
            if not visible(h2):
                return (h2, 'corners %d,%d / %d,%d' % (sa[0], sa[1], sb[0], sb[1]))
    return None


OUTLINE_PAD = 4
OUTLINE_SKIP = set()   # maps whose reshaped outline broke a route (main() retries them plain)


def reshape_outline(m):
    """1.5.4 (the user: no map may end in a plain rectangle - keep the middle and give every
    map its own outline): the band along the outer wall is reshaped per map. A few stretches
    of the edge streets give way to building (the wall steps in) and elsewhere the wall steps
    out into small yards. Every change keeps the map whole - each spawn still reaches every
    objective and every street, a lane beside a step-in keeps two cells, water, stairs,
    terraces and markers are left alone - and regular maps change in half-turn pairs.
    The grid is padded so the yards have room outside the old wall. Returns the changes."""
    import random
    pad = OUTLINE_PAD
    g = [[' '] * (m.w + 2 * pad) for _ in range(m.h + 2 * pad)]
    for r in range(m.h):
        for c in range(m.w):
            g[r + pad][c + pad] = m.g[r][c]
    m.g = g
    m.h += 2 * pad; m.w += 2 * pad
    m.W = m.w * CELL; m.H = m.h * CELL; m.ox = m.W / 2; m.oz = m.H / 2
    plain = set('.,cbswo')
    dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)]
    if m.index in OUTLINE_SKIP:
        return {'in': 0, 'out': 0}

    def level(ch):
        # stairs, cover and markers join whatever floor they stand on
        return None if ch in '/' or ch in COVER or ch in 'SNTDABC' else 1 if ch == '^' else -1 if ch == 'v' else 0

    def outside(r, c):
        return m.at(r, c) in ' x'

    def ring(r, c):
        return m.at(r, c) == '#' and any(outside(r + dr, c + dc) for dr in (-1, 0, 1) for dc in (-1, 0, 1))

    def whole(grid):
        cells = [(r, c) for r in range(m.h) for c in range(m.w) if grid[r][c] in WALK]
        if not cells:
            return False
        start = next(((r, c) for r, c in cells if grid[r][c] in 'SNTD'), cells[0])
        seen, stack = {start}, [start]
        while stack:
            a = stack.pop()
            for dr, dc in dirs:
                b = (a[0] + dr, a[1] + dc)
                if b not in seen and 0 <= b[0] < m.h and 0 <= b[1] < m.w and grid[b[0]][b[1]] in WALK:
                    la, lb = level(grid[a[0]][a[1]]), level(grid[b[0]][b[1]])
                    if la is not None and lb is not None and la != lb:
                        continue
                    seen.add(b); stack.append(b)
        return len(seen) == len(cells)

    def pairs(cells):
        out = list(cells)
        if m.symmetric:
            out += [m.mirror(r, c) for r, c in cells]
        return out

    def free(r, c, radius=1):
        return not any(m.at(r + dr, c + dc) in '~=/^vSNTDABC' for dr in range(-radius, radius + 1) for dc in range(-radius, radius + 1))

    rng = random.Random(9173 * m.index + 17)
    candidates = []
    for r in range(m.h):
        for c in range(m.w):
            if m.symmetric and m.canonical(r, c) != (r, c):
                continue
            for dr, dc in dirs:
                # (dr, dc): from the ring cell inward
                if not ring(r, c) or not outside(r - dr, c - dc):
                    continue
                along = (dc, dr)
                for length in (7, 6, 5, 4, 3, 2):
                    seg = [(r + along[0] * k, c + along[1] * k) for k in range(length)]
                    if not all(ring(*p) for p in seg):
                        continue
                    inner = [(a + dr, b + dc) for a, b in seg]
                    calm = all(free(*p, 1) for p in inner)
                    # step in: the edge-street cells become building (two cells of street stay)
                    deeper = [(a + 2 * dr, b + 2 * dc) for a, b in seg] + [(a + 3 * dr, b + 3 * dc) for a, b in seg]
                    if calm and all(m.at(*p) in plain for p in inner) and all(m.walk(*p) for p in deeper):
                        candidates.append(('in', inner, seg))
                    # step out: the wall and two or three cells beyond become a yard, open to the
                    # streets it touches (at least two cells of it)
                    if length >= 4 and calm and sum(1 for p in inner if m.at(*p) in plain) >= 2:
                        depth = 2 + (r * 3 + c * 5 + m.index) % 2
                        beyond = [(a - dr * k, b - dc * k) for a, b in seg for k in range(1, depth)]
                        if all(outside(*p) for p in beyond):
                            candidates.append(('out', seg + beyond, (dr * (depth - 1), dc * (depth - 1), seg)))
                    break
    rng.shuffle(candidates)
    want = {'in': 2 + m.index % 3, 'out': 3 + (m.index // 2) % 3}
    done = {'in': 0, 'out': 0}
    used = []
    for kind, cells, extra in candidates:
        if done[kind] >= want[kind]:
            continue
        if any(abs(p[0] - q[0]) + abs(p[1] - q[1]) < 4 for p in cells for q in used):
            continue
        before = [row[:] for row in m.g]
        for r, c in pairs(cells):
            if kind == 'in':
                m.g[r][c] = '#'
            else:
                m.g[r][c] = '.'
        if kind == 'out':
            # a piece of cover at the back of the yard
            dr, dc, seg = extra
            back = seg[len(seg) // 2]
            back = (back[0] - dr, back[1] - dc)
            for r, c in pairs([back]):
                m.g[r][c] = 'cbw'[(m.index + back[0] + back[1]) % 3]
        if not whole(m.g):
            m.g = before
            continue
        done[kind] += 1
        used += cells
    return done


def open_waters(m):
    """1.5.4 (the user: boats lay in basins walled in by buildings - open the water to the sea
    and give it room): deep water lying against the outer wall is let out past it. The
    boundary building between it and the edge of the grid gives way to water and the void
    beyond to open water ('O': deep, deadly, never walkable), so the basin meets a sea that
    runs on past the map to the horizon (build() extends its surface 300 m out).
    Returns the number of open-water cells."""
    dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)]
    def ring(r, c):
        return m.at(r, c) == '#' and any(m.at(r + dr, c + dc) in ' x' for dr in (-1, 0, 1) for dc in (-1, 0, 1))
    opened = 0
    for r, c in m.cells('~'):
        for dr, dc in dirs:
            path, rr, cc, walls = [], r + dr, c + dc, 0
            ok = True
            while 0 <= rr < m.h and 0 <= cc < m.w:
                ch = m.g[rr][cc]
                if ch in ' xO':
                    path.append((rr, cc, 'O'))
                elif ch == '#' and ring(rr, cc) and walls < 2 and all(p[2] == '~' for p in path):
                    path.append((rr, cc, '~')); walls += 1
                else:
                    ok = False
                    break
                rr += dr; cc += dc
            if not ok or not any(p[2] == 'O' for p in path):
                continue
            # a street beside the new opening keeps its wall: only cells with no walkable
            # neighbour across the channel are opened
            if any(m.walk(pr + dc, pc + dr) or m.walk(pr - dc, pc - dr) for pr, pc, ch in path if ch == '~'):
                continue
            for pr, pc, ch in path:
                if m.g[pr][pc] != ch:
                    m.g[pr][pc] = ch; opened += 1
    return opened


def central_pond(m):
    """1.5.4 (the user: maps with safe shallow water have it only round the edge - put a pond
    or a fountain pool in the middle too): on such maps the open 2x2 cells of plain ground
    nearest the centre (two cells clear of objectives, spawns, stairs and deep water, with
    ground all round so it reads as a pool in a square) become shallow water; regular maps
    get the half-turn pair (or one pool on the centre itself). Returns the pool cells."""
    if not m.cells('=') or m.indoor:
        return []
    best = None
    cr, cc = (m.h - 1) / 2, (m.w - 1) / 2
    for r in range(1, m.h - 2):
        for c in range(1, m.w - 2):
            block = [(r, c), (r + 1, c), (r, c + 1), (r + 1, c + 1)]
            if not all(m.at(*p) in '.,' for p in block):
                continue
            ring = [(r + dr, c + dc) for dr in range(-1, 3) for dc in range(-1, 3) if (r + dr, c + dc) not in block]
            if not all(m.at(*p) in '.,cbswonft' for p in ring):
                continue
            if any(m.at(r + dr, c + dc) in 'SNTDABC/~^v' for dr in range(-2, 4) for dc in range(-2, 4)):
                continue
            cells = block + ([m.mirror(*p) for p in block] if m.symmetric else [])
            if m.symmetric and len(set(cells)) < len(cells) and set(cells) != set(block):
                continue
            d = abs(r + .5 - cr) + abs(c + .5 - cc)
            if best is None or d < best[0]:
                best = (d, sorted(set(cells)))
    if best is None or best[0] > (m.w + m.h) * .18:
        # a small fountain pool (one cell) where the middle has no room for a pond
        for r in range(1, m.h - 1):
            for c in range(1, m.w - 1):
                if m.at(r, c) not in '.,' or not all(m.at(r + dr, c + dc) in '.,cbswonft' for dr in (-1, 0, 1) for dc in (-1, 0, 1) if (dr, dc) != (0, 0)):
                    continue
                if any(m.at(r + dr, c + dc) in 'SNTDABC/~^v' for dr in range(-1, 2) for dc in range(-1, 2)):
                    continue
                d = abs(r - cr) + abs(c - cc)
                cells = [(r, c)] + ([m.mirror(r, c)] if m.symmetric and m.mirror(r, c) != (r, c) else [])
                if best is None or d < best[0]:
                    best = (d, cells)
    if best is None:
        return []
    for r, c in best[1]:
        m.g[r][c] = '='
    return best[1]


def relocate_spawns(m):
    """1.4.7 (the user: no team may see the enemy side from its own spawn - fix it
    by moving the starting positions, not with screen walls). Sight is traced on
    the cell grid at the spawn grid points (16 per team, as DistrictLayout lays
    them out) through walls, boundary buildings and raised decks. Tried in order,
    the first that leaves no clear line is kept:
      1. the 2x2 spawn marker moved up to three cells within its own area;
      2. the spawn alcove slid sideways along the outer wall;
      3. a dog-leg: the spawn tucked sideways into the wall band beside its
         alcove (a short passage back to it), the wall in front of it kept.
    Regular maps change one side and mirror it; defusal maps move both."""
    import copy
    g0 = m.g
    defusal = m.bp['mode'] == 'defusal'
    teams = ('T', 'D') if defusal else ('S', 'N')

    def at(g, r, c):
        return g[r][c] if 0 <= r < len(g) and 0 <= c < len(g[0]) else ' '

    def cells(g, ch):
        return [(r, c) for r in range(len(g)) for c in range(len(g[0])) if g[r][c] == ch]

    def centre(cs):
        return (sum((c + .5) * CELL for r, c in cs) / len(cs), sum((r + .5) * CELL for r, c in cs) / len(cs))

    def grid(p):
        return [(p[0] + (i % 4 - 1.5) * 1.7, p[1] + (i // 4 - 1.5) * 1.7) for i in range(16)]

    def stands(g, x, z):
        return at(g, int(z // CELL), int(x // CELL)) in '.,:' + ''.join(teams)

    def blocked(g, a, b):
        n = max(1, int(math.dist(a, b) / .25))
        for k in range(1, n):
            x = a[0] + (b[0] - a[0]) * k / n
            z = a[1] + (b[1] - a[1]) * k / n
            if at(g, int(z // CELL), int(x // CELL)) in SIGHT_BLOCK:
                return True
        return False

    def visible(g):
        cs = [cells(g, ch) for ch in teams]
        if not all(cs):
            return 1
        a = [p for p in grid(centre(cs[0])) if stands(g, *p)]
        b = [p for p in grid(centre(cs[1])) if stands(g, *p)]
        if len(a) < 8 or len(b) < 8:
            return 1
        return sum(1 for p in a for q in b if not blocked(g, p, q))

    def mirrored(g):
        if not m.symmetric:
            return g
        H, W = len(g), len(g[0])
        out = copy.deepcopy(g)
        for r in range(H // 2):
            for c in range(W):
                src = g[H - 1 - r][W - 1 - c]
                out[r][c] = MARK_MIRROR.get(src, src)
        return out

    def move_marker(g, ch, dr, dc):
        cs = cells(g, ch)
        h = copy.deepcopy(g)
        for r, c in cs:
            h[r][c] = ','
        for r, c in cs:
            if at(g, r + dr, c + dc) not in '.,' + ch:
                return None
            h[r + dr][c + dc] = ch
        return h

    def slide(g, ch, k):
        cs = cells(g, ch)
        rows = sorted(set(r for r, c in cs))
        h = copy.deepcopy(g)
        inward = -1 if rows[0] > len(g) / 2 else 1
        for r in rows:
            lo = min(c for rr, c in cs if rr == r); hi = max(c for rr, c in cs if rr == r)
            while at(g, r, lo - 1) in '.,': lo -= 1
            while at(g, r, hi + 1) in '.,': hi += 1
            old = [g[r][c] for c in range(lo, hi + 1)]
            for c in range(lo, hi + 1):
                h[r][c] = '#'
            for i, c in enumerate(range(lo + k, hi + k + 1)):
                if at(g, r, c) not in '#.,' + ch:
                    return None
                h[r][c] = old[i]
        mouth = rows[0] - 1 if inward < 0 else rows[-1] + 1
        cs2 = cells(h, ch)
        if not all(at(h, mouth, c) in '.,cbw' for r, c in cs2 if r == (rows[0] if inward < 0 else rows[-1])):
            return None
        return h

    def dogleg(g, ch, side, depth):
        cs = cells(g, ch)
        rows = sorted(set(r for r, c in cs)); cols = sorted(set(c for r, c in cs))
        inward = -1 if rows[0] > len(g) / 2 else 1
        edge = rows[0] if inward < 0 else rows[-1]
        lo, hi = cols[0], cols[-1]
        while at(g, rows[0], lo - 1) in '.,': lo -= 1
        while at(g, rows[0], hi + 1) in '.,': hi += 1
        if side < 0:
            new_cols = [lo - depth - 1, lo - depth]; corridor = range(lo - depth - 1, lo)
        else:
            new_cols = [hi + depth, hi + depth + 1]; corridor = range(hi + 1, hi + depth + 2)
        h = copy.deepcopy(g)
        for r in rows:
            for c in corridor:
                if at(g, r, c) != '#':
                    return None
        for r, c in cs:
            h[r][c] = ','
        for r in rows:
            for c in corridor:
                h[r][c] = ','
            for c in new_cols:
                h[r][c] = ch
        if any(at(h, edge + inward, c) not in '#R' for c in new_cols):
            return None
        return h

    # 1.5.4 (the user: put the starting points where they can't see each other in a straight
    # line - e.g. in opposite corners - with room around them to respawn, instead of the
    # lane walls): every open 2x2 spot of a team's own part of the map is tried, and the
    # one out of the other spawn's sight, far enough from the objectives, with the most
    # open ground round it and nearest a corner of its side is kept.
    picked = corner_spawns(m, g0, teams, at, cells, visible, mirrored) or corner_spawns(m, g0, teams, at, cells, visible, mirrored, 3) or corner_spawns(m, g0, teams, at, cells, visible, mirrored, 3, True)
    if picked is not None:
        m.g = picked[0]
        return picked[1]
    movers = [teams[0]] if m.symmetric else list(teams)
    trials = []
    shifts = sorted(((dr, dc) for dr in range(-3, 4) for dc in range(-3, 4) if (dr, dc) != (0, 0)), key=lambda d: abs(d[0]) + abs(d[1]))
    if m.symmetric:
        trials += [('marker %d,%d' % d, (lambda g, d=d: move_marker(g, teams[0], *d))) for d in shifts]
        trials += [('slide %d' % k, (lambda g, k=k: slide(g, teams[0], k))) for k in sorted(range(-8, 9), key=abs) if k]
        trials += [('dogleg %d,%d' % (s, d), (lambda g, s=s, d=d: dogleg(g, teams[0], s, d))) for d in range(1, 6) for s in (-1, 1)]
    else:
        for d1 in [(0, 0)] + shifts:
            for d2 in [(0, 0)] + shifts:
                if d1 == d2 == (0, 0):
                    continue
                def both(g, d1=d1, d2=d2):
                    h = move_marker(g, teams[0], *d1) if d1 != (0, 0) else g
                    return move_marker(h, teams[1], *d2) if h is not None and d2 != (0, 0) else h
                trials.append(('markers %s %s' % (d1, d2), both))
    for name, trial in trials:
        h = trial(g0)
        if h is None:
            continue
        h = mirrored(h)
        if not visible(h):
            m.g = h
            return name
    m.problems.append('spawns still see each other')
    return 'unresolved'


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
        self.outline = reshape_outline(self)
        self.open_sea = open_waters(self)
        self.pond = central_pond(self)
        self.spawn_move = relocate_spawns(self)
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
            if near(r, c, 'SNTD', 3) or near(r, c, 'ABC/', 1):  # (1.4.7: 3 - a moved spawn's alcove mouth stays clear)
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
            # (1.5.4, the user: thin yellow strips showed through walls beside stairs - the treads
            # and risers stop 3 cm short of the stair's sides, clear of any wall there)
            s = .03
            if dc:
                a0, a1 = x0 + CELL * t0, x0 + CELL * t1
                tread = box(a0, z0 + s, a1, z1 - s)
                edge = a0 if yb > ya else a1
                riser = [(edge, z0 + s), (edge, z1 - s)]
            else:
                a0, a1 = z0 + CELL * t0, z0 + CELL * t1
                tread = box(x0 + s, a0, x1 - s, a1)
                edge = a0 if yb > ya else a1
                riser = [(x0 + s, edge), (x1 - s, edge)]
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
    railings = []  # 1.5.0: barred railings along deep water [u, v, d, hu, hv]

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
                    wall(v, u, WATER_BED, WATER_BED, hv + CURB, hu + CURB, 'wall')
                    rail_edge(u, v, d)
                    parapet(emit, wall, u, v, d, hu, hv, CURB)
                    railings.append((u, v, d, hu, hv))
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
                        # (1.5.4, the user: a strip with no depth - 5 cm deep now: its face stands
                        # 5 cm into the room, with an underside and ends)
                        n = (-d[1] * .05, -d[0] * .05)
                        u2, v2 = (u[0] + n[0], u[1] + n[1]), (v[0] + n[0], v[1] + n[1])
                        wall(u2, v2, ROOM_CEILING - .25, ROOM_CEILING - .25, ROOM_CEILING, ROOM_CEILING, 'trim')
                        lo = ROOM_CEILING - .25
                        emit([(u[0], lo, u[1]), (v[0], lo, v[1]), (v2[0], lo, v2[1])], 'trim')
                        emit([(u[0], lo, u[1]), (v2[0], lo, v2[1]), (u2[0], lo, u2[1])], 'trim')
                        wall(u, u2, lo, lo, ROOM_CEILING, ROOM_CEILING, 'trim')
                        wall(v2, v, lo, lo, ROOM_CEILING, ROOM_CEILING, 'trim')
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
    water_cells = m.cells('~O')
    water = unary_union([box(c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL) for r, c in water_cells]) if water_cells else Polygon()
    if water_cells:
        floor(water, lambda x, z: WATER_BED, 'waterbed')
        floor(water, lambda x, z: WATER_Y, 'water')
        # 1.5.4 open sea: open water at the edge of the grid runs on 300 m to the horizon
        far = []
        for r, c in m.cells('O'):
            if c == 0: far.append(box(-300., r * CELL, 0., (r + 1) * CELL))
            if c == m.w - 1: far.append(box(m.W, r * CELL, m.W + 300., (r + 1) * CELL))
            if r == 0: far.append(box(c * CELL, -300., (c + 1) * CELL, 0.))
            if r == m.h - 1: far.append(box(c * CELL, m.H, (c + 1) * CELL, m.H + 300.))
        if far:
            sea = unary_union(far)   # (cell-aligned boxes merge exactly; a buffer left slivers at the far corners)
            floor(sea, lambda x, z: WATER_BED, 'seabed')   # (seen, never walked on: no collision)
            floor(sea, lambda x, z: WATER_Y, 'water')
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

    # 1.5.4 (the user): the lane walls are gone - the spawns are placed out of each other's sight instead
    walls_across = []
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
                if part == 'pillar':  # (1.5.4, the user: a pillar holding nothing - a figure on it outdoors, up to the ceiling in a room;
                    # the one ending a low wall is a lamp-topped gatepost, still standing height)
                    part = 'pillar_full' if ch in INDOOR else 'pillar_statue' if kind == 'pillar' else 'pillar_post'
                props.append([round(x + offset[0] + wx - ox, 4), round(z + offset[1] + wz - oz, 4), y, round(yaw + dyaw, 5), part])
    decor_count = len(props)
    props += wall_decor(m, index)
    props += water_safety(m, open_quays, props, spawns, targets)
    m.decor_count = len(props) - decor_count
    # (1.5.0) nothing stands where a lane wall stands
    clear_of = lambda x, z, pad: not any(abs(x - b[2]) < b[5] * .5 + pad and abs(z - b[3]) < b[6] * .5 + pad for b in walls_across)
    props = [p for p in props if clear_of(p[0] + ox, p[1] + oz, .9)]

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
        if not clear_of(x, z, 1.2):
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
            'water_gates': [[round(g[0] - ox, 4), round(g[1] - oz, 4), round(g[2] - ox, 4), round(g[3] - oz, 4)] + list(g[4:]) for g in water_fences(m)],
            'railings': [[round(u[0] - ox, 4), round(u[1] - oz, 4), round(v[0] - ox, 4), round(v[1] - oz, 4), round(hu + CURB, 4), round(hv + CURB, 4), -d[1], -d[0]] for u, v, d, hu, hv in railings],
            'baffles': [[round(b[2] - ox, 4), round(b[4], 4), round(b[3] - oz, 4), round(b[5], 4), round(b[6], 4), round(b[7], 4)] for b in walls_across if not any(math.dist((b[2] - ox, b[3] - oz), (dd[0], dd[1])) < 3.5 for dd in doors)],
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


def parapet(emit, wall, u, v, d, hu, hv, height=PARAPET):
    # Inner face and cap of a parapet standing on the higher (left) side of u->v.
    nx, nz = -d[1], -d[0]  # into the walkable cell
    # Caps of perpendicular parapets share their corner square: lift the ones
    # running along z by 4 mm so the corner never z-fights.
    top = height + (.004 if abs(v[0] - u[0]) < 1e-6 else 0.)
    iu = (u[0] + nx * PARAPET_T, u[1] + nz * PARAPET_T)
    iv = (v[0] + nx * PARAPET_T, v[1] + nz * PARAPET_T)
    wall(u, v, 0, 0, 0, 0, 'trim')
    emit([(iv[0], hv, iv[1]), (iu[0], hu, iu[1]), (iv[0], hv + top, iv[1])], 'trim')
    emit([(iu[0], hu, iu[1]), (iu[0], hu + top, iu[1]), (iv[0], hv + top, iv[1])], 'trim')
    emit([(u[0], hu + top, u[1]), (v[0], hv + top, v[1]), (iu[0], hu + top, iu[1])], 'trim')
    emit([(v[0], hv + top, v[1]), (iv[0], hv + top, iv[1]), (iu[0], hu + top, iu[1])], 'trim')
    # 1.5.0 (the user: open models): both ends closed - where a parapet run
    # stopped, its end showed the hollow inside (inside a run the caps are hidden).
    for p, ip, h in ((u, iu, hu), (v, iv, hv)):
        emit([(p[0], h, p[1]), (ip[0], h, ip[1]), (ip[0], h + top, ip[1])], 'trim')
        emit([(p[0], h, p[1]), (ip[0], h + top, ip[1]), (p[0], h + top, p[1])], 'trim')


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
              'lighter': (12.0, 4.2), 'patrol': (9.5, 3.0), 'workboat': (6.0, 2.4), 'wreck': (9.0, 3.2), 'punt': (4.5, 1.5),
              # 1.5.4 (the user: boats far bigger, people walk about inside): walk-in deckhouses (BoatModels)
              'ferry': (20.0, 6.0), 'freighter': (24.0, 7.0), 'trawler': (15.0, 5.0), 'barge': (18.0, 4.6)}
BOAT_TYPES = {'canal': ['barge', 'narrowboat', 'houseboat'], 'oldtown': ['barge', 'narrowboat', 'launch'], 'market': ['barge', 'houseboat'],
              'harbour': ['freighter', 'trawler', 'tug'], 'logistics': ['freighter', 'barge', 'lighter'], 'shipyard': ['freighter', 'trawler', 'tug'],
              'coastal_base': ['ferry', 'patrol', 'launch'], 'desert': ['ferry', 'patrol'], 'wreckyard': ['trawler', 'wreck'],
              'nuclear': ['barge', 'workboat'], 'power': ['barge', 'workboat'], 'greenhouse': ['barge', 'punt'], 'orchard': ['barge', 'punt'], 'aqueduct': ['barge', 'narrowboat'],
              'hillside': ['trawler', 'launch']}


def place_boats(m):
    """Boats in the deep water ('~'): the largest that fits each straight run
    of water, with a margin to every wall, lying along the run beside a quay
    (walkable ground cells at level 0) where there is one. Regular maps place
    half-turn pairs. Returns (boats, open quay edges)."""
    style = MAP_STYLE[m.index] if m.index < len(MAP_STYLE) else 'harbour'
    types = BOAT_TYPES.get(style, ['launch', 'workboat'])
    taken = set()
    boats, open_quays = [], set()
    water = set(m.cells('~O'))
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
        # (1.5.4: the biggest boat that fits, so players can walk about it; ties by the map)
        fit = sorted(fit, key=lambda t: -BOAT_SIZES[t][0] * BOAT_SIZES[t][1])
        kind = fit[0] if len(fit) == 1 or (r + c + m.index) % 3 else fit[1]
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


def baffles(m, spawns, targets=()):
    """1.5.0 (the user): where a straight lane runs from a spawn toward the enemy
    side for 8 cells (32 m) and more, tall walls stand across part of it - at
    12 m and 28 m out (and 44 m on very long lanes), on alternate sides, as high
    as two storeys (to the ceiling indoors) - so grenades can't be lobbed down
    the lane into the spawn, and its straight sight line is broken. Each wall
    leaves at least 1.8 m to walk past. Returns [r, c, x, z, y, sx, sz, h] (grid
    metres, not yet centred)."""
    out = []
    marks = ('T', 'D') if m.cells('T') else ('S', 'N')
    blocks = [sorted(m.cells(ch)) for ch in marks]
    walk = lambda r, c: m.at(r, c) in WALK and (r, c) not in m.stairs and m.at(r, c) != '='
    for team, block in enumerate(blocks):
        if not block:
            continue
        enemy = blocks[1 - team]
        er = sum(r for r, _ in enemy) / len(enemy); sr = sum(r for r, _ in block) / len(block)
        ec = sum(c for _, c in enemy) / len(enemy); sc = sum(c for _, c in block) / len(block)
        d = (1 if er > sr else -1, 0) if abs(er - sr) >= abs(ec - sc) else (0, 1 if ec > sc else -1)
        best = None
        starts = set(block) | {(r + a, c + b) for r, c in block for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))}
        for r0, c0 in sorted(starts):
            if not (walk(r0, c0) or m.at(r0, c0) in marks):
                continue
            n, r, c = 0, r0, c0
            while walk(r + d[0], c + d[1]) or m.at(r + d[0], c + d[1]) in marks:
                r += d[0]; c += d[1]; n += 1
            if best is None or n > best[0]:
                best = (n, r0, c0)
        if best is None or best[0] < 8:
            continue
        n, r0, c0 = best
        across = (d[1], d[0])  # perpendicular (r, c) step
        side = 1
        for k in [3, 7, 11][:1 + (n >= 10) + (n >= 15)]:
            placed = False
            for kk in (k, k + 1, k - 1):
                r, c = r0 + d[0] * kk, c0 + d[1] * kk
                if not walk(r, c) or m.at(r, c) in COVER or m.at(r, c) in 'SNTDABC':
                    continue
                y = m.level.get((r, c), 0.)
                lo = hi = 0  # corridor extent across (cells) at this level
                while walk(r - across[0] * (lo + 1), c - across[1] * (lo + 1)) and abs(m.level.get((r - across[0] * (lo + 1), c - across[1] * (lo + 1)), 0.) - y) < .05:
                    lo += 1
                while walk(r + across[0] * (hi + 1), c + across[1] * (hi + 1)) and abs(m.level.get((r + across[0] * (hi + 1), c + across[1] * (hi + 1)), 0.) - y) < .05:
                    hi += 1
                cells = lo + hi + 1
                if cells > 3:
                    continue  # an open square, not a lane
                width_m = cells * CELL
                wall_w = min(width_m - 1.8, max(2.2, width_m * .55))
                # anchored to one side of the lane (alternating), centred along the cell
                x0, z0 = m.centre(r, c)
                edge_off = (hi + .5) * CELL if side > 0 else -(lo + .5) * CELL  # from this cell's centre to the lane side
                # off a railing or parapet edge (deep water, a drop) it stands 0.3 m in,
                # not through the bars; against a building it stands flush
                br, bc = (r + across[0] * (hi + 1), c + across[1] * (hi + 1)) if side > 0 else (r - across[0] * (lo + 1), c - across[1] * (lo + 1))
                inset = .3 if m.at(br, bc) == '~' or walk(br, bc) else 0.
                mid_off = edge_off - side * (inset + wall_w * .5)
                x = x0 + across[1] * mid_off
                z = z0 + across[0] * mid_off
                indoor = m.at(r, c) in INDOOR
                h = ROOM_CEILING if indoor else 6.0
                sx, sz = (wall_w, .4) if across[1] else (.4, wall_w)
                if any(math.dist((x, z), t) < 7. for t in targets):
                    continue  # never at an objective (a bomb site stood under one)
                out.append([r, c, x, z, y, sx, sz, h])
                placed = True
                break
            if placed:
                side = -side
    return out

def water_fences(m):
    """1.4.6 (the user's choice): bars only between safe and deadly water - where
    a shallow ditch lies one dry cell from deep water, its edge facing the deep
    water gets a barred grate under the water (never above its surface - the user). Never
    on the ditch's last open side. Segments [x, z, x2, z2, nx, nz, bed, top,
    'fence'] (n: from the shallow water out over the fence)."""
    dirs = [(0, 1), (1, 0), (0, -1), (-1, 0)]
    shallow = set(m.cells('='))
    deep = set(m.cells('~'))
    out = []
    for r, c in sorted(shallow):
        if m.symmetric and m.canonical(r, c) != (r, c):
            continue
        for dr, dc in dirs:
            n = (r + dr, c + dc)
            if n in shallow or not m.walk(*n):
                continue
            beyond = [(n[0] + dr, n[1] + dc), (n[0] + dr + dc, n[1] + dc + dr), (n[0] + dr - dc, n[1] + dc - dr)]
            if not any(b in deep for b in beyond):
                continue
            # keep a way out of the ditch: another open dry side somewhere on it
            others = [(rr, cc, d2) for rr, cc in shallow for d2 in dirs
                      if (rr + d2[0], cc + d2[1]) not in shallow and m.walk(rr + d2[0], cc + d2[1]) and (rr, cc, d2) != (r, c, (dr, dc))]
            if not others:
                continue
            x0, z0, x1, z1 = c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL
            seg = {(0, 1): (x1, z0, x1, z1), (0, -1): (x0, z0, x0, z1), (1, 0): (x0, z1, x1, z1), (-1, 0): (x0, z0, x1, z0)}[(dr, dc)]
            out.append(seg + (dc, dr, SHALLOW_BAND, SHALLOW_SURFACE - .04, 'fence'))
            if m.symmetric and m.mirror(r, c) != (r, c):
                out.append((m.W - seg[0], m.H - seg[1], m.W - seg[2], m.H - seg[3], -dc, -dr, SHALLOW_BAND, SHALLOW_SURFACE - .04, 'fence'))
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
        try:
            m, data, spec = build(index)
        except SystemExit as error:
            # (1.5.4: a reshaped outline that cuts a route - the map keeps its plain outline)
            print('V15 %02d outline dropped: %s' % (index, error))
            OUTLINE_SKIP.add(index)
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
