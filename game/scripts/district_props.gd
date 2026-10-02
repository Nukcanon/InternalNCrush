class_name DistrictProps
extends RefCounted
## 1.4 street/room props, themed per map (DistrictFacade style). Baked Toon
## Shooter pieces (assets/props, CC0) and procedural cartoon pieces share the
## world surface material. Every prop gets one box collider from its footprint,
## identical in native and Web builds.
# Cover-sized props at the baked anchors, per style.
const ROSTERS={
	"oldtown":["planter","bench","cask_pair","cafe_table","streetlight","trashcontainer","crate_stack","trafficcone"],
	"hillside":["planter","cask_pair","bench","streetlight","pots","crate_stack","laundry"],
	"canal":["bench","bollards","cask_pair","planter","streetlight","crate_stack","bike_rack"],
	"plaza":["bench","planter","fountain","streetlight","cafe_table","planter"],
	"market":["market_stall","fruit_crates","cask_pair","crate_stack","cardboardboxes_2","cafe_table","trashcontainer","market_stall"],
	"station":["bench","sign","trashcontainer","streetlight","planter","luggage"],
	"harbour":["container_small","crate_stack","pallet_load","bollards","cask_pair","fish_crates","container_long"],
	"shipyard":["container_long","gastank","pipes","pallet_load","cable_drum","barrier_single","container_small"],
	"logistics":["pallet_load","container_small","cardboardboxes_3","barrier_single","trashcontainer","pallet_load","cardboardboxes_4"],
	"desert":["sacktrench","crate_stack","gastank","watertank_floor","barrier_single","sacktrench_small","sign"],
	"orchard":["hay_bale","fruit_crates","cask_pair","fence_long","crate_stack","hay_bale"],
	"quarry":["rock_pile","woodplanks_stack","crate_stack","gastank","cable_drum","barrier_single","rock_pile"],
	"fortress":["cask_pair","crate_stack","sacktrench","hay_bale","weapon_rack","well"],
	"mountain_fort":["rock_pile","cask_pair","crate_stack","hay_bale","weapon_rack","sacktrench_small"],
	"monastery":["bench","planter","well","cask_pair","fountain","planter"],
	"aqueduct":["planter","bench","cask_pair","rock_pile","fountain","streetlight"],
	"nuclear":["barrier_single","gastank","pipes","container_small","sign","cable_drum","drums"],
	"wreckyard":["debris_tires","container_small","pallet_broken","gastank","barrier_single","woodplanks_stack","crate_stack"],
	"furnace":["gastank","pipes","crate_stack","ingots","cable_drum","barrier_single","pallet_load"],
	"greenhouse":["planter_long","potting_bench","bench","watertank_floor","crate_stack","planter_long"],
	"coastal_base":["sacktrench","container_small","barrier_single","crate_stack","gastank","sign","sacktrench_small"],
	"range":["target_stand","barrier_single","sacktrench","crate_stack","pallet_load","trafficcone","target_stand"],
	"steelmill":["ingots","crate_stack","pallet_load","gastank","cable_drum","pipes"],
	"lab":["lab_bench","cabinet","crate_stack","desk","lab_bench"],
	"garage":["workbench","tool_chest","debris_tires","gastank","crate_stack","cardboardboxes_2"],
	"power":["transformer","cable_drum","gastank","cabinet","pipes","transformer"],
	"testlab":["lab_bench","cabinet","crate_stack","barrier_single","lab_bench"],
	"derelict":["debris_tires","pallet_broken","crate_stack","woodplanks_stack","cardboardboxes_4","gastank"],
	"highrise":["desk","sofa","sofa_small","planter","cabinet","desk"],
	"library":["bookcase","reading_table","bookcase","sofa_small","globe","bookcase"],
	"vault":["deposit_block","crate_stack","barrier_single","money_cart","deposit_block"],
	"server":["server_block","cabinet","cable_drum","crate_stack","server_block"]}
const TREES={"orchard":["tree_1","tree_4"],"greenhouse":["tree_2","tree_4"],"desert":["tree_2"],"coastal_base":["tree_2"],"quarry":["tree_2","tree_3"],
	"mountain_fort":["tree_2","tree_3"],"monastery":["tree_1","tree_2"]}
static var meshes={}
static var manifest={}
static func baked(name:String) -> Mesh:
	if not meshes.has(name):meshes[name]=load("res://assets/props/"+name+".res")
	return meshes[name]
static func has_baked(name:String) -> bool:
	if manifest.is_empty():manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/props/manifest.json"))
	return manifest.has(name)
static func kind_for(index:int,ordinal:int) -> String:
	var roster:Array=ROSTERS[DistrictFacade.style_name(index)]
	return roster[(ordinal+index*3)%roster.size()]
static func tree_for(index:int,ordinal:int) -> String:
	var list:Array=TREES.get(DistrictFacade.style_name(index),["tree_1","tree_2","tree_3","tree_4"])
	return list[(ordinal+index)%list.size()]
