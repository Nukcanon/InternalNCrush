extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-"+name+".png")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	await capture("menu")
	g.ui.settings();await capture("settings")
	g.ui.practice_menu();await capture("practice")
	g.ui.menu();g.host_game();g.start_match();g.clock=100
	var a=g.actors[1];var p=g.players[1];a.position=Vector3(43,0,77);a.reset_view(0)
	g.add_player(-1,"TARGET","target");g.spawn(-1);g.actors[-1].position=Vector3(43,0,67);g.actors[-1].set_team(1-p.team);g.players[-1].team=1-p.team
	for i in range(30):a.visual(.016,p,g.clock);g.actors[-1].visual(.016,g.players[-1],g.clock)
	g.ui.refresh();await capture("rifle")
	a.input_state.ads=true
	for i in range(30):a.visual(.016,p,g.clock)
	g.ui.refresh();await capture("ads")
	p.primary="r2";g.equip_ammo(p)
	for i in range(30):a.visual(.016,p,g.clock)
	g.ui.refresh();await capture("scope")
	a.input_state.ads=false;p.primary="e1";p.reload_started=99;p.reload=101.5
	for i in range(30):a.visual(.016,p,g.clock)
	g.ui.refresh();await capture("reload")
	p.reload=0.;p.primary="a1";g.ui.gear();await capture("gear")
	g.ui.gear_class.select(3);g.ui.refresh_weapons();await capture("engineer")
	g.ui.clear_panel();g.leave_game();g.queue_free();await process_frame;quit()
