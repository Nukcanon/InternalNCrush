extends Node3D
class_name Arena
const M=preload("res://scripts/mesh_factory.gd")
var water_rect=Rect2(-9,-33,18,66)
var has_water=true
var spawn_points=[[],[]]
var ffa_spawns=[]
var supplies=[]
var sites=[Vector3(-44,0,-23),Vector3(44,0,23)]
var zones=[Vector3(-44,0,-23),Vector3(0,0,0),Vector3(44,0,23)]
var obstacles=[]
var mats={}
var map_index=0
var indoors=false
var bounds=Vector2(100,90)
var building=false
var playable_polygon=PackedVector2Array()
var walk_surfaces=[]
var floor_holes=[]
var navigation_goals=[]
var navigation_blocks=[]
var navigation_block_cells={}
var navigation_block_count=-1
var vertical_map=false
var props_authoritative=false
var props={}
var doors={}
func add_door(pos:Vector3,yaw:float=0.):
	var door=InteractiveDoor.new();add_child(door);var id=doors.size()+1;door.build(self,id,pos,yaw);doors[id]=door
func door_states() -> Array:
	var states=[]
	for door in doors.values():states.append({"id":door.door_id,"open":door.opened,"progress":door.progress})
	return states
func receive_doors(states:Array):
	for state in states:
		if doors.has(int(state.id)):doors[int(state.id)].opened=state.open;doors[int(state.id)].progress=state.progress;doors[int(state.id)].apply_pose()
var architecture:Node3D
var chunk_count=0
var world_font:Font
func mat(color:Color,emission:bool=false) -> StandardMaterial3D:
	var key=str(color)+str(emission)
	if mats.has(key):return mats[key]
	var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.86
	m.set_meta("surface_kind",SurfaceFinish.material_kind(color))
	if color.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.3
	mats[key]=m;return m
func box(pos:Vector3,size:Vector3,color:Color,solid=true,parent:Node=null) -> Node3D:
	if parent==null:parent=architecture if building else self
	var node:Node3D=StaticBody3D.new() if solid else Node3D.new();parent.add_child(node);node.position=pos
	var mesh=MeshInstance3D.new();var b=BoxMesh.new();b.size=size;mesh.mesh=b;mesh.material_override=mat(color);node.add_child(mesh)
	if solid:
		node.collision_layer=1;node.collision_mask=0
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;node.add_child(c)
		if vertical_map:navigation_blocks.append(AABB(pos-size*.5,size))
		if building and pos.y+size.y*.5>.35 and pos.y-size.y*.5<1.9:obstacles.append(Rect2(Vector2(pos.x-size.x*.5,pos.z-size.z*.5),Vector2(size.x,size.z)).grow(.6))
	return node
func text3d(txt:String,pos:Vector3,color:Color,size:int=32,parent:Node=null):
	if world_font==null and ResourceLoader.exists("res://assets/Korean.ttf"):
		var f=FontVariation.new();f.base_font=load("res://assets/Korean.ttf");f.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):650.0};world_font=f
	var l=Label3D.new();l.font=world_font;l.outline_size=8;l.outline_modulate=Color("102535");l.text=txt;l.position=pos;l.font_size=size;l.pixel_size=.008;l.modulate=color;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.no_depth_test=false;l.visibility_range_end=60;l.visibility_range_end_margin=10
	(parent if parent else self).add_child(l);return l
func detail(pos:Vector3,size:Vector3,color:Color,rot=Vector3.ZERO):
	return M.box(architecture,pos,size,color,rot,.08)
