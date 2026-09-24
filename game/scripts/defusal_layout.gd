extends RefCounted
class_name DefusalLayout
# Original connected layouts: rooms and route graphs are authored separately.
# The geometry is carved from their union, so intersections never have stacked walls.
const FIRST=19
const LAST=30
static var geometry={}
const NAMES=["KASBAH · 성채 시장","REACTOR · 이중 원자로","VIADUCT · 고가 수로","ARCHIVE · 기록 보관소","SHIPBREAK · 해체 부두","MONASTERY · 언덕 수도원","FOUNDRY CORE · 용광로","GREENHOUSE · 유리 온실","METRO VAULT · 지하 금고","COASTGUARD · 해안 통제소","DATACENTER · 데이터 센터","CITADEL · 산성"]
static func enabled(index:int) -> bool:return index>=FIRST and index<=LAST
static func spec(index:int) -> Dictionary:
	var k=index-FIRST
	# node 0 = attack staging, 1 = defender spawn, 2/3 = objectives, remaining = junctions
	var points=[
		[Vector2(0,30),Vector2(0,-26),Vector2(-17,-12),Vector2(17,-16),Vector2(-18,12),Vector2(2,4),Vector2(19,10),Vector2(-3,-12)],
		[Vector2(0,30),Vector2(15,-25),Vector2(-12,-11),Vector2(12,-5),Vector2(-16,14),Vector2(1,8),Vector2(18,17),Vector2(0,-22)],
		[Vector2(0,32),Vector2(0,-28),Vector2(-20,-5),Vector2(18,-19),Vector2(-19,20),Vector2(0,11),Vector2(20,5),Vector2(-2,-12)],
		[Vector2(0,30),Vector2(0,-25),Vector2(-17,-16),Vector2(15,-16),Vector2(-15,15),Vector2(15,15),Vector2(0,2),Vector2(0,-13)],
		[Vector2(0,32),Vector2(-14,-27),Vector2(-18,-8),Vector2(19,-17),Vector2(-18,18),Vector2(10,13),Vector2(24,1),Vector2(-2,-8)],
		[Vector2(0,32),Vector2(0,-26),Vector2(-18,-17),Vector2(17,-9),Vector2(-20,12),Vector2(0,15),Vector2(18,16),Vector2(-4,-3)],
		[Vector2(0,36),Vector2(0,-32),Vector2(-24,-15),Vector2(23,-15),Vector2(-24,19),Vector2(0,10),Vector2(24,20),Vector2(0,-15),Vector2(-10,-3)],
		[Vector2(0,36),Vector2(17,-33),Vector2(-23,-21),Vector2(21,-7),Vector2(-23,21),Vector2(0,20),Vector2(23,24),Vector2(-1,-7),Vector2(-25,0)],
		[Vector2(0,36),Vector2(0,-32),Vector2(-23,-13),Vector2(23,-23),Vector2(-17,24),Vector2(13,10),Vector2(25,20),Vector2(-7,-5),Vector2(1,-22)],
		[Vector2(0,36),Vector2(-13,-32),Vector2(-24,-18),Vector2(23,-10),Vector2(-25,20),Vector2(-3,12),Vector2(25,24),Vector2(12,-13),Vector2(-6,-12)],
		[Vector2(0,36),Vector2(0,-32),Vector2(-21,-19),Vector2(21,-19),Vector2(-20,20),Vector2(0,8),Vector2(20,20),Vector2(-20,0),Vector2(20,0)],
		[Vector2(0,36),Vector2(0,-32),Vector2(-23,-5),Vector2(20,-24),Vector2(-25,23),Vector2(-3,16),Vector2(24,17),Vector2(-4,-8),Vector2(8,-22)]
	][k]
	var links=[
		[[0,4],[0,6],[4,2],[6,3],[4,5],[5,7],[7,2],[7,3],[1,2],[1,3]],
		[[0,4],[0,6],[4,2],[4,5],[5,3],[6,3],[2,7],[3,7],[7,1],[2,3]],
		[[0,4],[0,5],[0,6],[4,2],[5,7],[6,3],[7,2],[7,3],[2,1],[3,1]],
		[[0,4],[0,5],[4,2],[5,3],[4,6],[5,6],[6,7],[7,2],[7,3],[1,2],[1,3]],
		[[0,4],[0,5],[4,2],[5,6],[6,3],[4,7],[7,3],[7,2],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,2],[6,3],[5,7],[7,2],[7,3],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,2],[6,3],[5,8],[8,2],[5,7],[7,3],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,8],[8,2],[5,7],[7,2],[7,3],[6,3],[2,1],[3,1]],
		[[0,4],[0,6],[4,7],[7,2],[6,5],[5,3],[5,8],[8,2],[8,3],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,2],[6,3],[5,8],[8,2],[5,7],[7,3],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,7],[7,2],[6,8],[8,3],[5,7],[5,8],[2,1],[3,1]],
		[[0,4],[0,6],[0,5],[4,2],[5,7],[7,2],[6,3],[7,8],[8,3],[8,1],[2,1]]
	][k]
	return {"points":points,"links":links,"size":Vector2(32,40) if k<6 else Vector2(38,46),"indoor":k in [1,3,6,8,10],"night":k in [4,9,11],"style":k}
