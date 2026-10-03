extends SceneTree
# 1.5.4 (the user: a refused medic class must warn in the gear panel and keep it open):
# the gear panel with the refusal dialog. Output validation/preview-154c/04_medic_cap_warning.jpg
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.classes=true
	g.build_world();g.add_player(1,"PLAYER","medcap_local");g.add_player(2,"MEDIC","medcap_2")
	g.players[1].team=0;g.players[2].team=0;g.players[2].role=5
	g.phase="combat";g.clock=100.
	g.ui.gear()
	for i in range(10):await process_frame
	g.ui.gear_warning("메딕 정원 초과",g.medic_full_text(0))
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../validation/preview-154c/")
	root.get_texture().get_image().save_jpg("res://../validation/preview-154c/04_medic_cap_warning.jpg",.9)
	print("MEDCAP_DONE");quit()
