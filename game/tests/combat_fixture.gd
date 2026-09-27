extends Arena
class_name CombatFixture
# Stable 1.2.5 warehouse fixture for coordinate-based combat unit tests only.
# Production Arena never calls this. New district traversal/physics tests exercise
# all release maps separately; this fixture isolates aiming, abilities and input.
static func install(game:Node):
	var previous=game.arena
	game.remove_child(previous);previous.free()
	var arena=CombatFixture.new();arena.props_authoritative=true;game.add_child(arena);arena.build(0);game.arena=arena
	game.bot_navigation=BotNavigation.new();game.bot_navigation.build(arena)
func build(which:int):
	bake_geometry=true
	if not bake_geometry and ArenaCache.restore(self,which):return
	if DefusalLayout.enabled(which) or which==PracticeLayout.INDEX:
		map_index=which;building=true;architecture=Node3D.new();architecture.name="Architecture";add_child(architecture)
		if which==PracticeLayout.INDEX:PracticeLayout.build(self)
		else:DefusalLayout.build(self,which)
		WorldDressing.build(self);finish_architecture();apply_surface_detail();ArenaLighting.build(self);return
	map_index=which;vertical_map=VerticalLayout.enabled(which);indoors=which in [2,3,6,8,11,14,15];has_water=which in [0,5];bounds=Vector2(100,90);building=true;architecture=Node3D.new();architecture.name="Architecture";add_child(architecture)
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
	finish_architecture();apply_surface_detail()
	ArenaLighting.build(self)
