extends SceneTree
# 1.4.7: the "전투 준비 중…" cover at a bot match start - white, larger, and
# covering the whole window (no bar). Saves the first covered frame. Run windowed.
var out="res://../validation/start-cover/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.start_bot_match({"role":0,"primary":"a1","secondary":"pistol","armor":0,"gadget":1,"team":-1})
	for i in range(900):
		await RenderingServer.frame_post_draw
		if is_instance_valid(g.start_cover):
			root.get_texture().get_image().save_png(out+"cover.png")
			print("START_COVER saved frame %d size %s"%[i,str(root.get_visible_rect().size)])
			break
		await process_frame
	quit()