func pipe(pos:Vector3,radius:float,length:float,color:Color,rot=Vector3.ZERO):return M.cylinder(architecture,pos,radius,length,color,rot)
func warehouse(pos:Vector3,style:int):
	var wall=Color("c8b795") if style==0 else Color("b9c6c8")
	var trim=Color("536e7b") if style==0 else Color("9b7256")
	for x in [-8.5,8.5]:
		box(pos+Vector3(x,3.6,0),Vector3(9,7.2,20),wall)
		for z in [-10.08,10.08]:
			detail(pos+Vector3(x,.42,z),Vector3(9.1,.84,.12),trim)
			for wx in [-2.7,0,2.7]:
				detail(pos+Vector3(x+wx,4.45,z),Vector3(1.95,2.55,.1),Color("f0e3c9"))
				detail(pos+Vector3(x+wx,4.45,z+sign(z)*.061),Vector3(1.6,2.22,.1),Color("354f61"))
				detail(pos+Vector3(x+wx,4.45,z+sign(z)*.13),Vector3(.075,2.2,.025),trim)
				detail(pos+Vector3(x+wx,4.45,z+sign(z)*.13),Vector3(1.6,.075,.025),trim)
		for side in [-1,1]:detail(pos+Vector3(x+side*4.38,3.65,0),Vector3(.18,7.3,20.3),Color("ded4bf"))
	box(pos+Vector3(0,6.5,0),Vector3(8,1.4,20),wall)
	for z in [-10.2,10.2]:
		detail(pos+Vector3(0,5.7,z),Vector3(8.3,.35,.34),trim)
		detail(pos+Vector3(0,7.35,z),Vector3(27,.4,.38),trim)
		for x in [-4.05,4.05]:detail(pos+Vector3(x,2.8,z),Vector3(.3,5.6,.3),trim)
		for x in [-2.7,2.7]:detail(pos+Vector3(x,5.1,z),Vector3(.12,1.5,.14),trim,Vector3(0,0,sign(x)*.6))
	detail(pos+Vector3(0,7.25,0),Vector3(27,.22,21.4),Color("4e646e"))
	for x in [-7,7]:
		detail(pos+Vector3(x,7.7,-1),Vector3(2.4,.8,3.4),Color("83999d"))
		for z in [-1.8,-1.3,-.8,-.3]:detail(pos+Vector3(x,8.12,z),Vector3(2.1,.04,.08),trim)
	pipe(pos+Vector3(12.8,2.5,9.8),.13,5.,trim)
func container_box(pos:Vector3,color:Color,length=8.):
	box(pos+Vector3(0,1.4,0),Vector3(length,2.8,3.),color)
	for i in range(int(length/.45)):
		detail(pos+Vector3(-length*.5+.2+i*.45,1.4,-1.52),Vector3(.05,2.65,.04),color.lightened(.16))
		detail(pos+Vector3(-length*.5+.2+i*.45,1.4,1.52),Vector3(.05,2.65,.04),color.darkened(.18))
	for x in [-length*.5-.02,length*.5+.02]:
		for z in [-.8,.8]:detail(pos+Vector3(x,1.4,z),Vector3(.035,2.6,.045),Color("bdc3b3"))
		detail(pos+Vector3(x,1.4,0),Vector3(.03,2.7,.065),Color("314c59"))
	for z in [-1.5,1.5]:detail(pos+Vector3(0,2.83,z),Vector3(length+.08,.1,.1),color.darkened(.3))
func crate(pos:Vector3,size=Vector3(2.2,1.7,2.2)):
	var wood=Color("ae8b5d");box(pos+Vector3(0,size.y*.5,0),size,wood)
	for x in [-size.x*.5+.12,size.x*.5-.12]:
		for z in [-size.z*.5-.015,size.z*.5+.015]:detail(pos+Vector3(x,size.y*.5,z),Vector3(.13,size.y,.08),Color("dbc099"))
	for y in [.16,size.y-.16]:
		for z in [-size.z*.5-.05,size.z*.5+.05]:detail(pos+Vector3(0,y,z),Vector3(size.x,.13,.08),Color("d0b186"))
	for z in [-size.z*.5-.10,size.z*.5+.10]:detail(pos+Vector3(0,size.y*.5,z),Vector3(.12,size.y*.9,.09),Color("c8a577"),Vector3(0,0,-.75))
