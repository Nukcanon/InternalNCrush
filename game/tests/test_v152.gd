extends SceneTree
# 1.5.2 (the user's list): fire rates, TIDAL reload, FEATHER heals allies 5 per hit, RIVET
# repairs friendly structures 8 per hit (enemy ones still take damage), and the ARC beam
# lands where the crosshair points even with something beside the muzzle's line.
var checks=0
var failures=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	for pair in [["r2",30.],["r1",40.],["m2",270.],["a2",670.]]:
		var w=Catalog.get_weapon(pair[0]);expect(absf(60./float(w.interval)-float(pair[1]))<1.,"%s fires %d rounds a minute"%[w.name,int(pair[1])])
	expect(is_equal_approx(float(Catalog.get_weapon("e2").reload),2.9),"TIDAL reloads in 2.9 s")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Shooter","s");g.add_player(2,"Ally","a");g.add_player(3,"Enemy","e")
	g.phase="combat";g.clock=100.;g.options.mode=0;g.options.friendly=false
	var p=g.players[1];var q=g.players[2];var e=g.players[3];var a=g.actors[1];var b=g.actors[2];var c=g.actors[3]
	p.team=0;q.team=0;e.team=1;p.protect=0.;q.protect=0.;e.protect=0.;p.placing="";p.reload=0.;q.armor=0.;e.armor=0.
	a.position=Vector3.ZERO;b.position=Vector3(0,0,-3);c.position=Vector3(20,0,0)
	a.aim_yaw=0.;a.input_state.yaw=0.;a.last_sprint=false;a.sprint_release=0.
	await physics_frame;await physics_frame
	a.aim_pitch=atan2(1.15-a.eye().y,3.);a.input_state.pitch=a.aim_pitch
	# FEATHER: an ally hit heals 5
	p.secondary="med_pistol";p.slot=1;p.fire_ready=0.;p.mag.med_pistol=10;p.bloom=0.;p.spray_phase=0.;a.spread_angle=0.;q.hp=10.;q.last_hit=g.clock
	await physics_frame;g.fire(1)
	expect(is_equal_approx(q.hp,15.),"FEATHER heals an ally 5 per hit (hp %s)"%q.hp)
	# RIVET: a friendly turret gains 8, an enemy one loses health
	b.position=Vector3(30,0,0);await physics_frame
	var own=g.add_device("turret",Vector3(0,0,-3),2,100.);g.devices[own].hp=50.
	g.update_world_visuals(.016);await physics_frame;await physics_frame
	a.aim_pitch=atan2(.6-a.eye().y,3.);a.input_state.pitch=a.aim_pitch
	p.secondary="eng_pistol";p.fire_ready=0.;p.mag.eng_pistol=10;p.bloom=0.;p.spray_phase=0.
	await physics_frame;g.fire(1)
	expect(is_equal_approx(float(g.devices[own].hp),58.),"RIVET repairs a friendly turret 8 per hit (hp %s)"%g.devices[own].hp)
	g.devices[own].team=1;var before=float(g.devices[own].hp);p.fire_ready=0.
	await physics_frame;g.fire(1)
	expect(float(g.devices[own].hp)<before,"RIVET still damages an enemy turret")
	g.devices.erase(own);if g.device_nodes.has(own):g.device_nodes[own].free();g.device_nodes.erase(own)
	# ARC: a post beside the muzzle's line to the target, clear of the eye's line - the beam
	# still hits the enemy at the crosshair
	p.role=2;p.primary="h6";p.slot=0;p.mag.h6=600.;p.laser_heat=0.;p.laser_lock=0.;p.switch_until=0.;a.input_state.fire=true
	c.position=Vector3(0,0,-10);e.hp=100.;e.alive=true;await physics_frame;await physics_frame
	var eye=a.eye();var target=c.position+Vector3.UP*1.15;a.aim_pitch=atan2(target.y-eye.y,10.);a.input_state.pitch=a.aim_pitch
	await physics_frame
	var muzzle=a.muzzle_world();var at=muzzle.lerp(target,.25)
	var post=StaticBody3D.new();var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(.06,.06,.06);shape.shape=box;post.add_child(shape);g.add_child(post);post.global_position=at
	await physics_frame;await physics_frame
	var clear=g.ray(eye,target,[a.get_rid()]).get("collider")==c
	for i in range(6):g.clock+=.1;LaserCombat.tick(g,1,.1)
	expect(clear and e.hp<100.,"ARC beam hits the target at the crosshair past a post beside the muzzle (eye line clear %s, hp %s)"%[clear,e.hp])
	post.free()
	print("V152_RESULT %d/%d"%[checks-failures,checks])
	g.free()
	quit(1 if failures>0 else 0)
