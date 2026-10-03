extends SceneTree
# 1.5.4 map review: a camera looking at given spots (map;x,y,z;nx,ny,nz per argument) from
# 2.5 m along the face normal. Output validation/spots/<n>.jpg and sheet.jpg.
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(960,540));root.size=Vector2i(960,540)
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	DirAccess.make_dir_recursive_absolute("res://../validation/spots/")
	var shots=[];var built=-1;var cam=Camera3D.new();cam.fov=60.
	for arg in OS.get_cmdline_user_args():
		var parts=str(arg).split(";")
		if parts.size()<3:continue
		var index=int(parts[0]);var p=str_to_var("Vector3("+parts[1]+")");var n=str_to_var("Vector3("+parts[2]+")")
		if index!=built:
			g.options.map=index;g.build_world();built=index
			for i in range(5):await process_frame
			if not is_instance_valid(cam.get_parent()):g.add_child(cam)
		cam.current=true
		var from=p+n*2.5+Vector3.UP*.6+n.cross(Vector3.UP).normalized()*.8 if absf(n.y)<.9 else p+n*2.5+Vector3(1.,0,.6)
		cam.global_position=from;cam.look_at(p,Vector3.UP if absf(n.y)<.9 else Vector3.FORWARD)
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(480,270,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var cols=4;var sheet=Image.create(480*cols,270*ceili(shots.size()/float(cols)),false,Image.FORMAT_RGBA8)
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,480,270),Vector2i((i%cols)*480,(i/cols)*270))
	sheet.save_jpg("res://../validation/spots/sheet.jpg",.88);print("SPOTS_DONE ",shots.size());quit()
