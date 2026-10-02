extends SceneTree
# 1.4.6 (the user): water rules on every map with water -
#  * shallow (safe) and deep (deadly) water never touch: there is dry ground
#    between them, so shallow water never turns deep underfoot;
#  * the depth never changes inside a pool: deep basins are 2 m and more with a
#    flat bed, shallow pools are .5 m at most with a flat floor;
#  * a player walks into shallow water, stays alive and walks out again;
#  * a player who falls into deep water dies at once;
#  * deep water is opaque and dark, shallow water clear and light.
# Args: map indices (default: every map with water).
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func inside_points(poly:PackedVector2Array,step:float,margin:float) -> Array:
	var rect=Rect2(poly[0],Vector2.ZERO)
	for p in poly:rect=rect.expand(p)
	var out=[]
	var x=rect.position.x+step*.5
	while x<rect.end.x:
		var z=rect.position.y+step*.5
		while z<rect.end.y:
			var p=Vector2(x,z)
			if Geometry2D.is_point_in_polygon(p,poly) and edge_distance(p,poly)>=margin:out.append(p)
			z+=step
		x+=step
	return out
func edge_distance(p:Vector2,poly:PackedVector2Array) -> float:
	var best=INF
	for i in range(poly.size()):best=minf(best,p.distance_to(Geometry2D.get_closest_point_to_segment(p,poly[i],poly[(i+1)%poly.size()])))
	return best
