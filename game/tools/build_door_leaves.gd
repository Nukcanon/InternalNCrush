extends SceneTree
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/door_leaves")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/doors_original/manifest.json"))
	for asset in manifest.assets:
		var source=load("res://assets/models/doors_original/"+asset.name+".glb").instantiate()
		MeshFactory.own_recursive(source,source)
		var packed=PackedScene.new();assert(packed.pack(source)==OK)
		assert(ResourceSaver.save(packed,"res://assets/door_leaves/"+asset.name+".scn",ResourceSaver.FLAG_COMPRESS)==OK)
		source.free()
	print("DOOR_LEAVES_BUILT ",manifest.assets.size());quit()
