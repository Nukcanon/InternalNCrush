extends SceneTree
# 1.4.6: the heroes' ink outline (thin, continuous; the middle one marked).
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(800,600)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d8e8f0");world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,30,0);world.add_child(sun)
	for i in range(3):
		var h=HeroCharacter.new();world.add_child(h);h.build([3,0,5][i],i%2,true);h.position=Vector3(-1.2+i*1.2,0,-i*1.5)
		for j in range(3):h.drive(.05,{"hold":"none"})
		if i==1:h.set_ink(TargetReveal.MARKED_INK)
	var cam=Camera3D.new();world.add_child(cam);cam.position=Vector3(0,1.5,3.2);cam.look_at(Vector3(0,1.0,-1));cam.current=true;cam.fov=45
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/outline_test.png")
	print("OUTLINE_TEST_OK");quit()
