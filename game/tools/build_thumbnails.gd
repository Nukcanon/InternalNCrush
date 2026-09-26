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
		for variant in range(3 if role==3 else 2 if role in [0,4] else 1):jobs.append(["gadget"+str(role)+"_"+str(variant),2,role,Catalog.first(role),variant])
		jobs.append(["gadget"+str(role)+"_8",2,role,Catalog.first(role),8])
		jobs.append(["gadget"+str(role)+"_9",2,role,Catalog.first(role),9])
		jobs.append(["skill"+str(role),4,role,Catalog.first(role),0])
	for variant in range(3):jobs.append(["armor"+str(variant),3,0,"a1",variant])
	var generated=0
	for job in jobs:
		if "--v122" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or str(job[0]).begins_with("armor")):continue
		if "--v121" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or job[0] in ["gadget4_0","gadget4_1","gadget2_0"]):continue
		if "--v119" in OS.get_cmdline_user_args() and FileAccess.file_exists("res://assets/thumbnails/"+str(job[0])+".png") and not (job[0] in ["repair","remote","h4","gadget2_0"] or (Catalog.weapons.has(job[0]) and Catalog.get_weapon(job[0]).slot==1 and Catalog.get_weapon(job[0]).kind=="gun")):continue
		if "--v118" in OS.get_cmdline_user_args() and not (job[0] in ["m1","m3","h4","gadget4_0","gadget4_1"] or str(job[0]).ends_with("_8")):continue
		if "--only-new" in OS.get_cmdline_user_args() and FileAccess.file_exists("res://assets/thumbnails/"+job[0]+".png"):continue
		preview.display(job[1],job[2],0,job[3],job[4])
		if job[1]==1:preview.camera.size*=.65
		if job[1]==0:preview.camera.position=Vector3(.2,1.40,-4);preview.camera.look_at(Vector3(0,1.25,0));preview.camera.size=1.15
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		generated+=1
		var image=preview.viewport.get_texture().get_image();image.resize(320,200,Image.INTERPOLATE_LANCZOS);image.save_png("res://assets/thumbnails/"+job[0]+".png")
	for job in jobs:
		if not FileAccess.file_exists("res://assets/thumbnails/"+str(job[0])+".png"):
			printerr("Missing equipment thumbnail: ",job[0]);quit(1);return
	print("THUMBNAILS_BUILT ",generated," / verified ",jobs.size());quit()