func cover(pos:Vector3,width=4.):
	box(pos+Vector3(0,.58,0),Vector3(width,1.16,.76),Color("8f9c9c"))
	M.tapered(architecture,pos+Vector3(0,.64,0),Vector3(width+.04,1.25,.9),Color("b2b6a7"),.68)
	detail(pos+Vector3(0,1.28,0),Vector3(width+.12,.13,.69),Color("d6d2bd"))
	for x in [-width*.37,width*.37]:
		detail(pos+Vector3(x,.14,0),Vector3(.5,.28,1.35),Color("74868a"))
		for z in [-.53,.53]:pipe(pos+Vector3(x,.29,z),.035,.018,Color("b5bdba"))
	for side in [-1,1]:
		detail(pos+Vector3(0,.92,side*.41),Vector3(width-.2,.16,.025),Color("3d535e"))
		for i in range(maxi(2,int(width/.55))):
			detail(pos+Vector3(-width*.42+i*.52,.93,side*.427),Vector3(.12,.17,.017),Color("d7b260"),Vector3(0,0,-.4))
		for x in [-width*.45,width*.45]:pipe(pos+Vector3(x,.58,side*.45),.028,.02,Color("66777b"),Vector3(PI/2,0,0))
func tree(pos:Vector3):
	var trunk=StaticBody3D.new();architecture.add_child(trunk);trunk.position=pos;trunk.collision_layer=1;trunk.collision_mask=0
	var collision=CollisionShape3D.new();var shape=CylinderShape3D.new();shape.radius=.32;shape.height=3.8;collision.shape=shape;collision.position.y=1.9;trunk.add_child(collision)
	M.cylinder(trunk,Vector3(0,1.9,0),.36,3.8,Color("87745a"),Vector3.ZERO,.18,16)
	obstacles.append(Rect2(Vector2(pos.x-.85,pos.z-.85),Vector2(1.7,1.7)))
	for i in range(7):
		var angle=i*2.399;var end=Vector3(cos(angle)*1.1,3.4+float(i%3)*.55,sin(angle)*1.1)
		HumanModel.cord(trunk,Vector3(0,2.2+i*.12,0),end,.07,Color("87745a"))
		HumanModel.oval(trunk,end+Vector3.UP*.6,Vector3(2.6,2.1,2.5),Color("779261") if i%2==0 else Color("94a678"))
