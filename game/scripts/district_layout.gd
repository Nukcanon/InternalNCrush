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
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/arenas/districts/map_%02d.json"%index))
static func build(a:Node,index:int):
	var plan=read_plan(index)
	a.bounds=Vector2(plan.dimensions[0],plan.dimensions[1])*.5;a.vertical_map=true;a.has_water=false;a.indoors=index in CombatLayout.INDOOR
	a.set_meta("district_spawns",[Vector2(plan.spawns[0][0],plan.spawns[0][1]),Vector2(plan.spawns[1][0],plan.spawns[1][1])])
	a.set_meta("district",true);a.set_meta("night",index in [4,15,23,28,30])
	if not plan.get("water",[]).is_empty():a.has_water=true;a.set_meta("district_water",ring(plan.water[0]))
	a.playable_polygon=ring(plan.border[0]);a.district_surfaces=[]
	for source in plan.surfaces:
		var surface={"rings":[],"plane":Vector3(source.plane[0],source.plane[1],source.plane[2])}
		for points in source.rings:surface.rings.append(ring(points))
		var rect=Rect2(surface.rings[0][0],Vector2.ZERO)
		for point in surface.rings[0]:rect=rect.expand(point)
		surface.rect=rect;a.district_surfaces.append(surface)
	var palette=[Color("b8b0a0"),Color("91a4ab"),Color("b6a084"),Color("98aaa1")]
	for group in plan.groups:
		var origin=Vector3(group.origin[0],0,group.origin[2])
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in group.vertices:st.add_vertex(Vector3(point[0],point[1],point[2])-origin)
		st.generate_normals();st.index();var mesh=st.commit()
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;a.architecture.add_child(body);body.position=origin
		var visual=MeshInstance3D.new();visual.mesh=mesh
		var color=Color("c6ad8c") if index in [7,9,12,17,19,22,24,30] else palette[index%palette.size()]
		if group.kind=="ground":color=Color("858f8e")
		elif group.kind=="upper":color=Color("8ca0aa")
		elif group.kind in ["lower","tunnel"]:color=Color("6f858a")
		elif group.kind=="water":color=Color("397784")
		elif group.kind=="roof":color=Color("976956") if index in [7,9,12,17,19,22,24,30] else color.darkened(.2)
		visual.material_override=a.mat(color)
		if group.kind=="ceiling":
			visual.material_override=visual.material_override.duplicate();visual.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
		body.add_child(visual)
		if group.kind=="water":continue
		var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(mesh.get_faces());shape.backface_collision=true;collision.shape=shape;body.add_child(collision)
	for team in range(2):
		var p=plan.spawns[team]
		for slot in range(16):
			var pos=Vector3(p[0]+(slot%4-1.5)*1.7,.15,p[1]+(slot/4-1.5)*1.7)
			if a.point_clear(pos):a.spawn_points[team].append(pos);a.ffa_spawns.append(pos)
		if a.spawn_points[team].is_empty():a.spawn_points[team].append(Vector3(p[0],.15,p[1]))
	a.sites=[];a.zones=[]
	for point in plan.targets:a.zones.append(Vector3(point[0],0,point[1]))
	a.sites=[a.zones[0],a.zones[1]]
	if a.zones.size()==2:
		var middle=(a.zones[0]+a.zones[1])*.5;var found=a.point_clear(middle)
		for radius in range(2,61,2):
			if found:break
			for step in range(16):
				var candidate=middle+Vector3(cos(step*TAU/16.),0,sin(step*TAU/16.))*radius
				if a.point_clear(candidate):middle=candidate;found=true;break
		a.zones.insert(1,middle)
	for point in plan.goals:a.navigation_goals.append(Vector3(point[0],point[1],point[2]))
	a.navigation_goals.append_array(a.sites)
	DistrictDressing.build(a,plan)
	a.set_meta("sight_blockers",plan.groups.size())
	if DefusalLayout.enabled(index):
		a.set_meta("staging_center",Vector2(plan.spawns[0][0],plan.spawns[0][1]));a.set_meta("staging_z",plan.spawns[0][1]-7.)
	# Cover is placed against courtyard edges, never in the centre of a route.
	for goal in a.zones:
		var pos=goal+Vector3(4.2,0,3.8)
		if a.point_clear(pos) and a.point_clear(pos+Vector3(2,0,1)):a.crate(pos,Vector3(2.6,1.25,1.8))
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
