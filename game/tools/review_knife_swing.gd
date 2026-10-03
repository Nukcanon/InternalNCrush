extends SceneTree
# 1.5.4 (the user's Counter-Strike knife clip): the first-person knife swing frame by frame,
# at the clip's moments. Output validation/knife-swing/sheet.jpg (and f_<ms>.jpg).
var g:Node
const AGES=[-1.,.0,.02,.035,.06,.10,.14,.17,.21,.30,.50,.56,.62,.68,.74]
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","knife_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=0;p.primary=Catalog.first(0);p.slot=MeleeCombat.SLOT
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	for i in range(60):g.clock+=1./60.;a.visual(1./60.,p,g.clock);await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/knife-swing/")
	var shots=[]
	for age in AGES:
		if age<0.:p.melee_started=-100.
		else:p.melee_started=g.clock-age
		for i in range(3):a.visual(0.,p,g.clock);await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(426,240,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var sheet=Image.create(426*5,240*3,false,Image.FORMAT_RGBA8)
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,426,240),Vector2i((i%5)*426,(i/5)*240))
	sheet.save_jpg("res://../validation/knife-swing/sheet.jpg",.88);print("KNIFE_DONE");quit()
