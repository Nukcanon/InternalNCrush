extends RefCounted
class_name DistrictDressing
const M=preload("res://scripts/mesh_factory.gd")
static func build(a:Node,plan:Dictionary):
	var index=a.map_index
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
	var fixtures=[]
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
	# 1.4: themed building facades on every street wall (DistrictFacade).
	# Gate walls across streets are dressed on both faces as well.
	var dressed=plan.duplicate();dressed.fronts=plan.get("fronts",[]).duplicate()
	var gate_height=6.8 if a.indoors else float(plan.get("street_height",3.1))
	for entry in plan.get("doors",[]):
		var origin=Vector3(entry[0],entry[2],entry[1]);var basis=Basis(Vector3.UP,float(entry[3]))
		for face in [1,-1]:
			var n=basis.z*face*.14
			for side in [-1,1]:
				var near=origin+basis.x*side*1.6+n;var far=origin+basis.x*side*float(entry[4] if side<0 else entry[5])+n
				var u=near if side*face>0 else far;var v=far if side*face>0 else near
				dressed.fronts.append([u.x,u.z,v.x,v.z,origin.y,origin.y,0.,gate_height,int(abs(origin.x*7+origin.z*3))+side,0])
			var lu=origin-basis.x*face*1.6+n;var lv=origin+basis.x*face*1.6+n
			dressed.fronts.append([lu.x,lu.z,lv.x,lv.z,origin.y,origin.y,2.8,gate_height,int(abs(origin.x*7+origin.z*3)),2])
	fixtures.append_array(DistrictFacade.build(a,dressed))
	for entry in plan.get("doors",[]):
		var origin=Vector3(entry[0],entry[2],entry[1]);var yaw=float(entry[3]);var basis=Basis(Vector3.UP,yaw)
		var opening=3.2
		var wall_height=6.8 if a.indoors else float(plan.get("street_height",3.1))
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
	var outdoor=not a.indoors
	for j in range(plan.get("trees",[]).size()):
		var t=plan.trees[j]
		anchors.append([t[0],t[1],t[2],float(j)*1.7,DistrictProps.tree_for(index,j)])
	# Boats stay on the water (authored watercraft).
	for boat in plan.get("boats",[]):
		var node=Node3D.new();a.architecture.add_child(node);node.position=Vector3(boat[0],boat[2],boat[1]);node.rotation.y=float(boat[3])
		node.set_meta("prop_asset",boat[4]);ImportedWorldProp.build(node,boat[4],Vector3.ONE,"transport_original",true)
	for i in range(anchors.size()):
		var p=anchors[i];var named=p.size()>4
		var pos=Vector3(p[0],float(p[2]) if p.size()>2 else 0.,p[1])
		var kind=str(p[4]) if named else DistrictProps.kind_for(index,i)
		if kind=="streetlight" and not outdoor:kind="crate_stack"
		var node=Node3D.new();a.architecture.add_child(node);node.position=pos
		node.set_meta("prop_asset",kind)
		if p.size()>3:node.rotation.y=float(p[3])
		var occupied:AABB=DistrictProps.build(node,kind,index,i)
		# Verify the complete rotated footprint, not just its anchor. This rejects
		# props that would intersect a wall, a ramp or a stair.
		var visual_bounds=AABB();var first=true
		for mesh in node.get_children():
			if mesh is MeshInstance3D:
				var bounds=mesh.transform*mesh.get_aabb();visual_bounds=bounds if first else visual_bounds.merge(bounds);first=false
		var supported=true
		var footprint=occupied if kind.begins_with("tree_") or kind=="streetlight" else visual_bounds
		for x in [footprint.position.x,footprint.end.x]:
			for z in [footprint.position.z,footprint.end.z]:
				var point=node.transform*Vector3(x,0,z);var levels=DistrictLayout.heights(a,point)
				if levels.is_empty() or absf(float(levels[0])-pos.y)>.12:supported=false
		if not supported:node.free();continue
		if kind=="streetlight":
			fixtures.append({"pos":node.transform*Vector3(0,4.3,.6),"direction":Vector3(0,-1,0),"color":Color("ffe2b0"),"range":9.,"energy":2.})
		if occupied.size==Vector3.ZERO:continue
		# One box collider per prop: identical cover in native and Web builds.
		var body=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.collision_mask=0
		var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=occupied.size;collision.shape=shape;collision.position=occupied.get_center();body.add_child(collision)
		a.navigation_blocks.append(node.transform*occupied)
	for p in plan.get("loose_props",[]):
		var id=a.props.size();var item=DistrictArt.loose(index,id);var prop=InteractiveProp.new()
		var height={"barrel":.485,"crate":.29,"cone":.31,"canister":.325,"tire":.365}[item]
		prop.position=Vector3(p[0],height+(float(p[2]) if p.size()>2 else 0.),p[1]);prop.configure(id,item,a.props_authoritative);a.add_child(prop);a.props[id]=prop
	a.set_meta("wall_fixtures",fixtures)
	a.set_meta("dressing_count",plan.props.size()+plan.facades.size());a.set_meta("interactive_count",a.props.size())
