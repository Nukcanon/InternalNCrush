extends SceneTree
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(1000,640));root.size=Vector2i(1000,640);Catalog.load_all()
	for index in range(2):
		var role=[1,5][index];var preview=EquipmentPreview.new();root.add_child(preview);preview.position=Vector2(index*500,0);preview.size=Vector2(500,640);preview.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		preview.display(0,role,0,Catalog.first(role));preview.camera.position=Vector3(.2,1.4,-4);preview.camera.look_at(Vector3(0,1.25,0));preview.camera.size=1.45
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/v113-female-front.png")
	for index in range(2):
		var preview=root.get_child(index);preview.model.rotation.y=PI/2
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/v113-female-side.png")
	quit()
