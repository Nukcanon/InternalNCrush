extends SceneTree
var g:Node
var server_mode=false
var elapsed=0.
var fired=false
var seen_frames=0
var barrier=""
var label=""
var done=false
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--barrier="):barrier=arg.trim_prefix("--barrier=")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	server_mode=label=="server"
	g=load("res://scripts/game.gd").new();g.name="PropsProbe";root.add_child(g);g.input_timer=1e6
	if server_mode:g.dedicated=true;g.options.map_random=false;g.options.map=7;g.host_game();g.start_match()
	else:g.profile.nick=label;g.profile.token="prop_probe_identity_"+label;g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func drive():
	if done:return
	elapsed+=1./Engine.physics_ticks_per_second
	if elapsed>35.:complete(false);return
	if FileAccess.file_exists(barrier.path_join("release")):complete(true);return
	if g.arena==null or not g.arena.props.has(0):return
	var prop=g.arena.props[0]
	if server_mode:
		if elapsed>5. and not fired and g.multiplayer.get_peers().size()>0:
			fired=true
			g.arena.doors.values()[0].opened=true
			prop.hit(prop.global_position+Vector3(.2,.25,.2),Vector3(.6,.15,-1),40.)
		if fired and elapsed>9.:
			if not FileAccess.file_exists(barrier.path_join("pose.ready")):
				var file=FileAccess.open(barrier.path_join("server_pose"),FileAccess.WRITE);file.store_var(prop.global_position);file.close()
				FileAccess.open(barrier.path_join("pose.ready"),FileAccess.WRITE).store_string("ready")
			if FileAccess.file_exists(barrier.path_join("early.ok")) and FileAccess.file_exists(barrier.path_join("late.ok")):FileAccess.open(barrier.path_join("server.ok"),FileAccess.WRITE).store_string("complete")
	elif g.players.has(g.local_id) and FileAccess.file_exists(barrier.path_join("pose.ready")):
		var file=FileAccess.open(barrier.path_join("server_pose"),FileAccess.READ);var expected=file.get_var();file.close()
		var difference=prop.global_position.distance_to(expected)
		if g.arena.doors.values()[0].opened and g.arena.doors.values()[0].progress>.95 and prop.freeze and prop.received and prop.global_position.distance_to(prop.home.origin)>.12 and difference<.18:
			seen_frames+=1
			if seen_frames==20:
				print("PROP_SYNC_OK DOOR_SYNC_OK ",label," error=",difference," displacement=",prop.global_position.distance_to(prop.home.origin)," peers=",g.players.size())
				FileAccess.open(barrier.path_join(label+".ok"),FileAccess.WRITE).store_string("synced")
func complete(ok:bool):
	done=true;g.set_physics_process(false);g.leave_game();g.queue_free()
	await process_frame;await process_frame
	if not ok:printerr("PROP_SYNC_TIMEOUT ",label)
	quit(0 if ok else 1)
