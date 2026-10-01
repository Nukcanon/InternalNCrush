extends SceneTree
# 1.4.5: the redesigned bipod - the support gadget (equipment preview, two
# turns) and folded under ANCHOR / BASTION.
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(640,480));root.size=Vector2i(640,480)
	Catalog.load_all();var out="res://../validation/v145-bipod/";DirAccess.make_dir_recursive_absolute(out)
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(640,480);preview.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var jobs=[["gadget-a",2,2,"",0,0.],["gadget-b",2,2,"",0,1.6],["h1",1,0,"h1",0,0.],["h2",1,0,"h2",0,0.],["h1-under",1,0,"h1",0,-.9]]
	for j in jobs:
		preview.display(j[1],j[2],0,j[3],j[4]);preview.model.rotation.y+=j[5]
		if j[0]=="h1-under":preview.model.rotation.x=.5
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		preview.viewport.get_texture().get_image().save_png(out+j[0]+".png")
	print("BIPOD_OK");quit()
