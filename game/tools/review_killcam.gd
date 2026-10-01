extends SceneTree
# 1.4.5: renders the kill replay's first-person view (KillReplay.drive_arms)
# for several weapons, so its grips can be compared with live play.
# Args: weapon ids (default: a set covering every hold kind). Output:
# validation/killcam/<wid>.png
var g:Node
func _initialize():call_deferred("run")
func run():
	var out="res://../validation/killcam/";DirAccess.make_dir_recursive_absolute(out)
	var args=OS.get_cmdline_user_args()
	var wids=args if args.size()>0 else ["a1","r2","e1","pistol","heavy_pistol","dual_pistol","h1","h2","m1","m3","s1","r3"]
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=7
	g.build_world()
	for i in range(3):await process_frame
	g.add_player(1,"VICTIM","review_killcam_v");g.add_player(2,"KILLER","review_killcam_k")
	g.players[2].team=1;g.phase="combat"
	var replay:KillReplay=g.kill_replay
	replay.prepare()
	for wid in wids:
		if not Catalog.weapons.has(wid):print("no weapon ",wid);continue
		var w=Catalog.get_weapon(wid)
		g.players[2].primary=wid;g.players[2].slot=0;g.players[2].role=int(w.get("role",0))
		for i in range(40):
			replay.warm_one()
			if replay.first_person_guns.has(wid):break
		if not replay.first_person_guns.has(wid):print("no replay gun for ",wid);continue
		for mount in replay.first_person_guns.values():mount.hide()
		replay.gun=replay.first_person_guns[wid];replay.gun.show()
		replay.arms_for(int(g.players[2].role),1)
		replay.stage.show();replay.stage.process_mode=Node.PROCESS_MODE_INHERIT;replay.camera.current=true
		replay.camera.position=Vector3(0,1.62,20);replay.camera.rotation=Vector3(0,0,0);replay.camera.fov=82.
		replay.kick=0.
		# The same per-frame placement as the replay (its _process, hip pose).
		var spec:Dictionary=replay.gun.get_meta("spec",{})
		var single_pistol=GunLooks.hold_kind(spec)=="pistol" and not bool(spec.get("dual",false))
		var hip:Vector3=Actor.hip_base_for(spec)
		replay.gun.transform=Transform3D(Basis.from_euler(Vector3(0,0,.10 if single_pistol else 0.)),hip)
		var model:GunModel=replay.gun.get_meta("model",null)
		if is_instance_valid(model):model.animate_reload(-1.,0.,10.)
		for i in range(12):
			replay.drive_arms(1./60.,{},1.)
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+wid+".png")
		# Twist / stretch report from the arms.
		var fp=replay.fp_body
		print("KILLCAM %s stretch R %.3f L %.3f twist R %.2f L %.2f"%[wid,float(fp.get_meta("fp_stretch_R",-1.)),float(fp.get_meta("fp_stretch_L",-1.)),float(fp.get_meta("fp_twist_R",0.)),float(fp.get_meta("fp_twist_L",0.))])
	print("KILLCAM_OK");quit()
