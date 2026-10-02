extends SceneTree
# 1.4.7: what a player sees on spawning (blue team, first spawn point, facing
# Game.open_yaw) - the moved spawns must look onto a way out, not a wall.
# Args: map indices. Run windowed (screenshots hang headless).
var g:Node
var out="res://../validation/spawn-view/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var ids=[]
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():ids.append(int(a))
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	for index in ids:
		g.options.map=index
		g.build_world()
		for i in range(3):await process_frame
		await physics_frame
		if not is_instance_valid(g.arena) or g.arena.spawn_points.size()<2:continue
		for team in range(2):
			var pos:Vector3=g.arena.spawn_points[team][0]
			var usual=atan2(pos.x,pos.z)
			var yaw=g.open_yaw(pos,usual)
			var space=g.get_world_3d().direct_space_state;var eye=pos+Vector3.UP*1.5;var ds=[]
			for k in range(8):
				var y=usual+k*TAU/8.;var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(eye,eye+Vector3(-sin(y),0,-cos(y))*24.,1))
				ds.append("-" if hit.is_empty() else str(snappedf(eye.distance_to(hit.position),.1))+":"+str(hit.collider.name)+"/"+str(hit.collider.get_parent().name))
			print("  reach ",pos.snapped(Vector3.ONE*.1)," ",ds)
			print("SPAWN_VIEW map %d team %d yaw %.2f (usual %.2f)"%[index,team,yaw,usual])
			var cam=Camera3D.new();root.add_child(cam);cam.fov=75.
			cam.global_position=pos+Vector3.UP*1.6;cam.rotation=Vector3(-.05,yaw,0);cam.current=true
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(out+"map%02d_team%d.jpg"%[index,team],.85)
			cam.queue_free()
	print("SPAWN_VIEW_DONE")
	quit()
