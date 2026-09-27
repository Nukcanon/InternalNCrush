extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,900);DisplayServer.window_set_size(root.size)
	DirAccess.make_dir_recursive_absolute("res://../validation/v125")
	var camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=800.
	var light=DirectionalLight3D.new();root.add_child(light);light.rotation_degrees=Vector3(-55,-25,0);light.light_energy=1.4
	var world=WorldEnvironment.new();root.add_child(world);world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("151f29");world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=.8
	for index in [7,10,13,16,19,22,26,30]:
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		camera.position=Vector3(arena.bounds.x*.6,arena.bounds.length()*1.3,arena.bounds.y*.8);camera.look_at(Vector3.ZERO);camera.size=arena.bounds.y*2.25
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/v125/map-%02d.png"%index)
		arena.free();await process_frame
	print("MAP_REVIEW_V125_OK");quit()
