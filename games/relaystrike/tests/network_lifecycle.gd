extends SceneTree
var g:Node
var start=0
var server_mode=false
var label_id=""
var rejoins=0
var lost=0
var last_phase="menu"
var max_players=0
var saw_restarted=false
var departed=false
var restart_done=false
var restart_at=0
var next_join=0
var finish_ms=105000
var snapshots=0
var control=""
var checked=false
var last_sequence=-1
func _initialize():call_deferred("run")
func run():
	g=load("res://scripts/game.gd").new();g.name="Lifecycle";root.add_child(g);start=Time.get_ticks_msec()
	for arg in OS.get_cmdline_user_args():
		if arg=="--life-server":server_mode=true
		if arg.begins_with("--life-control="):control=arg.trim_prefix("--life-control=")
		if arg.begins_with("--life-id="):label_id=arg.trim_prefix("--life-id=")
	if control.is_empty():push_error("Missing lifecycle barrier directory");quit(1);return
	if server_mode:g.dedicated=true;g.host_game()
	else:g.profile.nick="LIFE"+label_id;g.profile.token="lifecycle_unique_identity_"+label_id;g.join_game("127.0.0.1")
	physics_frame.connect(drive)
func drive():
	var elapsed=Time.get_ticks_msec()-start
	if elapsed>190000:push_error("Lifecycle completion barrier timed out");quit(1);return
	max_players=maxi(max_players,g.players.size())
	if server_mode:
		if elapsed>35000 and not restart_done:
			restart_done=true;g.leave_game();restart_at=elapsed;print("SERVER_RESTART_BEGIN count=",max_players)
		elif restart_done and g.phase=="menu" and elapsed-restart_at>1500:g.host_game();print("SERVER_RESTARTED")
		var all_checked=true
		for i in range(8):
			if not FileAccess.file_exists(control.path_join("client%d.ok"%i)):all_checked=false
		if all_checked and not checked:
			var ok=g.players.size()==8 and max_players==8 and restart_done and g.phase=="lobby"
			print("LIFECYCLE_SERVER peers=",g.players.size()," max=",max_players," barrier=",all_checked," OK=",ok)
			if not ok:quit(1);return
			checked=true
			FileAccess.open(control.path_join("server.ok"),FileAccess.WRITE).store_string("8 peers verified")
			# The runner releases every process only after this server-side assertion.
		if checked and FileAccess.file_exists(control.path_join("release")):quit(0)
		return
	if g.phase=="lobby":
		if last_phase!="lobby":rejoins+=1;print("JOINED id=",label_id," times=",rejoins," seq=",g.received_sequence)
		if g.received_sequence>=0 and g.received_sequence!=last_sequence:snapshots+=1;last_sequence=g.received_sequence
		if label_id=="2" and elapsed>16000 and not departed:
			departed=true;g.request_leave();next_join=Time.get_ticks_msec()+1000
	if g.phase=="menu" and last_phase=="lobby":lost+=1
	if g.phase=="menu" and not g.connection_busy and Time.get_ticks_msec()>next_join:
		next_join=Time.get_ticks_msec()+2000;g.join_game("127.0.0.1")
	last_phase=g.phase
	if elapsed>finish_ms and not checked:
		checked=true
		var age=Time.get_ticks_msec()-g.last_snapshot_ms
		var ok=g.phase=="lobby" and g.players.size()==8 and rejoins>=(3 if label_id=="2" else 2) and lost>=1 and age<3000 and snapshots>300
		print("LIFECYCLE_CLIENT id=",label_id," joins=",rejoins," losses=",lost," population=",g.players.size()," gap_ms=",age," snapshots=",snapshots," OK=",ok)
		if not ok:quit(1);return
		FileAccess.open(control.path_join("client"+label_id+".ok"),FileAccess.WRITE).store_string("passed")
	if checked and FileAccess.file_exists(control.path_join("release")):quit(0)
