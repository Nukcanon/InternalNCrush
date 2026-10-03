extends SceneTree
# 1.5.4 (the user: open the water to the sea, boats far bigger - walk about inside): the big
# boats in the baked maps from the quay and from above, and a deckhouse from inside.
# Output validation/boats/*.jpg and sheet.jpg.
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(960,540));root.size=Vector2i(960,540)
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	DirAccess.make_dir_recursive_absolute("res://../validation/boats/")
	var cam=Camera3D.new();cam.fov=62.;cam.far=600.;var shots=[]
	for index in [0,4,5,13,28]:
		var plan=JSON.parse_string(FileAccess.get_file_as_string("res://assets/arenas/districts/plan_%02d.json"%index))
		var boats:Array=plan.get("boats",[])
		if boats.is_empty():continue
		g.options.map=index;g.build_world()
		for i in range(6):await process_frame
		if not is_instance_valid(cam.get_parent()):g.add_child(cam)
		cam.current=true
		var b=boats[0];var at=Vector3(float(b[0]),0.,float(b[1]));var yaw=float(b[3])
		var along=Basis(Vector3.UP,yaw)*Vector3.RIGHT;var across=Basis(Vector3.UP,yaw)*Vector3.BACK*float(b[6] if int(b[6])!=0 else 1)
		for view in [["quay",at+across*9.+along*-8.+Vector3.UP*2.4,at+Vector3.UP*1.2],["above",at+across*16.+along*-14.+Vector3.UP*13.,at],["inside",at+along*-1.+Vector3.UP*1.6,at+along*-6.+Vector3.UP*1.4]]:
			cam.global_position=view[1];cam.look_at(view[2],Vector3.UP)
			for i in range(4):await process_frame
			await RenderingServer.frame_post_draw
			var img=root.get_texture().get_image();img.save_jpg("res://../validation/boats/map%02d_%s_%s.jpg"%[index,str(b[4]),view[0]],.88)
			img.resize(480,270,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var cols=3;var rows=ceili(shots.size()/float(cols))
	var sheet=Image.create(480*cols,270*rows,false,shots[0].get_format())
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,480,270),Vector2i((i%cols)*480,(i/cols)*270))
	sheet.save_jpg("res://../validation/boats/sheet.jpg",.88)
	print("BOATS_DONE");quit()
