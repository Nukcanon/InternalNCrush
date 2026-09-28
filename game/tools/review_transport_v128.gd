extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1200,700);DisplayServer.window_set_size(root.size)
	var world=Node3D.new();root.add_child(world)
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("29323c")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.65;world.add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.2;world.add_child(sun)
	var camera=Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=27.;camera.position=Vector3(9,17,23);camera.look_at(Vector3(0,1.,0));camera.current=true
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/transport_original/manifest.json"))
	var names=manifest.assets.map(func(item):return item.name)
	for i in range(names.size()):
		var holder=Node3D.new();world.add_child(holder);holder.position=Vector3((i%8-3.5)*3.2,0,(floori(i/8.)-1.5)*3.5)
		ImportedWorldProp.build(holder,names[i],Vector3(2.5,2.8,3.),"transport_original")
		assert(holder.get_child_count()>0)
		for mesh in holder.get_children():
			assert(mesh is MeshInstance3D and mesh.mesh.get_surface_count()==1)
			assert(mesh.get_active_material(0).vertex_color_use_as_albedo,"Authored colour must survive import")
	for frame in range(8):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://../validation/v128")
	root.get_texture().get_image().save_png("res://../validation/v128/transport-props.png")
	world.free();print("V128_TRANSPORT_VERIFIED");quit()
