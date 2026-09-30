class_name HeroCharacter
extends Node3D
## 1.4 cartoon hero: a Quaternius Ultimate Modular (CC0) character with its own
## skeleton, original proportions (only the role height scales it) and CC0 clips
## (native + Universal Animation Library 1/2, baked by tools/bake_heroes.gd).
##
## Per frame (drive): AnimationTree locomotion/aim/overlays are advanced
## manually, then the weapon frame is placed at the right shoulder along the aim
## and both hands are solved onto the held item's grips (two-bone IK). The same
## call runs headless on the server, so hit volumes follow the visible pose.
const OUTFITS=["men_swat","women_soldier","men_spacesuit","men_worker","men_adventurer","women_scifi"]
const HEIGHTS=[1.74,1.64,1.88,1.72,1.83,1.62]
const FEMALE_ROLES=[1,5]
const IDENTITIES=["MASON","SERA","BRIGGS","REED","VALE","MINA"]
# Source materials repainted per team (main / light / deep).
const TEAM_SLOTS={
	"men_swat":{"Swat":"main","Swat_Black":"deep"},
	"women_soldier":{"Swat":"main","Brown":"deep"},
	"men_spacesuit":{},
	"men_worker":{"Worker_Vest":"main","Worker_Yellow":"light"},
	"men_adventurer":{"Green":"main","LightGreen":"light"},
	"women_scifi":{"Blue":"main","LightBlue":"light"}}
# Everything above the pelvis is the "upper body" for aim / overlay layers.
const UPPER_ROOTS=["Torso"]
const RUN_SPEED=5.6
static var scenes={}
static var libraries={}
static var native_heights={}
static var bodies={}
static var grip_calibration={}
var role=0
var team=0
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var tree:AnimationTree
var weapon_frame:Node3D # children: held item; aim-aligned at the right shoulder
var held:Node3D # current held item (weapon/gadget) with right_grip/left_grip markers
var hands_weight=1.
var bone={}
var pitch=0.
var state={}
var outlined=false
# First person: the weapon frame follows this node (camera-space view mount).
var frame_override:Node3D
var armor_level=-1
# Finger poses of the last frame (bone -> Quaternion) to ease between grips.
var finger_memory={}
var frame_dt=0.
# First person: the view body is scaled up for longer arms and its hands are
# scaled back (uniformly, at the wrists) to their normal size.
var hand_size=1.
# Hidden server-side rigs (hit volumes only) skip the finger wrap.
var pose_fingers=true
static func scene(role_index:int) -> PackedScene:
	var outfit=OUTFITS[clampi(role_index,0,5)]
	if not scenes.has(outfit):scenes[outfit]=load("res://assets/heroes/"+outfit+".scn")
	return scenes[outfit]
# Clips come from each outfit's own file: rest orientations differ between packs.
static func clips(role_index:int) -> AnimationLibrary:
	var outfit=OUTFITS[clampi(role_index,0,5)]
	if not libraries.has(outfit):
		var library:AnimationLibrary=load("res://assets/heroes/"+outfit+"_clips.res");libraries[outfit]=library
		# The pack's directional run clips ship without looping: legs froze after
		# one cycle while strafing.
		for name in ["Run","Run_Back","Run_Left","Run_Right","Walk","Idle"]:
			if library.has_animation(name):library.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	return libraries[outfit]
func build(role_index:int,team_index:int,ink:bool=false):
	role=clampi(role_index,0,5);team=team_index;outlined=ink
	model=scene(role).instantiate();add_child(model)
	# glTF characters face +Z; the game faces -Z.
	model.rotation.y=PI
	skeleton=model.get_node("Skeleton3D")
	for name in ["Root","Body","Hips","Torso","Chest","Neck","Head","Shoulder.R","UpperArm.R","LowerArm.R","Wrist.R","Shoulder.L","UpperArm.L","LowerArm.L","Wrist.L","UpperLeg.L","LowerLeg.L","Foot.L","UpperLeg.R","LowerLeg.R","Foot.R"]:
		bone[name]=skeleton.find_bone(name)
	var outfit=OUTFITS[role]
	if not native_heights.has(outfit):native_heights[outfit]=rest_height()
	model.scale=Vector3.ONE*HEIGHTS[role]/float(native_heights[outfit])
	for body in skeleton.get_children():
		if body is MeshInstance3D:paint(body,outfit,ink)
	player=AnimationPlayer.new();player.name="AnimationPlayer";model.add_child(player)
	player.add_animation_library("",clips(role))
	tree=HeroAnimation.build_tree(self,player)
	weapon_frame=Node3D.new();weapon_frame.name="WeaponFrame";add_child(weapon_frame)
	drive(0.,{})
