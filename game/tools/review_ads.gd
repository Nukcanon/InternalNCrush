extends SceneTree
# 1.5.1: first-person hip and aimed views of guns (sights must not block the view).
# Output validation/ads/<id>.jpg (hip | aimed). Args: weapon ids.
var g:Node
func _initialize():call_deferred("run")
func grab() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.convert(Image.FORMAT_RGB8);img.resize(640,360,Image.INTERPOLATE_BILINEAR);return img
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","ads_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/ads/")
	var step=1./60.
	for wid in OS.get_cmdline_user_args():
		var w=Catalog.get_weapon(wid);p.role=maxi(0,int(w.get("role",0)));p.slot=0;p.primary=wid;a.shown_role=-1;a.shown_weapon=""
		a.input_state.ads=false;a.aim_progress=0.
		for i in range(40):g.clock+=step;a.visual(step,p,g.clock);await process_frame
		var hip=await grab()
		a.input_state.ads=true
		for i in range(50):a.aim_progress=minf(1.,a.aim_progress+.05);g.clock+=step;a.visual(step,p,g.clock);await process_frame
		var aim=await grab()
		var sheet=Image.create(1280,360,false,Image.FORMAT_RGB8);sheet.blit_rect(hip,Rect2i(0,0,640,360),Vector2i(0,0));sheet.blit_rect(aim,Rect2i(0,0,640,360),Vector2i(640,0))
		sheet.save_jpg("res://../validation/ads/%s.jpg"%wid,.85)
		a.input_state.ads=false;a.aim_progress=0.
	print("ADS_DONE");quit()
