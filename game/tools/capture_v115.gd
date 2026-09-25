extends SceneTree
## Actual bot combat at full HD. Screenshots are generated independently per platform.
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO
	root.scaling_3d_scale=1.;root.size=Vector2i(1920,1080)
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
			var pair=[]
			var viewpoint=Vector3.INF
			for attempt in range(450):
				pair=combat_pair(game)
				if not pair.is_empty():viewpoint=combat_camera(game,pair[0],pair[1],i)
				if viewpoint.is_finite():break
				await create_timer(.1).timeout
			if pair.is_empty() or not viewpoint.is_finite():printerr("No unobstructed active combat available for menu photograph");quit(1);return
			var actor=pair[0];var opponent=pair[1]
			var target=actor.position+Vector3.UP*1.3
			camera.position=viewpoint
			camera.look_at(target.lerp(opponent.position+Vector3.UP*1.1,.55))
			await process_frame;await RenderingServer.frame_post_draw
			var picture=root.get_texture().get_image();number+=1
			if picture.is_empty() or picture.get_size()!=Vector2i(1920,1080) or picture.save_jpg("res://assets/menu_slides/%02d.jpg"%number,.92)!=OK:quit(1);return
			await create_timer(2.).timeout
		game.free();camera.free();await process_frame
	print("MENU_SLIDES_OK count=",number," resolution=1920x1080 style=", "web" if RenderStyle.web() else "native")
	quit()

func combat_pair(game:Node) -> Array:
	var best=[];var nearest=35.
	for id in game.players:
		var p=game.players[id]
		if not p.alive or game.clock-float(p.get("shot_time",-100.))>1.2:continue
		var actor=game.actors[id]
		for other in game.players:
			if other==id or not game.players[other].alive or not game.enemies(p,game.players[other]):continue
			var opponent=game.actors[other];var distance=actor.position.distance_to(opponent.position)
			if distance<3. or distance>=nearest:continue
			if not game.ray(actor.eye(),opponent.eye(),[],1).is_empty():continue
			nearest=distance;best=[actor,opponent]
	return best

func combat_camera(game:Node,actor:Node3D,opponent:Node3D,index:int) -> Vector3:
	var target=actor.eye();var facing=(opponent.position-actor.position).normalized();var side=facing.cross(Vector3.UP)
	var offsets=[-facing*4.+side*2.+Vector3.UP*1.2,-facing*4.-side*2.+Vector3.UP*1.2,side*4.+Vector3.UP,-side*4.+Vector3.UP,-facing*3.+Vector3.UP*.4,facing*2.+side*3.+Vector3.UP*.6]
	for j in range(offsets.size()):
		var candidate=target+offsets[(j+index)%offsets.size()]
		if game.ray(target,candidate,[],1).is_empty() and game.ray(candidate,opponent.eye(),[],1).is_empty():return candidate
	return Vector3.INF