# Display-only models (lineups, previews) may simply play a clip.
func play(clip:String,time:=0.):
	if is_instance_valid(tree):tree.active=false
	player.play(clip);player.seek(time,true)
func rest_height() -> float:
	var top=0.
	for body in skeleton.get_children():
		if body is MeshInstance3D:top=maxf(top,(body.transform*body.mesh.get_aabb()).end.y)
	return top*skeleton.transform.basis.get_scale().y
func paint(body:MeshInstance3D,outfit:String,ink:bool):
	var key=str([outfit,body.name,ink])
	if not bodies.has(key):bodies[key]=HeroStyle.with_smooth_normals(body.mesh) if ink else body.mesh
	body.mesh=bodies[key]
	var slots:Dictionary=TEAM_SLOTS.get(outfit,{})
	for surface in range(body.mesh.get_surface_count()):
		var source:Material=body.mesh.surface_get_material(surface)
		var color=source.albedo_color if source is BaseMaterial3D else Color.WHITE
		var material_name=str(source.resource_name) if source else ""
		match str(slots.get(material_name,"")):
			"main":color=HeroStyle.TEAM_MAIN[team]
			"light":color=HeroStyle.TEAM_LIGHT[team]
			"deep":color=HeroStyle.TEAM_DEEP[team]
			_:
				# Every other piece of clothing takes the team hue (keeping its
				# own brightness): trousers, jeans, gloves and boots included.
				if is_cloth(str(body.name),material_name):color=team_tint(color)
		body.set_surface_override_material(surface,HeroStyle.tinted(color,ink,0.))
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
const NON_CLOTH=["Skin","Skin_Darker","Hair","Hair_Brown","Hair_Blond","Hair_Black","Eyebrows","Eye","Moustache","Earrings","Visor","Metal"]
const HEAD_CLOTH=["Worker_Yellow","Blue"]
static func is_cloth(mesh_name:String,material_name:String) -> bool:
	if material_name in NON_CLOTH:return false
	if mesh_name.ends_with("_Head"):return material_name in HEAD_CLOTH
	return true
func team_tint(source:Color) -> Color:
	var hue:Color=HeroStyle.TEAM_MAIN[clampi(team,0,1)]
	var value=clampf(.34+source.v*.8,.36,.95)
	return Color.from_hsv(hue.h,lerpf(hue.s,hue.s*.7,value),value)
func meshes() -> Array:
	return skeleton.get_children().filter(func(n):return n is MeshInstance3D and n.name!="FPArms")
# First person: only the arm/hand mesh is drawn.
var first_person=false
# Per-pose caches (HeroIK.torso_frame): bumped every drive().
var drive_serial=0
var torso_serial=-1
var torso_cache={}
func first_person_only():
	first_person=true
	for mesh in meshes():mesh.hide()
	var arms=skeleton.get_node_or_null("FPArms")
	if arms:
		arms.show();arms.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arms.mesh=slim_arms(arms.mesh,arms.skin)
