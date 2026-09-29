class_name HeroSkin
extends RefCounted
## Continuous skinned heroes converted from Quaternius Ultimate Modular
## Men/Women (CC0) by tools/convert_modular_heroes.py. The mesh is skinned to
## the 15-joint operator rig, so procedural clips, IK, weapon sockets, hit
## volumes and ragdolls keep one skeleton. Joint offsets and hit profile come
## from the same conversion so the visible body and hit volumes agree.
const OUTFITS=["men_swat","women_soldier","men_spacesuit","men_worker","men_adventurer","women_scifi"]
const PATHS=["Hips","Hips/Chest","Hips/Chest/Head","Hips/Chest/LeftArm","Hips/Chest/LeftArm/Elbow","Hips/Chest/LeftArm/Elbow/Hand","Hips/Chest/RightArm","Hips/Chest/RightArm/Elbow","Hips/Chest/RightArm/Elbow/Hand","Hips/LeftLeg","Hips/LeftLeg/Knee","Hips/LeftLeg/Knee/Foot","Hips/RightLeg","Hips/RightLeg/Knee","Hips/RightLeg/Knee/Foot"]
# Source material slots repainted per team (main / light / deep); others keep
# their authored colours so outfits stay recognisable.
const TEAM_SLOTS={
	"men_swat":{"Swat":"main","Swat_Black":"deep"},
	"women_soldier":{"Swat":"main","Brown":"deep"},
	"men_spacesuit":{"SciFi_Main":"main","SciFi_MainDark":"deep","SciFi_Light_Accent":"light"},
	"men_worker":{"Worker_Vest":"main","Worker_Yellow":"light"},
	"men_adventurer":{"Green":"main","LightGreen":"light"},
	"women_scifi":{"Blue":"main","LightBlue":"light"}}
static var data={}
static var meshes={}
static func outfit(role:int) -> Dictionary:
	var name=OUTFITS[clampi(role,0,OUTFITS.size()-1)]
	if not data.has(name):data[name]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/heroes/"+name+".json"))
	return data[name]
static func v3(a:Array) -> Vector3:return Vector3(a[0],a[1],a[2])
# Same node names and hierarchy as HumanModel.pose_rig, hero proportions.
static func pose_rig(role:int) -> Node3D:
	var o=outfit(role).offsets
	var rig=Node3D.new();rig.scale=Vector3.ONE*HumanModel.HEIGHTS[role]/1.8
	var hips=HumanModel.joint(rig,"Hips",v3(o.Hips));var chest=HumanModel.joint(hips,"Chest",v3(o.Chest))
	HumanModel.joint(chest,"Head",v3(o.Head));HumanModel.joint(chest,"WeaponSocket",Vector3(.07,-.02,-.12))
	for prefix in ["Left","Right"]:
		var arm=HumanModel.joint(chest,prefix+"Arm",v3(o[prefix+"Arm"]))
		var elbow=HumanModel.joint(arm,"Elbow",v3(o[prefix+"Elbow"]));HumanModel.joint(elbow,"Hand",v3(o[prefix+"Hand"]))
		var leg=HumanModel.joint(hips,prefix+"Leg",v3(o[prefix+"Leg"]));var knee=HumanModel.joint(leg,"Knee",v3(o[prefix+"Knee"]));HumanModel.joint(knee,"Foot",v3(o[prefix+"Foot"]))
	rig.set_meta("hero_outfit",OUTFITS[role]);rig.set_meta("hit_profile",outfit(role).profile)
	return rig
static func mesh(role:int,team:int) -> ArrayMesh:
	var key=str([role,team])
	if meshes.has(key):return meshes[key]
	var d=outfit(role);var slots:Array=d.slots;var names:Array=d.materials;var team_slots:Dictionary=TEAM_SLOTS.get(OUTFITS[role],{})
	var colors=[]
	for i in range(names.size()):
		var c=Color(d.palette[i][0],d.palette[i][1],d.palette[i][2]) # linear
		match str(team_slots.get(names[i],"")):
			"main":c=HeroStyle.TEAM_MAIN[team].srgb_to_linear()
			"light":c=HeroStyle.TEAM_LIGHT[team].srgb_to_linear()
			"deep":c=HeroStyle.TEAM_DEEP[team].srgb_to_linear()
		# Source colours are very dark in linear space; lift for cel shading.
		colors.append(c.linear_to_srgb().lightened(.08).srgb_to_linear())
	var count=slots.size()
	var vertices=PackedVector3Array();vertices.resize(count);var normals=PackedVector3Array();normals.resize(count)
	var paint=PackedColorArray();paint.resize(count)
	var raw_v:Array=d.vertices;var raw_n:Array=d.normals
	for i in range(count):
		vertices[i]=Vector3(raw_v[i*3],raw_v[i*3+1],raw_v[i*3+2]);normals[i]=Vector3(raw_n[i*3],raw_n[i*3+1],raw_n[i*3+2]);paint[i]=colors[int(slots[i])]
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=paint
	# glTF front faces are counter-clockwise; Godot's are clockwise.
	var indices=PackedInt32Array(d.indices)
	for t in range(0,indices.size(),3):
		var swap=indices[t+1];indices[t+1]=indices[t+2];indices[t+2]=swap
	arrays[Mesh.ARRAY_BONES]=PackedInt32Array(d.bones);arrays[Mesh.ARRAY_WEIGHTS]=PackedFloat32Array(d.weights);arrays[Mesh.ARRAY_INDEX]=indices
	var out=ArrayMesh.new();out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	meshes[key]=out;return out
# Adds DeformSkeleton + ContinuousBody exactly like OperatorSkin, so existing
# sync, ragdoll and replay code keep working.
static func install(rig:Node3D,role:int,team:int,outlined:bool=false) -> Skeleton3D:
	var skeleton=Skeleton3D.new();skeleton.name="DeformSkeleton";rig.add_child(skeleton)
	var rest=[]
	for i in range(PATHS.size()):skeleton.add_bone(PATHS[i].replace("/","_"));rig.get_node(PATHS[i]).set_meta("deform_bone",i)
	for i in range(PATHS.size()):
		var node:Node3D=rig.get_node(PATHS[i]);var parent=int(node.get_parent().get_meta("deform_bone",-1))
		if parent>=0:skeleton.set_bone_parent(i,parent)
		skeleton.set_bone_rest(i,node.transform);rest.append(OperatorSkin._relative(node,rig))
	var skin=Skin.new()
	for i in range(PATHS.size()):skin.add_bind(i,rest[i].affine_inverse())
	var body=MeshInstance3D.new();body.name="ContinuousBody";body.mesh=HeroStyle.with_smooth_normals(mesh(role,team)) if outlined else mesh(role,team)
	body.skin=skin;rig.add_child(body);body.skeleton=body.get_path_to(skeleton)
	body.material_override=HeroStyle.toon_material(outlined);body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	OperatorSkin.sync(rig,skeleton)
	return skeleton
