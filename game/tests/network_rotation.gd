extends SceneTree
var g:Node
var elapsed=0.
var stage=0
var barrier=""
var label=""
var done=false
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--barrier="):barrier=arg.trim_prefix("--barrier=")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=")
	g=load("res://scripts/game.gd").new();g.name="RotationProbe";root.add_child(g);g.input_timer=1e6
	if label=="server":
		g.dedicated=true;g.options.mode=4;g.options.map=19;g.options.map_random=false;g.options.map_rotation=true;g.options.max_players=8;g.host_game();g.start_match()
	else:g.profile.nick=label;g.profile.token="rotation_probe_"+label;g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func mark(name:String):FileAccess.open(barrier.path_join(name),FileAccess.WRITE).store_string("ready")
func drive():
	if done:return
	elapsed+=1./Engine.physics_ticks_per_second
	if elapsed>50.:complete(false);return
	if FileAccess.file_exists(barrier.path_join("release")):complete(true);return
	if g.arena==null:return
	if label=="server":
		if stage==0 and FileAccess.file_exists(barrier.path_join("early.initial")):
			g.begin_round();g.begin_round();g.broadcast_state(true);stage=1
			var file=FileAccess.open(barrier.path_join("expected"),FileAccess.WRITE);file.store_string(str(g.options.map));file.close();mark("rotated")
		if stage==1 and FileAccess.file_exists(barrier.path_join("early.ok")) and FileAccess.file_exists(barrier.path_join("late.ok")):mark("server.ok");stage=2
	elif g.players.has(g.local_id):
		if g.options.map==19 and g.round_no==1:mark(label+".initial")
		if FileAccess.file_exists(barrier.path_join("rotated")):
			var expected=int(FileAccess.get_file_as_string(barrier.path_join("expected")))
			if expected!=19 and g.options.map==expected and g.arena.map_index==expected and g.round_no==3 and g.phase=="buy" and g.arena.get_node_or_null("PreparationGate")!=null:
				if not FileAccess.file_exists(barrier.path_join(label+".ok")):print("ROTATION_SYNC_OK ",label," map=",expected," round=",g.round_no);mark(label+".ok")
func complete(ok:bool):
	done=true;g.set_physics_process(false);g.leave_game();g.queue_free();await process_frame;await process_frame
	if not ok:printerr("ROTATION_TIMEOUT ",label," stage=",stage)
	quit(0 if ok else 1)
