"""Bake approved district polygons into static, tiled collision/render geometry.

Requires Shapely 2.1. No runtime CSG, textures, lights, or physics per prop.
Coordinates and walk surfaces are shared by native and Web exports.
"""
import json, math, gzip
from pathlib import Path
from shapely import constrained_delaunay_triangles
from shapely.geometry import Polygon, LineString, Point, box
from shapely.ops import unary_union
from tile_faces import tiled_triangles

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'game/assets/arenas/districts'
OUT.mkdir(exist_ok=True)
plans=json.loads((OUT.parent/'district_specs.json').read_text(encoding='utf-8'))
transport=json.loads((ROOT/'game/assets/models/transport_original/manifest.json').read_text())['assets']

def polygons(g):
    if g.is_empty:return []
    if not hasattr(g,'geoms') and g.geom_type!='Polygon':return []
    return [g] if g.geom_type=='Polygon' else [p for part in g.geoms for p in polygons(part)]
def rings(p):return [list(p.exterior.coords)]+[list(h.coords) for h in p.interiors]
def shape(data):return unary_union([Polygon(p[0],p[1:]) for p in data])
def triangles(g):
    for p in polygons(g):
        try:parts=constrained_delaunay_triangles(p).geoms
        except Exception:
            # Near-degenerate slivers (landing/overlap cells): clean and retry.
            from shapely.ops import triangulate
            clean=p.buffer(0).simplify(1e-4)
            try:parts=[t for q in polygons(clean) for t in constrained_delaunay_triangles(q).geoms] if not clean.is_empty else []
            except Exception:parts=[t for t in triangulate(clean) if clean.contains(t.representative_point())]
        for t in parts:yield list(t.exterior.coords)[:3]

