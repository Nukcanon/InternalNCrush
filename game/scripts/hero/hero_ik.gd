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
# --- Hand frames -------------------------------------------------------------
# Wrist-local axes of this rig: +Y wrist -> knuckles, -Z palm, thumb -X (right
# hand) / +X (left hand). A "handle" is the item point the palm wraps, in a
# frame with -Z along the item and +Y up. FRAMES give the wrist axes (columns
# x, y, z) inside that handle frame for each grip style and side.
const FRAMES={
	# Fist around a vertical grip: palm toward the gun, thumb up, knuckles forward.
	"pistol":{"R":Basis(Vector3(0,-1,0),Vector3(0,0,-1),Vector3(1,0,0)),"L":Basis(Vector3(0,1,0),Vector3(0,0,-1),Vector3(-1,0,0))},
	# Support hand under a handguard: palm up, thumb forward, knuckles wrapping over the far side.
	"support":{"R":Basis(Vector3(0,0,1),Vector3(-1,0,0),Vector3(0,-1,0)),"L":Basis(Vector3(0,0,-1),Vector3(1,0,0),Vector3(0,-1,0))},
	# Hammer grip on a tool whose blade points along -Z: knuckles down, palm inward.
	"knife":{"R":Basis(Vector3(0,0,1),Vector3(0,-1,0),Vector3(1,0,0)),"L":Basis(Vector3(0,0,-1),Vector3(0,-1,0),Vector3(-1,0,0))},
	# Small object cupped in the palm (grenades): the pistol fist with the item deeper in the hand.
	"hold":{"R":Basis(Vector3(0,-1,0),Vector3(0,0,-1),Vector3(1,0,0)),"L":Basis(Vector3(0,1,0),Vector3(0,0,-1),Vector3(-1,0,0))},
	# Hanging at the side: fingers down, palm toward the body, thumb forward.
	"rest":{"R":Basis(Vector3(0,0,1),Vector3(0,-1,0),Vector3(1,0,0)),"L":Basis(Vector3(0,0,-1),Vector3(0,-1,0),Vector3(-1,0,0))}}
# Handle position inside the wrist frame (metres at hand scale 1).
const PALM={"pistol":Vector3(0,.085,-.025),"support":Vector3(0,.09,-.03),"knife":Vector3(0,.08,-.025),"hold":Vector3(0,.095,-.04),"rest":Vector3(0,.09,-.03)}
# Finger curl per style: index (trigger finger), the other three fingers (proximal, middle, distal) and the thumb.
const CURLS={"pistol":{"index":.5,"fingers":[1.15,1.05,.65],"thumb":.5},"support":{"index":1.0,"fingers":[1.05,.95,.6],"thumb":.55},
	"knife":{"index":1.25,"fingers":[1.3,1.15,.75],"thumb":.6},"hold":{"index":.9,"fingers":[.95,.85,.5],"thumb":.55},"rest":{"index":.35,"fingers":[.4,.35,.2],"thumb":.2}}
# World wrist transform that puts the palm on `handle` (world; may be mirrored
# for left-handed heroes, the frame then mirrors with it).
static func wrist_target(handle:Transform3D,side:String,style:String,hand_scale:float) -> Transform3D:
	var frame:Basis=FRAMES.get(style,FRAMES.pistol)[side]
	var basis:Basis=handle.basis.orthonormalized()*frame
	return Transform3D(basis,handle.origin-basis*(PALM.get(style,PALM.pistol)*hand_scale))
static func solve_arm(hero:HeroCharacter,side:String,target:Transform3D,weight:float,wrist_basis:bool=false):
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
	var wrist_world:Quaternion
	if wrist_basis:wrist_world=target.basis.get_rotation_quaternion()
	else:
		# Legacy markers: identity basis means the aim clip's own wrist orientation.
		var cal:Dictionary=calibrate(hero)
		var facing=hero.facing_basis().get_rotation_quaternion()
		var grip=target.basis.get_rotation_quaternion()*facing.inverse()
		wrist_world=(grip*facing*cal[side]).normalized()
	var parent_world=hero.bone_world(shoulder).basis.get_rotation_quaternion()
	set_world(sk,upper,parent_world,upper_world,weight)
	set_world(sk,lower,upper_world,lower_world,weight)
	set_world(sk,wrist,lower_world,wrist_world,weight)
static func set_world(sk:Skeleton3D,index:int,parent_world:Quaternion,world:Quaternion,weight:float):
	var local=(parent_world.inverse()*world).normalized()
	sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index).slerp(local,weight))
# Procedural finger curl. Each finger is a chain FingerN1 (metacarpal) .. N4
# (tip) with +Y along the bone; flexion is a rotation about the bone's -X from
# its rest pose (measured on the Quaternius rig, tools/probe_curl.gd).
static var finger_bones={}
static func fingers_of(hero:HeroCharacter,side:String) -> Array:
	var key=str([hero.role,side])
	if finger_bones.has(key):return finger_bones[key]
	var out=[]
	for i in range(hero.skeleton.get_bone_count()):
		var n=hero.skeleton.get_bone_name(i)
		if not n.ends_with("."+side):continue
		for finger in ["Index","Middle","Ring","Pinky","Thumb"]:
			if n.begins_with(finger):out.append([i,finger,int(n.substr(finger.length(),1))]);break
	finger_bones[key]=out;return out
# `pointing` keeps the index finger straight (bind pose) for pressing buttons.
static func curl(hero:HeroCharacter,side:String,weight:float,style:String="pistol",pointing:bool=false):
	var c:Dictionary=CURLS.get(style,CURLS.pistol)
	var sk=hero.skeleton
	for entry in fingers_of(hero,side):
		var b:int=entry[0];var finger:String=entry[1];var joint:int=entry[2]
		var amount:float
		if finger=="Thumb":amount=[0.,.35,.6,.7][mini(joint,3)]*float(c.thumb)
		elif joint<=1:amount=.06
		else:amount=float(c.fingers[joint-2])*(float(c.index) if finger=="Index" else 1.)
		var target:Quaternion=sk.get_bone_rest(b).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-amount)
		if pointing and finger=="Index":target=straight(hero,b)
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).slerp(target,weight))
# Local rotation of a bone in the skin bind (T) pose: a straight finger.
static var straight_cache={}
static func straight(hero:HeroCharacter,bone:int) -> Quaternion:
	var key=str([hero.role,bone])
	if not straight_cache.has(key):
		var skin:Skin
		for m in hero.meshes():
			if m.skin:skin=m.skin;break
		var binds={}
		for i in range(skin.get_bind_count()):binds[skin.get_bind_bone(i) if skin.get_bind_name(i)=="" else hero.skeleton.find_bone(skin.get_bind_name(i))]=skin.get_bind_pose(i).affine_inverse()
		var parent=hero.skeleton.get_bone_parent(bone)
		straight_cache[key]=(binds[parent].basis.get_rotation_quaternion().inverse()*binds[bone].basis.get_rotation_quaternion()).normalized() if binds.has(parent) and binds.has(bone) else hero.skeleton.get_bone_pose_rotation(bone)
	return straight_cache[key]