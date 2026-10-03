extends SceneTree
# 1.5.4 (the user: some sliding doors have no room for their leaves): every map's doors are
# classified (Arena.classify_doors) and the hinged ones photographed shut, half and fully open
# from both sides. Args: --maps=a,b (default all). Output validation/doors/*.jpg + counts.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	var indices=range(Rules.MAPS.size()-1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			indices=[]
			for e in arg.trim_prefix("--maps=").split(","):indices.append(int(e))
	DirAccess.make_dir_recursive_absolute("res://../validation/doors/")
	var shots=0;var total_hinged=0;var total=0
	for index in indices:
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		for i in range(2):await physics_frame
		var hinged=arena.classify_doors();total_hinged+=hinged;total+=arena.doors.size()
		print("DOORS map %d: %d of %d hinged"%[index,hinged,arena.doors.size()])
		if hinged>0 and shots<6:
			var light=DirectionalLight3D.new();light.rotation=Vector3(-.9,.6,0);arena.add_child(light)
			var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("9cc4e4");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.75,.75,.75);arena.add_child(env)
			var cam=Camera3D.new();arena.add_child(cam);cam.current=true;cam.fov=70
			for door in arena.doors.values():
				if not door.swing:continue
				var frames=[]
				for state in [[0.,1.],[.5,1.],[1.,1.],[1.,-1.]]:
					door.progress=state[0];door.swing_dir=state[1];door.apply_pose()
					var face=1. if state[1]>0. else -1.
					cam.global_position=door.global_transform*Vector3(1.2,2.1,-4.6*face);cam.look_at(door.global_position+Vector3.UP*1.3)
					for i in range(3):await process_frame
					await RenderingServer.frame_post_draw
					var img=root.get_texture().get_image();img.resize(640,360);frames.append(img)
				var sheet=Image.create(1280,720,false,frames[0].get_format())
				for i in range(4):sheet.blit_rect(frames[i],Rect2i(0,0,640,360),Vector2i((i%2)*640,(i/2)*360))
				sheet.save_jpg("res://../validation/doors/map%02d_door%d.jpg"%[index,door.door_id],.85);shots+=1
				break
		arena.free();await process_frame
	print("DOORS_TOTAL %d of %d hinged"%[total_hinged,total])
	print("DOORS_DONE");quit()
