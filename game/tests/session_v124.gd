extends Node
## Runs the same rendered workload in Windows and in an isolated Web export.
var failures=0
var samples=[]
var g:Node
func _ready():call_deferred("run")
func expect(ok:bool,reason:String):
	if not ok:failures+=1;printerr("FAIL ",reason)
func tick_for(seconds:float):
	var end=Time.get_ticks_msec()+int(seconds*1000.)
	var frames=0;var longest=0;var total=0
	while Time.get_ticks_msec()<end:
		var start=Time.get_ticks_usec();await get_tree().process_frame
		var usec=Time.get_ticks_usec()-start;longest=maxi(longest,usec);total+=usec;frames+=1
	return {"frames":frames,"average_ms":total/1000./maxi(1,frames),"max_ms":longest/1000.}
func run():
	g=load("res://scripts/game.gd").new();g.render_actors=true;add_child(g)
	g.profile.menu_animation=false;g.options.map_random=false;g.options.map_rotation=false;g.options.map=19;g.options.mode=4;g.options.bots=7;g.options.max_players=8
	g.host_game(OfflineMultiplayerPeer.new());g.start_match()
	expect(g.players.size()==8,"eight rendered actors")
	var replay_count=0
	var cycles=12
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--soak-cycles="):cycles=clampi(int(arg.trim_prefix("--soak-cycles=")),12,240)
	for cycle in range(cycles):
		if cycle>0:g.phase="round_end";g.begin_round()
		expect(g.ui.screen=="gear" or g.phase=="buy","buy phase transition")
		await tick_for(.6)
		g.ui.clear_panel();g.remaining=.01
		await tick_for(.5)
		for id in g.players:
			var p=g.players[id];p.protect=0.;p.role=absi(id)%6;p.primary="dual_pistols" if id==1 else Catalog.first(int(p.role));p.owned_primary=true;p.slot=0;g.equip_ammo(p)
		g.actors[1].position=Vector3(0,0,0);g.actors[-1].position=Vector3(0,0,-8)
		for burst in range(3):g.combat_fx.explosion(Vector3(burst*2,1,-5))
		var sample=await tick_for(3.)
		g.players[1].protect=0.;g.players[1].invulnerable=0.;g.players[1].hp=1.
		g.damage(1,1000.,-1,false,"a1",g.actors[-1].eye(),g.actors[1].eye())
		await tick_for(.4)
		if is_instance_valid(g.kill_replay) and g.kill_replay.active:replay_count+=1
		await tick_for(5.)
		RoundCleanup.clear(g)
		await tick_for(.15)
		sample.merge({"cycle":cycle,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"video_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),"loft_cache":HumanModel.loft_meshes.size(),"effect_pool":g.combat_fx.explosion_pool.size(),"replays":replay_count})
		samples.append(sample);print("SESSION_SAMPLE ",JSON.stringify(sample))
		if OS.has_feature("web"):JavaScriptBridge.eval("document.body.dataset.probe="+JSON.stringify(JSON.stringify(sample)))
	expect(replay_count>=8,"kill replay exercised repeatedly")
	expect(samples[-1].nodes<samples[3].nodes+400,"round/replay nodes bounded after warm-up")
	expect(samples[-1].resources<samples[3].resources+160,"round/replay resources bounded after warm-up")
	expect(samples[-1].static_bytes<samples[3].static_bytes+32*1024*1024,"round/replay static memory bounded")
	g.leave_game();g.queue_free();await get_tree().process_frame;await tick_for(1.)
	var result="SESSION_RESULT failures=%d replays=%d"%[failures,replay_count];print(result)
	if OS.has_feature("web"):JavaScriptBridge.eval("document.body.dataset.result="+JSON.stringify(result))
	get_tree().quit(1 if failures else 0)
