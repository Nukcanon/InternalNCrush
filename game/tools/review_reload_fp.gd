extends SceneTree
# 1.4.10: first-person reload frames (magazine guns and shotguns) at fixed
# progress steps - a sheet per weapon in validation/reload-fp/<id>.jpg.
# Args: optional comma list of weapon ids. Run windowed.
var g:Node
var out="res://../validation/reload-fp/"
const CASES=[["a1",0],["c1",0],["h1",0],["r4",0],["pistol",1],["e1",0],["e2",0]]
const STEPS=[.04,.10,.16,.24,.34,.46,.56,.64,.70,.76,.84,.92]
func _initialize():call_deferred("run")
func grab() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var full=root.get_texture().get_image();full.convert(Image.FORMAT_RGB8);var s=full.get_size()
	var img=full.get_region(Rect2i(int(s.x*.35),int(s.y*.25),int(s.x*.65),int(s.y*.75)));img.resize(480,270,Image.INTERPOLATE_BILINEAR);return img
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	for i in range(30):await process_frame
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0;p.hand=1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var only=OS.get_cmdline_user_args()
	for c in CASES:
		if only.size()>0 and not c[0] in str(only[0]).split(","):continue
		p.slot=c[1]
		if c[1]==0:p.primary=c[0]
		else:p.secondary=c[0]
		var w=Catalog.get_weapon(c[0]);p.role=int(w.get("role",0)) if int(w.get("role",-1))>=0 else 0
		p.mag[c[0]]=0;p.reload=0.;a.shown_weapon="";a.input_state.ads=false;a.ads_blend=0.
		for i in range(30):g.clock+=1./60.;a.visual(1./60.,p,g.clock)
		var duration=MagazineReload.duration(w)
		p.reload_weapon=c[0];p.reload_started=g.clock;p.reload=g.clock+duration;p.reload_count=int(w.mag)
		var sheet=Image.create(480*6,270*2,false,Image.FORMAT_RGB8);var k=0
		for t in STEPS:
			var target=float(p.reload_started)+duration*t
			while g.clock<target:g.clock+=1./120.;a.visual(1./120.,p,g.clock)
			var img=await grab();sheet.blit_rect(img,Rect2i(0,0,480,270),Vector2i(480*(k%6),270*(k/6)));k+=1
			if t in [.56,.64,.70]:root.get_texture().get_image().save_jpg(out+c[0]+"_%d.jpg"%int(t*100),.85)
		sheet.save_jpg(out+c[0]+".jpg",.85)
		p.reload=0.;print("RELOAD_SHEET ",c[0]," duration ",duration)
	print("RELOAD_OK");quit()
