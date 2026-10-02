extends SceneTree
# 1.4.10 previews: barred railings and the drowning sign at deep water, the lane
# walls out of a spawn, a boat's bow. validation/v150/<name>.jpg. Run windowed.
var g:Node
var out="res://../validation/v150/"
func _initialize():call_deferred("run")
func shoot(name:String,from:Vector3,at:Vector3):
	var cam=Camera3D.new();root.add_child(cam);cam.fov=70.;cam.global_position=from;cam.look_at(at);cam.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(out+name+".jpg",.85);cam.queue_free();print("SHOT ",name)
func load_map(index:int):
	g.options.map=index;g.build_world()
	for i in range(3):await process_frame
	await physics_frame
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	# 1) deep water: a sign and the railing behind it
	await load_map(5)
	var plan=DistrictLayout.read_plan(5)
	var sign_at=Vector3.INF
	for p in plan.get("props",[]):
		if p.size()>4 and str(p[4])=="warning_sign":sign_at=Vector3(p[0],float(p[2]),p[1]);break
	if sign_at!=Vector3.INF:
		var rail=plan.railings[0];var best=INF
		for r in plan.railings:
			var mid=Vector3((r[0]+r[2])*.5,0,(r[1]+r[3])*.5);var d=mid.distance_to(Vector3(sign_at.x,0,sign_at.z))
			if d<best:best=d;rail=r
		var n=Vector3(rail[6],0,rail[7]).normalized()
		await shoot("sign_railing",sign_at+n*3.2+Vector3.UP*1.6+Vector3(n.z,0,-n.x)*1.2,sign_at+Vector3.UP*1.2)
		await shoot("railing_close",sign_at+n*1.6+Vector3.UP*1.5,sign_at-n*.3+Vector3.UP*.9+Vector3(n.z,0,-n.x)*2.5)
	# a boat's bow
	if not plan.get("boats",[]).is_empty():
		var b=plan.boats[0];var yaw=float(b[3]);var fwd=Vector3(cos(yaw),0,-sin(yaw))
		var bow=Vector3(b[0],b[2]+.4,b[1])+fwd*5.
		await shoot("boat_bow",bow+fwd*3.+Vector3(-fwd.z,0,fwd.x)*2.+Vector3.UP*1.4,bow)
	# 2) the lane walls out of a spawn
	for index in [7,13]:
		await load_map(index)
		var lp=DistrictLayout.read_plan(index)
		if lp.get("baffles",[]).is_empty():continue
		var b=lp.baffles[0];var s=Vector3(lp.spawns[0][0],1.6,lp.spawns[0][1])
		var wall=Vector3(b[0],1.6,b[2])
		await shoot("lane_walls_%02d"%index,s+(s-wall).normalized()*2.,wall)
	print("V150_DONE");quit()
