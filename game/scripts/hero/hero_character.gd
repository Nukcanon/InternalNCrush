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
func first_person_only():
	for mesh in meshes():mesh.hide()
	var arms=skeleton.get_node_or_null("FPArms")
	if arms:arms.show();arms.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Pose update. `s` keys (all optional):
##  velocity (world), grounded, crouch, sprint, pitch (rad, + up), reload (-1 or 0..1),
##  reload_time (s), shot (seconds since last shot), throw (-1 or 0..1), hit (0..1),
##  slide (-1 or 0..1), plant (bool), hold ("rifle"|"pistol"|"item"|"none")
func drive(dt:float,s:Dictionary):
	state=s
	HeroAnimation.update(self,dt,s)
	tree.advance(dt)
	apply_hip_yaw(float(s.get("hip_yaw",0.)))
	pitch=float(s.get("pitch",0.))
	place_weapon_frame(s)
	solve_hands(s)

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
func bone_world(index:int) -> Transform3D:
	var chain=[]
	var i=index
	while i>=0:chain.push_front(i);i=skeleton.get_bone_parent(i)
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
	# Items with grip styles carry handle markers (the point the palm wraps);
	# legacy items carry wrist targets in the aim clip's own orientation.
	var styles:Dictionary=held.get_meta("grip_styles",{})
	var hand_scale=absf(skeleton.global_transform.basis.get_scale().y)
	var point=bool(s.get("point",false))
	if right:
		if styles.has("R"):
			var style=str(styles.R)
			HeroIK.solve_arm(self,"R",HeroIK.wrist_target(right.global_transform,"R",style,hand_scale),weight,true);HeroIK.curl(self,"R",weight,style,point)
		else:HeroIK.solve_arm(self,"R",right.global_transform,weight);HeroIK.curl(self,"R",weight,"pistol",point)
	# Reloading (or pumping): the support hand works the gun instead of gripping it.
	if held is GunModel and styles.has("L"):
		var work:Dictionary=ReloadMotion.support(held,s)
		if not work.is_empty():
			var handle=held.global_transform*Transform3D(Basis.IDENTITY,work.position)
			HeroIK.solve_arm(self,"L",HeroIK.wrist_target(handle,"L",str(work.style),hand_scale),weight,true);HeroIK.curl(self,"L",weight,str(work.style))
			return
	if bool(s.get("two_hands",true)):
		if left==null:return
		var lw=weight*float(s.get("left_hand",1.))
		if styles.has("L"):
			var style=str(styles.L)
			HeroIK.solve_arm(self,"L",HeroIK.wrist_target(left.global_transform,"L",style,hand_scale),lw,true);HeroIK.curl(self,"L",lw,style)
		else:HeroIK.solve_arm(self,"L",left.global_transform,lw);HeroIK.curl(self,"L",lw)
	elif styles.has("R"):
		# One-handed: the free arm hangs at the side (off screen in first person).
		var side_rest=Transform3D(facing_basis()*HeroIK.FRAMES.rest.L,global_position+facing_basis()*Vector3(-.27,.88,-.10)*(HEIGHTS[role]/1.8)*absf(global_basis.get_scale().y))
		HeroIK.solve_arm(self,"L",side_rest,weight,true);HeroIK.curl(self,"L",weight,"rest")
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
# Armour tier (0..2) worn over the outfit; the vest model arrives with the gear pass.
func set_armor(level:int):
	level=clampi(level,0,2)
	if level==armor_level and (level==0 or skeleton.has_node("ChestMount")):return
	armor_level=level
	var mount=skeleton.get_node_or_null("ChestMount")
	if mount:skeleton.remove_child(mount);mount.queue_free()
	if level==0 or meshes().all(func(m):return not m.visible):return
	HeroHitbox.load_volumes()
	for v in HeroHitbox.volumes.get(OUTFITS[role],[]):
		if v.bone=="Chest" and v.type=="ellipsoid":
			mount=BoneAttachment3D.new();mount.name="ChestMount";mount.bone_name="Chest";skeleton.add_child(mount)
			GearModels.vest(mount,level,team,HeroHitbox.v3(v.c),HeroHitbox.v3(v.e))
			break
# Bone-attached node on a hand (melee tools, thrown items).
func hand_attachment(side:String) -> BoneAttachment3D:
	var name="Hand"+side
	var node=skeleton.get_node_or_null(name)
	if node:return node
	var attach=BoneAttachment3D.new();attach.name=name;attach.bone_name="Wrist."+side;skeleton.add_child(attach)
	return attach
# Head position for nameplates/reticles.
func head_position() -> Vector3:return bone_world(bone.Head).origin