# First person scales the whole body up for reach; the upper arms and forearms
# are drawn slimmer about their bone axes so they do not fill the screen.
# Hands keep their shape. Built once per arm mesh (shared by every view body).
const FP_ARM_SLIM=.8
const FP_ELBOW_FILL=.55
static var slim_cache={}
# 1.4.2: the upper arm's cut end (at the dropped shoulder) is closed with a flat
# cap in the sleeve's material, so a glimpse of it reads as a sleeve end, not a
# hole. `keep` marks kept vertices; cut edges belong to one kept triangle and
# to a dropped one. Both windings (the cap is seen from either side).
static func cap_cut(arrays:Array,indices:PackedInt32Array,keep:PackedByteArray,kept:PackedInt32Array,welded:Array,per:int):
	var kept_edges={};var dropped={}
	for t in range(0,indices.size(),3):
		var tri=[indices[t],indices[t+1],indices[t+2]]
		var is_kept=keep[tri[0]]==1 or keep[tri[1]]==1 or keep[tri[2]]==1
		for e in range(3):
			var a=tri[e];var b=tri[(e+1)%3]
			var ka=str(welded[a]);var kb=str(welded[b]);var key=ka+"|"+kb if ka<kb else kb+"|"+ka
			if is_kept:
				if not kept_edges.has(key):kept_edges[key]=[]
				kept_edges[key].append([a,b])
			else:dropped[key]=true
	var next={} # welded key -> [vertex, following vertex]
	for key in kept_edges:
		if kept_edges[key].size()==1 and dropped.has(key):
			var e=kept_edges[key][0];next[str(welded[e[0]])]=[e[0],e[1]]
	var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var count=verts.size();var seen={}
	for start in next.keys():
		if seen.has(start):continue
		var loop=[];var k=start
		while next.has(k) and not seen.has(k):
			seen[k]=true;loop.append(next[k][0]);k=str(welded[next[k][1]])
		if loop.size()<3:continue
		var centre=Vector3.ZERO
		for v in loop:centre+=verts[v]
		centre/=loop.size()
		var normal=Vector3.ZERO
		for i in range(loop.size()):normal+=(verts[loop[i]]-centre).cross(verts[loop[(i+1)%loop.size()]]-centre)
		if normal.length()<1e-8:continue
		normal=normal.normalized()
		for side in [1.,-1.]:
			var n=normal*side;var base=count
			copy_vertex(arrays,loop[0],count,per,centre,n);count+=1
			for v in loop:copy_vertex(arrays,v,count,per,verts[v],n);count+=1
			for i in range(loop.size()):
				var a=base;var b=base+1+i;var c=base+1+(i+1)%loop.size()
				# Godot's front faces are clockwise: (c-a)x(b-a) must point along n.
				var pa:Vector3=centre;var pb:Vector3=verts[loop[i]];var pc:Vector3=verts[loop[(i+1)%loop.size()]]
				if (pc-pa).cross(pb-pa).dot(n)<0.:kept.append_array([a,c,b])
				else:kept.append_array([a,b,c])
	arrays[Mesh.ARRAY_INDEX]=kept
# Appends a copy of vertex `src` (every attribute) at `position` with `normal`.
static func copy_vertex(arrays:Array,src:int,count:int,per:int,position:Vector3,normal:Vector3):
	for k in range(arrays.size()):
		if k==Mesh.ARRAY_INDEX or arrays[k]==null:continue
		var a=arrays[k];var size=a.size()/maxi(1,count)
		if size<=0:continue
		for j in range(size):a.append(a[src*size+j])
		arrays[k]=a
	var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];v[count]=position;arrays[Mesh.ARRAY_VERTEX]=v
	if arrays[Mesh.ARRAY_NORMAL]!=null:
		var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];n[count]=normal;arrays[Mesh.ARRAY_NORMAL]=n
