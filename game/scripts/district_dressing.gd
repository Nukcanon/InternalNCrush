extends RefCounted
class_name DistrictDressing
const M=preload("res://scripts/mesh_factory.gd")
static func build(a:Node,plan:Dictionary):
	var index=a.map_index;var market=index in [7,9,12,17,19,22,24,30];var coastal=index in [0,1,5,21,23,28]
	var garden=index in [10,26];var web=RenderStyle.web()
	# Decorative façades are separate from tactical collision/cover. Their
	# visibility can change with quality without revealing players behind walls.
	var chunks={}
	for i in range(plan.facades.size()):
		var f=plan.facades[i];var key=Vector2i(floori(f[0]/24),floori(f[1]/24))
		if not chunks.has(key):var chunk=Node3D.new();chunk.name="Facade";a.add_child(chunk);chunk.position=Vector3(key.x*24+12,0,key.y*24+12);chunks[key]=chunk
		var n=Node3D.new();chunks[key].add_child(n);n.position=Vector3(f[0],0,f[1])-chunks[key].position;n.rotation.y=f[2]
		var wall=Color("d4c5ac") if market else Color("9aaeb3")
		M.box(n,Vector3(0,2.9,0),Vector3(f[3],.15,.13),Color("536e7b"))
		if market:
			for x in [-1.7,1.7]:
				M.box(n,Vector3(x,1.8,0),Vector3(1.22,1.5,.10),Color("304b58"))
				if not web:
					for side in [-1,1]:M.box(n,Vector3(x+side*.66,1.8,.025),Vector3(.13,1.65,.13),wall)
					M.box(n,Vector3(x,1.02,.10),Vector3(1.5,.13,.30),wall)
			if i%3==0:
				M.box(n,Vector3(0,2.5,.48),Vector3(3.2,.10,.95),Color("a57558") if i%2 else Color("5c8d83"),Vector3(.12,0,0))
		elif i%2==0:
			M.box(n,Vector3(0,1.45,.015),Vector3(2.4,2.7,.08),Color("526c77"))
			if not web:
				for k in range(9):M.box(n,Vector3(0,.3+k*.25,.07),Vector3(2.3,.025,.025),Color("809198"))
		M.merge_children(n)
	for chunk in chunks.values():
		# Flatten all local transforms once, yielding one draw per visible tile.
		for n in chunk.get_children():
			for child in n.get_children():
				var transform=child.global_transform;n.remove_child(child);chunk.add_child(child);child.global_transform=transform
			n.free()
		M.merge_children(chunk)
		for mesh in chunk.get_children():
			if mesh is MeshInstance3D:mesh.set_meta("district_detail",true);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var anchors=plan.props.duplicate()
	if not plan.get("water_boat",[]).is_empty():anchors.append(plan.water_boat)
	for i in range(anchors.size()):
		var floating=i==plan.props.size();var p=anchors[i];var pos=Vector3(p[0],-.5 if floating else 0.,p[1]);var kind="boat" if floating else "tree" if garden or (market and i%4==0) else "boat" if coastal and i%5==0 else "car" if market or coastal else "plant"
		if i==0 and not floating and index!=31:
			utility_room(a,pos);continue
		var node=Node3D.new();a.architecture.add_child(node);node.position=pos
		if kind=="tree":
			M.cylinder(node,Vector3(0,1.6,0),.24,3.2,Color("87745a"),Vector3.ZERO,.15,8)
			M.sphere(node,Vector3(0,3.3,0),Vector3(3.4,2.8,3.4),Color("6d8855"))
		elif kind=="car":
			M.box(node,Vector3(0,.62,0),Vector3(1.85,.7,3.8),Color("758f91"),Vector3.ZERO,.2)
			M.box(node,Vector3(0,1.24,.12),Vector3(1.6,.65,1.85),Color("3c5967"),Vector3.ZERO,.15)
			for x in [-.84,.84]:
				for z in [-1.2,1.2]:M.cylinder(node,Vector3(x,.43,z),.39,.24,Color("293642"),Vector3(0,0,PI/2),-1,10)
		elif kind=="boat":
			M.box(node,Vector3(0,.7,0),Vector3(2.1,1.1,4.),Color("596e7b"),Vector3.ZERO,.5)
			M.box(node,Vector3(0,1.35,-.25),Vector3(1.3,.65,1.7),Color("d2ccc0"))
			M.box(node,Vector3(0,1.5,-1.12),Vector3(1.1,.35,.03),Color("36556b"))
		else:
			WorldDressing.furniture(node,2+i%4,false)
		# Collision is generated before optional detail, identical in both builds.
		var faces=PackedVector3Array()
		for mesh in node.get_children():
			if mesh is MeshInstance3D:
				for point in mesh.mesh.get_faces():faces.append(mesh.transform*point)
		var body=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.collision_mask=0
		var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true;collision.shape=shape;body.add_child(collision)
		a.navigation_blocks.append(AABB(pos-Vector3(1.2,0,2.1),Vector3(2.4,4.8 if kind=="tree" else 2.,4.2)))
		if not web and kind in ["car","boat"]:
			for x in [-.63,.63]:
				M.box(node,Vector3(x,.82,-1.92),Vector3(.35,.2,.04),Color("e4d6a2"))
			M.box(node,Vector3(0,.55,-1.94),Vector3(.5,.18,.04),Color("d6dbd7"))
			for x in [-.82,.82]:M.box(node,Vector3(x,1.36,.10),Vector3(.08,.68,.08),Color("b7beb7"))
		M.merge_children(node)
	for p in plan.get("loose_props",[]):
		var id=a.props.size();var item=WorldDressing.KINDS[id%WorldDressing.KINDS.size()];var prop=InteractiveProp.new()
		var height={"barrel":.485,"crate":.29,"cone":.31,"canister":.325,"tire":.365}[item]
		prop.position=Vector3(p[0],height,p[1]);prop.configure(id,item,a.props_authoritative);a.add_child(prop);a.props[id]=prop
	a.set_meta("dressing_count",plan.props.size()+plan.facades.size());a.set_meta("interactive_count",a.props.size());a.set_meta("facade_tiles",chunks.size())
static func utility_room(a:Node,pos:Vector3):
	# A complete side room, with the door's pockets enclosed by its front wall.
	var paint=Color("899fa4");var trim=Color("405a68")
	for side in [-1,1]:
		a.box(pos+Vector3(side*1.8,1.5,0),Vector3(.24,3.,3.8),paint)
		a.box(pos+Vector3(side*1.525,1.5,-1.8),Vector3(.75,3.,.30),paint)
	a.box(pos+Vector3(0,1.5,1.8),Vector3(3.6,3.,.24),paint)
	a.box(pos+Vector3(0,2.94,0),Vector3(3.84,.18,3.84),trim)
	a.add_door(pos+Vector3(0,0,-1.8))
	a.detail(pos+Vector3(0,2.55,1.65),Vector3(1.4,.12,.10),Color("a5d8d8"))
