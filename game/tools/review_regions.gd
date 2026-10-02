extends SceneTree
# 1.4.6: one facade per map region (MapRegions), seen from the street, to
# check that windows, doors and props change from region to region.
# Args: map indices (default 5 7 13).
var out="res://../validation/v146-regions/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var maps=Array(OS.get_cmdline_user_args()).map(func(x):return int(x))
	if maps.is_empty():maps=[5,7,13]
	root.size=Vector2i(960,540);DisplayServer.window_set_size(Vector2i(960,540))
	for index in maps:
		var g=load("res://scripts/game.gd").new();root.add_child(g)
		for i in range(10):await process_frame
		g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
		g.build_world()
		for i in range(3):await process_frame
		await physics_frame
		var plan=DistrictLayout.read_plan(index)
		var best={}
		for f in plan.get("fronts",[]):
			if float(f[6])>0. or float(f[4])<-.1:continue
			var u=Vector3(f[0],0,f[1]);var v=Vector3(f[2],0,f[3]);var length=u.distance_to(v)
			if length<7.:continue
			var mid=(u+v)*.5;var region=MapRegions.region(index,mid,g.arena.bounds)
			var d=(v-u).normalized();var n=Vector3(-d.z,0,d.x)
			var eye=mid+n*8.;eye.y=float(f[4])+1.7
			# the camera must stand on open ground in front of the wall
			var hit=g.ray(eye,mid+n*.3+Vector3.UP*1.7,[],1)
			if not hit.is_empty():continue
			if not best.has(region) or length>best[region][0]:best[region]=[length,eye,mid+Vector3.UP*(float(f[4])+3.)]
		var cam=Camera3D.new();root.add_child(cam);cam.fov=70.;cam.current=true
		for region in best:
			cam.global_position=best[region][1];cam.look_at(best[region][2])
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"map%02d_r%d.png"%[index,region])
		cam.queue_free();g.queue_free()
		for i in range(4):await process_frame
		print("REGIONS map ",index," ",best.keys())
	print("REGIONS_OK");quit()
