extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",message)
func run():
	Catalog.load_all()
	for wid in ["r1","r2","r3","r4","r5"]:expect(Catalog.get_weapon(wid).ads_ms<=320,"faster scoped aim transition "+wid)
	var sounds=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	for name in ["bomb_planted","bomb_dropped","bomb_defused","bomb_defuse"]:expect(sounds.has(name) and ResourceLoader.exists(sounds[name].file),"bomb audio ships in build "+name)
	var d={"pos":Vector3.ZERO,"yaw":0.,"level":1}
	expect(TurretLogic.in_arc(d,Vector3(0,0,-20)) and not TurretLogic.in_arc(d,Vector3(30,0,-20)),"automatic turret has a 100 degree arc")
	expect(is_equal_approx(TurretLogic.remote_damage(10.,12.),10.) and is_equal_approx(TurretLogic.remote_damage(10.,48.),1.),"remote bullets sharply fall off between 12 and 48 metres")
	expect(TurretLogic.remote_damage(10.,30.)>TurretLogic.remote_damage(10.,40.),"remote damage decreases continuously")
	expect(TurretLogic.SCALES[0]==.5 and TurretLogic.SCALES[3]==1.,"turret grows from half size to full size")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.options.map_random=false;g.options.mode=4;g.options.map=19;g.options.max_players=12;g.phase="lobby";g.build_world()
	for id in range(1,13):g.add_player(id,"TEST "+str(id),"test"+str(id));g.players[id].team=0 if id<=6 else 1
	for index in range(19,31):
		g.options.map=index;g.build_world();g.phase="buy";g.round_no=1
		for p in g.players.values():p.alive=false
		for id in g.players:g.spawn(id);MatchFlow.preparation(g,id)
		var separate=true
		for id in g.players:
			for other in g.players:
				if id!=other and g.actors[id].position.distance_to(g.actors[other].position)<1.3:separate=false
		expect(separate,"defusal map %d assigns distinct spawn slots after preparation clamp"%index)
		MatchFlow.update_gate(g)
		var gate=g.arena.get_node("PreparationGate")
		expect(gate.get_child(0).get_child(0).shape.size.z>=1. and gate.get_child(0).get_child(1).material_override.albedo_color.a<.5,"preparation gate is thick and translucent %d"%index)
		g.players[1].protect=0.;g.damage(1,999.,7);expect(g.players[1].hp==100. and not g.can_attack(g.players[1]),"preparation blocks attack and incoming damage %d"%index)
		g.phase="combat";MatchFlow.update_gate(g);g.actors[1].position=g.arena.sites[0];g.bomb={"carrier":1,"planted":false,"site":-1,"actor":0,"progress":0.,"position":Vector3.ZERO,"time":0.}
		g.interact(1,3.1)
		expect(g.bomb.planted and g.bomb.time==(120. if index<25 else 150.),"map %d uses the requested bomb countdown"%index)
		await physics_frame
	var own=MatchFlow.spawn_rect(g,0);var defender=MatchFlow.spawn_rect(g,1)
	g.phase="buy";MatchFlow.update_gate(g)
	g.actors[7].position=Vector3(defender.get_center().x,0,defender.end.y+3.);var before=g.actors[7].position;MatchFlow.preparation(g,7)
	expect(g.actors[7].position==before and g.actors[7].collision_mask&32==0,"defenders can leave their spawn during preparation")
	g.actors[1].position=Vector3(own.get_center().x,0,own.position.y-3.);MatchFlow.preparation(g,1)
	expect(own.has_point(Vector2(g.actors[1].position.x,g.actors[1].position.z)),"attackers stay inside their spawn during preparation")
	g.phase="combat";MatchFlow.update_gate(g);g.actors[1].position=Vector3(own.get_center().x,0,own.position.y-3.);before=g.actors[1].position;MatchFlow.preparation(g,1)
	expect(g.actors[1].position==before and g.actors[1].collision_mask&16==0,"attackers can leave after preparation without stale collision")
	g.actors[1].position=Vector3(defender.get_center().x,0,defender.get_center().y);MatchFlow.preparation(g,1)
	expect(not defender.has_point(Vector2(g.actors[1].position.x,g.actors[1].position.z)),"enemy spawn remains forbidden after preparation")
	var gate=g.arena.get_node("PreparationGate");expect(gate.get_child(0).get_child(1).material_override.albedo_color.g>.7,"own spawn gate turns green when unlocked")
	await physics_frame
	var center=Vector3(own.get_center().x,1.5,own.get_center().y)
	expect(not g.ray(center,center+Vector3.FORWARD*15.,[],1).is_empty(),"spawn boundary blocks fire even when its team can walk through")
	expect(BombLogic.beep_interval(100,120)==1.2 and BombLogic.beep_interval(50,120)==.75 and BombLogic.beep_interval(20,120)==.4 and BombLogic.beep_interval(5,120)==.16,"bomb beeps accelerate through four stages")
	var p=g.players[7];p.cash=800;p.protect=0.;p.owned_primary=true;g.phase="buy"
	var request={"role":p.role,"primary":p.primary,"armor":0,"gadget":9}
	expect(g.loadout_cost(p,request)==400,"defuse kit costs 400 credits instead of the class gadget")
	g.commit_loadout(7,request);expect(p.gadget==9 and p.cash==400,"purchase equips the kit in the gadget slot")
	var stock=p.gadget_count;g.phase="combat";g.use_gadget(7);expect(p.gadget_count==stock,"kit does not invoke or consume the replaced class gadget")
	g.actors[7].position=g.bomb.position;g.bomb.actor=0;g.bomb.progress=0.;g.interact(7,9.9);expect(g.phase=="combat","kit cannot defuse before ten seconds")
	g.interact(7,.11);expect(g.phase!="combat","kit completes defuse at ten seconds")
	g.phase="combat";p.gadget=0;g.bomb.actor=0;g.bomb.progress=0.;g.interact(7,29.9);expect(g.phase=="combat","without kit defuse takes thirty seconds")
	g.interact(7,.11);expect(g.phase!="combat","normal defuse completes at thirty seconds")
	g.phase="combat";g.bomb.planted=false;BombLogic.assign(g)
	var carrier=int(g.bomb.carrier)
	expect(carrier!=0 and g.players[carrier].team==MatchFlow.attackers(g),"exactly one living attacker receives the bomb")
	BombLogic.drop(g,carrier);expect(g.bomb.dropped and g.bomb.carrier==0,"carrier drops the bomb on death or disconnect")
	g.actors[7].position=g.bomb.position;expect(not BombLogic.pickup(g,7),"defenders cannot pick up the dropped bomb")
	g.actors[2].position=g.bomb.position;expect(BombLogic.pickup(g,2) and g.bomb.carrier==2,"attacker can recover the bomb")
	g.bomb.planted=true;g.bomb.site=0;g.bomb.carrier=0;g.bomb.position=g.arena.sites[0];g.actors[2].position=g.arena.sites[1];g.interact(2,4.)
	expect(g.bomb.site==0,"a planted bomb cannot be placed at the second site")
	var radius=BombLogic.radius(g)
	expect(radius<=30. and radius<=minf(g.arena.bounds.x,g.arena.bounds.y)*.4,"bomb blast respects both map and thirty-metre limits")
	g.players[1].protect=0.;g.players[1].armor=0.;g.players[1].hp=100.;g.actors[1].position=g.bomb.position+Vector3.RIGHT*2.
	g.players[7].protect=0.;g.players[7].armor=0.;g.players[7].hp=100.;g.actors[7].position=g.bomb.position+Vector3.RIGHT*(radius+3.)
	g.bomb.time=.001;g.check_objectives(.016)
	expect(g.bomb.time==0.,"expired countdown clamps to zero without negative zero")
	expect(not g.players[1].alive and g.players[7].hp==100.,"bomb kills in the blast area and preserves players beyond it")
	expect(g.phase=="round_end" and g.bomb.exploded,"bomb detonation ends the round exactly once")
	g.leave_game();g.free();await process_frame
	print("V111_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
