extends SceneTree
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/"+name+".png")
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map=19;g.options.map_random=false;g.build_world();g.add_player(1,"QA","surface");g.local_id=1;var a=g.actors[1];a.set_local(true);a.position=Vector3(-20,.12,-7);a.reset_view(0.);a.visual(.1,g.players[1],1.)
	await shot("v103-surface-base")
	g.arena.get_node("Sun").shadow_bias=.25;g.arena.get_node("Sun").shadow_normal_bias=1.5;await shot("v103-surface-bias")
	g.arena.get_node("Sun").shadow_enabled=false;await shot("v103-surface-no-shadow")
	g.arena.get_node("Sun").shadow_enabled=true
	await shot("v103-surface-no-noise");g.leave_game();g.free();await process_frame;quit()
