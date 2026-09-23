extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func capture(name:String):
	for frame in range(6):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-v05-"+name+".png")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	g.profile.nick="닉네임";g.last_server_ip="";g.ui.menu();await capture("menu")
	g.version_check.state="newer";g.version_check.latest="0.6.0";g.ui.update_version_badge();await capture("update")
	g.ui.settings();var tabs=g.ui.panel.find_children("*","TabContainer",true,false)[0];tabs.current_tab=1;await capture("sound")
	tabs.current_tab=2;await capture("controls")
	g.ui.host_settings();await capture("host")
	g.server=true;g.phase="lobby";g.build_world();g.add_player(1,"닉네임","visual_local_token");g.players[1].team=0
	for i in range(1,12):g.add_player(-i,"BOT %02d"%i,"visual"+str(i));g.players[-i].team=i%2;g.players[-i].role=i%6
	g.add_player(200,"닉네임","visual_other_1234");g.add_player(201,"닉네임","visual_other_1235")
	g.ui.lobby();await capture("lobby");g.ui.members_menu();g.start_kick_vote(1,201);g.ui.refresh();await capture("vote");g.vote.clear()
	g.phase="combat";g.clock=100;g.ui.show_hud();g.ui.gear();await capture("gear")
	g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("weapon")
	g.ui.clear_panel();g.ui.hud.visible=true
	for index in range(6):
		g.options.map=index;g.build_world();await physics_frame;await physics_frame
		var a=g.actors[1];a.position=Vector3(0,0,72) if index in [2,3] else Vector3(22,0,28);a.reset_view(0);a.camera.current=true
		for i in range(1,12):
			var actor=g.actors[-i];actor.position=a.position+Vector3((i%4-1.5)*3,0,-8-floor(i/4.)*6);actor.reset_view(PI);g.players[-i].protect=0.;actor.visual(.016,g.players[-i],100.)
		g.players[1].protect=0.;a.visual(.016,g.players[1],100.);g.ui.refresh();await capture("map"+str(index))
		if index==5:
			g.fields=[{"kind":"smoke","pos":Vector3(0,0,0),"until":115.,"team":0},{"kind":"slow","pos":a.position+Vector3(0,0,-12),"until":115.,"team":0}];g.update_world_visuals(.1);await capture("effects")
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
