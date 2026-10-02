extends RefCounted
class_name DistrictDressing
const M=preload("res://scripts/mesh_factory.gd")
const GATE_DARK=Color("15191d")
const GATE_FRAME=Color("8b8f8a")
const GATE_BAR=Color("4b5157")
## 1.4.6 (the user): a barred grate in the water at the edge of a shallow ditch
## facing the deadly water close by - from the ditch's bed to just under its
## surface, never above the water (seen through the clear water; low enough
## to step over, so no collision). [x, z, x2, z2, nx, nz, bed, top, "fence"],
## n from the shallow water out over the grate. All grates of a map are one mesh.
static func water_fence(kit:DistrictFacade.Kit,g:Array):
	var u=Vector3(g[0],0,g[1]);var v=Vector3(g[2],0,g[3]);var n=Vector3(g[4],0,g[5]).normalized()
	var length=u.distance_to(v);var low=float(g[6]);var top=float(g[7]);var centre=(u+v)*.5-n*.05
	var z=-n;var x=Vector3.UP.cross(z).normalized()
	kit.xf=Transform3D(Basis(x,Vector3.UP,z),centre)
	var post=.06
	for s in [-1.,1.]:kit.box(Vector3(s*(length*.5-post*.5),(low+top)*.5,0),Vector3(post,top-low,post),GATE_FRAME,true)
	kit.box(Vector3(0,top-.02,0),Vector3(length,.04,.05),GATE_FRAME,true)
	var count=maxi(2,int((length-post*2.)/.12))
	for k in range(count+1):kit.box(Vector3(-length*.5+post+(length-post*2.)*k/count,(low+top)*.5,0),Vector3(.025,top-low,.025),GATE_BAR,true,false)
	kit.box(Vector3(0,lerpf(low,top,.45),0),Vector3(length,.025,.025),GATE_BAR,true)
	kit.xf=Transform3D()
