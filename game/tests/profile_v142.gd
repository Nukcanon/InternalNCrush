extends SceneTree
# 1.4.2 performance profile: rendered bot matches on 1.5 maps per graphics
# preset. Prints frame-time percentiles, the game's own section timers
# (run with INC_PROFILE=1), draw calls and node / orphan / memory counts, then
# re-hosts on the first map to check that nothing accumulates across matches.
# Args: optional "quick" (one short config).
var g:Node
func _initialize():call_deferred("run")
func counts() -> Dictionary:
	return {"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"static_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.,.1),"video_mb":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.,.1)}
func measure(seconds:float) -> Dictionary:
	g.prof.clear();Prof.data.clear()
	var samples=[];var end=Time.get_ticks_msec()+int(seconds*1000.);var previous=Time.get_ticks_usec();var draws=0.;var prims=0.
	while Time.get_ticks_msec()<end:
		await process_frame
		var now=Time.get_ticks_usec();samples.append(float(now-previous)/1000.);previous=now
		draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);prims+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var n=samples.size();var sorted=samples.duplicate();sorted.sort();var total=0.
	for v in samples:total+=v
	var sections={}
	for k in g.prof:sections[k]=snappedf(float(g.prof[k])/1000./n,.01)
	for k in Prof.data:sections[k]=snappedf(float(Prof.data[k])/1000./n,.01)
	return {"frames":n,"mean_ms":snappedf(total/n,.01),"p95_ms":snappedf(sorted[int(n*.95)],.01),"p99_ms":snappedf(sorted[int(n*.99)],.01),"max_ms":snappedf(sorted[-1],.01),
		"draw_calls":int(draws/n),"primitives":int(prims/n),"sections_ms_per_frame":sections}
func run():
	var quick="quick" in OS.get_cmdline_user_args()
	g=load("res://scripts/game.gd").new();g.render_actors=true;root.add_child(g)
	for i in range(10):await process_frame
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var configs=[[17,8,1]] if quick else [[17,8,0],[17,8,1],[17,8,2],[0,16,1],[0,32,1],[27,10,1]]
	var baseline={}
	for c in configs:
		g.profile.merge(GraphicsOptions.PRESETS[c[2]],true);g.profile.graphics_auto=false;g.profile.display_mode=0;g.profile.width=1280;g.profile.height=720;g.profile.frame_limit=0;g.profile.menu_animation=false
		g.apply_display_settings();GraphicsOptions.apply(g);Engine.max_fps=0
		g.options.map_random=false;g.options.map_rotation=false;g.options.map=c[0];g.options.max_players=c[1];g.options.bots=c[1]-1;g.options.mode=4 if DefusalLayout.enabled(c[0]) else 0
		var t0=Time.get_ticks_msec()
		g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
		var load_ms=Time.get_ticks_msec()-t0
		await create_timer(4.).timeout
		var m=await measure(4. if quick else 12.)
		m.merge({"map":c[0],"players":c[1],"preset":c[2],"host_ms":load_ms},true);m.merge(counts(),true)
		print("PROFILE_V142 ",JSON.stringify(m))
		g.leave_game();for i in range(6):await process_frame
		var after=counts()
		if baseline.is_empty():baseline=after
		print("AFTER_LEAVE ",JSON.stringify(after))
	# Accumulation check: host / leave the same match again several times.
	var rounds=[]
	for k in range(2 if quick else 4):
		g.options.map=17;g.options.max_players=8;g.options.bots=7;g.options.mode=0
		g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
		await create_timer(2.).timeout
		g.leave_game();for i in range(6):await process_frame
		rounds.append(counts())
	print("REHOST ",JSON.stringify(rounds))
	g.free();await process_frame;quit()
