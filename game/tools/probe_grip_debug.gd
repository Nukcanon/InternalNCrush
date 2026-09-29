extends SceneTree
# Prints knuckle positions, wrist offsets and solved finger angles for a grip.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var id=OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "pistol"
	var w=Catalog.get_weapon(id)
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
	var s={"hold":GunLooks.hold_kind(w),"hands":1.,"two_hands":false}
	hero.set_meta("ik_debug",true)
	for i in range(3):hero.drive(1./30.,s);await process_frame
	hero.remove_meta("ik_debug")
	var hs=absf(hero.skeleton.global_transform.basis.get_scale().y)
	print("hand scale ",hs)
	for side in ["R","L"]:print(side," knuckles ",HeroIK.knuckles(hero,side))
	var shapes=gun.get_meta("grip_shapes",{});print("shapes ",shapes)
	var handle=gun.right_grip.global_transform
	var ws=HeroIK.world_shape(handle,"pistol",shapes.get("R",{}))
	print("world shape ",ws," handle scale ",handle.basis.get_scale())
	var off=HeroIK.wrist_offset(hero,"R","pistol",ws,hs)
	print("wrist offset (handle frame) ",off)
	var target=HeroIK.wrist_target(handle,"R","pistol",hs,hero,shapes.get("R",{}))
	var actual=hero.bone_world(hero.bone["Wrist.R"])
	print("target ",target.origin," actual ",actual.origin," dist ",target.origin.distance_to(actual.origin))
	var tq=target.basis.get_rotation_quaternion();var aq=actual.basis.get_rotation_quaternion()
	print("orientation error (rad) ",tq.angle_to(aq))
	var fore_bone=hero.bone_world(hero.bone["LowerArm.R"])
	var forearm=(actual.origin-fore_bone.origin).normalized()
	print("forearm dir ",forearm," hand y target ",target.basis.y.normalized()," bend needed ",forearm.angle_to(target.basis.y.normalized()))
	print("shoulder ",hero.bone_world(hero.bone["UpperArm.R"]).origin," elbow ",fore_bone.origin," grip ",handle.origin)
	print("target basis ",target.basis," det ",target.basis.determinant())
	var chains=HeroIK.finger_chains(hero,"R")
	for f in chains:
		var names=[]
		for b in chains[f]:names.append("%s=%.2f"%[hero.skeleton.get_bone_name(b),(hero.skeleton.get_bone_rest(b).basis.get_rotation_quaternion().inverse()*hero.skeleton.get_bone_pose_rotation(b)).get_angle()])
		print(f," ",names)
	# Distances of the finger joints to the shape after solving.
	var to_handle=Transform3D(handle.basis.orthonormalized(),handle.origin).affine_inverse()
	for f in chains:
		var d=[]
		for b in chains[f]:
			var p=to_handle*hero.bone_world(b).origin
			d.append("%.3f"%HeroIK.box_distance(p,ws.half,ws.round))
		print("  dist ",f," ",d)
	# Solver prediction for the middle finger vs the posed skeleton.
	var sk=hero.skeleton;var bones:Array=chains["Middle"]
	var angles=[]
	for b in bones:angles.append((sk.get_bone_rest(b).basis.get_rotation_quaternion().inverse()*sk.get_bone_pose_rotation(b)).get_angle())
	var frames=HeroIK.finger_frames(sk,bones,angles)
	var wrist_world=hero.bone_world(hero.bone["Wrist.R"])
	for i in range(bones.size()):
		var predicted=to_handle*(wrist_world*frames[i].origin)
		var real=to_handle*hero.bone_world(bones[i]).origin
		print("  middle joint ",i," predicted ",predicted," real ",real)
	# Pose rotation axis check: the flex of Middle2 relative to rest, as axis-angle.
	var q=sk.get_bone_rest(bones[1]).basis.get_rotation_quaternion().inverse()*sk.get_bone_pose_rotation(bones[1])
	print("  middle2 local delta axis ",q.get_axis()," angle ",q.get_angle())
	quit()
