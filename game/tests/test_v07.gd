extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if ok:print("PASS ",message)
	else:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=7;g.build_world();g.add_player(1,"V07","v07_test_identity")
	var a=g.actors[1];a.position=Vector3(0,.1,18);a.reset_view(0);a.velocity=Vector3.ZERO
	await physics_frame;await physics_frame
	a.input_state.z=-1;a.simulate(.016,0.,true)
	expect(absf(a.velocity.z)>0 and absf(a.velocity.z)<7.4,"movement accelerates instead of snapping to maximum speed")
	for i in range(45):a.simulate(.016,0.,true)
	var expected_speed=Rules.WALK_SPEED*float(Catalog.get_weapon(g.players[1].primary).move_speed_scale)
	expect(absf(absf(a.velocity.z)-expected_speed)<.1,"acceleration reaches the weapon-specific walking speed")
	a.input_state.z=0;a.simulate(.016,0.,true)
	expect(absf(a.velocity.z)>0 and absf(a.velocity.z)<7.4,"releasing input brakes over time")
	for i in range(60):a.simulate(.016,0.,true)
	expect(Vector2(a.velocity.x,a.velocity.z).length()<.01,"braking settles fully without perpetual sliding")
	a.visual(.016,g.players[1],0.)
	var c:HeroCharacter=a.character
	# 1.4 hero: AnimationTree layers blend instead of snapping.
	var hips=func():return c.bone_world(c.bone.Hips).origin.y-c.global_position.y
	for i in range(30):c.drive(.016,{"velocity":Vector3.ZERO,"grounded":true})
	var standing=hips.call()
	for i in range(12):c.drive(.016,{"velocity":Vector3(0,0,-6.5),"grounded":true,"sprint":true})
	var memory=c.get_meta("anim_memory")
	expect(float(memory.sprint)>.7 and float(c.tree.get("parameters/hold/blend_amount"))<.35,"sprinting lowers the weapon and blends the sprint cycle")
	c.drive(.016,{"velocity":Vector3.ZERO,"grounded":true,"crouch":true})
	memory=c.get_meta("anim_memory")
	expect(float(memory.crouch)>0 and float(memory.crouch)<1,"crouching blends rather than snapping")
	for i in range(40):c.drive(.016,{"velocity":Vector3.ZERO,"grounded":true,"crouch":true})
	expect(hips.call()<standing-.12,"crouch lowers hips with bent knees")
	for i in range(10):c.drive(.016,{"velocity":Vector3(0,5,0),"grounded":false})
	expect(float(c.get_meta("anim_memory").air)>.5,"airborne pose blends in during a jump")
	for i in range(30):c.drive(.016,{"velocity":Vector3.ZERO,"grounded":true})
	expect(float(c.get_meta("anim_memory").air)<.1 and absf(hips.call()-standing)<.08,"landing returns to the standing pose")
	# Aim pitch drives the upper-body aim blend.
	c.drive(.016,{"velocity":Vector3.ZERO,"grounded":true,"pitch":.8})
	expect(float(c.tree.get("parameters/aim/blend_position"))>.5,"looking up raises the aim layer")
	for index in [7,10,12,16]:
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena)
		expect(arena.playable_polygon.size()>4,"map %d has a nonrectangular perimeter"%index)
		expect(arena.district_surfaces.any(func(s):return absf(s.plane.x)+absf(s.plane.y)>.01),"map %d has traversable terraces and ramps"%index)
		var terraces=arena.navigation_goals.filter(func(p):return p.y>1.5)
		expect(not terraces.is_empty(),"map %d exposes a high landing to navigation"%index)
		if terraces.is_empty():arena.free();continue
		var terrace=terraces[0]
		expect(arena.walk_height(terrace)>1.5,"map %d navigation recognizes terrace elevation"%index)
		await physics_frame;await physics_frame
		var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(terrace+Vector3.UP*.5,terrace-Vector3.UP*.5,1))
		expect(not hit.is_empty() and hit.position.y>1.5,"map %d terrace has actual collision"%index)
		arena.free()
	var replay=KillReplay.new();replay.game=g;root.add_child(replay);g.phase="combat"
	for i in range(200):replay.capture(.05)
	expect(replay.history.size()==KillReplay.MAX_FRAMES,"replay history has a fixed memory bound")
	replay.request({"attacker":0,"victim":1});expect(replay.pending.is_empty(),"environmental deaths cannot invent an attacker replay")
	replay.request({"attacker":1,"victim":1});expect(replay.pending.is_empty(),"self-eliminations do not fabricate killer footage")
	replay.reset();expect(replay.history.is_empty() and not replay.active,"leaving the room clears replay state")
	expect(is_equal_approx(KillReplay.TOTAL_SECONDS,4.8),"2.3 second replay, .5 second death and 2 second portrait fit the 5.2 second respawn")
	g.profile.width=5120;g.profile.height=1440;expect(g.display_window_size()==Vector2i(5120,1440),"ultrawide custom dimensions are preserved")
	g.profile.width=7680;g.profile.height=4320;expect(g.display_window_size()==Vector2i(7680,4320),"8K dimensions are accepted")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	expect(manifest.has("kill_sting") and manifest.hurt.duration>=.3,"heavy impact and portrait sting assets are available")
	replay.free();g.leave_game();g.free();await process_frame;await process_frame
	print("V07_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
