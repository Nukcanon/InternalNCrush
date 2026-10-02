extends SceneTree
# 1.5.0 (the user: windows and bands beside a pillar where no wall stands): views
# of the covered-room pillars (plan "supports" with a side) from the open
# ground in front of them. validation/pillars/mapXX_N.jpg. Run windowed.
var g:Node
var out="res://../validation/pillars/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var ids=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).is_valid_int()).map(func(x):return int(x))
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	for index in ids:
		g.options.map=index;g.build_world()
		for i in range(3):await process_frame
		await physics_frame
		var plan=DistrictLayout.read_plan(index);var n=0
		var space=g.get_world_3d().direct_space_state
		for s in plan.get("supports",[]):
			if s.size()<5 or n>=4:continue
			var p=Vector3(s[0],float(s[3])+1.6,s[1])
			# look from the side with the most open ground (the street in front of the opening)
			var best=Vector3.ZERO;var reach=0.
			for k in range(8):
				var dir=Vector3(cos(k*TAU/8.),0,sin(k*TAU/8.))
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+dir*9.,1))
				var r=9. if hit.is_empty() else p.distance_to(hit.position)
				if r>reach:reach=r;best=dir
			var cam=Camera3D.new();root.add_child(cam);cam.fov=75.
			cam.global_position=p+best*minf(6.,reach-.5)+Vector3.UP*.1;cam.look_at(p+Vector3.DOWN*.4);cam.current=true
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(out+"map%02d_%d.jpg"%[index,n],.85);n+=1
			cam.queue_free()
		print("PILLARS map ",index," shots ",n)
	print("PILLARS_DONE");quit()
