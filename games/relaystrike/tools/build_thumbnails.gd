extends SceneTree
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(512,320));root.size=Vector2i(512,320)
	Catalog.load_all();DirAccess.make_dir_recursive_absolute("res://assets/thumbnails")
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(512,320);preview.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var jobs=[]
	for id in Catalog.weapons:jobs.append([id,1,0,id,0])
	for role in range(6):
		jobs.append(["role"+str(role),0,role,Catalog.first(role),0])
		for variant in range(3 if role==3 else 2 if role==4 else 1):jobs.append(["gadget"+str(role)+"_"+str(variant),2,role,Catalog.first(role),variant])
		jobs.append(["skill"+str(role),4,role,Catalog.first(role),0])
	for variant in range(3):jobs.append(["armor"+str(variant),3,0,"a1",variant])
	for job in jobs:
		preview.display(job[1],job[2],0,job[3],job[4])
		if job[1]==0:preview.camera.position=Vector3(.2,1.40,-4);preview.camera.look_at(Vector3(0,1.25,0));preview.camera.size=1.15
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var image=preview.viewport.get_texture().get_image();image.resize(320,200,Image.INTERPOLATE_LANCZOS);image.save_png("res://assets/thumbnails/"+job[0]+".png")
	print("THUMBNAILS_BUILT ",jobs.size());quit()
