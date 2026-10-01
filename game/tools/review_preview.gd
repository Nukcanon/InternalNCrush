extends SceneTree
# Renders the equipment preview (shop thumbnail) of a weapon to a PNG.
# Args: weapon ids (default: remote). Output: validation/previews/<id>.png
var out="res://../validation/previews/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	var ids:Array=OS.get_cmdline_user_args()
	if ids.is_empty():ids=["remote"]
	root.size=Vector2i(900,600);DisplayServer.window_set_size(Vector2i(900,600))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false)
	for wid in ids:
		var layer=CanvasLayer.new();layer.layer=120;root.add_child(layer)
		var back=ColorRect.new();back.color=Color("e8eef2");back.position=Vector2(40,40);back.size=Vector2(440,330);layer.add_child(back)
		var box=PanelContainer.new();box.position=Vector2(40,40);box.size=Vector2(440,330);layer.add_child(box)
		var preview=EquipmentPreview.new();box.add_child(preview)
		await process_frame
		preview.display(1,0,0,str(wid))
		preview.fit_frame()
		for i in range(8):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().get_region(Rect2i(40,40,440,330)).save_png(out+str(wid)+".png")
		layer.queue_free()
		await process_frame
	print("PREVIEW_OK");quit()
