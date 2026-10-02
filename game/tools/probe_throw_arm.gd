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
	var role=0;var shots="shots" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("role="):role=int(str(arg).substr(5))
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=role;p.primary=Catalog.first(role);p.secondary="pistol";p.slot=2;p.gadget=1;p.team=0;p.gadget_count=3;p.flash_count=3;p.smoke=3
	print("ROLE ",role," equipped ",GrenadeLogic.equipped(p))
	var a=g.actors[1];a.shown_role=-1;a.set_local(true);a.set_team(0)
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
	a.aim_pitch=0.;a.input_state.pitch=0.;p.slot=2;for i in range(30):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	var prev={};var prev_rot={}
	for i in range(130):
		if i==10:p.cooking=1;p.grenade_started=g.clock
		if i==70:p.cooking=0;p.throw_until=g.clock+Actor.THROW_TIME
		if false:a.view_body.set_meta("ik_trace",true);print(" frame ",i)
		else:a.view_body.remove_meta("ik_trace")
		g.clock+=step;a.visual(step,p,g.clock);await process_frame
		if shots and i in [14,20,26,32,40,60]:
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://../validation/throw-pin/");root.get_texture().get_image().save_jpg("res://../validation/throw-pin/f%03d.jpg"%i,.85)
		var cam:Transform3D=a.camera.global_transform.affine_inverse();var b=a.view_body;var line=""
		for side in ["R","L"]:
			var sh:Vector3=cam*b.bone_world(b.bone["UpperArm."+side]).origin;var el:Vector3=cam*b.bone_world(b.bone["LowerArm."+side]).origin;var wr:Vector3=cam*b.bone_world(b.bone["Wrist."+side]).origin
			var up=(el-sh).normalized();var turn=0.
			if prev.has(side):turn=rad_to_deg(up.angle_to(prev[side]))
			prev[side]=up
			var lb:Basis=(cam.basis*b.bone_world(b.bone["LowerArm."+side]).basis).orthonormalized();var axis=lb.y.normalized();var twist=0.
			if prev_rot.has(side):
				var d:Quaternion=(lb.get_rotation_quaternion()*Basis(prev_rot[side]).get_rotation_quaternion().inverse()).normalized()
				var v=Vector3(d.x,d.y,d.z);var w=d.w;var proj=axis*v.dot(axis);var tq=Quaternion(proj.x,proj.y,proj.z,w).normalized();twist=rad_to_deg(2.*acos(clampf(absf(tq.w),0.,1.)))
			prev_rot[side]=lb
			line+="  %s turn %5.1f twist %5.1f"%[side,turn,twist]
		print("THROW f%03d%s"%[i,line])
	var bb=a.view_body;for sd in ["R","L"]:
		var u=bb.bone_world(bb.bone["UpperArm."+sd]);var l=bb.bone_world(bb.bone["LowerArm."+sd]);var w=bb.bone_world(bb.bone["Wrist."+sd])
		print("AXIS ",sd," upper y vs bone %.1f deg, lower y vs bone %.1f deg"%[rad_to_deg(u.basis.y.normalized().angle_to(l.origin-u.origin)),rad_to_deg(l.basis.y.normalized().angle_to(w.origin-l.origin))])
	print("ARM_DONE");quit()
