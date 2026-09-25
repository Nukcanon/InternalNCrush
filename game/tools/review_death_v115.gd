extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var scene=Node3D.new();root.add_child(scene)
	var floor_body=StaticBody3D.new();scene.add_child(floor_body)
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(30,.2,30);collision.shape=shape;collision.position.y=-.1;floor_body.add_child(collision)
	MeshFactory.box(scene,Vector3(0,-.1,0),Vector3(30,.2,30),Color("68777b"))
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-65,-20,0);scene.add_child(light)
	var camera=Camera3D.new();camera.position=Vector3(0,8,7);scene.add_child(camera);camera.look_at(Vector3(0,0,-1));camera.current=true
	var native=PhysicsRagdoll.new();scene.add_child(native);native.build(null,Vector3(-2,0,0),Vector3.FORWARD,0,0,0.,false,Vector3.ZERO)
	var web=AnimatedDeath.new();scene.add_child(web);web.build(null,Vector3(2,0,0),Vector3.FORWARD,0,0,0.,false,Vector3.ZERO)
	DirAccess.make_dir_recursive_absolute("res://validation")
	for sample in range(3):
		await create_timer(.65 if sample==0 else .85).timeout
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("res://validation/death-native-left-lightweight-right-%d.png"%sample)!=OK:quit(1);return
	print("DEATH_RENDER_OK native_left lightweight_right bullet_direction=forward");quit()
