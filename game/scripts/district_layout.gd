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
static func build(a:Node,index:int):
	var plan=read_plan(index)
	a.bounds=Vector2(plan.dimensions[0],plan.dimensions[1])*.5;a.vertical_map=true;a.has_water=false;a.indoors=index in CombatLayout.INDOOR
	a.set_meta("district_spawns",[Vector2(plan.spawns[0][0],plan.spawns[0][1]),Vector2(plan.spawns[1][0],plan.spawns[1][1])])
	a.set_meta("district",true);a.set_meta("night",index in [4,15,23,28,30])
	if not plan.get("water",[]).is_empty():
		a.has_water=true;a.set_meta("district_water",ring(plan.water[0]))
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
		if a.point_clear(pos) and a.point_clear(pos+Vector3(2,0,1)):a.crate(pos,Vector3(2.6,1.25,1.8))
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
