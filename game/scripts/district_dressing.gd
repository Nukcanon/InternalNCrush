extends RefCounted
class_name DistrictDressing
const M=preload("res://scripts/mesh_factory.gd")
static func build(a:Node,plan:Dictionary):
	var index=a.map_index;var market=index in [7,9,12,17,19,22,24,30];var coastal=index in [0,1,5,21,23,28]
	var garden=index in [10,26];var web=RenderStyle.web()
	for support in plan.get("supports",[]):
		var base=float(support[3]) if support.size()>3 else 0.
		var height=float(support[2])-base
		if height<.75:continue
		var pos=Vector3(support[0],base+height*.5,support[1]);var size=Vector3(.28,height,.28)
		var body=a.box(pos,size,Color("798795"))
		for mesh in body.get_children():
			if mesh is MeshInstance3D:mesh.material_override=WorldSurface.material("trim",index)
		M.box(a.architecture,Vector3(pos.x,base+.10,pos.z),Vector3(.48,.20,.48),Color("8c9696"))
		M.box(a.architecture,Vector3(pos.x,support[2]-.13,pos.z),Vector3(.65,.25,.5),Color("687982"))
	# Decorative fa챌ades are separate from tactical collision/cover. Their
	# visibility can change with quality without revealing players behind walls.
	var chunks={};var fixtures=[]
	for anchor in plan.get("room_ceiling_lights",[]):
		var pos=Vector3(anchor[0],anchor[1]-.12,anchor[2])
		M.box(a.architecture,pos,Vector3(.9,.12,.4),Color("48545a"))
		M.box(a.architecture,pos-Vector3.UP*.075,Vector3(.78,.025,.3),Color("efdfbb"))
		fixtures.append({"pos":pos-Vector3.UP*.16,"direction":Vector3(.01,-1,0),"color":Color("ffedcd"),"range":9.,"energy":4.})
	if float(plan.get("ceiling_height",0.))>0.:
		for i in range(0,plan.props.size(),3):
			var anchor=plan.props[i];var pos=Vector3(anchor[0],float(anchor[2])+float(plan.ceiling_height)-.12,anchor[1])
			M.box(a.architecture,pos,Vector3(1.4,.12,.5),Color("3d4c52"))
			M.box(a.architecture,pos-Vector3.UP*.075,Vector3(1.24,.025,.36),Color("efdfbb"))
			fixtures.append({"pos":pos-Vector3.UP*.16,"direction":Vector3(.01,-1,0),"color":Color("ffedcd"),"range":12.,"energy":5.})
	for i in range(plan.facades.size()):
		var f=plan.facades[i];var key=Vector2i(floori(f[0]/24),floori(f[1]/24))
		if not chunks.has(key):var chunk=Node3D.new();chunk.name="Facade";a.add_child(chunk);chunk.position=Vector3(key.x*24+12,0,key.y*24+12);chunks[key]=chunk
		var n=Node3D.new();chunks[key].add_child(n);n.position=Vector3(f[0],float(f[4]) if f.size()>4 else 0.,f[1])-chunks[key].position;n.rotation.y=f[2]
		# Each window is one complete authored unit, with separated depth layers.
		var lot=Vector2i(floori(f[0]/12.),floori(f[1]/12.))
		var variant=absi(lot.x*17+lot.y*37+index*11)%40
		if index in [3,14,20,29]:variant=20+variant%15
		for x in [-1.65,1.65]:
			var before=n.get_child_count()
			# Fit the opening in width/height without shrinking a whole window just
			# because its authored sun hood projects farther than a plain frame.
			ImportedWorldProp.build(n,"window_%02d"%variant,Vector3(1.9,1.8,.55),"windows_web" if web else "windows_original")
			var meshes=n.get_children().slice(before);var bounds=AABB();var first=true
			for mesh in meshes:
				var box=mesh.transform*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
			# Some thin variants have their glazing at the backmost depth. Embedding
			# the whole model hides those panes inside the wall; seat the back face
			# 2 mm forward instead, without the old visible floating gap.
			for mesh in meshes:mesh.position+=Vector3(x,.87,-bounds.position.z+.002)
		facade_details(n,i,market,web,index)
		if i%2==0:
			var local=Vector3(0,2.26,.60) if market else Vector3(0,2.32,.50)
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
	for entry in plan.get("doors",[]):
		var origin=Vector3(entry[0],entry[2],entry[1]);var yaw=float(entry[3]);var basis=Basis(Vector3.UP,yaw)
		var opening=3.2
		var wall_height=6.8 if a.indoors else 3.1
		for side in [-1,1]:
			var extent=float(entry[4] if side<0 else entry[5]);var width=extent-opening*.5
			var centre=origin+basis*Vector3(side*(opening*.5+width*.5),wall_height*.5,0)
			var prior_blocks=a.navigation_blocks.size();var prior_obstacles=a.obstacles.size()
			var body=a.solid_rotated(centre,Vector3(width,wall_height,.28),Color("8e9f94"),yaw)
			# Narrow navigation bounds follow diagonal walls instead of sealing
			# the doorway with the large rotated box's enclosing rectangle.
			a.navigation_blocks.resize(prior_blocks);a.obstacles.resize(prior_obstacles)
			var sections=maxi(1,ceili(width/.5))
			for section in range(sections):
				var local=AABB(Vector3(-width*.5+section*width/sections,-wall_height*.5,-.14),Vector3(width/sections,wall_height,.28))
				a.navigation_blocks.append(Transform3D(basis,centre)*local)
			for child in body.get_children():
				if child is MeshInstance3D:child.material_override=WorldSurface.material("wall",index)
		a.solid_rotated(origin+Vector3.UP*(2.8+wall_height)*.5,Vector3(opening,wall_height-2.8,.30),Color("b7c5b0"),yaw)
		a.add_door(origin,yaw,opening)
	var anchors=plan.props.duplicate()
	anchors.append_array(plan.get("vehicles",[]));anchors.append_array(plan.get("boats",[]))
	for j in range(plan.get("trees",[]).size()):
		var t=plan.trees[j];var species=(index+j)%10
		if coastal:species=[0,3,5,7][(index+j)%4]
		anchors.append([t[0],t[1],t[2],0.,"tree_%02d"%(species*3+(j%3))])
	for i in range(anchors.size()):
		var p=anchors[i];var transport=p.size()>4
		var pos=Vector3(p[0],float(p[2]) if p.size()>2 else 0.,p[1]);var region=(1 if pos.x>0 else 0)+(2 if pos.z>0 else 0)
		var kind=str(p[4]) if transport else DistrictArt.prop(index,i,region)
		if not transport and i%3==1:
			var tables=["round_cafe_table","picnic_table","console_table"] if market or garden else ["writing_desk","folding_table"]
			if index in [22,27]:tables=["writing_desk","console_table"]
			kind=tables[(index+i)%tables.size()]
		# One dock service cabin, not an identical room cloned into every map.
		if index==0 and i==0:
			utility_room(a,pos);continue
		var node=Node3D.new();a.architecture.add_child(node);node.position=pos
		node.set_meta("prop_asset",kind)
		if p.size()>3:node.rotation.y=float(p[3])
		var imported=true
		if kind.begins_with("tree_"):
			ImportedWorldProp.build(node,kind,Vector3.ONE,"trees_original",true)
		elif transport:
			ImportedWorldProp.build(node,kind,Vector3.ONE,"transport_original",true)
		elif DistrictArt.original(kind):
			var pack=DistrictArt.pack(kind)
			ImportedWorldProp.build(node,kind,Vector3(2.5,2.8,2.),pack,pack=="places_original")
		elif kind in ["container","tank"]:
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
		var faces=PackedVector3Array();var occupied=AABB();var first_mesh=true
		for mesh in node.get_children():
			if mesh is MeshInstance3D:
				var bounds=mesh.transform*mesh.get_aabb();occupied=bounds if first_mesh else occupied.merge(bounds);first_mesh=false
				for point in mesh.mesh.get_faces():faces.append(mesh.transform*point)
		# Verify the complete rotated footprint, not just its anchor. This rejects
		# oversized furnishings that would intersect a wall or a staircase.
		if not transport:
			var supported=true
			for x in [occupied.position.x,occupied.end.x]:
				for z in [occupied.position.z,occupied.end.z]:
					var point=node.transform*Vector3(x,0,z);var levels=DistrictLayout.heights(a,point)
					if levels.is_empty() or absf(float(levels[0])-pos.y)>.12:supported=false
			if not supported:node.free();continue
		var body=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.collision_mask=0
		var collision=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true;collision.shape=shape;body.add_child(collision)
		a.navigation_blocks.append(node.transform*occupied)
		DistrictSetdressing.decorate(node,kind,index,i)
		if not imported:
			M.merge_children(node)
			for mesh in node.get_children():
				if mesh is MeshInstance3D:mesh.material_override=WorldSurface.material("detail",index,true)
	for p in plan.get("loose_props",[]):
		var id=a.props.size();var item=DistrictArt.loose(index,id);var prop=InteractiveProp.new()
		var height={"barrel":.485,"crate":.29,"cone":.31,"canister":.325,"tire":.365}[item]
		prop.position=Vector3(p[0],height+(float(p[2]) if p.size()>2 else 0.),p[1]);prop.configure(id,item,a.props_authoritative);a.add_child(prop);a.props[id]=prop
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
	# Wall-mounted lantern: all parts connect to a bracket, no floating light.
	if id%2==0 and market:
		M.box(n,Vector3(0,2.45,.05),Vector3(.16,.35,.10),dark)
		M.box(n,Vector3(0,2.57,.24),Vector3(.07,.07,.48),dark)
		M.box(n,Vector3(0,2.26,.42),Vector3(.25,.38,.22),Color("edd8a3"))
		for y in [2.05,2.47]:M.box(n,Vector3(0,y,.42),Vector3(.32,.055,.29),dark)
		for x in [-.14,.14]:M.box(n,Vector3(x,2.26,.54),Vector3(.025,.40,.025),dark)
	elif id%2==0:
		# Industrial bulkhead/strip lights, not the town's hanging lanterns.
		var size=Vector3(1.1,.18,.18) if index in [3,6,14,20,27,29] else Vector3(.38,.45,.22)
		M.box(n,Vector3(0,2.32,.11),size+Vector3(.12,.12,.09),dark)
		M.box(n,Vector3(0,2.32,.24),size,Color("d5e6d4") if index in [3,14,29] else Color("e5c996"))
		for j in [-1,0,1]:M.box(n,Vector3(j*size.x*.30,2.32,.35),Vector3(.035,size.y+.06,.025),dark)
	# Loose floating leaf rectangles were removed; rooted trees provide greenery.
