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
	for button in g.ui.panel.find_children("*","Button",true,false):
		if "같은 네트워크" in button.text:printerr("NEARBY_BUTTON_REMAINS");quit(1);return
	g.ui.panel.find_child("QuickJoin",true,false).pressed.emit()
	if not is_instance_valid(g.ui.quick_join):printerr("QUICK_JOIN_DIALOG_MISSING");quit(1);return
	g.ui.close_quick_join()
	print("PUBLIC_LOBBY_PASS default automatic connection / create enabled / one public list / quick-join dialog")
	g.free();quit()
