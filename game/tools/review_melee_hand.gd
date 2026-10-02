extends SceneTree
# 1.5.2 (the user: the ring and little fingers round the wrench looked odd): the first-person
# melee hand close up, wrench and knife. Output validation/melee-hand/<tool>.jpg
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","melee_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/melee-hand/")
	for role in [3,0]:
		p.role=role;p.primary=Catalog.first(role);p.slot=MeleeCombat.SLOT;a.shown_role=-1;a.shown_weapon=""
		for i in range(60):g.clock+=1./60.;a.visual(1./60.,p,g.clock);await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();var s=img.get_size()
		img.get_region(Rect2i(int(s.x*.35),int(s.y*.3),int(s.x*.65),int(s.y*.7))).save_jpg("res://../validation/melee-hand/%s.jpg"%("wrench" if role==3 else "knife"),.9)
		# finger joints vs the handle (wrist frame)
		var b=a.view_body;var chains=HeroIK.finger_chains(b,"R")
		for f in ["Index","Middle","Ring","Pinky"]:
			var pts=[];for bone in chains[f]:pts.append(b.bone_world(bone).origin)
			var bend=0.
			for k in range(1,pts.size()-1):bend+=rad_to_deg((pts[k]-pts[k-1]).angle_to(pts[k+1]-pts[k]))
			print("MELEE ",role," ",f," bend %.0f deg"%bend)
	print("MELEE_DONE");quit()
