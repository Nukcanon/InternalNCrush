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
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map=7;g.build_world();g.add_player(1,"V07","v07_test_identity")
	var a=g.actors[1];a.position=Vector3(0,.1,18);a.reset_view(0);a.velocity=Vector3.ZERO
	await physics_frame;await physics_frame
	a.input_state.z=-1;a.simulate(.016,0.,true)
	expect(absf(a.velocity.z)>0 and absf(a.velocity.z)<7.4,"movement accelerates instead of snapping to maximum speed")
	for i in range(45):a.simulate(.016,0.,true)
	var expected_speed=7.4*float(Catalog.get_weapon(g.players[1].primary).move_speed_scale)
	expect(absf(absf(a.velocity.z)-expected_speed)<.1,"acceleration reaches the weapon-specific walking speed")
	a.input_state.z=0;a.simulate(.016,0.,true)
	expect(absf(a.velocity.z)>0 and absf(a.velocity.z)<7.4,"releasing input brakes over time")
	for i in range(60):a.simulate(.016,0.,true)
	expect(Vector2(a.velocity.x,a.velocity.z).length()<.01,"braking settles fully without perpetual sliding")
	a.visual(.016,g.players[1],0.)
	var c=a.character
	for i in range(12):c.update_pose(.016,Vector3(0,0,-8),true,false,true,0,-1,0,.25,0)
	var swing=c.left_arm.rotation.x
	for i in range(12):c.update_pose(.016,Vector3(0,0,-8),true,false,true,0,-1,0,.75,0)
	expect(absf(swing-c.left_arm.rotation.x)>.25,"sprinting visibly counter-swings the support arm")
	c.update_pose(.016,Vector3.ZERO,false,true,true,0,-1,0,0,0)
	expect(c.visual_crouch>0 and c.visual_crouch<1,"crouching blends rather than snapping")
	for i in range(40):c.update_pose(.016,Vector3.ZERO,false,true,true,0,-1,0,0,0)
	expect(c.hips.position.y<.66,"crouch lowers hips with bent knees")
	c.update_pose(.016,Vector3(0,5,0),false,false,false,0,-1,0,0,0)
	expect(c.hips.get_node("LeftLeg/Knee").rotation.x<-.6,"stationary jump tucks the knees")
	c.update_pose(.016,Vector3.ZERO,false,false,true,0,-1,0,0,0)
	expect(c.landing_compression>.1,"landing absorbs impact through the pelvis")
	for i in range(12):c.update_pose(.016,Vector3.ZERO,false,false,true,0,-1,0,0,2.)
	expect(absf(c.pelvis_yaw)>.05,"turning in place separates lower body and aim rotation")
	c.update_pose(.016,Vector3(6,0,-2),false,false,true,0,-1,0,.2,0)
	expect(c.lower_lag.x<0 and c.lower_lag.length()<.13,"direction changes produce bounded opposing lower-body inertia")
	for index in [7,9,16,17]:
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena)
		expect(arena.playable_polygon.size()==8,"map %d has a nonrectangular perimeter"%index)
		expect(arena.walk_surfaces.size()>=6,"map %d has traversable terraces and ramps"%index)
		var terrace=arena.sites[1]
		expect(arena.walk_height(terrace)>1.5,"map %d navigation recognizes terrace elevation"%index)
		await physics_frame;await physics_frame
		var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(terrace+Vector3.UP*5,terrace-Vector3.UP,1))
		expect(not hit.is_empty() and hit.position.y>1.5,"map %d terrace has actual collision"%index)
		arena.free()
	var replay=KillReplay.new();replay.game=g;root.add_child(replay);g.phase="combat"
	for i in range(200):replay.capture(.05)
	expect(replay.history.size()==KillReplay.MAX_FRAMES,"replay history has a fixed memory bound")
	replay.request({"attacker":0,"victim":1});expect(replay.pending.is_empty(),"environmental deaths cannot invent an attacker replay")
	replay.request({"attacker":1,"victim":1});expect(replay.pending.is_empty(),"self-eliminations do not fabricate killer footage")
	replay.reset();expect(replay.history.is_empty() and not replay.active,"leaving the room clears replay state")
	expect(is_equal_approx(KillReplay.TOTAL_SECONDS,3.8),"2.3 second replay, .5 second death and 1 second portrait fit the 4 second respawn")
	g.profile.width=5120;g.profile.height=1440;expect(g.display_window_size()==Vector2i(5120,1440),"ultrawide custom dimensions are preserved")
	g.profile.width=7680;g.profile.height=4320;expect(g.display_window_size()==Vector2i(7680,4320),"8K dimensions are accepted")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	expect(manifest.has("kill_sting") and manifest.hurt.duration>=.3,"heavy impact and portrait sting assets are available")
	replay.free();g.leave_game();g.free();await process_frame;await process_frame
	print("V07_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
