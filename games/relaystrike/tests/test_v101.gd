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
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		expect(w.has_all(["weight_kg","portability","stability","ads_ms","ads_spread"]),id+" has displayed handling stats")
		if w.kind!="gun":continue
		var standing=AimModel.spread(w,0,false,false,false,true,0)
		var moving=AimModel.spread(w,7.4,false,false,false,true,0)
		var aiming=AimModel.spread(w,0,true,false,false,true,0)
		expect(moving>standing and standing>aiming,id+" movement and ADS change actual spread")
		var recoil={"spray_phase":10.,"bloom":w.bloom_max}
		var cone=AimModel.spread(w,0,false,false,false,true,w.bloom_max)
		expect(AimModel.reticle_angle(w,recoil,cone)>=cone,id+" reticle includes the spray pattern envelope")
		AimModel.recover(recoil,w,3.,100.)
		expect(recoil.bloom<.001 and recoil.spray_phase<.001,id+" sustained spread recovers after a pause")
	expect(Catalog.get_weapon("r2").spread>Catalog.get_weapon("r3").spread and Catalog.get_weapon("r3").spread>Catalog.get_weapon("a1").spread*4,"sniper hip cone is larger than DMR and rifle")
	expect(Catalog.get_weapon("c2").shot_bloom>Catalog.get_weapon("a4").shot_bloom and Catalog.get_weapon("e1").shot_bloom<Catalog.get_weapon("pistol").shot_bloom,"stability differentiates automatic and sidearm handling")
	expect(Catalog.get_weapon("r2").move_spread>Catalog.get_weapon("c2").move_spread and Catalog.get_weapon("r2").ads_ms>Catalog.get_weapon("c2").ads_ms,"heavy scoped weapons have larger movement penalties and slower ADS")
	for native in [Vector2i(1920,1080),Vector2i(3440,1440),Vector2i(7680,4320),Vector2i(1440,2560)]:
		var choices=DisplayOptions.resolutions_for(native)
		expect(native in choices and choices.all(func(v):return v.x<=native.x and v.y<=native.y),"resolution presets fit "+str(native))
	var female=0
	for role in range(6):
		var model=HumanModel.build(role,0)
		if model.get_meta("gender")=="female":female+=1
		var chest=model.get_node("Hips/Chest");var hip=model.get_node("Hips")
		expect(chest.get_node("RightArm").position.x<.23 and hip.get_node("RightLeg").position.x<.105,"role %d has narrowed shoulders and hip joints"%role)
		model.free()
	expect(female==2,"six-role roster contains two female operators")
	for size in [6,8,16,32]:
		var flat=Rules.maps_for_size(size).filter(func(index):return not VerticalLayout.enabled(index))
		expect(flat.size()==1,"one flat map remains for %d players"%size)
	for index in range(19):
		if not VerticalLayout.enabled(index):continue
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena)
		expect(int(arena.get_meta("stair_count",0))>=6 and arena.get_meta("vertical_levels").size()>=3,"map %d has stairs, ground, upper floor and underground"%index)
		for team in [0,1]:
			var start=arena.spawn_points[team][3]
			for goal in arena.navigation_goals:
				var route=nav.route(start,goal)
				expect(route.size()>1 and route[-1].distance_to(goal)<2.1,"map %d team %d reaches %s"%[index,team,str(goal)])
		await physics_frame;await physics_frame
		var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,-.5,0),Vector3(0,-5,0),1))
		expect(not hit.is_empty() and absf(hit.position.y+3.2)<.05,"map %d basement has actual walkable floor"%index)
		arena.free();await process_frame
	var g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map=0;g.build_world();g.add_player(1,"TEST","v101_test")
	var actor=g.actors[1];var p=g.players[1]
	p.hand=-1;actor.reset_view(0);actor.visual(.1,p,g.clock)
	expect(actor.handedness==-1 and actor.character.scale.x<0 and actor.gun.scale.x<0,"left-handed spawn mirrors first and third person models")
	p.hand=1;actor.reset_view(0);actor.visual(.1,p,g.clock)
	expect(actor.handedness==1 and actor.character.scale.x>0,"right-handed spawn restores both models")
	var left=0;seed(101)
	for i in range(300):
		g.spawn(1)
		if p.hand==-1:left+=1
	expect(left>15 and left<60,"server chooses a low left-handed proportion ("+str(left)+"/300)")
	g.phase="combat";g.clock=100.;p.primary="a1";p.slot=0;p.protect=0.;p.reload=0.;p.fire_ready=0.;p.switch_until=0.;p.bloom=0.;p.spray_phase=0.;g.equip_ammo(p)
	actor.position=Vector3(0,.15,76);actor.reset_view(0);await physics_frame;await physics_frame
	actor.simulate(.016,g.clock,false);actor.visual(.016,p,g.clock);var initial=actor.visual_spread
	for i in range(9):
		g.clock+=.13;p.fire_ready=0.;actor.sprint_release=0.;g.fire(1);actor.update_spread(.13,g.clock);actor.visual(.13,p,g.clock)
	expect(actor.visual_spread>initial+1. and p.bloom>1.,"real firing grows stationary on-screen crosshair")
	actor.input_state.ads=true;actor.aim_progress=0.;actor.update_spread(.1,g.clock)
	expect(actor.aim_progress>0 and actor.aim_progress<1.,"ADS accuracy transitions over the weapon-specific aiming time")
	g.ui.gear();g.ui.preview_kind=1;g.ui.refresh_gear_detail();g.ui.refresh_gear_cards()
	expect(g.ui.role_cards.get_child_count()==6 and g.ui.gear_cards.get_child_count()>=3,"equipment selector exposes operator and weapon picture cards")
	expect("안정성" in g.ui.gear_detail.text and "휴대성" in g.ui.gear_detail.text and not g.ui.gear_primary.get_parent().visible,"weapon stats appear alongside visual selection")
	g.leave_game();g.free();await process_frame
	print("V101_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
