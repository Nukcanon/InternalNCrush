extends SceneTree
# 1.5.4 (the user: the settings tabs had no bottom edge): the settings screen's tab row.
# Output validation/settings-tabs.jpg
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(30):await process_frame
	g.ui.settings()
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();var s=img.get_size()
	img.get_region(Rect2i(int(s.x*.15),0,int(s.x*.7),int(s.y*.45))).save_jpg("res://../validation/settings-tabs.jpg",.9)
	print("TABS_DONE");quit()
