extends SceneTree
# Close 3/4 views of guns (validation/gun-closeup/<id>.png, left and right sides). Args: weapon ids.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();root.size=Vector2i(1200,560)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("d8e4ea");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.6;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);world.add_child(sun)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	DirAccess.make_dir_recursive_absolute("res://../validation/gun-closeup/")
	for wid in OS.get_cmdline_user_args():
		var w=Catalog.get_weapon(wid)
		var nodes=[]
		for k in range(2):
			var holder=Node3D.new();world.add_child(holder);nodes.append(holder)
			var gun=GunModel.new();holder.add_child(gun);gun.build(w,true)
			var box=AABB();var first=true
			for m in gun.find_children("*","MeshInstance3D",true,false):
				if m.mesh==null:continue
				var b=GunModel.relative(m,gun)*m.get_aabb();box=b if first else box.merge(b);first=false
			holder.rotation.y=[-.55,PI+.55][k];holder.position=Vector3(0,0,0)
			gun.position=-box.get_center()
			holder.position.x=[-1.,1.][k]*maxf(box.size.z,box.size.y)*.62
			cam.size=maxf(box.size.z,box.size.y)*1.25
		cam.position=Vector3(0,.25,3);cam.look_at(Vector3.ZERO)
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/gun-closeup/%s.png"%wid)
		for n in nodes:n.queue_free()
		await process_frame
	print("CLOSEUP_OK");quit()
