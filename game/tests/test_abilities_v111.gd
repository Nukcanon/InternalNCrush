extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(200,1,200),Color.GRAY)
	g.add_player(1,"Builder","builder");g.add_player(2,"Target","target");g.players[1].team=0;g.players[2].team=1;g.phase="combat";g.clock=100.
	var p=g.players[1];var q=g.players[2];var a=g.actors[1];var b=g.actors[2]
	p.protect=0.;q.protect=0.;p.role=3;p.primary="e1";p.gadget=0;p.gadget_count=2;a.position=Vector3(20,0,20);b.position=Vector3(20,0,0);a.reset_view(0.)
	await physics_frame;await physics_frame
	g.use_skill(1);expect(g.devices.is_empty() and p.placing=="turret" and p.skill_ready==0.,"placement preview spends no charge and creates no device")
	expect(Deployment.confirm(g,1) and g.devices.size()==1 and p.builds==1,"click confirmation validates floor and awards one build")
	var did=g.devices.keys()[0];var turret=g.devices[did]
	for level in range(2,5):turret.upgrade_ready=0.;p.skill_ready=0.;TurretLogic.upgrade(g,1,did);expect(turret.level==level,"nearby turret upgrade level %d"%level)
	TurretLogic.upgrade(g,1,did);expect(turret.level==4,"turret upgrades stop at level four")
	turret.disabled=0.;turret.next_fire=1000.;turret.rocket_ready=0.;turret.target=2;turret.lock=0.;turret.next_scan=1000.
	TurretLogic.track(turret,(b.eye()-Vector3.UP*.35-TurretLogic.origin(turret)).normalized(),1.)
	TurretLogic.tick(g,.016);expect(g.rockets.size()==1 and turret.rocket_ready==102.,"level four launches a slow missile once every two seconds")
	TurretLogic.tick(g,.016);expect(g.rockets.size()==1,"missile cooldown prevents duplicate launches")
	g.rockets.clear();turret.level=1;turret.next_fire=0.;turret.next_scan=0.;turret.target=0;turret.lock=0.
	b.position=Vector3(40,0,16);await physics_frame;TurretLogic.tick(g,.016);expect(turret.target==0 and q.hp==100.,"automatic fire rejects a target outside its forward arc")
	p.primary="remote";p.slot=0;a.input_state.fire=true;var delta=b.eye()-Vector3.UP*.3-a.eye();a.aim_yaw=atan2(-delta.x,-delta.z);a.aim_pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
	for frame in range(60):TurretLogic.tick(g,1./60.)
	expect(turret.remote and q.hp<100.,"remote control can hit a target outside the automatic arc")
	expect(100.-q.hp<TurretLogic.DAMAGE[0],"remote hit applies distance falloff")
	p.role=0;p.skill_ready=0.;g.use_skill(1);expect(p.dash==105. and p.dash_recovery==108.,"movement skill has five fast seconds and three recovery seconds")
	p.role=1;p.skill_ready=0.;g.use_skill(1);expect(q.mark==104. and p.skill_ready==140.,"scan marks for four seconds with forty-second cooldown")
	p.role=2;p.skill_ready=0.;g.use_skill(1);expect(p.shield==106.,"heavy protection lasts six seconds")
	p.role=4;p.skill_ready=0.;g.use_skill(1);expect(g.fields.back().kind=="slow" and AbilityBalance.SLOW_RADIUS==11.,"slow field has expanded eleven-metre radius")
	p.role=5;p.skill_ready=0.;g.use_skill(1);expect(p.invul_select>g.clock and p.skill_ready==0.,"medic can select a target without consuming its skill")
	g.use_skill(1);expect(p.invulnerable==104. and p.skill_ready==145.,"double activation grants self invulnerability")
	var health=p.hp;g.damage(1,999.,2,false,"fall");expect(p.hp==health,"invulnerability also blocks fall damage")
	p.invulnerable=0.;p.shield=0.;p.armor=50.;p.hp=100.;g.damage(1,40.,1,false,"fall");expect(p.hp==60. and p.armor==50.,"fall damage bypasses armour")
	g.leave_game();g.free();await process_frame
	print("ABILITIES_V111_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