func build(which:int):
	if DefusalLayout.enabled(which) or which==PracticeLayout.INDEX:
		map_index=which;building=true;architecture=Node3D.new();architecture.name="Architecture";add_child(architecture)
		if which==PracticeLayout.INDEX:PracticeLayout.build(self)
		else:DefusalLayout.build(self,which)
		WorldDressing.build(self);building=false;SurfaceCleanup.clean(architecture);batch_architecture();apply_surface_detail();ArenaLighting.build(self);return
	map_index=which;vertical_map=VerticalLayout.enabled(which);indoors=which in [2,3,6,8,11,14,15];has_water=which in [0,5];bounds=MapLayouts.extent(which);building=true;architecture=Node3D.new();architecture.name="Architecture";add_child(architecture)
	if not vertical_map:box(Vector3(0,-.5,0),Vector3(bounds.x*2,1,bounds.y*2),Color("b9b5a5") if has_water else Color("c5b69a"))
	build_perimeter(which)
	if vertical_map:VerticalLayout.build(self,which)
	elif which<2:
		# Broad navigation lanes, traversable warehouse passages, and readable cover heights.
		for x in [-44,0,44]:detail(Vector3(x,.035,0),Vector3(22,.018,172),Color("a2acaa"))
		for z in [-75,0,75]:detail(Vector3(0,.07,z),Vector3(190,.018,12),Color("a2acaa"))
		for sx in [-1,1]:
			for sz in [-1,1]:
				warehouse(Vector3(sx*43,0,sz*51),which)
				container_box(Vector3(sx*79,0,sz*26),Color("608e90") if sz<0 else Color("b06d57"),12.)
				container_box(Vector3(sx*79,2.8,sz*26),Color("839da2"),10.)
				for k in range(3):cover(Vector3(sx*(22+k*13),0,sz*9))
				crate(Vector3(sx*23,0,sz*34),Vector3(7,2.1,3.))
				crate(Vector3(sx*66,0,sz*63),Vector3(3.6,2.4,3.6))
				crate(Vector3(sx*69.7,0,sz*62),Vector3(2.5,1.5,2.5))
				container_box(Vector3(sx*81,0,sz*60),Color("c9b374"),9.)
				for tx in [87,94]:tree(Vector3(sx*tx,0,sz*77))
				# Harbor crane silhouette stays outside playable lanes.
				for z in [-4,4]:detail(Vector3(sx*95,10,sz*45+z),Vector3(.8,20,.8),Color("b18b51"))
				detail(Vector3(sx*88,20,sz*45),Vector3(17,.8,8.8),Color("c09b60"))
			for z in [-69,-42,-14,14,42,69]:
				cover(Vector3(sx*12,0,z),3.5)
			for i in range(8):
				var spawn=Vector3(-68+i*19,.15,sx*77);spawn_points[0 if sx<0 else 1].append(spawn);ffa_spawns.append(spawn)
			for x in [-70,-32,32,70]:
				detail(Vector3(x,.02,sx*83),Vector3(10,.018,.12),Color("e6d7ac"))
				for k in range(4):detail(Vector3(x-3+k*2,.02,sx*81),Vector3(.15,.02,3.5),Color("e6d7ac"))
			text3d("NORTH TERMINAL" if sx<0 else "SOUTH TERMINAL",Vector3(0,3.3,sx*88),Color("f3eddb"),65).pixel_size=.015
		if has_water:
			var water=box(Vector3(0,.31,0),Vector3(18,.6,66),Color(.18,.52,.59,.50),false)
			var shader=Shader.new();shader.code="shader_type spatial; render_mode blend_mix, cull_disabled; uniform vec4 tint : source_color = vec4(0.12,0.47,0.53,0.5); void fragment(){float ripple=sin(UV.x*100.0+TIME*0.7)*sin(UV.y*55.0-TIME*0.4); ALBEDO=tint.rgb+vec3(ripple*0.035); ROUGHNESS=0.3; ALPHA=tint.a;}"
			var material=ShaderMaterial.new();material.shader=shader;water.get_child(0).material_override=material
			for x in [-9.3,9.3]:detail(Vector3(x,.17,0),Vector3(.6,.32,66.6),Color("cfceba"))
			for z in [-35,35]:detail(Vector3(0,.07,z),Vector3(20,.14,2.2),Color("849e9f"))
		else:
			for z in [-24,24]:container_box(Vector3(0,0,z),Color("a48668"),11.)
	elif which<6:MapLayouts.build(self,which)
	elif which in [7,9,16,17]:UrbanLayout.build(self,which)
	else:MapLayouts.build_sized(self,which)
	for i in range(zones.size()):
		var pos=zones[i]
		for x in [-6,6]:detail(pos+Vector3(x,.12,0),Vector3(.16,.018,12),Color("e3bf68"))
		for z in [-6,6]:detail(pos+Vector3(0,.12,z),Vector3(11.7,.018,.16),Color("e3bf68"))
		text3d(["A","C","B"][i],pos+Vector3(0,3.4,0),Color("f5e0a1"),65)
		if i!=1:
			box(pos+Vector3(-5,.45,-5),Vector3(1.2,.9,1.2),Color("486773"));detail(pos+Vector3(-5,.92,-5),Vector3(.9,.035,.8),Color("78b0b2"))
	var supply_positions=[Vector3(-30,.3,0),Vector3(30,.3,0),Vector3(0,.3,-49),Vector3(0,.3,49)] if which<6 else [Vector3(-bounds.x*.55,.3,0),Vector3(bounds.x*.55,.3,0),Vector3(0,.3,-bounds.y*.52),Vector3(0,.3,bounds.y*.52)]
	for supply_pos in supply_positions:
		var pos=supply_pos
		if vertical_map:pos.y=walk_height(pos)+.3
		var n=Node3D.new();add_child(n);n.position=pos
		M.box(n,Vector3.ZERO,Vector3(.9,.5,.65),Color("455f56"));M.box(n,Vector3(0,.265,0),Vector3(.96,.05,.7),Color("798e6c"))
		for x in [-.31,.31]:M.box(n,Vector3(x,0,-.334),Vector3(.07,.3,.03),Color("d2ba76"))
		M.merge_children(n);var label=text3d("AMMO",Vector3(0,.6,0),Color("e1d6a3"),21,n);label.visibility_range_end=20
		supplies.append({"pos":pos,"node":n,"ready":0.})
	if which<6 and not vertical_map:MapLayouts.finish_detail(self,which)
	CombatLayout.build(self)
	MapIdentity.renew(self)
	WorldDressing.build(self)
	building=false;SurfaceCleanup.clean(architecture);batch_architecture();apply_surface_detail()
	ArenaLighting.build(self)
