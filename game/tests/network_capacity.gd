extends SceneTree
var g:Node
var control=""
var label=""
var started=0
var checked=false
var finishing=false
var ready=false
var next_report=0
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--control="):control=arg.trim_prefix("--control=")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	started=Time.get_ticks_msec();g=load("res://scripts/game.gd").new();g.name="Capacity";root.add_child(g)
	if label=="server":
		g.dedicated=true;g.options.map_random=false;g.options.map=0;g.options.max_players=32;g.host_game();FileAccess.open(control.path_join("server.ready"),FileAccess.WRITE).store_string("ready")
	else:
		g.profile.nick="CAPACITY_"+label;g.profile.token="capacity_unique_identity_"+label;g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func drive():
	if finishing:return
	# A release file is written only after every peer and the server pass the barrier.\n\t# Check it before disconnect detection: the server may already be shutting down.\n\tif FileAccess.file_exists(control.path_join("release")):finish(true);return\n\tvar now=Time.get_ticks_msec()
	if now>next_report:
		next_report=now+15000;print("CAPACITY_PROGRESS ",label," phase=",g.phase," peers=",g.players.size()," busy=",g.connection_busy," seq=",g.received_sequence)
	if label!="server" and not ready and g.phase=="lobby" and g.received_sequence>=0:
		ready=true;FileAccess.open(control.path_join("client"+label+".ready"),FileAccess.WRITE).store_string("joined")
	if label!="server" and ready and g.phase=="menu" and not g.connection_busy:
		var reason=g.ui.notice_label.text if is_instance_valid(g.ui.notice_label) else "no notice"
		printerr("CAPACITY_DISCONNECTED ",label," reason=",reason);finish(false);return
	if Time.get_ticks_msec()-started>180000:finish(false);return
	if label=="server":
		var all_clients=true
		for i in range(32):
			if not FileAccess.file_exists(control.path_join("client%d.ok"%i)):all_clients=false
		if all_clients and not checked:
			if g.players.size()!=32:finish(false);return
			checked=true;print("CAPACITY_SERVER_OK peers=32 barrier=true")
			FileAccess.open(control.path_join("server.ok"),FileAccess.WRITE).store_string("32")
	elif not checked and g.players.size()==32 and g.received_sequence>=10 and Time.get_ticks_msec()-g.last_snapshot_ms<3000:
		checked=true;print("CAPACITY_CLIENT_OK ",label," peers=32 gap_ms=",Time.get_ticks_msec()-g.last_snapshot_ms," seq=",g.received_sequence)
		FileAccess.open(control.path_join("client"+label+".ok"),FileAccess.WRITE).store_string("32")
func finish(ok:bool):
	finishing=true
	if not ok:printerr("CAPACITY_TIMEOUT_OR_LOST_PEER ",label," peers=",g.players.size())
	g.set_physics_process(false);g.leave_game();g.queue_free();await process_frame;await process_frame;quit(0 if ok else 1)
