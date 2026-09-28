extends SceneTree
const OUT="res://../validation/completion-hud/"
func _initialize():call_deferred("run")
func capture(label:String):
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT);root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.options.map_random=false;g.options.map=17;g.options.bots=0;g.host_game(OfflineMultiplayerPeer.new());g.start_match();g.set_physics_process(false);g.ui.clear_panel();g.ui.show_hud()
	var p=g.players[1];var a=g.actors[1];p.protect=0.;p.flash=0.;p.reload=0.;p.slot=0;p.last_hit=-100.;p.role=2;a.position=Vector3(0,20,0);a.reset_view(0.)
	for id in ["r1","r2","r3","r4","r5","h6"]:
		p.primary=id;g.equip_ammo(p);a.input_state.ads=true
		for i in range(30):a.visual(.05,p,g.clock);await process_frame
		g.ui.refresh();await capture("scope-"+id)
	var view=MapPlanView.new();g.ui.root.add_child(view);view.position=Vector2(120,70);view.size=Vector2(1040,580);view.interactive=true;view.select_map(17)
	for level in range(3):view.level=level;view.queue_redraw();await capture("map-layer-"+str(level))
	view.free();g.free();await process_frame;print("COMPLETION_HUD_DONE");quit()
