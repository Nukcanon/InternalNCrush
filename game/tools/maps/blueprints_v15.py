"""1.5 authored map blueprints (see build_v15.py for the legend).

Maps are drawn with a small rectangle canvas instead of hand-counted ASCII:
fill(x, y, w, h, ch) paints cells (x = column, y = row). Regular maps are the
bottom half only (row 0 touches the half-turn line); defusal maps are whole.

Design rules taken from competitive shooters (Counter-Strike, Overwatch, Team
Fortress 2):
  * three lanes from each spawn, joined by a few connectors (rotations), never
    one open field; every objective has two or three ways in;
  * long sight lines are broken by bends, blocks and cover every 20-30 m;
  * high ground (terraces, docks, catwalks) overlooks objectives but is exposed
    and reached by stairs from the side the defenders do not hold;
  * spawn rooms have several exits and no view of the objectives;
  * the playable area is closed by tall buildings: nothing outside is modelled.
"""


class Canvas:
    def __init__(self, w, h, fill=' '):
        self.w, self.h = w, h
        self.g = [[fill] * w for _ in range(h)]

    def fill(self, x, y, w, h, ch):
        for r in range(y, y + h):
            for c in range(x, x + w):
                if not (0 <= r < self.h and 0 <= c < self.w):
                    raise ValueError('fill outside canvas: %d,%d' % (c, r))
                self.g[r][c] = ch
        return self

    def put(self, x, y, ch):
        return self.fill(x, y, 1, 1, ch)

    def points(self, ch, *cells):
        for x, y in cells:
            self.put(x, y, ch)
        return self

    def rows(self):
        return [''.join(r) for r in self.g]


MAPS = {}


