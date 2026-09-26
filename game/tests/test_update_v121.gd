extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	expect(Rules.CLASS_HP==[100.,100.,150.,100.,130.,100.],"class health")
	expect(MedicLink.RATE==20. and Catalog.get_weapon("m1").heal_rate==20.,"LINK rate matches catalog")
	expect(Catalog.get_weapon("m2").damage==22 and is_equal_approx(60./Catalog.get_weapon("m2").interval,250.),"PIPER balance")
	expect(Catalog.get_weapon("m3").damage==16 and Catalog.get_weapon("m3").pellets==8 and is_equal_approx(60./Catalog.get_weapon("m3").interval,50.),"MENDER balance")
	var touch=TouchControls.new();root.add_child(touch)
	for role in range(6):
		for primary in ["m1","m2","m3","a1"]:
			touch.layout_actions({"role":role,"primary":primary})
			expect(touch.buttons.has("medical")==bool(role==5 and primary in ["m2","m3"]),"medical action visibility")
			expect(touch.buttons.has("skill") and touch.buttons.skill.position.x>touch.buttons.use.position.x,"skill always present at row right")
			var first:Rect2=touch.buttons.gadget;var last:Rect2=touch.buttons.skill
			expect(is_equal_approx((first.position.x+last.end.x)*.5,640.),"dynamic row centered")
	expect(touch.buttons.melee.size==touch.buttons.ads.size,"melee has full-sized action target")
	expect(touch.buttons.gear.end.x<touch.buttons.score.position.x and touch.buttons.gear.position.y==touch.buttons.score.position.y,"gear beside score")
	touch.free()
	var graph=StatGraph.new();root.add_child(graph);graph.configure(0,Catalog.get_weapon("h1"),2,0)
	expect(graph.rows[0][0]=="최대 체력" and graph.rows[0][1]==150.,"character health graph")
	graph.configure(3,Catalog.get_weapon("h1"),2,2);expect(graph.rows.size()==1 and graph.rows[0][0]=="추가 방어구","armor does not claim health");graph.free()
	for radius in [.020,.025,.044]:
		var grip=HeldGrip.new();root.add_child(grip);grip.build(0,radius)
		for points in grip.finger_paths:
			var length=0.
			for i in range(points.size()):
				expect(Vector2(points[i].x,points[i].z).length()>=radius+.011,"fingers outside object")
				if i>0:length+=points[i].distance_to(points[i-1])
			expect(length<=.087,"anatomical finger length")
		expect(grip.wrist.z>.09,"wrist follows palm instead of exiting hand back");grip.free()
	var melee=MeleeVisual.new();root.add_child(melee);melee.build(false,0,true);melee.pose(MeleeCombat.CONTACT_START);var high=melee.pivot.position;melee.pose(MeleeCombat.CONTACT_END);var low=melee.pivot.position
	expect(high.x>low.x and high.y>low.y,"cut travels upper-right to lower-left")
	melee.pose(MeleeCombat.DURATION);expect(melee.pivot.position.is_equal_approx(Vector3(.16,-.08,-.08)),"single swing returns to ready");melee.free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.add_player(1,"Medic","m");g.add_player(2,"Heavy","h");g.phase="combat";g.clock=100.
	var p=g.players[1];var q=g.players[2];p.team=0;q.team=0;p.role=5;q.role=2;p.protect=0.;q.protect=0.;q.hp=140.;q.last_hit=-100.
	g.heal_target(1,2,30.,true,false);expect(q.hp==150.,"heavy healing capped at 150, not 100")
	q.role=4;q.hp=125.;g.heal_target(1,2,20.,true,false);expect(q.hp==130.,"control healing capped at 130")
	g.phase="buy";p.role=0;p.hp=100.
	g.commit_loadout(1,{"role":2,"primary":"h1"});expect(p.hp==150.,"buy-phase class switch grants correct full heavy health")
	g.commit_loadout(1,{"role":4,"primary":"c1"});expect(p.hp==130.,"switching to control does not retain heavy health")
	p.hp=65.;g.commit_loadout(1,{"role":0,"primary":"a1"});expect(p.hp==50.,"loadout change preserves damage fraction without exceeding new class cap")
	g.phase="combat";p.role=0;p.slot=0;p.reload=0.;p.placing="";p.invul_select=0.;p.cooking=0;p.melee_ready=0.;p.melee_started=-100.
	var a=g.actors[1];a.input_state.melee=true;g.process_trigger(1);var started=p.melee_started
	g.clock+=.79;g.process_trigger(1);expect(p.melee_started==started,"hold cannot bypass 0.8 second interval")
	g.clock+=.02;g.process_trigger(1);expect(p.melee_started==g.clock,"held quick melee repeats automatically")
	a.input_state.melee=false;g.clock+=.6;g.process_trigger(1);expect(p.melee_started<g.clock,"release stops repeated quick melee")
	var invalid={"x":0.,"z":0.,"yaw":0.,"pitch":0.,"melee":"true"};expect(InputGuard.normalize(invalid).is_empty(),"network validates held melee type")
	g.free();await process_frame
	print("V121_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
