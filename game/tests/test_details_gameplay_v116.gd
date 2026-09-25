extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Builder","detail_builder");g.add_player(2,"Target","detail_target");g.phase="combat";g.clock=100.
	var p=g.players[1];var q=g.players[2];var a=g.actors[1];var b=g.actors[2]
	p.team=0;q.team=1;p.protect=0.;q.protect=0.;p.primary="a1";p.slot=0;p.reload=0.;p.placing="";q.hp=100.;q.armor=0.
	a.position=Vector3.ZERO;b.position=Vector3(.5,0,-12);a.input_state.yaw=0.;a.input_state.pitch=0.
	await physics_frame;await physics_frame
	g.profile.touch_auto_fire=false;g.profile.touch_aim_assist=true
	TouchAim.assist(g,a,1./30.)
	expect(a.input_state.yaw<0. and a.input_state.pitch<0.,"magnet assistance approaches a nearby visible enemy without auto fire")
	g.profile.touch_aim_assist=false;var before=Vector2(a.input_state.yaw,a.input_state.pitch);TouchAim.assist(g,a,1./30.)
	expect(before==Vector2(a.input_state.yaw,a.input_state.pitch),"assist setting completely disables camera correction")
	g.profile.touch_aim_assist=true;q.team=0;TouchAim.assist(g,a,1./30.)
	expect(before==Vector2(a.input_state.yaw,a.input_state.pitch),"assist never pulls toward teammates")
	q.team=1
	var wall=StaticBody3D.new();g.add_child(wall);wall.position=Vector3(.25,1.,-6.)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(2,3,.3);shape.shape=box;wall.add_child(shape)
	await physics_frame;TouchAim.assist(g,a,1./30.)
	expect(before==Vector2(a.input_state.yaw,a.input_state.pitch),"assist never pulls through a wall")
	wall.free();a.position=Vector3(-8,0,2);b.position=Basis(Vector3.UP,deg_to_rad(40.))*Vector3(0,0,-15)
	await physics_frame
	var turret={"id":901,"kind":"turret","pos":Vector3.ZERO,"yaw":0.,"head_yaw":-TurretLogic.HALF_ARC,"owner":1,"team":0,"hp":100.,"max_hp":100.,"level":1,"next_fire":0.,"target":0,"lock":0.,"disabled":0.,"expires":1000.}
	g.devices[901]=turret
	TurretLogic.tick(g,1./60.)
	expect(turret.target==2 and is_equal_approx(turret.lock,100.1) and q.hp==100.,"acquisition chirp delays fire")
	g.clock=100.09;TurretLogic.tick(g,1./60.)
	expect(is_equal_approx(turret.head_yaw,-TurretLogic.HALF_ARC) and q.hp==100.,"head waits during recognition beep")
	g.clock=100.11;TurretLogic.tick(g,1./60.)
	expect(turret.head_yaw>-TurretLogic.HALF_ARC and q.hp==100.,"tracking begins without an instantaneous shot")
	for frame in range(32):g.clock+=1./60.;TurretLogic.tick(g,1./60.)
	expect(q.hp<100.,"turret fires after barrel reaches the target")
	g.devices.clear();g.free();await process_frame
	print("DETAILS_GAMEPLAY_V116_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
