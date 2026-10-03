extends SceneTree
# 1.5.4 (the user: the ARC's beam trailed the gun when turning fast): the beam while the view
# swings quickly, frame by frame. Output validation/arc-beam/sheet.jpg.
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","arc_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=2;p.primary="h6";p.slot=0;p.mag.h6=600.
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(40):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/arc-beam/")
	var shots=[];a.input_state.fire=true;a.last_sprint=false;a.sprint_release=0.;p.switch_until=0.
	for i in range(70):
		g.clock+=step
		var turn=sin(i*.18)*.07 # fast swings (up to ~4 rad/s)
		a.aim_yaw+=turn;a.input_state.yaw=a.aim_yaw
		LaserCombat.tick(g,1,step);a.visual(step,p,g.clock);await process_frame
		if i>=20 and i%5==0 and shots.size()<10:
			await RenderingServer.frame_post_draw
			var img=root.get_texture().get_image();img.resize(426,240,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var sheet=Image.create(426*5,240*2,false,Image.FORMAT_RGBA8)
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,426,240),Vector2i((i%5)*426,(i/5)*240))
	sheet.save_jpg("res://../validation/arc-beam/sheet.jpg",.88);print("ARC_DONE");quit()
