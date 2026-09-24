extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();DirAccess.make_dir_recursive_absolute("res://assets/models")
	var art_source="--with-art-source" in OS.get_cmdline_user_args()
	var manifest={"license":"Original equipment + CC0 MakeHuman-derived anatomy; see assets/human/source/LICENSE.md","style":"1.0.4 authored human anatomy, textile/skin materials, GPU skinning and joint physics","operators":[],"weapons":[],"animations":["idle","walk","run","crouch","crouch_walk","jump","fall","fire","reload","hit","land","death","fall_back","fall_front","fall_left","fall_right","fall_fold"]}
	for role in range(6):
		for team in range(2):
			var node=CharacterVisual.make_rig(role,team);root.add_child(node)
			OperatorSkin.install(node,str(role)+"_"+str(team))
			var body=node.get_node("ContinuousBody");var importer=ImporterMesh.new()
			importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,body.mesh.surface_get_arrays(0),[],{},SurfaceFinish.human_material(role))
			importer.generate_lods(60.,60.,[]);body.mesh=importer.get_mesh();body.set_meta("lod_count",importer.get_surface_lod_count(0))
			print("OPERATOR_LOD ",role,"/",team," levels=",importer.get_surface_lod_count(0))
			MeshFactory.own_recursive(node,node)
			var scene=PackedScene.new();scene.pack(node);var path="res://assets/models/operator_%d_%d.scn"%[role,team];ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS)
			if art_source:
				var document=GLTFDocument.new();var state=GLTFState.new();document.append_from_scene(node,state);document.write_to_filesystem(state,"res://assets/models/operator_%d_%d.glb"%[role,team])
			manifest.operators.append({"role":Rules.CLASSES[role],"name":CharacterVisual.ROLE_NAMES[role],"identity":HumanModel.IDENTITIES[role],"gender":"female" if role in HumanModel.FEMALE_ROLES else "male","height_cm":roundi(HumanModel.HEIGHTS[role]*100),"team":team,"scene":path});node.queue_free();await process_frame
	for id in Catalog.weapons:
		var visual=WeaponVisual.new();root.add_child(visual);visual.build(Catalog.get_weapon(id),false);visual.name="Working_"+id
		var model=Node3D.new();model.name=Catalog.get_weapon(id).name;root.add_child(model)
		for child in visual.get_children():visual.remove_child(child);model.add_child(child)
		MeshFactory.own_recursive(model,model);var packed=PackedScene.new();packed.pack(model);ResourceSaver.save(packed,"res://assets/models/weapon_"+id+".scn",ResourceSaver.FLAG_COMPRESS)
		if art_source:
			var document=GLTFDocument.new();var state=GLTFState.new();document.append_from_scene(model,state);document.write_to_filesystem(state,"res://assets/models/weapon_"+id+".glb")
		manifest.weapons.append({"id":id,"name":model.name});model.queue_free();visual.queue_free();await process_frame
	var file=FileAccess.open("res://assets/models/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("MODELS_BUILT operators=12 weapons=27 clips=17_per_operator");quit()
