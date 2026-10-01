extends SceneTree
# 1.4.5: can a team see the enemy spawn from its own spawn? For every map the
# rays between the spawn points (eye height) are tested; maps with any clear
# line are listed, with a screenshot from the blue spawn looking at orange.
# Args: optional map indices; "shots" saves screenshots for every map.
var g:Node
var out="res://../validation/spawn-los/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var args=OS.get_cmdline_user_args();var ids=[]
	for a in args:
		if a.is_valid_int():ids.append(int(a))
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	var count=32
	if ids.is_empty():
		for i in range(count):ids.append(i)
	var report=[]
	for index in ids:
		g.options.map=index
		g.build_world()
		for i in range(3):await process_frame
		await physics_frame
		if not is_instance_valid(g.arena) or g.arena.spawn_points.size()<2:continue
		var clear=0;var total=0;var worst=INF;var sample=[]
		for team in range(2):
			for s in g.arena.spawn_points[team]:
				for t in g.arena.spawn_points[1-team]:
					var from:Vector3=s+Vector3.UP*1.6;var to:Vector3=t+Vector3.UP*1.6
					total+=1
					if g.clear_line(from,to,[]):
						clear+=1;worst=minf(worst,from.distance_to(to))
						if sample.size()<2:sample.append([from.snapped(Vector3.ONE*.1),to.snapped(Vector3.ONE*.1)])
		print("SPAWN_LOS map %d clear %d/%d nearest %.0f m %s"%[index,clear,total,worst if clear>0 else 0.,str(sample)])
		report.append({"map":index,"clear":clear,"total":total})
		if clear>0 or "shots" in args:
			var cam=Camera3D.new();root.add_child(cam);cam.fov=70.
			var from:Vector3=g.arena.spawn_points[0][0]+Vector3.UP*1.6;var to:Vector3=g.arena.spawn_points[1][0]+Vector3.UP*1.6
			cam.global_position=from;cam.look_at(to);cam.current=true
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"map%02d.png"%index)
			cam.queue_free()
	print("SPAWN_LOS_DONE ",JSON.stringify(report))
	quit()
