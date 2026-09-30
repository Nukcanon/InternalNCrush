extends SceneTree
# Arm lengths, torso bones and shoulder / head positions of the hero rig (model space, scale 1).
func _initialize():call_deferred("run")
func run():
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	for i in range(4):await process_frame
	var names=[]
	for i in range(hero.skeleton.get_bone_count()):names.append(hero.skeleton.get_bone_name(i))
	print("BONES ",names)
	print("RIG head ",hero.head_position()-hero.global_position)
	for n in ["Hips","Abdomen","Torso","Chest","Neck","Spine","Spine1","Spine2"]:
		if hero.skeleton.find_bone(n)>=0:print("RIG ",n," ",hero.bone_world(hero.skeleton.find_bone(n)).origin-hero.global_position)
	for side in ["L","R"]:
		var prev=Vector3.INF
		for n in ["Shoulder."+side,"UpperArm."+side,"LowerArm."+side,"Wrist."+side]:
			var p=hero.bone_world(hero.bone[n]).origin-hero.global_position
			print("RIG ",n," ",p," seg ",(p.distance_to(prev) if prev.is_finite() else 0.))
			prev=p
	quit()
