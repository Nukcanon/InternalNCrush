extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func run():
	Engine.time_scale=4.
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.dedicated=true;g.server=true;g.phase="lobby"
	for index in [7,14,16,17]:
		g.options.map=index;g.build_world()
		if not g.players.has(-1):g.add_player(-1,"STAIRS","stairs")
		g.players[-1].role=0;g.players[-1].primary="a1";g.players[-1].protect=0
		var a=g.actors[-1];var bot=BotAgent.new();bot.setup(g,-1)
		g.phase="combat";a.position=g.arena.spawn_points[0][3];a.velocity=Vector3.ZERO;a.reset_view(0)
		await physics_frame;await physics_frame
		var goals=[g.arena.sites[0],Vector3(0,-3.2,0)]
		if index==16:goals.insert(1,g.arena.navigation_goals[0])
		for goal in goals:
			bot.path.clear();bot.next_path=0.;bot.goal=goal
			var started=a.position
			for step in range(2400):
				g.clock+=1./60.;a.input_state.x=0.;a.input_state.z=0.;a.input_state.sprint=false
				bot.navigate(goal,1./60.);a.simulate(1./60.,g.clock,true)
				if a.position.distance_to(goal)<2.1:break
				await physics_frame
			checks+=1
			if a.position.distance_to(goal)>2.1:failures+=1;printerr("FAIL_TRAVERSE map=",index," from=",started," goal=",goal," actual=",a.position," waypoint=",bot.waypoint," path=",bot.path)
			else:print("PASS_TRAVERSE map=",index," goal=",goal," actual=",a.position)
	g.leave_game();g.free();await process_frame;print("TRAVERSAL_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