## Builds the prop under node (local frame, footprint centred on the origin).
## Returns the collision box (local AABB) or an empty AABB for none.
static func build(node:Node3D,kind:String,index:int,ordinal:int) -> AABB:
	var material=WorldSurface.material("detail",index,true)
	# 1.4.5: remodelled vehicles, drums, casks, cable drums and the water tank
	# (PropModels) replace the old generated set.
	if PropModels.has(kind) or PropCatalog.has(kind):
		var pk=DistrictFacade.Kit.new()
		var pbox=PropModels.build(pk,kind,ordinal+index*7) if PropModels.has(kind) else PropCatalog.build(pk,kind,ordinal+index*7)
		var pv=MeshInstance3D.new();pv.mesh=pk.detail.commit();pv.material_override=material;node.add_child(pv)
		if kind=="fountain":
			# 1.4.6 (the user: all water in the new design): clear, light, moving water
			var pool=MeshInstance3D.new();var disc=CylinderMesh.new();disc.top_radius=1.3;disc.bottom_radius=1.3;disc.height=.01;disc.radial_segments=24;disc.rings=1
			pool.mesh=disc;pool.position.y=.43;pool.material_override=WaterSurface.material_kind("shallow");pool.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pool.set_meta("no_collision",true);node.add_child(pool)
		# (1.4.10: the drowning sign carries no text plate any more - a pictogram only)
		return pbox
	if kind.begins_with("vehicle_"):
		# Parked vehicles (original transport set) as hard cover, length along local X.
		var holder=Node3D.new();node.add_child(holder)
		ImportedWorldProp.build(holder,kind,Vector3.ONE,"transport_original",true)
		var local_bounds=func() -> AABB:
			var out=AABB();var first=true
			for mesh in holder.find_children("*","MeshInstance3D",true,false):
				var xf=holder.transform
				var parent=mesh.get_parent()
				while parent!=holder:xf=xf*parent.transform;parent=parent.get_parent()
				var b=(xf*mesh.transform)*mesh.get_aabb()
				out=b if first else out.merge(b);first=false
			return out
		var bounds:AABB=local_bounds.call()
		if bounds.size.z>bounds.size.x:holder.rotation.y=PI*.5;bounds=local_bounds.call()
		var centre=bounds.get_center();holder.position-=Vector3(centre.x,0,centre.z)
		return AABB(Vector3(-bounds.size.x*.5,0,-bounds.size.z*.5),Vector3(bounds.size.x,minf(bounds.size.y,1.6),bounds.size.z))
	if has_baked(kind):
		var mesh=MeshInstance3D.new();mesh.mesh=baked(kind);mesh.material_override=material;node.add_child(mesh)
		var box=mesh.get_aabb()
		if kind.begins_with("tree_"):return AABB(Vector3(-.3,0,-.3),Vector3(.6,2.4,.6))
		if kind=="streetlight":return AABB(Vector3(-.18,0,-.18),Vector3(.36,3.,.36))
		return box
	var kit=DistrictFacade.Kit.new()
	var box=procedural(kit,kind,ordinal+index*7)
	var visual=MeshInstance3D.new();visual.mesh=kit.detail.commit();visual.material_override=material;node.add_child(visual)
	return box
## 1.4.2 collision that follows the prop instead of one box round everything
## (a box on a fountain, a barrel group or a stepped crate stack left invisible
## corners and air a player could stand on). Returns [[Shape3D, Transform3D]]
## in the prop's local frame. Procedural props list their solid parts; baked
## props use the convex hull of their mesh; the rest keep the footprint box.
const CYL="cyl"
const NEW_PIECES=["ammo_crates","equipment_cases","sack_stack","lobster_pots","produce_boxes","sack_pallet","drum_pallet","brick_pallet","water_barrels",
	"generator","milk_churns","vending_machine","phone_booth","wheelie_bins","notice_board","mailbox","fire_hydrant","statue","net_rack","compressor","wheelbarrow","flower_cart","warning_sign","lifebuoy_stand"]
static var hull_cache={}
static func cylinder(p:Vector3,radius:float,height:float,axis_z:=false) -> Array:
	var s=CylinderShape3D.new();s.radius=radius;s.height=height
	var basis=Basis(Vector3.RIGHT,PI*.5) if axis_z else Basis()
	return [s,Transform3D(basis,p+(Vector3.ZERO if axis_z else Vector3.UP*height*.5))]
static func block(lo:Vector3,hi:Vector3) -> Array:
	var s=BoxShape3D.new();s.size=hi-lo;return [s,Transform3D(Basis(),(lo+hi)*.5)]
