extends SceneTree
# 1.4 map review: an orthographic overview and a player-height view per map.
# Args after "--": map indices (default: all regular maps).
const OUT="res://../validation/maps-v14/"
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,960);DisplayServer.window_set_size(root.size)
	Catalog.load_all()
	var indices=[]
	for arg in OS.get_cmdline_user_args():indices.append(int(arg))
	if indices.is_empty():indices=range(19)
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby"
	for index in indices:
		g.options.map_random=false;g.options.map=index;g.options.mode=0;g.build_world()
		for i in range(3):await physics_frame
		g.ui.hide_hud() if g.ui.has_method("hide_hud") else null
		var arena:Node3D=g.arena
		var camera=Camera3D.new();root.add_child(camera);camera.current=true
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(arena.bounds.x,arena.bounds.y)*2.1
		camera.position=Vector3(0,120,0.01);camera.look_at(Vector3.ZERO,Vector3.FORWARD);camera.far=400
		await shot("map-%02d-top"%index)
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=70
		var spawn:Vector3=arena.spawn_points[0][0] if not arena.spawn_points[0].is_empty() else Vector3.ZERO
		camera.position=spawn+Vector3(0,1.6,0);camera.look_at(Vector3(0,1.4,0) if spawn.length()>2 else Vector3(0,1.4,-10))
		await shot("map-%02d-eye"%index)
		camera.position=Vector3(arena.bounds.x*.55,28,arena.bounds.y*.55);camera.look_at(Vector3.ZERO)
		await shot("map-%02d-angle"%index)
		# Street view: face the longest ordinary front from across the street.
		var plan=DistrictLayout.read_plan(index);var best=[];var best_len=0.
		for f in plan.get("fronts",[]):
			var length=Vector2(f[2]-f[0],f[3]-f[1]).length()
			if int(f[9])&3!=0 or length<=best_len or absf(float(f[4])-float(f[5]))>.2:continue
			var fu=Vector3(f[0],f[4],f[1]);var fd=(Vector3(f[2],f[5],f[3])-fu).normalized();var fn=Vector3(-fd.z,0,fd.x)
			var standing=(fu+Vector3(f[2],f[5],f[3]))*.5+fn*9.
			var levels=DistrictLayout.heights(arena,standing)
			if levels.is_empty() or absf(float(levels[0])-float(f[4]))>.5:continue
			# The view must see the facade: no prop, tree or wall in between.
			var eye=Vector3(standing.x,float(levels[0])+1.7,standing.z)
			var sight=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,(fu+Vector3(f[2],f[5],f[3]))*.5+Vector3.UP*2.,1))
			if not sight.is_empty() and sight.position.distance_to(eye)<8.4:continue
			var blocked=false
			for node in arena.architecture.get_children():
				if node.has_meta("prop_asset") and Vector2(node.position.x-eye.x,node.position.z-eye.z).length()<3.5:blocked=true
			if blocked:continue
			best=f;best_len=length
		if not best.is_empty():
			var u=Vector3(best[0],best[4],best[1]);var v=Vector3(best[2],best[5],best[3]);var d=(v-u).normalized();var n=Vector3(-d.z,0,d.x)
			var mid=(u+v)*.5
			camera.fov=75;camera.position=mid+n*9.+Vector3.UP*1.7;camera.look_at(mid+Vector3.UP*3.2)
			await shot("map-%02d-street"%index)
			for back in [16.,13.,11.]:
				var eye=mid+n*back
				var levels=DistrictLayout.heights(arena,eye)
				if levels.is_empty() or absf(float(levels[0])-mid.y)>.6 or not arena.point_clear(Vector3(eye.x,float(levels[0]),eye.z)):continue
				camera.position=Vector3(eye.x,float(levels[0])+2.,eye.z)+d*3.;camera.look_at(mid+Vector3.UP*3.-d*2.)
				break
			await shot("map-%02d-street2"%index)
		camera.queue_free()
		print("MAP_REVIEW ",index," bounds=",arena.bounds," spawns=",arena.spawn_points[0].size(),"/",arena.spawn_points[1].size()," zones=",arena.zones.size())
	print("MAP_REVIEW_OK");quit()
