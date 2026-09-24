extends RefCounted
class_name WorldDressing
const M=preload("res://scripts/mesh_factory.gd")
const H=preload("res://scripts/human_model.gd")
const KINDS=["barrel","crate","cone","canister","tire"]
static func allowed(arena:Node,pos:Vector3,placed:Array) -> bool:
	if arena.has_meta("route_spec"):
		var routes=arena.get_meta("route_spec");var point=Vector2(pos.x,pos.z)
		# Preserve every authored approach, not merely one surviving route to a site.
		for link in routes.links:
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,routes.points[link[0]],routes.points[link[1]]))<2.:return false
	if arena.vertical_map:
		for surface in arena.walk_surfaces:
			if (surface.low!=surface.high or surface.low<2.) and surface.rect.grow(1.3).has_point(Vector2(pos.x,pos.z)):return false
	if absf(pos.x)<4. or absf(pos.z)<4. or arena.wading(pos) or absf(arena.walk_height(pos))>.1 or (arena.vertical_map and not 0. in arena.navigation_heights(pos)):return false
	if not arena.point_clear(pos):return false
	for obstacle in arena.obstacles:
		if obstacle.grow(1.2).has_point(Vector2(pos.x,pos.z)):return false
	for spawn in arena.ffa_spawns:
		if pos.distance_to(spawn)<5.:return false
	for goal in arena.zones+arena.sites+arena.navigation_goals:
		if pos.distance_to(goal)<7.5:return false
	for supply in arena.supplies:
		if pos.distance_to(supply.pos)<4.:return false
	for old in placed:
		if pos.distance_to(old)<(4.4 if arena.bounds.x<=36 else 5.2):return false
	return true
static func build(arena:Node):
	var rng=RandomNumberGenerator.new();rng.seed=641029+arena.map_index*179
	var navigation=BotNavigation.new();navigation.build(arena)
	var placed=[];var wanted=clampi(int(arena.bounds.x*arena.bounds.y/75),22,72)
	var fixed_count=0;var moving_count=0
	for attempt in range(1800):
		if placed.size()>=wanted:break
		var pos=Vector3(rng.randf_range(-arena.bounds.x+5,arena.bounds.x-5),0,rng.randf_range(-arena.bounds.y+5,arena.bounds.y-5))
		if not allowed(arena,pos,placed):continue
		var moving=(placed.size()+1)%2==0 and moving_count<24
		if not moving and not preserve_routes(navigation,arena,pos):continue
		placed.append(pos)
		if moving:
			var kind=KINDS[moving_count%KINDS.size()];var body=InteractiveProp.new()
			var half={"barrel":.46,"crate":.265,"cone":.285,"canister":.30,"tire":.34}[kind]
			body.position=pos+Vector3.UP*(half+.025);body.rotation.y=rng.randf_range(-PI,PI);body.configure(moving_count,kind,arena.props_authoritative)
			arena.add_child(body);arena.props[moving_count]=body;moving_count+=1
		else:
			var type=fixed_count%12;fixed_count+=1
			var node=Node3D.new();arena.architecture.add_child(node);node.position=pos;node.rotation.y=rng.randf_range(-PI,PI)
			furniture(node,type,arena.indoors)
			if type==6:
				node.queue_free()
				var body=InteractiveProp.new();body.position=pos;body.rotation.y=node.rotation.y;body.configure(moving_count,"table",arena.props_authoritative)
				arena.add_child(body);arena.props[moving_count]=body;moving_count+=1
			else:
				var body=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.collision_mask=0
				var faces=PackedVector3Array()
				for mesh in node.get_children():
					if mesh is MeshInstance3D:
						for point in mesh.mesh.get_faces():faces.append(mesh.transform*point)
				var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(faces);collision.shape=shape;body.add_child(collision)
				arena.obstacles.append(Rect2(Vector2(pos.x-1.25,pos.z-1.25),Vector2(2.5,2.5)))
				if arena.vertical_map:arena.navigation_blocks.append(AABB(pos-Vector3(.9,0,.9),Vector3(1.8,1.6,1.8)))
	arena.set_meta("dressing_count",fixed_count);arena.set_meta("interactive_count",moving_count)
static func preserve_routes(nav:BotNavigation,arena:Node,pos:Vector3) -> bool:
	var lo=nav.cell(pos-Vector3(1.25,0,1.25));var hi=nav.cell(pos+Vector3(1.25,0,1.25));var changed=[]
	for x in range(lo.x,hi.x+1):
		for y in range(lo.y,hi.y+1):
			var cell=Vector2i(x,y)
			if not nav.grid.is_point_solid(cell):nav.grid.set_point_solid(cell);changed.append(cell)
	for team in [0,1]:
		var starts=arena.spawn_points[team].filter(func(point):return arena.point_clear(point))
		var start=starts[0] if not starts.is_empty() else Vector3(0,.12,(-1 if team==0 else 1)*(arena.bounds.y-10))
		for goal in arena.zones+arena.sites+arena.navigation_goals:
			var path=nav.route(start,goal)
			if path.size()<2 or path[-1].distance_to(goal)>4.5:
				for cell in changed:nav.grid.set_point_solid(cell,false)
				return false
	return true
