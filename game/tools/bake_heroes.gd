extends SceneTree
## Bakes Quaternius Ultimate Modular Men/Women (CC0) characters with their native
## skeleton and proportions. Each outfit becomes a small binary scene (skeleton +
## skinned meshes) plus one clip library: the outfit's own 24 CC0 clips and clips
## retargeted from Universal Animation Library 1/2 (CC0, tools/clip_retarget.gd).
## Source files stay outside the project (.tools/).
const Retarget=preload("res://tools/clip_retarget.gd")
const HitboxBake=preload("res://tools/hitbox_bake.gd")
var hitboxes={}
const SOURCE="res://../../.tools/quaternius-modular/"
const UAL1="res://../../.tools/quaternius-ual/ual1/Animation Library[Standard]/Godot/AnimationLibrary_Godot_Standard.glb"
const UAL2="res://../../.tools/quaternius-ual/ual2/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb"
const OUTFITS={"men_swat":"men/Swat","women_soldier":"women/Soldier","men_spacesuit":"men/Spacesuit","men_worker":"men/Worker","men_adventurer":"men/Adventurer","women_scifi":"women/SciFi"}
# 1.4 heroes are our own mixes of the modular parts (same 62-bone rig): faces
# stay visible (no full helmets, no heavy beard) and every hero has its own
# skin, hair and cloth palette baked into its materials.
const PARTS={"men_swat":{"Head":"men/Suit"},"women_soldier":{"Head":"women/Casual"},"men_spacesuit":{"Head":"men/Beach","Body":"men/Casual_Hoodie","Legs":"men/Adventurer","Feet":"men/Worker"},
	"men_worker":{"Legs":"men/Casual_2"},"men_adventurer":{"Head":"men/Casual_2"},"women_scifi":{}}
const PALETTES={
	"men_swat":{"Skin":"d9a57a","Hair":"1f1a17","Eyebrows":"1f1a17","Swat_Black":"2b2a33"},
	"women_soldier":{"Skin":"f0c4a0","Hair_Brown":"8a3b22","Hair_Blond":"a8532e","Brown":"4a2a1c","Black":"2e2b33"},
	"men_spacesuit":{"Skin":"b9855e","Hair":"2e241c","Eyebrows":"2e241c","Earrings":"2e241c"},
	"men_worker":{"Skin":"c8905f","Moustache":"3a2a1e","Eyebrows":"3a2a1e","LightBlue":"3c4c63","LightBrown":"8f8a7c"},
	"men_adventurer":{"Skin":"8d5a3b","Skin_Darker":"8d5a3b","Hair":"231a15","Eyebrows":"231a15","Brown":"5e4c36"},
	"women_scifi":{"Skin":"e8b996","Hair_Black":"3b2a4a","Metal":"9aa3ad","Black":"2b2a33"}}
static func paint_parts(mesh:Mesh,palette:Dictionary) -> Mesh:
	var copy:Mesh=mesh.duplicate()
	for s in range(copy.get_surface_count()):
		var mat=copy.surface_get_material(s)
		if mat is BaseMaterial3D and palette.has(mat.resource_name):
			var tinted=mat.duplicate();tinted.albedo_color=Color(palette[mat.resource_name]);copy.surface_set_material(s,tinted)
	return copy
func part_meshes(source:String,suffix:String) -> Array:
	var doc=GLTFDocument.new();var state=GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(SOURCE+source+".gltf"),state)!=OK:push_error("load failed "+source);return []
	var scene:Node3D=doc.generate_scene(state);root.add_child(scene)
	var out=[]
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).ends_with("_"+suffix) and mesh.skin!=null:out.append([str(mesh.name),mesh.mesh,mesh.skin,scene.find_children("*","Skeleton3D",true,false)[0].global_transform.affine_inverse()*mesh.global_transform])
	scene.queue_free()
	return out
const UAL1_CLIPS=["Idle_Loop","Walk_Loop","Jog_Fwd_Loop","Sprint_Loop","Crouch_Idle_Loop","Crouch_Fwd_Loop","Jump_Start","Jump_Loop","Jump_Land",
	"Pistol_Idle_Loop","Pistol_Aim_Neutral","Pistol_Aim_Up","Pistol_Aim_Down","Pistol_Shoot","Pistol_Reload","Hit_Chest","Hit_Head","Death01","Fixing_Kneeling","PickUp_Table"]
const UAL2_CLIPS=["Slide_Start","Slide_Loop","Slide_Exit","OverhandThrow","Hit_Knockback"]
func _initialize():call_deferred("run")
func skin_of(skel:Skeleton3D) -> Skin:
	for body in skel.get_children():
		if body is MeshInstance3D and body.skin!=null:return body.skin
	return null
