extends SceneTree
# Close-ups of hand/finger poses in candidate grip clips.
const CASES=[["Idle_Gun_Pointing",.3],["Punch_Left",.25],["Punch_Right",.25],["Pistol_Aim_Neutral",.3],["Sword_Slash",.3],["Idle_Sword",.3]]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,600)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,30,0);scene.add_child(light)
	for i in range(CASES.size()):
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(3,0,true);hero.position=Vector3(-7.5+i*3.,0,0)
		hero.play(CASES[i][0],CASES[i][1])
		var label=Label3D.new();label.text=CASES[i][0];label.position=hero.position+Vector3(0,2.,0);label.font_size=32;label.pixel_size=.005;label.modulate=Color.BLACK;scene.add_child(label)
	var camera=Camera3D.new();camera.position=Vector3(0,1.4,-7.);camera.fov=62;scene.add_child(camera);camera.look_at(Vector3(0,1.2,0));camera.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands.png");quit()
