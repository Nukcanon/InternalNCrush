extends RefCounted
class_name DistrictDressing
const M=preload("res://scripts/mesh_factory.gd")
static func build(a:Node,plan:Dictionary):
	var index=a.map_index;var market=index in [7,9,12,17,19,22,24,30];var coastal=index in [0,1,5,21,23,28]
	var garden=index in [10,26];var web=RenderStyle.web()
	for support in plan.get("supports",[]):
		var pos=Vector3(support[0],support[2]*.5,support[1]);var size=Vector3(.28,support[2],.28)
		var body=a.box(pos,size,Color("798795"))
		for mesh in body.get_children():
			if mesh is MeshInstance3D:mesh.material_override=WorldSurface.material("trim",index)
		M.box(a.architecture,Vector3(pos.x,.10,pos.z),Vector3(.48,.20,.48),Color("8c9696"))
		M.box(a.architecture,Vector3(pos.x,support[2]-.13,pos.z),Vector3(.65,.25,.5),Color("687982"))
	# Decorative façades are separate from tactical collision/cover. Their
	# visibility can change with quality without revealing players behind walls.
	var chunks={};var fixtures=[]
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
			if i%3==0 and index in [7,17]:
				M.box(n,Vector3(0,2.5,.48),Vector3(3.2,.10,.95),Color("a57558") if i%2 else Color("5c8d83"),Vector3(.12,0,0))
		elif i%2==0:
			M.box(n,Vector3(0,1.45,.015),Vector3(2.4,2.7,.08),Color("526c77"))
			if not web:
				for k in range(9):M.box(n,Vector3(0,.3+k*.25,.07),Vector3(2.3,.025,.025),Color("809198"))
		facade_details(n,i,market,web,index)
		if i%2==0:
			var local=Vector3(-2.5,2.26,.60) if market else Vector3(-2.25,2.32,.50)
			fixtures.append({"pos":n.global_transform*local,"direction":n.global_basis*Vector3(0,-1,.5),"color":Color("ffd49a") if market else Color("c1e1eb"),"range":8.,"energy":4.5})
		M.merge_children(n)
	for chunk in chunks.values():
		# Flatten all local transforms once, yielding one draw per visible tile.
		for n in chunk.get_children():
			for child in n.get_children():
				var transform=child.global_transform;n.remove_child(child);chunk.add_child(child);child.global_transform=transform
			n.free()
		# The first merge already produces ShaderMaterials. merge_children only
		# accepts StandardMaterials, so it could not actually batch these facades.
		var combined=SurfaceTool.new();combined.begin(Mesh.PRIMITIVE_TRIANGLES)
		for child in chunk.get_children():
			if child is MeshInstance3D:
				for surface in range(child.mesh.get_surface_count()):combined.append_from(child.mesh,surface,child.transform)
				child.free()
		combined.index();var geometry=MeshInstance3D.new();geometry.mesh=combined.commit();chunk.add_child(geometry)
		for mesh in chunk.get_children():
			if mesh is MeshInstance3D:mesh.set_meta("district_detail",true);mesh.material_override=WorldSurface.material("detail",index,true);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.set_meta("wall_fixtures",fixtures)
	var anchors=plan.props.duplicate()
	if not plan.get("water_boat",[]).is_empty():anchors.append(plan.water_boat)
	for i in range(anchors.size()):
		var floating=i==plan.props.size();var p=anchors[i];var pos=Vector3(p[0],-.5 if floating else 0.,p[1]);var kind="boat" if floating else "tree" if garden or (market and i%4==0) else "container" if coastal and i%3==0 else "car" if market or coastal else "tank"
		if i==0 and not floating and index!=31:
			utility_room(a,pos);continue
		var node=Node3D.new();a.architecture.add_child(node);node.position=pos
		var imported=kind in ["container","tank","car","tree","boat"]
		if kind in ["container","tank"]:
			ImportedWorldProp.build(node,("shipping-container-a" if i%2==0 else "shipping-container-b") if kind=="container" else ("detail-tank" if i%2==0 else "detail-tank-large"),Vector3(2.2,2.8,4.))
		elif kind=="tree":
			ImportedWorldProp.build(node,"tree_pineTallA" if index in [10,26] else "tree_oak",Vector3(3.4,4.8,3.4),"nature")
		elif kind=="car":
			ImportedWorldProp.build(node,"van" if coastal else "taxi" if index in [7,17] and i%3==1 else "sedan",Vector3(1.85,2.1,3.8),"car")
		elif kind=="boat":
			ImportedWorldProp.build(node,"boat-fishing-small" if index in [5,21] else "boat-tug-c",Vector3(2.1,2.4,4.),"watercraft")
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
		if not imported:
			M.merge_children(node)
			for mesh in node.get_children():
				if mesh is MeshInstance3D:mesh.material_override=WorldSurface.material("detail",index,true)
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

