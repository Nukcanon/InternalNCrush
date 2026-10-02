extends SceneTree
const FILL=.8
func _initialize():call_deferred("run")
## The pixels of the item (not the transparent background), as a rect.
func content_box(img:Image) -> Rect2:
	var w=img.get_width();var h=img.get_height();var lo=Vector2(w,h);var hi=Vector2(-1,-1)
	for y in range(0,h,2):
		for x in range(0,w,2):
			if img.get_pixel(x,y).a>.1:lo=lo.min(Vector2(x,y));hi=hi.max(Vector2(x,y))
	if hi.x<0:return Rect2()
	return Rect2(lo,hi-lo+Vector2(2,2))
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
		var missing=not FileAccess.file_exists("res://assets/thumbnails/"+str(job[0])+".png")
		if not missing and "--v141" in OS.get_cmdline_user_args() and job[0] not in ["h4","h5"]:continue
		if not missing and "--v125" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or str(job[0]).begins_with("gadget")):continue
		if not missing and "--v124" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or str(job[0]).begins_with("gadget") or (job[1]==1 and Catalog.get_weapon(job[3]).slot==1)):continue
		if not missing and "--v123" in OS.get_cmdline_user_args() and job[0] not in ["role1","role5","dual_pistols"]:continue
		if not missing and "--v122" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or str(job[0]).begins_with("armor")):continue
		if not missing and "--v121" in OS.get_cmdline_user_args() and not (str(job[0]).begins_with("role") or job[0] in ["gadget4_0","gadget4_1","gadget2_0"]):continue
		if not missing and "--v119" in OS.get_cmdline_user_args() and FileAccess.file_exists("res://assets/thumbnails/"+str(job[0])+".png") and not (job[0] in ["repair","remote","h4","gadget2_0"] or (Catalog.weapons.has(job[0]) and Catalog.get_weapon(job[0]).slot==1 and Catalog.get_weapon(job[0]).kind=="gun")):continue
		if not missing and "--v118" in OS.get_cmdline_user_args() and not (job[0] in ["m1","m3","h4","gadget4_0","gadget4_1"] or str(job[0]).ends_with("_8")):continue
		if "--only-new" in OS.get_cmdline_user_args() and FileAccess.file_exists("res://assets/thumbnails/"+job[0]+".png"):continue
		# 1.4.5: gadgets again (the plate card showed the old plate; throwables
		# were small in their cards - the preview now frames items close)
		if not missing and "--v145" in OS.get_cmdline_user_args() and not str(job[0]).begins_with("gadget"):continue
		# 1.4.5 round 4: the new bipod (gadget and the guns carrying one), grenades with the pull ring
		if not missing and "--v145b" in OS.get_cmdline_user_args() and not job[0] in ["h1","h2","gadget2_0","gadget0_1","gadget4_0","gadget4_1"] and not str(job[0]).ends_with("_8"):continue
		# 1.4.6: --only=id,id regenerates just those cards (the TETHER remote pad)
		var only=Array(OS.get_cmdline_user_args()).filter(func(x):return str(x).begins_with("--only="))
		if not only.is_empty() and not str(job[0]) in str(only[0]).trim_prefix("--only=").split(","):continue
		preview.display(job[1],job[2],0,job[3],job[4])
		# (1.4.5: the preview frames items close itself - 1.18x, about the old 1.85x * .65)
		if job[1]==1 and not "--v145b" in OS.get_cmdline_user_args() and job[3]!="remote":preview.camera.size*=.65
		if job[1]==0:preview.camera.position=Vector3(.2,1.40,-4);preview.camera.look_at(Vector3(0,1.25,0));preview.camera.size=1.15
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		# 1.4.6 (the user: some cards - the armour, pistols - were tiny): every
		# item is framed to fill about FILL of its card, centred, with a margin
		# so nothing runs off the card.
		# (the armour card shows the vest: the upper body, turned a little toward the viewer)
		if job[1]==3:
			preview.model.rotation.y=-.3;preview.camera.position=Vector3(0,1.27,-4);preview.camera.look_at(Vector3(0,1.23,0));preview.camera.size=1.08
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
		if not job[1] in [0,3,4]:
			for _pass in range(2):
				var shot=preview.viewport.get_texture().get_image();var box=content_box(shot)
				if box.size==Vector2.ZERO:break
				var fill=maxf(box.size.x/shot.get_width(),box.size.y/shot.get_height())
				if absf(fill-FILL)<.03:break
				var cam:Camera3D=preview.camera;var aspect=float(shot.get_width())/shot.get_height()
				var c=(box.get_center()/Vector2(shot.get_width(),shot.get_height()))-Vector2(.5,.5)
				cam.global_position+=cam.global_basis.x*(c.x*cam.size*aspect)-cam.global_basis.y*(c.y*cam.size)
				cam.size*=fill/FILL
				await process_frame;await process_frame;await RenderingServer.frame_post_draw
		generated+=1
		var image=preview.viewport.get_texture().get_image();image.resize(320,200,Image.INTERPOLATE_LANCZOS);image.save_png("res://assets/thumbnails/"+job[0]+".png")
	for job in jobs:
		if not FileAccess.file_exists("res://assets/thumbnails/"+str(job[0])+".png"):
			printerr("Missing equipment thumbnail: ",job[0]);quit(1);return
	print("THUMBNAILS_BUILT ",generated," / verified ",jobs.size());quit()
