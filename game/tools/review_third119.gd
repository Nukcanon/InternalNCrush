extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("526779");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1.;world.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,150,0);world.add_child(light)
	var camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(2.,1.6,-2.);camera.look_at(Vector3(0,1.25,-.1));camera.current=true
	var c=CharacterVisual.new();world.add_child(c);c.enable_physics=false;c.build(2,0)
	var weapon=WeaponVisual.new();c.socket.add_child(weapon);weapon.build(Catalog.get_weapon("h4"),false,false);weapon.scale=Vector3.ONE*.85
	for phase in [-1.,.4,.65]:
		for i in range(10):
			weapon.animate_reload(phase,0.,10.);c.update_pose(1./60.,Vector3.ZERO,false,false,true,0.,phase,0.);await process_frame
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_jpg("res://../validation/v119/third-rocket-%s.jpg"%str(phase),.92)
	c.hide();camera.position=Vector3.ZERO;camera.rotation=Vector3.ZERO;camera.fov=82.;camera.near=.04
	var first=WeaponVisual.new();camera.add_child(first);first.position=Vector3(.255,-.255,-.46);first.build(Catalog.get_weapon("h4"),true,false);first.scale=Vector3.ONE*.85
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_jpg("res://../validation/v119/rocket-bore.jpg",.92)
	world.free();await process_frame;quit()
