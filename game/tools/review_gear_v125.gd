extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://../validation/v125")
	var game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
	for web in [false,true]:
		ProjectSettings.set_setting("application/config/web_assets",web)
		for viewport_size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(960,540)]:
			root.size=viewport_size;DisplayServer.window_set_size(viewport_size)
			for mode in range(4):
				game.options.mode=mode;game.ui.bot_setup=true;game.ui.gear()
				for i in range(8):await process_frame
				var label=game.ui.gear_price;var actions=label.get_parent().get_parent().get_parent()
				var good=label.text=="무료" and label.size.x>=40 and label.size.y<70 and actions.size.y<115
				for child in actions.get_children():
					if child is Button:good=good and child.size.y<115
				if not good:failures+=1
				print("GEAR_LAYOUT ",web," ",viewport_size," mode=",mode," footer=",actions.size," label=",label.size," ok=",good)
				if mode==0:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://../validation/v125/gear-%s-%d.png"%["web" if web else "native",viewport_size.x])
	game.ui.bot_setup=false;game.server=true;game.local_id=1;game.add_player(1,"MENU REVIEW","v125-review")
	for mode in range(5):
		game.options.mode=mode;game.phase="buy" if mode==4 else "combat";game.remaining=30.;game.players[1].alive=true;game.ui.gear()
		for i in range(8):await process_frame
		var value=game.ui.gear_price;var actions=value.get_parent().get_parent().get_parent()
		var good=actions.size.y<115 and (value.text!="무료" if mode==4 else value.text=="무료")
		if not good:failures+=1
		print("GEAR_COMBAT mode=",mode," footer=",actions.size," ok=",good)
	game.leave_game();game.free();await process_frame
	print("GEAR_V125_FAILURES ",failures);quit(1 if failures else 0)
