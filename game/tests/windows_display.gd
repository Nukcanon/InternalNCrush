extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.ui.clear_panel();g.set_physics_process(false)
	var failures=0
	for screen in range(DisplayServer.get_screen_count()):
		for mode in [0,1,2]:
			g.profile.monitor=screen;g.profile.display_mode=mode;g.profile.width=960;g.profile.height=540;g.apply_display_settings()
			await create_timer(.3).timeout
			var actual_screen=DisplayServer.window_get_current_screen();var actual_mode=DisplayServer.window_get_mode();var size=DisplayServer.window_get_size()
			var expected=[DisplayServer.WINDOW_MODE_WINDOWED,DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN][mode]
			g.ui.settings()
			var native=DisplayServer.screen_get_size(screen);var choices=DisplayOptions.resolutions_for(native)
			var resolution=g.ui.panel.find_child("ResolutionChoices",true,false);var manual=g.ui.panel.find_child("CustomResolution",true,false)
			var rendered=root.get_texture().get_size()
			var ok=actual_screen==screen and actual_mode==expected and choices.all(func(v):return v.x<=native.x and v.y<=native.y) and not manual.visible and not resolution.disabled and rendered==Vector2(960,540)
			resolution.select(resolution.item_count-1);resolution.item_selected.emit(resolution.selected)
			ok=ok and manual.visible
			if not ok:failures+=1
			print("DISPLAY_CHECK screen=",screen," mode=",mode," actual_screen=",actual_screen," actual_mode=",actual_mode," size=",size," rendered=",rendered," OK=",ok)
	g.profile.monitor=0;g.profile.display_mode=0;g.profile.width=1280;g.profile.height=720;g.apply_display_settings();g.free()
	for i in range(8):await process_frame
	print("WINDOWS_DISPLAY_RESULT failures=",failures," monitors=",DisplayServer.get_screen_count());quit(1 if failures else 0)
