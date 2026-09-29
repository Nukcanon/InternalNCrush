class_name HeroIK
extends RefCounted
## Analytic two-bone arm IK on the hero skeleton (UpperArm -> LowerArm -> Wrist).
## Targets are wrist transforms in world space. The wrist orientation keeps the
## hand pose of the reference aim clip, rotated with the grip marker.
const POLE={"R":Vector3(.55,-.75,.35),"L":Vector3(-.55,-.75,.35)} # hero-local: +x right, -z forward
static var calibration={}
static func rot(hero:HeroCharacter,index:int) -> Quaternion:return hero.bone_world(index).basis.get_rotation_quaternion()
# Wrist orientation relative to the facing frame in the two-handed aim clip.
static func calibrate(hero:HeroCharacter) -> Dictionary:
	var key=hero.role
	if calibration.has(key):return calibration[key]
	var saved=hero.tree.active;hero.tree.active=false
	var anim=hero.player.get_animation("Pistol_Aim_Neutral")
	var out={}
	for side in ["R","L"]:
		var wrist=hero.skeleton.find_bone("Wrist."+side)
		var track=anim.find_track(NodePath("Skeleton3D:Wrist."+side),Animation.TYPE_ROTATION_3D)
		# Evaluate the clip pose directly from its tracks (no mixer involved).
		var pose={}
		for t in range(anim.get_track_count()):
			if anim.track_get_type(t)!=Animation.TYPE_ROTATION_3D:continue
			var b=hero.skeleton.find_bone(str(anim.track_get_path(t)).get_slice(":",1))
			if b>=0:pose[b]=anim.rotation_track_interpolate(t,.1)
		var chain=[];var i=wrist
		while i>=0:chain.push_front(i);i=hero.skeleton.get_bone_parent(i)
		var q=Quaternion.IDENTITY
		for b in chain:q=q*Quaternion(pose.get(b,hero.skeleton.get_bone_pose_rotation(b)))
		# Clip space: glTF +Z forward; hero facing is the model rotated by PI.
		out[side]=Quaternion(Vector3.UP,PI)*q
	hero.tree.active=saved
	calibration[key]=out;return out
static func solve_arm(hero:HeroCharacter,side:String,target:Transform3D,weight:float):
	var sk=hero.skeleton
	var upper=hero.bone["UpperArm."+side];var lower=hero.bone["LowerArm."+side];var wrist=hero.bone["Wrist."+side]
	var shoulder=hero.bone["Shoulder."+side]
	var wu=hero.bone_world(upper);var wl=hero.bone_world(lower);var ww=hero.bone_world(wrist)
	var a:Vector3=wu.origin;var b:Vector3=wl.origin;var c:Vector3=ww.origin
	var la=a.distance_to(b);var lb=b.distance_to(c)
	var t:Vector3=target.origin
	var d=clampf(a.distance_to(t),absf(la-lb)+.01,(la+lb)*.999)
	var dir=(t-a).normalized()
	var pole:Vector3=a+hero.facing_basis()*POLE[side]
	var perp=((pole-a)-dir*(pole-a).dot(dir))
	if perp.length_squared()<.000001:perp=hero.facing_basis()*Vector3.DOWN
	perp=perp.normalized()
	var cos_a=clampf((la*la+d*d-lb*lb)/(2.*la*d),-1.,1.)
	var elbow=a+dir*la*cos_a+perp*la*sqrt(1.-cos_a*cos_a)
	var q1=Quaternion((b-a).normalized(),(elbow-a).normalized())
	var upper_world=(q1*wu.basis.get_rotation_quaternion()).normalized()
	var c1=elbow+q1*(c-b)
	var q2=Quaternion((c1-elbow).normalized(),(a+dir*d-elbow).normalized())
	var lower_world=(q2*q1*wl.basis.get_rotation_quaternion()).normalized()
	var cal:Dictionary=calibrate(hero)
	var facing=hero.facing_basis().get_rotation_quaternion()
	var grip=target.basis.get_rotation_quaternion()*facing.inverse()
	var wrist_world=(grip*facing*cal[side]).normalized()
	var parent_world=hero.bone_world(shoulder).basis.get_rotation_quaternion()
	set_world(sk,upper,parent_world,upper_world,weight)
	set_world(sk,lower,upper_world,lower_world,weight)
	set_world(sk,wrist,lower_world,wrist_world,weight)
static func set_world(sk:Skeleton3D,index:int,parent_world:Quaternion,world:Quaternion,weight:float):
	var local=(parent_world.inverse()*world).normalized()
	sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index).slerp(local,weight))
