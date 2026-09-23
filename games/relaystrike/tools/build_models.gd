extends SceneTree
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();DirAccess.make_dir_recursive_absolute("res://assets/models")
	var art_source="--with-art-source" in OS.get_cmdline_user_args()
	var manifest={"license":"Original Internal N Crush assets; see LICENSE.txt","operators":[],"weapons":[],"animations":["idle","walk","run","crouch","crouch_walk","jump","fall","fire","reload","hit","land","death","fall_back","fall_front","fall_left","fall_right","fall_fold"]}
	for role in range(6):
		for team in range(2):
			var node=CharacterVisual.make_rig(role,team);root.add_child(node);MeshFactory.own_recursive(node,node)
			var scene=PackedScene.new();scene.pack(node);var path="res://assets/models/operator_%d_%d.scn"%[role,team];ResourceSaver.save(scene,path)
			if art_source:
				var document=GLTFDocument.new();var state=GLTFState.new();document.append_from_scene(node,state);document.write_to_filesystem(state,"res://assets/models/operator_%d_%d.glb"%[role,team])
			manifest.operators.append({"role":Rules.CLASSES[role],"name":CharacterVisual.ROLE_NAMES[role],"team":team,"scene":path});node.queue_free();await process_frame
	for id in Catalog.weapons:
		var visual=WeaponVisual.new();root.add_child(visual);visual.build(Catalog.get_weapon(id),false);visual.name="Working_"+id
		var model=Node3D.new();model.name=Catalog.get_weapon(id).name;root.add_child(model)
		for child in visual.get_children():visual.remove_child(child);model.add_child(child)
		MeshFactory.own_recursive(model,model);var packed=PackedScene.new();packed.pack(model);ResourceSaver.save(packed,"res://assets/models/weapon_"+id+".scn")
		if art_source:
			var document=GLTFDocument.new();var state=GLTFState.new();document.append_from_scene(model,state);document.write_to_filesystem(state,"res://assets/models/weapon_"+id+".glb")
		manifest.weapons.append({"id":id,"name":model.name});model.queue_free();visual.queue_free();await process_frame
	var file=FileAccess.open("res://assets/models/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("MODELS_BUILT operators=12 weapons=27 clips=17_per_operator");quit()
