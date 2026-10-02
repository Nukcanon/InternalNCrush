extends SceneTree
# 1.4.9 (the user: with a throwable in hand the upper arm shakes): the first-person
# shoulder/elbow/wrist of both arms, frame by frame, while a grenade is held -
# standing, walking and turning. Prints the frame-to-frame change.
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","arm_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=2;p.gadget=1;p.team=0;p.gadget_count=3
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	for mode in ["stand","walk","turn","pitch","gun-pitch"]:
		if mode=="gun-pitch":p.slot=0
		var last={};var worst={"R":[0.,0.,0.,0.],"L":[0.,0.,0.,0.]}
		for i in range(90):
			g.clock+=step
			if mode=="walk":a.velocity=Vector3(0,0,-4.);a.gait+=step*1.6
			else:a.velocity=Vector3.ZERO
			if mode=="turn":a.aim_yaw+=step*1.5;a.input_state.yaw=a.aim_yaw
			if mode.ends_with("pitch"):a.aim_pitch=sin(i*.1)*.5;a.input_state.pitch=a.aim_pitch
			a.visual(step,p,g.clock);await process_frame
			var cam:Transform3D=a.camera.global_transform.affine_inverse()
			for side in ["R","L"]:
				var b=a.view_body
				var sh:Vector3=cam*b.bone_world(b.bone["UpperArm."+side]).origin
				var el:Vector3=cam*b.bone_world(b.bone["LowerArm."+side]).origin
				var wr:Vector3=cam*b.bone_world(b.bone["Wrist."+side]).origin
				var up=(el-sh).normalized()
				if last.has(side):
					var turn=rad_to_deg(up.angle_to(last[side][0]));var move=(el-last[side][1]).length()
					worst[side]=[maxf(worst[side][0],turn),maxf(worst[side][1],move),maxf(worst[side][2],(sh-last[side][3]).length()),maxf(worst[side][3],(wr-last[side][2]).length())]
				last[side]=[up,el,wr,sh]
				if mode=="pitch" and side=="R" and i%6==0:print("  pitch %.2f elbow %s"%[a.aim_pitch,str(el.snapped(Vector3.ONE*.001))])
		print("ARM ",mode," upper-arm turn per frame max deg R %.2f L %.2f | elbow cm R %.2f L %.2f | shoulder cm R %.2f L %.2f | wrist cm R %.2f L %.2f"%[worst.R[0],worst.L[0],worst.R[1]*100.,worst.L[1]*100.,worst.R[2]*100.,worst.L[2]*100.,worst.R[3]*100.,worst.L[3]*100.])
	# the pin pull and throw, frame by frame (elbow in camera space, upper-arm turn)
	p.slot=2;for i in range(30):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	var prev={}
	for i in range(130):
		if i==10:p.cooking=1;p.grenade_started=g.clock
		if i==70:p.cooking=0;p.throw_until=g.clock+Actor.THROW_TIME
		g.clock+=step;a.visual(step,p,g.clock);await process_frame
		var cam:Transform3D=a.camera.global_transform.affine_inverse();var b=a.view_body;var line=""
		for side in ["R","L"]:
			var sh:Vector3=cam*b.bone_world(b.bone["UpperArm."+side]).origin;var el:Vector3=cam*b.bone_world(b.bone["LowerArm."+side]).origin;var wr:Vector3=cam*b.bone_world(b.bone["Wrist."+side]).origin
			var up=(el-sh).normalized();var turn=0.
			if prev.has(side):turn=rad_to_deg(up.angle_to(prev[side]))
			prev[side]=up
			line+="  %s el %s wr %s sh %s turn %5.1f"%[side,str(el.snapped(Vector3.ONE*.01)),str(wr.snapped(Vector3.ONE*.01)),str(sh.snapped(Vector3.ONE*.01)),turn]
		print("THROW f%03d%s"%[i,line])
	print("ARM_DONE");quit()