func batch_architecture():
	var meshes=[];gather_meshes(architecture,meshes);var chunks={}
	for mesh in meshes:
		if not mesh.visible or mesh.mesh.get_surface_count()==0 or not mesh.material_override is StandardMaterial3D or mesh.material_override.albedo_color.a<1:continue
		var pos=mesh.global_position;var key=Vector2i(int(floor(pos.x/32)),int(floor(pos.z/32)))
		if not chunks.has(key):var n=Node3D.new();architecture.add_child(n);chunks[key]=n
		var transform=mesh.global_transform;mesh.get_parent().remove_child(mesh);chunks[key].add_child(mesh);mesh.global_transform=transform
	for chunk in chunks.values():M.merge_children(chunk)
	chunk_count=chunks.size()
func gather_meshes(node:Node,out:Array):
	for child in node.get_children():
		if child is MeshInstance3D:out.append(child)
		else:gather_meshes(child,out)
func point_clear(pos:Vector3) -> bool:
	if vertical_map:return navigation_clear(pos) and navigation_heights(pos).any(func(height):return absf(height-pos.y)<.45)
	if not playable_polygon.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z),playable_polygon):return false
	if absf(pos.x)>bounds.x-6 or absf(pos.z)>bounds.y-6:return false
	for rect in obstacles:
		if rect.grow(.2).has_point(Vector2(pos.x,pos.z)):return false
	return true
func spawn_candidates(team:int,roaming:bool) -> Array:
	var out=[]
	for pos in (ffa_spawns if roaming else spawn_points[team]):
		if point_clear(pos):out.append(pos)
	for i in range(48):
		var margin=12. if map_index<6 else 7.
		var z=randf_range(-bounds.y+8,bounds.y-8) if roaming else randf_range(-bounds.y+7,-bounds.y+22) if team==0 else randf_range(bounds.y-22,bounds.y-7)
		if map_index>=6 and not roaming:z=(-1 if team==0 else 1)*randf_range(bounds.y-10,bounds.y-7)
		var pos=Vector3(randf_range(-bounds.x+margin,bounds.x-margin),.12,z)
		if point_clear(pos) and not wading(pos):out.append(pos)
	if out.is_empty():out.append(Vector3(0,.12,(-1 if team==0 else 1)*(bounds.y-10)))
	return out
func make_water():
	var water=box(Vector3(0,.31,0),Vector3(18,.6,66),Color(.18,.52,.59,.50),false)
	var shader=Shader.new();shader.code="shader_type spatial; render_mode blend_mix, cull_disabled; void fragment(){float v=sin(UV.x*85.0+TIME)*sin(UV.y*70.0-TIME*.7); ALBEDO=vec3(.12,.4,.46)+v*.025; ROUGHNESS=.3; ALPHA=.45;}"
	var mat_water=ShaderMaterial.new();mat_water.shader=shader;water.get_child(0).material_override=mat_water
	for x in [-9.3,9.3]:detail(Vector3(x,.2,0),Vector3(.6,.4,66),Color("b4bab0"))