static func inside(p:Vector2,s:Dictionary) -> bool:
	var upper=s.points[3 if s.style in [1,8] or s.style%2==1 else 2]
	if Rect2(upper+Vector2(-4.,-6.),Vector2(6.,23.)).has_point(p):return true
	for i in range(s.points.size()):
		var radius=Vector2(10,7) if i==0 else Vector2(7,7) if i in [2,3] else Vector2(5,5)
		if Rect2(s.points[i]-radius,radius*2).has_point(p):return true
	for link in s.links:
		if Geometry2D.get_closest_point_to_segment(p,s.points[link[0]],s.points[link[1]]).distance_to(p)<3.5:return true
	return false
static func build(a:Node,index:int):
	var s=spec(index);a.bounds=s.size;a.indoors=s.indoor;a.has_water=false;a.vertical_map=true;a.set_meta("night",s.night)
	var wall=[Color("cab38d"),Color("91a9ae"),Color("b8b2a0"),Color("acb4af"),Color("86959b"),Color("c0b7a0"),Color("8f9e9b"),Color("a7bca8"),Color("93a7ae"),Color("91acba"),Color("bdc9c8"),Color("b7ad9b")][s.style]
	a.box(Vector3(0,-.4,0),Vector3(a.bounds.x*2,.8,a.bounds.y*2),Color("a2acaa"));a.build_perimeter(index)
	a.set_meta("route_spec",s);shell(a,index,wall)
	for i in range(s.points.size()):
		var point=Vector3(s.points[i].x,0,s.points[i].y)
		if i==0 or i==1:
			for slot in range(8):
				var spawn=point+Vector3((slot%4-1.5)*1.4,.15,(slot/4)*1.5);a.spawn_points[i].append(spawn);a.ffa_spawns.append(spawn)
		if i in [2,3]:
			a.container_box(point+Vector3(2.5,0,1),Color("608e90") if i==2 else Color("b06d57"),3.2)
			a.cover(point+Vector3(-3.5,0,-2.),2.4)
			a.text3d("A / "+NAMES[s.style].split(" · ")[0] if i==2 else "B / SERVICE",point+Vector3(0,4.3,0),Color("f5d48d"),40)
		elif i>3:
			a.crate(point+Vector3(2.8,0,-2.),Vector3(1.5,1.4,1.6))
			if s.style in [6,8,10]:a.pipe(point+Vector3(-3,3.7,0),.17,6.,Color("536e7b"),Vector3(PI/2,0,0))
	# Balconies use separate stairs and limited parapets, with two ground approaches below.
	var p=s.points[3 if s.style in [1,8] or s.style%2==1 else 2];var deck=Vector3(p.x-1.,4.2,p.y)
	VerticalLayout.deck(a,deck,Vector2(5.,10.),wall)
	VerticalLayout.stairs(a,deck+Vector3(0,-4.2,10.),Vector2(4.,10.),4.2,0.,Color("536e7b"))
	a.box(deck+Vector3(-2.35,.5,0),Vector3(.3,1.,9.5),wall)
	a.navigation_goals.append(deck)
	a.sites=[Vector3(s.points[2].x-1.,0,s.points[2].y-2.5),Vector3(s.points[3].x-1.,0,s.points[3].y-2.5)]
	if s.style in [1,8]:a.sites[1]=Vector3(s.points[3].x-1.,4.2,s.points[3].y-2.5)
	a.zones=[a.sites[0],Vector3(s.points[5].x,0,s.points[5].y),a.sites[1]]
	a.navigation_goals.append_array(a.sites)
	if a.indoors:a.box(Vector3(0,10.5,0),Vector3(a.bounds.x*2,.4,a.bounds.y*2),Color("586a76"))
	a.set_meta("staging_z",s.points[0].y-7.);a.set_meta("staging_center",s.points[0]);a.set_meta("sight_blockers",s.points.size())
	# Doors on readable auxiliary doorways; these never seal either main attack route.
	for side in [-1,1]:
		var point=Vector3(s.points[0].x+side*6.,0,s.points[0].y-6.)
		a.add_door(point)
	a.text3d("ATTACK STAGING",Vector3(s.points[0].x,3.4,s.points[0].y+5.),Color("79dbc4"),34)
static func shell(a:Node,index:int,color:Color):
	if geometry.is_empty():geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/arenas/defusal_geometry.json"))
	var plan=geometry[str(index)];var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in plan.walls:
		var left=Vector3(edge[0][0],0,edge[0][1]);var right=Vector3(edge[1][0],0,edge[1][1]);var up=Vector3.UP*6.8
		var delta=right-left;var n=Vector3(delta.z,0,-delta.x).normalized()
		for point in [left,right,left+up,right,right+up,left+up]:st.set_normal(n);st.add_vertex(point)
	for triangle in plan.roof:
		for point in triangle:st.set_normal(Vector3.UP);st.add_vertex(Vector3(point[0],6.8,point[1]))
	st.index();var mesh=st.commit();var body=StaticBody3D.new();a.architecture.add_child(body);body.collision_layer=1;body.collision_mask=0
	var visual=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=a.mat(color);body.add_child(visual)
	var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(mesh.get_faces());shape.backface_collision=true;collision.shape=shape;body.add_child(collision)
