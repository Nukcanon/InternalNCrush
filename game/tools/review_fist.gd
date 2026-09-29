extends SceneTree
# Close-up of hands at several times of native clips, to pick grip finger poses.
const CASES=[["Idle_Gun_Pointing",.3],["Punch_Left",.1],["Punch_Left",.2],["Punch_Left",.3],["Punch_Right",.2],["Idle_Sword",.3]]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,500)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,30,0);scene.add_child(light)
	var shots=[]
	for i in range(CASES.size()):
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(3,0,false);hero.position=Vector3(i*3.,0,0)
		hero.play(CASES[i][0],CASES[i][1])
	await process_frame
	var vp_images=[]
	for i in range(CASES.size()):
		var hero:HeroCharacter=scene.get_child(2+i)
		var side="L" if CASES[i][0].ends_with("Left") else "R"
		var focus=hero.bone_world(hero.skeleton.find_bone("Wrist."+side)).origin
		var cam=Camera3D.new();scene.add_child(cam);cam.fov=25;cam.position=focus+Vector3(0,.15,-.6);cam.look_at(focus);cam.current=true
		for k in range(2):await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.crop(1800,500);vp_images.append(img);cam.queue_free()
	var sheet=Image.create(300*CASES.size(),250,false,Image.FORMAT_RGBA8)
	for i in range(vp_images.size()):
		var small=vp_images[i].get_region(Rect2i(650,0,500,500));small.resize(250,250);sheet.blit_rect(small,Rect2i(0,0,250,250),Vector2i(i*300,0))
	sheet.save_png("res://../validation/fists.png");quit()