func bridge(z:float):
	var prior=building;building=false
	box(Vector3(0,.3,z),Vector3(19,.6,4.6),Color("a1ada6"))
	for side in [-1,1]:
		var body=StaticBody3D.new();architecture.add_child(body);body.collision_layer=1
		var points=PackedVector3Array()
		for x in [9.5,13.5]:
			for zz in [-2.3,2.3]:
				points.append(Vector3(x*side,0,z+zz));points.append(Vector3(x*side,.6 if x==9.5 else .015,z+zz))
		var shape=ConvexPolygonShape3D.new();shape.points=points;var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
		var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in [1,3,5,3,7,5]:mesh.set_normal(Vector3.UP);mesh.add_vertex(points[index] if side==1 else points[{1:5,3:7,5:1,7:3}[index]])
		var node=MeshInstance3D.new();node.mesh=mesh.commit();node.material_override=mat(Color("a1ada6"));body.add_child(node)
	building=prior
func apply_surface_detail():
	var material=SurfaceFinish.world_material()
	var list=[];gather_meshes(architecture,list)
	for mesh in list:
		if mesh.name=="Geometry":mesh.material_override=material
func wading(pos:Vector3) -> bool:
	if map_index==5:
		for z in [-27,0,27]:
			if absf(pos.z-z)<2.5:return false
	return has_water and water_rect.has_point(Vector2(pos.x,pos.z)) and pos.y<.61
func submerged(pos:Vector3) -> bool:return wading(pos) and pos.y<=.61

func solid_rotated(pos:Vector3,size:Vector3,color:Color,yaw:float) -> Node3D:
	var prior=building;building=false
	var body=box(pos,size,color);body.rotation.y=yaw;building=prior
	if vertical_map:
		var rotated_size=Vector3(absf(cos(yaw))*size.x+absf(sin(yaw))*size.z,size.y,absf(sin(yaw))*size.x+absf(cos(yaw))*size.z)
		navigation_blocks[-1]=AABB(pos-rotated_size*.5,rotated_size)
	if prior and pos.y-size.y*.5<1.9 and pos.y+size.y*.5>.35:
		var extent=Vector2(absf(cos(yaw))*size.x+absf(sin(yaw))*size.z,absf(sin(yaw))*size.x+absf(cos(yaw))*size.z)
		obstacles.append(Rect2(Vector2(pos.x,pos.z)-extent*.5,extent).grow(.6))
	return body
func build_perimeter(which:int):
	var x=bounds.x;var z=bounds.y
	# Chamfered corners and recessed flanks replace the rectangular enclosing wall.
	playable_polygon=MapIdentity.perimeter(which,bounds)
	for i in range(playable_polygon.size()):
		var start=playable_polygon[i];var end=playable_polygon[(i+1)%playable_polygon.size()]
		var center=(start+end)*.5;var delta=end-start;var yaw=-atan2(delta.y,delta.x)
		var height=5.+float((i+which)%3)*1.4
		solid_rotated(Vector3(center.x,height*.5,center.y),Vector3(delta.length()+.7,height,1.2),Color("718b91") if indoors else Color("b6aa91"),yaw)
		detail(Vector3(center.x,height+.1,center.y),Vector3(delta.length()+.9,.25,1.5),Color("4a626a"),Vector3(0,yaw,0))
		# Outside skyline masses break the uniform wall height without blocking lanes.
		if not indoors:
			var outward=center.normalized()*5.
			detail(Vector3(center.x+outward.x,(height+4.5)*.5,center.y+outward.y),Vector3(delta.length()*.55,height+4.5,5.),Color("7b9193"),Vector3(0,yaw,0))
func terrace(center:Vector3,size:Vector2,height:float,color:Color):
	var prior=building;building=false
	box(center+Vector3.UP*(height*.5),Vector3(size.x,height,size.y),color)
	building=prior
	walk_surfaces.append({"rect":Rect2(Vector2(center.x-size.x*.5,center.z-size.y*.5),size),"low":height,"high":height})
	detail(center+Vector3.UP*(height+.02),Vector3(size.x,.04,size.y),Color("c8c2ae"))