static func facade_details(n:Node3D,id:int,market:bool,web:bool,index:int):
	# Low-poly landmarks are shared by both builds and merged into static tiles.
	var dark=Color("34434a");var stone=Color("d6c9ad");var timber=Color("826147")
	if market:
		for x in [-1.7,1.7]:
			M.box(n,Vector3(x,1.8,.085),Vector3(.055,1.4,.10),stone)
			M.box(n,Vector3(x,1.8,.085),Vector3(1.2,.055,.10),stone)
			for side in [-1,1]:M.box(n,Vector3(x+side*.75,1.8,.03),Vector3(.23,1.55,.12),timber)
		if index==17 and id%3==0:
			for x in [-1.45,1.45]:M.box(n,Vector3(x,1.22,.88),Vector3(.065,2.44,.065),timber)
			M.box(n,Vector3(0,.63,.63),Vector3(2.65,.12,.62),timber)
			for x in [-.85,0.,.85]:
				M.box(n,Vector3(x,.79,.63),Vector3(.7,.22,.46),Color("987751"))
				for k in range(3):M.box(n,Vector3(x-.20+k*.20,.94,.62),Vector3(.16,.12,.17),Color("c39556") if id%2==0 else Color("8ea665"))
	else:
		if id%3==0:
			M.box(n,Vector3(2.15,1.7,.13),Vector3(.65,.95,.28),Color("738b8d"))
			for j in range(5):M.box(n,Vector3(2.15,1.4+j*.13,.285),Vector3(.50,.035,.045),dark)
			M.cylinder(n,Vector3(2.55,1.2,.15),.07,2.35,Color("a2b0aa"),Vector3.ZERO,-1,8)
	# Wall-mounted lantern: all parts connect to a bracket, no floating light.
	if id%2==0 and market:
		M.box(n,Vector3(-2.5,2.45,.05),Vector3(.16,.35,.10),dark)
		M.box(n,Vector3(-2.5,2.57,.24),Vector3(.07,.07,.48),dark)
		M.box(n,Vector3(-2.5,2.26,.42),Vector3(.25,.38,.22),Color("edd8a3"))
		for y in [2.05,2.47]:M.box(n,Vector3(-2.5,y,.42),Vector3(.32,.055,.29),dark)
		for x in [-2.64,-2.36]:M.box(n,Vector3(x,2.26,.54),Vector3(.025,.40,.025),dark)
	elif id%2==0:
		# Industrial bulkhead/strip lights, not the town's hanging lanterns.
		var size=Vector3(1.1,.18,.18) if index in [3,6,14,20,27,29] else Vector3(.38,.45,.22)
		M.box(n,Vector3(-2.25,2.32,.11),size+Vector3(.12,.12,.09),dark)
		M.box(n,Vector3(-2.25,2.32,.24),size,Color("d5e6d4") if index in [3,14,29] else Color("e5c996"))
		for j in [-1,0,1]:M.box(n,Vector3(-2.25+j*size.x*.30,2.32,.35),Vector3(.035,size.y+.06,.025),dark)
	# A short draped banner provides large-scale variation without alpha overdraw.
	if id%5==1 and market:
		M.cylinder(n,Vector3(.1,2.62,.1),.025,1.35,dark,Vector3(0,0,PI/2),-1,6)
		for j in range(3):M.box(n,Vector3(-.31+j*.42,2.17,.15+j*.04),Vector3(.43,.85,.035),[Color("7e9f87"),Color("d8c696"),Color("ab6756")][(id+j)%3],Vector3(0,.08*j,0))
	if id%7==2 and index in [7,9,10,12,17,19,24,26,30]:
		# Sparse opaque leaf clusters, never a transparent full-wall plane.
		for j in range(8 if web else 14):
			var x=2.3+sin(j*1.7)*.32;var y=.35+j*.17
			M.box(n,Vector3(x,y,.12),Vector3(.21,.13,.055),Color("638257") if j%2 else Color("879b63"),Vector3(0,0,j*.7))
