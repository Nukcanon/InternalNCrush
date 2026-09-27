extends SceneTree
func _initialize():call_deferred("run")
func run():
	var host="--rtc-host" in OS.get_cmdline_user_args()
	var game=load("res://scripts/game.gd").new();game.name="Game";root.add_child(game);game.render_actors=false
	game.profile.nick="RTC HOST" if host else "RTC CLIENT";game.profile.token=game.profile.nick.sha256_text()
	var result=await game.internet.connect_service(OS.get_environment("INC_DIRECTORY_URL") if not OS.get_environment("INC_DIRECTORY_URL").is_empty() else "http://127.0.0.1:30880")
	if result.has("error"):printerr(result);quit(1);return
	var id=""
	if host:
		result=await game.internet.request("/v1/rooms",{"name":"RTC TEST","mode":0,"map":13,"capacity":8,"map_random":false,"minutes":0,"target":125,"team_respawns":28,"capture_hold":40,"rounds":6,"starting_cash":1700,"prep_seconds":25,"round_minutes":7,"lives":3,"next_teams":2})
		id=str(result.get("id",""))
	else:
		for attempt in range(60):
			result=await game.internet.request("/v1/rooms")
			for room in result.get("rooms",[]):
				if room.name=="RTC TEST" and room.phase!="starting":id=room.id
			if not id.is_empty():break
			await create_timer(.5).timeout
	if id.is_empty():printerr("ROOM_NOT_FOUND ",result);quit(1);return
	result=await game.internet.join(id)
	if result.has("error"):printerr(result);quit(1);return
	var connected_at=-1.
	for step in range(120):
		await create_timer(.5).timeout
		if host and game.players.keys().filter(func(pid):return pid>0).size()>=2 and game.phase=="lobby":game.start_match()
		if game.players.size()>=2 and game.phase=="combat":
			if connected_at<0:connected_at=step
			if step-connected_at>=8:
				for key in ["minutes","target","team_respawns","capture_hold","rounds","starting_cash","prep_seconds","round_minutes","lives","next_teams"]:
					var wanted={"minutes":0,"target":125,"team_respawns":28,"capture_hold":40,"rounds":6,"starting_cash":1700,"prep_seconds":25,"round_minutes":7,"lives":3,"next_teams":2}
					if int(game.options[key])!=int(wanted[key]):printerr("RTC_OPTION_MISMATCH ",key);quit(1);return
				print("RTC_CONNECTED role=", "host" if host else "client"," players=",game.players.size()," ping=",game.ping_ms," snapshots=",game.received_sequence)
				if not host and (game.received_sequence<2 or game.ping_ms>4000):quit(1);return
				if host:await create_timer(180. if "--rtc-hold" in OS.get_cmdline_user_args() else 4.).timeout
				game.leave_game();game.free();await process_frame;quit();return
	printerr("RTC_TIMEOUT host=",host," phase=",game.phase," peers=",game.multiplayer.get_peers()," active=",game.rtc.active," connections=",game.rtc.connections.size());quit(1)
