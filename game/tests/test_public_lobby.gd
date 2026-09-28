extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.profile.nick="Lobby verification";g.profile.lobby_url=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lobby_defaults.json")).url
	g.ui.internet_menu()
	for attempt in range(200):
		await create_timer(.1).timeout
		if not g.internet.token.is_empty() and not g.internet.busy:break
	if g.internet.token.is_empty():printerr("AUTO_CONNECT_FAILED ",g.ui.notice_label.text);quit(1);return
	var create=g.ui.panel.find_child("CreateRoom",true,false)
	if create==null or create.disabled:printerr("CREATE_NOT_ENABLED");quit(1);return
	g.ui.internet_menu("lan")
	await create_timer(2.).timeout
	if g.internet.scope!="internet" or not g.ui.internet_nearby:printerr("NEARBY_CHANGED_ADMISSION_SCOPE");quit(1);return
	print("PUBLIC_LOBBY_PASS default automatic connection / create enabled / nearby is only a filter")
	g.free();quit()
