extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.local_id=1;g.dedicated=true;g.phase="lobby";g.options=Rules.default_options();g.options.map_random=false
	await process_frame;await process_frame
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false
	for id in [1,2,-1,-2]:g.add_player(id,"Test "+str(id),"test"+str(id))
	expect(g.options.bot_difficulty==2 and g.bot_agents[-1].difficulty==2,"new rooms default to hard bots")
	expect(not BotSettings.change(g,2,{"player_id":-1,"difficulty":0}),"guest cannot change bots")
	expect(not BotSettings.change(g,1,{"player_id":2,"role":3}),"bot controls cannot modify humans")
	expect(not BotSettings.change(g,1,{"player_id":-1,"role":99}),"invalid role rejected")
	expect(BotSettings.change(g,1,{"player_id":-1,"difficulty":0,"role":2}),"host can edit one bot before start")
	expect(g.players[-1].role==2 and g.bot_agents[-1].difficulty==0 and g.bot_agents[-2].difficulty==2,"per-bot independence")
	g.phase="combat";g.players[-1].alive=true;g.players[-1].hp=31.;g.players[-1].mag.h1=7
	expect(BotSettings.change(g,1,{"player_id":-1,"role":4}),"combat role request accepted")
	expect(g.players[-1].role==2 and g.players[-1].bot_role==4 and g.players[-1].hp==31. and g.players[-1].mag.h1==7,"role request cannot refill live bot")
	g.players[-1].alive=false;BotSettings.apply_role(g,-1)
	expect(g.players[-1].role==4,"queued role applied at spawn boundary")
	g.ui.show_hud();var board=g.ui.scoreboard
	board.toggle();await process_frame
	expect(board.pinned and board.shown() and not g.pointer_input_active(),"host scoreboard stays open and blocks aim")
	var release=InputEventKey.new();release.physical_keycode=KEY_TAB;release.pressed=false;board._input(release)
	expect(board.pinned,"Tab release does not close host board")
	var press=InputEventKey.new();press.physical_keycode=KEY_TAB;press.pressed=true;board._input(press)
	expect(not board.pinned,"second Tab press closes host board")
	board.toggle();board.refresh_scores(1.);await process_frame
	expect(board.find_children("BotDifficulty","OptionButton",true,false).size()==2,"each bot has its own dropdown")
	expect(board.z_index>0 and board.get_parent()==g.ui.root,"records render above mobile HUD")
	if "--capture" in OS.get_cmdline_user_args():
		root.size=Vector2i(960,540);DisplayServer.window_set_size(Vector2i(960,540));g.ui.scale_interface()
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/bot-settings-mobile.png")
	if is_instance_valid(g.touch):
		expect(not g.touch.active(),"mobile game controls inactive under pinned records")
		var outside=InputEventScreenTouch.new();outside.index=7;outside.pressed=true;outside.position=Vector2.ZERO;board._input(outside)
		expect(not board.pinned,"mobile outside touch dismisses records")
		g.touch.press("score",true);g.touch.press("score",false)
		expect(board.pinned,"mobile records tap remains open after release")
	g.ui.make_panel("Settings")
	expect(not board.pinned and not board.visible,"opening a menu closes records")
	print("BOT_SETTINGS ",checks," checks / ",failures," failures")
	g.queue_free();await process_frame;quit(1 if failures else 0)
