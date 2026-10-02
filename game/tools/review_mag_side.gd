extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1500,700);DisplayServer.window_set_size(Vector2i(1500,700))
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d8e8f0");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,30,0);world.add_child(sun)
	var ids=Array(OS.get_cmdline_user_args())
	var ts=[-1.,.1,.2,.3,.4,.55,.7,.8]
	for row in range(ids.size()):
		for i in range(ts.size()):
			var g=GunModel.new();world.add_child(g);g.build(Catalog.get_weapon(ids[row]),true)
			g.position=Vector3(i*.9-3.2,-row*1.1+.5,0);g.rotation.y=PI*.5
			g.animate_reload(ts[i])
	var cam=Camera3D.new();world.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=1.1*ids.size()+.6;cam.position=Vector3(0,.5-(ids.size()-1)*.55,5);cam.current=true
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands2/mag_side.png")
	print("SIDE_OK");quit()
