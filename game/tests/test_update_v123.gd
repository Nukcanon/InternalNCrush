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
	expect(not g.change_team(1,2,0),"host cannot move other human")
	expect(not g.change_team(2,2,0),"self cannot unbalance teams")
	g.add_player(3,"Three","three");TeamBalance.reconcile(g);expect(g.players.size()==4 and TeamBalance.auto_ids(g).size()==1,"odd players get one hard bot")
	var auto_id=TeamBalance.auto_ids(g)[0];expect(g.bot_agents[auto_id].difficulty==2,"automatic bot hard difficulty")
	TeamBalance.remove_auto(g,auto_id);g.players.erase(3);g.actors[3].free();g.actors.erase(3)
	g.options.mode=4;g.options.map=13;g.options.map_rotation=false;g.clock=100.;g.start_match()
	var p=g.players[1];var q=g.players[2]
	expect(p.primary=="" and p.slot==1 and p.secondary=="pistol" and p.gadget==-1,"pistol only defusal start")
	expect(not GadgetLoadout.has_item(p) and not GadgetLoadout.selectable(p),"unbought gadget absent")
	expect(MatchFlow.attackers(g)==0,"first half attackers")
	g.round_no=2;expect(MatchFlow.attackers(g)==0,"same side through half");g.round_no=3;expect(MatchFlow.attackers(g)==1,"halftime swaps sides");g.round_no=5;g.overtime_attacker=0;expect(MatchFlow.attackers(g)==0,"overtime assigned side")
	g.round_no=1;p.cash=4000
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
	g.ui.clear_panel();g.free();await process_frame
	print("V123_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
