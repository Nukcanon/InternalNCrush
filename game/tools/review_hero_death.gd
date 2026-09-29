extends SceneTree
# Native ragdolls (back row) and web deaths (front row) for every role.
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1600,900)
	var scene=Node3D.new();root.add_child(scene)
	var floor_body=StaticBody3D.new();scene.add_child(floor_body)
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(40,.2,40);collision.shape=shape;collision.position.y=-.1;floor_body.add_child(collision)
	MeshFactory.box(scene,Vector3(0,-.1,0),Vector3(40,.2,40),Color("8a969b"))
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-20,0);scene.add_child(light)
	var camera=Camera3D.new();camera.position=Vector3(0,7.5,9);scene.add_child(camera);camera.look_at(Vector3(0,0,0));camera.current=true
	for role in range(6):
		var source=HeroCharacter.new();scene.add_child(source);source.build(role,role%2,true);source.position=Vector3(-5+role*2,0,-2.);source.drive(.1,{"pitch":0.})
		var rag=HeroRagdoll.new();scene.add_child(rag);rag.build(source,source.global_position,Vector3(0,0,1),role,role%2,0.,false,Vector3.ZERO,source.global_position+Vector3(0,1.5,0))
		source.queue_free()
		var web=HeroDeath.new();scene.add_child(web);web.build(null,Vector3(-5+role*2,0,2.),Vector3(0,0,1),role,role%2,0.,false,Vector3.ZERO)
	for sample in range(3):
		await create_timer(.5 if sample==0 else .9).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/hero-death-%d.png"%sample)
	print("HERO_DEATH_OK");quit()
