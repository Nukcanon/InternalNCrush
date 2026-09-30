extends SceneTree
# 1.5 map review: builds a map through the game, checks it and takes views.
#  * cover: planned blueprint props vs props actually placed (rejects listed)
#  * routes: bot navigation from each spawn to every objective and the other spawn
#  * views: top, and eye-level views at stairs, terraces, trenches, covered rooms
#    and objectives found in the blueprint grid.
# Args: map indices. Output: validation/maps-v15/.
const OUT="res://../validation/maps-v15/"
var g:Node
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(960,600);DisplayServer.window_set_size(root.size)
	Catalog.load_all()
	var indices=[]
	for arg in OS.get_cmdline_user_args():indices.append(int(arg))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby"
	# Review at the default (medium) preset regardless of this machine's profile.
	g.profile.graphics_auto=false;g.profile.merge(GraphicsOptions.PRESETS[1],true);GraphicsOptions.apply(g)
	for index in indices:
		g.options.map_random=false;g.options.map=index;g.options.mode=4 if DefusalLayout.enabled(index) else 0;g.build_world()
		for i in range(3):await physics_frame
		var arena:Node3D=g.arena
		var plan=DistrictLayout.read_plan(index)
		var placed=0
		for node in arena.architecture.get_children():
			if node.has_meta("prop_asset"):placed+=1
		var planned=plan.props.size()+plan.get("trees",[]).size()
		print("V15_REVIEW %d props placed %d / planned %d"%[index,placed,planned])
		# Routes (bot navigation graph).
		var nav=BotNavigation.new();nav.build(arena)
		var starts=[arena.spawn_points[0][0],arena.spawn_points[1][0]]
		var failures=[]
		for s in starts:
			for goal in arena.zones+[starts[0],starts[1]]:
				var a=nav.layers.get_closest_point(s);var b=nav.layers.get_closest_point(goal)
				var route=nav.layers.get_point_path(a,b)
				if route.is_empty():failures.append("%s->%s"%[s,goal])
		print("V15_ROUTES %d unreachable=%d %s"%[index,failures.size(),str(failures.slice(0,3))])
		# Views.
		var camera=Camera3D.new();root.add_child(camera);camera.current=true
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(arena.bounds.x,arena.bounds.y)*2.1
		camera.position=Vector3(0,120,.01);camera.look_at(Vector3.ZERO,Vector3.FORWARD);camera.far=400
		await shot("%02d-top"%index)
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=72;camera.far=500
		var grid:Array=plan.get("grid",[]);var cell=float(plan.get("cell",4.))
		var half=Vector2(plan.dimensions[0],plan.dimensions[1])*.5
		var wanted={"/":"stairs","^":"terrace","v":"trench",":":"room","A":"objective-a","C":"objective-c","S":"spawn","T":"spawn-t","D":"spawn-d","B":"objective-b","w":"cover-wall","c":"cover-crates","s":"cover-sandbags","o":"cover-container"}
		var taken={}
		for r in range(grid.size()):
			for c in range(grid[r].length()):
				var ch=grid[r][c]
				if not wanted.has(ch) or taken.has(ch):continue
				taken[ch]=true
				var x=(c+.5)*cell-half.x;var z=(r+.5)*cell-half.y
				var levels=DistrictLayout.heights(arena,Vector3(x,0,z))
				var y=float(levels[0]) if not levels.is_empty() else 0.
				# Stand a few cells away on walkable ground and look at the feature.
				var best=Vector3(x,y+1.7,z+8.);var best_score=-1.
				for dir in [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0),Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
					for dist in [14.,10.,7.]:
						var p=Vector3(x+dir.x*dist,0,z+dir.y*dist)
						var h=DistrictLayout.heights(arena,p)
						if h.is_empty():continue
						var eye=Vector3(p.x,float(h[0])+1.7,p.z)
						var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,Vector3(x,y+1.,z),1))
						var score=dist+(10. if hit.is_empty() else 0.)
						if score>best_score:best_score=score;best=eye
				camera.position=best;camera.look_at(Vector3(x,y+1.,z))
				await shot("%02d-%s"%[index,wanted[ch]])
		# First interactive door, seen from 7 m down its corridor.
		if not arena.doors.is_empty():
			var door=arena.doors.values()[0]
			camera.position=door.global_position+door.basis*Vector3(0,1.7,7.);camera.look_at(door.global_position+Vector3.UP*1.4)
			await shot("%02d-door"%index)
		camera.queue_free()
	print("V15_REVIEW_OK");quit()
