extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	for pair in [["head",300.],["torso",120.],["arms",90.],["legs",90.],["hands",80.],["feet",80.]]:expect(is_equal_approx(CombatBalance.damage_at(Catalog.get_weapon("r2"),10.,pair[0]),pair[1]),"MONOLITH "+pair[0])
	expect(CombatBalance.damage_at(Catalog.get_weapon("r2"),200.,"head")>200.,"head beats highest HP plus armor at range")
	for role in range(6):
		for id in ["pistol","heavy_pistol","auto_pistol","dual_pistols"]:expect(id in Catalog.secondaries_for(role),"universal sidearm "+id)
	expect(Catalog.get_weapon("m1").price==800,"LINK price")
	var opt=Rules.default_options();expect(opt.minutes==10 and opt.target==60 and opt.rounds==4 and opt.prep_seconds==30,"mode defaults")
	opt.minutes=0;expect(ModeOptions.seconds(opt)>1e10,"unlimited match timer");opt.mode=4;expect(ModeOptions.seconds(opt)==300.,"defusal separate round timer")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options=Rules.default_options();g.options.map_random=false
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(160,1,160),Color.GRAY);g.arena.sites=[Vector3(10,0,10),Vector3(-10,0,-10)]
	g.add_player(1,"One","one");g.add_player(2,"Two","two");g.players[1].team=0;g.players[2].team=1
	TeamBalance.reconcile(g);expect(g.players.size()==2,"even players need no automatic bot")
	# 1.3.2: the host manages teams for everyone; restore the pairing afterwards.
	expect(g.change_team(1,2,0) and g.players[2].team==0,"host can move another person")
	g.players[2].team=1;g.actors[2].set_team(1);g.options.manual_roster=false
	expect(not g.change_team(2,2,0),"self cannot unbalance teams")
	g.add_player(3,"Three","three");TeamBalance.reconcile(g);expect(g.players.size()==4 and TeamBalance.auto_ids(g).size()==1,"odd players get one hard bot")
	var auto_id=TeamBalance.auto_ids(g)[0];expect(g.bot_agents[auto_id].difficulty==2,"automatic bot hard difficulty")
	TeamBalance.remove_auto(g,auto_id);g.players.erase(3);g.actors[3].free();g.actors.erase(3)
	g.options.mode=4;g.options.map=19;g.options.map_rotation=false;g.clock=100.;g.start_match()
	var p=g.players[1];var q=g.players[2]
	expect(p.primary=="" and p.slot==1 and p.secondary=="pistol" and p.gadget==-1,"pistol only defusal start")
	expect(not GadgetLoadout.has_item(p) and not GadgetLoadout.selectable(p),"unbought gadget absent")
	expect(MatchFlow.attackers(g)==0,"first half attackers")
	g.round_no=2;expect(MatchFlow.attackers(g)==0,"same side through half");g.round_no=3;expect(MatchFlow.attackers(g)==1,"halftime swaps sides");g.round_no=5;g.overtime_attacker=0;expect(MatchFlow.attackers(g)==0,"overtime assigned side")
	g.round_no=1;p.cash=4000
	var buy_spawn=MatchFlow.spawn_rect(g,int(p.team)).get_center()
	g.actors[1].position=Vector3(buy_spawn.x,0.,buy_spawn.y)
	var purchase={"role":0,"primary":"a1","secondary":"pistol","armor":0,"gadget":8,"confirmed":true}
	g.commit_loadout(1,purchase);expect(p.primary=="a1" and p.slot==0 and p.gadget_count==2,"owned slots purchased")
	var money=p.cash;g.commit_loadout(1,purchase);expect(p.cash==money,"same equipment no duplicate charge")
	g.phase="combat";p.team=0;q.team=1;p.protect=0.;q.protect=0.;g.bomb.carrier=1
	var actor=g.actors[1];actor.position=Vector3(12,0,11);actor.input_state.use=true
	var plant=actor.position
	for i in range(185):g.interact(1,1./60.)
	expect(g.bomb.planted and g.bomb.position.distance_to(plant)<.05,"bomb stays at actual plant location without crash")
	g.actors[2].position=g.bomb.position+Vector3(2.2,0,0);expect(BombLogic.action(g,2)=="","defuse requires close range")
	g.actors[2].position=g.bomb.position+Vector3(1.2,0,0);g.actors[2].input_state.use=true;expect(BombLogic.busy(g,2) and not g.can_attack(q),"defuse locks attacks")
	g.interact(2,1.);expect(g.bomb.progress>=1.,"defuse progress accumulates");g.actors[2].input_state.use=false;g.check_objectives(.01);expect(g.bomb.progress==0.,"release resets defuse progress")
	g.bomb.planted=false;g.bomb.carrier=1;g.bomb.actor=0;actor.position=Vector3.ZERO;actor.input_state.use=false
	BombLogic.tap(g,1);g.clock+=.2;BombLogic.tap(g,1);expect(g.bomb.dropped and g.bomb.carrier==0,"double use drops bomb outside site")
	await physics_frame;await physics_frame
	for i in range(150):BombLogic.tick(g,1./60.);await physics_frame
	var resting=g.bomb.position
	for i in range(30):BombLogic.tick(g,1./60.)
	expect(g.bomb.get("resting",false) and g.bomb.position.is_equal_approx(resting),"dropped bomb settles without vibrating")
	g.damage(1,10000.,2);expect(p.primary=="" and p.secondary=="pistol" and p.gadget==-1 and p.armor_max==0,"death loses purchased gear")
	g.phase="combat";g.round_no=4;g.scores=[2,1];DefusalMatch.finish(g,1,"test");expect(g.phase=="round_end","tied series gets overtime")
	DefusalMatch.begin(g);expect(g.round_no==5 and MatchFlow.attackers(g) in [0,1],"one random side overtime begins")
	g.phase="combat";DefusalMatch.finish(g,0,"test");expect(g.phase=="result" and g.result.team==0,"overtime winner ends series")
	g.phase="combat";g.round_no=4;g.scores=[3,0];DefusalMatch.finish(g,1,"last round");expect(g.result.team==0,"series champion differs from last round winner")
	var pose=GunModel.new();g.add_child(pose);pose.build(Catalog.get_weapon("dual_pistols"));pose.animate_reload(.8,.2,.02);pose.fire_side=1;expect(is_instance_valid(pose.muzzle) and pose.muzzle==pose.muzzles[1],"dedicated DUET pose has valid alternating muzzle");pose.free()
	g.phase="lobby";g.options.mode=0
	g.players[1].team=0;g.players[2].team=0;TeamBalance.reconcile(g)
	expect(g.team_count(0)==g.team_count(1),"multiple departures balanced without moving humans")
	for bid in TeamBalance.auto_ids(g):expect(g.bot_agents[bid].difficulty==2,"all fill bots hard")
	g.players[2].team=1;TeamBalance.reconcile(g);expect(TeamBalance.auto_ids(g).is_empty(),"excess fill bots removed after returning player")

	g.phase="combat";g.options.mode=0;g.clock=200.;p.alive=true;p.protect=0.;p.reload=0.;p.placing="";p.gadget_ready=0.;p.owned_gadget=true;p.invul_select=0.;p.slot=2
	var click_serial=20
	for kind in [8,0,1]:
		p.role=4 if kind!=8 else 0;p.gadget=kind;GadgetLoadout.reset(p);p.gadget_count=1;p.smoke=1;p.flash_count=1;p.gadget_ready=0.;p.cooking=0
		g.clock+=5.;click_serial+=1;g.handle_command(1,"trigger_press",{"seq":click_serial})
		expect(p.cooking>0 and g.grenades[-1].held,"mouse/touch press cooks last throwable "+str(kind))
		g.actors[1].input_state.fire=false;g.process_trigger(1);g.clock+=.4;GrenadeLogic.tick(g,.01)
		expect(p.cooking>0 and g.grenades[-1].held,"no input snapshot can immediately throw direct press "+str(kind))
		g.handle_command(1,"trigger_release",{})
		expect(p.cooking==0 and not g.grenades[-1].held and g.grenades[-1].velocity.length()>10.,"release throws "+str(kind))
		g.clock+=.4;expect(not GadgetLoadout.held_visible(p,g.clock) and not GadgetLoadout.selectable(p),"last item leaves empty hand/slot "+str(kind))
		g.grenades.clear()
	p.role=1;p.gadget=0;p.slot=0;p.primary="r1";p.owned_primary=true;p.flash=0.;p.reload=0.;p.gadget_count=1
	q.alive=true;q.team=1;q.cleanse=0.;g.actors[1].position=Vector3.ZERO;g.actors[2].position=Vector3(0,0,-25)
	g.actors[1].aim_yaw=0.;g.actors[1].aim_pitch=0.;g.actors[1].input_state.ads=true;g.actors[1].aim_progress=1.;g.actors[1].input_state.use=false
	await physics_frame;await physics_frame
	expect(GadgetLoadout.has_item(p) and not GadgetLoadout.selectable(p),"marker is passive equipment")
	g.handle_command(1,"slot",{"slot":2});expect(p.slot==0,"passive shortcut rejected by authority")
	for i in range(10):MarkerTracker.tick(g,1,.1)
	expect(p.marker_target==2 and p.marker_progress>.9,"scope tracks nearest central target")
	g.actors[1].aim_yaw=.3;MarkerTracker.tick(g,1,.1);expect(p.marker_progress==0.,"leaving marker cone restarts countdown")
	g.actors[1].aim_yaw=0.;p.primary="a1";MarkerTracker.tick(g,1,.1);expect(p.marker_target==0,"ordinary rifle cannot mark")
	p.primary="r1"
	for i in range(20):MarkerTracker.tick(g,1,.1)
	expect(q.mark>g.clock,"two seconds of scope dwell marks target")
	expect(is_equal_approx(MarkerTracker.HALF_ANGLE_DEGREES,1.25),"marker cone and ring diameter reduced to one quarter")
	g.actors[1].aim_yaw=deg_to_rad(2.);MarkerTracker.tick(g,1,.1)
	expect(p.marker_target==0 and p.marker_progress==0.,"previous broad-cone target no longer acquires outside narrowed cone")
	g.actors[1].aim_yaw=0.
	g.actors[2].ensure_character()
	TargetReveal.apply(g.actors[2],q)
	var shown=g.actors[2].character.get_meta("silhouette_meshes",[])
	expect(not shown.is_empty(),"marked opponent has visibility-gated silhouette assembly")
	for mesh in shown:
		expect(mesh.material_overlay!=null and mesh.material_overlay.next_pass==TargetReveal.outline_for(1),"marked enemy gets its own team outline and occluded silhouette")
	g.local_id=2;TargetReveal.apply(g.actors[2],q)
	for mesh in shown:expect(mesh.material_overlay==null,"unrelated observer gets neither outline nor through-wall fill")
	g.local_id=1;TargetReveal.apply(g.actors[2],q)
	var reticle=load("res://scripts/reticle.gd").new();root.add_child(reticle);reticle.position=Vector2(80,40);reticle.scale=Vector2(.7,.7)
	var camera=g.actors[1].camera;camera.position=Vector3(0,1.6,0);camera.look_at(g.actors[2].character.head_position())
	var marker=reticle.marker_position(g.actors[2],camera)
	var projected=camera.unproject_position(g.actors[2].character.head_position()+Vector3.UP*.26)
	expect((reticle.get_global_transform_with_canvas()*marker).distance_to(projected)<.01,"countdown remains above animated head under scaled/offset HUD")
	reticle.free()
	p.hp=100.;p.armor=0.;p.protect=0.;p.invulnerable=0.;p.shield=g.clock+6.;g.actors[1].aim_pitch=.8
	g.damage(1,10.,2,false,"pistol");expect(is_equal_approx(p.hp,98.5),"frontal shield covers head-height attacks independently of camera pitch")
	g.actors[2].position.z=25.;g.damage(1,10.,2,false,"pistol");expect(is_equal_approx(p.hp,88.5),"shield preserves rear vulnerability")
	p.shield=0.;g.actors[1].aim_pitch=0.;g.actors[2].position.z=-25.

	for key in ["door","reload","magazine","throw","bounce","deploy","melee_swing"]:expect(GameAudio.audible_range(key)==40.,"non-strategic audio range "+key)
	for key in ["explosion","flash","smoke"]:expect(GameAudio.audible_range(key)==220.,"strategic blast audio range "+key)
	g.options.mode=0;g.ui.practice_menu()
	for mode in range(5):
		g.options.mode=mode;ModeOptions.refresh(g.ui)
		for row in g.ui.mode_fields.get_children():expect(row.visible==(mode in row.get_meta("modes")),"mode-specific settings "+str(mode))
	g.ui.clear_panel();g.options.mode=0;g.phase="combat";p.alive=false
	if not is_instance_valid(g.kill_replay):g.kill_replay=KillReplay.new();g.kill_replay.game=g;g.add_child(g.kill_replay)
	g.kill_replay.active=true
	var gear_key=InputEventAction.new();gear_key.action="gear";gear_key.pressed=true;g._unhandled_input(gear_key)
	expect(g.ui.screen=="gear" and not g.kill_replay.active,"B skips replay and opens loadout in non-purchase modes")
	g.ui.clear_panel();g.ui.screen="hud";g.options.mode=4;g.kill_replay.active=true;g._unhandled_input(gear_key)
	expect(g.ui.screen=="hud" and g.kill_replay.active,"replay B cannot bypass purchase-mode restrictions")
	g.kill_replay.active=false;g.ui.clear_panel();g.free();await process_frame
	print("V123_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
