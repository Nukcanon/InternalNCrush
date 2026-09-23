extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func capture(label:String):
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-v06-"+label+".png")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	g.ui.host_settings();await capture("maps")
	g.server=true;g.local_id=1;g.phase="lobby";g.options.map=7;g.build_world();g.add_player(1,"PLAYER","visual_local_v06")
	for i in range(1,7):
		g.add_player(-i,"BOT %02d"%i,"visual"+str(i));g.players[-i].team=i%2;g.players[-i].role=i-1
	g.phase="combat";g.clock=100.;g.remaining=600.;g.ui.show_hud();g.ui.clear_panel();g.ui.stats.visible=false
	for index in [7,8,10,12,13,14,16,17,18,6]:
		g.options.map=index;g.build_world();await physics_frame;await physics_frame
		var a=g.actors[1];a.position=Vector3(0,.1,g.arena.bounds.y*.62);a.reset_view(0);a.set_local(true);g.players[1].protect=0.
		for i in range(1,7):
			var other=g.actors[-i];other.position=Vector3((i-3.5)*2.2,.1,a.position.z-9-abs(i-3.5)*.8);other.reset_view(PI);other.net_grounded=true;g.players[-i].protect=0.
			other.character.motion_seed=i;other.velocity=Vector3(0,0,5.5 if i%2 else 0.);other.gait=i*.18;other.visual(.08,g.players[-i],100.);other.character.update_pose(.08,other.velocity,false,false,true,0,-1,0,other.gait,0)
		for frame in range(20):a.visual(.016,g.players[1],100.)
		g.ui.refresh();g.ui.stats.visible=false;await capture("map"+str(index))
		if index==7:
			g.ui.damage_indicator.set_process(false);g.combat_fx.set_process(false)
			g.ui.damage_indicator.register_hit(Vector3.RIGHT,30,Time.get_ticks_msec()/1000.+10)
			g.ui.damage_indicator.register_hit(Vector3.FORWARD,20,Time.get_ticks_msec()/1000.+10)
			a.show_shot(100.);a.visual(.035,g.players[1],100.035);g.combat_fx._process(.045);await capture("feedback")
			g.ui.damage_indicator.clear_hits();g.ui.damage_indicator.set_process(true);g.combat_fx.clear();g.combat_fx.set_process(true)
			for phase in [.0,.25,.5,.75]:
				for i in range(1,7):g.actors[-i].character.update_pose(.016,Vector3(0,0,7.4),true,false,true,0,-1,0,phase,0)
				await capture("motion"+str(phase))
	g.ui.gear();await capture("gear")
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
