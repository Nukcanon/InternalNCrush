extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,800);DisplayServer.window_set_size(root.size)
	var world=Node3D.new();root.add_child(world)
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("29323c")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.65;world.add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.2;world.add_child(sun)
	var camera=Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=16.;camera.position=Vector3(6,12,17);camera.look_at(Vector3(0,1.,0));camera.current=true
	DirAccess.make_dir_recursive_absolute("res://../validation/v128/catalogue")
	var count=0
	for pack in ["district_original","transport_original","doors_original","places_original"]:
		var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+pack+"/manifest.json"))
		var groups={}
		for i in range(manifest.assets.size()):
			var item=manifest.assets[i];var key=str(item.get("theme","sheet_%d"%(i/12)))
			if not groups.has(key):groups[key]=[]
			groups[key].append(item.name)
		for key in groups:
			var stage=Node3D.new();world.add_child(stage)
			var names=groups[key];var rows=ceili(names.size()/4.)
			for i in range(names.size()):
				var holder=Node3D.new();stage.add_child(holder);holder.position=Vector3((i%4-1.5)*3.2,0,(floori(i/4.)-(rows-1)*.5)*3.3)
				ImportedWorldProp.build(holder,names[i],Vector3(2.4,2.7,2.7),pack)
				assert(holder.get_child_count()>0)
				for mesh in holder.get_children():
					assert(mesh is MeshInstance3D and mesh.mesh.get_surface_count()==1)
					assert(mesh.get_active_material(0).vertex_color_use_as_albedo)
				count+=1
			for frame in range(5):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../validation/v128/catalogue/"+pack+"-"+key+".png")
			stage.free();await process_frame
	world.free();print("EXPANDED_ASSETS_VERIFIED ",count);quit()
