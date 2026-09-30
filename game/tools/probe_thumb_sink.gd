extends SceneTree
# Why a support-hand thumb sinks into a gun (test_v141): palm placement and
# finger wrap debug for one weapon, third person.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var wid=OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "e3"
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	var w=Catalog.get_weapon(wid)
	var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
	var kind=GunLooks.hold_kind(w);if kind=="shoulder":kind="rifle"
	HeroIK.debug_contact=true
	for i in range(3):hero.drive(1./30.,{"hold":kind,"hands":1.,"two_hands":true})
	HeroIK.debug_contact=false
	for side in ["R","L"]:
		var g=gun.grip(side);var c=GripField.contact(gun,g.global_transform)
		print(side," contact=",not c.is_empty()," style=",gun.get_meta("grip_styles",{}).get(side,"?")," wrist_to_grip=",hero.bone_world(hero.bone["Wrist."+side]).origin.distance_to(g.global_position))
		if c.is_empty():continue
		var to_g=Transform3D(g.global_transform.basis.orthonormalized(),g.global_transform.origin).affine_inverse()
		var chains=HeroIK.finger_chains(hero,side)
		for finger in chains:
			var line="  "+finger+":"
			for b in chains[finger]:line+=" %.3f"%GripField.distance(c,to_g*hero.bone_world(b).origin)
			print(line)
	quit()
