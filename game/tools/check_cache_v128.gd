extends SceneTree
func _initialize():
	var states={};var failed=false
	for index in range(32):
		var scene=load("res://assets/arenas/complete/map_%02d.scn"%index).instantiate()
		var revision=int(scene.get_meta("revision",0));var state=scene.get_meta("state")
		if revision!=ArenaCache.REVISION:failed=true;printerr("STALE_CACHE ",index," ",revision)
		states[str(index)]={"revision":revision,"props":state.props,"spawns":state.spawn_points,"zones":state.zones,"surfaces":state.district_surfaces,"doors":state.doors,"metadata":state.metadata}
		scene.free()
	var output="res://../validation/v128-cache-state.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(states))
	print("CACHE_V128 ","FAIL" if failed else "PASS");quit(1 if failed else 0)
