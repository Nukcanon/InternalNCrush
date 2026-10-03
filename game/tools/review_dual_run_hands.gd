extends SceneTree
# 1.5.4 (the user: running with DUET the left hand must hold its pistol like the right one -
# mirrored, only the timing differs): the moment each pistol is at the top of its pump,
# without the HUD, plus how far each wrist is from its pistol's grip in the grip's own space.
# Output validation/dual-grip/top_R.jpg, top_L.jpg
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","dualrun_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=0;p.primary=Catalog.first(0);p.secondary="dual_pistols";p.slot=1
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	for c in g.ui.find_children("*","CanvasItem",true,false):if c is Control and c.get_parent()==g.ui:c.visible=false
	for c in g.find_children("*","CanvasLayer",true,false):c.visible=false
	var step=1./60.
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/dual-grip/")
	var saved={}
	for i in range(240):
		g.clock+=step
		a.velocity=Vector3(0,0,-Rules.RUN_SPEED);a.gait+=step*2.2;a.last_sprint=true;a.input_state.sprint=true
		a.visual(step,p,g.clock);await process_frame
		var gun=a.view_weapon
		if not is_instance_valid(gun) or gun.dual_guns.size()<2 or gun.pair_run<.95:continue
		for k in [0,1]:
			var side="R" if k==0 else "L"
			if saved.has(side) or gun.pair_pump(k)<.97:continue
			var b=a.view_body;var grip:Node3D=gun.grip(side)
			var local:Vector3=grip.global_transform.affine_inverse()*b.bone_world(b.bone["Wrist."+side]).origin
			print("TOP %s wrist in grip space %s (mm)"%[side,str(local*1000.)])
			await RenderingServer.frame_post_draw
			var img=root.get_texture().get_image();img.save_jpg("res://../validation/dual-grip/top_%s.jpg"%side,.9);saved[side]=true
		if saved.size()==2:break
	print("DUALRUN_DONE");quit()
