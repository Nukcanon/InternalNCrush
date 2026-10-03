extends SceneTree
# 1.5.4 (the user: textures flicker on every map): finds visible z-fighting the way a player
# sees it. For each map, views from walkable points (spawns, goals, a grid) in 6 directions,
# each rendered twice with the camera nudged by 3 mm and 0.02 degrees: real edges barely
# change, coplanar or near-coplanar layers swap pixels in noisy patches. Frames go to
# validation/flicker/<map>/vNNN_a.png / _b.png with views.json; tools/flicker_scan.py finds
# the patches. Run WINDOWED (the compatibility renderer's 24-bit depth, as the game draws).
# Args: map indices (default all but the range), --fov=82, --per=40 views per map.
const W=960
const H=540
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(W,H);DisplayServer.window_set_size(Vector2i(W,H))
	var maps=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).is_valid_int()).map(func(x):return int(x))
	if maps.is_empty():maps=range(31)
	var fov=82.;var per=40
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--fov="):fov=float(str(arg).trim_prefix("--fov="))
		if str(arg).begins_with("--per="):per=int(str(arg).trim_prefix("--per="))
	Catalog.load_all()
	for index in maps:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		for i in range(2):await physics_frame
		var light=DirectionalLight3D.new();light.rotation=Vector3(-.9,.7,0);light.shadow_enabled=false;arena.add_child(light)
		var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("9cc4e4")
		env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.7,.7,.7);arena.add_child(env)
		var cam=Camera3D.new();cam.near=.08;cam.far=300.;cam.fov=fov;arena.add_child(cam);cam.current=true
		# viewpoints: spawns, navigation goals, then a grid of walkable points
		var points=[]
		for s in arena.spawn_points:
			if s is Array:
				for v in s:points.append(Vector3(v))
			else:points.append(Vector3(s))
		for gpos in arena.navigation_goals:
			if gpos is Vector3:points.append(gpos)
		var space=arena.get_world_3d().direct_space_state
		var b:Vector2=arena.bounds
		for gx in range(-3,4):
			for gz in range(-3,4):
				var q=Vector3(gx*b.x/4.,40.,gz*b.y/4.)
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(q,q+Vector3.DOWN*60.,1))
				if not hit.is_empty() and hit.normal.y>.8 and hit.position.y<1.5:points.append(hit.position)
		seed(index*7919);points.shuffle() # (the same views every run, to compare before and after)
		var chosen=[]
		for p in points:
			if chosen.size()>=per/6+1:break
			if chosen.all(func(c):return c.distance_to(p)>8.):chosen.append(p)
		var dir="res://../validation/flicker/%02d/"%index
		DirAccess.make_dir_recursive_absolute(dir)
		var views=[];var n=0
		for p in chosen:
			for k in range(6):
				var yaw=TAU*k/6.+float(index)*.37
				var eye=Vector3(p.x,p.y+1.62,p.z)
				var basis=Basis.from_euler(Vector3(-.04,yaw,0.))
				var frames=[]
				for nudge in [0,1]:
					var offset=basis*Vector3(.003,.002,0.)*nudge
					cam.global_transform=Transform3D(Basis.from_euler(Vector3(-.04+.00035*nudge,yaw+.00035*nudge,0.)),eye+offset)
					for i in range(2):await process_frame
					await RenderingServer.frame_post_draw
					var img=root.get_texture().get_image()
					img.save_png(dir+"v%03d_%s.png"%[n,"ab"[nudge]])
				views.append({"n":n,"eye":[eye.x,eye.y,eye.z],"yaw":yaw,"pitch":-.04,"fov":fov,"w":W,"h":H})
				n+=1
		var f=FileAccess.open(dir+"views.json",FileAccess.WRITE);f.store_string(JSON.stringify(views));f.close()
		print("FLICKER_VIEWS map %d: %d views"%[index,n])
		arena.free();await process_frame
	print("FLICKER_DONE");quit()



