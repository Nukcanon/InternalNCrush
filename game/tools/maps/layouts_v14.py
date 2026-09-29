"""1.4 competitive layouts: point-symmetric route chains for the 19 regular maps.

Every regular map is exactly symmetric under the half-turn
(x, y) -> (100 - x, 100 - y): team A spawns at the bottom (50, 90), team B at the
top (50, 10), and every route, room and elevation seen by one team exists for
the other. Chains 0/1/2 are the left / middle / right lanes, so capture zones
A and B (lane midpoints) mirror each other and C sits at the centre.

A lane is built from two "lower halves" (spawn A up to the midline): the left
lane is H_left followed by the half-turn of H_right, and the right lane is
H_right followed by the half-turn of H_left, which makes the pair symmetric.
Coordinates are normalized design units (0..100) like the 1.2.8 chains.
"""
import random

A = (50.0, 90.0)
C = (50.0, 50.0)

def mirror(p):
    return (round(100.0 - p[0], 2), round(100.0 - p[1], 2))

def lanes(h_left, h_right):
    # The two halves must meet the midline at half-turn partner points.
    h_right = h_right[:-1] + [mirror(h_left[-1])]
    left = h_left + [mirror(p) for p in reversed(h_right[:-1])]
    right = h_right + [mirror(p) for p in reversed(h_left[:-1])]
    return left, right

def middle(half):
    """Spawn A up to the centre, completed by its own half-turn image."""
    return half + [mirror(p) for p in reversed(half[:-1])]

def links(*pairs):
    """Each (a, b) link is added with its half-turn image."""
    out = []
    for a, b in pairs:
        out += [[a, b], [mirror(a), mirror(b)]]
    return out

def shake(points, rng, amount):
    out = []
    for x, y in points:
        if (x, y) in (A, C):
            out.append((x, y)); continue
        out.append((round(min(92, max(8, x + rng.uniform(-amount, amount))), 2),
                    round(min(92, max(8, y + rng.uniform(-amount, amount))), 2)))
    return out

def flip_x(points):
    return [(100 - x, y) for x, y in points]

def family(kind, rng):
    j = 3.0
    if kind == 'three_lanes':
        hl = shake([A, (26, 84), (14, 68), (22, 56), (16, 50)], rng, j)
        hr = shake(flip_x([A, (26, 84), (14, 68), (22, 56), (16, 50)]), rng, j)
        hm = shake([A, (52, 76), (44, 64), C], rng, j)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hl[3], hm[2]), (hr[1], hm[1]))
    if kind == 'hub':
        hl = shake([A, (28, 82), (18, 64), (24, 50)], rng, j)
        hr = shake(flip_x([A, (28, 82), (18, 64), (24, 50)]), rng, j)
        hm = shake([A, (50, 74), C], rng, 1.5)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hl[3], C), (hr[3], C), (hl[1], hm[1]))
    if kind == 'switchback':
        hl = shake([A, (32, 86), (12, 76), (32, 64), (14, 54), (18, 50)], rng, j)
        hr = shake(flip_x([A, (30, 84), (16, 70), (30, 58), (20, 50)]), rng, j)
        hm = shake([A, (58, 78), (42, 66), (56, 58), C], rng, j)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hl[3], hm[2]), (hr[2], hm[3]))
    if kind == 'diamond':
        hl = shake([A, (24, 78), (12, 50)], rng, j)
        hr = shake(flip_x([A, (24, 78), (12, 50)]), rng, j)
        hm = shake([A, (38, 68), C], rng, j)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hl[1], hm[1]), (hl[2], hm[1]), (hr[1], hm[1]))
    if kind == 'ring':
        hl = shake([A, (22, 82), (12, 62), (18, 50)], rng, j)
        hr = shake(flip_x([A, (22, 82), (12, 62), (18, 50)]), rng, j)
        hm = shake([A, (50, 76), (36, 60), C], rng, j)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hm[2], hl[2]), (hm[1], hr[1]))
    if kind == 'ladder':
        hl = shake([A, (24, 88), (22, 72), (22, 50)], rng, 2.0)
        hr = shake(flip_x([A, (24, 88), (22, 72), (22, 50)]), rng, 2.0)
        hm = shake([A, (50, 72), C], rng, 1.5)
        l, r = lanes(hl, hr)
        return [l, middle(hm), r] + links((hl[2], hm[1]), (hr[2], hm[1]), (hl[3], C))
    raise ValueError(kind)

# One family per map, spread so neighbours in the rotation feel different.
MAP_KINDS = {0: 'hub', 1: 'three_lanes', 2: 'switchback', 3: 'ladder', 4: 'ring', 5: 'diamond',
             6: 'three_lanes', 7: 'ring', 8: 'ladder', 9: 'switchback', 10: 'hub', 11: 'diamond',
             12: 'hub', 13: 'three_lanes', 14: 'switchback', 15: 'ring', 16: 'ladder', 17: 'diamond', 18: 'hub'}

def chains(index):
    rng = random.Random(1400 + index)
    return [' '.join('%g,%g' % p for p in chain) for chain in family(MAP_KINDS[index], rng)]

def is_symmetric(index):
    """Every chain's half-turn image is also a chain (possibly reversed)."""
    raw = [[tuple(map(float, p.split(','))) for p in c.split()] for c in chains(index)]
    keys = {tuple(c) for c in raw} | {tuple(reversed(c)) for c in raw}
    return all(tuple(mirror(p) for p in c) in keys for c in raw)

# Symmetric terrain: palindromic height profiles along the attack axis (z) or
# the cross axis (x), so both teams climb or descend equally.
def terrain(index):
    rng = random.Random(900 + index)
    style = index % 4
    # A sunken lane under a central hill would sit above the surrounding
    # ground; tunnel maps use the stepped (side-high) profile instead.
    if style == 0 and routes(index)[1]:
        style = 3
    if style == 0:   # central hill
        h = rng.choice([2.8, 3.4, 4.2]); return ('z', [0, .24, .38, .62, .76, 1], [0, 0, h, h, 0, 0])
    if style == 1:   # central basin
        h = -rng.choice([2.8, 3.6, 4.2]); return ('z', [0, .26, .40, .60, .74, 1], [0, 0, h, h, 0, 0])
    if style == 2:   # high spawns stepping down to the middle
        h = rng.choice([3.2, 4.0]); return ('z', [0, .20, .34, .66, .80, 1], [h, h, 0, 0, h, h])
    h = rng.choice([2.6, 3.4]); return ('x', [0, .22, .34, .66, .78, 1], [h, h, 0, 0, h, h])

# Elevated / sunken symmetric segment of the self-symmetric middle lane.
def routes(index):
    upper = (1, .22, .78, 4.8 + (index % 3) * .6) if index % 3 != 2 else None
    lower = (1, .30, .70, -3.6) if index % 3 == 2 else None
    # A sunken middle lane cuts the ground at both ramps; in the diamond family
    # no link reaches the ground between them, leaving the central objective on
    # an unreachable island. Those maps use an elevated deck instead.
    if lower and MAP_KINDS[index] == 'diamond':
        upper, lower = (1, .22, .78, 4.8), None
    # Central basins (terrain style 1) already give the map its vertical
    # layer; a deck inside the bowl tangles its ramps with the basin slopes.
    if index % 4 == 1:
        upper = None
    return upper, lower

REGULAR = range(19)
