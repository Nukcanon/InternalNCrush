extends SceneTree
# Measures periodic frame spikes for an 8-player LAN match: one host and seven
# clients in separate processes. Reports server snapshot costs and client
# physics-frame gaps so network work can be separated from rendering.
var g:Node
var control=""
var label=""
var started=0
var last_frame=0
var gaps=[]
var receive_costs=[]
var measuring_from=0
var done=false
var started_match=false
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--control="):control=arg.trim_prefix("--control=")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	started=Time.get_ticks_msec();g=load("res://scripts/game.gd").new();g.name="Hitch";root.add_child(g)
	if label=="server":
		g.profile.nick="HOST";g.options.map_random=false;g.options.map=int(OS.get_environment("HITCH_MAP")) if not OS.get_environment("HITCH_MAP").is_empty() else 13;g.options.max_players=8;g.host_game()
		FileAccess.open(control.path_join("server.ready"),FileAccess.WRITE).store_string("ready")
	else:
		g.profile.nick="C"+label;g.profile.token="hitch_probe_identity_"+label;g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func drive():
	if done:return
	var now=Time.get_ticks_usec()
	if measuring_from>0 and now>measuring_from and last_frame>0:gaps.append((now-last_frame)/1000.)
	last_frame=now
	if label=="server":
		if not started_match and g.players.size()>=8:
			started_match=true;g.start_match();measuring_from=now+4000000
			print("HITCH_SERVER_MATCH players=",g.players.size()," props=",g.arena.props.size()," doors=",g.arena.doors.size())
		if started_match and now>measuring_from+20000000:report()
	else:
		if g.phase in ["combat","buy"] and measuring_from==0:measuring_from=now+4000000
		if measuring_from>0 and now>measuring_from+20000000:report()
	if Time.get_ticks_msec()-started>120000:print("HITCH_TIMEOUT ",label);done=true;quit(1)
func report():
	done=true
	var sorted=gaps.duplicate();sorted.sort()
	var over=gaps.filter(func(v):return v>40.).size()
	print("HITCH_RESULT ",label," frames=",gaps.size()," p50=%.2f p99=%.2f max=%.2f over40=%d"%[sorted[sorted.size()/2],sorted[int(sorted.size()*.99)],sorted[-1],over])
	if label=="server":
		# Direct cost of one normal snapshot and one forced full-state broadcast.
		var costs={}
		for kind in [false,true]:
			var t=Time.get_ticks_usec()
			for i in range(20):g.broadcast_state(kind)
			costs[kind]=(Time.get_ticks_usec()-t)/20000.
		var list=[]
		for id in g.players:list.append(g.players[id].duplicate())
		var state={"players":list,"props":g.arena.prop_states(),"doors":g.arena.door_states(),"devices":g.devices}
		var raw=var_to_bytes(state)
		print("HITCH_SERVER_COST snapshot_ms=%.3f full_ms=%.3f raw_bytes=%d players_bytes=%d props_bytes=%d doors_bytes=%d"%[costs[false],costs[true],raw.size(),var_to_bytes(list).size(),var_to_bytes(state.props).size(),var_to_bytes(state.doors).size()])
	FileAccess.open(control.path_join(label+".done"),FileAccess.WRITE).store_string("done")
	g.set_physics_process(false);g.leave_game();g.queue_free();await process_frame;quit(0)