static func collision(node:Node3D,kind:String,occupied:AABB) -> Array:
	if occupied.size==Vector3.ZERO:return []
	match kind:
		"cask_pair","drums":
			var out=[]
			for p in [Vector3(-.45,0,-.2),Vector3(.45,0,-.2),Vector3(0,0,.45)]:out.append(cylinder(p,.37,.95))
			return out
		"fountain":return [cylinder(Vector3.ZERO,1.5,.52),cylinder(Vector3.ZERO,.3,1.3),cylinder(Vector3(0,1.3,0),.7,.14)]
		"bollards":return [cylinder(Vector3(-.7,0,0),.24,.82),cylinder(Vector3(.7,0,0),.24,.82)]
		"pots":
			var out=[]
			for i in range(3):out.append(cylinder(Vector3(-.5+i*.5,0,(i%2)*.2),.22,.7))
			return out
		"well":return [cylinder(Vector3.ZERO,.9,.82),block(Vector3(-.86,0,-.06),Vector3(-.74,2.,.06)),block(Vector3(.74,0,-.06),Vector3(.86,2.,.06))]
		"cable_drum":return [cylinder(Vector3(0,.7,-.35),.7,.1,true),cylinder(Vector3(0,.7,.35),.7,.1,true),cylinder(Vector3(0,.7,0),.5,.7,true)]
		# 1.4.5 remodel (PropModels.water_tank): the tank on its saddles
		"watertank_floor":return [cylinder(Vector3(0,1.08,0),.9,4.4,true),block(Vector3(-.75,0,-2.3),Vector3(.75,.55,2.3))]
		"cafe_table":return [cylinder(Vector3.ZERO,.5,.77),block(Vector3(-1.,0,-.2),Vector3(-.6,.82,.2)),block(Vector3(.6,0,-.2),Vector3(1.,.82,.2)),cylinder(Vector3(0,.77,0),.05,1.7)]
		"crate_stack":return [block(Vector3(-.9,0,-.45),Vector3(0,.9,.45)),block(Vector3(.05,0,-.3),Vector3(.85,.8,.5)),block(Vector3(-.75,.9,-.4),Vector3(.05,1.7,.4))]
		"bench":return [block(Vector3(-.95,0,-.25),Vector3(.95,.51,.25)),block(Vector3(-.95,.51,-.25),Vector3(.95,.95,-.19))]
		"laundry":return [cylinder(Vector3(-1.3,0,0),.06,2.2),cylinder(Vector3(1.3,0,0),.06,2.2)]
		"hay_bale":return [block(Vector3(-.7,0,-.45),Vector3(.7,.8,.45)),block(Vector3(-.3,.8,-.4),Vector3(.9,1.2,.4))]
		"rock_pile":
			var out=[]
			for i in range(5):
				var p=Vector3([-.6,.5,0,-.2,.4][i],[.35,.3,.8,.25,.7][i],[.1,-.2,0,.4,.2][i]);var half=Vector3(.9,.7,.8)*[1.,.9,.7,.8,.6][i]*.5
				out.append(block(p-half,p+half))
			return out
		"desk":return [block(Vector3(-.8,0,-.4),Vector3(.8,.77,.4)),block(Vector3(-.3,.77,-.25),Vector3(.3,1.22,-.15)),block(Vector3(-.25,0,.35),Vector3(.25,.65,.85))]
		"lab_bench":return [block(Vector3(-1.15,0,-.45),Vector3(1.15,.95,.45)),block(Vector3(.45,.95,-.2),Vector3(.95,1.25,.2))]
		"workbench":return [block(Vector3(-1.,0,-.4),Vector3(1.,.95,.4)),block(Vector3(-.7,.95,-.15),Vector3(-.3,1.15,.15))]
		"target_stand":return [block(Vector3(-.65,0,-.25),Vector3(.65,.8,.25)),block(Vector3(-.6,.8,-.04),Vector3(.6,1.8,.04))]
		"potting_bench":return [block(Vector3(-.9,0,-.35),Vector3(.9,.89,.35)),block(Vector3(-.75,.89,-.15),Vector3(.75,1.33,.15))]
		"weapon_rack":return [block(Vector3(-.8,0,-.25),Vector3(.8,.2,.25)),block(Vector3(-.8,.2,-.27),Vector3(.8,1.5,-.05))]
		"globe":return [cylinder(Vector3.ZERO,.3,.8),block(Vector3(-.28,.78,-.28),Vector3(.28,1.35,.28))]
		"money_cart":return [block(Vector3(-.6,0,-.35),Vector3(.6,1.1,.35))]
		"bike_rack":return [block(Vector3(-1.05,0,-.08),Vector3(1.05,.68,.08))]
		"market_stall":
			# Counter plus the canopy (reachable from the counter: it must hold a player).
			var roof=BoxShape3D.new();roof.size=Vector3(2.7,.06,1.4)
			return [block(Vector3(-1.25,0,-.5),Vector3(1.25,1.2,.5)),[roof,Transform3D(Basis(Vector3.RIGHT,atan2(.3,1.35)),Vector3(0,2.33,.075))]]
	if kind.begins_with("tree_") or kind=="streetlight" or kind.begins_with("vehicle_"):return [block(occupied.position,occupied.end)]
	# 1.4.6 themed pieces: their own cylinders, else hulls of their mesh in
	# height bands (a footprint box would leave air to stand on above them).
	if PropCatalog.has(kind) and kind in NEW_PIECES:
		var own=PropCatalog.collision(kind,occupied)
		if not own.is_empty():return own
		for child in node.get_children():
			if child is MeshInstance3D and child.mesh:
				var hulls=band_hulls(child.mesh,4)
				if not hulls.is_empty():return hulls.map(func(h):return [h,Transform3D()])
	if has_baked(kind):
		# Baked mesh cut into horizontal bands, one convex hull per band (a single
		# hull ran from a tank's valve to its rim, leaving an invisible cone of
		# air on top). Cached per kind; deterministic on every platform.
		if not hull_cache.has(kind):hull_cache[kind]=band_hulls(baked(kind),4)
		var hulls:Array=hull_cache[kind]
		if not hulls.is_empty():return hulls.map(func(h):return [h,Transform3D()])
	return [block(occupied.position,occupied.end)]
static func band_hulls(mesh:Mesh,bands:int) -> Array:
	var faces:PackedVector3Array=mesh.get_faces()
	if faces.is_empty():return []
	var lo=INF;var hi=-INF
	for p in faces:lo=minf(lo,p.y);hi=maxf(hi,p.y)
	var out=[]
	for b in range(bands):
		var y0=lerpf(lo,hi,float(b)/bands);var y1=lerpf(lo,hi,float(b+1)/bands)
		var points=PackedVector3Array()
		for i in range(0,faces.size(),3):
			# The triangle clipped to y0..y1 (its corners inside plus edge crossings).
			var tri=[faces[i],faces[i+1],faces[i+2]]
			for k in range(3):
				var p:Vector3=tri[k];var q:Vector3=tri[(k+1)%3]
				if p.y>=y0-.0001 and p.y<=y1+.0001:points.append(p)
				for level in [y0,y1]:
					if (p.y-level)*(q.y-level)<0.:points.append(p.lerp(q,(level-p.y)/(q.y-p.y)))
		if points.size()<4:continue
		# Skip flat or needle-thin bands (a degenerate hull cannot be built).
		var box=AABB(points[0],Vector3.ZERO)
		for p in points:box=box.expand(p)
		if box.size.x<.02 or box.size.y<.02 or box.size.z<.02:continue
		var unique={}
		for p in points:unique[p.snapped(Vector3.ONE*.002)]=true
		var shape=ConvexPolygonShape3D.new();shape.points=PackedVector3Array(unique.keys())
		out.append(shape)
	return out
