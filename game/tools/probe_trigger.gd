extends SceneTree
# Trigger point vs index fingertip (handle frame) for a weapon, third person.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var wid=OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "h6"
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	var w=Catalog.get_weapon(wid)
	var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
	var kind=GunLooks.hold_kind(w);if kind=="shoulder":kind="rifle"
	for i in range(12):hero.drive(1./30.,{"hold":kind,"hands":1.,"two_hands":true})
	var shapes:Dictionary=gun.get_meta("grip_shapes",{})
	var handle=gun.right_grip.global_transform;var to_handle=Transform3D(handle.basis.orthonormalized(),handle.origin).affine_inverse()
	var ws=HeroIK.world_shape(handle,"pistol",shapes.get("R",{}))
	var chain:Array=HeroIK.finger_chains(hero,"R").Index
	var tip=hero.bone_world(chain[chain.size()-1])*Vector3(0,.02,0)
	print("TRIG ",wid," shape.trigger=",shapes.R.get("trigger")," ws.trigger=",ws.get("trigger")," tip_handle=",(to_handle*tip).snapped(Vector3.ONE*.001)," wrist_handle=",(to_handle*hero.bone_world(hero.bone["Wrist.R"]).origin).snapped(Vector3.ONE*.001)," scale=",handle.basis.get_scale())
	for b in chain:print("  ",hero.skeleton.get_bone_name(b)," ",(to_handle*hero.bone_world(b).origin).snapped(Vector3.ONE*.001))
	var wb:Basis=to_handle.basis*hero.bone_world(hero.bone["Wrist.R"]).basis.orthonormalized()
	print("  wrist x=",wb.x.snapped(Vector3.ONE*.01)," y=",wb.y.snapped(Vector3.ONE*.01)," z=",wb.z.snapped(Vector3.ONE*.01)," want x=(0,-1,0) y=(0,0,-1) z=(1,0,0)")
	var lb:Basis=to_handle.basis*hero.bone_world(hero.bone["LowerArm.R"]).basis.orthonormalized()
	print("  forearm y=",lb.y.snapped(Vector3.ONE*.01)," elbow=",(to_handle*hero.bone_world(hero.bone["LowerArm.R"]).origin).snapped(Vector3.ONE*.001)," shoulder=",(to_handle*hero.bone_world(hero.bone["UpperArm.R"]).origin).snapped(Vector3.ONE*.001))
	quit()
