extends SceneTree
var g:Node
var output="res://../../validation/v102-visual"
func _initialize():call_deferred("run")
func capture(label:String):
	if "--gallery" in OS.get_cmdline_user_args() and is_instance_valid(g.ui.stats):g.ui.stats.hide()
	for i in range(6):
		if label=="medic-link":g.combat_fx.healing_link(g,g.actors[-1].visual_muzzle(),g.actors[-2].position+Vector3.UP*1.15,-1,-2)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output)
	g=load("res://scripts/game.gd").new();root.add_child(g)
	await create_timer(2.).timeout;await capture("menu")
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.build_world();g.add_player(1,"PLAYER","visual_v102")
	g.ui.gear();g.ui.preview_kind=1;g.ui.refresh_gear_detail();await capture("weapon-graphs")
	g.ui.gear_gadget.select(1);g.ui.preview_kind=2;g.ui.refresh_gear_detail();await capture("grenade-card")
	g.ui.internet_menu();await capture("internet-lobby")
	g.ui.show_hud();g.phase="combat";g.clock=100.;g.players[1].protect=0.;g.players[1].alive=true
	var a=g.actors[1];a.set_local(true)
	for index in ([] if "--fx-only" in OS.get_cmdline_user_args() else range(19)):
		g.options.map_random=false;g.options.map=index;g.build_world();await physics_frame;await physics_frame
		a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);a.aim_pitch=-.03;a.input_state.pitch=-.03
		for i in range(12):a.visual(.016,g.players[1],100.);await process_frame
		g.ui.refresh();await capture("map-%02d"%index)
		print("NATIVE_MAP ",index," blockers=",g.arena.get_meta("sight_blockers")," indoors=",g.arena.indoors)
	g.options.map_random=false;g.options.map=14;g.build_world();await physics_frame;await physics_frame
	a.position=Vector3(0,.05,g.arena.bounds.y-8.);a.reset_view(0)
	g.add_player(-1,"MINA","visual_medic");g.add_player(-2,"MASON","visual_patient")
	g.spawn(-1);g.spawn(-2)
	var medic=g.actors[-1];var patient=g.actors[-2];var p=g.players[-1]
	p.role=5;p.primary="m1";p.team=0;p.protect=0.;g.players[-2].role=0;g.players[-2].team=0;g.players[-2].protect=0.
	medic.position=a.position+Vector3(-1.4,0,-4.);patient.position=a.position+Vector3(1.7,0,-5.);medic.set_team(0);patient.set_team(0)
	medic.aim_yaw=-PI*.6;patient.aim_yaw=PI;medic.visual(.1,p,100.);patient.visual(.1,g.players[-2],100.)
	a.visual(.1,g.players[1],100.);g.ui.refresh()
	g.combat_fx.healing_link(g,medic.visual_muzzle(),patient.position+Vector3.UP*1.15,-1,-2);await capture("medic-link")
	g.combat_fx.explosion(a.position+Vector3(1.5,1.,-6.));await capture("explosion")
	for i in range(45):medic.character.update_pose(.016,Vector3(0,0,-9),true,false,true,0.,-1.,0.,i/30.);await process_frame
	await capture("sprint")
	medic.character.slide_pose(1.);await capture("slide")
	var body=PhysicsRagdoll.new();g.combat_fx.add_child(body);body.build(medic.character,medic.position+Vector3.UP*3.,Vector3(1,0,0),5,0,0.,false,Vector3(2,0,0));medic.hide()
	await create_timer(.25).timeout;await capture("airborne-ragdoll")
	await create_timer(1.5).timeout;await capture("grounded-ragdoll")
	print("NATIVE_V102_COMPLETE renderer=",RenderingServer.get_video_adapter_name())
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
