extends SceneTree
func _initialize():call_deferred("run")
func run():
	var failed=0;var checks=0
	for index in range(31):
		var a=Arena.new();root.add_child(a);a.build(index);var nav=BotNavigation.new();nav.build(a)
		var goals=a.sites+a.navigation_goals
		for team in range(2):
			for goal in goals:
				checks+=1;var route=nav.route(a.spawn_points[team][0],goal)
				if route.size()<2 or route[-1].distance_to(goal)>3.:
					failed+=1;print("ROUTE_FAIL ",index," team=",team," goal=",goal," count=",route.size())
		print("DISTRICT ",index," points=",nav.layers.get_point_count()," size=",a.bounds*2," spawns=",a.spawn_points[0].size(),"/",a.spawn_points[1].size())
		a.free();await process_frame
	print("DISTRICT_CHECKS ",checks," FAILED ",failed);quit(1 if failed else 0)
