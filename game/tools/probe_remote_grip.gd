extends SceneTree
# Where the TETHER grip markers are and where the hands actually end up.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var w=Catalog.get_weapon(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "remote")
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(3,0,true)
	var gun=GunModel.new();gun.build(w,true);hero.hold(gun)
	var s={"hold":"rifle","hands":1.,"pitch":0.,"reload":-1.,"velocity":Vector3.ZERO,"grounded":true,"shot":9.}
	for i in range(10):hero.drive(1./30.,s);await process_frame
	print("STYLES ",gun.get_meta("grip_styles")," SHAPES ",gun.get_meta("grip_shapes"))
	print("BASE scale ",gun.base.scale," gun scale ",gun.scale," R local ",gun.right_grip.position," L local ",gun.left_grip.position)
	for pair in [["R",gun.right_grip],["L",gun.left_grip]]:
		var side=pair[0];var marker:Node3D=pair[1]
		var wrist=hero.bone_world(hero.bone["Wrist."+side])
		var local=marker.global_transform.affine_inverse()*wrist.origin
		var palm=wrist.origin+wrist.basis.orthonormalized().y*.08*hero.hand_scale()
		print("GRIP ",side," marker ",marker.global_position," wrist ",wrist.origin," wrist_in_handle ",local," palm_in_handle ",marker.global_transform.affine_inverse()*palm)
	quit()
