extends SceneTree
# 1.5.4 (the user): every map's map-view with the starting points (larger, labelled Blue /
# Orange). Output validation/map-spawns/maps_<n>.jpg, six maps per sheet.
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(1200,780));root.size=Vector2i(1200,780)
	DirAccess.make_dir_recursive_absolute("res://../validation/map-spawns/")
	var names=Rules.MAPS
	for sheet in range(6):
		for child in root.get_children():
			if child is Control:child.queue_free()
		await process_frame
		for k in range(6):
			var index=sheet*6+k
			if index>30:break
			var view=MapPlanView.new();view.interactive=true;root.add_child(view)
			view.position=Vector2((k%3)*400,(k/3)*390);view.size=Vector2(396,360);view.select_map(index)
			var title=Label.new();title.text="%d · %s"%[index,names[index]];title.position=view.position+Vector2(8,362);title.add_theme_font_size_override("font_size",16);root.add_child(title)
		for i in range(6):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("res://../validation/map-spawns/maps_%d.jpg"%sheet,.88)
	print("MAPS_DONE");quit()
