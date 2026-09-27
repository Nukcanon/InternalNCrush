extends SceneTree
func _initialize():
	var game=load("res://scripts/game.gd").new()
	game.clock=100.
	game.drops=[{"until":100.+game.DROP_LIFETIME,"amount":0,"weapon":"a1"}]
	game.clock=141.;game.update_pickups()
	assert(game.drops.size()==1,"An empty dropped gun must survive the former 40s timeout")
	game.clock=279.9;game.update_pickups();assert(game.drops.size()==1)
	game.clock=280.;game.update_pickups();assert(game.drops.is_empty())
	for i in range(150):game.drops.append({"until":500.+i,"amount":i,"weapon":"a1"})
	game.update_pickups();assert(game.drops.size()==96 and game.drops[0].amount==54,"Bound retention by removing oldest drops")
	game.free();print("DROPS_V127_PASS");quit()
