"""Bake original route graphs into clean diagonal walls. Dev dependency: shapely==2.1.2.
Godot runtime/export only reads the resulting JSON; Shapely is not shipped.
"""
import json
from pathlib import Path
import shapely
from shapely.geometry import Polygon, LineString, box

folder=Path(__file__).resolve().parents[1]/'assets/arenas'
specs=json.loads((folder/'defusal_specs.json').read_text(encoding='utf-8'))
result={}
def coords(ring):return [[round(x,5),round(z,5)] for x,z in ring.coords]
for key,s in specs.items():
    shapes=[]
    for i,(x,z) in enumerate(s['points']):
        rx,rz=(10,7) if i==0 else (7,7) if i in (2,3) else (5,5)
        shapes.append(box(x-rx,z-rz,x+rx,z+rz))
    for a,b in s['links']:
        shapes.append(LineString([s['points'][a],s['points'][b]]).buffer(3.5,quad_segs=3))
    x,z=s['points'][3 if s['style'] in (1,8) or s['style']%2 else 2]
    shapes.append(box(x-4,z-6,x+2,z+17))
    bounds=Polygon(s['perimeter'])
    free=shapely.union_all(shapes).intersection(bounds)
    solids=shapely.orient_polygons(bounds.difference(free))
    walls=[];roof=[]
    for poly in getattr(solids,'geoms',[solids]):
        for ring in [poly.exterior,*poly.interiors]:
            points=coords(ring)
            walls.extend([[a,b] for a,b in zip(points,points[1:])])
        for tri in shapely.constrained_delaunay_triangles(poly).geoms:
            roof.append(coords(shapely.orient_polygons(tri).exterior)[:3])
    result[key]={'walls':walls,'roof':roof}
    print(key,len(walls),'wall edges',len(roof),'roof triangles')
(folder/'defusal_geometry.json').write_text(json.dumps(result,separators=(',',':')),encoding='utf-8')
