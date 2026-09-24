extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute("res://../validation/v103-maps")
	var camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.far=500;camera.fov=62.
	for index in range(32):
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		camera.position=Vector3(arena.bounds.x*.45,maxf(arena.bounds.x,arena.bounds.y)*1.8,arena.bounds.y*1.5);camera.look_at(Vector3(0,1.,0))
		for frame in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/v103-maps/map-%02d.png"%index)
		print("MAP_RENDERED ",index," layers=",arena.walk_surfaces.size()," doors=",arena.doors.size())
		arena.free();await process_frame
	print("V103_MAP_RENDER_COMPLETE");quit()
