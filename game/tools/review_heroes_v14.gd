extends SceneTree
# 1.4 hero lineup: all six roles side by side (team colours), front and 3/4 view.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1600,900)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("bfe3f5")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("dfe6f2");env.environment.ambient_light_energy=.7;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,25,0);sun.light_energy=.9;world.add_child(sun)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(20,10);floor.mesh=plane;var mat=StandardMaterial3D.new();mat.albedo_color=Color("d6c8a8");floor.material_override=mat;world.add_child(floor)
	var heroes=[]
	for role in range(6):
		var hero=HeroCharacter.new();world.add_child(hero);hero.build(role,role%2);hero.position=Vector3(2.75-role*1.1,0,0)
		for i in range(20):hero.drive(1./30.,{"velocity":Vector3.ZERO,"grounded":true,"hold":"none"})
		heroes.append(hero)
	var cam=Camera3D.new();world.add_child(cam);cam.fov=40;cam.position=Vector3(0,1.3,-8.);cam.look_at(Vector3(0,1.,0));cam.current=true
	for f in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/heroes-v14.png")
	cam.position=Vector3(0,1.6,-3.2);cam.look_at(Vector3(0,1.5,0));cam.fov=55
	for f in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/heroes-v14-faces.png")
	quit()
