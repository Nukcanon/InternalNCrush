extends SceneTree
# 1.5.4 (the user: the held gadget rises a little more after every gun <-> gadget switch):
# switches back and forth for each class and prints the item's height in the camera's
# frame after it has settled, switch by switch.
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.classes=true
	g.build_world();g.add_player(1,"PLAYER","switch_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];var a=g.actors[1]
	var step=1./60.
	for role in [0,5,4,3]:
		p.protect=0.;p.alive=true;p.team=0;p.role=role;p.primary=Catalog.first(role);p.secondary=Catalog.secondaries_for(role)[0];p.slot=0;p.gadget=0;p.gadget_count=3;p.smoke=3;p.flash_count=3
		a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
		a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
		for i in range(30):g.clock+=step;a.visual(step,p,g.clock);await process_frame
		var heights=[]
		for n in range(6):
			p.slot=2
			for i in range(70):g.clock+=step;a.visual(step,p,g.clock);await process_frame
			if is_instance_valid(a.view_item):
				var local:Vector3=a.camera.global_transform.affine_inverse()*a.view_item.global_position
				heights.append(snappedf(local.y*1000.,.1))
			p.slot=0
			for i in range(70):g.clock+=step;a.visual(step,p,g.clock);await process_frame
		print("SWITCH role %d item height in view per switch (mm): %s"%[role,str(heights)])
	print("SWITCH_DONE");quit()

