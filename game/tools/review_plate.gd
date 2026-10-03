extends SceneTree
# 1.5.4 (the user): the assault's armour plate in first person - the hold (thumbs out to the
# side) and putting it on (both hands bring it to the chest, then down). Output
# validation/plate/sheet.jpg (hold close-up first, then the apply frames).
var g:Node
const AGES=[-1.,.08,.16,.24,.32,.40,.50,.60]
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","plate_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=0;p.primary=Catalog.first(0);p.gadget=0;GadgetLoadout.reset(p);p.slot=2
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(80):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/plate/")
	await RenderingServer.frame_post_draw
	var hold=root.get_texture().get_image();var hs=hold.get_size();hold.get_region(Rect2i(int(hs.x*.22),int(hs.y*.5),int(hs.x*.5),int(hs.y*.5))).save_jpg("res://../validation/plate/hold.jpg",.9)
	var shots=[]
	p.plate_at=g.clock
	var start=g.clock
	for age in AGES:
		if age<0.:continue
		while g.clock-start<age:g.clock+=step;a.visual(step,p,g.clock);await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(426,240,Image.INTERPOLATE_BILINEAR);shots.append(img)
	var sheet=Image.create(426*4,240*2,false,Image.FORMAT_RGBA8)
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,426,240),Vector2i((i%4)*426,(i/4)*240))
	sheet.save_jpg("res://../validation/plate/apply.jpg",.88);print("PLATE_DONE");quit()
