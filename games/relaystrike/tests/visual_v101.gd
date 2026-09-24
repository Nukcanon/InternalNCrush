extends SceneTree
var g:Node
var output="res://../../validation/v101-visual"
func _initialize():call_deferred("run")
func capture(label:String):
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output)
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=16;g.build_world();g.add_player(1,"LOCAL","v101")
	g.ui.gear();g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("gear-primary")
	g.ui.gear_class.select(1);g.ui.refresh_weapons();g.ui.refresh_gear_cards();await capture("gear-recon")
	g.ui.gear_class.select(3);g.ui.refresh_weapons();g.ui.gear_category=4;g.ui.preview_kind=4;g.ui.refresh_gear_detail();g.ui.refresh_gear_cards();await capture("gear-turret")
	g.ui.settings();await capture("display-presets")
	var choices=g.ui.panel.find_child("ResolutionChoices",true,false);choices.select(choices.item_count-1);choices.item_selected.emit(choices.selected);await capture("display-custom")
	g.ui.clear_panel();g.phase="combat";g.players[1].alive=true;g.players[1].protect=0;g.clock=100
	g.add_player(-1,"SERA / RECON","v101_killer");g.players[-1].role=1;g.players[-1].team=1;g.players[-1].primary="r3";g.players[-1].hand=-1
	var a=g.actors[-1];a.set_team(1);a.position=Vector3(0,-3.2,-4);a.reset_view(PI);a.aim_yaw=PI;a.visual(.1,g.players[-1],100)
	var local=g.actors[1];local.position=Vector3(0,-3.2,5);local.reset_view(0);local.set_local(true);local.visual(.1,g.players[1],100)
	for i in range(50):g.kill_replay.warm_one()
	for i in range(60):
		g.kill_replay.capture(.05);g.kill_replay.history.back().time=Time.get_ticks_msec()/1000.-3.+i*.05
	g.players[1].alive=false
	g.kill_replay.begin({"attacker":-1,"attacker_name":"SERA / RECON","victim":1,"weapon":"r3","origin":a.muzzle_world(),"hit_point":local.eye()-Vector3.UP*.2,"victim_pos":local.position})
	g.kill_replay.set_process(false);g.kill_replay._process(.3);await capture("replay-first")
	g.kill_replay._process(1.7);await capture("replay-bullet")
	g.kill_replay._process(.55);await capture("replay-death")
	g.kill_replay._process(.95);await capture("replay-killer")
	print("REPLAY_BEGIN_USEC=",g.kill_replay.begin_usec," map_reused=",g.kill_replay.stage.get_parent()==g)
	g.kill_replay.finish()
	var camera=Camera3D.new();g.add_child(camera);camera.current=true;camera.position=Vector3(35,30,37);camera.look_at(Vector3(0,1,0));camera.fov=70;await capture("vertical-overview")
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()

