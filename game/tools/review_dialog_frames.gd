extends SceneTree
# Frames 1-3 right after a confirmation opens: no resize jump, clean border.
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1600,900);DisplayServer.window_set_size(root.size)
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(30):await process_frame
	g.ui.practice_menu();for i in range(5):await process_frame
	g.ui.confirm_navigation(func():pass,"메인메뉴")
	var frames=[]
	for k in range(3):
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image();image.resize(1600,900);frames.append(image)
		await process_frame
	var strip=Image.create(1600,600*3,false,frames[0].get_format())
	for k in range(3):
		var f:Image=frames[k].get_region(Rect2i(400,300,800,300));f.resize(1600,600);strip.blit_rect(f,Rect2i(0,0,1600,600),Vector2i(0,k*600))
	strip.save_png("res://../validation/ui-v14/dialog-frames.png")
	quit()
