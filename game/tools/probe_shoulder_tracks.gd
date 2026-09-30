extends SceneTree
# Which animation tracks key the Shoulder / UpperArm bones (position vs rotation)?
func _initialize():call_deferred("run")
func run():
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0)
	await process_frame
	var lib_names=hero.player.get_animation_list()
	var counts={}
	for n in lib_names:
		var anim=hero.player.get_animation(n)
		for t in range(anim.get_track_count()):
			var path=str(anim.track_get_path(t))
			for b in ["Shoulder.R","UpperArm.R","Chest","Neck"]:
				if path.ends_with(":"+b):
					var key=b+" "+["value","position","rotation","scale","blend","method","bezier","audio","anim"][clampi(anim.track_get_type(t),0,8)]
					counts[key]=int(counts.get(key,0))+1
	print("ANIMS ",lib_names.size()," TRACKS ",counts)
	var sk=hero.skeleton;var s=sk.find_bone("Shoulder.R")
	print("SHOULDER parent ",sk.get_bone_name(sk.get_bone_parent(s))," rest ",sk.get_bone_rest(s).origin," pose ",sk.get_bone_pose_position(s))
	quit()
