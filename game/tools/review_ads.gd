extends SceneTree
# Hip / aimed first-person views of a set of weapons (right handed, map 13).
var g:Node
var out="res://../validation/ads/"
const CASES=[["a1",0],["a3",0],["e1",0],["c1",0],["pistol",1],["dual_pistols",1],["r1",0],["r2",0],["r3",0],["r4",0],["r5",0],["h6",0],["h4",0],["h5",0]]
func _initialize():call_deferred("run")
func shot(label:String):
	g.ui.refresh()
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func settle(a,frames:int=24):
	for i in range(frames):
		a.visual(1./30.,g.players[a.pid],g.clock);await process_frame
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
		var w=Catalog.get_weapon(c[0]);p.mag[c[0]]=int(w.mag);p.role=int(w.get("role",0)) if int(w.get("role",-1))>=0 else 0
		a.shown_weapon="";a.input_state.ads=false;a.ads_blend=0.;await settle(a);await shot(c[0]+"-hip")
		a.input_state.ads=true;a.aim_progress=1.;a.ads_blend=1.;await settle(a);await shot(c[0]+"-aim")
		a.input_state.ads=false;a.ads_blend=0.
	print("ADS_OK");quit()
