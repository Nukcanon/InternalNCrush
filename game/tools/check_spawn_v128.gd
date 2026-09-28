extends SceneTree
func _initialize():call_deferred("run")
func run():
	var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(18)
	for team in [0,1]:
		print("SPAWN ",team," raw=",arena.spawn_points[team].size()," candidates=",arena.spawn_candidates(team,false).size())
		for p in arena.spawn_points[team]:
			if not arena.point_clear(p):print("BLOCKED ",p)
	arena.free();quit()
