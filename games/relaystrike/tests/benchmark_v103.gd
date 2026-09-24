extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	g=load("res://scripts/game.gd").new();root.add_child(g);g.ui.clear_panel()
	var results=[]
	for count in [8,32]:
		g.options.map_random=false;g.options.map=13 if count==8 else 0;g.options.max_players=count;g.options.bots=count-1
		g.host_game();g.start_match();g.actors[1].position=g.arena.spawn_points[0][0];g.actors[1].reset_view(PI)
		await create_timer(5.).timeout
		var samples=[];var end=Time.get_ticks_msec()+12000;var previous=Time.get_ticks_usec()
		while Time.get_ticks_msec()<end:
			await process_frame
			var now=Time.get_ticks_usec();samples.append(float(now-previous)/1000.);previous=now
		samples.sort();var total=0.
		for value in samples:total+=value
		var result={"players":count,"map":g.options.map,"frames":samples.size(),"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"max_ms":samples.back(),"renderer":RenderingServer.get_video_adapter_name(),"resolution":DisplayServer.window_get_size()}
		results.append(result);print("BENCHMARK ",JSON.stringify(result))
		g.leave_game();await process_frame;await process_frame
	var file=FileAccess.open("res://../../validation/v103-benchmark.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
	g.queue_free();await process_frame;quit()
