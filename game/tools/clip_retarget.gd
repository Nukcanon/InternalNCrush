extends RefCounted
## Offline retargeting of Quaternius Universal Animation Library 1/2 (CC0)
## clips onto the Ultimate Modular hero skeleton.
##
## World-space delta method: for every mapped bone,
##   target_world = source_world * source_reference^-1 * target_reference
## where the references are matching T-poses (source: the pack's "A_TPose"
## clip, target: the hero bind pose). Bone axis conventions may differ freely.
## The pelvis translation is scaled by the ratio of hip heights.
const FPS=30.
const MAP_UAL1={"Body":"DEF-hips","Abdomen":"DEF-spine.001","Torso":"DEF-spine.002","Chest":"DEF-spine.003","Neck":"DEF-neck","Head":"DEF-head",
	"Shoulder.L":"DEF-shoulder.L","UpperArm.L":"DEF-upper_arm.L","LowerArm.L":"DEF-forearm.L","Wrist.L":"DEF-hand.L",
	"Shoulder.R":"DEF-shoulder.R","UpperArm.R":"DEF-upper_arm.R","LowerArm.R":"DEF-forearm.R","Wrist.R":"DEF-hand.R",
	"UpperLeg.L":"DEF-thigh.L","LowerLeg.L":"DEF-shin.L","Foot.L":"DEF-foot.L","UpperLeg.R":"DEF-thigh.R","LowerLeg.R":"DEF-shin.R","Foot.R":"DEF-foot.R"}
const MAP_UAL2={"Body":"pelvis","Abdomen":"spine_01","Torso":"spine_02","Chest":"spine_03","Neck":"neck_01","Head":"Head",
	"Shoulder.L":"clavicle_l","UpperArm.L":"upperarm_l","LowerArm.L":"lowerarm_l","Wrist.L":"hand_l",
	"Shoulder.R":"clavicle_r","UpperArm.R":"upperarm_r","LowerArm.R":"lowerarm_r","Wrist.R":"hand_r",
	"UpperLeg.L":"thigh_l","LowerLeg.L":"calf_l","Foot.L":"foot_l","UpperLeg.R":"thigh_r","LowerLeg.R":"calf_r","Foot.R":"foot_r"}
static func finger_map(ual2:bool) -> Dictionary:
	var out={}
	for side in ["L","R"]:
		for finger in [["Index","index","f_index"],["Middle","middle","f_middle"],["Ring","ring","f_ring"],["Pinky","pinky","f_pinky"],["Thumb","thumb","thumb"]]:
			for i in range(1,4):
				out["%s%d.%s"%[finger[0],i,side]]="%s_%02d_%s"%[finger[1],i,side.to_lower()] if ual2 else "DEF-%s.%02d.%s"%[finger[2],i,side]
	return out
# Loads a pack; returns {scene, skeleton, player}. The scene is added under `host`.
static func load_pack(path:String,host:Node) -> Dictionary:
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(path,state)!=OK:return {}
	var scene:Node3D=doc.generate_scene(state);host.add_child(scene)
	return {"scene":scene,"skeleton":scene.find_children("*","Skeleton3D",true,false)[0],"player":scene.find_children("*","AnimationPlayer",true,false)[0]}
# World transforms composed from the local poses the player just wrote (the
# skeleton's cached global poses update lazily and can be a frame stale).
# Bones the sampled clip does not key are taken at rest: the mixer would
# otherwise keep applying whatever an earlier clip left on them.
static func world_poses(skeleton:Skeleton3D,keyed={}) -> Array:
	var out=[];out.resize(skeleton.get_bone_count())
	for i in range(skeleton.get_bone_count()):
		var parent=skeleton.get_bone_parent(i)
		var local=skeleton.get_bone_pose(i) if keyed.is_empty() or keyed.has(i) else skeleton.get_bone_rest(i)
		out[i]=(skeleton.global_transform if parent<0 else out[parent])*local
	return out
static func world_rotations(skeleton:Skeleton3D,keyed={}) -> Array:
	var out=[]
	for xf in world_poses(skeleton,keyed):out.append(xf.basis.get_rotation_quaternion())
	return out
static func keyed_bones(pack:Dictionary,clip:String) -> Dictionary:
	if not pack.has("keyed"):pack.keyed={}
	if not pack.keyed.has(clip):
		var anim:Animation=pack.player.get_animation(clip);var out={}
		for t in range(anim.get_track_count()):
			var b=pack.skeleton.find_bone(str(anim.track_get_path(t)).get_slice(":",1))
			if b>=0:out[b]=true
		pack.keyed[clip]=out
	return pack.keyed[clip]
static func sample(pack:Dictionary,clip:String,time:float):
	var player:AnimationPlayer=pack.player
	# Bones a clip does not key must sit at rest, not at the previous clip's pose.
	pack.skeleton.reset_bone_poses()
	player.stop();player.play(clip);player.seek(time,true);player.advance(0.)
