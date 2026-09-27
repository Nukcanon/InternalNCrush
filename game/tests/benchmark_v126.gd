extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.profile.merge(GraphicsOptions.PRESETS[1],true);g.profile.display_mode=0;g.profile.width=1280;g.profile.height=720;g.profile.frame_limit=0;g.profile.graphics_quality=1;g.profile.menu_animation=false;g.apply_display_settings();GraphicsOptions.apply(g)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	for count in [8,32]:
		g.options.map_random=false;g.options.map=17 if count==8 else 0;g.options.max_players=count;g.options.bots=count-1;g.options.mode=0
		g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
		await create_timer(5.).timeout
		var samples=[];var end=Time.get_ticks_msec()+15000;var previous=Time.get_ticks_usec()
		while Time.get_ticks_msec()<end:
			await process_frame
			var now=Time.get_ticks_usec();samples.append(float(now-previous)/1000.);previous=now
		samples.sort();var total=0.
		for value in samples:total+=value
		print("BENCHMARK_V126 ",JSON.stringify({"players":count,"map":g.options.map,"frames":samples.size(),"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"p99_ms":samples[int(samples.size()*.99)],"max_ms":samples.back(),"renderer":RenderingServer.get_video_adapter_name(),"resolution":DisplayServer.window_get_size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.}))
		g.leave_game();await process_frame;await process_frame
	g.free();await process_frame;quit()
