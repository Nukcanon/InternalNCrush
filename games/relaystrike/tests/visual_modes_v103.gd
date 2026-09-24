extends SceneTree
var g:Node
var folder="res://../../validation/v103-modes"
func _initialize():call_deferred("run")
func capture(name:String):
	for frame in range(5):await process_frame
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run():
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(folder)
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	g.ui.training_menu();await capture("training-menu")
	g.ui.host_settings();await capture("room-options")
	g.options.mode=4;g.ui.host_settings();await capture("defusal-options")
	g.ui.clear_panel();PracticeSession.start(g)
	var a=g.actors[1]
	for frame in range(20):
		g.clock+=.016
		for id in g.players:g.actors[id].visual(.016,g.players[id],g.clock)
		g.ui.refresh();await process_frame
	await capture("practice-entry")
	for pos in [Vector3(-25,4.25,12),Vector3(25,8.45,12),Vector3(-25,12.65,-12)]:
		a.position=pos;a.reset_view(0.);a.visual(.1,g.players[1],g.clock);g.ui.refresh();await capture("practice-level-"+str(roundi(pos.y)))
	g.ui.gear();g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("equipment-transparent")
	g.ui.clear_panel();g.options.practice=false;g.options.mode=4;g.options.map_random=false;g.options.map=19;g.options.max_players=8;g.build_world();g.phase="buy";g.round_no=1;g.remaining=45.;g.spawn(1);MatchFlow.update_gate(g);g.ui.show_hud()
	a.position=g.arena.spawn_points[0][2];a.reset_view(0.);a.visual(.1,g.players[1],g.clock);g.ui.refresh();await capture("defusal-preparation")
	g.phase="combat";MatchFlow.update_gate(g)
	for index in range(19,31):
		g.options.map=index;g.build_world();var spec=DefusalLayout.spec(index)
		a.position=Vector3(spec.points[2].x-3.,.12,spec.points[2].y+5.);a.reset_view(0.);a.visual(.1,g.players[1],g.clock);g.ui.refresh();await capture("defusal-%02d"%index)
	g.leave_game();g.free();await process_frame;await process_frame;print("V103_MODES_NATIVE_COMPLETE");quit()
