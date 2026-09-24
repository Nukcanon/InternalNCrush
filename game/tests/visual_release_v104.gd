extends SceneTree
var g:Node
var output="res://../validation/v104-release"
func _initialize():call_deferred("run")
func capture(label:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output)
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.build_world();g.add_player(1,"MASON","release_104")
	g.ui.gear();await capture("loadout");g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("weapon-stats")
	g.ui.clear_panel();g.phase="combat";g.players[1].alive=true;g.players[1].protect=0;g.clock=100
	var local=g.actors[1];local.position=Vector3(0,.08,18);local.reset_view(0);local.set_local(true);local.visual(.1,g.players[1],100)
	g.players[1].mag[g.players[1].primary]-=7;g.ui.show_hud();g.ui.refresh();await capture("hud")
	g.ui.gear();await capture("loadout-in-game");g.ui.clear_panel()
	var device=Node3D.new();g.add_child(device);device.position=Vector3(-2.4,0,13);CombatFX.device(device,"turret",0)
	var cover=Node3D.new();g.add_child(cover);cover.position=Vector3(.2,0,13);CombatFX.device(cover,"cover",0)
	var camera=Camera3D.new();g.add_child(camera);camera.current=true;camera.position=Vector3(-.7,2.0,9.5);camera.look_at(Vector3(-1.2,.8,13));camera.fov=60;await capture("deployables");device.queue_free();cover.queue_free();camera.queue_free()
	g.add_player(-1,"SERA / RECON","release_killer");g.players[-1].role=1;g.players[-1].team=1;g.players[-1].primary="r3";g.players[-1].hand=-1
	var a=g.actors[-1];a.set_team(1);a.position=Vector3(0,.08,10);a.reset_view(PI);a.aim_yaw=PI;a.visual(.1,g.players[-1],100)
	for i in range(50):g.kill_replay.warm_one();await process_frame
	for i in range(60):g.kill_replay.capture(.05);g.kill_replay.history.back().time=Time.get_ticks_msec()/1000.-3.+i*.05
	g.players[1].alive=false
	g.kill_replay.begin({"attacker":-1,"attacker_name":"SERA / RECON","victim":1,"weapon":"r3","origin":a.muzzle_world(),"hit_point":local.eye()-Vector3.UP*.2,"victim_pos":local.position})
	g.kill_replay.set_process(false)
	for i in range(223):
		g.kill_replay._process(1./60.);await physics_frame
		if i in [24,122,145,164,201]:await capture("replay-"+str(i))
		if g.kill_replay.active and g.kill_replay.elapsed>=KillReplay.RUNUP_SECONDS and g.kill_replay.elapsed<=KillReplay.FIRST_PERSON_SECONDS+KillReplay.DEATH_SECONDS:
			assert(g.kill_replay.camera.global_position.distance_to(g.kill_replay.event.hit_point)>=1.1,"Replay camera entered victim")
	print("NATIVE_RELEASE_V104_OK begin_usec=",g.kill_replay.begin_usec)
	g.kill_replay.finish();g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
