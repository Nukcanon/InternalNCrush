extends SceneTree
# Rendered 8-player measurement. "server" hosts seven combat bots headless; the
# rendered client joins, plays for a fixed window and logs frame spikes with
# the physics steps, snapshots and effects observed in the same frame.
var g:Node
var control=""
var label=""
var started=0
var last=0
var samples=[]
var measuring_from=0
var done=false
var started_match=false
var physics_steps=0
var last_sequence=-1
var totals={}
var seconds=float(OS.get_environment("HITCH_SECONDS")) if not OS.get_environment("HITCH_SECONDS").is_empty() else 25.
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--control="):control=arg.trim_prefix("--control=")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	started=Time.get_ticks_msec();g=load("res://scripts/game.gd").new();g.name="Hitch";root.add_child(g)
	if label=="server":
		g.dedicated=true;g.options.map_random=false;g.options.map=int(OS.get_environment("HITCH_MAP")) if not OS.get_environment("HITCH_MAP").is_empty() else 13;g.options.max_players=8;g.options.bots=7;g.options.join=2;g.host_game()
		FileAccess.open(control.path_join("server.ready"),FileAccess.WRITE).store_string("ready")
	else:
		g.profile.nick="VIEW";g.profile.token="render_hitch_identity_000";g.join_game("127.0.0.1")
	physics_frame.connect(func():physics_steps+=1)
	process_frame.connect(drive)
func drive():
	if done:return
	var now=Time.get_ticks_usec()
	if label=="server":
		if not started_match and g.players.size()>=8:started_match=true;g.start_match()
		if FileAccess.file_exists(control.path_join("client.done")) or Time.get_ticks_msec()-started>150000:done=true;g.leave_game();quit(0)
		return
	if g.phase=="combat" and measuring_from==0:
		measuring_from=now+5000000
	if g.players.has(g.local_id) and g.actors.has(g.local_id):
		# Keep the local player moving and firing so effects and audio are exercised.
		var a=g.actors[g.local_id];a.input_state.x=sin(now/700000.);a.input_state.fire=int(now/900000)%2==0
	if measuring_from>0 and now>measuring_from:
		var frame_ms=(now-last)/1000.
		samples.append({"ms":frame_ms,"steps":physics_steps,"snap":g.received_sequence!=last_sequence,"proc":Performance.get_monitor(Performance.TIME_PROCESS)*1000.,"phys":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"t":(now-measuring_from)/1000000.,"prof":g.prof.duplicate()})
		for key in g.prof:totals[key]=int(totals.get(key,0))+int(g.prof[key])
		if now>measuring_from+int(seconds*1000000):report()
	g.prof.clear()
	last=now;physics_steps=0;last_sequence=g.received_sequence
	if Time.get_ticks_msec()-started>140000:print("HITCH_TIMEOUT");done=true;quit(1)
func report():
	done=true
	var ms=samples.map(func(s):return s.ms);ms.sort()
	var phys=samples.map(func(s):return s.phys);phys.sort()
	var multi=samples.filter(func(s):return s.steps>=2)
	var avg_multi=0.;var avg_single=0.;var singles=samples.filter(func(s):return s.steps==1)
	for s in multi:avg_multi+=s.phys
	for s in singles:avg_single+=s.phys
	print("HITCH_RENDER frames=",samples.size()," p50=%.2f p95=%.2f p99=%.2f max=%.2f"%[ms[ms.size()/2],ms[int(ms.size()*.95)],ms[int(ms.size()*.99)],ms[-1]])
	print("HITCH_PHYSICS p50=%.2f p99=%.2f max=%.2f single_avg=%.2f multi_avg=%.2f multi_frames=%d"%[phys[phys.size()/2],phys[int(phys.size()*.99)],phys[-1],avg_single/maxf(1,singles.size()),avg_multi/maxf(1,multi.size()),multi.size()])
	var spikes=samples.filter(func(s):return s.ms>ms[ms.size()/2]*1.6)
	for s in spikes.slice(0,25):print("HITCH_SPIKE t=%.2f ms=%.2f steps=%d snap=%s proc=%.2f phys=%.2f nodes=%d prof=%s"%[s.t,s.ms,s.steps,s.snap,s.proc,s.phys,s.nodes,str(s.prof)])
	var averages={}
	for key in totals:averages[key]="%.3f"%(totals[key]/1000./samples.size())
	print("HITCH_AVG_MS_PER_FRAME ",averages)
	for key in totals:
		var values=samples.map(func(s):return int(s.prof.get(key,0))/1000.);values.sort()
		var hits=values.filter(func(v):return v>0.)
		var over=values.filter(func(v):return v>4.)
		print("HITCH_SECTION %s p50=%.3f p99=%.3f max=%.3f frames=%d over4ms=%d total_ms=%.1f"%[key,values[values.size()/2],values[int(values.size()*.99)],values[-1],hits.size(),over.size(),totals[key]/1000.])
	print("HITCH_SPIKES total=",spikes.size())
	FileAccess.open(control.path_join("client.done"),FileAccess.WRITE).store_string("done")
	g.leave_game();await process_frame;quit(0)
