extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var arena=Arena.new();root.add_child(arena)
	arena.walk_surfaces=[{"rect":Rect2(-2,-2,4,4),"low":2.,"high":6.}]
	expect(not ArenaLighting.fixture_clear(arena,Vector3(0,5.8,0),false),"street lamp cannot intersect stairs")
	expect(ArenaLighting.fixture_clear(arena,Vector3(5,5.8,5),false),"clear outdoor fixture remains")
	arena.walk_surfaces=[{"rect":Rect2(-2,-2,4,4),"low":4.,"high":4.}]
	expect(not ArenaLighting.fixture_clear(arena,Vector3(0,5.8,0),false),"pole cannot pass through upper floor")
	arena.free()
	for role in HumanModel.FEMALE_ROLES:
		var rig=load("res://assets/models/operator_%d_0.scn"%role).instantiate();root.add_child(rig)
		var pose=HumanModel.pose_rig(role);root.add_child(pose)
		for side in ["LeftArm","RightArm"]:
			var arm=rig.get_node("Hips/Chest/"+side)
			expect(is_equal_approx(arm.position.y,.175),"raised female shoulder socket")
			expect(arm.position==pose.get_node("Hips/Chest/"+side).position,"visible and hit pose shoulders match")
		rig.free();pose.free()
	for index in range(Rules.MAPS.size()):
		var map=Arena.new();root.add_child(map);map.build(index)
		for mesh in map.find_children("*","MeshInstance3D",true,false):
			if mesh.has_meta("fixture_point"):expect(ArenaLighting.fixture_clear(map,mesh.get_meta("fixture_point"),mesh.get_meta("fixture_indoor")),"fixture clearance map %d"%index)
		map.free();await process_frame
	var game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
	game.ui.practice_menu();expect(game.options.bots==7,"bot battle defaults to seven bots")
	game.ui.bot_setup=true;game.ui.gear()
	expect(game.phase=="menu" and game.players.is_empty(),"loadout selection precedes host and spawn")
	game.ui.gear_class.select(5);game.ui.refresh_weapons()
	var selected=game.ui.selected_loadout();var expected_weapon=selected.primary
	game.ui.exit_gear();expect(game.ui.screen=="practice" and game.options.bots==7,"back returns to retained bot setup")
	game.start_bot_match(selected);game.set_physics_process(false)
	expect(game.players[1].role==5 and game.players[1].primary==expected_weapon,"selected medic and weapon present on first spawn")
	expect(game.players.size()==8,"seven bots plus local player")
	game.ui.toggle_pause();expect(game.ui.panel.custom_minimum_size.x==480,"compact desktop pause menu")
	game.ui.clear_panel();game.ui.gear();game.ui.gear_class.select(1);game.ui.refresh_weapons()
	var deaths=int(game.players[1].deaths)
	for b in game.ui.panel.find_children("*","Button",true,false):
		if b.text.begins_with("사망 후"):b.pressed.emit();break
	expect(game.players[1].alive and game.players[1].role==1 and game.players[1].deaths==deaths+1,"actual immediate-apply button redeploys with one death")
	expect(not is_instance_valid(game.ui.panel),"immediate apply closes loadout")
	game.clock+=1.;game.cycle_weapon(1);expect(game.players[1].slot==1,"wheel advances to secondary")
	game.clock+=1.;game.cycle_weapon(-1);expect(game.players[1].slot==0,"reverse wheel returns to primary")
	var did=game.add_device("turret",Vector3(0,0,10),1,180.)
	var other=game.add_device("turret",Vector3(0,0,-10),-1,180.)
	game.players[1].protect=0.;game.damage(1,100000.,1,false,"redeploy")
	expect(not game.devices.has(did) and game.devices.has(other),"owner death destroys only their turret")
	game.spawn(1);game.options.mode=4;game.phase="combat";game.players[1].team=MatchFlow.attackers(game)
	game.bomb.planted=false;game.bomb.carrier=1;game.bomb.defused=false;game.bomb.exploded=false
	game.actors[1].position=game.arena.sites[0]
	expect(BombLogic.action(game,1)=="plant" and BombLogic.use_label(game,1)=="폭탄 설치","carrier sees planting prompt inside a site")
	game.bomb.carrier=-1;expect(BombLogic.action(game,1).is_empty(),"noncarrier cannot see planting action")
	game.bomb.planted=true;game.bomb.position=game.arena.sites[0];game.players[1].team=1-MatchFlow.attackers(game)
	expect(BombLogic.action(game,1)=="defuse","defender near planted bomb sees defuse prompt")
	game.actors[1].position+=Vector3.RIGHT*6;expect(BombLogic.action(game,1).is_empty(),"defuse prompt disappears outside actual range")
	game.players[1].skill_ready=game.clock+40.;game.players[1].gadget_ready=game.clock+10.
	game.spawn(1)
	expect(game.players[1].skill_ready<=game.clock and game.players[1].gadget_ready<=game.clock,"respawn resets ability cooldowns")
	var arc={"pos":Vector3.ZERO,"yaw":0.,"level":1}
	expect(TurretLogic.in_arc(arc,Vector3(20,60,-20)) and TurretLogic.in_arc(arc,Vector3(-20,-60,-20)),"100 degree horizontal arc ignores elevation")
	expect(not TurretLogic.in_arc(arc,Vector3(30,0,-20)),"outside 100 degree arc is rejected")
	game.options.mode=0;game.phase="combat";game.clock=100.
	for pid in game.players:game.players[pid].alive=false;game.actors[pid].collision_layer=0
	game.players[1].alive=true;game.players[1].team=0;game.players[1].protect=0.
	game.players[-1].alive=true;game.players[-1].team=1;game.players[-1].protect=0.
	for old in game.devices.keys():game.remove_device(old)
	var tower=game.add_device("turret",Vector3(0,60,-10),1,180.)
	game.actors[1].position=Vector3(1000,60,1000);game.actors[-1].position=Vector3(0,60,0)
	game.actors[-1].reset_view(0.);game.update_world_visuals(.016)
	await physics_frame;await physics_frame
	var own_node=game.device_nodes[tower]
	var meshes=own_node.find_children("*","MeshInstance3D",true,false)
	expect(not meshes.is_empty() and meshes[0].material_overlay!=null and meshes[0].material_overlay.no_depth_test,"own device silhouette renders through walls")
	DeploymentSilhouette.apply(own_node,game.devices[tower],-1)
	expect(meshes[0].material_overlay==null,"other players devices have no silhouette")
	DeploymentSilhouette.apply(own_node,game.devices[tower],1)
	var bot=BotAgent.new();bot.setup(game,-1);bot.perceive()
	expect(bot.device_target==tower and bot.visible_target,"bot acquires visible hostile turret")
	bot.ready_to_fire=0.;bot.choose_action();bot.next_perception=200.;bot.next_decision=200.
	game.players[-1].primary="a1";game.players[-1].secondary="pistol";game.players[-1].role=0;game.players[-1].slot=0
	game.equip_ammo(game.players[-1]);game.clock=100.7;bot.tick(.1)
	expect(game.actors[-1].input_state.fire,"bot fires at hostile turret")
	game.devices[tower].yaw=PI;game.devices[tower].disabled=0.;game.devices[tower].next_scan=0.
	game.actors[-1].position=Vector3(0,75,5)
	await physics_frame
	expect(TurretLogic.visible_point(game,game.devices[tower],-1,[own_node.get_rid()])!=Vector3.INF,"turret detects exposed enemy on higher floor")
	game.actors[-1].position=Vector3(0,45,5)
	await physics_frame
	expect(TurretLogic.visible_point(game,game.devices[tower],-1,[own_node.get_rid()])!=Vector3.INF,"turret detects exposed enemy on lower floor")
	game.players[1].role=3;game.actors[1].position=game.devices[tower].pos+Vector3.RIGHT*2
	game.players[1].skill_ready=game.clock-1.;game.devices[tower].upgrade_ready=game.clock+12.
	var display=AbilityBalance.skill_state(game,1)
	expect(display.remaining==12. and display.label=="포탑 강화","HUD shows upgrade cooldown rather than ready deployment timer")
	game.devices[tower].level=4
	expect(not AbilityBalance.skill_state(game,1).enabled,"max level upgrade is not shown ready")
	game.actors[1].position+=Vector3.RIGHT*20;game.players[1].skill_ready=game.clock+9.
	expect(AbilityBalance.skill_state(game,1).remaining==9.,"away from turret HUD follows placement cooldown")
	expect(TurretLogic.ROCKET_SPEED==30.,"missile velocity raised from 18 to 30 m/s")
	game.players[1].role=1;game.players[1].primary="r1";game.players[1].slot=0;game.actors[1].input_state.ads=true
	expect(SniperScope.active(game) and SniperScope.magnification(game.profile,Catalog.get_weapon("r1"))==4.,"sniper default is four times magnification")
	SniperScope.change(game,1);SniperScope.change(game,1)
	expect(SniperScope.magnification(game.profile,Catalog.get_weapon("r1"))==8.,"SCOUT maximum is eight times")
	game.actors[1].input_state.ads=false;game.actors[1].input_state.ads=true
	expect(SniperScope.magnification(game.profile,Catalog.get_weapon("r1"))==8.,"scope reentry retains selected zoom")
	game.players[1].primary="r2";SniperScope.change(game,1);SniperScope.change(game,1)
	expect(SniperScope.magnification(game.profile,Catalog.get_weapon("r2"))==16.,"MONOLITH supports sixteen times")
	expect(SniperScope.fov(game.profile,Catalog.get_weapon("r2"))<7.,"sixteen times uses optical field of view")
	game.profile.sniper_mouse_sensitivity=1.2;game.profile.sniper_touch_sensitivity=.4
	expect(is_equal_approx(SniperScope.sensitivity(game),.3) and is_equal_approx(SniperScope.sensitivity(game,true),.1),"independent mouse and touch sniper sensitivities scale with zoom")
	game.players[1].primary="r3"
	expect(not SniperScope.active(game) and SniperScope.fov(game.profile,Catalog.get_weapon("r3"))==25.,"designated marksman zoom unchanged")
	var shooter=game.actors[1];shooter.position=Vector3(0,60,0);shooter.reset_view(0.);shooter.aim_progress=0.
	var hip=shooter.desired_muzzle();shooter.aim_progress=1.;var sight=shooter.desired_muzzle()
	expect(sight.y-hip.y>.35 and absf(sight.y-shooter.eye().y)<.06,"ADS muzzle rises to eye level and hip muzzle stays below chest")
	var barrier=StaticBody3D.new();barrier.collision_layer=1;game.add_child(barrier)
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(2,1.4,.18);collision.shape=shape;barrier.add_child(collision);barrier.position=Vector3(0,60.7,-.45)
	await physics_frame;await physics_frame
	expect(game.ray(shooter.eye(),sight,[shooter.get_rid()],1).is_empty() and not game.ray(shooter.eye(),hip,[shooter.get_rid()],1).is_empty(),"ADS clears chest-high cover while hip barrel is blocked")
	shape.size.y=2.;barrier.position.y=61.
	await physics_frame;await physics_frame
	expect(not game.ray(shooter.eye(),sight,[shooter.get_rid()],1).is_empty(),"ADS cannot fire through full-height wall")
	barrier.free()
	game.options.mode=0;game.players[1].team=0;game.players[-2].team=0;game.players[-1].team=1;game.players[-1].alive=true
	TargetReveal.mark(game,-1,1,4.)
	expect(TargetReveal.visible_to(game,-1,1) and TargetReveal.visible_to(game,-1,-2),"scan silhouette is shared with every teammate")
	game.players[-3].team=1
	expect(not TargetReveal.visible_to(game,-1,-3),"opposing team does not receive reveal")
	game.clock+=4.1
	expect(not TargetReveal.visible_to(game,-1,1),"scan silhouette expires after four seconds")
	TargetReveal.mark(game,-1,1,6.);game.clock+=5.
	expect(TargetReveal.visible_to(game,-1,-2),"marker silhouette remains for six seconds")
	game.players[-1].mark=0.
	expect(not TargetReveal.visible_to(game,-1,1),"cleanse removes reveal immediately")
	game.options.mode=1;TargetReveal.mark(game,-1,1,4.)
	expect(TargetReveal.visible_to(game,-1,1) and not TargetReveal.visible_to(game,-1,-2),"free-for-all reveal belongs only to its source")
	game.leave_game();game.free();await process_frame
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.kind!="gun":continue
		var weapon=WeaponVisual.new();root.add_child(weapon);weapon.build(w,false)
		var duration=w.reload
		weapon.animate_reload(.85,0.)
		expect(weapon.action_part.position.z>weapon.action_origin.z+.06,"chambering phase "+id)
		weapon.animate_reload(1.,0.)
		expect(weapon.action_part.position.is_equal_approx(weapon.action_origin) and w.reload==duration,"reload ends at unchanged duration "+id)
		weapon.free()
	print("V112_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
