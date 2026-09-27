"""Bake approved district polygons into static, tiled collision/render geometry.

Requires Shapely 2.1. No runtime CSG, textures, lights, or physics per prop.
Coordinates and walk surfaces are shared by native and Web exports.
"""
import json, math
from pathlib import Path
from shapely import constrained_delaunay_triangles
from shapely.geometry import Polygon, LineString, Point, box
from shapely.ops import unary_union

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'game/assets/arenas/districts'
OUT.mkdir(exist_ok=True)
plans=json.loads((OUT.parent/'district_specs.json').read_text(encoding='utf-8'))

def polygons(g):
    if g.is_empty:return []
    return [g] if g.geom_type=='Polygon' else [p for part in g.geoms for p in polygons(part)]
def rings(p):return [list(p.exterior.coords)]+[list(h.coords) for h in p.interiors]
def shape(data):return unary_union([Polygon(p[0],p[1:]) for p in data])
def triangles(g):
    for p in polygons(g):
        for t in constrained_delaunay_triangles(p).geoms:yield list(t.exterior.coords)[:3]

for plan in plans:
    w,h=plan['dimensions'];ox,oz=w/2,h/2
    floor=shape(plan['floor']); border=shape(plan['border'])
    # Bounds are exact; the preview's buffer may extend a few metres outside.
    envelope=box(1,1,w-1,h-1)
    floor=floor.intersection(envelope);border=border.intersection(box(0,0,w,h))
    architecture_floor=floor
    surfaces=[];groups={};goals=[]
    def emit(points,kind):
        cx=sum(p[0] for p in points)/3-ox;cz=sum(p[2] for p in points)/3-oz
        key=(math.floor(cx/24),math.floor(cz/24),kind)
        groups.setdefault(key,[]).extend([[round(x-ox,4),round(y,4),round(z-oz,4)] for x,y,z in points])
    def face(poly,plane,kind,walk=True):
        # y = ax + bz + c, in centred world coordinates.
        def height(x,z):return plane[0]*(x-ox)+plane[1]*(z-oz)+plane[2]
        for p in polygons(poly):
            if walk:
                rr=[[[round(x-ox,4),round(z-oz,4)] for x,z in ring] for ring in rings(p)]
                surfaces.append({'rings':rr,'plane':plane,'layer':kind})
            for t in triangles(p):
                a,b,c=t
                if (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])<0:b,c=c,b
                emit([(x,height(x,z),z) for x,z in [a,b,c]],kind)
                if kind=='ceiling':emit([(x,height(x,z),z) for x,z in [c,b,a]],kind)
    def walls(poly,low,high,kind):
        for p in polygons(poly):
            for ring in rings(p):
                for a,b in zip(ring,ring[1:]):
                    first=[(a[0],low,a[1]),(b[0],low,b[1]),(a[0],high,a[1])]
                    second=[(b[0],low,b[1]),(b[0],high,b[1]),(a[0],high,a[1])]
                    for tri in [first,second]:emit(tri,kind);emit(tri[::-1],kind)
    def level(path,height,width):
        # Two graded entrances and a level middle, with a maximum 1:3 slope.
        line=LineString(path)
        if line.length<45:line=LineString(max(plan['paths'],key=lambda p:LineString(p).length))
        length=line.length;run=min(abs(height)*3.5,length*.33)
        cuts=sorted(set([0.,run,length-run,length]+[line.project(__import__('shapely').geometry.Point(p)) for p in path]))
        strips=[];cuts_ground=[]
        def elevation(d):return height*min(1,d/run,(length-d)/run)
        for start,end in zip(cuts,cuts[1:]):
            if end-start<.01:continue
            a=line.interpolate(start);b=line.interpolate(end);dx=b.x-a.x;dz=b.y-a.y;distance=math.hypot(dx,dz)
            if distance<.01:continue
            nx=-dz/distance*width/2;nz=dx/distance*width/2
            p=Polygon([(a.x+nx,a.y+nz),(b.x+nx,b.y+nz),(b.x-nx,b.y-nz),(a.x-nx,a.y-nz)])
            ya,yb=elevation(start),elevation(end);slope=(yb-ya)/distance
            plane=[slope*dx/distance,slope*dz/distance,0.]
            plane[2]=ya-plane[0]*(a.x-ox)-plane[1]*(a.y-oz)
            face(p,plane,'upper' if height>0 else 'lower');strips.append(p)
            # The complete descending entrance stays open, never a ground slab
            # cutting across the player's head halfway down the stairs.
            if height<0 and (start<run+.01 or end>length-run-.01):cuts_ground.append(p)
        # Fill only corner wedges, at their shared height. Avoid coplanar strips.
        full=line.buffer(width/2,join_style=2,cap_style=2).intersection(envelope)
        missing=full.difference(unary_union(strips))
        for t in triangles(missing):
            # A ramp corner must interpolate its vertices. Giving an entire
            # wedge its centroid height creates an invisible vertical step.
            distances=[line.project(Point(p)) for p in t]
            ys=[elevation(d) for d in distances]
            (x0,z0),(x1,z1),(x2,z2)=t
            det=(x1-x0)*(z2-z0)-(x2-x0)*(z1-z0)
            if abs(det)<1e-8:continue
            ax=((ys[1]-ys[0])*(z2-z0)-(ys[2]-ys[0])*(z1-z0))/det
            bz=((x1-x0)*(ys[2]-ys[0])-(x2-x0)*(ys[1]-ys[0]))/det
            p=Polygon(t);face(p,[ax,bz,ys[0]-ax*(x0-ox)-bz*(z0-oz)],'upper' if height>0 else 'lower')
            if height<0 and (min(distances)<run+.01 or max(distances)>length-run-.01):cuts_ground.append(p)
        if height<0:walls(full,height,-.08,'tunnel')
        mid=line.interpolate(length*.5);goals.append([mid.x-ox,height,mid.y-oz])
        return unary_union(cuts_ground),full
    if plan['id']!=32:
        cut,lower=level((plan['lower_path'][1:-1] if len(plan['lower_path'])>3 else plan['lower_path']),-4.2,max(4.4,plan['corridor_m']*.65))
        _,upper=level((plan['upper_path'][1:-1] if len(plan['upper_path'])>3 else plan['upper_path']),4.2,max(4.8,plan['corridor_m']*.70))
        floor=floor.difference(cut)
    else:
        # Existing four-storey target range stays in the centre, new outdoor
        # districts extend its approaches without moving familiar target lanes.
        floor=unary_union([floor,box(ox-43,oz-47,ox+43,oz+47)])
        border=unary_union([border,box(ox-46,oz-50,ox+46,oz+50)])
        architecture_floor=floor
        lower=Polygon();upper=Polygon()
    face(floor,[0,0,0],'ground')
    if plan['id']-1 in [2,3,8,11,14,15]:
        face(architecture_floor,[0,0,6.8],'ceiling',False)
    water=Polygon()
    if plan['id']-1 in [0,1,5,21,23,28]:
        holes=[Polygon(r) for p in polygons(shape(plan['floor'])) for r in p.interiors if Polygon(r).area>45]
        if holes:water=max(holes,key=lambda p:p.area)
    # Solid building islands and exterior boundary give rooms and corridors
    # real occlusion. Open courtyards remain roofless; selected side rooms get
    # ceilings at runtime, never across the stair entrances.
    for p in polygons(architecture_floor):
        walls(Polygon(p.exterior),0,3.1,'wall')
        for hole in p.interiors:
            island=Polygon(hole);walls(island,0,.45 if island.equals(water) else 3.1,'wall')
    face(border.difference(architecture_floor).difference(water),[0,0,3.1],'roof',False)
    if not water.is_empty:
        face(water,[0,0,-.6],'lower')
        face(water,[0,0,-.35],'water',False)
    walls(border,0,7.2,'perimeter')
    def centered(p):return [round(p[0]-ox,4),round(p[1]-oz,4)]
    routes=unary_union([LineString(path) for path in plan['paths']])
    props=[]
    for x in range(8,int(w)-8,8):
        for z in range(8,int(h)-8,8):
            point=Point(x,z)
            if plan['id']==32 and abs(x-ox)<44 and abs(z-oz)<48:continue
            if not floor.contains(point.buffer(2.4)):continue
            if routes.distance(point)<plan['corridor_m']/2+1.4:continue
            if not upper.is_empty and upper.distance(point)<3:continue
            if not lower.is_empty and lower.distance(point)<3:continue
            if min(math.dist((x,z),p) for p in plan['spawns']+plan['targets'])<11:continue
            if any(math.dist((x,z),p)<11 for p in props):continue
            props.append((x,z))
    props=props[:min(48,plan['capacity']*2)]
    # Small movable objects use a separate, less restrictive edge allowance.
    # They are kept out of the central route, spawns, objectives and ramps.
    loose=[]
    for x in range(4,int(w)-4,4):
        for z in range(4,int(h)-4,4):
            point=Point(x,z)
            if plan['id']==32 and abs(x-ox)<44 and abs(z-oz)<48:continue
            if not floor.contains(point.buffer(.9)):continue
            if routes.distance(point)<min(3.,plan['corridor_m']*.28):continue
            if min(math.dist((x,z),p) for p in plan['spawns']+plan['targets'])<9:continue
            if (not upper.is_empty and upper.distance(point)<2) or (not lower.is_empty and lower.distance(point)<2):continue
            if any(math.dist((x,z),p)<3.5 for p in props+loose):continue
            loose.append((x,z))
            if len(loose)>=12:break
        if len(loose)>=12:break
    facades=[]
    for poly in polygons(architecture_floor):
        for ring in rings(poly):
            for a,b in zip(ring,ring[1:]):
                length=math.dist(a,b)
                if length<7:continue
                x,z=(a[0]+b[0])/2,(a[1]+b[1])/2
                dx,dz=(b[0]-a[0])/length,(b[1]-a[1])/length
                nx,nz=-dz,dx
                if not floor.contains(Point(x+nx*.3,z+nz*.3)):nx,nz=-nx,-nz
                # Front detail is clipped to the wall, never across an entrance.
                facades.append([*centered((x+nx*.04,z+nz*.04)),math.atan2(nx,nz),min(6,length-1)])
    data={'index':plan['id']-1,'name':plan['name'],'dimensions':[w,h],
          'rectangle':plan['rectangle'],'surfaces':surfaces,'groups':[{'kind':key[2],'origin':[key[0]*24+12,0,key[1]*24+12],'vertices':v} for key,v in groups.items()],
          'border':[[centered(p) for p in ring] for ring in rings(max(polygons(border),key=lambda p:p.area))],
          'spawns':[centered(p) for p in plan['spawns']], 'targets':[centered(p) for p in plan['targets']],
          'goals':goals,'corridor_m':plan['corridor_m'],'capacity':plan['capacity'],
          'props':[centered(p) for p in props], 'loose_props':[centered(p) for p in loose], 'facades':facades,
          'water':[[centered(p) for p in ring] for ring in rings(water)] if not water.is_empty else [],
          'water_boat':centered((water.representative_point().x,water.representative_point().y)) if not water.is_empty else []}
    (OUT/('map_%02d.json'%data['index'])).write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    preview={k:v for k,v in data.items() if k!='groups'}
    preview['triangles']={key:[] for key in ['ground','upper','lower']}
    for surface in surfaces:
        poly=Polygon(surface['rings'][0],surface['rings'][1:]).buffer(0)
        for tri in triangles(poly):preview['triangles'][surface['layer']].extend(tri)
    (OUT/('plan_%02d.json'%data['index'])).write_text(json.dumps(preview,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    print(data['index'],data['name'],len(surfaces),'surfaces',len(groups),'tiles')
