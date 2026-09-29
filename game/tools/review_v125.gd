extends SceneTree
const OUT="res://../validation/v125/"
func _initialize():call_deferred("run")
func capture(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	root.size=Vector2i(1100,800);DisplayServer.window_set_size(root.size);DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(1100,800)
	for web in [false,true]:
		ProjectSettings.set_setting("application/config/web_assets",web)
		for role in ([1,5] if web else range(6)):
			preview.display(0,role,0,Catalog.first(role),0,0)
			# Hero face portraits (the preview already shows the 1.4 hero).
			for angle in [0.,.8,1.57]:
				preview.model.rotation.y=angle;var focus=Vector3(0,1.6*HeroCharacter.HEIGHTS[role]/1.8,0)
				preview.camera.position=focus+Vector3(0,0,-2);preview.camera.look_at(focus);preview.camera.size=.52
				await capture(("web" if web else "native")+"-face"+str(role)+"-"+str(angle))
		ProjectSettings.set_setting("application/config/web_assets",web)
		preview.display(1,0,0,"dual_pistols");await capture(("web" if web else "native")+"-duet")
		for item in [[0,8],[4,0],[4,1],[5,0],[3,0],[2,0]]:
			preview.display(2,item[0],0,"a1",item[1]);await capture(("web" if web else "native")+"-gadget-%d-%d"%[item[0],item[1]])
	preview.free();print("V125_REVIEW_OK");quit()
