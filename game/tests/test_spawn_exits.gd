extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func run():
	Engine.time_scale=4.
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.dedicated=true;g.options.mode=4;g.options.map_random=false;g.phase="lobby"
	for index in range(19,31):
		g.options.map=index;g.build_world()
		if not g.players.has(-1):g.add_player(-1,"EXIT TEST","exit")
		var a=g.actors[-1];var p=g.players[-1];var spec=DefusalLayout.spec(index)
		for round_number in [1,2]:
			g.round_no=round_number
			for side in [0,1]:
				p.team=MatchFlow.attackers(g) if side==0 else 1-MatchFlow.attackers(g);p.alive=true
				g.phase="buy";g.spawn(-1);MatchFlow.update_gate(g)
				await physics_frame;await physics_frame
				if side==0:g.phase="combat";MatchFlow.update_gate(g)
				var target_index=-1
				for link in spec.links:
					if side in link:target_index=link[1] if link[0]==side else link[0];break
				var target=Vector3(spec.points[target_index].x,0,spec.points[target_index].y)
				var bot=BotAgent.new();bot.setup(g,-1);var rect=MatchFlow.spawn_rect(g,p.team).grow(2.)
				for step in range(600):
					var dt=Engine.time_scale/Engine.physics_ticks_per_second;g.clock+=dt
					a.input_state.x=0.;a.input_state.z=0.;a.input_state.sprint=false
					bot.navigate(target,dt);a.simulate(dt,g.clock,true);MatchFlow.preparation(g,-1)
					if not rect.has_point(Vector2(a.position.x,a.position.z)):break
					await physics_frame
				checks+=1
				var escaped=not rect.has_point(Vector2(a.position.x,a.position.z))
				if not escaped:failures+=1
				print("PASS" if escaped else "FAIL"," EXIT map=",index," round=",round_number," side=",side," actual=",a.position," goal=",target)
	g.leave_game();g.free();await process_frame
	print("SPAWN_EXITS_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
