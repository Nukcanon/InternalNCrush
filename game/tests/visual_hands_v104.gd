extends SceneTree
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://../validation/v104-hands")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.ui.clear_panel();g.set_physics_process(false)
	g.options.map_random=false;g.options.map=13;g.server=true;g.phase="lobby";g.build_world();g.add_player(1,"HAND REVIEW","hand_review");g.phase="combat";g.clock=100.
	var a=g.actors[1];a.set_local(true);a.position=Vector3(0,.1,20);a.reset_view(0.)
	var p=g.players[1];p.alive=true;p.protect=0.;p.slot=0;g.ui.show_hud()
	for id in ["a1","r2","e1","pistol"]:
		p.primary=id;p.role=Catalog.get_weapon(id).role;g.equip_ammo(p)
		for hand in [-1,1]:
			p.hand=hand;p.reload=0.
			for i in range(12):a.visual(.016,p,100.);await process_frame
			g.ui.refresh();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../validation/v104-hands/"+id+"-"+str(hand)+".png")
		p.reload_started=99.;p.reload=102.
		for i in range(6):a.visual(.016,p,100.);await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/v104-hands/"+id+"-reload.png")
	g.ui.clear_panel();g.free();await process_frame;print("HANDS_VISUAL_OK");quit()
