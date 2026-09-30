extends SceneTree
# Which way does "rest * Quaternion(RIGHT, -a)" bend each hand's fingers?
# Prints, per side, the fingertip movement in the wrist frame for a +0.8 rad
# flex of the middle finger's first two joints: toward the palm is -Z.
func _initialize():call_deferred("run")
func run():
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	var sk=hero.skeleton
	for side in ["R","L"]:
		var chain:Array=HeroIK.finger_chains(hero,side).Middle
		var straight=HeroIK.finger_frames(sk,chain,[0.,0.,0.,0.])
		var bent=HeroIK.finger_frames(sk,chain,[0.,.8,.8,0.])
		var tip0=HeroIK.segment_end(sk,chain,straight,3,.03);var tip1=HeroIK.segment_end(sk,chain,bent,3,.03)
		print("FLEX ",side," straight tip ",tip0," bent tip ",tip1," delta ",tip1-tip0)
		var thumb:Array=HeroIK.finger_chains(hero,side).Thumb
		var t0=HeroIK.segment_end(sk,thumb,HeroIK.finger_frames(sk,thumb,[0.,0.,0.]),2,.03);var t1=HeroIK.segment_end(sk,thumb,HeroIK.finger_frames(sk,thumb,[0.,.8,.8]),2,.03)
		print("THUMB ",side," delta ",t1-t0," straight ",t0)
		# Palm normal check: knuckle average vs wrist, and where the palm skin is.
		print("KNUCKLES ",side," ",HeroIK.knuckles(hero,side))
	quit()
