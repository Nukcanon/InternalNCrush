extends SceneTree
# Prints the hand bone hierarchy and rest poses of one outfit (finger curl design).
func _initialize():call_deferred("run")
func run():
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	var sk=hero.skeleton
	for i in range(sk.get_bone_count()):
		var n=sk.get_bone_name(i)
		if n.ends_with(".R") and (n.begins_with("Wrist") or n.begins_with("Index") or n.begins_with("Middle") or n.begins_with("Ring") or n.begins_with("Pinky") or n.begins_with("Thumb") or n.begins_with("LowerArm")):
			var rest=sk.get_bone_rest(i);var parent=sk.get_bone_parent(i)
			print("%s parent=%s rest_pos=%s rest_rot=%s len=%.4f"%[n,sk.get_bone_name(parent) if parent>=0 else "-",rest.origin,rest.basis.get_euler(),rest.origin.length()])
	# Wrist-local direction of each finger's first joint, to find the flexion axis.
	var wrist=sk.find_bone("Wrist.R");var ww=hero.bone_world(wrist)
	for f in ["Index","Middle","Ring","Pinky","Thumb"]:
		var chain=[]
		for i in range(sk.get_bone_count()):
			var n=sk.get_bone_name(i)
			if n.begins_with(f) and n.ends_with(".R"):chain.append(i)
		for b in chain:
			var w=hero.bone_world(b);var kids=sk.get_bone_children(b)
			var tip=hero.bone_world(kids[0]).origin if kids.size()>0 else w.origin
			var dir_local=(w.basis.inverse()*(tip-w.origin)).normalized() if kids.size()>0 else Vector3.ZERO
			print("  %s: dir_in_own_basis=%s wristlocal_pos=%s"%[sk.get_bone_name(b),dir_local,ww.affine_inverse()*w.origin])
	print("wrist basis (world, hero facing -Z): x=%s y=%s z=%s"%[ww.basis.x,ww.basis.y,ww.basis.z])
	print("PROBE_OK");quit()
