extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1200,1200);DisplayServer.window_set_size(Vector2i(1200,1200))
	var args=Array(OS.get_cmdline_user_args())
	var index=int(args[0]);var x=float(args[1]);var z=float(args[2]);var span=float(args[3])
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.ui.root.visible=false;g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
	g.build_world()
	for i in range(3):await process_frame
	var cam=Camera3D.new();root.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=span;cam.current=true
	cam.global_position=Vector3(x,40,z);cam.look_at(Vector3(x,0,z),Vector3.FORWARD)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/v146-water/top_map%02d.png"%index)
	print("TOP_OK");quit()