# Retargets `clips` from a loaded pack onto `target` (a Skeleton3D inside the
# baked hero, in its bind pose). Returns {name: Animation}.
# Hero rig quirks: legs hang from "Body" (the pelvis mover, parent of Hips), and
# "Foot"/"PT" are IK bones parented to Root. They are carried rigidly by their
# anatomical parent so the skin never stretches.
const CARRIED={"Foot.L":"LowerLeg.L","Foot.R":"LowerLeg.R","PT.L":"LowerLeg.L","PT.R":"LowerLeg.R"}
const MOVER="Body"
# `skin` supplies the true T-pose: the glTF node rest is an arbitrary animation
# frame, only the inverse bind matrices describe the bind (T) pose.
static func retarget(pack:Dictionary,ual2:bool,target:Skeleton3D,skin:Skin,clips:Array,track_prefix:String) -> Dictionary:
	var source:Skeleton3D=pack.skeleton
	var map=(MAP_UAL2 if ual2 else MAP_UAL1).duplicate();map.merge(finger_map(ual2))
	var count=target.get_bone_count();var t_xf=target.global_transform
	# Target reference: bind pose (T-pose) in world space.
	var bind=[];var rest=[]
	var binds={}
	for b in range(skin.get_bind_count()):
		var name=skin.get_bind_name(b) if skin.get_bind_name(b)!="" else target.get_bone_name(skin.get_bind_bone(b))
		binds[name]=skin.get_bind_pose(b).affine_inverse()
	for i in range(count):
		rest.append(target.get_bone_rest(i))
		bind.append(t_xf*binds.get(target.get_bone_name(i),target.get_bone_global_rest(i)))
	# Source reference: the pack's T-pose clip.
	sample(pack,"A_TPose",0.);var ref_keys=keyed_bones(pack,"A_TPose");var s_ref=world_rotations(source,ref_keys)
	var s_pelvis=source.find_bone(map[MOVER]);var mover=target.find_bone(MOVER)
	var s_ref_pelvis:Vector3=world_poses(source,ref_keys)[s_pelvis].origin
	var t_ref_pelvis:Vector3=bind[mover].origin
	var height_scale=t_ref_pelvis.y/maxf(.01,s_ref_pelvis.y)
	var pairs={}
	for t_name in map:
		var ti=target.find_bone(t_name);var si=source.find_bone(map[t_name])
		if ti>=0 and si>=0:pairs[ti]=si
	var carried={}
	for name in CARRIED:
		var bi=target.find_bone(name);var ai=target.find_bone(CARRIED[name])
		if bi>=0 and ai>=0:carried[bi]=ai
	var out={}
	for clip in clips:
		if not pack.player.has_animation(clip):push_warning("missing clip "+clip);continue
		var src_anim:Animation=pack.player.get_animation(clip)
		var anim=Animation.new();anim.length=src_anim.length;anim.loop_mode=Animation.LOOP_LINEAR if clip.ends_with("_Loop") else Animation.LOOP_NONE
		# Every bone is keyed (unmapped ones at rest) so no pose leaks between clips.
		var rot_tracks={};var pos_tracks={}
		for i in range(count):
			var track=anim.add_track(Animation.TYPE_ROTATION_3D);anim.track_set_path(track,NodePath(track_prefix+":"+target.get_bone_name(i)));rot_tracks[i]=track
			if i==mover or carried.has(i):
				track=anim.add_track(Animation.TYPE_POSITION_3D);anim.track_set_path(track,NodePath(track_prefix+":"+target.get_bone_name(i)));pos_tracks[i]=track
		var frames=maxi(1,ceili(src_anim.length*FPS))
		for f in range(frames+1):
			var time=minf(f/FPS,src_anim.length)
			sample(pack,clip,time);var keys=keyed_bones(pack,clip);var s_now=world_rotations(source,keys)
			var s_pos:Vector3=world_poses(source,keys)[s_pelvis].origin
			var world=[];world.resize(count)
			for i in range(count):
				var parent=target.get_bone_parent(i)
				var parent_world:Transform3D=t_xf if parent<0 else world[i if false else parent]
				var desired_rot:Quaternion
				var anchor=carried.get(i,-1)
				if pairs.has(i):desired_rot=s_now[pairs[i]]*s_ref[pairs[i]].inverse()*bind[i].basis.get_rotation_quaternion()
				elif anchor>=0:desired_rot=world[anchor].basis.get_rotation_quaternion()*bind[anchor].basis.get_rotation_quaternion().inverse()*bind[i].basis.get_rotation_quaternion()
				else:desired_rot=parent_world.basis.get_rotation_quaternion()*rest[i].basis.get_rotation_quaternion()
				var local:Transform3D
				if i==mover or anchor>=0:
					var desired_pos:Vector3=t_ref_pelvis+(s_pos-s_ref_pelvis)*height_scale if i==mover else world[anchor]*(bind[anchor].affine_inverse()*bind[i].origin)
					local=parent_world.affine_inverse()*Transform3D(Basis(desired_rot).scaled(bind[i].basis.get_scale()),desired_pos)
				else:
					var q=(parent_world.basis.get_rotation_quaternion().inverse()*desired_rot).normalized()
					local=Transform3D(Basis(q).scaled(rest[i].basis.get_scale()),rest[i].origin)
				world[i]=parent_world*local
				anim.rotation_track_insert_key(rot_tracks[i],time,local.basis.get_rotation_quaternion())
				if pos_tracks.has(i):anim.position_track_insert_key(pos_tracks[i],time,local.origin)
		out[clip]=anim
	return out