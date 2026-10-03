extends SceneTree
# 1.5.4 (the user: running with DUET the left fingers left the gun; does the right hand shake?):
# each hand against its own pistol frame by frame (standing, then sprinting with the pump),
# and close-ups of both hands. Output validation/dual-grip/*.jpg
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","dualgrip_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=0;p.primary=Catalog.first(0);p.secondary="dual_pistols";p.slot=1
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation/dual-grip/")
	var shots=[]
	for mode in ["stand","run"]:
		var last={};var worst={"R":0.,"L":0.};var drift={"R":0.,"L":0.};var start={}
		for i in range(150):
			g.clock+=step
			if mode=="run":a.velocity=Vector3(0,0,-Rules.RUN_SPEED);a.gait+=step*2.2;a.last_sprint=true;a.input_state.sprint=true
			else:a.velocity=Vector3.ZERO
			a.visual(step,p,g.clock);await process_frame
			var guns:Array=a.view_weapon.dual_guns if is_instance_valid(a.view_weapon) else []
			if guns.size()<2:continue
			var b=a.view_body
			for side in ["R","L"]:
				var gun:Node3D=guns[0] if side=="R" else guns[1]
				var local:Vector3=gun.global_transform.affine_inverse()*b.bone_world(b.bone["Wrist."+side]).origin
				if last.has(side):worst[side]=maxf(worst[side],(local-last[side]).length())
				if not start.has(side):start[side]=local
				drift[side]=maxf(drift[side],(local-start[side]).length())
				last[side]=local
			if mode=="run" and i>=60 and i%9==0 and shots.size()<8:
				await RenderingServer.frame_post_draw
				var img=root.get_texture().get_image();var s=img.get_size();shots.append(img.get_region(Rect2i(0,int(s.y*.35),s.x,int(s.y*.65))))
		print("DUAL %s hand vs its pistol, worst per frame R %.2f mm L %.2f mm | most drift R %.1f mm L %.1f mm"%[mode,worst.R*1000.,worst.L*1000.,drift.R*1000.,drift.L*1000.])
		if mode=="stand":
			await RenderingServer.frame_post_draw
			var img=root.get_texture().get_image();var s=img.get_size();img.get_region(Rect2i(0,int(s.y*.35),s.x,int(s.y*.65))).save_jpg("res://../validation/dual-grip/stand.jpg",.9)
	for i in range(shots.size()):shots[i].resize(640,234);shots[i].save_jpg("res://../validation/dual-grip/run_%d.jpg"%i,.88)
	print("DUALGRIP_DONE");quit()
