extends SceneTree
# Rendered menus on a phone (2400x1080, touch) and a 4:3 monitor (1024x768).
const OUT="res://../validation/screens-v14/"
var g:Node
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	TouchControls.supported_cache=1
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	for setup in [["phone",Vector2i(2400,1080),1],["4x3",Vector2i(1024,768),0]]:
		TouchControls.supported_cache=setup[2]
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO
		root.size=setup[1];DisplayServer.window_set_size(setup[1])
		for i in range(4):await process_frame
		g.ui.scale_interface()
		var ui=g.ui
		ui.menu();await shot(setup[0]+"-menu")
		ui.practice_menu();await shot(setup[0]+"-bot-battle")
		ui.confirm_navigation(func():pass,"메인메뉴");await shot(setup[0]+"-confirm")
		ui.navigation_confirm.queue_free();ui.navigation_confirm=null
		ui.bot_setup=true;ui.bot_choice={"role":0,"primary":"a1","secondary":"pistol","armor_max":0,"gadget":0,"team":0};ui.gear();await shot(setup[0]+"-loadout")
		ui.bot_setup=false;ui.menu()
		ui.settings();await shot(setup[0]+"-settings")
		ui.menu()
	quit()
