extends SceneTree
# 1.4 hero lineup: all six roles for each team, plus a strafe/backpedal check.
func _initialize():call_deferred("run")
func lineup(world:Node3D,team:int) -> Array:
	var heroes=[]
	for role in range(6):
		var hero=HeroCharacter.new();world.add_child(hero);hero.build(role,team);hero.position=Vector3(2.75-role*1.1,0,0)
		for i in range(20):hero.drive(1./30.,{"velocity":Vector3.ZERO,"grounded":true,"hold":"none"})
		heroes.append(hero)
	return heroes
func capture(path:String):
	for f in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	root.size=Vector2i(1600,900)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("bfe3f5")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("dfe6f2");env.environment.ambient_light_energy=.7;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,25,0);sun.light_energy=.9;world.add_child(sun)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(20,10);floor.mesh=plane;var mat=StandardMaterial3D.new();mat.albedo_color=Color("d6c8a8");floor.material_override=mat;world.add_child(floor)
	var cam=Camera3D.new();world.add_child(cam);cam.fov=48;cam.position=Vector3(0,1.4,-6.2);cam.look_at(Vector3(0,1.,0));cam.current=true
	var heroes=[]
	for team in [0,1]:
		for h in heroes:h.free()
		heroes=lineup(world,team)
		await capture("res://../validation/heroes-v14-team%d.png"%team)
	# Strafe check: one hero moving sideways / diagonally / backwards.
	for h in heroes:h.hide()
	var runner:HeroCharacter=heroes[0];runner.show();runner.position=Vector3.ZERO
	cam.position=Vector3(0,1.2,-4.);cam.look_at(Vector3(0,.9,0));cam.fov=45
	var frames=[]
	for velocity in [Vector3(3.2,0,0),Vector3(-3.2,0,0),Vector3(2.3,0,-2.3),Vector3(0,0,3.2)]:
		for i in range(40):runner.drive(1./60.,{"velocity":velocity,"grounded":true,"hold":"rifle"})
		await process_frame;await RenderingServer.frame_post_draw
		frames.append(root.get_texture().get_image())
	var strip=Image.create(1600,900,false,frames[0].get_format())
	for k in range(4):
		var f:Image=frames[k];f.resize(800,450);strip.blit_rect(f,Rect2i(0,0,800,450),Vector2i((k%2)*800,(k/2)*450))
	strip.save_png("res://../validation/heroes-v14-strafe.png")
	quit()
