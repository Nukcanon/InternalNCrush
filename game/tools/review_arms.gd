extends SceneTree
# Native heroes: front row Idle, back row Idle_Gun, to inspect arms and proportions.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1600,900)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,150,0);scene.add_child(light)
	var clip=["Idle","Idle_Gun"]
	for row in range(2):
		for role in range(6):
			var hero=HeroCharacter.new();scene.add_child(hero);hero.build(role,role%2,true)
			hero.position=Vector3(-4.6+role*1.84,0,row*2.4);hero.player.play(clip[row]);hero.player.seek(.3,true)
	var camera=Camera3D.new();camera.position=Vector3(0,1.5,-6.6);camera.fov=50;scene.add_child(camera);camera.look_at(Vector3(0,1.,1.));camera.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/arms.png");quit()