# 1.4.5: how deep a placed prop may sink into a wall or another prop before it
# is moved or removed (8 cm left visible clipping: crates inside containers).
const SINK_LIMIT=.02
const JOINTS=[["low_wall","pillar"],["sacktrench","sacktrench_small"],["sacktrench","sacktrench"],["sacktrench_small","sacktrench_small"]]
static func joint(a:String,b:String) -> bool:
	var pair=[a,b];pair.sort();return pair in JOINTS
## 1.4.6 (the user): a shot at any prop must strike the prop itself, never the
## air beside it. When a map loads, every static prop and boat swaps its
## approximate collision (boxes / hulls, kept in the cache for the bake's
## settling pass) for its exact visible surface. Shapes are shared per mesh.
static var exact_shapes={}
static func exact_collision(a:Node3D):
	if not is_instance_valid(a.architecture):return
	if exact_shapes.size()>400:exact_shapes.clear()
	for node in a.architecture.get_children():
		if not (node.has_meta("footprint") or node.has_meta("boat")):continue
		if str(node.get_meta("prop_asset","")).begins_with("tree_"):continue
		var body:StaticBody3D=null
		var visuals=[]
		for child in node.get_children():
			if child is StaticBody3D:body=child
			elif child is MeshInstance3D and child.mesh!=null and not child.has_meta("no_collision"):visuals.append(child)
		if body==null or visuals.is_empty():continue
		var faces=PackedVector3Array()
		var key=""
		for mesh in visuals:key+=str(mesh.mesh.get_instance_id())+str(mesh.transform)
		if exact_shapes.has(key):faces=PackedVector3Array()
		else:
			for mesh in visuals:
				var source:PackedVector3Array=mesh.mesh.get_faces()
				var xf:Transform3D=body.transform.affine_inverse()*mesh.transform
				for p in source:faces.append(xf*p)
			if faces.size()<3:continue
			var shape=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
			exact_shapes[key]=shape
		for child in body.get_children():
			if child is CollisionShape3D:body.remove_child(child);child.queue_free()
		var exact=CollisionShape3D.new();exact.shape=exact_shapes[key];body.add_child(exact)
## Map bake pass (after a physics step, so the space holds every wall): props
## sunk more than SINK_LIMIT into walls or other props move to a nearby spot on the same floor, or
## are removed (SINK_LIMIT). Returns [moved, removed].
static func settle_props(a:Node3D) -> Array:
	var bodies=[]
	for node in a.architecture.get_children():
		if not node.has_meta("footprint"):continue
		for child in node.get_children():
			if child is StaticBody3D:bodies.append(child);break
	var moved=0;var dropped=[]
	for body in bodies:
		var node:Node3D=body.get_parent();var kind=str(node.get_meta("prop_asset",""))
		var footprint:AABB=node.get_meta("footprint");var base_y=float(node.get_meta("base_y"))
		var fits=func() -> bool:
			for x in [footprint.position.x,footprint.end.x]:
				for z in [footprint.position.z,footprint.end.z]:
					var levels=DistrictLayout.heights(a,node.transform*Vector3(x,0,z))
					if levels.is_empty() or absf(float(levels[0])-base_y)>.12:return false
			var at=node.position
			if covers_opening(a,node,footprint):return false
			return not (a.navigation_goals+a.zones).any(func(goal):return Vector2(goal.x-at.x,goal.z-at.z).length()<2.5+footprint.size.length()*.5 and absf(goal.y-at.y)<2.)
		var before=node.position
		# Designed joints (a low wall into its end pillar, sandbag corners) may overlap.
		var others=[]
		for other in bodies:
			if other!=body and is_instance_valid(other) and joint(kind,str(other.get_parent().get_meta("prop_asset",""))):others.append(other.get_rid())
		if not clear_of_walls(a,node,body,1. if kind.begins_with("vehicle_") else .5,others,fits):dropped.append(node);continue
		if node.position!=before:
			moved+=1;a.navigation_blocks[int(node.get_meta("nav_block"))]=node.transform*AABB(node.get_meta("occupied"))
	# Drop the unplaceable ones (their navigation blocks too, highest index first).
	var indices=dropped.map(func(n):return int(n.get_meta("nav_block")));indices.sort();indices.reverse()
	for i in indices:a.navigation_blocks.remove_at(i)
	for n in dropped:n.free()
	return [moved,dropped.size()]
## 1.4.6 (the user): true when the prop would stand in a window or a facade door.
static func covers_opening(a:Node3D,node:Node3D,footprint:AABB) -> bool:
	var world:AABB=node.transform*footprint
	var inv=node.transform.affine_inverse()
	for o in a.get_meta("facade_openings",[]):
		var xf:Transform3D=o[0];var h:Vector3=o[1]+Vector3(.05,0,.3)
		if not (xf*AABB(-h,h*2.)).intersects(world):continue
		var l=Vector3.INF;var hi=-Vector3.INF
		for x in [-h.x,h.x]:
			for y in [-h.y,h.y]:
				for z in [-h.z,h.z]:
					var p:Vector3=inv*(xf*Vector3(x,y,z));l=l.min(p);hi=hi.max(p)
		if AABB(l,hi-l).intersects(footprint):return true
	return false