# First person shows only the arms: triangles whose three vertices are all
# driven mainly by arm/hand bones, as an extra hidden mesh "FPArms".
const ARM_BONES=["UpperArm","LowerArm","Wrist","Index","Middle","Ring","Pinky","Thumb"]
func add_first_person_arms(skel:Skeleton3D):
	var out=ArrayMesh.new();var skin:Skin
	for body in skel.get_children():
		if not body is MeshInstance3D or body.skin==null or not str(body.name).ends_with("_Body"):continue
		skin=body.skin
		for s in range(body.mesh.get_surface_count()):
			var arrays=body.mesh.surface_get_arrays(s)
			var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS];var idx:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var count=(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size();var per=bones.size()/count
			var arm=PackedByteArray();arm.resize(count)
			for i in range(count):
				var best=0;var bw=-1.
				for k in range(per):
					if weights[i*per+k]>bw:bw=weights[i*per+k];best=bones[i*per+k]
				var name=skin.get_bind_name(best) if skin.get_bind_name(best)!="" else skel.get_bone_name(skin.get_bind_bone(best))
				arm[i]=1 if ARM_BONES.any(func(b):return name.begins_with(b)) else 0
			var kept=PackedInt32Array()
			for t in range(0,idx.size(),3):
				if arm[idx[t]] and arm[idx[t+1]] and arm[idx[t+2]]:kept.append_array([idx[t],idx[t+1],idx[t+2]])
			if kept.is_empty():continue
			arrays[Mesh.ARRAY_INDEX]=kept
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			out.surface_set_material(out.get_surface_count()-1,body.mesh.surface_get_material(s))
	if out.get_surface_count()==0:return
	var arms=MeshInstance3D.new();arms.name="FPArms";arms.mesh=out;arms.skin=skin;skel.add_child(arms);arms.owner=skel.owner;arms.skeleton=NodePath("..");arms.visible=false
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/heroes")
	var ual1=Retarget.load_pack(ProjectSettings.globalize_path(UAL1),root)
	var ual2=Retarget.load_pack(ProjectSettings.globalize_path(UAL2),root)
	if ual1.is_empty() or ual2.is_empty():push_error("animation packs missing");quit(1);return
	for outfit in OUTFITS:
		var doc=GLTFDocument.new();var state=GLTFState.new()
		var path=ProjectSettings.globalize_path(SOURCE+OUTFITS[outfit]+".gltf")
		if doc.append_from_file(path,state)!=OK:push_error("load failed "+path);quit(1);return
		var scene:Node3D=doc.generate_scene(state);root.add_child(scene)
		var skeleton:Skeleton3D=scene.find_children("*","Skeleton3D",true,false)[0]
		var player:AnimationPlayer=scene.find_children("*","AnimationPlayer",true,false)[0]
		# Output: Hero(Node3D) > Skeleton3D > Body#(MeshInstance3D), glTF +Z forward kept.
		var hero=Node3D.new();hero.name="Hero";root.add_child(hero)
		var skel=Skeleton3D.new();skel.name="Skeleton3D";hero.add_child(skel);skel.owner=hero
		for i in range(skeleton.get_bone_count()):skel.add_bone(skeleton.get_bone_name(i))
		for i in range(skeleton.get_bone_count()):
			skel.set_bone_parent(i,skeleton.get_bone_parent(i));skel.set_bone_rest(i,skeleton.get_bone_rest(i))
			skel.set_bone_pose(i,skeleton.get_bone_rest(i))
		skel.transform=skeleton.global_transform
		var index=0;var swaps:Dictionary=PARTS.get(outfit,{});var palette:Dictionary=PALETTES.get(outfit,{})
		for mesh in scene.find_children("*","MeshInstance3D",true,false):
			# Outfits ship a prop pistol; weapons are separate game models.
			if mesh.name.to_lower().contains("pistol") or mesh.skin==null:continue
			# Swapped parts come from another outfit (added below).
			if swaps.keys().any(func(part):return str(mesh.name).ends_with("_"+part)):continue
			var body=MeshInstance3D.new();body.name=str(mesh.name);index+=1;skel.add_child(body);body.owner=hero
			body.mesh=paint_parts(mesh.mesh,palette);body.skin=mesh.skin;body.transform=skeleton.global_transform.affine_inverse()*mesh.global_transform
			body.skeleton=NodePath("..")
		for part in swaps:
			for entry in part_meshes(swaps[part],part):
				var body=MeshInstance3D.new();body.name=entry[0];index+=1;skel.add_child(body);body.owner=hero
				body.mesh=paint_parts(entry[1],palette);body.skin=entry[2];body.transform=entry[3];body.skeleton=NodePath("..")
		add_first_person_arms(skel)
		# Native clips: tracks target "Skeleton3D:<bone>" relative to the Hero root.
		var library:AnimationLibrary=player.get_animation_library(player.get_animation_library_list()[0]).duplicate(true)
		for clip in library.get_animation_list():
			var anim=library.get_animation(clip)
			for t in range(anim.get_track_count()):anim.track_set_path(t,NodePath(str(anim.track_get_path(t)).replace("CharacterArmature/Skeleton3D","Skeleton3D")))
		var added=0
		for pack in [[ual1,false,UAL1_CLIPS],[ual2,true,UAL2_CLIPS]]:
			var clips=Retarget.retarget(pack[0],pack[1],skel,skin_of(skel),pack[2],"Skeleton3D")
			for clip in clips:library.add_animation(clip,clips[clip]);added+=1
		for name in ["Run","Run_Back","Run_Left","Run_Right","Walk","Idle"]:
			if library.has_animation(name):library.get_animation(name).loop_mode=Animation.LOOP_LINEAR
		ResourceSaver.save(library,"res://assets/heroes/"+outfit+"_clips.res",ResourceSaver.FLAG_COMPRESS)
		hitboxes[outfit]=HitboxBake.measure(skel)
		root.remove_child(hero)
		var packed=PackedScene.new();packed.pack(hero)
		ResourceSaver.save(packed,"res://assets/heroes/"+outfit+".scn",ResourceSaver.FLAG_COMPRESS)
		print(outfit,": bones ",skel.get_bone_count()," meshes ",index," clips ",library.get_animation_list().size()," (retargeted ",added,")")
		hero.free();scene.queue_free();await process_frame
	HitboxBake.save_all(hitboxes)
	print("HERO_BAKE_OK");quit()