static func furniture(n:Node3D,type:int,indoors:bool):
	var metal=Color("637574");var dark=Color("445654");var wood=Color("b8986e")
	match type:
		0: # Slatted bench, rounded ends and cast legs.
			for z in [-.25,-.08,.09,.26]:M.box(n,Vector3(0,.5,z),Vector3(1.65,.08,.135),wood,Vector3.ZERO,.55)
			for y in [.75,.95]:M.box(n,Vector3(0,y,.32),Vector3(1.65,.135,.07),wood,Vector3(-.12,0,0),.55)
			for x in [-.61,.61]:
				for z in [-.24,.27]:H.cord(n,Vector3(x,.06,z),Vector3(x,.52,z),.038,dark)
				H.cord(n,Vector3(x,.48,.28),Vector3(x,1.04,.38),.026,dark)
		1: # Planter with clustered leaves (indoors/outdoors variants).
			M.cylinder(n,Vector3(0,.33,0),.58,.66,Color("aa9274"),Vector3.ZERO,.67,20)
			M.cylinder(n,Vector3(0,.65,0),.64,.04,Color("6f7052"),Vector3.ZERO,-1.,20)
			for i in range(8):
				var a=i*TAU/8.;H.cord(n,Vector3(0,.62,0),Vector3(cos(a)*.42,1.15+sin(i*3.)*.18,sin(a)*.42),.022,Color("6b8050"))
				var leaf=H.oval(n,Vector3(cos(a)*.38,1.03,sin(a)*.38),Vector3(.25,.57,.16),Color("718d61") if i%2==0 else Color("90a172"));leaf.rotation=Vector3(.35,a,.45)
		2: # Utility cabinet / laboratory console with curved door and vent grille.
			M.box(n,Vector3(0,.79,0),Vector3(1.02,1.58,.66),metal,Vector3.ZERO,.22)
			M.box(n,Vector3(0,.81,-.35),Vector3(.87,1.40,.06),Color("8e9d96"),Vector3.ZERO,.25)
			M.box(n,Vector3(-.27,1.26,-.39),Vector3(.22,.18,.028),Color("455d65"))
			H.cord(n,Vector3(.30,.71,-.405),Vector3(.30,.93,-.405),.022,dark)
			for i in range(6):M.box(n,Vector3(0,.24+i*.085,-.387),Vector3(.59,.017,.017),dark)
		3: # Recycling bins, a lid and side handles.
			for x in [-.34,.34]:
				M.box(n,Vector3(x,.61,0),Vector3(.56,1.10,.61),Color("84937a") if x<0 else Color("78959e"),Vector3.ZERO,.65)
				M.box(n,Vector3(x,1.20,0),Vector3(.62,.11,.66),dark,Vector3.ZERO,.65)
				M.box(n,Vector3(x,1.25,-.09),Vector3(.32,.023,.25),Color("303e3d"),Vector3.ZERO,.55)
		4: # Pallet with tied canvas bags, seams and soft silhouettes.
			for i in range(5):M.box(n,Vector3(-.55+i*.27,.14,0),Vector3(.23,.13,1.18),wood)
			for z in [-.4,.4]:M.box(n,Vector3(0,.055,z),Vector3(1.3,.1,.15),wood.darkened(.2))
			for x in [-.31,.31]:
				H.oval(n,Vector3(x,.43,0),Vector3(.63,.52,1.0),Color("b9ad89"));H.oval(n,Vector3(x,.70,.04),Vector3(.55,.30,.89),Color("c5b99a"))
				H.cord(n,Vector3(x-.23,.56,-.34),Vector3(x+.23,.56,-.34),.013,Color("8e876c"))
		5: # Workshop pipes with curved supports and valve wheel.
			for x in [-.33,0,.33]:
				M.cylinder(n,Vector3(x,.75,0),.12,1.4,metal,Vector3.ZERO,-1.,16)
				for y in [.23,1.19]:M.cylinder(n,Vector3(x,y,0),.15,.065,dark,Vector3.ZERO,-1.,16)
			var ring=TorusMesh.new();ring.inner_radius=.16;ring.outer_radius=.20;ring.rings=16;ring.ring_segments=8;M.instance(n,ring,Vector3(0,.84,-.29),Color("aa765b"),Vector3(PI/2,0,0))
			H.cord(n,Vector3(0,.84,0),Vector3(0,.84,-.32),.036,dark)
		6: # Low worktable with pot, cartons and tool tray.
			M.box(n,Vector3(0,.81,0),Vector3(1.55,.10,1.10),wood,Vector3.ZERO,.25)
			for x in [-.63,.63]:
				for z in [-.42,.42]:H.cord(n,Vector3(x,.06,z),Vector3(x,.77,z),.035,dark)
			M.box(n,Vector3(-.34,1.01,0),Vector3(.44,.28,.48),Color("a29577"),Vector3.ZERO,.12)
			M.cylinder(n,Vector3(.33,1.03,-.12),.14,.30,Color("8b9a8d"),Vector3.ZERO,-1.,16)
		7: # Bollard and cable reel / hose spool.
			M.cylinder(n,Vector3(0,.48,0),.21,.86,wood,Vector3(PI/2,0,0),-1.,20)
			for z in [-.47,.47]:M.cylinder(n,Vector3(0,.48,z),.49,.08,wood,Vector3(PI/2,0,0),-1.,20)
			for i in range(10):
				var ring=TorusMesh.new();ring.inner_radius=.28;ring.outer_radius=.32;ring.rings=16;ring.ring_segments=8;M.instance(n,ring,Vector3(0,.48,-.35+i*.075),dark,Vector3(PI/2,0,0))
		8: # Rolling diagnostic cart: shelf, monitor, cables and rubber casters.
			for x in [-.43,.43]:
				for z in [-.32,.32]:
					M.cylinder(n,Vector3(x,.13,z),.10,.08,dark,Vector3(0,0,PI/2),-1.,12)
					H.cord(n,Vector3(x,.20,z),Vector3(x,1.02,z),.025,metal)
			for y in [.28,.9]:M.box(n,Vector3(0,y,0),Vector3(.98,.07,.77),metal)
			M.box(n,Vector3(0,1.23,.14),Vector3(.69,.47,.10),dark,Vector3(-.16,0,0))
			M.box(n,Vector3(0,1.23,.078),Vector3(.58,.35,.015),Color("467a84"),Vector3(-.16,0,0))
			for i in range(4):M.box(n,Vector3(-.12,1.13+i*.058,.04),Vector3(.31,.016,.009),Color("8bc1bd"))
			M.box(n,Vector3(0,.96,-.19),Vector3(.49,.04,.19),Color("9daaa4"))
			M.box(n,Vector3(.17,.5,0),Vector3(.31,.37,.44),dark)
		9: # Emergency station; a glazed recess, extinguisher and pressure gauge.
			M.box(n,Vector3(0,.83,0),Vector3(.78,1.60,.55),Color("aab2a6"))
			M.box(n,Vector3(0,.82,-.29),Vector3(.60,1.16,.03),dark)
			M.cylinder(n,Vector3(0,.71,-.33),.14,.72,Color("b5664d"),Vector3.ZERO,-1.,20)
			M.cylinder(n,Vector3(0,1.09,-.33),.07,.08,metal)
			M.box(n,Vector3(0,1.16,-.34),Vector3(.21,.045,.07),dark)
			H.cord(n,Vector3(.07,1.11,-.32),Vector3(.2,.88,-.34),.021,dark)
			M.cylinder(n,Vector3(0,.98,-.48),.045,.018,Color("eee3c8"),Vector3(PI/2,0,0),-1.,12)
			M.box(n,Vector3(0,1.49,-.292),Vector3(.54,.08,.02),Color("709786"))
		10: # Industrial fan housing with angled blades and protective grille.
			M.box(n,Vector3(0,.75,0),Vector3(1.10,1.42,.72),metal)
			M.cylinder(n,Vector3(0,.91,-.4),.40,.06,dark,Vector3(PI/2,0,0),-1.,28)
			for i in range(5):
				var rotor=Node3D.new();n.add_child(rotor);rotor.position=Vector3(0,.91,-.44);rotor.rotation.z=i*TAU/5.
				M.tapered(rotor,Vector3(.17,0,0),Vector3(.28,.12,.025),Color("9dabaa"),.65)
			for i in range(7):M.box(n,Vector3(-.3+i*.1,.91,-.47),Vector3(.012,.65,.012),Color("53646a"))
			for y in [.23,.31]:M.box(n,Vector3(0,y,-.38),Vector3(.81,.025,.035),dark)
		11: # Stack of weathered delivery cases with offset lids and straps.
			for i in range(3):
				var center=Vector3((i%2)*.06,.24+i*.40,0)
				M.box(n,center,Vector3(1.12,.37,.76),Color("a28d66") if i%2 else Color("75867b"),Vector3.ZERO,.5)
				M.box(n,center+Vector3.UP*.18,Vector3(1.15,.055,.80),dark)
				for x in [-.36,.36]:M.box(n,center+Vector3(x,0,-.392),Vector3(.035,.34,.022),Color("c9b887"))
				M.box(n,center+Vector3(0,.04,-.405),Vector3(.20,.07,.025),dark)