func slim_arms(source:Mesh,skin:Skin) -> Mesh:
	if source==null or skin==null:return source
	var key=source.get_instance_id()
	if slim_cache.has(key):return slim_cache[key]
	# Bone axes in mesh space: origin and +Y of each bound arm bone.
	var axes={}
	# 1.4.2: first-person shoulders slide to meet each forearm (HeroIK), which
	# would stretch the shoulder caps into loose pieces: the arms are kept from
	# the upper arm down (its open end sits at the hidden shoulder, off screen).
	var lower={}
	for bind in range(skin.get_bind_count()):
		var name=skin.get_bind_name(bind)
		if name=="":name=skeleton.get_bone_name(skin.get_bind_bone(bind))
		if name.begins_with("UpperArm") or name.begins_with("LowerArm"):
			var bone:Transform3D=skin.get_bind_pose(bind).affine_inverse()
			axes[bind]=[bone.origin,bone.basis.y.normalized(),name.begins_with("UpperArm")]
		if not (name.begins_with("Shoulder") or name in ["Chest","Neck","Head","Abdomen","Hips","Body","Root"]):lower[bind]=true
	var out=ArrayMesh.new()
	for s in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(s)
		var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
		var per=bones.size()/maxi(1,verts.size())
		# Vertices carried mostly by the forearm, wrist and fingers.
		var keep=PackedByteArray();keep.resize(verts.size())
		for i in range(verts.size()):
			var w=0.
			for k in range(per):
				if lower.has(bones[i*per+k]):w+=weights[i*per+k]
			keep[i]=1 if w>=.5 else 0
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array(range(verts.size()))
		var kept=PackedInt32Array()
		for t in range(0,indices.size(),3):
			if keep[indices[t]]==1 or keep[indices[t+1]]==1 or keep[indices[t+2]]==1:kept.append_array([indices[t],indices[t+1],indices[t+2]])
		var welded=[]
		for i in range(verts.size()):welded.append(verts[i].snapped(Vector3.ONE*.0005))
		for i in range(verts.size()):
			# Slim only where arm bones carry (nearly) all of the weight.
			var arm_weight=0.;var best=-1;var bw=-1.;var upper=0.;var fore=0.
			for k in range(per):
				var b=bones[i*per+k];var wgt=weights[i*per+k]
				if axes.has(b):
					arm_weight+=wgt
					if axes[b][2]:upper+=wgt
					else:fore+=wgt
				if wgt>bw:bw=wgt;best=b
			if not axes.has(best) or arm_weight<.6:continue
			var o:Vector3=axes[best][0];var y:Vector3=axes[best][1]
			var rel=verts[i]-o;var along=y*rel.dot(y)
			var factor=lerpf(1.,FP_ARM_SLIM,clampf((arm_weight-.6)/.35,0.,1.))
			# 1.4.2: the elbow (weights shared by upper arm and forearm) collapsed
			# into a thin twist when the arm bent; it is filled out instead.
			factor*=1.+FP_ELBOW_FILL*clampf(4.*upper*fore,0.,1.)
			verts[i]=o+along+(rel-along)*factor
		arrays[Mesh.ARRAY_VERTEX]=verts
		if kept.is_empty():continue
		cap_cut(arrays,indices,keep,kept,welded,per)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},source.surface_get_format(s)&Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		out.surface_set_material(out.get_surface_count()-1,source.surface_get_material(s))
	slim_cache[key]=out
	return out

## Pose update. `s` keys (all optional):
##  velocity (world), grounded, crouch, sprint, pitch (rad, + up), reload (-1 or 0..1),
##  reload_time (s), shot (seconds since last shot), throw (-1 or 0..1), hit (0..1),
##  slide (-1 or 0..1), plant (bool), hold ("rifle"|"pistol"|"item"|"none")
func drive(dt:float,s:Dictionary):
	state=s;frame_dt=dt;drive_serial+=1
	var _t=Prof.now()
	HeroAnimation.update(self,dt,s)
	# First-person arms slide the hidden shoulders (HeroIK.solve_arm); most
	# clips do not key their position, so start every pose from the rest.
	if first_person:
		for side in ["R","L"]:skeleton.set_bone_pose_position(bone["Shoulder."+side],skeleton.get_bone_rest(bone["Shoulder."+side]).origin)
	Prof.add("hero_anim_params",_t);_t=Prof.now()
	tree.advance(dt)
	Prof.add("hero_tree_advance",_t);_t=Prof.now()
	apply_hip_yaw(float(s.get("hip_yaw",0.)))
	pitch=float(s.get("pitch",0.))
	if hand_size!=1.:
		for side in ["R","L"]:skeleton.set_bone_pose_scale(bone["Wrist."+side],Vector3.ONE*hand_size)
	place_weapon_frame(s)
	Prof.add("hero_frame",_t);_t=Prof.now()
	solve_hands(s)
	Prof.add("hero_hands",_t)
# World size of the hands relative to the rig's own units.
func hand_scale() -> float:return absf(skeleton.global_transform.basis.get_scale().y)*hand_size

