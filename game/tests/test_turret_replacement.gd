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

	expect(turret.upgrade_ready==135.,"first deployment waits full cooldown")
	TurretLogic.upgrade(g,1,did);expect(turret.level==1,"early upgrade rejected")
	g.clock=135.;TurretLogic.upgrade(g,1,did);expect(turret.level==2,"upgrade available at deadline")
	a.position.x+=12.;p.placing="turret"
	await physics_frame;await physics_frame
	expect(Deployment.confirm(g,1),"replacement succeeds after deployment cooldown")
	expect(not g.devices.has(did) and g.devices.size()==1,"old turret removed once")
	did=g.devices.keys()[0];turret=g.devices[did]
	expect(turret.level==1 and turret.upgrade_ready==170.,"replacement gets fresh upgrade deadline")
	expect(p.skill_ready==170.,"replacement preserves deployment cooldown")
	TurretLogic.upgrade(g,1,did);expect(turret.level==1,"replacement cannot instantly upgrade")
	g.clock=169.99;TurretLogic.upgrade(g,1,did);expect(turret.level==1,"upgrade remains locked before deadline")
	g.clock=170.;TurretLogic.upgrade(g,1,did);expect(turret.level==2,"replacement upgrades at deadline")
	g.free();await process_frame
	print("TURRET_REPLACEMENT_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
