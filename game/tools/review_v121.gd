extends SceneTree
const OUT="res://../validation/v121/"
func _initialize():call_deferred("run")
func capture(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(OUT+name+".jpg",.95)
func run():
	root.size=Vector2i(1000,760);DisplayServer.window_set_size(root.size);DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(1000,760)
	for role in [0,1,2,3,4,5]:
		preview.display(0,role,0,Catalog.first(role));await capture("operator"+str(role))
		preview.camera.position=Vector3(.2,1.64,-2);preview.camera.look_at(Vector3(0,1.61,0));preview.camera.size=.52;await capture("face"+str(role))
	for variant in [0,1]:preview.display(2,4,0,"c1",variant);await capture("control"+str(variant))
	preview.display(2,2,0,"h1",0);await capture("bipod")
	for spec in [[0,8],[4,0],[4,1],[0,0],[3,0]]:
		preview.display(2,spec[0],0,"a1",spec[1]);preview.stage.remove_child(preview.model);preview.model.free()
		preview.model=GadgetVisual.new();preview.stage.add_child(preview.model);preview.model.build(spec[0],spec[1],true)
		preview.camera.position=Vector3(.25,.13,.75);preview.camera.look_at(Vector3(0,0,-.12));preview.camera.size=.65
		await capture("grip%d_%d"%[spec[0],spec[1]])
	preview.free()
	TouchControls.supported_cache=1
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.add_player(1,"Mobile","mobile");g.phase="combat";g.clock=100.;var p=g.players[1];p.role=5;p.primary="m2";p.skill_ready=0.;g.ui.show_hud();g.ui.refresh();g.touch._process(.1);await capture("mobile-medic")
	p.role=2;p.primary="h1";g.ui.refresh();g.touch._process(.1);await capture("mobile-heavy")
	g.free();print("V121_REVIEW_OK");quit()