for plan in plans:
    sea=plan['id']-1 in [0,1,23,28]
    w,h=plan['dimensions'];ox,oz=w/2,h/2
    floor=shape(plan['floor']); border=shape(plan['border'])
    # Bounds are exact; the preview's buffer may extend a few metres outside.
    envelope=box(1,1,w-1,h-1)
    floor=floor.intersection(envelope);border=border.intersection(box(0,0,w,h))
    # Corridor unions can leave centimetre-wide interior holes. Extruding those
    # holes into full-height buildings produces the isolated wall blades seen
    # in the warehouse/canal maps. Fill only tiny, narrow isolated remnants.
    cleaned=[];removed_slivers=[]
    for p in polygons(floor):
        holes=[]
        for ring in p.interiors:
            island=Polygon(ring)
            if island.area<4. and island.buffer(-.30).is_empty:
                removed_slivers.append([*island.centroid.coords[0],round(island.area,6)])
            else:holes.append(ring)
        cleaned.append(Polygon(p.exterior,holes))
    floor=unary_union(cleaned)
    architecture_floor=floor
    surfaces=[];groups={};goals=[];pending_faces={};seen_triangles=set()
    terrain=plan.get('terrain')
    bands=[]
    if terrain:
        axis,stops,heights=terrain;extent=w if axis=='x' else h
        for j in range(len(stops)-1):
            low,high=stops[j]*extent,stops[j+1]*extent
            slope=(heights[j+1]-heights[j])/(high-low)
            plane=[slope,0,heights[j]-slope*(low-ox)] if axis=='x' else [0,slope,heights[j]-slope*(low-oz)]
            region=box(low,-1,high,h+1) if axis=='x' else box(-1,low,w+1,high)
            bands.append((region,plane))
    else:bands=[(box(-w,-h,w*2,h*2),[0,0,0])]
    def terrain_y(x,z):
        for region,plane in bands:
            if region.covers(Point(x,z)):return plane[0]*(x-ox)+plane[1]*(z-oz)+plane[2]
        return 0.
    def emit(points,kind):
        signature=tuple(sorted(tuple(round(c,5) for c in p) for p in points))
        if signature in seen_triangles:return
        seen_triangles.add(signature)
        if kind=='water':
            cx=sum(p[0] for p in points)/3-ox;cz=sum(p[2] for p in points)/3-oz
            key=(math.floor(cx/24),math.floor(cz/24),kind)
            groups.setdefault(key,[]).extend([[round(x-ox,4),round(y,4),round(z-oz,4)] for x,y,z in points])
            return
        for tx,tz,triangle in tiled_triangles(points,ox,oz):
            key=(tx,tz,kind)
            rounded=[[round(x-ox,4),round(y,4),round(z-oz,4)] for x,y,z in triangle]
            a,b,c=rounded;u=[b[j]-a[j] for j in range(3)];v=[c[j]-a[j] for j in range(3)]
            if sum(n*n for n in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]])<1e-14:continue
            groups.setdefault(key,[]).extend(rounded)
    def face(poly,plane,kind,walk=True):
        key=(kind,tuple(round(v,8) for v in plane),walk)
        pending_faces.setdefault(key,[]).append(poly)
    def flush_faces():
        # Adjacent corridor strips overlap at corners. Union each plane before
        # triangulating so a visible pixel never has two coplanar floor faces.
        for (kind,plane,walk),pieces in pending_faces.items():
            merged=unary_union(pieces)
            if kind in ['water','waterbed']:
                emit_face(merged,plane,kind,walk)
                continue
            for region,offset in bands:
                clipped=merged.intersection(region)
                if not clipped.is_empty:
                    combined=[plane[j]+offset[j] for j in range(3)]
                    emit_face(clipped,combined,kind,walk)
                    if kind=='ground' and plan['id']-1 in [3,9,10,12,14,16,17,19,22,24,26,27,29,30] and abs(offset[0])+abs(offset[1])>.001:
                        # Supported terrace stairs, not another suspended route.
                        # Walking collision remains the smooth grade; visible
                        # tread/riser geometry never changes native/Web physics.
                        axis=0 if abs(offset[0])>.001 else 1
                        bounds=region.bounds;lo,hi=(bounds[0],bounds[2]) if axis==0 else (bounds[1],bounds[3])
                        count=max(1,math.ceil(abs((hi-lo)*offset[axis])/.17))
                        for step in range(count):
                            a,b=lo+(hi-lo)*step/count,lo+(hi-lo)*(step+1)/count
                            strip=box(a,-1,b,h+1) if axis==0 else box(-1,a,w+1,b)
                            tread=clipped.intersection(strip)
                            if tread.is_empty:continue
                            y0=offset[axis]*(a-(ox if axis==0 else oz))+offset[2]
                            y1=offset[axis]*(b-(ox if axis==0 else oz))+offset[2]
                            top=max(y0,y1)+.015
                            emit_face(tread,[0,0,top],'stair_detail',False)
                            edge=a if y1>y0 else b
                            cut=LineString([(edge,-1),(edge,h+1)]) if axis==0 else LineString([(-1,edge),(w+1,edge)])
                            lines=clipped.intersection(cut)
                            for line in ([lines] if lines.geom_type=='LineString' else getattr(lines,'geoms',[])):
                                if line.geom_type!='LineString' or line.is_empty:continue
                                u,v=list(line.coords)[0],list(line.coords)[-1]
                                emit([(u[0],min(y0,y1),u[1]),(v[0],min(y0,y1),v[1]),(u[0],top,u[1])],'stair_detail')
                                emit([(v[0],min(y0,y1),v[1]),(v[0],top,v[1]),(u[0],top,u[1])],'stair_detail')
    def emit_face(poly,plane,kind,walk=True):
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
    def walls(poly,low,high,kind):
        for p in ([poly] if poly.geom_type=='LineString' else polygons(poly)):
            for ring in ([list(p.coords)] if p.geom_type=='LineString' else rings(p)):
                for a,b in zip(ring,ring[1:]):
                    if kind=='eave_edge' and buildings.distance(Point((a[0]+b[0])*.5,(a[1]+b[1])*.5))<.02:continue
                    if kind=='perimeter' and sea and (a[0]+b[0])*.5>w*.76:
                        # The coastal edge opens onto the sea; remaining sides
                        # retain the map boundary and its collision.
                        continue
                    segment=LineString([a,b])
                    for region,offset in bands:
                        piece=segment.intersection(region)
                        if piece.is_empty or piece.geom_type!='LineString':continue
                        u,v=list(piece.coords)[0],list(piece.coords)[-1]
                        uy=terrain_y(*u);vy=terrain_y(*v)
                        top=.35 if kind=='quay_edge' and (a[0]+b[0])*.5>w*.76 else high
                        for tri in [[(u[0],low+uy,u[1]),(v[0],low+vy,v[1]),(u[0],top+uy,u[1])],[(v[0],low+vy,v[1]),(v[0],top+vy,v[1]),(u[0],top+uy,u[1])]]:emit(tri,kind)
    def level(path,height,width):
        # Two graded entrances and a level middle, with a maximum 1:3 slope.
        line=LineString(path)
        length=line.length
        # Bends get a level landing (half the width plus 0.3 m each side): a
        # ramp turning a corner is far steeper on its inner edge than on its
        # centre line. The rise happens only on straight runs, never over 1:2.2.
        vertices=[line.project(Point(q)) for q in path[1:-1]]
        delta=width*.5+.3
        flats=[(v-delta,v+delta) for v in vertices]
        def sloped(a,b):
            total=max(0.,b-a)
            for f0,f1 in flats:total-=max(0.,min(b,f1)-max(a,f0))
            return max(0.,total)
        run=min(abs(height)*3.5,length*.33)
        while min(sloped(0.,run),sloped(length-run,length))<abs(height)*3. and run<length*.45:run+=.25
        up=max(sloped(0.,run),.01);down=max(sloped(length-run,length),.01)
        def elevation(d):
            if d<=length*.5:return height*min(1.,sloped(0.,min(d,run))/up)
            return height*min(1.,sloped(max(d,length-run),length)/down)
        cuts=sorted(set([0.,run,length-run,length]+vertices+[min(length,max(0.,x)) for f in flats for x in f]))
        strips=[];planes=[];cuts_ground=[]
        for start,end in zip(cuts,cuts[1:]):
            if end-start<.01:continue
            a=line.interpolate(start);b=line.interpolate(end);dx=b.x-a.x;dz=b.y-a.y;distance=math.hypot(dx,dz)
            if distance<.01:continue
            nx=-dz/distance*width/2;nz=dx/distance*width/2
            p=Polygon([(a.x+nx,a.y+nz),(b.x+nx,b.y+nz),(b.x-nx,b.y-nz),(a.x-nx,a.y-nz)])
            ya,yb=elevation(start),elevation(end);slope=(yb-ya)/distance
            plane=[slope*dx/distance,slope*dz/distance,0.]
            plane[2]=ya-plane[0]*(a.x-ox)-plane[1]*(a.y-oz)
            strips.append(p);planes.append(plane)
            if plan.get('stairs_enabled',False) and abs(yb-ya)>.03:
                # Visible stair treads over the smooth walking collision ramp.
                # The small offset avoids coplanar flicker at step/ramp edges.
                steps=max(1,math.ceil(abs(yb-ya)/.17))
                for step in range(steps):
                    t0,t1=step/steps,(step+1)/steps
                    x0,z0=a.x+dx*t0,a.y+dz*t0;x1,z1=a.x+dx*t1,a.y+dz*t1
                    y0,y1=ya+(yb-ya)*t0,ya+(yb-ya)*t1;top=max(y0,y1)+.012
                    tread=Polygon([(x0+nx,z0+nz),(x1+nx,z1+nz),(x1-nx,z1-nz),(x0-nx,z0-nz)])
                    face(tread,[0,0,top],'stair_detail',False)
                    rx,rz=(x0,z0) if y1>y0 else (x1,z1)
                    emit([(rx+nx,min(y0,y1),rz+nz),(rx-nx,min(y0,y1),rz-nz),(rx+nx,top,rz+nz)],'stair_detail')
                    emit([(rx-nx,min(y0,y1),rz-nz),(rx-nx,top,rz-nz),(rx+nx,top,rz+nz)],'stair_detail')
            # The complete descending entrance stays open, never a ground slab
            # cutting across the player's head halfway down the stairs.
            if height<0 and (start<run+.01 or end>length-run-.01):cuts_ground.append(p)
        # Bends are level landings, so strips overlapping at a bend share one
        # plane there (identical plane keys are unioned in flush_faces).
        kind='upper' if height>0 else 'lower'
        for strip,plane in zip(strips,planes):face(strip,plane,kind)
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
        # Decks and trenches ride on the terrain bands (flush_faces adds the offset).
        mid=line.interpolate(length*.5);goals.append([mid.x-ox,height+terrain_y(mid.x,mid.y),mid.y-oz])
        return unary_union(cuts_ground),full
    if plan['id']!=32:
        cut,lower=level(plan['lower_path'],plan.get('lower_height',-4.2),max(2.7,plan['corridor_m']*.65)) if plan['lower_path'] else (Polygon(),Polygon())
        _,upper=level(plan['upper_path'],plan.get('upper_height',4.2),max(2.7,plan['corridor_m']*.70)) if plan['upper_path'] else (Polygon(),Polygon())
        floor=floor.difference(cut)
    else:
        # Existing four-storey target range stays in the centre, new outdoor
        # districts extend its approaches without moving familiar target lanes.
        floor=unary_union([floor,box(ox-43,oz-47,ox+43,oz+47)])
        border=unary_union([border,box(ox-46,oz-50,ox+46,oz+50)])
        architecture_floor=floor
        lower=Polygon();upper=Polygon()
    face(floor,[0,0,0],'ground')
    indoor=plan['id']-1 in [2,3,8,11,14,15,16,22,27,29]
    wall_height=max(6.8,plan.get('upper_height',4.2)+2.6) if indoor else 3.1
    # 1.4: outdoor streets are framed by two-storey buildings (3.1 m storeys);
    # covered side rooms keep a one-storey ceiling (wall_height).
    STOREY=3.1
    street_height=wall_height if indoor else STOREY*2
    # Nothing a player can stand on may reach a roof: a jump rises 0.82 m
    # (6 m/s, 22 m/s^2), so tops stay 1.4 m above any nearby walkable deck.
    REACH=1.4
    upper_top=plan.get('upper_height',0.) if plan['upper_path'] else 0.
    def storeys_over(height):return math.ceil((height+REACH)/STOREY-1e-6)*STOREY
    def clear_top(region,top):
        if upper_top>0 and not upper.is_empty and upper.distance(region)<7.:top=max(top,storeys_over(upper_top))
        return top
    if indoor:
        face(architecture_floor,[0,0,wall_height],'ceiling',False)
    room_ceilings=Polygon();room_tops=[]
    if not indoor:
        # Authored side-building loops contain three linked rooms. Cover these
        # rooms, leaving the main streets, courtyards and elevated routes open.
        pockets=[]
        for bounds in plan.get('ceiling_rooms',[]):
            room=box(*bounds).intersection(architecture_floor)
            if room.is_empty:continue
            # A room needs existing perimeter walls supporting its roof.
            supported=room.boundary.intersection(architecture_floor.boundary.buffer(.03)).length
            if supported>room.length*.28:pockets.append(room)
        for path in plan['paths']:
            if len(path)!=5 or math.dist(path[0],path[-1])>.01:continue
            if LineString(path).length>145:continue
            rooms=unary_union([box(x-6,z-5,x+6,z+5) for x,z in path[1:4]])
            pockets.append(rooms.union(LineString(path[1:4]).buffer(1.35,join_style=2)))
        if pockets:
            room_ceilings=unary_union(pockets).intersection(architecture_floor)
            room_ceilings=room_ceilings.difference(upper.buffer(1.)).difference(lower.buffer(1.))
            face(room_ceilings,[0,0,wall_height],'ceiling',False)
            # A covered room is the ground floor of a building: its roof is at
            # street height (never a low ledge beside a deck).
            for room in polygons(room_ceilings):
                top=clear_top(room,street_height);room_tops.append((room,top))
                face(room,[0,0,top],'roof',False)
                for ring in rings(room):
                    for a,b in zip(ring,ring[1:]):
                        if architecture_floor.boundary.distance(Point((a[0]+b[0])*.5,(a[1]+b[1])*.5))<.02:continue
                        walls(LineString([a,b]),wall_height,top,'wall')
    water=Polygon()
    if plan['id']-1 in [0,1,5,21,23,28]:
        holes=[Polygon(r) for p in polygons(shape(plan['floor'])) for r in p.interiors if Polygon(r).area>45]
        if holes:
            water=max(holes,key=lambda p:p.area)
            if plan['id']-1<19:
                # Half-turn symmetric maps get the partner basin as well.
                from shapely.affinity import rotate
                image=rotate(water,180,origin=(w/2,h/2))
                partner=[q for q in holes if q.symmetric_difference(image).area<max(4.,water.area*.05)]
                if partner and not partner[0].equals(water):water=unary_union([water,partner[0]])
    # Solid building islands and exterior boundary give rooms and corridors
    # real occlusion. Open courtyards remain roofless; selected side rooms get
    # ceilings at runtime, never across the stair entrances.
    for p in polygons(architecture_floor):
        walls(Polygon(p.exterior),0,street_height,'quay_edge' if sea else 'wall')
        for hole in p.interiors:
            island=Polygon(hole);basin=not water.is_empty and island.symmetric_difference(island.intersection(water)).area<1.
            walls(island,0,.45 if basin else street_height,'wall')
    coastal_margin=border.difference(unary_union([Polygon(p.exterior) for p in polygons(architecture_floor)])).intersection(box(w*.76,-h,w*2,h*2)) if sea else Polygon()
    buildings=border.difference(architecture_floor).difference(water).difference(coastal_margin)
    # Individually supported building lots. Disjoint roofs, no stacked coplanar
    # roof sheets. Only the taller neighbour owns each internal step face.
    lots={}
    for ix in range(math.floor(-ox/12),math.ceil(ox/12)):
        for iz in range(math.floor(-oz/12),math.ceil(oz/12)):
            lot=buildings.intersection(box(ix*12+ox,iz*12+oz,(ix+1)*12+ox,(iz+1)*12+oz))
            if lot.is_empty:continue
            extra=[0.,.65,1.3,2.1][abs(ix*17+iz*37+(plan['id']-1)*11)%4]
            if not indoor:
                # Whole storeys; half-turn partner lots (-1-ix,-1-iz) share a height.
                cx,cz=min((ix,iz),(-1-ix,-1-iz))
                extra=clear_top(lot,street_height+[0.,0.,STOREY][abs(cx*17+cz*37+(plan['id']-1)*11)%3])-wall_height
            # A clipping remainder is not a separate tall building. Keep very
            # narrow roof lots at their parent wall height instead of extruding
            # a freestanding blade above neighbouring roofs.
            if lot.buffer(-.30).is_empty:extra=0.
            lots[ix,iz]=(lot,wall_height+extra)
            eave=Polygon()
            if not indoor and abs(ix*17+iz*37+(plan['id']-1)*11)%5<3:
                eave=lot.buffer(.4,join_style=2).difference(buildings).intersection(architecture_floor)
                if not eave.is_empty:
                    face(eave,[0,0,wall_height+extra-.16],'soffit',False)
                    walls(eave,wall_height+extra-.16,wall_height+extra,'eave_edge')
            face(lot.union(eave),[0,0,wall_height+extra],'roof',False)
    waterfront=[]
    for (ix,iz),(lot,top) in lots.items():
        for poly in polygons(lot):
            for ring in rings(poly):
                for a,b in zip(ring,ring[1:]):
                    mid=((a[0]+b[0])*.5,(a[1]+b[1])*.5)
                    # Street faces already have a ground wall up to street
                    # height; faces on water (or any other open edge) run down
                    # to the bed so buildings never hover.
                    low=street_height if architecture_floor.boundary.distance(Point(mid))<.05 else -1.2
                    if low<0 and not water.is_empty and water.boundary.distance(Point(mid))<.05:
                        waterfront.append((a,b,top,(ix*131+iz*7)%9973))
                    for neighbour in [(ix-1,iz),(ix+1,iz),(ix,iz-1),(ix,iz+1)]:
                        if neighbour in lots and lots[neighbour][0].distance(Point(mid))<.001:
                            low=max(low,lots[neighbour][1])
                    if top<=low+.001:continue
                    # Roofs are split at terrain slope changes. Their fascia
                    # must use the same planes, not interpolate across a hill:
                    # doing so leaves sky gaps and overlapping diagonal strips.
                    for region,offset in bands:
                        segment=LineString([a,b]).intersection(region)
                        if segment.is_empty or segment.geom_type!='LineString':continue
                        u,v=list(segment.coords)[0],list(segment.coords)[-1]
                        uy=offset[0]*(u[0]-ox)+offset[1]*(u[1]-oz)+offset[2]
                        vy=offset[0]*(v[0]-ox)+offset[1]*(v[1]-oz)+offset[2]
                        emit([(u[0],low+uy,u[1]),(v[0],low+vy,v[1]),(u[0],top+uy,u[1])],'wall')
                        emit([(v[0],low+vy,v[1]),(v[0],top+vy,v[1]),(u[0],top+uy,u[1])],'wall')
    water_y=min([terrain_y(x,z) for q in polygons(water) for x,z in q.exterior.coords],default=0.)-.35 if not water.is_empty else -.35
    if not water.is_empty:
        face(water,[0,0,water_y-(4.5 if sea else .55)],'waterbed',not sea)
        face(water,[0,0,water_y],'water',False)
    if sea:
        face(box(-w*2,-h*2,w*3,h*3).difference(border).union(coastal_margin),[0,0,water_y],'water',False)
    walls(border,0,max(7.2,street_height+STOREY),'perimeter')
    flush_faces()
    def centered(p):return [round(p[0]-ox,4),round(p[1]-oz,4)]
    routes=unary_union([LineString(path) for path in plan['paths']])
    doors=[]
    for path in plan['paths']:
        for start,end in zip(path,path[1:]):
            dx,dz=end[0]-start[0],end[1]-start[1];distance=math.hypot(dx,dz)
            if distance<12:continue
            x,z=(start[0]+end[0])*.5,(start[1]+end[1])*.5
            if any(math.dist((x,z),q)<11 for q in plan['spawns']+plan['targets']):continue
            if any(math.dist((x-ox,z-oz),q[:2])<22 for q in doors):continue
            if (not upper.is_empty and upper.distance(Point(x,z))<5) or (not lower.is_empty and lower.distance(Point(x,z))<5):continue
            nx,nz=dz/distance,-dx/distance
            cross=LineString([(x-nx*12,z-nz*12),(x+nx*12,z+nz*12)])
            cut=floor.intersection(cross)
            lines=[cut] if cut.geom_type=='LineString' else list(getattr(cut,'geoms',[]))
            chosen=next((line for line in lines if line.geom_type=='LineString' and line.distance(Point(x,z))<.001),None)
            if chosen is None or not 4.5<chosen.length<18:continue
            ends=list(chosen.coords);left=math.dist((x,z),ends[0]);right=math.dist((x,z),ends[-1])
            if min(left,right)<2.:continue
            if max(terrain_y(x+nx*s,z+nz*s) for s in [-left,0,right])-min(terrain_y(x+nx*s,z+nz*s) for s in [-left,0,right])>.04:continue
            doors.append([*centered((x,z)),terrain_y(x,z),math.atan2(dx,dz),left,right])
            if len(doors)>=3:break
        if len(doors)>=3:break
    def near_door(x,z,padding):
        for door in doors:
            dx,dz=x-ox-door[0],z-oz-door[1];yaw=door[3]
            across=math.cos(yaw)*dx-math.sin(yaw)*dz
            along=math.sin(yaw)*dx+math.cos(yaw)*dz
            if abs(along)<padding and -door[4]-padding<across<door[5]+padding:return True
        return False
    props=[];prop_candidates=[]
    for x in range(6,int(w)-6,4):
        for z in range(6,int(h)-6,4):
            point=Point(x,z)
            if plan['id']==32 and abs(x-ox)<44 and abs(z-oz)<48:continue
            if not floor.contains(point.buffer(1.8)) or near_door(x,z,2.5):continue
            if max(terrain_y(x+dx,z+dz) for dx,dz in [(-2,-2),(2,2)])-min(terrain_y(x+dx,z+dz) for dx,dz in [(-2,-2),(2,2)])>.05:continue
            if routes.distance(point)<3.2:continue
            if not upper.is_empty and upper.distance(point)<3:continue
            if not lower.is_empty and lower.distance(point)<3:continue
            if min(math.dist((x,z),p) for p in plan['spawns']+plan['targets'])<7:continue
            prop_candidates.append((x,z))
    # Stable spatial shuffle prevents every budgeted prop ending up on the west
    # side just because the old scan iterated x before z.
    prop_candidates.sort(key=lambda p:((int(p[0])*73856093)^(int(p[1])*19349663)^(plan['id']*83492791))%2147483647)
    vehicles=[];vehicle_clearance=[]
    road_rosters={0:['flatbed','tanker','delivery'],1:['crane','tow','flatbed'],2:['tanker','dump','flatbed'],4:['utility','box','pickup'],5:['compact','estate','delivery'],6:['taxi','minibus','van'],7:['hatch','sedan','taxi'],8:['tow','pickup','van'],9:['compact','hatch'],13:['reefer','box','delivery'],15:['refuse','flatbed'],17:['van','reefer','pickup'],18:['dump','crane'],19:['utility','flatbed'],21:['pickup','van'],23:['tow','crane'],25:['dump','tanker'],28:['utility','ambulance','fire']}
    if False and plan['id']-1 in road_rosters:  # 1.4: no parked vehicles
        names=road_rosters[plan['id']-1]
        roster=[next(a for a in transport if a['name']=='vehicle_'+name) for name in names]
        for ordinal in range(3 if plan['capacity']>=16 else 2):
            asset=roster[ordinal%len(roster)]
            radius=math.hypot(asset['length_m'],asset['width_m'])*.5+.35
            for x,z in prop_candidates:
                pt=Point(x,z)
                if not floor.contains(pt.buffer(radius)) or near_door(x,z,radius+.5):continue
                if routes.distance(pt)<radius+1.:continue
                if any(math.hypot(x-q[0],z-q[1])<radius+q[2]+1. for q in vehicle_clearance):continue
                if abs(terrain_y(x-radius,z-radius)-terrain_y(x+radius,z+radius))>.05:continue
                vehicles.append([*centered((x,z)),terrain_y(x,z),0.,asset['name']]);vehicle_clearance.append((x,z,radius));break
    # 1.4 regular maps are half-turn symmetric: cover props, trees and loose
    # objects are placed in partner pairs so neither team gets extra cover.
    symmetric=plan['id']-1<19
    candidate_set=set(prop_candidates)
    def partner(q):return (w-q[0],h-q[1])
    def canonical(q):return (q[1],q[0])<(partner(q)[1],partner(q)[0])
    for p in prop_candidates:
        if symmetric and (not canonical(p) or partner(p) not in candidate_set):continue
        pair_points=[p,partner(p)] if symmetric else [p]
        if any(any(math.dist(r,q[:2])<q[2]+2. for q in vehicle_clearance) for r in pair_points):continue
        if any(any(math.dist(r,q)<6 for q in props) for r in pair_points):continue
        if symmetric and math.dist(p,partner(p))<6:continue
        props.extend(pair_points)
        if len(props)>=min(56,plan['capacity']*3):break
    trees=[]
    if not indoor:
        def tree_ok(q):
            if not room_ceilings.is_empty and room_ceilings.distance(Point(q))<3.2:return False
            if not floor.contains(Point(q).buffer(3.2)):return False
            if any(math.dist(q,r)<5.5 for r in props+trees):return False
            return not any(math.dist(q,r[:2])<r[2]+4 for r in vehicle_clearance)
        for p in prop_candidates:
            if symmetric:
                if not canonical(p) or math.dist(p,partner(p))<5.5 or not tree_ok(p) or not tree_ok(partner(p)):continue
                trees.extend([p,partner(p)])
            else:
                if not tree_ok(p):continue
                trees.append(p)
            if len(trees)>=min(18,plan['capacity']):break
    # Small movable objects use a separate, less restrictive edge allowance.
    # They are kept out of the central route, spawns, objectives and ramps.
    loose=[]
    for x in range(4,int(w)-4,4):
        for z in range(4,int(h)-4,4):
            point=Point(x,z)
            if plan['id']==32 and abs(x-ox)<44 and abs(z-oz)<48:continue
            if not floor.contains(point.buffer(.9)) or near_door(x,z,1.5):continue
            if abs(terrain_y(x+.8,z+.8)-terrain_y(x-.8,z-.8))>.05:continue
            if routes.distance(point)<min(3.,plan['corridor_m']*.28):continue
            if min(math.dist((x,z),p) for p in plan['spawns']+plan['targets'])<9:continue
            if (not upper.is_empty and upper.distance(point)<2) or (not lower.is_empty and lower.distance(point)<2):continue
            if any(math.dist((x,z),p)<3.5 for p in props+trees+loose):continue
            if any(math.dist((x,z),q[:2])<q[2]+1. for q in vehicle_clearance):continue
            if symmetric:
                m=partner((x,z))
                if not canonical((x,z)) or math.dist((x,z),m)<3.5 or any(math.dist(m,q)<3.5 for q in props+trees+loose):continue
                if not floor.contains(Point(m).buffer(.9)) or near_door(m[0],m[1],1.5):continue
                loose.extend([(x,z),m])
            else:loose.append((x,z))
            if len(loose)>=12:break
        if len(loose)>=12:break
    facades=[]
    for poly in polygons(architecture_floor):
        for ring in rings(poly):
            for a,b in zip(ring,ring[1:]):
                length=math.dist(a,b)
                if length<7:continue
                x,z=(a[0]+b[0])/2,(a[1]+b[1])/2
                # Seaward quay edges are knee-high, not building facades.
                if sea and ring==list(poly.exterior.coords) and x>w*.76:continue
                if not water.is_empty and water.boundary.distance(Point(x,z))<.01:continue
                dx,dz=(b[0]-a[0])/length,(b[1]-a[1])/length
                nx,nz=-dz,dx
                if not floor.contains(Point(x+nx*.3,z+nz*.3)):nx,nz=-nx,-nz
                # Front detail is clipped to the wall, never across an entrance.
                facades.append([*centered((x,z)),math.atan2(nx,nz),min(6,length-1)])
    # 1.4 facade fronts: every street-facing wall, split on the 12 m lot grid so
    # each piece belongs to one building (height, colour and style per lot).
    # [x0,z0,x1,z1,y0,y1,from,top,lot,flags]; flags 1 = inside a covered room.
    fronts=[]
    def lot_top(x,z):
        key=(math.floor((x-ox)/12),math.floor((z-oz)/12))
        return (lots[key][1] if key in lots else street_height),key
    for poly in polygons(architecture_floor):
        exterior=list(poly.exterior.coords)
        for ring in rings(poly):
            for a,b in zip(ring,ring[1:]):
                length=math.dist(a,b)
                if length<.8:continue
                cuts={0.,1.}
                for axis,o in [(0,ox),(1,oz)]:
                    lo,hi=sorted([a[axis],b[axis]])
                    for k in range(math.floor((lo-o)/12)+1,math.ceil((hi-o)/12)):
                        t=(o+k*12-a[axis])/(b[axis]-a[axis]);cuts.add(min(1.,max(0.,t)))
                cuts=sorted(cuts)
                for t0,t1 in zip(cuts,cuts[1:]):
                    u=(a[0]+(b[0]-a[0])*t0,a[1]+(b[1]-a[1])*t0);v=(a[0]+(b[0]-a[0])*t1,a[1]+(b[1]-a[1])*t1)
                    piece=math.dist(u,v)
                    if piece<.8:continue
                    x,z=(u[0]+v[0])*.5,(u[1]+v[1])*.5
                    if sea and ring==exterior and x>w*.76:continue
                    if not water.is_empty and water.boundary.distance(Point(x,z))<.01:continue
                    dx,dz=(v[0]-u[0])/piece,(v[1]-u[1])/piece;nx,nz=-dz,dx
                    if not floor.contains(Point(x+nx*.3,z+nz*.3)):nx,nz=-nx,-nz
                    # Orient every front so its normal (left of u->v) faces the street.
                    if (v[0]-u[0])*nz-(v[1]-u[1])*nx<0:u,v=v,u
                    top,key=lot_top(x-nx*.4,z-nz*.4)
                    if indoor:top=wall_height
                    inside=not room_ceilings.is_empty and room_ceilings.buffer(.05).contains(Point(x+nx*.3,z+nz*.3))
                    near_deck=not upper.is_empty and upper.distance(Point(x,z))<3.5
                    fronts.append([*centered(u),*centered(v),round(terrain_y(*u),4),round(terrain_y(*v),4),0.,round(top,4),(key[0]*131+key[1]*7)%9973,(1 if inside else 0)|(4 if near_deck else 0)])
    # Houses rising straight out of a canal/harbour basin (flag 8).
    for a,b,top,code in waterfront:
        x,z=(a[0]+b[0])*.5,(a[1]+b[1])*.5;length=math.dist(a,b)
        if length<.8:continue
        dx,dz=(b[0]-a[0])/length,(b[1]-a[1])/length;nx,nz=-dz,dx
        if not water.buffer(.2).contains(Point(x+nx*.3,z+nz*.3)):a,b=b,a
        fronts.append([*centered(a),*centered(b),round(terrain_y(*a),4),round(terrain_y(*b),4),0.,round(top,4),code,8])
    # Upper walls over covered rooms (above their street openings).
    for room,top in room_tops:
        for ring in rings(room):
            for a,b in zip(ring,ring[1:]):
                x,z=(a[0]+b[0])*.5,(a[1]+b[1])*.5
                if math.dist(a,b)<.8 or architecture_floor.boundary.distance(Point(x,z))<.02:continue
                dx,dz=(b[0]-a[0])/math.dist(a,b),(b[1]-a[1])/math.dist(a,b);nx,nz=-dz,dx
                if room.contains(Point(x+nx*.3,z+nz*.3)):a,b=b,a
                fronts.append([*centered(a),*centered(b),round(terrain_y(*a),4),round(terrain_y(*b),4),wall_height,round(top,4),int(abs(x*13+z*7))%9973,2|(4 if not upper.is_empty and upper.distance(Point(x,z))<3.5 else 0)])
    # A new descending entrance may cut through a former ground objective.
    # Move that objective onto nearby clear ground, never leave it in a hole.
    def safe_target(point):
        p=Point(point)
        if not floor.contains(p.buffer(1.2)):return False
        for surface in surfaces:
            if surface['layer']!='upper':continue
            local=Point(point[0]-ox,point[1]-oz)
            if Polygon(surface['rings'][0],surface['rings'][1:]).contains(local):
                a,b,c=surface['plane'];height=a*local.x+b*local.y+c
                if .28<height<2.1:return False
        return True
    targets=[]
    for target in plan['targets']:
        candidates=[target]+[(target[0]+radius*math.cos(angle*math.tau/32),target[1]+radius*math.sin(angle*math.tau/32)) for radius in range(1,21) for angle in range(32)]
        targets.append(next(p for p in candidates if safe_target(p)))
    supports=[]
    if plan['id']!=32 and plan['upper_path']:
        line=LineString(plan['upper_path']);height=plan.get('upper_height',4.2)
        run=min(abs(height)*3.5,line.length*.33);deck_width=max(2.7,plan['corridor_m']*.70)
        for distance in range(6,int(line.length)-5,9):
            top=height*min(1,distance/run,(line.length-distance)/run)
            if top<3.2:continue
            p=line.interpolate(distance);q=line.interpolate(min(line.length,distance+.2));dx,dz=q.x-p.x,q.y-p.y
            size=math.hypot(dx,dz)
            if size<.001:continue
            nx,nz=-dz/size,dx/size
            for side in [-1,1]:
                x,z=p.x+side*nx*deck_width*.43,p.y+side*nz*deck_width*.43
                if not floor.contains(Point(x,z).buffer(.35)):continue
                if not upper.contains(Point(x,z).buffer(.18)):continue
                if min(math.dist((x,z),v) for v in plan['spawns']+targets)<5:continue
                deck_heights=[]
                for surface in surfaces:
                    if surface['layer']!='upper':continue
                    rr=surface['rings'];point=Point(x-ox,z-oz)
                    if Polygon(rr[0],rr[1:]).covers(point):
                        a,b,c=surface['plane'];deck_heights.append(a*(x-ox)+b*(z-oz)+c)
                base=terrain_y(x,z)
                if not deck_heights:continue
                actual_top=min(deck_heights)-.04
                if actual_top-base<.75:continue
                supports.append([*centered((x,z)),round(actual_top,4),round(base,4)])
    boats=[];boat_clearance=[]
    if not water.is_empty:
        roster=[a for a in transport if a['category']==('sea' if sea else 'river')]
        candidates=[(x,z) for x in range(4,int(w)-4,5) for z in range(4,int(h)-4,5)]
        for ordinal in range(3):
            asset=roster[(plan['id']+ordinal)%len(roster)]
            radius=math.hypot(asset['length_m'],asset['width_m'])*.55
            for x,z in candidates:
                if not water.contains(Point(x,z).buffer(radius+.5)):continue
                if any(math.hypot(x-q[0],z-q[1])<radius+q[2]+1. for q in boat_clearance):continue
                depth=.50 if asset['length_m']<6 else .85
                boats.append([*centered((x,z)),water_y-depth*.32,0.,asset['name']]);boat_clearance.append((x,z,radius));break
    def prop_anchor(p):
        boundary=floor.boundary
        nearest=boundary.interpolate(boundary.project(Point(p)))
        # Face away from the nearest wall; the back never points into the lane.
        yaw=math.atan2(nearest.x-p[0],nearest.y-p[1])
        return [*centered(p),terrain_y(*p),round(yaw,5)]
    ceiling_lights=[]
    for room in polygons(room_ceilings):
        anchor=room.representative_point()
        ceiling_lights.append([anchor.x-ox,terrain_y(anchor.x,anchor.y)+wall_height,anchor.y-oz])
    supported_facades=[]
    for f in facades:
        heights=[terrain_y(f[0]+ox+math.cos(f[2])*x,f[1]+oz-math.sin(f[2])*x) for x in [-2.7,-1.35,0.,1.35,2.7]]
        # Keep both glazing and trim above the uphill pavement and below the wall top.
        if max(heights)-min(heights)>.60:continue
        supported_facades.append(f+[min(heights)])
    data={'index':plan['id']-1,'name':plan['name'],'dimensions':[w,h],'room_ceiling_lights':ceiling_lights,
          'rectangle':plan['rectangle'],'removed_sliver_islands':removed_slivers,'surfaces':surfaces,'groups':[{'kind':key[2],'origin':[key[0]*24+12,0,key[1]*24+12],'vertices':v} for key,v in groups.items()],
          'border':[[centered(p) for p in ring] for ring in rings(max(polygons(border),key=lambda p:p.area))],
          'spawns':[centered(p) for p in plan['spawns']], 'targets':[centered(p) for p in targets],
          'goals':goals,'corridor_m':plan['corridor_m'],'capacity':plan['capacity'],
          # Keep the whole window below a sloped wall's lowest top edge.
          'props':[prop_anchor(p) for p in props], 'trees':[[*centered(p),terrain_y(*p)] for p in trees], 'ceiling_height':wall_height if indoor else 0., 'loose_props':[[*centered(p),terrain_y(*p)] for p in loose], 'facades':supported_facades,'fronts':fronts,'street_height':street_height,'storey':STOREY,'supports':supports,
          'terrain':terrain,'elevated_crossing':plan.get('elevated_crossing',False),
          'spawn_heights':[terrain_y(*p) for p in plan['spawns']], 'target_heights':[terrain_y(*p) for p in targets],
          'water':[[centered(p) for p in q.exterior.coords] for q in polygons(water)] if not water.is_empty else [],
          'vehicles':vehicles,'boats':boats,'doors':doors,'water_kind':'sea' if sea else 'river','water_height':water_y,
          'water_boat':centered((water.representative_point().x,water.representative_point().y)) if not water.is_empty else []}
    (OUT/('map_%02d.json'%data['index'])).write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    (OUT/('map_%02d.json.gz'%data['index'])).write_bytes(gzip.compress(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode('utf-8'),mtime=0))
    preview={k:v for k,v in data.items() if k!='groups'}
    preview['triangles']={key:[] for key in ['ground','upper','lower']}
    for surface in surfaces:
        poly=Polygon(surface['rings'][0],surface['rings'][1:]).buffer(0)
        for tri in triangles(poly):preview['triangles']['lower' if surface['layer']=='waterbed' else surface['layer']].extend(tri)
    (OUT/('plan_%02d.json'%data['index'])).write_text(json.dumps(preview,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    print(data['index'],data['name'],len(surfaces),'surfaces',len(groups),'tiles')
