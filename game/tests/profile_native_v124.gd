extends SceneTree
## Rendered 8-player workload. Run with exported EXE via --script; no settings are saved.
## These timings are measurements of this machine, not an integrated-GPU prediction.
var game:Node
func _initialize():call_deferred("run")
func run():
    game=load("res://scripts/game.gd").new();root.add_child(game)
    game.profile.menu_animation=false;game.profile.display_mode=0;game.profile.width=1280;game.profile.height=720;game.profile.frame_limit=0
    game.profile.merge(GraphicsOptions.PRESETS[0],true);game.apply_display_settings();GraphicsOptions.apply(game)
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    game.options.map=19;game.options.map_random=false;game.options.map_rotation=false;game.options.mode=4;game.options.bots=7;game.options.max_players=8
    var before=Time.get_ticks_usec();game.host_game(OfflineMultiplayerPeer.new());game.start_match();print("PROFILE_LOAD_MS ",(Time.get_ticks_usec()-before)/1000.)
    game.ui.clear_panel();game.remaining=.01
    for i in range(10):await process_frame
    game.players[1].protect=1e10
    var rid=root.get_viewport_rid();RenderingServer.viewport_set_measure_render_time(rid,true)
    var data=[];var stamp=Time.get_ticks_usec();var start=stamp;var next_burst=3.;var next_report=1.
    while Time.get_ticks_usec()-start<60000000:
        await process_frame
        var now=Time.get_ticks_usec();var elapsed=(now-start)/1000000.
        data.append({"second":elapsed,"frame_ms":(now-stamp)/1000.,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.,"render_cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(rid),"render_gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(rid),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"focused":root.has_focus(),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)})
        stamp=now
        if elapsed>next_burst:game.combat_fx.explosion(game.actors[1].position+Vector3(0,1,-4));next_burst+=3.
        if elapsed>next_report:print("PROFILE_TICK ",JSON.stringify(data[-1]));next_report+=10.
    var output="user://native-performance-v124.json"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--profile-output="):output=arg.trim_prefix("--profile-output=")
    var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1280,720],"quality":"low","map":19,"players":8,"frames":data}));f.close()
    print("PROFILE_SAVED ",output)
    game.leave_game();game.queue_free();await process_frame;quit()
