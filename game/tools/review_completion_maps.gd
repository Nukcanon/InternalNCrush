extends SceneTree
var camera:Camera3D
const OUT="res://../validation/completion-maps/"
func _initialize():call_deferred("run")
func shot(label:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(960,600);DisplayServer.window_set_size(root.size)
	GraphicsOptions.shadows=2;GraphicsOptions.lighting=2;ToonMaterials.configure(true)
	RenderingServer.global_shader_parameter_set("material_detail_enabled",true)
	camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.far=600.
	var indices=range(32)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			indices=[]
			for item in arg.trim_prefix("--maps=").split(","):indices.append(int(item))
	for index in indices:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		var plan=DistrictLayout.read_plan(index)
		await physics_frame;await physics_frame
		if not plan.facades.is_empty():
			var f=plan.facades[plan.facades.size()/2]
			var center=Vector3(f[0],f[4]+1.7,f[1]);var outward=Vector3(sin(f[2]),0,cos(f[2]));var right=Vector3(cos(f[2]),0,-sin(f[2]))
			var ray=PhysicsRayQueryParameters3D.create(center+outward*.25,center+outward*7.,1)
			var hit=arena.get_world_3d().direct_space_state.intersect_ray(ray)
			var distance=minf(5.,center.distance_to(hit.position)-.25) if not hit.is_empty() else 5.
			camera.fov=110. if distance<3. else 80.
			camera.position=center+outward*maxf(.5,distance);camera.look_at(center);await shot("%02d-front"%index)
			camera.position=center+outward*.65+right*2.;camera.look_at(center);await shot("%02d-side"%index)
		camera.fov=75.
		camera.position=Vector3(arena.bounds.x*.55,arena.bounds.length()*.95,arena.bounds.y*.7);camera.look_at(Vector3.ZERO);await shot("%02d-layout"%index)
		print("MAP_REVIEW ",index);arena.free();await process_frame
	print("MAP_REVIEW_COMPLETE");quit()