func run():
	var maps=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).is_valid_int()).map(func(x):return int(x))
	if maps.is_empty():
		for index in range(Rules.MAPS.size()):
			var plan=DistrictLayout.read_plan(index)
			if not plan.is_empty() and (not plan.get("water",[]).is_empty() or not plan.get("shallow",[]).is_empty()):maps.append(index)
	expect(maps.size()>=6,"several maps have water: "+str(maps))
	# materials: deep water opaque and dark, shallow clear and light
	for kind in ["sea","river"]:
		var m:ShaderMaterial=WaterSurface.material_kind(kind)
		expect(not m.shader.code.contains("ALPHA") and not m.shader.code.contains("blend_mix"),kind+" water is opaque")
		expect(Color(m.get_shader_parameter("water_colour")).b>Color(m.get_shader_parameter("water_colour")).r*2. and Color(m.get_shader_parameter("water_colour")).get_luminance()<.25,kind+" water is dark blue")
	var clear:ShaderMaterial=WaterSurface.material_kind("shallow")
	expect(clear.shader.code.contains("ALPHA") and float(clear.get_shader_parameter("alpha"))<.5 and Color(clear.get_shader_parameter("water_colour")).get_luminance()>.75,"shallow water is clear and very light")
	for index in maps:
		var g=load("res://scripts/game.gd").new();root.add_child(g)
		for i in range(4):await process_frame
		g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
		g.build_world()
		for i in range(3):await physics_frame
		var arena=g.arena;var plan=DistrictLayout.read_plan(index)
		var space=arena.get_world_3d().direct_space_state
		var boats=[]
		for node in arena.architecture.get_children():
			if node.has_meta("boat"):
				for b in node.get_children():
					if b is StaticBody3D:boats.append(b.get_rid())
		var deep:Array=arena.get_meta("district_waters",[arena.get_meta("district_water")] if arena.has_meta("district_water") else [])
		var shallow:Array=arena.get_meta("shallow_waters",[])
		var level=float(arena.get_meta("water_height",-.35));var shallow_level=float(arena.get_meta("shallow_height",-.02))
		# 1. dry ground between shallow and deep water
		var gap=INF
		for s in shallow:
			for d in deep:
				for i in range(s.size()):
					var a2:Vector2=s[i];var b2:Vector2=s[(i+1)%s.size()]
					for k in range(9):gap=minf(gap,edge_distance(a2.lerp(b2,k/8.),d))
				for p in d:expect(not Geometry2D.is_point_in_polygon(p,s),"map %d deep basin inside a shallow pool"%index)
		if not shallow.is_empty() and not deep.is_empty():expect(gap>=3.,"map %d shallow and deep water %.2f m apart (no direct step from one into the other)"%[index,gap])
		# 2. the bed of each deep basin: flat, 2 m and more below the surface
		var beds=[]
		for d in deep:
			for p in inside_points(d,1.5,.7):
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,level-.05,p.y),Vector3(p.x,level-8.,p.y),1,boats))
				if not hit.is_empty():beds.append(hit.position.y)
		if not deep.is_empty():
			expect(beds.size()>10,"map %d deep basins have a bed (%d samples)"%[index,beds.size()])
			if not beds.is_empty():
				expect(level-beds.max()>=2.,"map %d deep water is 2 m and more everywhere (shallowest %.2f m)"%[index,level-beds.max()])
				expect(beds.max()-beds.min()<.1,"map %d deep bed is flat (%.2f..%.2f)"%[index,beds.min(),beds.max()])
		# 3. the floor of each shallow pool: flat, .5 m at most below the surface
		var floors=[]
		for s in shallow:
			for p in inside_points(s,1.,.3):
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,shallow_level+1.5,p.y),Vector3(p.x,shallow_level-3.,p.y),1,boats))
				if not hit.is_empty():floors.append(hit.position.y)
				expect(arena.shallow(Vector3(p.x,shallow_level-.2,p.y)) and not arena.fatal_water(Vector3(p.x,shallow_level-.45,p.y)) and not arena.deep_water(Vector3(p.x,0,p.y)),"map %d shallow water at %s is safe"%[index,str(p)])
		if not shallow.is_empty():
			expect(floors.size()>4,"map %d shallow pools have a floor"%index)
			if not floors.is_empty():
				expect(shallow_level-floors.min()<=.5,"map %d shallow water is .5 m at most (deepest %.2f m)"%[index,shallow_level-floors.min()])
				expect(floors.max()-floors.min()<.06,"map %d shallow floor is flat (%.2f..%.2f)"%[index,floors.min(),floors.max()])
		# 4. a player in the water (real movement, server rules)
		g.add_player(-1,"Swimmer","water_probe");g.phase="combat";g.clock=100.
		var a=g.actors[-1]
		for s in shallow:
			var pts=inside_points(s,1.,.9)
			if pts.is_empty():continue
			var c:Vector2=pts[pts.size()/2]
			var left=false
			for dir in [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT]:
				g.players[-1].alive=true;g.players[-1].hp=100.;a.visible=true
				a.position=Vector3(c.x,floors.max()+.05 if not floors.is_empty() else -.2,c.y);a.velocity=Vector3.ZERO;a.reset_view(atan2(-dir.x,-dir.z));a.input_state.z=-1.;a.input_state.x=0.;a.input_state.jump=false
				await physics_frame
				var was_in=false
				for i in range(180):
					g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
					was_in=was_in or arena.shallow(a.global_position)
					if not g.players[-1].alive:break
				expect(g.players[-1].alive,"map %d walking through shallow water keeps the player alive (%s)"%[index,str(a.global_position)])
				expect(was_in,"map %d the player was in the shallow pool"%index)
				if not arena.shallow(a.global_position) and a.global_position.y>shallow_level:left=true
			a.input_state.z=0.
			expect(left,"map %d the player walks out of the shallow pool"%index)
		for d in deep:
			var pts=inside_points(d,1.5,1.)
			if pts.is_empty():continue
			var c:Vector2=pts[pts.size()/2]
			g.players[-1].alive=true;g.players[-1].hp=100.;g.players[-1].lives=99;a.visible=true
			a.position=Vector3(c.x,level+.6,c.y);a.velocity=Vector3.ZERO;a.input_state.z=0.
			# (nothing may stand there - a boat deck is fine too)
			var on_boat=not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x,level+.6,c.y),Vector3(c.x,level-1.,c.y),1,[])).is_empty()
			if on_boat:continue
			var died=false
			for i in range(120):
				g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
				if not g.players[-1].alive:died=true;break
			expect(died,"map %d a player in deep water drowns (%s)"%[index,str(a.global_position)])
		print("WATER146 map %d deep=%d shallow=%d gap=%.1f bed=%s floor=%s"%[index,deep.size(),shallow.size(),gap,str([beds.min(),beds.max()]) if not beds.is_empty() else "-",str([floors.min(),floors.max()]) if not floors.is_empty() else "-"])
		g.queue_free()
		for i in range(4):await process_frame
	print("V146_WATER checks=%d failures=%d"%[checks,failures])
	if failures==0:print("V146_WATER_PASS")
	quit(1 if failures>0 else 0)
