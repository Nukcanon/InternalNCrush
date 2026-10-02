extends SceneTree
# 1.4.6: the first moments after entering the practice range (a puff of
# "smoke" was reported) - frames saved to validation/practice-start/.
var out="res://../validation/practice-start/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(960,540);DisplayServer.window_set_size(Vector2i(960,540))
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	PracticeSession.start(g)
	var t0=Time.get_ticks_msec()
	for f in range(90):
		await process_frame
		if f%6==0 or f<6:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"f%03d_%dms.png"%[f,Time.get_ticks_msec()-t0])
	print("PRACTICE_START_OK");quit()
