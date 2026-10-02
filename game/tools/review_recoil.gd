extends SceneTree
# 1.4.9: the first-person firing animation - a sheet per weapon of hip and aimed
# frames before and after one shot (validation/recoil/<id>.jpg). Run windowed.
# Args: optional comma list of weapon ids.
var g:Node
var out="res://../validation/recoil/"
const CASES=[["a1",0],["c2",0],["h2",0],["e1",0],["pistol",1],["heavy_pistol",1],["a3",0],["r4",0],["r2",0],["h4",0],["h5",0]]
const TIMES=[0.,.03,.06,.10,.16,.26,.40]
func _initialize():call_deferred("run")
func grab() -> Image:
	g.ui.refresh();g.ui.reticle.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.convert(Image.FORMAT_RGB8);img.resize(640,360,Image.INTERPOLATE_BILINEAR);return img
func step(a,p,seconds:float):
	var n=maxi(1,roundi(seconds*120.))
	for i in range(n):g.clock+=seconds/n;a.visual(seconds/n,p,g.clock)
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0;p.hand=1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var only=OS.get_cmdline_user_args()
	for c in CASES:
		if only.size()>0 and not c[0] in only[0].split(","):continue
		p.slot=c[1]
		if c[1]==0:p.primary=c[0]
		else:p.secondary=c[0]
		var w=Catalog.get_weapon(c[0]);p.role=int(w.get("role",0)) if int(w.get("role",-1))>=0 else 0
		var sheet=Image.create(640*TIMES.size(),360*2,false,Image.FORMAT_RGB8)
		for row in range(2):
			p.mag[c[0]]=int(w.mag);p.reload=0.;a.shown_weapon="";a.kick=0.;a.recoil=0.;a.launcher_tilt=0.
			a.input_state.ads=row==1;a.aim_progress=float(row);a.ads_blend=float(row)
			step(a,p,.8)
			p.shot_time=g.clock;var shot_at=g.clock
			if bool(w.get("rocket",false)):p.mag[c[0]]=0;p.reload=g.clock+float(w.reload)
			for k in range(TIMES.size()):
				var t=float(TIMES[k])
				if t>0.:step(a,p,shot_at+t-g.clock)
				var img=await grab()
				sheet.blit_rect(img,Rect2i(0,0,640,360),Vector2i(640*k,360*row))
		sheet.save_jpg(out+c[0]+".jpg",.85)
		print("RECOIL_SHEET ",c[0]," power %.2f unsteady %.2f ads %.2f"%[Actor.kick_strength(w),clampf((100.-float(w.get("stability",70)))/100.,0.,1.),Actor.kick_ads_scale(w)])
	print("RECOIL_OK");quit()
