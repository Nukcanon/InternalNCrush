extends SceneTree
## Actual bot combat at full HD. Screenshots are generated independently per platform.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute("res://assets/menu_slides")
	var number=0
	for map_index in [0,7,13]:
		var game=load("res://scripts/game.gd").new();game.demo_mode=true;game.demo_map=map_index;root.add_child(game)
		GraphicsOptions.detail=1;GraphicsOptions.lighting=0 if RenderStyle.web() else 1
		GraphicsOptions.shadows=0 if RenderStyle.web() else 1;GraphicsOptions.antialias=0 if RenderStyle.web() else 1
		GraphicsOptions.fog=not RenderStyle.web();ToonMaterials.configure(RenderStyle.web() and GraphicsOptions.lighting>0)
		GraphicsOptions.apply_viewport(root);GraphicsOptions.apply_world(game)
		var camera=Camera3D.new();camera.far=200.;camera.fov=72.;root.add_child(camera);camera.current=true
		await create_timer(5.).timeout
		for i in range(4):
			var actor=game.actors[-1-i]
			var target=actor.position+Vector3.UP*1.3
			var offset=Basis(Vector3.UP,actor.aim_yaw+.35)*Vector3(2.5,2.4,5.)
			var hit=game.ray(target,target+offset,[],1)
			camera.position=hit.position+(target-hit.position).normalized()*.25 if not hit.is_empty() else target+offset
			camera.look_at(target+actor.direction()*5.)
			await create_timer(2.).timeout
			await process_frame;await RenderingServer.frame_post_draw
			var picture=root.get_texture().get_image();number+=1
			if picture.is_empty() or picture.save_jpg("res://assets/menu_slides/%02d.jpg"%number,.92)!=OK:quit(1);return
		game.free();camera.free();await process_frame
	print("MENU_SLIDES_OK count=",number," resolution=1920x1080 style=", "web" if RenderStyle.web() else "native")
	quit()
