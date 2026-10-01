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
		# The arms reach far from the rig's rest bounds (fixed shoulders below the
		# view, a throw above it): a generous bound so they are never culled.
		arms.custom_aabb=AABB(Vector3(-2.5,-2.5,-2.5),Vector3(5.,5.,5.))
		# 1.4.4: the arms are cut from the outfit's body mesh here (shoulders
		# included) and take its team paint surface by surface.
		var body:MeshInstance3D
		for mesh in meshes():
			if str(mesh.name).ends_with("_Body") and mesh.skin:body=mesh;break
		if body:
			var built=fp_arms(body.mesh,body.skin)
			arms.mesh=built[0];arms.skin=body.skin
			for i in range(built[1].size()):arms.set_surface_override_material(i,body.get_surface_override_material(built[1][i]))
# First person (1.4.4): the arms are the outfit's own arm triangles from the
# shoulder down, thickened about the upper-arm and forearm bone axes to the
# same girth on every hero (mean radius in rig units; the cartoon rigs' arms
# are thin next to their big hands, the women's half the men's, and the user
# wants arms that read as real arms). The hands keep their shape. Built once
# per outfit mesh (shared by every view body).
# World radii in first person (1.4.4): 1.5x the 1.4.3 first-person forearm
# (0.057 m on MASON), the same on every hero. FP_BODY_SCALE: the view body's scale.
const FP_FOREARM_R=.086
const FP_UPPERARM_R=.09
const FP_BODY_SCALE=2.0
const FP_WRIST_TAPER=.62 # fallback taper when the hand mesh cannot be measured
# 1.4.5: the forearm tapers to the hand's own wrist girth (times this margin),
# so the arm runs into the hand without a step (a fixed thick wrist next to
# the small hand looked wrong on bare-armed heroes).
const FP_WRIST_MATCH=1.12
const FP_HAND=1.15 # first-person hand scale (Actor.VIEW_HAND); hand_size = FP_HAND/FP_BODY_SCALE
# First person: how far the support hand may slide back along a handguard /
# off a vertical grip before the shoulder stretches instead.
const FP_SLIDE=.06
const FP_SLIDE_GRIP=0.
const FP_ELBOW_FILL=.3
static var slim_cache={}
# Bones whose triangles make up the first-person arm mesh.
const FP_ARM_BONES=["Shoulder","UpperArm","LowerArm","Wrist","Index","Middle","Ring","Pinky","Thumb"]
# 1.4.2: the upper arm's cut end (at the dropped shoulder) is closed with a flat
# cap in the sleeve's material, so a glimpse of it reads as a sleeve end, not a
# hole. `keep` marks kept vertices; cut edges belong to one kept triangle and
# to a dropped one. Both windings (the cap is seen from either side).
static func cap_cut(arrays:Array,indices:PackedInt32Array,keep:PackedByteArray,kept:PackedInt32Array,welded:Array,per:int,all_vertices:bool=false):
	var kept_edges={};var dropped={}
	for t in range(0,indices.size(),3):
		var tri=[indices[t],indices[t+1],indices[t+2]]
		var is_kept=(keep[tri[0]]==1 and keep[tri[1]]==1 and keep[tri[2]]==1) if all_vertices else (keep[tri[0]]==1 or keep[tri[1]]==1 or keep[tri[2]]==1)
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
## First-person arm mesh from an outfit's body mesh: [mesh, source surface of
## each output surface]. Triangles whose vertices all belong mainly to arm
## bones (shoulder to fingertips) are kept, the cut at the chest is capped, and
## upper arm / forearm vertices are pushed out radially from their bone axes.
func fp_arms(source:Mesh,skin:Skin) -> Array:
	if source==null or skin==null:return [source,range(source.get_surface_count() if source else 0)]
	var key=source.get_instance_id()
	if slim_cache.has(key):return slim_cache[key]
	# Bone axes in mesh space: origin and +Y of each bound arm bone.
	var axes={};var arm={};var wrists={}
	for bind in range(skin.get_bind_count()):
		var name=skin.get_bind_name(bind)
		if name=="":name=skeleton.get_bone_name(skin.get_bind_bone(bind))
		if name.begins_with("UpperArm") or name.begins_with("LowerArm"):
			var bone:Transform3D=skin.get_bind_pose(bind).affine_inverse()
			axes[bind]=[bone.origin,bone.basis.y.normalized(),name.begins_with("UpperArm")]
		if name.begins_with("Wrist."):wrists[bind]=name.substr(name.length()-1)
		for prefix in FP_ARM_BONES:
			if name.begins_with(prefix):arm[bind]=true;break
	# Mean radius of each arm bone's own vertices, for the girth factors.
	var girth={}
	for s in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(s)
		var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
		if bones==null or weights==null:continue
		var per=bones.size()/maxi(1,verts.size())
		for i in range(verts.size()):
			var best=-1;var bw=-1.
			for k in range(per):
				if weights[i*per+k]>bw:bw=weights[i*per+k];best=bones[i*per+k]
			if not axes.has(best) or bw<.8:continue
			var rel=verts[i]-axes[best][0];var y:Vector3=axes[best][1]
			if not girth.has(best):girth[best]=[0.,0]
			girth[best][0]+=(rel-y*rel.dot(y)).length();girth[best][1]+=1
	var factors={};var lengths={}
	# Mesh units to world metres in first person.
	var unit=absf((model.transform*skeleton.transform).basis.get_scale().y)*FP_BODY_SCALE
	for b in axes:
		var mean=girth[b][0]/girth[b][1] if girth.has(b) and girth[b][1]>0 else .05
		factors[b]=clampf((FP_UPPERARM_R if axes[b][2] else FP_FOREARM_R)/maxf(.001,mean*unit),.7,3.)
		# Bone length: to the child joint (forearm -> wrist, upper arm -> forearm).
		var child_prefix="LowerArm" if axes[b][2] else "Wrist"
		var side=skin.get_bind_name(b) if skin.get_bind_name(b)!="" else skeleton.get_bone_name(skin.get_bind_bone(b))
		side=side.substr(side.length()-1)
		lengths[b]=.2
		for other in range(skin.get_bind_count()):
			var name=skin.get_bind_name(other)
			if name=="":name=skeleton.get_bone_name(skin.get_bind_bone(other))
			if name==child_prefix+"."+side:lengths[b]=maxf(.05,(skin.get_bind_pose(other).affine_inverse().origin-axes[b][0]).length())
	# 1.4.5: the forearm's end factor matches the hand's own girth just past
	# the wrist joint (hand vertices, measured about the forearm axis), scaled
	# as the hand is in first person, so the arm runs into the hand without a
	# step. `ends`: forearm bind -> factor at the wrist.
	var ends={};var fore_of={}
	for b in axes:
		if axes[b][2]:continue
		var nm=skin.get_bind_name(b) if skin.get_bind_name(b)!="" else skeleton.get_bone_name(skin.get_bind_bone(b))
		fore_of[nm.substr(nm.length()-1)]=b
	var wrist_girth={};var fore_end={}
	for s in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(s)
		var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
		if bones==null or weights==null:continue
		var per=bones.size()/maxi(1,verts.size())
		for i in range(verts.size()):
			var best=-1;var bw=-1.
			for k in range(per):
				if weights[i*per+k]>bw:bw=weights[i*per+k];best=bones[i*per+k]
			if bw<.8:continue
			if axes.has(best) and not axes[best][2]:
				# ...and the forearm mesh's own girth near its wrist end.
				var r=verts[i]-axes[best][0];var ay:Vector3=axes[best][1]
				if r.dot(ay)>.8*float(lengths[best]):
					if not fore_end.has(best):fore_end[best]=[0.,0]
					fore_end[best][0]+=(r-ay*r.dot(ay)).length();fore_end[best][1]+=1
				continue
			if not wrists.has(best) or not fore_of.has(wrists[best]):continue
			var fb=fore_of[wrists[best]];var frel=verts[i]-axes[fb][0];var fy:Vector3=axes[fb][1]
			var past=frel.dot(fy)-float(lengths[fb])
			if past<-.02*float(lengths[fb]) or past>.22*float(lengths[fb]):continue
			if not wrist_girth.has(fb):wrist_girth[fb]=[0.,0]
			wrist_girth[fb][0]+=(frel-fy*frel.dot(fy)).length();wrist_girth[fb][1]+=1
	for b in wrist_girth:
		if wrist_girth[b][1]<4:continue
		var end_r=fore_end[b][0]/fore_end[b][1] if fore_end.has(b) and fore_end[b][1]>3 else (girth[b][0]/girth[b][1] if girth.has(b) and girth[b][1]>0 else .05)
		var hand_r=wrist_girth[b][0]/wrist_girth[b][1]*FP_HAND/FP_BODY_SCALE
		ends[b]=clampf(hand_r*FP_WRIST_MATCH/maxf(.001,end_r),.5,float(factors[b]))
		if OS.is_stdout_verbose():print("fp_arms wrist match: forearm end r %.4f hand wrist r %.4f -> end factor %.2f (elbow factor %.2f)"%[end_r,hand_r,ends[b],factors[b]])
	var out=ArrayMesh.new();var sources=[]
	for s in range(source.get_surface_count()):
		var arrays=source.surface_get_arrays(s)
		var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
		if bones==null or weights==null:continue
		var per=bones.size()/maxi(1,verts.size())
		# Vertices carried mostly by arm bones.
		var keep=PackedByteArray();keep.resize(verts.size())
		for i in range(verts.size()):
			var w=0.
			for k in range(per):
				if arm.has(bones[i*per+k]):w+=weights[i*per+k]
			keep[i]=1 if w>=.5 else 0
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array(range(verts.size()))
		var kept=PackedInt32Array()
		for t in range(0,indices.size(),3):
			if keep[indices[t]]==1 and keep[indices[t+1]]==1 and keep[indices[t+2]]==1:kept.append_array([indices[t],indices[t+1],indices[t+2]])
		if kept.is_empty():continue
		var welded=[]
		for i in range(verts.size()):welded.append(verts[i].snapped(Vector3.ONE*.0005))
		for i in range(verts.size()):
			# Thicken only where arm bones carry (nearly) all of the weight, so the
			# wrist and the shoulder taper into the hand and the chest.
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
			var factor=lerpf(1.,float(factors[best]),clampf((arm_weight-.6)/.35,0.,1.))
			# A forearm tapers toward the wrist (a real one narrows to about
			# 60% of its girth at the elbow); the hand keeps its size.
			if not axes[best][2]:
				var t=clampf(rel.dot(y)/float(lengths[best]),0.,1.)
				factor=lerpf(factor,float(ends.get(best,maxf(.7,factor*FP_WRIST_TAPER))),smoothstep(.1,1.,t))
			# The elbow (weights shared by upper arm and forearm) collapses into a
			# thin twist when the arm bends; it is filled out a little.
			factor*=1.+FP_ELBOW_FILL*clampf(4.*upper*fore,0.,1.)
			verts[i]=o+along+(rel-along)*factor
		arrays[Mesh.ARRAY_VERTEX]=verts
		# The cut at the chest is closed (a kept triangle's edge shared with a
		# dropped one): the arm never shows as a hollow tube.
		cap_cut(arrays,indices,keep,kept,welded,per,true)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},source.surface_get_format(s)&Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		out.surface_set_material(out.get_surface_count()-1,source.surface_get_material(s))
		sources.append(s)
	slim_cache[key]=[out,sources]
	return slim_cache[key]

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
	# 1.4.4: a throw keeps the wrist straight (the hand continues the forearm).
	for side in straight_wrist:
		var wrist=bone["Wrist."+side]
		skeleton.set_bone_pose_rotation(wrist,skeleton.get_bone_pose_rotation(wrist).slerp(HeroIK.straight(self,wrist),float(straight_wrist[side])))
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
# 1.4.4: wrist transforms (world) that replace the held item's grips for a
# side, e.g. the first-person melee swing (the tool rides the hand bone). The
# fingers close into a fist; the other arm hangs.
var wrist_override={}
# Sides whose wrist is held straight after the hands are solved (side -> weight).
var straight_wrist={}
func solve_hands(s:Dictionary):
	var weight=clampf(float(s.get("hands",1.)),0.,1.)
	if not wrist_override.is_empty():
		if weight<=.001:return
		for side in ["R","L"]:
			if wrist_override.has(side):
				HeroIK.solve_arm(self,side,wrist_override[side],weight,true)
				# Fingers: closed round the tool's handle when its shape is given
				# ("tool_<side>": centre in the wrist bone's space, half, round), else
				# a fist, or the cupped throwing hand opening on release.
				if wrist_override.has("tool_"+side):
					var tool:Dictionary=wrist_override["tool_"+side]
					HeroIK.fingers_round(self,side,Vector3(tool.centre),tool,weight)
				else:HeroIK.curl(self,side,weight,str(wrist_override.get("curl_"+side,"fist")))
				var open=float(wrist_override.get("open_"+side,0.))
				if open>0.:HeroIK.curl(self,side,weight*open,"open")
				# A rigid wrist over a swing: at rest ("capture") the solved wrist
				# angle is remembered; while swinging the hand keeps that angle to
				# the forearm, so arm, fist and tool turn as one piece.
				var wrist=bone["Wrist."+side];var key="rigid_wrist_"+side
				if bool(wrist_override.get("capture_"+side,false)) or not has_meta(key):set_meta(key,skeleton.get_bone_pose_rotation(wrist))
				elif bool(wrist_override.get("rigid_"+side,false)):skeleton.set_bone_pose_rotation(wrist,Quaternion(get_meta(key)))
			else:hang_arm(side,weight)
		return
	if not is_instance_valid(held) or not held.visible:return
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
			# A handguard beyond the support arm's reach (long guns held from the
			# shoulder) is taken further back along the gun, in 1 cm steps so the
			# grip caches stay warm. 1.4.4: first person too, from its fixed shoulder.
			if held is GunModel:
				var shoulder=bone_world(bone["UpperArm.L"]).origin;var reach=arm_length("L")*.97
				# First person: at most FP_SLIDE back along a handguard (the hand
				# stays on the front half), and hardly at all off a vertical grip
				# or magazine (a "pistol" support style); the fixed shoulder then
				# stretches for the rest (HeroIK.solve_arm), out of view.
				var cap=INF
				if first_person:
					var anchor=HeroIK.fp_anchor(self,"L")
					if anchor!=Vector3.INF:shoulder=anchor;reach=arm_length("L")*.94
					cap=FP_SLIDE_GRIP if str(styles.L)=="pistol" else FP_SLIDE
				var slid=0.
				for i in range(2):
					var over=shoulder.distance_to(HeroIK.wrist_target(handle,"L",str(styles.L),hand_scale(),self,shapes.get("L",{}),c).origin)-reach
					if over<=0. or slid>=cap:break
					var step=minf(snappedf(over*1.2+.005,.01),cap-slid)
					handle.origin+=handle.basis.orthonormalized().z*step;slid+=step
					c=support_contact(handle,shapes.get("L",{}))
			grip_hand("L",handle,str(styles.L),shapes.get("L",{}),lw,false,c)
		else:HeroIK.solve_arm(self,"L",left.global_transform,lw);HeroIK.curl(self,"L",lw)
	elif styles.has("R"):
		# One-handed: the free arm hangs at the side (off screen in first person).
		hang_arm("L",weight)
# The free arm hanging at the side: fingers down, palm toward the body. In first
# person it hangs from its fixed shoulder anchor (well below the view).
func hang_arm(side:String,weight:float):
	var x=-.27 if side=="L" else .27
	var at:Vector3=global_position+facing_basis()*Vector3(x,.88,-.10)*(HEIGHTS[role]/1.8)*absf(global_basis.get_scale().y)
	if first_person:
		var anchor=HeroIK.fp_anchor(self,side)
		if anchor!=Vector3.INF:at=anchor+facing_basis().orthonormalized()*Vector3(.04*(-1. if side=="L" else 1.),-arm_length(side)*.9,.06)
	var side_rest=Transform3D(facing_basis()*HeroIK.FRAMES.rest[side],at)
	HeroIK.solve_arm(self,side,side_rest,weight,true);HeroIK.curl(self,side,weight,"rest")
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
