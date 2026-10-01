extends SceneTree
# Debug: which navigation cells the spawn screens block on a map (arg: map).
func _initialize():call_deferred("run")
func run():
	var index=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 15
	var arena=Arena.new();root.add_child(arena);arena.build(index)
	var nav=BotNavigation.new();nav.build(arena)
	print("blocks ",arena.navigation_blocks.size()," obstacles ",arena.obstacles.size()," vertical ",arena.vertical_map," bounds ",arena.bounds," offset ",nav.grid.offset)
	var plan=DistrictLayout.read_plan(index)
	for team in range(2):
		var here=Vector2(plan.spawns[team][0],plan.spawns[team][1]);var there=Vector2(plan.spawns[1-team][0],plan.spawns[1-team][1]);var dir=(there-here).normalized()
		for k in range(9):
			var at=here+dir*(DistrictLayout.SCREEN_DISTANCE+k*2.-6.)
			var row=""
			for s in range(-7,8):
				var p=Vector3(at.x+s*2.,0,at.y)
				var id=nav.cell(p)
				row+=("#" if nav.grid.is_point_solid(id) else ".")
			print("team ",team," z=",at.y," cells x -14..14: ",row)
	var start=arena.spawn_points[0][0];print("start ",start," solid ",nav.grid.is_point_solid(nav.cell(start))," lanes ",arena.get_meta("screen_lanes",[]))
	for pt in [Vector3(-2.3,0,24),Vector3(-2.3,0,22),Vector3(2.3,0,29),Vector3(-2.3,0,26)]:print("clear ",pt," ",arena.navigation_clear(pt)," heights ",arena.navigation_heights(pt))
	print("connect (-2.3,26)->(-2.3,24) ",nav.connects_surface(Vector3(-2.3,0,26),Vector3(-2.3,0,24))," (-2.3,24)->(-2.3,22) ",nav.connects_surface(Vector3(-2.3,0,24),Vector3(-2.3,0,22)))
	for goal in [Vector3(0,0,32),Vector3(2,0,29),Vector3(2,0,27),Vector3(-2,0,23),Vector3(0,0,20),Vector3(0,0,10),Vector3(0,0,0)]:
		var path=nav.route(start,goal);print("route to ",goal," points ",path.size()," end ",path[-1] if path.size()>0 else null)
	quit()
