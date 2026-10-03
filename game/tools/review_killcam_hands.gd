extends SceneTree
# 1.5.4 (the user: a FEATHER kill's replay showed no hands; check every gun): the kill replay
# for each gun, frozen in the attacker's first person, with both wrists measured against
# the gun's grips. Output validation/killcam/<wid>.jpg and a sheet.
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(960,540);DisplayServer.window_set_size(Vector2i(960,540))
	DirAccess.make_dir_recursive_absolute("res://../validation/killcam/")
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.classes=true
	g.build_world();g.add_player(1,"VICTIM","kc_victim")
	g.phase="combat";g.players[1].alive=true;g.players[1].protect=0;g.clock=100
	var local=g.actors[1];local.position=Vector3(0,.08,18);local.reset_view(0);local.set_local(true);local.visual(.1,g.players[1],100)
	g.add_player(-1,"KILLER","kc_killer");g.players[-1].team=1
	var a=g.actors[-1];a.set_team(1);a.position=Vector3(0,.08,10);a.reset_view(PI);a.aim_yaw=PI
	var ids=[]
	for wid in Catalog.weapons:
		var w=Catalog.get_weapon(wid)
		if str(w.get("kind",""))=="gun":ids.append(wid)
	var shots=[];var missing=[]
	for wid in ids:
		var w=Catalog.get_weapon(wid);var p=g.players[-1]
		p.role=maxi(0,int(w.get("role",0)));p.slot=0 if int(w.get("slot",0))==0 else 1
		if p.slot==0:p.primary=wid
		else:p.secondary=wid
		a.shown_role=-1;a.set_team(1);a.visual(.1,p,100)
		g.kill_replay.history.clear()
		for i in range(80):g.kill_replay.warm_one()
		for i in range(60):g.kill_replay.capture(.05);g.kill_replay.history.back().time=Time.get_ticks_msec()/1000.-3.+i*.05
		g.players[1].alive=false
		g.kill_replay.begin({"attacker":-1,"attacker_name":"KILLER","victim":1,"weapon":wid,"origin":a.muzzle_world(),"hit_point":local.eye()-Vector3.UP*.2,"victim_pos":local.position})
		g.kill_replay.set_process(false)
		var ok=g.kill_replay.active
		for i in range(40):g.kill_replay._process(1./60.);await process_frame
		var body=g.kill_replay.fp_body
		var shown=ok and is_instance_valid(body) and body.visible and body.is_visible_in_tree()
		var model=g.kill_replay.gun.get_meta("model",null) if ok and is_instance_valid(g.kill_replay.gun) else null
		var gap=-1.
		if shown and is_instance_valid(model):
			var grip:Node3D=model.grip("R");gap=body.bone_world(body.bone["Wrist.R"]).origin.distance_to(grip.global_position)
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(480,270);shots.append(img)
		img.save_jpg("res://../validation/killcam/%s.jpg"%wid,.85)
		print("KILLCAM %s %s active %s hands %s wrist-grip %.0f mm"%[wid,str(w.name),str(ok),str(shown),gap*1000.])
		if not shown:missing.append(str(w.name))
		g.kill_replay.finish();g.players[1].alive=true
	var cols=4;var rows=ceili(shots.size()/float(cols))
	var sheet=Image.create(480*cols,270*rows,false,shots[0].get_format())
	for i in range(shots.size()):sheet.blit_rect(shots[i],Rect2i(0,0,480,270),Vector2i((i%cols)*480,(i/cols)*270))
	sheet.save_jpg("res://../validation/killcam/sheet.jpg",.85)
	print("KILLCAM_MISSING ",missing)
	print("KILLCAM_DONE");quit()
