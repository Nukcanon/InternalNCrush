extends SceneTree
# Screenshots of map spots: args <map> x,z[,y] ... (world coordinates); the
# camera stands 10 m away at eye height looking at each spot, from two sides.
var g:Node
var out="res://../validation/spots/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var args=OS.get_cmdline_user_args()
	if args.size()<2:print("usage: <map> x,z ...");quit();return
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=int(args[0])
	g.build_world()
	for i in range(3):await process_frame
	await physics_frame
	var cam=Camera3D.new();root.add_child(cam);cam.fov=75.;cam.current=true
	for k in range(1,args.size()):
		var parts=str(args[k]).split(",")
		if parts.size()<2:continue
		var target=Vector3(float(parts[0]),float(parts[2]) if parts.size()>2 else 2.5,float(parts[1]))
		var n=0
		for off in [Vector3(0,0,10),Vector3(10,0,0),Vector3(0,0,-10),Vector3(-10,0,0)]:
			var from=target+off;from.y=1.6
			cam.global_position=from;cam.look_at(target)
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"map%02d_%s_%d.png"%[int(args[0]),str(args[k]).replace(",","_").replace("-","m"),n]);n+=1
	print("SPOTS_OK");quit()
