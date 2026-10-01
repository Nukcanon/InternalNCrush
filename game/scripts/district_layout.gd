extends RefCounted
class_name DistrictLayout
static var specs=[]
static func route_spec(index:int) -> Dictionary:
	if specs.is_empty():specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/arenas/district_specs.json"))
	var source=specs[index];var origin=Vector2(source.dimensions[0],source.dimensions[1])*.5
	var points=[];var links=[]
	for p in source.spawns+source.targets:points.append(Vector2(p[0],p[1])-origin)
	for path in source.paths:
		var previous=-1
		for p in path:
			var point=Vector2(p[0],p[1])-origin;var id=points.find(point)
			if id<0:id=points.size();points.append(point)
			if previous>=0:links.append([previous,id])
			previous=id
	var radii=[]
	for point in points:radii.append(Vector2.ONE*source.corridor_m*.5)
	return {"points":points,"links":links,"radii":radii,"rooms":points.size(),"lane_width":source.corridor_m*.5,"size":origin,"indoor":false,"night":index in [23,28,30],"style":index-19}
# Immutable polygon data is compiled once, then ArenaCache stores the complete
# scene and navigation graph. No polygon construction runs during a match.
static func read_plan(index:int) -> Dictionary:
	var path="res://assets/arenas/districts/map_%02d.json"%index
	if FileAccess.file_exists(path):return JSON.parse_string(FileAccess.get_file_as_string(path))
	return JSON.parse_string(FileAccess.get_file_as_bytes(path+".gz").decompress_dynamic(32*1024*1024,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
# 1.4.5: maps whose main street ran straight from spawn to spawn (the enemy
# base in view from the first second; tools/audit_spawn_los.gd). A staggered
# pair of screen walls across the street in front of each spawn breaks the
# line of sight while leaving a path round either end.
const SPAWN_SCREENS=[0,1,2,3,5,6,7,8,10,12,13,14,15,16,17,18,25,26,27,28,29]
const SCREEN_DISTANCE=11.
const SCREEN_HEIGHT=3.2
static func lane_extent(plan:Dictionary,at:Vector2,right:Vector2) -> Array:
	# The walkable street across `at` along `right`: contiguous ground around 0.
	var grounds=[]
	for source in plan.surfaces:
		if source.layer!="ground":continue
		var polys=[]
		for points in source.rings:polys.append(ring(points))
		grounds.append(polys)
	var inside=func(p:Vector2) -> bool:
		for polys in grounds:
			if Geometry2D.is_point_in_polygon(p,polys[0]):
				var hole=false
				for k in range(1,polys.size()):
					if Geometry2D.is_point_in_polygon(p,polys[k]):hole=true;break
				if not hole:return true
		return false
	if not inside.call(at):return []
	var lo=0.;var hi=0.
	while lo>-14. and inside.call(at+right*(lo-.25)):lo-=.25
	while hi<14. and inside.call(at+right*(hi+.25)):hi+=.25
	# ...clipped by the nearest walls crossing the line at chest height (the
	# ground polygon can run on under rooms beside the street).
	var a2=at+right*lo;var b2=at+right*hi
	for group in plan.groups:
		if str(group.kind) not in ["wall","perimeter","quay_edge","tunnel"]:continue
		var v:Array=group.vertices
		for i in range(0,v.size(),3):
			var ys=[float(v[i][1]),float(v[i+1][1]),float(v[i+2][1])]
			if ys.min()>1.5 or ys.max()<1.5:continue
			var pts=[Vector2(float(v[i][0]),float(v[i][2])),Vector2(float(v[i+1][0]),float(v[i+1][2])),Vector2(float(v[i+2][0]),float(v[i+2][2]))] # plan vertices are world coordinates
			for e in range(3):
				var p=pts[e];var q=pts[(e+1)%3]
				if p.distance_to(q)<.05:continue
				var x=Geometry2D.segment_intersects_segment(a2,b2,p,q)
				if x==null:continue
				var s=(Vector2(x)-at).dot(right)
				if s<0.:lo=maxf(lo,s)
				elif s>0.:hi=minf(hi,s)
	return [lo,hi]
static func spawn_screens(a:Node,plan:Dictionary,index:int):
	if not index in SPAWN_SCREENS or plan.spawns.size()<2:return
	for team in range(2):
		var here=Vector2(plan.spawns[team][0],plan.spawns[team][1]);var there=Vector2(plan.spawns[1-team][0],plan.spawns[1-team][1])
		var dir=(there-here).normalized();var right=Vector2(-dir.y,dir.x)
		var ground_y=float(plan.get("spawn_heights",[0,0])[team])
		var lane=[Vector3(here.x+dir.x*(SCREEN_DISTANCE-4.),ground_y,here.y+dir.y*(SCREEN_DISTANCE-4.))]
		for k in range(2):
			var at=here+dir*(SCREEN_DISTANCE+k*5.)
			var span=lane_extent(plan,at,right)
			if span.is_empty():continue
			var lo=float(span[0]);var hi=float(span[1])
			# The gap must stay open a few metres before and after the screen too
			# (a corridor edge stepping in just past it made the gap a dead end).
			for ahead in [-2.5,2.5]:
				var other=lane_extent(plan,at+dir*ahead,right)
				if other.is_empty():continue
				lo=maxf(lo,float(other[0]));hi=minf(hi,float(other[1]))
			var width=hi-lo
			if width<3.:continue
			# Each screen covers 62% of the street from one side; the two leave
			# their gaps on opposite sides, so there is no straight view through.
			# (never narrower than a 3.4 m gap: on the narrow indoor streets the
			# bot grid lost the route through)
			var cover=minf(width*.62,width-3.4)
			if cover<1.5:continue
			var s0=lo if k==0 else hi-cover;var s1=lo+cover if k==0 else hi
			# The gap beside this screen, for the bots' lane through (below).
			var gap_s=(s1+hi)*.5 if k==0 else (lo+s0)*.5
			lane.append(Vector3(at.x+right.x*gap_s,ground_y,at.y+right.y*gap_s))
			var centre=at+right*((s0+s1)*.5)
			var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;a.architecture.add_child(body)
			# Local +x along `right`: Basis(UP,t)*(1,0,0) = (cos t,0,-sin t).
			body.position=Vector3(centre.x,ground_y+SCREEN_HEIGHT*.5,centre.y);body.rotation.y=atan2(-right.y,right.x)
			var size=Vector3(s1-s0,SCREEN_HEIGHT,.6)
			var mesh=MeshInstance3D.new();var box=BoxMesh.new();box.size=size;mesh.mesh=box
			mesh.material_override=WorldSurface.material("wall",index,false,team);body.add_child(mesh)
			var cap=MeshInstance3D.new();var cap_box=BoxMesh.new();cap_box.size=Vector3(size.x+.2,.16,.8);cap.mesh=cap_box;cap.position.y=SCREEN_HEIGHT*.5;cap.material_override=WorldSurface.material("trim",index);body.add_child(cap)
			var shape=CollisionShape3D.new();var bs=BoxShape3D.new();bs.size=size;shape.shape=bs;body.add_child(shape)
			# Bot navigation: district maps block cells by navigation_blocks (AABB,
			# see Arena.navigation_clear); the footprint's bounding box, grown by
			# half a capsule as Arena.box does for obstacles.
			var r=Rect2(centre,Vector2.ZERO)
			for sx in [-1.,1.]:
				for sz in [-1.,1.]:r=r.expand(centre+right*(sx*size.x*.5)+dir*(sz*size.z*.5))
			a.obstacles.append(r.grow(.6))
			# (ungrown: navigation_clear adds its own half-metre margin, and the
			# 2 m grid must keep a cell centre inside the gap beside the screen)
			a.navigation_blocks.append(AABB(Vector3(r.position.x,ground_y-.1,r.position.y),Vector3(r.size.x,SCREEN_HEIGHT+.2,r.size.y)))
		if lane.size()>1:
			lane.append(Vector3(here.x+dir.x*(SCREEN_DISTANCE+9.),ground_y,here.y+dir.y*(SCREEN_DISTANCE+9.)))
			var lanes:Array=a.get_meta("screen_lanes",[]);lanes.append(lane);a.set_meta("screen_lanes",lanes)
static func build(a:Node,index:int):
	var plan=read_plan(index)
	a.bounds=Vector2(plan.dimensions[0],plan.dimensions[1])*.5;a.vertical_map=true;a.has_water=false;a.indoors=index in CombatLayout.INDOOR
	a.set_meta("district_spawns",[Vector2(plan.spawns[0][0],plan.spawns[0][1]),Vector2(plan.spawns[1][0],plan.spawns[1][1])])
	a.set_meta("district",true);a.set_meta("night",index in [4,15,23,28,30])
	if not plan.get("water",[]).is_empty():
		a.has_water=true;a.set_meta("district_water",ring(plan.water[0]))
		var basins=[]
		for points in plan.water:basins.append(ring(points))
		a.set_meta("district_waters",basins)
		a.set_meta("water_kind",plan.get("water_kind","river"));a.set_meta("water_height",float(plan.get("water_height",-.35)))
	a.playable_polygon=ring(plan.border[0]);a.district_surfaces=[]
	for source in plan.surfaces:
		var surface={"rings":[],"plane":Vector3(source.plane[0],source.plane[1],source.plane[2])}
		for points in source.rings:surface.rings.append(ring(points))
		var rect=Rect2(surface.rings[0][0],Vector2.ZERO)
		for point in surface.rings[0]:rect=rect.expand(point)
		surface.rect=rect;a.district_surfaces.append(surface)
	for group in plan.groups:
		var origin=Vector3(group.origin[0],0,group.origin[2])
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Flat normals avoid smoothing across unrelated triangles after indexing.
		for i in range(0,group.vertices.size(),3):
			var points=[]
			for k in range(3):
				var p=group.vertices[i+k];points.append(Vector3(p[0],p[1],p[2]))
			var normal=(points[2]-points[0]).cross(points[1]-points[0]).normalized()
			for point in points:st.set_normal(normal);st.add_vertex(point-origin)
		st.index();var mesh=st.commit()
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;a.architecture.add_child(body);body.position=origin
		var visual=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=WorldSurface.material(group.kind,index,false,(1 if origin.x>0 else 0)+(2 if origin.z>0 else 0));body.add_child(visual)
		if group.kind=="water":
			visual.material_override=WaterSurface.material(plan.get("water_kind","river")=="sea")
			visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if group.kind in ["water","stair_detail"]:continue
		var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(mesh.get_faces());shape.backface_collision=true;collision.shape=shape;body.add_child(collision)
	# Vertical fascia gives elevated paths visible thickness without changing cover.
	var edges=SurfaceTool.new();edges.begin(Mesh.PRIMITIVE_TRIANGLES);var edge_count=0
	for source in plan.surfaces:
		if source.layer!="upper":continue
		for points in source.rings:
			for i in range(points.size()-1):
				var p=points[i];var q=points[i+1]
				var v=Vector3(p[0],source.plane[0]*p[0]+source.plane[1]*p[1]+source.plane[2],p[1]);var w=Vector3(q[0],source.plane[0]*q[0]+source.plane[1]*q[1]+source.plane[2],q[1])
				if maxf(v.y,w.y)<.4:continue
				var normal=(w-v).cross(Vector3.DOWN).normalized()
				for point in [v,w,v+Vector3.DOWN*.18,w,w+Vector3.DOWN*.18,v+Vector3.DOWN*.18]:edges.set_normal(normal);edges.add_vertex(point)
				edge_count+=1
	if edge_count>0:
		edges.index();var fascia=MeshInstance3D.new();fascia.mesh=edges.commit();fascia.material_override=WorldSurface.material("trim",index);a.architecture.add_child(fascia)
	for team in range(2):
		var p=plan.spawns[team]
		for slot in range(16):
			var pos=Vector3(p[0]+(slot%4-1.5)*1.7,float(plan.get("spawn_heights",[0,0])[team])+.15,p[1]+(slot/4-1.5)*1.7)
			var floor_candidates=heights(a,pos)
			if not floor_candidates.is_empty():pos.y=float(floor_candidates[0])+.04
			if a.point_clear(pos):a.spawn_points[team].append(pos);a.ffa_spawns.append(pos)
		if a.spawn_points[team].is_empty():a.spawn_points[team].append(Vector3(p[0],float(plan.get("spawn_heights",[0,0])[team])+.15,p[1]))
	spawn_screens(a,plan,index)
	a.sites=[];a.zones=[]
	for i in range(plan.targets.size()):
		var point=plan.targets[i];a.zones.append(Vector3(point[0],float(plan.get("target_heights",[0,0,0])[i]),point[1]))
	a.sites=[a.zones[0],a.zones[1]]
	if a.zones.size()==2:
		# Select a real ground-floor route, not an arbitrary clear point in a
		# basement opening. Defusal layouts also supply capture-mode previews.
		var midpoint=(a.zones[0]+a.zones[1])*.5;var middle=a.zones[0];var best=INF
		route_spec(index)
		var spec=specs[index];var offset=Vector2(spec.dimensions[0],spec.dimensions[1])*.5
		for path in spec.paths:
			for i in range(path.size()-1):
				var start=Vector2(path[i][0],path[i][1])-offset;var end=Vector2(path[i+1][0],path[i+1][1])-offset
				var steps=maxi(1,ceili(start.distance_to(end)))
				for step in range(steps+1):
					var point=start.lerp(end,float(step)/steps);var candidate=Vector3(point.x,0,point.y)
					var possible=heights(a,candidate)
					if possible.is_empty():continue
					candidate.y=possible[0]
					var distance=candidate.distance_squared_to(midpoint)
					if distance>=best or not a.navigation_clear(candidate):continue
					var clear=true
					for side in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
						if not a.navigation_clear(candidate+side*1.2):clear=false;break
					if clear:middle=candidate;best=distance
		a.zones.insert(1,middle)
	for point in plan.goals:a.navigation_goals.append(Vector3(point[0],point[1],point[2]))
	# Grounded terraces have no old upper/lower ribbon midpoint. Include their
	# landings in roaming/navigation coverage as well as the combat objectives.
	if plan.get("terrain")!=null:
		var seen={};route_spec(index);var source=specs[index]
		for path in source.paths:
			for point in path:
				var candidate=Vector3(point[0]-a.bounds.x,0,point[1]-a.bounds.y)
				var values=heights(a,candidate)
				if values.is_empty():continue
				candidate.y=float(values[0]);var bucket=roundi(candidate.y)
				if absf(candidate.y)<1.5 or seen.has(bucket) or not a.point_clear(candidate):continue
				# Gate walls are added later by DistrictDressing; keep landings clear of them.
				if plan.get("doors",[]).any(func(door):return Vector2(door[0]-candidate.x,door[1]-candidate.z).length()<float(maxf(door[4],door[5]))+2.):continue
				# Roaming targets belong on broad landings, not clipped ramp edges.
				var landing=true
				for offset in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
					var nearby=heights(a,candidate+offset*.6)
					if nearby.is_empty() or absf(float(nearby[0])-candidate.y)>.04:landing=false;break
				if not landing:continue
				seen[bucket]=true;a.navigation_goals.append(candidate)
	a.navigation_goals.append_array(a.sites)
	DistrictDressing.build(a,plan)
	a.set_meta("sight_blockers",plan.groups.size())
	if DefusalLayout.enabled(index):
		a.set_meta("staging_center",Vector2(plan.spawns[0][0],plan.spawns[0][1]));a.set_meta("staging_z",plan.spawns[0][1]-7.)
	# Cover is placed against courtyard edges, never in the centre of a route.
	for goal in a.zones:
		var pos=goal+Vector3(4.2,0,3.8)
		var landing=a.navigation_goals.any(func(goal):return Vector2(goal.x-pos.x,goal.z-pos.z).length()<3.5 and absf(goal.y-pos.y)<2.)
		if not landing and a.point_clear(pos) and a.point_clear(pos+Vector3(2,0,1)):a.crate(pos,Vector3(2.6,1.25,1.8))
	validate_spawns(a)
static func validate_spawns(a:Node):
	# Dressing is added after candidate starts; reject starts covered by props.
	a.ffa_spawns.clear()
	for team in range(2):
		var clear=a.spawn_points[team].filter(func(pos):return a.point_clear(pos))
		if not clear.is_empty():a.spawn_points[team]=clear
		a.ffa_spawns.append_array(a.spawn_points[team])
static func ring(points:Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for point in points:result.append(Vector2(point[0],point[1]))
	return result
static func candidates(a:Node,point:Vector2) -> Array:
	if a.district_cells.is_empty():
		for surface in a.district_surfaces:
			for x in range(floori(surface.rect.position.x/8.),floori(surface.rect.end.x/8.)+1):
				for z in range(floori(surface.rect.position.y/8.),floori(surface.rect.end.y/8.)+1):
					var key=Vector2i(x,z)
					if not a.district_cells.has(key):a.district_cells[key]=[]
					a.district_cells[key].append(surface)
	return a.district_cells.get(Vector2i(floori(point.x/8.),floori(point.y/8.)),[])
static func heights(a:Node,pos:Vector3) -> Array:
	var result=[];var p=Vector2(pos.x,pos.z)
	for surface in candidates(a,p):
		if not surface.rect.grow(.001).has_point(p) or not Geometry2D.is_point_in_polygon(p,surface.rings[0]):continue
		var hole=false
		for i in range(1,surface.rings.size()):
			if Geometry2D.is_point_in_polygon(p,surface.rings[i]):hole=true;break
		if not hole:
			var plane:Vector3=surface.plane;var y=plane.x*p.x+plane.y*p.y+plane.z
			if not result.any(func(value):return absf(value-y)<.02):result.append(y)
	for surface in a.walk_surfaces:
		if surface.rect.has_point(p):result.append(lerpf(surface.low,surface.high,(p.y-surface.rect.position.y)/surface.rect.size.y))
	return result
static func clear(a:Node,pos:Vector3) -> bool:
	# Five samples keep capsules inside real corridors, including holes, and
	# prevent the navigation graph from crossing vertical balcony edges.
	for offset in [Vector3.ZERO,Vector3(.55,0,0),Vector3(-.55,0,0),Vector3(0,0,.55),Vector3(0,0,-.55)]:
		var samples=heights(a,pos+offset)
		if not samples.any(func(y):return absf(y-pos.y)<.28):return false
		for height in samples:
			if height>pos.y+.28 and height<pos.y+1.9:return false
	return true
