extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.profile.menu_animation=false;g.options.map_random=false;g.options.map=17;g.options.bots=1
	g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.ui.clear_panel()
	for i in range(60):await process_frame
	g.leave_game()
	# Let the newly-created menu preview render before destroying its viewport.
	for i in range(4):await process_frame
	g.free();await process_frame;await process_frame
	CharacterVisual.templates.clear();OperatorSkin.templates.clear();WeaponVisual.web_templates.clear()
	SurfaceFinish.clear_cache()
	ToonMaterials.clear_cache()
	for i in range(5):await process_frame
	print("RENDER_SHUTDOWN_DONE");quit()