# Strafing: the legs run their forward cycle turned toward the travel direction
# while chest and aim stay square. In this rig the thighs hang off Body, the
# spine off Hips, and feet / knee targets (Foot.*, PT.*) directly off Root.
func apply_hip_yaw(yaw:float):
	if absf(yaw)<.001:return
	var root_bone=bone.Root;var body=bone.Body;var hips=bone.Hips
	if root_bone<0 or body<0 or hips<0:return
	var root_pose:Transform3D=skeleton.get_bone_pose(root_bone)
	var body_pose:Transform3D=skeleton.get_bone_pose(body)
	var up=(skeleton.transform.basis.inverse()*Vector3.UP).normalized()
	var turn=Basis(up,yaw)
	# Body (legs) turns about its own pivot; Hips gets the inverse turn.
	var body_local=Basis(skeleton.get_bone_pose_rotation(body))
	var body_turned=root_pose.basis.inverse()*turn*root_pose.basis*body_local
	skeleton.set_bone_pose_rotation(body,body_turned.get_rotation_quaternion())
	var hips_local=Basis(skeleton.get_bone_pose_rotation(hips))
	skeleton.set_bone_pose_rotation(hips,(body_turned.inverse()*body_local*hips_local).get_rotation_quaternion())
	# Foot/pole targets swing around the pelvis with the legs.
	var pivot=(root_pose*body_pose).origin
	for name in ["Foot.L","Foot.R","PT.L","PT.R"]:
		var i=skeleton.find_bone(name)
		if i<0 or skeleton.get_bone_parent(i)!=root_bone:continue
		var world:Transform3D=root_pose*skeleton.get_bone_pose(i)
		world.origin=pivot+turn*(world.origin-pivot);world.basis=turn*world.basis
		var local:Transform3D=root_pose.affine_inverse()*world
		skeleton.set_bone_pose_position(i,local.origin);skeleton.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion())
# World transform of a bone composed from current local poses (never stale).
# Parent chains are fixed per rig: built once instead of an array per call
# (bone_world runs many times per pose).
var bone_chains={}
func bone_world(index:int) -> Transform3D:
	var chain:PackedInt32Array=bone_chains.get(index,PackedInt32Array())
	if chain.is_empty():
		var i=index
		while i>=0:chain.insert(0,i);i=skeleton.get_bone_parent(i)
		bone_chains[index]=chain
	var xf=skeleton.global_transform
	for b in chain:xf=xf*skeleton.get_bone_pose(b)
	return xf
func bone_global_in_skeleton(index:int) -> Transform3D:return skeleton.global_transform.affine_inverse()*bone_world(index)
func facing_basis() -> Basis:return global_basis.orthonormalized()
# Aim frame: right shoulder pocket, yaw of the body, pitch of the aim. Items
# are authored with their stock/butt at the origin, forward -Z.
func place_weapon_frame(s:Dictionary):
	if is_instance_valid(frame_override):
		weapon_frame.global_transform=frame_override.global_transform;return
	var hold=str(s.get("hold","rifle"))
	var shoulder:Vector3=bone_world(bone["UpperArm.R"]).origin
	var chest:Vector3=bone_world(bone["Chest"]).origin
	var basis=facing_basis()*Basis(Vector3.RIGHT,clampf(pitch,-1.2,1.2))
	var scale_factor=HEIGHTS[role]/1.8
	var origin:Vector3
	if hold=="pistol" and not bool(s.get("two_hands",true)):
		# One-handed pistol: extended from the shooting shoulder.
		origin=shoulder+basis*Vector3(-.03,-.05,-.30)*scale_factor
	elif hold in ["pistol","item"]:
		origin=chest.lerp(shoulder,.5)+basis*Vector3(0,.02,-.34)*scale_factor
	else:
		origin=shoulder+basis*Vector3(-.035,-.035,.04)*scale_factor
		# Stockless guns are pushed forward so the grip is not at the shoulder.
		if is_instance_valid(held) and held.has_meta("frame_offset"):origin+=basis*Vector3(held.get_meta("frame_offset"))*scale_factor
	var sprint=float(s.get("sprint_blend",0.))
	if sprint>0.:
		# Low ready while sprinting: muzzle down and across the chest.
		# Left-handed heroes are mirrored (negative scale), so their bases are
		# not rotations: blend the underlying rotations, then restore the mirror.
		var ready=facing_basis()*Basis(Vector3.RIGHT,-.75)*Basis(Vector3.UP,.55)
		var mirrored=basis.determinant()<0.
		basis=Basis(basis.get_rotation_quaternion().slerp(ready.get_rotation_quaternion(),sprint))
		if mirrored:basis=basis.scaled(Vector3(-1,-1,-1))
		origin=origin.lerp(chest+facing_basis()*Vector3(.05,-.12,-.18)*scale_factor,sprint)
	weapon_frame.global_transform=Transform3D(basis,origin)
	weapon_frame.scale=Vector3.ONE*scale_factor
