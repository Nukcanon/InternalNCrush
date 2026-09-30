extends SceneTree
# Hosts every map in turn (two bots) and prints node / object / resource /
# static-memory counts after each leave, to see whether switching maps
# accumulates memory. Prints the static caches that grow with maps.
var g:Node
func _initialize():call_deferred("run")
func counts() -> Dictionary:
	return {"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"static_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.,.1),"video_mb":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.,.1),
		"surface_materials":WorldSurface.cache.size(),"skin_materials":DistrictFacade.skin_materials.size(),"grip_cache":HeroIK.grip_cache.size()}
func run():
	g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g)
	for i in range(10):await process_frame
	var passes=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 1
	for rep in range(passes):
		for index in range(31):
			g.options.map_random=false;g.options.map_rotation=false;g.options.map=index;g.options.max_players=3;g.options.bots=2;g.options.mode=4 if DefusalLayout.enabled(index) else 0
			g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
			for i in range(20):await process_frame
			g.leave_game();for i in range(6):await process_frame
			var c=counts();c.map=index;c.pass=rep
			print("MAPMEM ",JSON.stringify(c))
	g.free();await process_frame;quit()
