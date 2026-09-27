extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();root.size=Vector2i(512,320)
	DirAccess.make_dir_recursive_absolute("res://assets/kill_icons")
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(512,320)
	preview.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for id in Catalog.weapons:
		preview.display(1,0,0,id)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var source=preview.viewport.get_texture().get_image();var bounds=source.get_used_rect()
		if bounds.size.x==0:printerr("Empty weapon silhouette: ",id);quit(1);return
		var cropped=source.get_region(bounds);var ratio=minf(124./cropped.get_width(),44./cropped.get_height())
		cropped.resize(maxi(1,roundi(cropped.get_width()*ratio)),maxi(1,roundi(cropped.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
		for y in range(cropped.get_height()):
			for x in range(cropped.get_width()):cropped.set_pixel(x,y,Color(1,1,1,cropped.get_pixel(x,y).a))
		var icon=Image.create(128,48,false,Image.FORMAT_RGBA8)
		icon.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),(Vector2i(128,48)-cropped.get_size())/2)
		icon.save_png("res://assets/kill_icons/"+str(id)+".png")
	preview.free();print("WEAPON_SILHOUETTES_BUILT ",Catalog.weapons.size());quit()
