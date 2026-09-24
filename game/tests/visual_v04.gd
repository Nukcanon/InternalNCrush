extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-"+name+".png")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	g.last_server_ip="192.168.1.100";g.ui.menu();await capture("menu-v040")
	g.ui.host_settings();await capture("host-v040")
	g.server=true;g.phase="lobby";g.build_world();g.add_player(1,"Player","visual_local_token");g.players[1].team=0
	for i in range(1,32):
		g.add_player(-i,"PLAYER %02d"%i,"visual"+str(i));var p=g.players[-i];p.team=i%2;p.role=i%6;p.kills=32-i;p.deaths=i%8;p.assists=i%6;p.objective=i*2
	for id in g.actors:g.actors[id].visual(.016,g.players[id],g.clock)
	g.ui.lobby();await capture("lobby-v040")
	g.phase="combat";g.ui.show_hud();g.ui.refresh();g.ui.scoreboard.visible=true;g.ui.scoreboard.refresh_scores(1.);await capture("score-teams-v040")
	g.options.mode=1;g.ui.scoreboard.refresh_scores(1.);await capture("score-ffa-v040");g.options.mode=0
	g.ui.gear();await capture("gear-v040")
	g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("weapon-preview-v040")
	g.ui.preview_secondary=true;g.ui.refresh_gear_detail();await capture("secondary-preview-v040")
	g.ui.gear_class.select(3);g.ui.refresh_weapons();g.ui.preview_kind=2;g.ui.refresh_gear_detail();await capture("gadget-preview-v040")
	g.ui.settings();g.profile.window=false;g.apply_display_settings();await process_frame
	print("DISPLAY_FULLSCREEN ",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
	g.profile.window=true;g.apply_display_settings();await process_frame
	print("DISPLAY_WINDOWED ",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED)
	g.ui.clear_panel();g.ui.hud.visible=false
	var a=g.actors[1];a.position=Vector3(43,0,77);a.reset_view(0);a.camera.rotation.x=-.55;a.gun.visible=false
	g.drops=[{"pos":Vector3(42.7,.18,74.8),"yaw":.3,"amount":40,"weapon":"r2","until":200.},{"pos":Vector3(43.9,.18,74.7),"yaw":2.1,"amount":30,"weapon":"heavy_pistol","until":201.}]
	g.update_world_visuals(.1);await capture("drops-v040")
	g.leave_game();g.queue_free();await process_frame;await process_frame
	var stage=Node3D.new();root.add_child(stage)
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("182833");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.75;world.environment=env;stage.add_child(world)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,130,0);stage.add_child(light)
	MeshFactory.box(stage,Vector3(0,-.12,0),Vector3(13,.15,5),Color("304653"))
	var camera=Camera3D.new();stage.add_child(camera);camera.position=Vector3(0,6,-8);camera.look_at(Vector3(0,.15,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.8;camera.current=true
	for i in range(5):
		var c=CharacterVisual.new();stage.add_child(c);c.build(i,i%2);c.position=Vector3((i-2)*2.,0,0)
		c.animator.play(["fall_back","fall_front","fall_left","fall_right","fall_fold"][i]);c.animator.seek(.9,true);c.animator.pause()
	await capture("fall-poses-v040");stage.queue_free();await process_frame;quit()