static func build(a:Node,plan:Dictionary):
	var index=a.map_index
	a.set_meta("plan_fronts",plan.get("fronts",[])) # access doors take the look of the buildings around them (DoorModels)
	for support in plan.get("supports",[]):
		var base=float(support[3]) if support.size()>3 else 0.
		var height=float(support[2])-base
		if height<.75:continue
		# 1.4.5: a fifth value is the pillar's side (building-mass pillars under
		# covered-room openings are thicker than deck supports).
		var side=float(support[4]) if support.size()>4 else .28
		var pos=Vector3(support[0],base+height*.5,support[1]);var size=Vector3(side,height,side)
		var listed=a.obstacles.size()
		var body=a.box(pos,size,Color("798795"))
		# Pillars at covered-room openings: bots keep a capsule's width from them
		# (the general .6 m margin closed 4 m passages between two pillars).
		if support.size()>4 and a.obstacles.size()>listed:a.obstacles[-1]=Rect2(Vector2(pos.x-side*.5,pos.z-side*.5),Vector2(side,side)).grow(.3)
		for mesh in body.get_children():
			if mesh is MeshInstance3D:mesh.material_override=WorldSurface.material("trim",index)
		M.box(a.architecture,Vector3(pos.x,base+.10,pos.z),Vector3(side+.2,.20,side+.2),Color("8c9696"))
		M.box(a.architecture,Vector3(pos.x,support[2]-.145,pos.z),Vector3(side+.37,.25,side+.22),Color("687982")) # (1.4.7: top 1.5 cm under the shaft's - no shared plane)
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
	for entry in plan.get("doors",[]):
		var origin=Vector3(entry[0],entry[2],entry[1]);var yaw=float(entry[3]);var basis=Basis(Vector3.UP,yaw)
		var opening=3.2
		var wall_height=6.8 if a.indoors else float(plan.get("street_height",3.1))
		for side in [-1,1]:
			var extent=float(entry[4] if side<0 else entry[5]);var width=extent-opening*.5
			if width<.2:continue # (a quay side: the parapet itself closes the gap)
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
	var anchors=plan.props.duplicate();var blockers=[]
	var outdoor=not a.indoors
	for j in range(plan.get("trees",[]).size()):
		var t=plan.trees[j]
		anchors.append([t[0],t[1],t[2],float(j)*1.7,DistrictProps.tree_for(index,j)])
	# Boats stay on the water (authored watercraft).
	# 1.4.6: boats (BoatModels) moored in deep water; a boat beside a quay can be
	# boarded - its deck is flush with the quay where the parapet is open.
	for boat in plan.get("boats",[]):
		var node=Node3D.new();a.architecture.add_child(node);node.position=Vector3(boat[0],boat[2],boat[1]);node.rotation.y=float(boat[3])
		node.set_meta("prop_asset",str(boat[4]));node.set_meta("boat",true)
		var kit=DistrictFacade.Kit.new()
		var parts=BoatModels.build(kit,str(boat[4]),int(absf(boat[0]*7+boat[1]*3))+index,int(boat[6]) if boat.size()>6 else 0)
		var visual=MeshInstance3D.new();visual.mesh=kit.detail.commit();visual.material_override=WorldSurface.material("detail",index,true);node.add_child(visual)
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;node.add_child(body)
		for part in parts:
			var shape=CollisionShape3D.new();shape.shape=part[0];shape.transform=part[1];body.add_child(shape)
	# 1.4.6 (the user): barred fences between safe and deadly water
	# (build_v15.water_fences; the plan key keeps its first name).
	var fences:Array=plan.get("water_gates",[])
	if not fences.is_empty():
		var fence_kit=DistrictFacade.Kit.new()
		var holder=Node3D.new();holder.name="WaterFences";a.architecture.add_child(holder)
		for fence in fences:water_fence(fence_kit,fence)
		var mesh=MeshInstance3D.new();mesh.mesh=fence_kit.detail.commit();mesh.material_override=WorldSurface.material("detail",index,true);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;holder.add_child(mesh)
	# open quay edges beside the boats: a yellow-and-black curb line
	for q in plan.get("open_quays",[]):
		var u=Vector2(q[0],q[1]);var v=Vector2(q[2],q[3]);var n=int(u.distance_to(v)/.5)
		for k in range(n):
			var p=u.lerp(v,(k+.5)/n)
			M.box(a.architecture,Vector3(p.x,.02,p.y),Vector3(.5 if absf(u.x-v.x)>.1 else .18,.04,.5 if absf(u.y-v.y)>.1 else .18),Color("f0c23f") if k%2==0 else Color("2a2a2a"))
	for i in range(anchors.size()):
		var p=anchors[i];var named=p.size()>4
		var pos=Vector3(p[0],float(p[2]) if p.size()>2 else 0.,p[1])
		var kind=str(p[4]) if named else DistrictProps.kind_for(index,i)
		if kind=="streetlight" and not outdoor:kind="crate_stack"
		# 1.4.6: each region of the map has its own theme of props (same size class).
		if not kind.begins_with("tree_"):kind=PropCatalog.themed(kind,index,MapRegions.region(index,pos,a.bounds),i*7+index)
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
		var footprint=occupied if kind.begins_with("tree_") or kind=="streetlight" else visual_bounds
		var fits=func() -> bool:
			for x in [footprint.position.x,footprint.end.x]:
				for z in [footprint.position.z,footprint.end.z]:
					var point=node.transform*Vector3(x,0,z);var levels=DistrictLayout.heights(a,point)
					if levels.is_empty() or absf(float(levels[0])-pos.y)>.12:return false
			# Never cover an objective or a navigation landing.
			var at=node.position
			return not (a.navigation_goals+a.zones).any(func(goal):return Vector2(goal.x-at.x,goal.z-at.z).length()<2.5+footprint.size.length()*.5 and absf(goal.y-at.y)<2.)
		if not fits.call():node.free();continue
		if occupied.size!=Vector3.ZERO:
			# 1.4.2: collision follows the prop's solid parts (DistrictProps.collision);
			# identical in native and Web builds.
			var body=StaticBody3D.new();node.add_child(body);body.collision_layer=1;body.collision_mask=0
			for part in DistrictProps.collision(node,kind,occupied):
				var collision=CollisionShape3D.new();collision.shape=part[0];collision.transform=part[1];body.add_child(collision)
			# 1.4.2: kept for DistrictProps.settle_props (the bake moves props out of
			# walls once the physics space holds the finished geometry).
			node.set_meta("footprint",footprint);node.set_meta("occupied",occupied);node.set_meta("base_y",pos.y);node.set_meta("nav_block",a.navigation_blocks.size())
			a.navigation_blocks.append(node.transform*occupied)
		if kind=="streetlight":
			fixtures.append({"pos":node.transform*Vector3(0,4.3,.6),"direction":Vector3(0,-1,0),"color":Color("ffe2b0"),"range":9.,"energy":2.})
		blockers.append([node.transform,visual_bounds if kind=="streetlight" else footprint,false]) # the lamp arm reaches out over the street
	# 1.4.6 (the user): facades come after the props, boats and doors - no window
	# or facade door is drawn where any of them stands against the wall.
	for node in a.architecture.get_children():
		if node.has_meta("boat"):
			for m in node.get_children():
				if m is MeshInstance3D:blockers.append([node.transform,m.get_aabb(),false])
	for door in a.doors.values():
		for leaf in door.leaves:
			for cs in leaf.get_children():
				if cs is CollisionShape3D and cs.shape is BoxShape3D and cs.is_inside_tree():blockers.append([cs.global_transform,AABB(-cs.shape.size*.5,cs.shape.size),false])
	# ...nor where a pillar, a low wall or a crossing wall of the map stands.
	if a.is_inside_tree():
		var stack:Array=[a]
		while not stack.is_empty():
			var n:Node=stack.pop_back()
			if n.has_meta("prop_asset") or n.has_meta("boat") or n.has_meta("door_id") or n is InteractiveProp:continue
			if n is CollisionShape3D and n.shape is BoxShape3D:blockers.append([n.global_transform,AABB(-n.shape.size*.5,n.shape.size),true])
			if n is CollisionShape3D and n.shape is ConcavePolygonShape3D:
				var faces:PackedVector3Array=n.shape.get_faces();var xf:Transform3D=n.global_transform
				for k in range(0,faces.size(),3):
					var tri=[xf*faces[k],xf*faces[k+1],xf*faces[k+2]]
					blockers.append([Transform3D.IDENTITY,AABB(tri[0],Vector3.ZERO).expand(tri[1]).expand(tri[2]).grow(.05),true,tri])
			stack.append_array(n.get_children())
	DistrictFacade.set_blockers(blockers);DistrictFacade.openings=[]
	fixtures.append_array(DistrictFacade.build(a,dressed))
	DistrictFacade.set_blockers([]);a.set_meta("facade_openings",DistrictFacade.openings);DistrictFacade.openings=[]
	for p in plan.get("loose_props",[]):
		var id=a.props.size();var item=DistrictArt.loose(index,id);var prop=InteractiveProp.new()
		var height={"barrel":.485,"crate":.29,"cone":.31,"canister":.325,"tire":.365}[item]
		# 1.4.5 (the user): junk tyres lie flat or stand, picked per prop (the same
		# on every peer: from the map and the prop's id)
		if item=="tire" and InteractiveProp.tyre_lying(index,id):height=InteractiveProp.TYRE_FLAT;prop.rotation=Vector3(PI*.5,float((id*37+index*11)%360)*PI/180.,0.)
		prop.position=Vector3(p[0],height+(float(p[2]) if p.size()>2 else 0.),p[1]);prop.configure(id,item,a.props_authoritative);a.add_child(prop);a.props[id]=prop
	a.set_meta("wall_fixtures",fixtures)
	a.set_meta("dressing_count",plan.props.size()+plan.facades.size());a.set_meta("interactive_count",a.props.size())
