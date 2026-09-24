extends SceneTree
var failures=0
var checks=0
var g:Node
func expect(ok:bool,description:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",description)
	else:print("PASS ",description)
func _initialize():call_deferred("run")
func arm(wid:String):
	var p=g.players[1];p.primary=wid;p.protect=0.;p.slot=0;p.reload=0.;p.fire_ready=0.;p.burst_left=0;p.trigger_until=0.;p.fire_prev=false;p.trigger_seen=0;p.shield=0.;g.equip_ammo(p)
	var a=g.actors[1];a.sprint_release=0.;a.last_sprint=false;a.input_state.fire=false;a.input_state.trigger_seq=0
func click(seq:int):
	g.actors[1].input_state.fire=true;g.actors[1].input_state.trigger_seq=seq;g.process_trigger(1)
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.options.map_random=false;g.options.map=0;g.options.max_players=32;g.host_game();g.set_physics_process(false);g.add_player(2,"Observer","test_observer_12345")
	g.players[2].team=g.players[1].team;g.phase="combat";g.remaining=500;g.clock=100
	var a=g.actors[1];var p=g.players[1];g.actors[2].position=Vector3(45,0,50)
	for cycle in range(3):
		p.alive=false;g.spectator_target=2;var before=g.actors[2].position;g.update_spectator()
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;var motion=InputEventMouseMotion.new();motion.relative=Vector2(130,-50);g._unhandled_input(motion);g.update_spectator()
		expect(g.actors[2].position.is_equal_approx(before),"spectator mouse never moves observed actor "+str(cycle))
		g.spawn(1);g.update_spectator();a.visual(.016,p,g.clock)
		expect(not a.camera.top_level and a.camera.global_position.distance_to(a.eye())<.001 and a.camera.current,"respawn restores camera origin "+str(cycle))
	a.position=Vector3(25,0,60);a.reset_view(0);g.actors[2].position=Vector3(-50,0,60)
	await physics_frame;await physics_frame
	arm("pistol");click(1)
	for i in range(20):g.clock+=.1;g.process_trigger(1)
	expect(p.mag.pistol==11,"holding semiautomatic fires exactly once")
	g.actors[1].input_state.fire=false;g.process_trigger(1);g.clock+=.5;click(2)
	expect(p.mag.pistol==10,"second click fires next semiautomatic shot")
	arm("a1");click(1)
	for i in range(12):g.clock+=.12;g.process_trigger(1)
	expect(p.mag.a1==17,"automatic continues while held")
	arm("a4");click(1)
	for i in range(20):g.clock+=.12;g.process_trigger(1)
	expect(p.mag.a4==24,"burst fires exactly three while held")
	arm("a1");p.mag.a1=1;p.reserve.a1=7;click(1)
	expect(p.mag.a1==0 and p.reload>g.clock,"last round starts automatic reload")
	g.clock=p.reload+.01;a.input_state.fire=false;p.input_time=g.clock;g.server_tick(.016)
	expect(p.mag.a1==7 and p.reserve.a1==0,"automatic reload transfers only available reserve")
	arm("a1");g.clock+=1;g.apply_loadout(1,{"role":3,"primary":"e1","armor":2,"gadget":1,"repair":true})
	expect(p.primary=="a1" and not p.pending_loadout.is_empty(),"living loadout change queues without respawning")
	g.spawn(1)
	expect(p.primary=="e1" and p.secondary=="repair" and p.role==3 and p.pending_loadout.is_empty(),"queued class and both weapons apply on respawn")
	g.apply_loadout(1,{"role":0,"primary":"r2"})
	expect(p.pending_loadout.is_empty(),"invalid class weapon cannot be queued")
	p.alive=false;g.apply_loadout(1,{"role":4,"primary":"c1","armor":2,"gadget":1});g.spawn(1)
	expect(p.primary=="c1" and p.smoke==1 and p.flash_count==2,"dead player selection and gadget composition survive respawn")
	g.clock+=1;g.handle_command(1,"slot",{"slot":2});expect(p.slot==2,"numeric gadget slot selectable")
	g.clock+=1;g.handle_command(1,"slot",{"slot":3});expect(p.slot==3 and p.gadget==1,"fourth slot selects flash")
	var key=InputEventKey.new();key.physical_keycode=KEY_F;expect(InputMap.event_is_action(key,"skill"),"F activates skill")
	key.physical_keycode=KEY_Q;expect(InputMap.event_is_action(key,"medical"),"Q activates medical shot")
	key.physical_keycode=KEY_E;expect(InputMap.event_is_action(key,"use"),"E keeps interaction")
	arm("a1");a.position=Vector3(25,0,60);a.reset_view(0);a.input_state.z=-1;g.options.mode=0
	for step in range(40):a.simulate(.016,g.clock,true)
	expect(is_equal_approx(absf(a.velocity.z),Rules.WALK_SPEED*Catalog.get_weapon("a1").move_speed_scale),"movement includes weapon mobility")
	a.input_state.sprint=true
	for step in range(40):a.simulate(.016,g.clock,true)
	expect(is_equal_approx(absf(a.velocity.z),Rules.RUN_SPEED*Catalog.get_weapon("a1").move_speed_scale),"sprint includes weapon mobility")
	a.position=Vector3(120,-6,110);a.input_state.z=0;a.simulate(.016,g.clock,true)
	expect(absf(a.position.x)<=98 and absf(a.position.z)<=88 and a.position.y>=0,"out of map fallback restores playable bounds")
	a.position=Vector3(25,0,60);a.reset_view(0);await physics_frame;await physics_frame
	var muzzle=a.muzzle_world();expect(muzzle.distance_to(a.eye())>.4 and muzzle.y<a.eye().y,"shot origin is below and forward of eye")
	var wall=g.arena.box(a.eye()+Vector3(0,0,-.25),Vector3(2,3,.15),Color.GRAY)
	await physics_frame;await physics_frame
	expect(a.muzzle_world().z>a.position.z-.3,"muzzle is constrained before nearby wall")
	wall.queue_free();await physics_frame;await physics_frame
	for wid in Catalog.weapons:
		p.primary=wid;p.protect=0.;p.slot=0;a.visual(.016,p,g.clock)
		expect(is_instance_valid(a.view_weapon.muzzle) and a.view_weapon.find_children("*","MeshInstance3D",true,false).size()>4,"complete procedural model "+wid)
		for fraction in [.1,.5,.9]:a.view_weapon.animate_reload(fraction,0)
	arm("r2");a.input_state.ads=true;a.visual(.8,p,g.clock)
	expect(not a.view_weapon.visible,"scoped ADS removes opaque weapon from center")
	arm("a1");a.input_state.ads=true;a.visual(.5,p,g.clock)
	expect(a.view_weapon.visible and a.gun.position.y<-.1,"rifle ADS keeps model below aiming center")
	var pos=a.position;a.react_hit(Vector3.RIGHT);a.visual(.016,p,g.clock)
	expect(a.position.is_equal_approx(pos) and a.hit_recoil>0,"hit reaction changes visuals without moving collider")
	g.options.mode=4;g.phase="combat";p.cash=4000;p.armor=0;g.apply_loadout(1,{"role":0,"primary":"a1","armor":2})
	expect(p.cash==4000,"bomb queued purchase does not spend in combat")
	p.owned_primary=false;g.phase="buy";g.spawn(1)
	expect(p.cash==1000 and p.primary=="a1" and p.armor==50,"next-round queued purchase charges exactly once")
	print("REGRESSION_RESULT ",checks-failures,"/",checks," passed")
	await create_timer(.8).timeout
	g.leave_game();g.queue_free();await process_frame;quit(1 if failures else 0)
