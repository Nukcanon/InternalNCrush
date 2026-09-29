extends SceneTree
# Side / three-quarter renders of the code-built launchers with their rounds:
# COMET loaded / empty / loading, QUAD 4 / 2 / loading the third.
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,900)
	Catalog.load_all()
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.6;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,40,0);scene.add_child(light)
	var cases=[["h4",1,-1.],["h4",0,-1.],["h4",0,.6],["h5",4,-1.],["h5",2,-1.],["h5",2,.6]]
	for i in range(cases.size()):
		var gun=GunModel.new();scene.add_child(gun);gun.build(Catalog.get_weapon(cases[i][0]),true)
		gun.set_rounds(int(cases[i][1]),float(cases[i][2]))
		gun.position=Vector3(-2.5+(i%3)*2.5,.6-(i/3)*1.2,0);gun.rotation=Vector3(0,PI*.5+.35,0)
	var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,.6,-4.2);camera.look_at(Vector3(0,0,0));camera.fov=45;camera.current=true
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/launchers.png");print("LAUNCHERS_OK");quit()
