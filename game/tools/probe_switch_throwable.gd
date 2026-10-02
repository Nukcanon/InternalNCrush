extends SceneTree
# 1.4.10 (the user: switching to a throwable, the hand holding it shakes for an instant):
# the grenade hand and the throwable in camera space, frame by frame, from a gun to the
# throwable slot. Args: role=N shots
var g:Node
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","switch_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var role=0;var shots=false;var hand=1
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("role="):role=int(str(arg).substr(5))
		if str(arg)=="shots":shots=true
		if str(arg).begins_with("hand="):hand=int(str(arg).substr(5))
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=role;p.primary=Catalog.first(role);p.secondary="pistol";p.slot=0;p.gadget=1;p.team=0;p.gadget_count=3;p.flash_count=3;p.smoke=3;p.hand=hand
	var a=g.actors[1];a.shown_role=-1;a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	var last={}
	for i in range(50):
		if i==3:p.slot=2;p.switch_until=g.clock+.32
		g.clock+=step;a.visual(step,p,g.clock);await process_frame
		if shots and i<30 and i%2==1:
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://../validation/switch/");root.get_texture().get_image().save_jpg("res://../validation/switch/s%02d.jpg"%i,.8)
		var cam:Transform3D=a.camera.global_transform.affine_inverse();var b=a.view_body;var line="SW f%02d"%i
		for side in ["R","L"]:
			var w:Vector3=cam*b.bone_world(b.bone["Wrist."+side]).origin;var e:Vector3=cam*b.bone_world(b.bone["LowerArm."+side]).origin
			var dw=(w-last.get("w"+side,w)).length()*100.;var de=(e-last.get("e"+side,e)).length()*100.
			var q:Quaternion=(cam.basis*b.bone_world(b.bone["Wrist."+side]).basis).get_rotation_quaternion();var turn=rad_to_deg(q.angle_to(last.get("q"+side,q)))
			var fq:Quaternion=(cam.basis*b.bone_world(b.bone["LowerArm."+side]).basis).get_rotation_quaternion();var fturn=rad_to_deg(fq.angle_to(last.get("f"+side,fq)))
			last["q"+side]=q;last["f"+side]=fq;line+=" %s hand turn %.0f fore turn %.0f |"%[side,turn,fturn]
			last["w"+side]=w;last["e"+side]=e
			line+="  %s wrist %s d%.1fcm elbow d%.1fcm"%[side,str(w.snapped(Vector3.ONE*.001)),dw,de]
		var item:Vector3=cam*a.view_item.global_position if is_instance_valid(a.view_item) and a.view_item.is_inside_tree() else Vector3.ZERO
		line+="  item %s d%.1fcm vis %s"%[str(item.snapped(Vector3.ONE*.001)),(item-last.get("i",item)).length()*100.,str(is_instance_valid(a.view_item) and a.view_item.visible)];last.i=item
		print(line)
	print("SWITCH_DONE");quit()
