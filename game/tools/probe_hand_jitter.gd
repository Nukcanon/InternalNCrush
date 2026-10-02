extends SceneTree
# 1.5.1 (the user: the hands holding a gun tremble a little): the first-person hands
# against the gun, frame by frame - standing, walking, turning - per weapon.
# Prints the largest frame-to-frame wobble (hand relative to its gun) and sign flips.
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","jitter_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var ids=Array(OS.get_cmdline_user_args()).filter(func(x):return not str(x).contains("="))
	if ids.is_empty():ids=["a1","r1","h1","c1","e1","pistol","dual_pistols"]
	var step=1./60.
	for wid in ids:
		var w=Catalog.get_weapon(wid);p.role=maxi(0,int(w.get("role",0)));p.slot=0 if int(w.get("slot",0))==0 else 1
		if p.slot==0:p.primary=wid
		else:p.secondary=wid
		a.shown_role=-1;a.shown_weapon=""
		for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
		for mode in ["stand","walk","turn"]:
			var last={};var lastd={};var worst={"R":0.,"L":0.};var rot={"R":0.,"L":0.};var flips={"R":0,"L":0}
			for i in range(120):
				g.clock+=step
				if mode=="walk":a.velocity=Vector3(0,0,-3.);a.gait+=step*1.4
				else:a.velocity=Vector3.ZERO
				if mode=="turn":a.aim_yaw+=step*.8;a.input_state.yaw=a.aim_yaw
				if "nocarry" in OS.get_cmdline_user_args():HeroIK.reset_continuity(a.view_body)
				for key in ["upper_","fore_","kept_","roll_"]:
					if ("no"+key) in OS.get_cmdline_user_args():
						for sd in ["L","R"]:a.view_body.remove_meta(key+sd)
				a.visual(step,p,g.clock);await process_frame
				if not is_instance_valid(a.view_weapon):continue
				var gun_inv:Transform3D=a.view_weapon.global_transform.affine_inverse()
				for side in ["R","L"]:
					var wt:Transform3D=a.view_body.bone_world(a.view_body.bone["Wrist."+side])
					var lp:Vector3=gun_inv*wt.origin;var lq:Quaternion=(gun_inv.basis*wt.basis).get_rotation_quaternion()
					if last.has(side):
						var d:Vector3=lp-last[side][0]
						worst[side]=maxf(worst[side],d.length()*1000.);rot[side]=maxf(rot[side],rad_to_deg(lq.angle_to(last[side][1])))
						if lastd.has(side) and d.length()>.0002 and Vector3(lastd[side]).length()>.0002 and d.dot(lastd[side])<0.:flips[side]+=1
						lastd[side]=d
					last[side]=[lp,lq]
			print("JIT %s %s  R move %.2f mm turn %.2f deg flips %d | L move %.2f mm turn %.2f deg flips %d"%[wid,mode,worst.R,rot.R,flips.R,worst.L,rot.L,flips.L])
		a.input_state.yaw=0.;a.aim_yaw=0.
	print("JIT_DONE");quit()
