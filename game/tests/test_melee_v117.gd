extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	TouchControls.supported_cache=0
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Attacker","melee_a");g.add_player(2,"Victim","melee_b");g.add_player(3,"Ally","melee_c")
	g.phase="combat";g.clock=100.
	var p=g.players[1];var q=g.players[2];var a=g.actors[1];var b=g.actors[2]
	p.team=0;q.team=1;g.players[3].team=0;p.protect=0.;q.protect=0.;p.primary="a1";p.slot=0;p.reload=0.;p.placing="";q.hp=100.;q.armor=0.;p.role=0
	a.position=Vector3.ZERO;b.position=Vector3(0,0,-1.1);g.actors[3].position=Vector3(20,0,20)
	a.aim_yaw=0.;a.aim_pitch=-.3;a.input_state.yaw=0.;a.input_state.pitch=-.3
	await physics_frame;await physics_frame
	expect(InputMap.action_get_events("melee")[0].physical_keycode==KEY_Q,"Q is quick melee")
	expect(InputMap.action_get_events("medical")[0].physical_keycode==KEY_C,"medical alternate fire remains accessible on C")
	g.options.classes=false;g.handle_command(1,"slot",{"slot":4});expect(p.slot==4,"slot 5 works without classes")
	g.clock+=2.;p.fire_ready=g.clock+.8;expect(MeleeCombat.ready(g,p),"quick melee remains available while a gun is cooling down");a.input_state.fire=true;g.process_trigger(1);a.input_state.fire=false;expect(p.melee_started==g.clock,"click swings the persistently equipped knife")
	g.handle_command(1,"slot",{"slot":0});expect(p.slot==4,"switching cannot cancel active melee to bypass its cooldown")
	expect(not MeleeCombat.begin(g,1),"duplicate command cannot bypass cooldown")
	var start=g.clock
	g.clock=start+.17;MeleeCombat.tick(g,1);expect(q.hp==100.,"windup has no early damage")
	g.clock=start+.43;MeleeCombat.tick(g,1);expect(q.hp<100.,"swept arc hits nearby actor")
	var once=q.hp;MeleeCombat.tick(g,1);expect(q.hp==once,"one damage per victim per swing")
	g.clock=start+1.39;expect(not MeleeCombat.begin(g,1),"cooldown remains until 1.4s")
	g.clock=start+1.41;expect(MeleeCombat.begin(g,1),"attack available after 1.4s")
	# Explicit anatomy damage preserves individual head/torso/limb results.
	for role in [0,3]:
		p.role=role
		for zone in MeleeCombat.ZONES:
			q.alive=true;q.hp=500.;q.armor=0.;p.melee_hits={}
			MeleeCombat.contact(g,1,{"collider":b,"zone":zone,"position":b.eye(),"normal":Vector3.BACK},a.eye(),Vector3.FORWARD)
			expect(is_equal_approx(500.-q.hp,(30. if role==3 else 40.)*MeleeCombat.ZONES[zone]),"melee body-zone "+str(role)+" "+zone)
	q.hp=100.;p.role=0;b.position=Vector3(0,0,-2.0)
	g.clock+=2.;p.fire_ready=0.;MeleeCombat.begin(g,1);g.clock+=.5;MeleeCombat.tick(g,1);expect(q.hp==100.,"very short range cannot reach 2 metres")
	b.position=Vector3(0,0,-1.1)
	var wall=StaticBody3D.new();g.add_child(wall);wall.position=Vector3(0,1.,-.55)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(4,3,.15);shape.shape=box;wall.add_child(shape)
	await physics_frame;g.clock+=2.;MeleeCombat.begin(g,1);g.clock+=.5;MeleeCombat.tick(g,1)
	expect(q.hp==100.,"wall blocks a melee arc");wall.free()
	var device=StaticBody3D.new();g.add_child(device);device.set_meta("device",901)
	g.devices[901]={"kind":"turret","team":0,"owner":3,"hp":51.,"max_hp":100.,"pos":Vector3.ZERO,"last_hit":0.}
	p.role=3;p.melee_hits={};var hit={"collider":device,"position":Vector3.ZERO,"normal":Vector3.UP}
	MeleeCombat.contact(g,1,hit,a.eye(),Vector3.FORWARD);expect(g.devices[901].hp==71.,"wrench repairs someone else's allied turret by 20")
	MeleeCombat.contact(g,1,hit,a.eye(),Vector3.FORWARD);expect(g.devices[901].hp==71.,"one repair per swing")
	p.melee_hits={};g.devices[901].hp=95.;MeleeCombat.contact(g,1,hit,a.eye(),Vector3.FORWARD);expect(g.devices[901].hp==100.,"repair clamps at maximum health")
	p.melee_hits={};g.devices[901].team=1;MeleeCombat.contact(g,1,hit,a.eye(),Vector3.FORWARD);expect(g.devices[901].hp==70.,"wrench deals 30 to enemy turret")
	p.role=0;p.melee_hits={};MeleeCombat.contact(g,1,hit,a.eye(),Vector3.FORWARD);expect(g.devices[901].hp==30.,"knife deals 40 to enemy turret")
	g.devices.clear();device.free()
	# Zero spread isolates the existing per-pellet damage accumulation from RNG.
	b.position=Vector3(0,0,-3.);q.alive=true;q.hp=500.;q.armor=0.
	p.primary="e1";p.slot=0;p.melee_started=-100.;p.fire_ready=0.;p.reload=0.;p.mag.e1=5;p.bloom=0.;p.spray_phase=0.;a.spread_angle=0.;a.aim_pitch=atan2(1.15-a.eye().y,3.);a.last_sprint=false;a.sprint_release=0.
	await physics_frame;g.fire(1)
	expect(is_equal_approx(500.-q.hp,140.),"ten PULSE pellets each apply 14 torso damage")
	# Shotgun marks use the real ballistic paths and bounded shared impact pool.
	b.position=Vector3(20,0,20);g.arena.box(Vector3(0,2.,-5.),Vector3(12,5,.3),Color.GRAY)
	await physics_frame;g.dedicated=false;p.role=3;p.slot=0;p.melee_started=-100.;p.primary="e1";p.reload=0.;p.fire_ready=0.;p.mag.e1=5;p.bloom=0.;a.spread_angle=4.;a.aim_pitch=0.;a.aim_yaw=0.;a.last_sprint=false;a.sprint_release=0.
	var before=g.wall_marks.size();g.fire(1)
	expect(g.wall_marks.size()-before==10,"PULSE produces ten distinct pellet impact marks")
	for wid in ["e1","e2","e3"]:
		var w=Catalog.get_weapon(wid)
		expect(int(w.pellets)>1 and CombatBalance.damage_at(w,1.,"head")>CombatBalance.damage_at(w,1.,"torso") and CombatBalance.damage_at(w,1.,"legs")<CombatBalance.damage_at(w,1.,"torso"),wid+" has per-pellet zone multipliers")
	for web in [false,true]:
		for wrench in [false,true]:
			var mark=MeleeMark.make(web,wrench);expect(mark.material_override.shader.code!=BulletMark.CODE,"melee marks are distinct from bullet craters");mark.free()
	g.free();await process_frame
	print("MELEE_V117_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
