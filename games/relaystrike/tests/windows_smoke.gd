extends SceneTree
var g:Node
var output=""
func _initialize():call_deferred("run")
func capture(label:String):
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run():
	output=ProjectSettings.globalize_path("res://../../validation/windows")
	DirAccess.make_dir_recursive_absolute(output)
	g=load("res://scripts/game.gd").new();root.add_child(g)
	await create_timer(5.).timeout
	await capture("menu-live")
	var live=g.ui.background.get_child(0)
	print("WINDOWS_MENU_LIVE bots=",live.match_game.players.size()," clock=",live.match_game.clock," render=",RenderingServer.get_video_adapter_name())
	g.ui.settings();await capture("settings")
	g.ui.menu();await create_timer(1.).timeout
	g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=7;g.build_world();g.add_player(1,"PLAYER","windows_smoke_local")
	for i in range(1,7):g.add_player(-i,"BOT %d"%i,"smoke_bot_"+str(i));g.players[-i].role=i-1;g.players[-i].team=i%2
	g.start_match();g.set_physics_process(false);g.clock=100.;g.ui.stats.visible=false
	for index in [7,9,16,17]:
		g.options.map_random=false;g.options.map=index;g.build_world();await physics_frame;await physics_frame
		var a=g.actors[1];a.position=Vector3(0,.1,g.arena.bounds.y*.50);a.reset_view(0);a.set_local(true)
		for i in range(1,7):
			var other=g.actors[-i];other.position=Vector3((i-3.5)*2.,.1,a.position.z-7.-abs(i-3.5));other.reset_view(PI);g.players[-i].protect=0.;other.visual(.1,g.players[-i],100.)
		for frame in range(20):a.visual(.016,g.players[1],100.)
		g.ui.refresh();g.ui.stats.visible=false;await capture("map"+str(index))
		if index==7:
			var device=Node3D.new();g.add_child(device);device.position=Vector3(1.9,0,a.position.z-4.);CombatFX.device(device,"turret",0)
			for phase in [0.,.25,.5,.75]:
				for i in range(1,7):
					for frame in range(8):g.actors[-i].character.update_pose(.016,Vector3(0,0,-8),true,false,true,0,-1,0,phase,1.4)
				await capture("motion"+str(phase))
			device.queue_free()
	var source=-1;var victim=g.actors[1];var attacker=g.actors[source]
	attacker.position=Vector3(0,.1,0);attacker.aim_yaw=PI;attacker.aim_pitch=0.;g.players[source].alive=true;g.players[1].alive=true
	for i in range(65):
		attacker.position.x=sin(i*.05)*.6;g.players[source].shot_time=i*.05;g.kill_replay.capture(.05)
		g.kill_replay.history.back().time=Time.get_ticks_msec()/1000.-3.25+i*.05
	g.players[1].alive=false
	var kill={"attacker":source,"attacker_name":"BOT 1","attacker_team":1,"victim":1,"victim_name":"PLAYER","victim_team":0,"weapon":"a1","critical":true,"origin":attacker.position,"victim_pos":victim.position}
	g.kill_event(kill);await create_timer(.8).timeout;await capture("kill-replay-first-person")
	print("WINDOWS_REPLAY active=",g.kill_replay.active)
	await create_timer(2.).timeout;await capture("kill-replay-portrait")
	await create_timer(1.).timeout
	print("WINDOWS_REPLAY_FINISHED=",not g.kill_replay.active)
	g.players[1].alive=true;g.ui.refresh();await capture("compact-killfeed")
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
