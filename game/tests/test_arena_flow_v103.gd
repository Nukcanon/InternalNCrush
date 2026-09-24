extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run():
	Catalog.load_all()
	var defaults=Rules.default_options();expect(defaults.max_players==8 and defaults.map_random and defaults.rounds==0,"default eight-player random map with unlimited games")
	for mode in range(5):
		for capacity in range(2,33,2):
			var options=Rules.default_options();options.mode=mode;options.max_players=capacity;Rules.sanitize_room(options)
			expect(options.max_players%2==0 and options.max_players<=Rules.MAP_PLAYERS[options.map] and (mode!=4 or options.max_players<=12),"legal mode/capacity %d/%d"%[mode,capacity])
	for capacity in [6,8,12,16,32]:
		var rectangles=Rules.maps_for_size(capacity).filter(func(index):return index in MapIdentity.RECTANGLES)
		expect(rectangles.size()==2,"exactly two rectangular footprints at "+str(capacity))
	var signatures={}
	for index in range(19,32):
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena)
		expect(arena.spawn_points[0].size()>=6 and arena.spawn_points[1].size()>=6,"new map has valid team starts "+str(index))
		if index<31:
			var s=DefusalLayout.spec(index);signatures[JSON.stringify(s.links)+str(s.points)]=true
			for team in [0,1]:
				for site in arena.sites:
					var route=nav.route(arena.spawn_points[team][0],site)
					expect(route.size()>1 and route[-1].distance_to(site)<2.1,"defusal %d team %d reaches %s"%[index,team,str(site)])
		else:
			expect(arena.get_meta("practice_levels").size()>=4,"outdoor range has four walkable height levels")
			for goal in arena.navigation_goals:
				var route=nav.route(arena.spawn_points[0][0],goal);expect(route.size()>1 and route[-1].distance_to(goal)<2.1,"practice route to "+str(goal))
		arena.free();await process_frame
	expect(signatures.size()==12,"twelve defusal maps have distinct route graphs and positions")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.mode=4;g.options.map=19;g.options.map_size=8;g.options.map_random=true;g.phase="lobby";g.build_world();g.add_player(1,"A","stage_a");g.add_player(2,"B","stage_b");g.players[1].team=0;g.players[2].team=1;g.start_match()
	expect(g.phase=="buy" and g.remaining==45.,"45-second preparation starts")
	var boundary=float(g.arena.get_meta("staging_z"));g.actors[1].position.z=boundary-8.;g.actors[2].position.z=boundary+2.
	MatchFlow.preparation(g,1);MatchFlow.preparation(g,2)
	expect(g.actors[1].position.z>=boundary and not MatchFlow.spawn_rect(g,0).has_point(Vector2(g.actors[2].position.x,g.actors[2].position.z)),"preparation keeps opposing teams in disjoint areas")
	g.players[1].protect=0.;var hp=g.players[1].hp;g.damage(1,500,2);expect(g.players[1].hp==hp,"preparation blocks all incoming damage")
	g.phase="combat";MatchFlow.update_gate(g);expect(g.arena.get_node_or_null("PreparationGate")!=null and g.actors[1].collision_mask&16==0,"round start unlocks friendly passage and retains spawn protection")
	var first=g.options.map;g.begin_round();expect(g.options.map==first and MatchFlow.attackers(g)==1,"second leg swaps attacking team on the same map")
	g.begin_round();expect(g.options.map!=first and Rules.MAP_PLAYERS[g.options.map]==8,"third leg rotates only after both sides played")
	g.leave_game();g.free();await process_frame
	var practice=load("res://scripts/game.gd").new();root.add_child(practice);practice.set_physics_process(false);practice.ui.clear_panel();PracticeSession.start(practice)
	expect(practice.arena.map_index==31 and practice.players.size()==10,"practice creates player and nine passive targets")
	for id in practice.players:
		if id>=0:continue
		PracticeSession.input(practice,id);expect(not practice.actors[id].input_state.fire and not practice.actors[id].input_state.alt,"practice target never attacks "+str(id))
	practice.players[-1].protect=0.;practice.damage(-1,500,1);practice.clock+=4.1;practice.server_tick(.016);expect(practice.players[-1].alive,"destroyed practice target respawns")
	practice.leave_game();practice.free();await process_frame
	print("ARENA_FLOW_V103_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