## Moves a freshly placed prop sideways out of walls and props it sinks into
## (more than SINK_LIMIT), at most `limit` metres; false when it still
## overlaps. Designed joints (JOINTS) may overlap; touching is fine.
static func clear_of_walls(a:Node3D,node:Node3D,body:StaticBody3D,limit:float,others:Array,fits:Callable) -> bool:
	var space=a.get_world_3d().direct_space_state
	var depth=func() -> float:
		var deepest=0.
		for cs in body.get_children():
			if not cs is CollisionShape3D:continue
			# (lifted a few centimetres: resting on - or a little into - the ground,
			# sloped or not, is not sinking into a wall or another prop)
			var q=PhysicsShapeQueryParameters3D.new();q.shape=cs.shape;q.transform=(node.global_transform*cs.transform).translated(Vector3.UP*.06);q.collision_mask=1;q.exclude=[body.get_rid()]+others
			var pairs=space.collide_shape(q,32)
			for i in range(0,pairs.size(),2):deepest=maxf(deepest,pairs[i].distance_to(pairs[i+1]))
		return deepest
	if depth.call()<=SINK_LIMIT:return true
	# Nearby spots on the same floor, nearest first (8 directions per ring).
	var start=node.position
	for r in [.25,.5,.75,1.]:
		if r>limit+.001:break
		for k in range(8):
			var dir=Vector3(cos(k*TAU/8.),0,sin(k*TAU/8.))
			node.position=start+dir*r
			if fits.call() and depth.call()<=SINK_LIMIT:return true
	node.position=start
	return false