func solve_hands(s:Dictionary):
	if not is_instance_valid(held) or not held.visible:return
	var weight=clampf(float(s.get("hands",1.)),0.,1.)
	if weight<=.001:return
	var right:Node3D=held.grip("R") if held.has_method("grip") else held.get_node_or_null("RightGrip")
	var left:Node3D=held.grip("L") if held.has_method("grip") else held.get_node_or_null("LeftGrip")
	# Items with grip styles carry handle markers (the point the palm wraps)
	# and grip shapes; legacy items carry wrist targets in the aim clip's own
	# orientation.
	var styles:Dictionary=held.get_meta("grip_styles",{})
	var shapes:Dictionary=held.get_meta("grip_shapes",{})
	var point=bool(s.get("point",false))
	# Guns carry baked fields of their real surface round the grips (GripField).
	if right:
		if styles.has("R"):grip_hand("R",right.global_transform,str(styles.R),shapes.get("R",{}),weight,point,GripField.contact(held,right.global_transform))
		else:HeroIK.solve_arm(self,"R",right.global_transform,weight);HeroIK.curl(self,"R",weight,"rest",point)
	# Reloading (or pumping): the support hand works the gun instead of gripping it.
	if held is GunModel and styles.has("L"):
		var work:Dictionary=ReloadMotion.support(held,s)
		if not work.is_empty():
			var handle=held.global_transform*Transform3D(work.get("basis",Basis.IDENTITY),work.position)
			grip_hand("L",handle,str(work.style),work.get("shape",{}),weight)
			return
	if bool(s.get("two_hands",true)):
		if left==null:return
		var lw=weight*float(s.get("left_hand",1.))
		if styles.has("L"):
			var handle:Transform3D=left.global_transform
			var c=support_contact(handle,shapes.get("L",{}))
			# Third person: a handguard beyond the support arm's reach (long guns
			# held from the shoulder) is taken further back along the gun, in 1 cm
			# steps so the grip caches stay warm. First person arms always reach.
			if not first_person and held is GunModel:
				var shoulder=bone_world(bone["UpperArm.L"]).origin;var reach=arm_length("L")*.97
				for i in range(2):
					var over=shoulder.distance_to(HeroIK.wrist_target(handle,"L",str(styles.L),hand_scale(),self,shapes.get("L",{}),c).origin)-reach
					if over<=0.:break
					handle.origin+=handle.basis.orthonormalized().z*snappedf(over*1.2+.005,.01)
					c=support_contact(handle,shapes.get("L",{}))
			grip_hand("L",handle,str(styles.L),shapes.get("L",{}),lw,false,c)
		else:HeroIK.solve_arm(self,"L",left.global_transform,lw);HeroIK.curl(self,"L",lw)
	elif styles.has("R"):
		# One-handed: the free arm hangs at the side (off screen in first person).
		var side_rest=Transform3D(facing_basis()*HeroIK.FRAMES.rest.L,global_position+facing_basis()*Vector3(-.27,.88,-.10)*(HEIGHTS[role]/1.8)*absf(global_basis.get_scale().y))
		HeroIK.solve_arm(self,"L",side_rest,weight,true);HeroIK.curl(self,"L",weight,"rest")
# Grip field contact for the support hand (pistol cup: the support hand closes
# round the firing hand's fingers, a box round the grip).
func support_contact(handle:Transform3D,shape:Dictionary) -> Dictionary:
	var c=GripField.contact(held,handle)
	if not c.is_empty() and bool(shape.get("cup",false)):
		var cup=HeroIK.world_shape(handle,"pistol",shape);c.box={"half":cup.half,"round":cup.round}
	return c
