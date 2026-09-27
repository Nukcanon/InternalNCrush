"""Map-specific elevated/depressed routes, not two repeated full-map layers.

Each tuple selects an authored ground-chain and the portion occupied by the
alternate route. Both ends meet the actual ground route; the baker grades them.
These are metre-scale gameplay geometry, identical for native and Web builds.
"""
from shapely.geometry import LineString
from shapely.ops import substring

# upper chain/start/end/height, lower chain/start/end/height
ROUTES = [
    ((3,0,1,5.2),(0,.22,.73,-4.0)),     # Harbour: loading bridge / customs tunnel
    ((2,.08,.92,6.0),(4,.05,.95,-5.0)), # Shipyard: transverse gantry / north dry-dock spur
    ((4,0,1,5.4),(1,.16,.81,-4.0)),     # Steelworks: furnace crossing / service spine
    ((3,.12,.88,4.4),(4,0,1,-3.2)),     # Labs: south connector / northern service wing
    ((2,.20,.88,6.2),(3,0,1,-4.5)),     # Desert: ridge spur / central passage
    ((4,0,1,4.2),(2,.10,.92,-3.5)),     # Canal: short crossing / western lock route
    ((3,0,1,5.0),(0,.23,.74,-4.2)),     # Station: concourse crossing / platform route
    ((3,0,1,4.0),(2,.18,.70,-3.0)),
    ((4,.05,.95,4.0),(1,.21,.78,-3.0)),
    ((2,.16,.82,5.0),(5,.10,.92,-3.2)),
    ((4,0,1,4.6),(2,.18,.80,-3.0)),
    ((3,0,1,4.8),(0,.25,.73,-4.0)),
    ((2,.18,.85,4.0),(3,0,1,-3.0)),
    ((3,0,1,4.4),(2,.20,.72,-3.5)),
    ((4,.05,.96,4.8),(2,.14,.81,-3.5)),
    ((2,0,1,5.2),(0,.25,.72,-3.8)),
    ((4,0,1,5.8),(2,.16,.78,-3.2)),
    ((3,0,1,4.2),(4,.10,.90,-3.0)),    # Market: shop gallery / cross-street cellars
    ((4,.05,.96,6.0),(2,.14,.87,-4.5)),
    ((-1,.05,.78,5.0),(-4,.30,.78,-3.0)),
    ((-2,.10,.89,5.4),(-3,.18,.64,-4.5)),
    ((-2,.04,.74,6.0),(-4,.24,.82,-3.8)),
    ((-1,.20,.91,4.6),(-2,.08,.94,-3.6)),
    ((-3,.30,.77,5.2),(-4,.18,.65,-3.8)),
    ((-4,.38,.85,5.8),(-1,.08,.65,-3.6)),
    ((-2,.08,.90,6.0),(-3,.24,.79,-4.2)),
    ((-1,.20,.76,4.6),(-4,.26,.70,-3.2)),
    ((-2,.06,.86,4.2),(-3,.14,.83,-5.2)),
    ((-3,.25,.81,6.2),(-4,.25,.82,-4.5)),
    ((-1,.12,.84,4.8),(-2,.05,.94,-3.8)),
    ((-4,.34,.84,6.0),(-1,.10,.81,-3.8)),
]

# Absence is intentional. A map is not required to have both a basement and a
# suspended deck. These compositions follow the location, not the player count.
COMPOSITIONS = [
    'loading_bridge', 'dry_dock', 'factory_catwalk', 'laboratory_floors',
    'ridge', 'canal_bridge', 'subway', 'balconies', 'single_storey',
    'hillside_streets', 'single_storey', 'service_basement', 'single_storey',
    'single_storey', 'laboratory_floors', 'boiler_basement', 'rooftops',
    'shop_gallery', 'quarry_pit', 'ramparts', 'reactor_floors', 'aqueduct',
    'library_gallery', 'ship_hold', 'cloister_crypt', 'factory_catwalk',
    'single_storey', 'underground_vault', 'coastal_ridge', 'server_mezzanine',
    'ramparts',
]
GROUND_ONLY={8,10,12,13,26}
LOWER_ONLY={1,6,11,15,18,23,27}
BOTH_LEVELS={20,24}
STAIR_MAPS={2,3,6,7,9,11,14,15,16,17,19,20,22,23,24,25,27,29,30}

for index in range(len(ROUTES)):
    upper,lower=ROUTES[index]
    if index in GROUND_ONLY:upper=lower=None
    elif index in LOWER_ONLY:upper=None
    elif index not in BOTH_LEVELS:lower=None
    ROUTES[index]=(upper,lower)

def select(index, paths):
    result=[]
    for entry in ROUTES[index]:
        if entry is None:
            result.append(([],0.));continue
        chain,start,end,height=entry
        route=substring(LineString(paths[chain]),start,end,normalized=True)
        result.append((list(route.coords),height))
    return result