static func c(hex:String) -> Color:return Color(hex)
static func procedural(k:DistrictFacade.Kit,kind:String,hs:int) -> AABB:
	var wood=c("9a6a42");var dark_wood=c("6b4a2f");var metal=c("7f8a92");var dark=c("3a4046")
	match kind:
		# 1.5 blueprint cover: concrete pillar and a chest-high wall.
		"pillar":
			k.box(Vector3(0,1.7,0),Vector3(.8,3.4,.8),c("a7aaa6"),true)
			k.box(Vector3(0,.12,0),Vector3(1.,.24,1.),c("8c8f8b"),true)
			k.box(Vector3(0,3.3,0),Vector3(1.,.2,1.),c("8c8f8b"),true)
			return AABB(Vector3(-.5,0,-.5),Vector3(1.,3.4,1.))
		"low_wall":
			k.box(Vector3(0,.55,0),Vector3(3.,1.1,.4),c(["b9ada0","a6a9a2","b39a86"][hs%3]),true)
			k.box(Vector3(0,1.14,0),Vector3(3.1,.08,.5),c("8c8f8b"),true)
			return AABB(Vector3(-1.55,0,-.25),Vector3(3.1,1.18,.5))
		"planter","planter_long":
			var w=2.4 if kind=="planter_long" else 1.3
			k.box(Vector3(0,.3,0),Vector3(w,.6,.8),c(["b5634a","a8a39a","7a6a5a"][hs%3]),true)
			k.box(Vector3(0,.62,0),Vector3(w-.12,.06,.68),c("5a3f2a"),true)
			for i in range(int(w/.35)):
				k.box(Vector3(-w*.5+.25+i*.35,.78,((i%2)-.5)*.3),Vector3(.3,.28,.3),c(["5f9f4a","6fb055","d9577a","f0c24f","4f8f3f"][(hs+i)%5]),true)
			return AABB(Vector3(-w*.5,0,-.4),Vector3(w,.9,.8))
		"bench":
			for x in [-.8,.8]:k.box(Vector3(x,.22,0),Vector3(.12,.44,.5),dark,true)
			k.box(Vector3(0,.47,0),Vector3(1.9,.08,.5),wood,true)
			k.box(Vector3(0,.8,-.22),Vector3(1.9,.3,.06),wood,true)
			return AABB(Vector3(-.95,0,-.28),Vector3(1.9,.95,.56))
		"cask_pair","drums":
			var col=c("8a5a32") if kind=="cask_pair" else c(["e0b83a","3f7fbf","c9503a"][hs%3])
			for i in range(3):
				var p=Vector3([-.45,.45,0.][i],0,[-.2,-.2,.45][i])
				k.prism(p,.36,.95,col,8)
				for y in [.2,.75]:k.prism(p+Vector3.UP*y,.375,.06,dark,8,false)
			return AABB(Vector3(-.85,0,-.6),Vector3(1.7,.95,1.4))
		"cafe_table":
			k.prism(Vector3.ZERO,.08,.72,dark,6);k.prism(Vector3(0,.72,0),.5,.05,c("f1ece0"),10)
			for side in [-1,1]:
				var p=Vector3(side*.8,0,0)
				k.box(p+Vector3(0,.22,0),Vector3(.4,.44,.4),c(["4f8f7a","b5563e","5a6f9a"][hs%3]),true)
				k.box(p+Vector3(side*.18,.62,0),Vector3(.06,.4,.4),c(["4f8f7a","b5563e","5a6f9a"][hs%3]),true)
			# Parasol above head height.
			k.prism(Vector3(0,.77,0),.04,1.7,dark,4,false)
			for i in range(8):
				var a=TAU*i/8.;var b=TAU*(i+1)/8.
				var top=Vector3(0,2.7,0);var p=Vector3(cos(a)*1.3,2.25,sin(a)*1.3);var q=Vector3(cos(b)*1.3,2.25,sin(b)*1.3)
				k.quad4(k.detail,p,q,top,top,c("d24c3f") if i%2==0 else c("f4ead7"))
				k.quad4(k.detail,q,p,top,top,c("d24c3f") if i%2==0 else c("f4ead7"))
			return AABB(Vector3(-1.,0,-.5),Vector3(2.,.9,1.))
		"crate_stack":
			k.box(Vector3(-.45,.45,0),Vector3(.9,.9,.9),wood,true);k.box(Vector3(.45,.4,.1),Vector3(.8,.8,.8),wood.lightened(.08),true)
			k.box(Vector3(-.35,1.3,0),Vector3(.8,.8,.8),wood.darkened(.05),true)
			for p in [Vector3(-.45,.45,.451),Vector3(.45,.4,.501),Vector3(-.35,1.3,.401)]:
				k.box(p,Vector3(.7,.08,.02),dark_wood,true);k.box(p,Vector3(.08,.7,.02),dark_wood,true)
			return AABB(Vector3(-.9,0,-.45),Vector3(1.75,1.7,1.))
		"bollards":
			for x in [-.7,.7]:
				k.prism(Vector3(x,0,0),.2,.7,c("3a4046"),8);k.prism(Vector3(x,.7,0),.26,.12,c("3a4046"),8)
			return AABB(Vector3(-.95,0,-.26),Vector3(1.9,.82,.52))
		"pots":
			for i in range(3):
				var p=Vector3(-.5+i*.5,0,(i%2)*.2)
				k.prism(p,.2+.04*(i%2),.4,c("b5634a"),8);k.box(p+Vector3(0,.55,0),Vector3(.38,.3,.38),c("5f9f4a"),true)
			return AABB(Vector3(-.75,0,-.25),Vector3(1.5,.75,.7))
		"laundry":
			# 1.4.5: sturdier posts and a visible line with the cloths hung from it
			# (thin posts and a 2 cm line vanished at a distance, leaving the
			# cloths floating in the air).
			for x in [-1.3,1.3]:
				k.prism(Vector3(x,0,0),.09,2.25,dark_wood,6)
				k.box(Vector3(x,2.15,0),Vector3(.26,.1,.26),dark_wood,true)
			k.box(Vector3(0,2.12,0),Vector3(2.6,.06,.06),c("d8d2c4"),true)
			for i in range(4):
				k.box(Vector3(-.9+i*.6,1.8,0),Vector3(.45,.6,.03),c(["e8523f","5a88b8","f0c24f","f4f1e8"][(hs+i)%4]),true)
				k.box(Vector3(-.9+i*.6,2.1,0),Vector3(.47,.06,.07),c("8a6a4a"),true) # pegs
			return AABB(Vector3(-1.35,0,-.1),Vector3(2.7,.4,.2))
		"bike_rack":
			for i in range(4):k.arch_ring(-.9+i*.6,.35,0.,.3,.05,dark)
			k.box(Vector3(0,.03,0),Vector3(2.2,.06,.1),dark,true)
			return AABB(Vector3(-1.2,0,-.2),Vector3(2.4,.7,.4))
		"fountain":
			k.prism(Vector3.ZERO,1.5,.5,c("d6cbb5"),12);k.prism(Vector3(0,.5,0),1.3,.02,c("5fb8d0"),12)
			k.prism(Vector3.ZERO,.3,1.3,c("d6cbb5"),8);k.prism(Vector3(0,1.3,0),.7,.14,c("d6cbb5"),10);k.prism(Vector3(0,1.44,0),.12,.4,c("5fb8d0"),6)
			return AABB(Vector3(-1.5,0,-1.5),Vector3(3.,1.,3.))
		"market_stall":
			var cloth=[c("d24c3f"),c("2f7fbf"),c("2f9a6a"),c("e0a02f")][hs%4]
			k.box(Vector3(0,.45,0),Vector3(2.4,.9,.9),wood,true)
			k.box(Vector3(0,.93,0),Vector3(2.5,.06,1.),wood.lightened(.1),true)
			for i in range(5):k.box(Vector3(-1.+i*.5,1.05,0),Vector3(.4,.18,.6),c(["e05a3a","f0c24f","8fbf5a","d9577a","f09a3a"][(hs+i)%5]),true)
			for x in [-1.2,1.2]:
				for z in [-.45,.45]:k.prism(Vector3(x,0,z),.04,2.3,dark_wood,4,false)
			for i in range(6):
				var x0=-1.35+i*.45
				k.quad4(k.detail,Vector3(x0,2.2,.75),Vector3(x0+.45,2.2,.75),Vector3(x0+.45,2.5,-.6),Vector3(x0,2.5,-.6),cloth if i%2==0 else c("f4ead7"))
				k.quad4(k.detail,Vector3(x0+.45,2.2,.75),Vector3(x0,2.2,.75),Vector3(x0,2.5,-.6),Vector3(x0+.45,2.5,-.6),cloth if i%2==0 else c("f4ead7"))
			return AABB(Vector3(-1.25,0,-.5),Vector3(2.5,1.2,1.))
		"fruit_crates","fish_crates":
			for i in range(4):
				var p=Vector3(-.55+(i%2)*1.1,.2+(i/2)*.4,((i/2)-.5)*.15)
				k.box(p,Vector3(1.,.4,.6),wood,true)
				k.box(p+Vector3(0,.22,0),Vector3(.9,.08,.5),c(["e05a3a","f0c24f","8fbf5a","f09a3a"][(hs+i)%4]) if kind=="fruit_crates" else c(["9fb8c4","c8d4dc"][i%2]),true)
			return AABB(Vector3(-1.05,0,-.4),Vector3(2.1,.9,.8))
		"pallet_load":
			k.box(Vector3(0,.08,0),Vector3(1.3,.16,1.1),wood,true)
			k.box(Vector3(0,.66,0),Vector3(1.2,1.,1.),c(["c9a36d","b8894f","d8b47a"][hs%3]),true)
			k.box(Vector3(0,.66,.501),Vector3(1.2,.1,.02),c("e8e4da"),true)
			return AABB(Vector3(-.65,0,-.55),Vector3(1.3,1.16,1.1))
		"cable_drum":
			var col=c(["b5563e","8a6a42","3f7fbf"][hs%3])
			for z in [-.35,.35]:
				k.xf=Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(0,.7,z));k.prism(Vector3.ZERO,.7,.08,col,10)
			k.xf=Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(0,.7,-.35));k.prism(Vector3.ZERO,.4,.7,c("3a3a3a"),8,false)
			k.xf=Transform3D()
			return AABB(Vector3(-.7,0,-.45),Vector3(1.4,1.4,.9))
		"hay_bale":
			k.box(Vector3(0,.4,0),Vector3(1.4,.8,.9),c("e0c070"),true)
			for x in [-.35,.35]:k.box(Vector3(x,.4,0),Vector3(.04,.82,.92),c("b8903a"),true)
			k.box(Vector3(.3,1.0,0),Vector3(1.2,.4,.8),c("d8b860"),true)
			return AABB(Vector3(-.7,0,-.45),Vector3(1.4,1.2,.9))
		"rock_pile":
			for i in range(5):
				var p=Vector3([-.6,.5,0,-.2,.4][i],[.35,.3,.8,.25,.7][i],[.1,-.2,0,.4,.2][i])
				k.box(p,Vector3(.9,.7,.8)*[1.,.9,.7,.8,.6][i],c(["a8a090","9c9484","b4ac9c"][(hs+i)%3]),true)
			return AABB(Vector3(-1.05,0,-.6),Vector3(2.,1.2,1.2))
		"woodplanks_stack":
			for i in range(4):k.box(Vector3(0,.1+i*.16,(i%2)*.1),Vector3(2.4,.14,.9),wood.darkened(.05*(i%2)),true)
			return AABB(Vector3(-1.2,0,-.45),Vector3(2.4,.7,1.))
		"weapon_rack":
			k.box(Vector3(0,.1,0),Vector3(1.6,.2,.5),dark_wood,true);k.box(Vector3(0,1.2,-.2),Vector3(1.6,.1,.1),dark_wood,true)
			for i in range(4):k.box(Vector3(-.6+i*.4,.7,-.1),Vector3(.05,1.3,.05),c("8a8f94"),true);k.box(Vector3(-.6+i*.4,1.4,-.1),Vector3(.12,.2,.03),c("b8c0c6"),true)
			return AABB(Vector3(-.8,0,-.3),Vector3(1.6,1.5,.6))
		"well":
			k.prism(Vector3.ZERO,.9,.8,c("a9a08c"),10);k.prism(Vector3(0,.8,0),.75,.02,c("2a3a44"),10)
			for x in [-.8,.8]:k.box(Vector3(x,1.4,0),Vector3(.12,1.2,.12),dark_wood,true)
			k.box(Vector3(0,2.05,0),Vector3(1.9,.1,.9),c("b5563e"),true)
			return AABB(Vector3(-.9,0,-.9),Vector3(1.8,.9,1.8))
		"ingots":
			for i in range(6):k.box(Vector3(-.5+(i%3)*.5,.12+(i/3)*.24,0),Vector3(.45,.22,1.),c("c9d0d4") if i%2 else c("b8a060"),true)
			return AABB(Vector3(-.75,0,-.5),Vector3(1.5,.48,1.))
		"target_stand":
			for x in [-.5,.5]:k.box(Vector3(x,.8,0),Vector3(.08,1.6,.08),dark_wood,true)
			k.box(Vector3(0,1.3,0),Vector3(1.2,1.,.04),c("f4f1e8"),true)
			k.disc(Vector3(0,1.3,.03),.35,c("e05a3a"),12);k.disc(Vector3(0,1.3,.035),.15,c("f4f1e8"),10)
			k.box(Vector3(0,.4,0),Vector3(1.3,.8,.5),c("b8a47a"),true)
			return AABB(Vector3(-.65,0,-.25),Vector3(1.3,1.8,.5))
		"luggage":
			k.box(Vector3(0,.25,0),Vector3(1.4,.1,.7),metal,true)
			for i in range(3):k.box(Vector3(-.4+i*.4,.55+(i%2)*.1,0),Vector3(.36,.5+.2*(i%2),.5),c(["b5563e","3f5f8a","5a8a5a"][(hs+i)%3]),true)
			for x in [-.6,.6]:k.prism(Vector3(x,0,.3),.1,.2,dark,6)
			return AABB(Vector3(-.7,0,-.35),Vector3(1.4,1.,.7))
		"potting_bench":
			k.box(Vector3(0,.85,0),Vector3(1.8,.08,.7),wood,true)
			for x in [-.8,.8]:k.box(Vector3(x,.42,0),Vector3(.08,.85,.6),dark_wood,true)
			for i in range(4):k.prism(Vector3(-.6+i*.4,.89,0),.12,.2,c("b5634a"),6);k.box(Vector3(-.6+i*.4,1.2,0),Vector3(.25,.25,.25),c("5f9f4a"),true)
			return AABB(Vector3(-.9,0,-.35),Vector3(1.8,1.,.7))
		"lab_bench":
			k.box(Vector3(0,.45,0),Vector3(2.2,.9,.8),c("e8ecef"),true)
			k.box(Vector3(0,.92,0),Vector3(2.3,.05,.9),c("3a4652"),true)
			for i in range(3):k.prism(Vector3(-.7+i*.6,.95,0),.07,.22,c("9fd6cf"),6)
			k.box(Vector3(.7,1.1,0),Vector3(.5,.3,.4),c("4a5560"),true)
			return AABB(Vector3(-1.15,0,-.45),Vector3(2.3,1.2,.9))
		"cabinet":
			k.box(Vector3(0,.9,0),Vector3(1.2,1.8,.5),c(["b8c4c8","8a9aa4","c8b89a"][hs%3]),true)
			k.box(Vector3(0,.9,.251),Vector3(.02,1.7,.01),dark,true)
			return AABB(Vector3(-.6,0,-.25),Vector3(1.2,1.8,.5))
		"desk":
			k.box(Vector3(0,.74,0),Vector3(1.6,.06,.8),c("c8a878"),true)
			for x in [-.72,.72]:k.box(Vector3(x,.37,0),Vector3(.06,.74,.7),dark,true)
			k.box(Vector3(0,1.02,-.2),Vector3(.6,.4,.05),c("2a3036"),true);k.box(Vector3(0,1.02,-.17),Vector3(.52,.32,.01),c("5fb8e0"),true)
			k.box(Vector3(0,.4,.6),Vector3(.5,.5,.5),c("3a4652"),true)
			return AABB(Vector3(-.8,0,-.4),Vector3(1.6,1.2,1.2))
		"workbench":
			k.box(Vector3(0,.9,0),Vector3(2.,.1,.8),wood,true)
			for x in [-.9,.9]:k.box(Vector3(x,.45,0),Vector3(.1,.9,.7),metal,true)
			k.box(Vector3(-.5,1.05,0),Vector3(.4,.2,.3),c("c93f3f"),true);k.box(Vector3(.4,1.,.1),Vector3(.5,.1,.2),dark,true)
			return AABB(Vector3(-1.,0,-.4),Vector3(2.,1.15,.8))
		"tool_chest":
			k.box(Vector3(0,.55,0),Vector3(1.,1.1,.55),c("c93f3f"),true)
			for i in range(4):k.box(Vector3(0,.25+i*.24,.28),Vector3(.9,.03,.02),dark,true)
			return AABB(Vector3(-.5,0,-.28),Vector3(1.,1.1,.56))
		"transformer":
			k.box(Vector3(0,.8,0),Vector3(1.6,1.6,1.1),c("8a9a92"),true)
			for i in range(5):k.box(Vector3(-.6+i*.3,.8,.56),Vector3(.12,1.3,.04),c("6f7f78"),true)
			for x in [-.4,0,.4]:k.prism(Vector3(x,1.6,0),.08,.4,c("c8c0a8"),6)
			k.box(Vector3(0,1.2,.59),Vector3(.3,.3,.01),c("f0c23f"),true)
			return AABB(Vector3(-.8,0,-.55),Vector3(1.6,1.6,1.1))
		"bookcase":
			var frame=c("6b4630")
			k.box(Vector3(0,1.1,0),Vector3(2.,2.2,.7),frame,true)
			for side in [-1,1]:
				for r in range(4):
					var y=.2+r*.5
					for i in range(12):
						var x=-.9+i*.15
						k.box(Vector3(x,y+.2,side*.3),Vector3(.12,.36-.04*((hs+i+r)%3),.1),c(["a33a3a","3a5a8a","3a7a4a","c9a03a","6a4a8a","d8cbb0"][(hs+i*3+r)%6]),true)
			return AABB(Vector3(-1.,0,-.35),Vector3(2.,2.2,.7))
		"reading_table":
			k.box(Vector3(0,.76,0),Vector3(2.2,.08,1.),c("8a5a3a"),true)
			for x in [-1.,1.]:
				for z in [-.4,.4]:k.box(Vector3(x,.38,z),Vector3(.08,.76,.08),c("6b4630"),true)
			for x in [-.6,.6]:k.box(Vector3(x,.95,0),Vector3(.25,.3,.25),c("3f6b55"),true)
			return AABB(Vector3(-1.1,0,-.5),Vector3(2.2,.9,1.))
		"globe":
			k.prism(Vector3.ZERO,.3,.1,c("6b4630"),8);k.prism(Vector3(0,.1,0),.05,.7,c("6b4630"),6)
			k.box(Vector3(0,1.05,0),Vector3(.55,.55,.55),c("5a88b8"),true);k.box(Vector3(.05,1.1,0),Vector3(.3,.3,.57),c("7fb56a"),true)
			return AABB(Vector3(-.3,0,-.3),Vector3(.6,1.35,.6))
		"deposit_block":
			k.box(Vector3(0,1.1,0),Vector3(1.8,2.2,.8),c("8a949c"),true)
			for side in [-1,1]:
				for r in range(5):
					for i in range(4):k.box(Vector3(-.6+i*.4,.3+r*.4,side*.41),Vector3(.34,.32,.02),c("c9b27a"),true)
			return AABB(Vector3(-.9,0,-.4),Vector3(1.8,2.2,.8))
		"money_cart":
			k.box(Vector3(0,.5,0),Vector3(1.2,.6,.7),metal,true)
			for i in range(6):k.box(Vector3(-.4+(i%3)*.4,.9+(i/3)*.12,((i%2)-.5)*.2),Vector3(.35,.1,.2),c("7fb56a"),true)
			for x in [-.5,.5]:k.prism(Vector3(x,0,.25),.08,.2,dark,6)
			return AABB(Vector3(-.6,0,-.35),Vector3(1.2,1.1,.7))
		"server_block":
			k.box(Vector3(0,1.05,0),Vector3(2.4,2.1,1.),c("2a3036"),true)
			for side in [-1,1]:
				for i in range(4):
					for r in range(8):
						var p=Vector3(-.9+i*.6,.2+r*.23,side*.51)
						k.box(p,Vector3(.52,.16,.02),c("3a424a"),true)
						k.box(p+Vector3(.2,0,side*.012),Vector3(.04,.04,.01),c(["3fe07a","2fb8e0","3fe07a","f0c23f"][(hs+i+r)%4]),true)
			return AABB(Vector3(-1.2,0,-.5),Vector3(2.4,2.1,1.))
	# Fallback: a crate.
	k.box(Vector3(0,.45,0),Vector3(.9,.9,.9),wood,true)
	return AABB(Vector3(-.45,0,-.45),Vector3(.9,.9,.9))