# Shoulder-to-wrist length of an arm (world), measured once per hero scale.
func arm_length(side:String) -> float:
	var key="arm_len_"+side
	var scale=absf(skeleton.global_transform.basis.get_scale().y)
	if has_meta(key) and is_equal_approx(float(get_meta(key)[1]),scale):return float(get_meta(key)[0])
	var u=bone_world(bone["UpperArm."+side]).origin;var l=bone_world(bone["LowerArm."+side]).origin;var w=bone_world(bone["Wrist."+side]).origin
	var length=u.distance_to(l)+l.distance_to(w)
	set_meta(key,[length,scale]);return length
# One hand on a handle: wrist placed from the grip shape, arm IK, finger wrap.
func grip_hand(side:String,handle:Transform3D,style:String,shape:Dictionary,weight:float,point:bool=false,contact:Dictionary={}):
	var _t=Prof.now()
	HeroIK.solve_arm(self,side,HeroIK.wrist_target(handle,side,style,hand_scale(),self,shape,contact),weight,true)
	Prof.add("hero_arm_ik",_t);_t=Prof.now()
	if pose_fingers:HeroIK.apply_grip(self,side,handle,style,shape,weight,point,contact)
	Prof.add("hero_fingers",_t)
# `mount`: false keeps the item where it is (e.g. a camera-space view model);
# the hands still follow its grip markers.
func hold(item:Node3D,mount:bool=true):
	if is_instance_valid(held) and held!=item and held.get_parent()==weapon_frame:held.hide()
	held=item
	if is_instance_valid(item) and not mount:item.show();return
	if is_instance_valid(item):
		if item.get_parent()!=weapon_frame:
			if item.get_parent():item.get_parent().remove_child(item)
			weapon_frame.add_child(item)
		item.show()
# Hides outfit parts by source mesh suffix ("_Head", "_Legs", "_Feet").
func hide_parts(suffixes:Array):
	for mesh in meshes():
		for suffix in suffixes:
			if str(mesh.name).ends_with(suffix):mesh.hide()
# Armour tier (0..2) worn over the outfit. 1.4.2: the vest is fitted to each
# hero's own torso and skinned to its skeleton (FittedArmor); the old strapped
# box vest stays as the fallback for an outfit without a torso mesh.
func set_armor(level:int):
	level=clampi(level,0,2)
	if level==armor_level and (level==0 or skeleton.has_node("ChestMount") or skeleton.has_node("FittedArmor")):return
	armor_level=level
	for old in ["ChestMount","FittedArmor"]:
		var node=skeleton.get_node_or_null(old)
		if node:skeleton.remove_child(node);node.queue_free()
	if level==0 or meshes().all(func(m):return not m.visible):return
	var fitted=FittedArmor.build(self,level)
	if fitted:
		skeleton.add_child(fitted)
		if first_person:fitted.hide()
		return
	HeroHitbox.load_volumes()
	for v in HeroHitbox.volumes.get(OUTFITS[role],[]):
		if v.bone=="Chest" and v.type=="ellipsoid":
			var mount=BoneAttachment3D.new();mount.name="ChestMount";mount.bone_name="Chest";skeleton.add_child(mount)
			GearModels.vest(mount,level,team,HeroHitbox.v3(v.c),HeroHitbox.v3(v.e))
			break
# Corpses wear what the living hero wore: armour and the carried kit (the
# weapon that was in hand goes back to its place).
func dress_like(source:HeroCharacter):
	if not is_instance_valid(source):return
	if source.armor_level>0:set_armor(source.armor_level)
	var spec:Dictionary=source.get_meta("carried_spec",{})
	if not spec.is_empty():
		var copy=spec.duplicate();copy.primary_out=false;copy.secondary_out=false
		CarriedGear.apply(self,copy)
# Bone-attached node on a hand (melee tools, thrown items).
func hand_attachment(side:String) -> BoneAttachment3D:
	var name="Hand"+side
	var node=skeleton.get_node_or_null(name)
	if node:return node
	var attach=BoneAttachment3D.new();attach.name=name;attach.bone_name="Wrist."+side;skeleton.add_child(attach)
	return attach
# Head position for nameplates/reticles.
func head_position() -> Vector3:return bone_world(bone.Head).origin
