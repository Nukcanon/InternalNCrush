extends SceneTree
var g:Node
var started=0
var saw_dead=false
var saw_feed=false
var saw_damage=false
var queued=false
var ticks=0
var done=false
var server_mode=false
var killed={}
func _initialize():call_deferred("run")
func run():
	g=load("res://scripts/game.gd").new();g.name="NetworkProbe";root.add_child(g)
	g.input_timer=1e6;server_mode="--probe-server" in OS.get_cmdline_user_args();started=Time.get_ticks_msec()
	if server_mode:g.dedicated=true;g.host_game();g.start_match()
	else:
		g.profile.nick="PROBE";g.profile.token="probe_client_1234567890";g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func drive():
	if done:return
	if Time.get_ticks_msec()-started>18000:
		done=true;print("PROBE_SERVER_COMPLETE" if server_mode else "PROBE_TIMEOUT");quit(0 if server_mode else 1);return
	if server_mode:
		for id in g.players:
			var p=g.players[id]
			if p.alive and not p.get("pending_loadout",{}).is_empty() and not killed.has(id):
				p.protect=0.;g.damage(id,1000,0);killed[id]=true;print("PROBE_SERVER_ELIMINATION")
		return
	if not g.players.has(g.local_id):return
	for event in g.kill_events:
		if int(event.victim)==g.local_id and event.weapon=="world" and str(event.victim_name).begins_with("PROBE #"):saw_feed=true
	var p=g.players[g.local_id];var a=g.actors[g.local_id]
	if not g.ui.damage_indicator.hits.is_empty():saw_damage=true
	if not queued and p.alive:
		g.command("loadout",{"role":3,"primary":"e1","armor":2,"gadget":1,"repair":true});queued=true
	if queued and not p.alive:
		saw_dead=true
		var motion=InputEventMouseMotion.new();motion.relative=Vector2(20,2);Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;g._unhandled_input(motion)
	if saw_dead and p.alive and g.clock>=p.protect:
		ticks+=1
		a.input_state.yaw=.5;a.input_state.pitch=0.;a.input_state.fire=true;a.input_state.trigger_seq=1;a.input_state.x=.3
		if ticks%2==0:g.send_input.rpc_id(1,a.input_state)
		if p.primary=="e1" and p.mag.e1<6:
			var offset=a.camera.global_position-a.eye()
			var horizontal=Vector2(offset.x,offset.z).length()
			# Landing compression intentionally offsets the camera vertically by up to 5.5 cm.
			# The original regression detached the camera horizontally and moved the observed actor.
			print("PROBE_RESPAWN_SHOT primary=",p.primary," mag=",p.mag.e1," camera_xz=",horizontal," camera_y=",offset.y," repair=",p.secondary)
			print("PROBE_KILL_FEED ",saw_feed)
			print("PROBE_DAMAGE_FEEDBACK ",saw_damage)
			done=true;finish_probe(0 if horizontal<.001 and absf(offset.y)<.07 and not a.camera.top_level and p.secondary=="repair" and saw_feed and saw_damage else 1)

func finish_probe(code:int):
	g.set_physics_process(false)
	await create_timer(.8).timeout
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit(code)
