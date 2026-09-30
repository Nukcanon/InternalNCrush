extends SceneTree
# Third-person grip probe: a hero holding one weapon (args: weapon ids);
# prints per-finger wrap angles / segment-end distances (HeroIK debug) and the
# deepest finger joints against the weapon's grip field.
func _initialize():call_deferred("run")
func run():
	var ids=OS.get_cmdline_user_args()
	if ids.is_empty():ids=["r1"]
	HeroIK.debug_contact=true
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	for wid in ids:
		var w=Catalog.get_weapon(wid)
		var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
		var kind=GunLooks.hold_kind(w);if kind=="shoulder":kind="rifle"
		HeroIK.grip_cache.clear();HeroIK.offset_cache.clear()
		for i in range(12):hero.drive(1./30.,{"hold":kind,"hands":1.,"two_hands":true})
		HeroIK.debug_contact=false
		for side in ["R","L"]:
			var g=gun.grip(side);var c=GripField.contact(gun,g.global_transform)
			if c.is_empty():continue
			var to_g=Transform3D(g.global_transform.basis.orthonormalized(),g.global_transform.origin).affine_inverse()
			var styles:Dictionary=gun.get_meta("grip_styles",{});var shapes:Dictionary=gun.get_meta("grip_shapes",{})
			var want=HeroIK.wrist_target(g.global_transform,side,str(styles.get(side,"pistol")),hero.hand_scale(),hero,shapes.get(side,{}),c)
			var got=hero.bone_world(hero.bone["Wrist."+side])
			print("WRIST ",wid," ",side," pos_err=%.3f ang_err=%.2f"%[want.origin.distance_to(got.origin),want.basis.get_rotation_quaternion().angle_to(got.basis.get_rotation_quaternion())])
			var chains=HeroIK.finger_chains(hero,side);var line="JOINTS "+wid+" "+side
			for finger in chains:
				line+=" "+finger+"["
				for b in chains[finger]:line+="%.3f "%GripField.distance(c,to_g*hero.bone_world(b).origin)
				line+="]"
			print(line)
		HeroIK.debug_contact=true
		gun.queue_free();await process_frame
	quit()