func ramp(center:Vector3,size:Vector2,low:float,high:float,color:Color):
	var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;architecture.add_child(body)
	var points=PackedVector3Array()
	for z in [-1,1]:
		for x in [-1,1]:
			points.append(center+Vector3(x*size.x*.5,-.05,z*size.y*.5))
			points.append(center+Vector3(x*size.x*.5,low if z<0 else high,z*size.y*.5))
	var shape=ConvexPolygonShape3D.new();shape.points=points;var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for idx in [1,5,3,3,5,7]:st.add_vertex(points[idx])
	st.generate_normals();var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=mat(color);body.add_child(mesh)
	walk_surfaces.append({"rect":Rect2(Vector2(center.x-size.x*.5,center.z-size.y*.5),size),"low":low,"high":high})
	for x in [-size.x*.43,size.x*.43]:
		var angle=atan2(high-low,size.y)
		detail(center+Vector3(x,(low+high)*.5+.022,0),Vector3(.07,.03,sqrt(size.y*size.y+(high-low)*(high-low))),Color("d7ba71"),Vector3(-angle,0,0))
func walk_height(pos:Vector3) -> float:
	if vertical_map:
		var heights=navigation_heights(pos)
		var best=0.;var distance=INF
		for y in heights:
			if absf(y-pos.y)<distance:distance=absf(y-pos.y);best=y
		return best
	var height=0.
	for surface in walk_surfaces:
		if surface.rect.has_point(Vector2(pos.x,pos.z)):
			height=maxf(height,lerpf(surface.low,surface.high,(pos.z-surface.rect.position.y)/surface.rect.size.y))
	return height

func prop_states() -> Array:
	var result=[]
	for prop in props.values():result.append(prop.state())
	return result
func receive_props(states:Array):
	for state in states:
		if state is Array and state.size()==3 and props.has(int(state[0])):props[int(state[0])].receive(state[1],state[2])
func reset_props():
	for door in doors.values():door.reset()
	for prop in props.values():prop.reset_home()

func navigation_heights(pos:Vector3) -> Array:
	var result=[];var point=Vector2(pos.x,pos.z);var hole=false
	for rect in floor_holes:
		if rect.has_point(point):hole=true;break
	if not hole:result.append(0.)
	for surface in walk_surfaces:
		if surface.rect.has_point(point):
			var height=lerpf(surface.low,surface.high,(pos.z-surface.rect.position.y)/surface.rect.size.y)
			if not height in result:result.append(height)
	return result
func navigation_clear(pos:Vector3) -> bool:
	if has_meta("route_spec") and pos.y<6.8:
		var point=Vector2(pos.x,pos.z);var spec=get_meta("route_spec")
		for offset in [Vector2.ZERO,Vector2(.5,0),Vector2(-.5,0),Vector2(0,.5),Vector2(0,-.5)]:
			if not DefusalLayout.inside(point+offset,spec):return false
	for surface in walk_surfaces:
		if surface.low==surface.high or not surface.rect.has_point(Vector2(pos.x,pos.z)):continue
		var top=lerpf(surface.low,surface.high,(pos.z-surface.rect.position.y)/surface.rect.size.y)
		var bottom=top-.35 if surface.get("slab",false) else minf(surface.low,surface.high)-.4
		if pos.y+.15<top and pos.y+1.85>bottom:return false
	if absf(pos.x)>bounds.x-2 or absf(pos.z)>bounds.y-2:return false
	if not Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z),playable_polygon):return false
	if navigation_block_count!=navigation_blocks.size():
		navigation_block_count=navigation_blocks.size();navigation_block_cells.clear()
		for block in navigation_blocks:
			for x in range(floori((block.position.x-.5)/8.),floori((block.end.x+.5)/8.)+1):
				for z in range(floori((block.position.z-.5)/8.),floori((block.end.z+.5)/8.)+1):
					var key=Vector2i(x,z)
					if not navigation_block_cells.has(key):navigation_block_cells[key]=[]
					navigation_block_cells[key].append(block)
	for block in navigation_block_cells.get(Vector2i(floori(pos.x/8.),floori(pos.z/8.)),[]):
		if pos.x>block.position.x-.5 and pos.x<block.end.x+.5 and pos.z>block.position.z-.5 and pos.z<block.end.z+.5 and pos.y+.15<block.end.y and pos.y+1.85>block.position.y:return false
	return true
