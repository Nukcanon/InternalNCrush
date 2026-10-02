extends SceneTree
# 1.4.6: the water maps - each boat seen from its quay and each shallow pool -
# plus a check that the deck of a boardable boat is reachable on foot.
# Args: map indices (default: every map with water).
var out="res://../validation/v146-water/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var maps=Array(OS.get_cmdline_user_args()).map(func(x):return int(x))
	if maps.is_empty():maps=[0,4,5,7,13,20,21,23,26,28]
	root.size=Vector2i(960,540);DisplayServer.window_set_size(Vector2i(960,540))
	for index in maps:
		var g=load("res://scripts/game.gd").new();root.add_child(g)
		for i in range(10):await process_frame
		g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
		g.build_world()
		for i in range(3):await process_frame
		await physics_frame;await physics_frame
		var plan=DistrictLayout.read_plan(index)
		var cam=Camera3D.new();root.add_child(cam);cam.fov=65.;cam.current=true
		var n=0
		for boat in plan.get("boats",[]):
			var c=Vector3(boat[0],0.,boat[1]);var yaw=float(boat[3]);var gap=int(boat[6])
			var side=Basis(Vector3.UP,yaw)*Vector3(0,0,gap if gap!=0 else 1)
			cam.global_position=c+side*4.6+Vector3(0,2.3,0)+Basis(Vector3.UP,yaw)*Vector3(2.5,0,0);cam.look_at(c+Vector3(0,.4,0))
			# reachable: a ray straight down at the gap lands on the deck (not water)
			var probe=c+side*.4+Vector3.UP*2.;var hit=g.ray(probe,probe+Vector3.DOWN*4.,[],1)
			print("WATERBOAT map %d %s boardable=%s deck_hit=%s"%[index,boat[4],str(boat[5]),str(snappedf(hit.position.y,.01)) if not hit.is_empty() else "none"])
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"map%02d_boat%d.png"%[index,n]);n+=1
		var s=0
		for poly in plan.get("shallow",[]):
			var cx=0.;var cz=0.
			for p in poly:cx+=p[0];cz+=p[1]
			cx/=poly.size();cz/=poly.size()
			cam.global_position=Vector3(cx+.5,6.,cz+2.5);cam.look_at(Vector3(cx,-.3,cz))
			print("WATERSHALLOW map %d at %.1f,%.1f shallow()=%s fatal()=%s deep()=%s"%[index,cx,cz,str(g.arena.shallow(Vector3(cx,-.3,cz))),str(g.arena.fatal_water(Vector3(cx,-.3,cz))),str(g.arena.deep_water(Vector3(cx,-.3,cz)))])
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"map%02d_shallow%d.png"%[index,s]);s+=1
		cam.queue_free();g.queue_free()
		for i in range(4):await process_frame
	print("WATER_REVIEW_OK");quit()
