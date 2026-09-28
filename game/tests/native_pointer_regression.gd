extends SceneTree
var game:Node
var failures=[]
func check(ok:bool,label:String):
	print("POINTER_CHECK ",label," ","PASS" if ok else "FAIL")
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func key(code:int):
	var event=InputEventKey.new();event.keycode=code;event.pressed=true;Input.parse_input_event(event)
	await process_frame
	event=InputEventKey.new();event.keycode=code;event.pressed=false;Input.parse_input_event(event)
	await process_frame
func run():
	root.size=Vector2i(1280,720);root.gui_embed_subwindows=false
	game=load("res://Main.tscn").instantiate();root.add_child(game)
	await create_timer(2.).timeout
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"startup menu visible cursor")
	var demo=load("res://scripts/game.gd").new();demo.demo_mode=true
	demo.capture_pointer();check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"demo cannot capture menu cursor");demo.free()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	await create_timer(.15).timeout
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"menu corrects accidental capture")
	game.options.bots=0;game.options.map=17;game.options.map_random=false
	game.host_game(OfflineMultiplayerPeer.new());game.start_match();game.ui.clear_panel()
	root.grab_focus();await create_timer(.3).timeout;game.capture_pointer()
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"gameplay can capture")
	game.ui.gear();await create_timer(.2).timeout
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"B equipment menu cursor")
	var other=Window.new();other.title="Pointer focus regression";other.size=Vector2i(240,120);root.add_child(other);other.show();other.grab_focus()
	await create_timer(.4).timeout
	check(not root.has_focus(),"native focus leaves game window")
	game.spawn(game.local_id);await create_timer(.2).timeout
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"respawn while unfocused with menu")
	other.hide();root.grab_focus();await create_timer(.5).timeout
	check(root.has_focus() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"native focus return keeps B cursor")
	other.queue_free()
	game.ui.teams_menu();await key(KEY_ESCAPE)
	check(not is_instance_valid(game.ui.panel),"Escape closes team menu")
	game.ui.make_panel("Shortcut regression",480,true)
	var accepted=[false];game.ui.button("확인",func():accepted[0]=true)
	await key(KEY_ENTER);check(accepted[0],"Enter activates confirm")
	var left=[false];game.ui.confirm_navigation(func():left[0]=true,"이전 화면")
	await create_timer(.2).timeout
	var event=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true
	game.ui.navigation_confirm.window_input.emit(event)
	await process_frame;check(left[0],"Escape on leave warning confirms leaving")
	print("POINTER_REGRESSION_RESULT ","PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