def spawn_room(k, x, y, ch, w=4, h=3, pave=','):
    """Spawn pad: w x h room with the 2 x 2 marker centred on its back half."""
    k.fill(x, y, w, h, pave)
    k.fill(x + w // 2 - 1, y + h - 2, 2, 2, ch)
    return k


def show(index):
    import build_v15 as B
    m = B.Map(index, MAPS[index])
    print('map', index, MAPS[index]['name'], m.w, 'x', m.h, 'problems', m.problems)
    print('    ' + ''.join(str(c % 10) for c in range(m.w)))
    for i, row in enumerate(m.g):
        print('%3d %s' % (i, ''.join(row)))


def regular(index, name, capacity, canvas, identity, styles, props=None, indoor=False, water_kind='river', hall=None):
    MAPS[index] = {'name': name, 'capacity': capacity, 'mode': 'regular', 'symmetric': True, 'rows': canvas.rows(),
                   'identity': identity, 'styles': styles, 'props': props or {}, 'indoor': indoor,
                   'water_kind': water_kind, **({'hall': hall} if hall else {})}


def defusal(index, name, capacity, canvas, identity, styles, props=None, indoor=False, water_kind='river', hall=None):
    MAPS[index] = {'name': name, 'capacity': capacity, 'mode': 'defusal', 'symmetric': False, 'rows': canvas.rows(),
                   'identity': identity, 'styles': styles, 'props': props or {}, 'indoor': indoor,
                   'water_kind': water_kind, **({'hall': hall} if hall else {})}


# --- 13 물류 창고 (logistics yard, 8 players, 26 x 26 cells) -------------------------
def logistics():
    k = Canvas(26, 13)
    # Interior blocks between the lanes (lower than the boundary buildings).
    k.fill(1, 0, 24, 9, '#')
    # Spawn: room with a paved forecourt and three exits (west, north, east).
    k.fill(11, 9, 4, 3, '.').fill(12, 10, 2, 2, 'S').fill(11, 9, 4, 1, ',')
    k.fill(3, 9, 20, 1, '.')                     # back street behind the lanes
    # West lane: a covered sorting hall with pillars and crates...
    k.fill(2, 5, 5, 4, ':').points('3', (3, 6), (5, 7)).points('1', (2, 5), (6, 8))
    # ...opening onto yard A: loading dock on the west wall, containers.
    k.fill(1, 1, 7, 4, '.').fill(4, 2, 2, 2, 'A')
    k.fill(1, 1, 2, 3, '^').put(3, 2, '/')
    k.points('o', (7, 3)).points('c', (6, 1), (3, 4)).points('b', (5, 4))
    k.fill(1, 0, 3, 1, '.').put(2, 0, 'c')      # yard A continues across the half-turn line
    # Covered door from yard A into the central yard (a choke).
    k.put(8, 2, ':')
    # Middle lane: a narrow alley north from spawn with a jog, into the central yard.
    k.fill(12, 5, 2, 4, '.').fill(11, 4, 2, 2, '.').put(12, 6, 'w')
    k.fill(9, 0, 8, 4, ',').fill(12, 0, 2, 1, 'C')
    k.points('c', (10, 1)).points('b', (15, 2)).points('w', (11, 3)).points('k', (14, 3))
    # Catwalk on the east side of the central yard (reached by stairs from the west).
    k.fill(16, 0, 1, 3, '^').put(15, 1, '/')
    # East lane: containers and a sunken truck bay.
    k.fill(20, 4, 3, 5, '.').fill(19, 0, 4, 4, '.')
    k.fill(20, 5, 3, 2, 'v').fill(20, 7, 3, 1, '/').fill(20, 4, 3, 1, '/')
    k.points('o', (19, 2), (21, 8)).points('k', (22, 1)).points('c', (20, 0))
    # East-middle connector alley.
    k.fill(14, 5, 6, 1, '.').put(17, 5, 's')
    return k


# --- 6-player maps (20 x 20 cells, 80 m) ----------------------------------------------
def oldtown():
    # Winding lanes between houses: a small market square (A), a stepped lane
    # up to a terrace overlooking the centre fountain yard (C).
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S')
    k.fill(3, 5, 5, 1, '.').fill(12, 5, 5, 1, '.')            # spawn side exits
    k.fill(3, 2, 2, 3, '.')                                    # west lane
    k.fill(3, 0, 5, 3, ',').put(5, 1, 'A')                     # market square A
    k.points('n', (3, 0), (7, 2)).points('c', (6, 0))
    k.fill(9, 3, 2, 2, '.').fill(8, 1, 2, 2, '.')              # middle lane (jogs west)
    k.fill(8, 0, 4, 1, ',').fill(9, 0, 2, 1, 'C').put(11, 0, 'w')
    k.fill(12, 1, 1, 3, ':')                                   # covered passage east of the middle
    k.fill(15, 0, 2, 5, '.').points('c', (16, 2)).points('b', (15, 4))   # east lane
    k.fill(13, 1, 2, 2, '^').fill(13, 3, 2, 1, '/')            # terrace from the east exit
    k.put(12, 4, '.').fill(13, 4, 2, 1, '.')
    return k


def hillside():
    # Terraced village: every lane climbs; the centre (C) sits on the middle
    # terrace, A in a lower courtyard reached by stairs.
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S')
    k.fill(4, 5, 4, 1, '.').fill(12, 5, 4, 1, '.')
    k.fill(4, 1, 2, 4, '.').fill(3, 1, 4, 3, ',').put(4, 2, 'A').points('t', (6, 1)).points('w', (3, 3))
    k.fill(3, 0, 2, 1, '.')
    k.fill(9, 2, 2, 3, '.').put(9, 3, 'r')                      # middle lane
    k.fill(7, 0, 6, 2, '^').fill(9, 0, 2, 1, 'C')             # upper terrace with the centre point
    k.fill(9, 2, 2, 1, '/')                                    # stairs up from the middle lane
    k.fill(14, 1, 2, 4, '.').fill(13, 0, 3, 1, '.').points('s', (15, 2))   # east lane
    k.fill(12, 1, 1, 1, '/')                                   # side stairs onto the terrace
    k.put(13, 1, '.')
    return k


def orchard():
    # Orchard rows (trees give soft cover), a barn (covered) and a farmyard (C).
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S', pave='.')
    k.fill(3, 5, 14, 1, '.')
    k.fill(3, 0, 5, 5, '.')                                    # west orchard block
    k.points('t', (3, 1), (5, 1), (7, 1), (4, 3), (6, 3)).put(5, 2, 'A').points('n', (7, 4))
    k.fill(9, 3, 2, 2, ':').put(9, 3, '6')                      # barn passage on the middle lane
    k.fill(9, 2, 2, 1, '.')
    k.fill(8, 0, 4, 2, '.').fill(9, 0, 2, 1, 'C').points('n', (8, 1)).points('c', (11, 1))
    k.fill(13, 0, 4, 5, '.').points('t', (14, 1), (16, 1), (14, 3), (16, 3)).points('k', (13, 4))
    k.fill(12, 2, 1, 1, '.')
    return k


def fountain():
    # Arcaded square: the centre fountain is water; players fight round it under
    # the arcades. A in a side courtyard with a raised loggia.
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S')
    k.fill(3, 5, 13, 1, '.')
    k.fill(4, 1, 3, 4, ',').put(5, 2, 'A').points('n', (4, 1)).points('t', (6, 4))
    k.fill(3, 1, 1, 3, '^').put(3, 4, '/')                     # loggia along the west wall
    k.fill(4, 0, 2, 1, '.')
    k.fill(7, 1, 1, 3, ':')                                    # arcade west of the square
    k.fill(8, 0, 4, 4, ',').fill(9, 0, 2, 1, 'C')              # the square (C); planters around it
    k.points('w', (8, 1), (11, 2)).points('n', (8, 3)).points('f', (10, 3))
    k.fill(12, 1, 1, 3, ':')                                   # east arcade
    k.fill(13, 1, 3, 4, '.').points('c', (15, 2)).points('t', (14, 4))
    k.fill(14, 0, 2, 1, '.')
    k.fill(9, 4, 2, 1, '.')
    return k


def garage():
    # Indoor service hall: inspection pits (sunken) under the lifts, parked cars,
    # a parts store (covered) and a glazed office block on the east side.
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S', pave='.')
    k.fill(3, 5, 14, 1, '.')
    k.fill(3, 0, 5, 5, '.')                                    # west service bays
    k.fill(4, 1, 1, 3, 'v').put(4, 4, '/').fill(6, 1, 1, 2, 'v').put(6, 3, '/')
    k.put(5, 2, 'A').points('k', (3, 1), (7, 4)).points('c', (7, 0))
    k.fill(9, 2, 2, 3, ':').points('1', (9, 2)).points('6', (10, 4))   # parts store on the middle lane
    k.fill(8, 0, 4, 2, '.').fill(9, 0, 2, 1, 'C').points('b', (8, 1)).points('c', (11, 1))
    k.fill(13, 1, 3, 3, ':').points('5', (13, 1), (15, 3)).points('2', (14, 2))    # offices
    k.fill(16, 0, 1, 5, '.').fill(12, 0, 4, 1, '.').put(12, 4, '.').put(12, 3, '.')
    return k


def power():
    # Turbine hall: three turbines on the centre line, a catwalk along the west
    # wall over the pump room, control rooms east.
    k = Canvas(20, 10)
    k.fill(2, 0, 16, 8, '#')
    spawn_room(k, 8, 5, 'S', pave='.')
    k.fill(3, 5, 14, 1, '.')
    k.fill(3, 0, 5, 5, '.').fill(3, 0, 1, 4, '^').put(3, 4, '/')    # catwalk on the west wall
    k.put(5, 2, 'A').points('4', (6, 0)).points('c', (6, 4)).points('b', (5, 3))
    k.fill(8, 0, 4, 4, '.').fill(9, 0, 2, 1, 'C').points('4', (8, 2), (11, 2)).points('s', (9, 3))
    k.fill(13, 1, 3, 3, ':').points('4', (13, 2)).points('5', (15, 1))   # control room
    k.fill(16, 0, 1, 5, '.').fill(12, 0, 4, 1, '.').put(12, 2, ':')
    return k


def labcomplex():
    # Test chambers joined by corridors, a decontamination hall and a central
    # observation room over the main chamber (C).
    k = Canvas(26, 13)
    k.fill(2, 0, 22, 11, '#')
    spawn_room(k, 11, 8, 'S', pave='.')
    k.fill(3, 8, 20, 1, '.')                                   # service corridor
    k.fill(3, 3, 2, 5, '.')                                    # west corridor
    k.fill(5, 1, 5, 5, ',').put(7, 3, 'A').points('4', (5, 1), (9, 5)).points('b', (8, 2))   # chamber A
    k.fill(5, 6, 3, 2, ':').points('5', (5, 6)).points('1', (7, 7))                     # lab
    k.fill(3, 0, 2, 3, '.')
    k.fill(12, 4, 2, 4, '.')                                   # middle corridor
    k.fill(10, 0, 6, 4, ',').fill(12, 0, 2, 1, 'C').points('4', (10, 0), (15, 3)).points('w', (12, 3))
    k.fill(16, 0, 2, 2, '^').put(15, 1, '/')                   # observation deck
    k.fill(18, 2, 5, 3, ':').points('5', (19, 3)).points('2', (21, 2))   # decon hall
    k.fill(21, 5, 2, 3, '.').fill(19, 0, 4, 2, '.').points('c', (22, 0))
    k.fill(16, 4, 5, 1, '.')
    return k


def derelict():
    # Abandoned factory: collapsed floor (sunken) through the centre, rubble,
    # dead machinery, a broken loading office.
    k = Canvas(26, 13)
    k.fill(2, 0, 22, 11, '#')
    spawn_room(k, 11, 8, 'S', pave='.')
    k.fill(3, 8, 20, 1, '.')
    k.fill(3, 1, 6, 7, '.').put(5, 3, 'A').points('r', (3, 1), (7, 6)).points('4', (6, 1), (8, 4)).points('c', (3, 5))
    k.fill(4, 0, 3, 1, '.')
    k.fill(10, 2, 6, 2, 'v').fill(14, 1, 2, 1, '/')            # collapsed floor
    k.fill(10, 0, 6, 2, '.').fill(12, 0, 2, 1, 'C').points('r', (10, 0), (15, 0)).fill(14, 1, 2, 1, '/')
    k.fill(12, 4, 2, 4, '.').put(12, 5, 'r').fill(12, 4, 2, 1, '/')
    k.put(15, 3, 'r').put(10, 3, 'r')
    k.fill(17, 3, 5, 4, ':').points('6', (17, 3), (21, 6)).points('4', (19, 5))   # loading office
    k.fill(17, 0, 5, 3, '.').points('k', (20, 1)).points('r', (17, 0))
    k.fill(21, 7, 2, 1, '.').fill(16, 4, 1, 1, '.')
    return k


def highrise():
    # Office floor: open-plan desks (low partitions), meeting rooms, an atrium
    # with a mezzanine bridge over the centre (C).
    k = Canvas(26, 13)
    k.fill(2, 0, 22, 11, '#')
    spawn_room(k, 11, 8, 'S', pave='.')
    k.fill(3, 8, 20, 1, '.')
    k.fill(3, 2, 7, 6, '.').put(6, 4, 'A').points('2', (4, 3), (8, 3), (4, 6), (8, 6)).points('5', (6, 2))
    k.fill(3, 2, 2, 2, ':').points('5', (3, 2))                  # meeting room corner
    k.fill(4, 0, 3, 2, '.')
    k.fill(11, 4, 4, 4, '.').points('w', (11, 5), (14, 6)).points('p', (12, 7))
    k.fill(10, 0, 6, 4, ',').fill(12, 0, 2, 1, 'C').points('n', (10, 2), (15, 1))
    k.fill(10, 0, 1, 2, '^').put(10, 2, '/')                   # atrium mezzanine (west side)
    k.fill(17, 1, 5, 3, ':').points('5', (18, 2), (21, 1)).points('2', (20, 3))   # boardroom
    k.fill(17, 4, 5, 4, '.').points('2', (18, 5), (21, 6)).fill(16, 1, 1, 2, '.')
    k.fill(19, 0, 3, 1, '.')
    return k


def market():
    # Covered market: stall rows under arcades, a fish hall, a crowded square (C).
    k = Canvas(26, 13)
    k.fill(2, 0, 22, 11, '#')
    spawn_room(k, 11, 8, 'S')
    k.fill(3, 8, 20, 1, '.')
    k.fill(3, 2, 2, 6, '.').fill(3, 1, 7, 2, ',').put(6, 1, 'A').points('n', (3, 1), (9, 2)).points('c', (8, 1))
    k.fill(6, 3, 4, 4, ':').points('5', (6, 4), (9, 5), (7, 6))   # covered stall hall
    k.fill(3, 0, 3, 1, '.')
    k.fill(12, 4, 2, 4, '.').points('n', (12, 5)).fill(11, 3, 2, 1, '.')
    k.fill(10, 0, 6, 3, ',').fill(12, 0, 2, 1, 'C').points('n', (10, 1), (15, 2)).points('c', (14, 2))
    k.fill(16, 1, 2, 5, ':').points('5', (16, 2), (17, 4))     # fish hall
    k.fill(18, 0, 4, 8, '.').points('n', (19, 1), (21, 3), (18, 6)).points('k', (21, 6))
    k.fill(14, 4, 2, 1, '.')
    return k


def quarry():
    # Open pit quarry: the centre (C) is on the pit floor, benches (terraces)
    # step down to it; conveyors and rock piles break the sight lines.
    k = Canvas(26, 13)
    k.fill(2, 0, 22, 11, '#')
    spawn_room(k, 11, 8, 'S', pave='.')
    k.fill(3, 8, 20, 1, '.')
    k.fill(3, 1, 7, 7, '.').put(5, 4, 'A').points('r', (3, 1), (8, 3), (4, 6)).points('4', (7, 6)).points('k', (9, 1))
    k.fill(3, 0, 3, 1, '.')
    k.fill(10, 0, 6, 3, 'v').fill(12, 0, 2, 1, 'C').points('r', (10, 0), (15, 2))   # pit floor
    k.fill(12, 3, 2, 1, '/').fill(12, 4, 2, 4, '.').put(12, 6, 'r')
    k.fill(16, 1, 1, 1, '/').fill(17, 0, 5, 8, '.').fill(17, 2, 3, 3, '^').put(18, 5, '/')   # bench (terrace)
    k.points('r', (21, 1), (20, 6)).points('c', (17, 7)).points('4', (21, 4))
    k.fill(10, 3, 1, 1, '/').fill(10, 4, 2, 1, '.')
    return k


# --- 32-player maps (44 x 44 cells, 176 m) ---------------------------------------------
def harbour():
    # Harbour: a basin with a pier on the west (A on the quay plaza beyond it),
    # customs warehouses, a monument square in the centre (C) and a container
    # terminal with a crane rail on the east.
    k = Canvas(44, 22)
    k.fill(2, 0, 40, 20, '#')
    spawn_room(k, 19, 17, 'S', w=6, h=3)
    k.fill(3, 16, 38, 1, '.')                                                 # quay road
    k.fill(3, 6, 6, 8, '~').fill(3, 14, 8, 2, '.')                             # basin
    k.fill(5, 9, 2, 5, '.').points('c', (5, 9))                                # short pier
    k.fill(9, 4, 3, 12, '.').points('c', (10, 7), (9, 12)).points('b', (11, 14))   # quay walk
    k.fill(3, 3, 9, 3, ',').fill(5, 3, 2, 2, 'A').points('o', (9, 3), (3, 5)).points('c', (7, 5))
    k.fill(3, 0, 5, 3, '.').points('b', (4, 1))
    k.fill(13, 8, 5, 5, ':').points('1', (14, 9), (16, 11)).points('6', (13, 12))  # customs hall
    k.fill(12, 10, 1, 1, '.').fill(18, 10, 2, 1, '.')
    k.fill(20, 6, 4, 10, '.').points('k', (20, 8)).points('b', (23, 12)).points('w', (21, 14))   # main street
    k.fill(16, 0, 12, 5, ',').fill(21, 0, 2, 1, 'C').points('f', (18, 2)).points('c', (26, 1), (16, 4)).points('w', (24, 3))
    k.fill(20, 5, 4, 1, '.').fill(12, 2, 4, 1, '.').fill(28, 1, 3, 1, '.')    # square entrances
    k.fill(29, 3, 11, 13, '.').fill(39, 3, 1, 11, '^').put(39, 14, '/')        # container terminal + crane rail
    k.points('o', (31, 4), (31, 5), (34, 7), (34, 8), (31, 11), (36, 12), (37, 4)).points('k', (33, 14)).points('c', (29, 9))
    k.fill(31, 0, 6, 3, '.').points('c', (33, 1))
    k.fill(24, 8, 5, 1, '.')
    return k


def shipyard():
    # Shipyard: a dry dock in the centre (C on the dock floor), fabrication halls
    # and the plate yard west (A), a slipway with a gantry east.
    k = Canvas(44, 22)
    k.fill(2, 0, 40, 20, '#')
    spawn_room(k, 19, 17, 'S', w=6, h=3, pave='.')
    k.fill(3, 16, 38, 1, '.')
    k.fill(15, 0, 14, 6, 'v').fill(21, 0, 2, 1, 'C').points('o', (17, 1), (26, 3)).points('r', (19, 4), (24, 1))   # dry dock
    k.fill(13, 6, 18, 4, '.').fill(17, 6, 2, 1, '/').fill(25, 6, 2, 1, '/')  # dock apron and stairs down
    k.points('c', (13, 8), (30, 7)).points('b', (22, 8))
    k.fill(3, 4, 8, 5, ':').points('4', (4, 5), (8, 7)).points('6', (6, 4), (10, 6))   # fabrication hall
    k.fill(3, 9, 8, 7, '.').fill(5, 11, 2, 2, 'A').points('o', (8, 10), (3, 13), (9, 14)).points('c', (4, 9))   # plate yard
    k.fill(3, 0, 5, 4, '.').points('c', (5, 1))
    k.fill(11, 5, 2, 1, '.').fill(11, 6, 2, 3, '.')
    k.fill(20, 10, 4, 6, '.').points('w', (20, 12)).points('b', (23, 14))
    k.fill(32, 2, 8, 13, '.').fill(35, 4, 2, 9, '^').fill(35, 13, 2, 1, '/').fill(35, 3, 2, 1, '/')   # slipway + gantry
    k.points('o', (33, 5), (38, 9), (33, 11)).points('c', (38, 3), (32, 14)).points('k', (38, 13))
    k.fill(33, 0, 5, 2, '.')
    k.fill(11, 12, 9, 1, '.').fill(24, 11, 8, 1, '.').fill(31, 7, 1, 1, '.')
    return k


def canal():
    # Canal quarter: a canal crosses each half, spanned by three bridges; the
    # centre piazza (C) between the canals, a market square (A) on the west
    # bank, warehouses on the east bank.
    k = Canvas(44, 22)
    k.fill(2, 0, 40, 20, '#')
    spawn_room(k, 19, 17, 'S', w=6, h=3)
    k.fill(3, 16, 38, 1, '.')
    k.fill(3, 7, 38, 2, '~')                                                  # canal
    k.fill(6, 7, 2, 2, '.').fill(21, 7, 2, 2, '.').fill(35, 7, 2, 2, '.')     # bridges
    k.fill(3, 9, 38, 1, '.')                                                  # south quay
    k.fill(5, 10, 4, 6, '.').fill(20, 10, 4, 6, '.').fill(34, 10, 4, 6, '.')  # lanes from the quay road
    k.points('c', (5, 12), (37, 13)).points('w', (22, 12)).points('t', (8, 14), (34, 14))
    k.fill(11, 11, 6, 4, ':').points('5', (12, 12), (15, 13))                 # arcade (south-west)
    k.fill(9, 12, 2, 1, '.').fill(17, 12, 3, 1, '.')
    k.fill(26, 11, 6, 4, ':').points('1', (27, 12), (30, 13))                 # warehouse (south-east)
    k.fill(24, 12, 2, 1, '.').fill(32, 12, 2, 1, '.')
    k.fill(3, 2, 9, 5, ',').fill(6, 3, 2, 2, 'A').points('n', (3, 2), (10, 5)).points('f', (9, 3)).points('c', (4, 6))   # market square
    k.fill(3, 0, 4, 2, '.')
    k.fill(14, 0, 16, 6, ',').fill(21, 0, 2, 1, 'C').points('t', (15, 1), (28, 4)).points('n', (18, 4), (26, 2)).points('w', (22, 3))   # piazza
    k.fill(12, 4, 2, 1, '.').fill(20, 6, 4, 1, '.')
    k.fill(32, 1, 8, 6, '.').points('o', (33, 2), (38, 4)).points('k', (35, 5)).points('c', (39, 1))
    k.fill(30, 3, 2, 1, '.').fill(34, 0, 4, 1, '.')
    return k


# --- 16-player maps (34 x 34 cells, 136 m) ---------------------------------------------
def steelmill():
    # Indoor mill (hall 9.6 m): casting floor with a wall catwalk (A), rolling
    # line through the centre with gantry platforms (C), furnace bay east.
    k = Canvas(34, 17)
    k.fill(2, 0, 30, 15, '#')
    spawn_room(k, 14, 12, 'S', w=6, h=3, pave='.')
    k.fill(3, 11, 28, 1, '.')
    k.fill(3, 3, 7, 8, '.').fill(3, 3, 1, 6, '^').put(3, 9, '/')             # casting floor + catwalk
    k.fill(5, 5, 2, 2, 'A').points('o', (8, 4), (4, 10)).points('b', (7, 8)).points('c', (9, 6)).points('k', (6, 3))
    k.fill(3, 0, 4, 3, '.').points('c', (5, 1))
    k.fill(15, 4, 4, 7, '.').points('w', (15, 6), (18, 8)).points('b', (16, 10))    # rolling line approach
    k.fill(12, 0, 10, 4, ',').fill(16, 0, 2, 1, 'C').points('w', (14, 2), (19, 1)).points('o', (21, 3))
    k.fill(12, 0, 2, 2, '^').put(12, 2, '/')                                  # gantry platform
    k.fill(24, 2, 7, 9, '.').points('o', (26, 4), (28, 8)).points('c', (24, 6), (30, 10)).points('s', (27, 2))
    k.fill(28, 2, 3, 3, ':').points('4', (29, 3))                              # furnace control room
    k.fill(25, 0, 4, 2, '.')
    k.fill(10, 7, 5, 1, '.').fill(19, 5, 5, 1, '.').put(21, 5, 'b')           # connectors
    return k


def institute():
    # Research institute: glass atrium with planters (C), lab wing west with
    # the cleanroom hall (A), offices and archive east.
    k = Canvas(34, 17)
    k.fill(2, 0, 30, 15, '#')
    spawn_room(k, 14, 12, 'S', w=6, h=3, pave='.')
    k.fill(3, 11, 28, 1, '.')
    k.fill(3, 2, 2, 9, '.')                                                   # west corridor
    k.fill(5, 3, 6, 4, '.').fill(7, 4, 2, 2, 'A').points('b', (5, 3), (10, 6)).points('n', (10, 3)).points('c', (6, 6))
    k.fill(5, 8, 5, 2, ':').points('5', (6, 8), (8, 9))                       # lab
    k.fill(3, 0, 3, 2, '.').points('c', (5, 0))
    k.fill(16, 5, 2, 6, '.').put(16, 7, 'w')                                  # middle corridor
    k.fill(12, 0, 10, 5, ',').fill(16, 0, 2, 1, 'C').points('t', (13, 1), (20, 3)).points('n', (15, 3), (19, 1)).points('w', (12, 4))
    k.fill(24, 3, 5, 3, ':').points('5', (25, 4), (27, 3))                    # offices
    k.fill(23, 7, 5, 3, ':').points('2', (24, 8), (26, 7))                    # archive
    k.fill(29, 1, 2, 10, '.').fill(24, 0, 6, 2, '.').points('c', (30, 5), (25, 1))
    k.fill(11, 8, 5, 1, '.').fill(22, 6, 7, 1, '.').put(28, 6, 'b')
    return k


def desert():
    # Desert outpost: motor pool (A) with vehicles and containers, radar hill in
    # the centre (C, raised), barracks and sandbagged bunkers east.
    k = Canvas(34, 17)
    k.fill(2, 0, 30, 15, '#')
    spawn_room(k, 14, 12, 'S', w=6, h=3, pave='.')
    k.fill(3, 11, 28, 1, '.')
    k.fill(3, 2, 8, 8, '.').fill(6, 5, 2, 2, 'A').points('k', (4, 3), (9, 8)).points('o', (10, 4), (3, 8)).points('s', (7, 3), (5, 8))
    k.fill(3, 2, 3, 2, ':').points('6', (3, 2))                               # motor pool shed
    k.fill(4, 0, 4, 2, '.').points('b', (5, 1))
    k.fill(15, 5, 4, 6, '.').points('s', (15, 7), (18, 9))
    k.fill(12, 0, 10, 5, '.').fill(14, 0, 6, 2, '^').fill(16, 0, 2, 1, 'C').points('s', (14, 0), (19, 1))
    k.put(15, 2, '/').put(18, 2, '/').points('b', (12, 3), (21, 4)).points('k', (13, 4))
    k.fill(24, 2, 7, 9, '.').points('s', (24, 4), (29, 9), (26, 7)).points('o', (30, 2)).points('b', (27, 10))
    k.fill(25, 3, 2, 2, ':').fill(28, 6, 2, 2, ':').points('1', (25, 3))      # bunkers
    k.fill(25, 0, 4, 2, '.')
    k.fill(11, 7, 4, 1, '.').fill(19, 4, 5, 1, '.')
    return k


def station():
    # Central station: forecourt, a pillared concourse (covered) under the
    # platforms, raised platforms with sunken tracks, a freight yard east.
    k = Canvas(34, 17)
    k.fill(2, 0, 30, 15, '#')
    spawn_room(k, 14, 12, 'S', w=6, h=3)
    k.fill(3, 11, 28, 1, ',')                                                 # forecourt
    k.fill(5, 7, 24, 3, ':').points('3', (8, 8), (12, 8), (21, 8), (25, 8)).points('5', (6, 9), (27, 9))   # concourse
    k.fill(5, 10, 2, 1, '.').fill(27, 10, 2, 1, '.').fill(16, 10, 2, 1, '.')
    k.fill(5, 1, 3, 5, '^').put(6, 6, '/').fill(6, 3, 2, 2, 'A').points('n', (5, 1))     # west platform (A)
    k.fill(8, 0, 2, 7, 'v').put(8, 0, '/').put(9, 6, '/')                    # west track trench
    k.fill(3, 0, 2, 7, '.').points('c', (3, 2))
    k.fill(12, 0, 10, 5, ',').fill(16, 0, 2, 1, 'C').points('n', (13, 1), (20, 2)).points('t', (12, 4), (21, 4)).points('w', (16, 3))
    k.fill(16, 5, 2, 2, '.')
    k.fill(24, 1, 6, 6, '.').points('o', (25, 2), (29, 5)).points('k', (27, 4)).points('c', (24, 6))    # freight yard
    k.fill(25, 0, 3, 1, '.')
    k.fill(10, 3, 2, 1, '.').fill(22, 2, 2, 1, '.')
    return k


# --- Defusal maps (attack T bottom, defend D top; sites A west, B east) -----------------
def defend_spawn(k, x, y, w=6, h=3, pave=','):
    """Defender pad: marker on the top (back) rows of the room."""
    k.fill(x, y, w, h, pave)
    k.fill(x + w // 2 - 1, y, 2, 2, 'D')
    return k


def fortress():
    # Castle: the keep courtyard (A) under a rampart, the chapel yard (B), an
    # outer bailey (A long), a gatehouse in the split middle, a vault tunnel (B).
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2)
    spawn_room(k, 11, 26, 'T')
    k.fill(3, 25, 20, 1, '.')                                                  # lower street
    k.fill(3, 5, 7, 6, ',').fill(5, 7, 2, 2, 'A').fill(3, 5, 1, 5, '^').put(3, 10, '/')   # keep courtyard + rampart
    k.points('c', (8, 6), (5, 10)).points('w', (7, 9)).points('r', (9, 5))
    k.fill(3, 11, 3, 14, '.').points('r', (4, 14), (3, 20)).points('c', (5, 18)).points('b', (4, 23))   # outer bailey (A long)
    k.fill(10, 12, 5, 12, '.').fill(12, 17, 2, 3, '#').fill(11, 15, 4, 2, ':')  # split middle with a gatehouse
    k.points('c', (10, 13), (14, 21)).points('w', (11, 22))
    k.fill(9, 9, 2, 4, '.').put(10, 10, 'c')                                   # A short
    k.fill(14, 5, 2, 7, '.').put(14, 8, 'w')                                   # defender middle
    k.fill(16, 5, 7, 6, ',').fill(19, 7, 2, 2, 'B').points('w', (17, 6), (21, 9)).points('c', (22, 5), (16, 10))   # chapel yard
    k.fill(19, 11, 3, 2, '.').fill(19, 13, 3, 10, ':').points('1', (19, 15), (21, 19))   # vault tunnel (B)
    k.fill(19, 23, 3, 2, '.').fill(15, 12, 4, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')                             # defender exits
    return k


def nuclear():
    # Nuclear plant: reactor hall A (raised containment ring), cooling pond yard
    # B with the pond (water), turbine corridor as the middle, service tunnel.
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2)
    spawn_room(k, 11, 26, 'T', pave='.')
    k.fill(3, 25, 20, 1, '.')
    k.fill(3, 5, 8, 7, '.').fill(5, 7, 3, 3, '^').fill(6, 8, 1, 1, 'A').put(6, 10, '/').put(8, 8, '/')   # reactor hall
    k.points('4', (3, 5), (10, 6)).points('b', (4, 11), (9, 10))
    k.fill(3, 12, 2, 13, '.').fill(3, 16, 2, 4, ':').points('c', (3, 13), (4, 21))   # west service way
    k.fill(11, 13, 4, 11, ':').fill(12, 17, 2, 2, '#').points('4', (11, 14), (14, 22)).points('2', (14, 14))   # turbine corridor
    k.fill(11, 12, 4, 1, '.').fill(9, 12, 2, 1, '.')
    k.fill(13, 5, 2, 7, '.').put(13, 9, 'b')
    k.fill(16, 5, 7, 7, '.').fill(19, 8, 2, 2, 'B').fill(21, 5, 2, 3, '~').points('o', (16, 6), (22, 10)).points('b', (18, 11))   # pond yard
    k.fill(17, 12, 2, 12, '.').fill(20, 14, 3, 8, ':').points('c', (17, 16), (18, 22)).points('6', (21, 15))   # east lane + tunnel
    k.fill(19, 13, 1, 1, '.').fill(20, 22, 2, 3, '.').fill(15, 13, 2, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')
    return k


def aqueduct():
    # Aqueduct: the viaduct deck (raised) carries A, the river channel (water)
    # below with a ford bridge, arcades in the middle, the mill yard (B).
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2)
    spawn_room(k, 11, 26, 'T')
    k.fill(3, 25, 20, 1, '.')
    k.fill(3, 5, 8, 2, '^').fill(5, 5, 2, 2, 'A').put(10, 7, '/').put(3, 7, '/')    # viaduct deck (A)
    k.fill(3, 8, 8, 3, '.').points('c', (4, 9), (9, 10)).points('t', (7, 8))
    k.fill(3, 11, 21, 2, '~').fill(6, 11, 2, 2, '.').fill(13, 11, 2, 2, '.').fill(20, 11, 2, 2, '.')   # river, three crossings
    k.fill(3, 13, 3, 12, '.').points('r', (4, 16), (3, 21)).points('c', (5, 24))
    k.fill(10, 13, 6, 11, '.').fill(11, 16, 4, 4, ':').points('5', (12, 17)).points('w', (10, 21), (15, 14))   # arcades
    k.fill(13, 5, 2, 6, '.').put(14, 7, 'w')
    k.fill(16, 5, 7, 6, ',').fill(19, 7, 2, 2, 'B').points('f', (17, 6)).points('c', (22, 9), (16, 9)).points('n', (21, 5))   # mill yard (B)
    k.fill(19, 13, 4, 12, '.').fill(20, 16, 3, 5, ':').points('6', (21, 17)).points('b', (19, 22))
    k.fill(6, 13, 4, 1, '.').fill(16, 14, 3, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')
    return k


def library():
    # Indoor library (hall 9.6 m): reading room A under a gallery, stacks
    # (shelves as walls) in the middle, the rare-books vault B, cloister corridor.
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2, pave='.')
    spawn_room(k, 11, 26, 'T', pave='.')
    k.fill(3, 25, 20, 1, '.')
    k.fill(3, 5, 8, 7, '.').fill(5, 7, 2, 2, 'A').fill(3, 5, 8, 1, '^').put(10, 6, '/')   # reading room + gallery
    k.points('n', (4, 8), (8, 10)).points('w', (7, 7), (3, 11))
    k.fill(3, 12, 2, 13, '.').fill(3, 15, 2, 5, ':').points('c', (4, 13), (3, 22))   # cloister
    k.fill(10, 12, 6, 12, '.').points('w', (11, 13), (13, 15), (11, 17), (14, 19), (11, 21), (13, 23))   # stacks
    k.fill(12, 5, 2, 7, '.').put(12, 8, 'n')
    k.fill(16, 5, 7, 7, ':').fill(19, 7, 2, 2, 'B').points('2', (16, 6), (22, 10)).points('1', (21, 6), (17, 10))   # rare-books vault
    k.fill(17, 12, 3, 13, '.').points('c', (18, 15), (17, 21)).points('b', (19, 18))
    k.fill(14, 5, 2, 1, '.').fill(15, 13, 2, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')
    return k


def wreckyard():
    # Ship-breaking yard: a beached hull (raised deck, A), scrap piles, the
    # flooded slip (water) and the torch shed (B).
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2, pave='.')
    spawn_room(k, 11, 26, 'T', pave='.')
    k.fill(3, 25, 20, 1, '.')
    k.fill(3, 5, 8, 7, '.').fill(4, 6, 5, 3, '^').fill(5, 7, 2, 1, 'A').put(6, 9, '/').put(9, 7, '/')   # hull deck (A)
    k.points('r', (3, 10), (10, 5)).points('o', (9, 10))
    k.fill(3, 12, 3, 13, '.').points('r', (3, 14), (5, 17), (4, 22)).points('k', (3, 19))
    k.fill(9, 13, 7, 11, '.').fill(11, 16, 3, 4, '~').points('r', (9, 14), (15, 21)).points('o', (15, 14)).points('c', (10, 22))   # flooded slip
    k.fill(12, 5, 2, 8, '.').put(13, 9, 'r')
    k.fill(16, 5, 7, 7, ':').fill(19, 7, 2, 2, 'B').points('4', (16, 6), (22, 10)).points('6', (21, 6))   # torch shed
    k.fill(18, 12, 4, 13, '.').points('r', (19, 14), (21, 18)).points('o', (18, 21))
    k.fill(6, 13, 3, 1, '.').fill(16, 17, 2, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')
    return k


def monastery():
    # Hill monastery: the cloister garth (A), a terrace garden stepping down
    # the middle, the chapel (B, covered), the old cellar passage (sunken).
    k = Canvas(26, 32)
    k.fill(2, 2, 22, 28, '#')
    defend_spawn(k, 10, 2)
    spawn_room(k, 11, 26, 'T')
    k.fill(3, 25, 20, 1, '.')
    k.fill(3, 5, 8, 7, ',').fill(5, 7, 2, 2, 'A').fill(3, 5, 8, 1, ':').fill(3, 6, 1, 6, ':')   # cloister around the garth
    k.points('t', (8, 8)).points('f', (6, 10)).points('w', (9, 6))
    k.fill(3, 12, 3, 13, '.').points('t', (4, 15), (3, 21)).points('c', (5, 18))
    k.fill(10, 12, 6, 12, '.').fill(10, 15, 6, 3, '^').fill(12, 18, 2, 1, '/').fill(12, 14, 2, 1, '/')   # terrace garden
    k.points('t', (10, 20), (15, 22)).points('w', (11, 16))
    k.fill(13, 5, 2, 7, '.').put(13, 8, 'n')
    k.fill(16, 5, 7, 7, ':').fill(19, 7, 2, 2, 'B').points('5', (17, 6), (21, 10)).points('3', (17, 9), (21, 6))   # chapel
    k.fill(18, 12, 4, 2, '.').fill(18, 14, 4, 8, 'v').fill(18, 22, 4, 1, '/').fill(18, 13, 4, 1, '/')   # cellar passage
    k.fill(18, 23, 4, 2, '.').points('r', (19, 17))
    k.fill(6, 13, 4, 1, '.').fill(16, 12, 2, 1, '.')
    k.fill(8, 3, 2, 2, '.').fill(16, 3, 2, 2, '.')
    return k


def furnace():
    # Blast furnace works: casting platform (raised, A), the charging hall
    # (covered middle), slag pits (sunken) around the slag yard (B), an ore
    # conveyor gallery west and the cooling tunnel east.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2, pave='.')
    spawn_room(k, 14, 34, 'T', pave='.')
    k.fill(3, 33, 26, 1, '.')
    k.fill(3, 6, 9, 8, '.').fill(4, 7, 5, 4, '^').fill(5, 8, 2, 2, 'A').put(6, 11, '/').put(9, 8, '/')   # casting floor
    k.points('4', (10, 6), (3, 12)).points('c', (11, 11)).points('b', (4, 13))
    k.fill(3, 14, 3, 19, '.').fill(3, 18, 3, 6, ':').points('1', (4, 19), (3, 22)).points('c', (4, 27), (5, 15))   # ore gallery
    k.fill(12, 16, 8, 12, ':').points('4', (13, 18), (18, 21), (14, 25)).points('2', (16, 17), (13, 22), (18, 26))   # charging hall
    k.fill(14, 28, 4, 5, '.').fill(12, 14, 8, 2, '.').points('w', (15, 30))
    k.fill(15, 5, 2, 9, '.').put(16, 9, 'b')
    k.fill(20, 6, 9, 8, '.').fill(20, 6, 3, 3, 'v').fill(26, 10, 3, 3, 'v').put(21, 9, '/').put(27, 9, '/')   # slag yard
    k.fill(23, 9, 2, 2, 'B').points('o', (25, 6), (20, 12)).points('c', (28, 7))
    k.fill(25, 14, 3, 19, '.').fill(25, 17, 3, 9, ':').points('6', (26, 18), (25, 23)).points('c', (27, 29))   # cooling tunnel
    k.fill(6, 14, 6, 1, '.').fill(20, 15, 5, 1, '.').fill(20, 27, 5, 1, '.').fill(6, 26, 6, 1, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


def greenhouse():
    # Botanical glasshouses: palm house (covered, A), the reservoir garden
    # (water and paths) in the middle, the orchid house (B), potting yards.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2)
    spawn_room(k, 14, 34, 'T')
    k.fill(3, 33, 26, 1, ',')
    k.fill(3, 6, 9, 8, ':').fill(6, 8, 2, 2, 'A').points('5', (4, 7), (10, 12), (9, 7)).points('2', (4, 11))   # palm house
    k.fill(3, 14, 3, 19, '.').points('t', (4, 16), (3, 22), (5, 28)).points('n', (4, 19)).points('c', (3, 25))
    k.fill(10, 15, 12, 13, ',').fill(13, 18, 6, 6, '~').fill(15, 18, 2, 6, ',')   # reservoir garden, causeway
    k.points('t', (10, 16), (21, 17), (11, 26), (20, 25)).points('n', (12, 21), (19, 20)).points('w', (15, 24))
    k.fill(14, 28, 4, 5, ',').fill(15, 5, 2, 10, '.').put(15, 10, 'n')
    k.fill(20, 6, 9, 8, ':').fill(23, 8, 2, 2, 'B').points('5', (21, 7), (27, 11)).points('2', (26, 7), (21, 12))   # orchid house
    k.fill(25, 14, 3, 19, '.').points('t', (26, 17), (25, 24)).points('c', (27, 20), (26, 29)).points('n', (27, 26))
    k.fill(6, 21, 4, 1, '.').fill(22, 19, 3, 1, '.').fill(12, 14, 2, 1, '.').fill(18, 14, 2, 1, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


def vault():
    # Underground bank (indoor): the vault room (B, covered with strongboxes),
    # the security office and cells (A), the banking hall with pillars in the
    # middle, a sunken loading bay on the west.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2, pave='.')
    spawn_room(k, 14, 34, 'T', pave='.')
    k.fill(3, 33, 26, 1, '.')
    k.fill(3, 6, 9, 8, '.').fill(5, 8, 2, 2, 'A').fill(9, 6, 3, 3, ':').points('5', (10, 7)).points('b', (4, 12), (8, 11)).points('c', (3, 6))   # security wing
    k.fill(3, 14, 4, 19, '.').fill(3, 18, 4, 7, 'v').fill(3, 17, 4, 1, '/').fill(3, 25, 4, 1, '/')   # loading bay
    k.points('k', (4, 20)).points('c', (6, 22), (3, 29))
    k.fill(11, 16, 10, 12, '.').points('p', (12, 17), (19, 17), (12, 26), (19, 26)).points('w', (15, 20), (16, 24)).points('n', (13, 22))   # banking hall
    k.fill(14, 28, 4, 5, '.').fill(15, 5, 2, 11, '.').put(16, 11, 'b')
    k.fill(20, 6, 9, 8, ':').fill(23, 8, 2, 2, 'B').points('1', (21, 7), (27, 7), (21, 12), (27, 12)).points('2', (24, 11))   # vault room
    k.fill(25, 14, 3, 19, '.').points('c', (26, 18), (25, 26)).points('b', (27, 30))
    k.fill(7, 22, 4, 1, '.').fill(21, 20, 4, 1, '.').fill(12, 14, 3, 2, '.').fill(20, 14, 2, 2, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


def coastal():
    # Coast guard station: the helipad on the radar bluff (raised, A), the sea
    # inlet (water) along the west, the boathouse (covered) and the barracks
    # yard (B) with sandbag positions.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2, pave='.')
    spawn_room(k, 14, 34, 'T', pave='.')
    k.fill(3, 33, 26, 1, '.')
    k.fill(3, 6, 10, 8, '.').fill(5, 7, 6, 5, '^').fill(7, 8, 2, 2, 'A').put(8, 12, '/').put(11, 9, '/')   # helipad bluff
    k.points('s', (5, 7), (10, 11)).points('b', (3, 13)).points('c', (12, 6))
    k.fill(3, 14, 3, 19, '~').fill(6, 14, 3, 19, '.').fill(6, 19, 3, 5, ':').points('1', (7, 20)).points('k', (6, 16)).points('c', (8, 28))   # inlet + boathouse
    k.fill(3, 25, 3, 2, '.')
    k.fill(12, 16, 8, 12, '.').points('o', (13, 17), (18, 21), (13, 25)).points('s', (16, 18), (15, 24)).points('b', (19, 26))   # vehicle park (middle)
    k.fill(14, 28, 4, 5, '.').fill(15, 5, 2, 11, '.').put(15, 10, 's')
    k.fill(19, 6, 10, 8, '.').fill(22, 8, 2, 2, 'B').fill(26, 6, 3, 3, ':').points('s', (20, 7), (25, 11), (21, 12)).points('o', (28, 12))   # barracks yard
    k.fill(25, 14, 3, 19, '.').fill(25, 19, 3, 6, ':').points('5', (26, 20)).points('c', (26, 16), (27, 29))
    k.fill(9, 22, 3, 1, '.').fill(20, 20, 5, 1, '.').fill(12, 14, 3, 2, '.').fill(20, 14, 2, 2, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


def servercentre():
    # Data centre (indoor, hall 9.6 m): server hall A with rack rows and a
    # raised cable deck, the cooling plant in the middle, the core room B,
    # a network operations corridor east.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2, pave='.')
    spawn_room(k, 14, 34, 'T', pave='.')
    k.fill(3, 33, 26, 1, '.')
    k.fill(3, 6, 9, 8, '.').fill(5, 8, 2, 2, 'A').points('w', (3, 7), (8, 7), (3, 10), (8, 10), (9, 12)).fill(10, 6, 2, 4, '^').put(10, 10, '/')   # server hall A
    k.fill(3, 14, 3, 19, '.').fill(3, 17, 3, 7, ':').points('2', (4, 18), (3, 22)).points('c', (5, 27))
    k.fill(12, 16, 8, 12, '.').points('4', (13, 17), (18, 17), (13, 25), (18, 25)).points('w', (15, 21)).points('b', (16, 19))   # cooling plant
    k.fill(14, 28, 4, 5, '.').fill(15, 5, 2, 11, '.').put(16, 10, 'w')
    k.fill(20, 6, 9, 8, ':').fill(23, 8, 2, 2, 'B').points('2', (21, 7), (27, 7), (21, 12), (27, 12), (24, 11))   # core room B
    k.fill(25, 14, 3, 19, '.').fill(25, 19, 3, 5, ':').points('5', (26, 20)).points('c', (26, 16), (27, 29))
    k.fill(6, 21, 6, 1, '.').fill(20, 22, 5, 1, '.').fill(12, 14, 3, 2, '.').fill(20, 14, 2, 2, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


def citadel():
    # Mountain citadel: terraces climb toward the defenders; the upper bailey
    # (raised, A), the gate ramp in the middle, the armoury (B, covered), a
    # rock-cut passage (sunken) east.
    k = Canvas(32, 40)
    k.fill(2, 2, 28, 36, '#')
    defend_spawn(k, 13, 2)
    spawn_room(k, 14, 34, 'T', pave='.')
    k.fill(3, 33, 26, 1, '.')
    k.fill(3, 6, 9, 8, '^').fill(5, 8, 2, 2, 'A').points('c', (4, 7), (10, 12)).points('w', (8, 10))   # upper bailey (A)
    k.fill(3, 14, 3, 19, '.').fill(3, 14, 3, 1, '/').points('r', (4, 18), (3, 24)).points('t', (5, 28))
    k.fill(12, 16, 8, 12, '.').fill(12, 16, 8, 4, '^').fill(12, 20, 8, 1, '/').points('r', (13, 23), (18, 26)).points('w', (15, 17))   # gate ramp
    k.fill(14, 28, 4, 5, '.').fill(15, 5, 2, 11, '.').put(15, 9, 'c').fill(15, 15, 2, 1, '/').fill(15, 5, 2, 1, '.')
    k.fill(12, 8, 3, 6, '^').fill(11, 6, 2, 2, '/').fill(13, 6, 2, 2, '#')      # stairs from the defender exit
    k.fill(20, 6, 9, 8, ':').fill(23, 8, 2, 2, 'B').points('1', (21, 7), (27, 11)).points('3', (21, 11), (27, 7))   # armoury
    k.fill(25, 14, 3, 19, '.').fill(25, 17, 3, 10, 'v').fill(25, 16, 3, 1, '/').fill(25, 27, 3, 1, '/').points('r', (26, 20))
    k.fill(6, 20, 6, 1, '.').fill(20, 23, 5, 1, '.').fill(20, 14, 5, 2, '.')
    k.fill(11, 3, 2, 3, '.').fill(19, 3, 2, 3, '.')
    return k


defusal(25, '용광로', 12, furnace(), ('용광로', '주선 바닥 / 장입 홀 / 슬래그 마당', '주선 플랫폼 +2m, 슬래그 구덩이 -2m'),
        ['furnace', 'steelmill'], props={'4': ['gastank', 'transformer'], 'c': ['ingots', 'crate_stack'], 'b': 'barrier_single', 'o': 'ingots', '1': 'pallet_load', '2': 'pipes', '6': 'cable_drum', 'w': 'low_wall'})
defusal(26, '온실', 12, greenhouse(), ('온실', '야자 온실 / 저수 정원 / 난초 온실', '저수지 둑길'),
        ['greenhouse', 'orchard'], props={'5': ['potting_bench', 'planter_long'], '2': 'planter_long', 'n': ['bench', 'potting_bench'], 'c': ['watertank_floor', 'planter'], 'w': 'planter_long'})
defusal(27, '지하 금고', 12, vault(), ('지하 금고', '금고실 / 보안 사무실 / 은행 홀', '하역장 -2m'),
        ['vault'], indoor=True, props={'1': ['deposit_block', 'money_cart'], '2': 'deposit_block', '5': 'desk', 'b': 'barrier_single', 'c': ['crate_stack', 'money_cart'], 'k': 'vehicle_van', 'p': 'pillar', 'w': 'low_wall', 'n': 'desk'})
defusal(28, '해안 기지', 12, coastal(), ('해안 기지', '헬기장 절벽 / 보트 창고 / 막사 마당', '헬기장 +2m · 해안 수로'),
        ['coastal_base', 'harbour'], water_kind='sea', props={'s': ['sacktrench', 'sacktrench_small'], 'o': 'container_small', 'b': 'barrier_single', 'k': 'vehicle_utility', 'c': ['gastank', 'crate_stack'], '1': 'crate_stack', '5': 'desk'})
defusal(29, '서버 센터', 12, servercentre(), ('서버 센터', '서버 홀 / 냉각 설비 / 코어 룸', '케이블 데크 +2m'),
        ['server'], indoor=True, hall=9.6, props={'w': 'server_block', '2': 'server_block', '4': ['transformer', 'cabinet'], 'b': 'barrier_single', 'c': ['cable_drum', 'crate_stack'], '5': 'desk'})
defusal(30, '산성', 12, citadel(), ('산성', '윗 성곽 / 성문 비탈 / 무기고', '성곽 +2m, 암굴 -2m'),
        ['mountain_fort', 'fortress'], props={'c': ['cask_pair', 'crate_stack'], 'r': 'rock_pile', 'w': 'low_wall', '1': 'weapon_rack', '3': 'pillar', 't': 'tree_2'})

defusal(19, '요새', 8, fortress(), ('성채', '본성 안뜰 / 예배당 마당 / 외성', '성벽길 +2m'),
        ['fortress', 'mountain_fort'], props={'c': ['cask_pair', 'crate_stack'], 'r': ['rock_pile', 'hay_bale'], 'w': 'low_wall', 'b': 'sacktrench', '1': 'weapon_rack'})
defusal(20, '원전', 8, nuclear(), ('원전', '원자로 홀 / 냉각수 마당 / 터빈 통로', '격납 링 +2m'),
        ['nuclear', 'power'], props={'4': ['transformer', 'gastank'], 'b': 'barrier_single', 'o': 'container_small', 'c': ['drums', 'cable_drum'], '2': 'cabinet', '6': 'pipes'})
defusal(21, '수로교', 8, aqueduct(), ('수로교', '수로교 상판 / 강 여울 / 방앗간 마당', '상판 +2m · 강'),
        ['aqueduct', 'oldtown'], props={'c': ['cask_pair', 'pots'], 'r': 'rock_pile', 'w': 'low_wall', 'n': 'bench', '5': 'cafe_table', '6': 'hay_bale', 'b': 'bollards'})
defusal(22, '도서관', 8, library(), ('도서관', '열람실 / 서가 / 희귀본 금고', '회랑 +2m'),
        ['library'], indoor=True, hall=9.6, props={'n': 'reading_table', 'w': 'bookcase', 'c': ['globe', 'crate_stack'], 'b': 'reading_table', '2': 'bookcase', '1': 'bookcase'})
defusal(23, '폐선장', 8, wreckyard(), ('폐선장', '해체 선체 / 침수 선대 / 절단 창고', '선체 갑판 +2m'),
        ['wreckyard', 'shipyard'], water_kind='sea', props={'r': ['debris_tires', 'pallet_broken', 'woodplanks_stack'], 'o': 'container_small', 'k': 'vehicle_tow', 'c': 'gastank', '4': 'gastank', '6': 'pallet_broken'})
defusal(24, '수도원', 8, monastery(), ('수도원', '회랑 안뜰 / 계단 정원 / 예배당', '정원 +2m, 지하 통로 -2m'),
        ['monastery', 'aqueduct'], props={'w': 'planter_long', 'n': 'bench', 'c': ['cask_pair', 'planter'], '5': 'bench', '3': 'pillar', 'r': 'rock_pile'})

regular(0, '항구', 32, harbour(), ('항구', '선거·부두 / 세관 창고 / 컨테이너 터미널', '크레인 레일 +2m'),
        ['harbour', 'logistics', 'canal'], water_kind='sea',
        props={'o': ['container_small', 'container_long'], 'c': ['crate_stack', 'bollards', 'fish_crates'], 'k': ['vehicle_flatbed', 'vehicle_delivery'], 'b': 'barrier_single', 'w': 'low_wall', '1': 'crate_stack', '6': 'pallet_load'})
regular(1, '조선소', 32, shipyard(), ('조선소', '건선거 / 제관 공장 / 선대 갠트리', '건선거 -2m, 갠트리 +2m'),
        ['shipyard', 'logistics'], props={'o': ['container_long', 'pipes'], 'r': ['cable_drum', 'woodplanks_stack'], 'c': ['cable_drum', 'crate_stack'], 'b': 'barrier_single', 'k': 'vehicle_flatbed', '4': 'transformer', '6': 'pallet_load', 'w': 'low_wall'})
regular(5, '운하', 32, canal(), ('운하', '운하와 다리 / 시장 광장 / 창고 부두', '운하 수면 · 다리 3곳'),
        ['canal', 'oldtown', 'market'], water_kind='river',
        props={'n': ['market_stall', 'bench'], 'c': ['cask_pair', 'crate_stack'], 'o': 'container_small', 'k': 'vehicle_van', 'w': 'planter_long', '5': 'cafe_table', '1': 'crate_stack'})
regular(2, '제철소', 16, steelmill(), ('제철소', '주조장 / 압연 라인 / 용광로동', '점검 통로·갠트리 +2m'),
        ['steelmill'], indoor=True, hall=9.6, props={'o': ['ingots', 'gastank'], 'c': 'crate_stack', 'b': 'barrier_single', 'k': 'cable_drum', 'w': 'low_wall', '4': 'transformer', 's': 'pipes'})
regular(3, '연구소', 16, institute(), ('연구소', '유리 아트리움 / 실험동 / 기록실', '실내 단층 · 클린룸'),
        ['lab'], indoor=True, props={'n': ['bench', 'planter'], 'c': ['cabinet', 'crate_stack'], 'b': 'lab_bench', '5': 'lab_bench', '2': 'bookcase', 'w': 'planter_long'})
regular(4, '사막 기지', 16, desert(), ('사막 기지', '차량 정비장 / 레이더 언덕 / 막사', '레이더 언덕 +2m'),
        ['desert', 'coastal_base'], props={'k': ['vehicle_pickup', 'vehicle_utility'], 'o': 'container_small', 's': ['sacktrench', 'sacktrench_small'], 'b': 'barrier_single', '1': 'crate_stack', '6': 'gastank'})
regular(6, '중앙역', 16, station(), ('중앙역', '광장 / 기둥 대합실 / 승강장·선로', '승강장 +2m, 선로 -2m'),
        ['station', 'oldtown', 'plaza'], props={'n': ['bench', 'sign'], '5': 'bench', '3': 'pillar', 'o': 'container_long', 'k': 'vehicle_van', 'c': ['luggage', 'trashcontainer'], 'w': 'planter_long'})

regular(8, '정비 공장', 6, garage(), ('정비 공장', '정비 베이 / 부품 창고 / 사무동', '검사 피트 -2m'),
        ['garage'], indoor=True, props={'k': ['vehicle_hatch', 'vehicle_compact'], 'c': ['tool_chest', 'debris_tires'], '1': 'tool_chest', '6': 'debris_tires', 'b': 'workbench'})
regular(11, '발전소', 6, power(), ('발전소', '터빈 홀 / 펌프실 / 제어실', '점검 통로 +2m'),
        ['power'], indoor=True, props={'4': 'transformer', 'c': 'cable_drum', 'b': 'barrier_single', 's': 'gastank'})
regular(14, '실험 단지', 8, labcomplex(), ('실험 단지', '실험 챔버 / 제독 홀 / 관찰실', '관찰 데크 +2m'),
        ['testlab', 'lab'], indoor=True, props={'4': ['lab_bench', 'cabinet'], '5': 'lab_bench', 'b': 'barrier_single', 'w': 'low_wall', 'c': 'crate_stack'})
regular(15, '폐공장', 8, derelict(), ('폐공장', '붕괴 바닥 / 기계실 / 하역 사무실', '무너진 바닥 -2m'),
        ['derelict'], indoor=True, props={'r': ['debris_tires', 'pallet_broken', 'woodplanks_stack'], '4': 'gastank', '6': 'pallet_broken', 'k': 'vehicle_pickup', 'c': 'crate_stack'})
regular(16, '고층 빌딩', 8, highrise(), ('고층 빌딩', '사무 층 / 회의실 / 아트리움', '메자닌 +2m'),
        ['highrise'], indoor=True, props={'2': 'low_wall', '5': 'desk', 'w': 'low_wall', 'p': 'pillar', 'n': ['sofa', 'planter']})
regular(17, '재래시장', 8, market(), ('재래시장', '좌판 골목 / 수산 홀 / 장터 광장', '평지 · 아케이드'),
        ['market', 'oldtown'], props={'n': ['market_stall', 'fruit_crates'], '5': ['market_stall', 'fruit_crates'], 'c': ['cask_pair', 'cardboardboxes_2'], 'k': 'vehicle_delivery'})
regular(18, '채석장', 8, quarry(), ('채석장', '채굴 구덩이 / 벤치 / 파쇄장', '구덩이 -2m, 벤치 +2m'),
        ['quarry'], props={'r': 'rock_pile', '4': ['cable_drum', 'gastank'], 'k': 'vehicle_dump', 'c': 'woodplanks_stack'})

regular(7, '구시가지', 6, oldtown(), ('구시가지', '시장 광장 / 골목 / 테라스', '테라스 +2m'),
        ['oldtown', 'market', 'canal'], props={'c': ['cask_pair', 'crate_stack'], 'n': ['cafe_table', 'market_stall']})
regular(9, '산동네', 6, hillside(), ('산동네', '계단 골목 / 안뜰 / 위 테라스', '중앙 테라스 +2m'),
        ['hillside', 'oldtown'], props={'r': 'rock_pile', 's': 'pots'})
regular(10, '과수원', 6, orchard(), ('과수원', '과수 줄 / 헛간 / 농가 마당', '평지 · 헛간 통로'),
        ['orchard'], props={'n': ['hay_bale', 'fruit_crates'], 'k': 'vehicle_pickup', 'c': 'cask_pair', '6': 'hay_bale'})
regular(12, '분수 광장', 6, fountain(), ('분수 광장', '분수 / 아케이드 / 로지아', '로지아 +2m'),
        ['plaza', 'oldtown'], props={'n': ['bench', 'cafe_table'], 'w': 'planter_long', 'c': 'planter', 'f': 'fountain'})

regular(13, '물류 창고', 8, logistics(),
        ('물류 야드', '분류 창고 / 컨테이너 야드 / 하역장', '하역 도크 +2m, 트럭 베이 -2m'),
        ['logistics', 'harbour', 'shipyard'],
        props={'c': ['crate_stack', 'pallet_load'], '1': ['pallet_load', 'crate_stack'], '3': 'pillar'})
