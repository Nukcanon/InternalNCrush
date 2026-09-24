extends SceneTree
func _initialize():call_deferred("run")
func physics_signature(node:Node3D) -> String:
	var entries=PackedStringArray()
	for collider in node.find_children("*","CollisionShape3D",true,false):
		if collider.shape==null:continue
		var points=collider.shape.get_debug_mesh().get_aabb()
		var transform:Transform3D=collider.global_transform
		entries.append(str([collider.shape.get_class(),points.position.snapped(Vector3.ONE*.001),points.size.snapped(Vector3.ONE*.001),transform.origin.snapped(Vector3.ONE*.001),transform.basis.x.snapped(Vector3.ONE*.001),transform.basis.y.snapped(Vector3.ONE*.001),transform.basis.z.snapped(Vector3.ONE*.001),collider.get_parent().collision_layer]))
	entries.sort();return "\n".join(entries).sha256_text()
func run():
	DirAccess.make_dir_recursive_absolute("res://assets/arenas/geometry")
	for index in range(Rules.MAPS.size()):
		var started=Time.get_ticks_msec();var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		MeshFactory.own_recursive(arena.architecture,arena.architecture)
		var packed=PackedScene.new();var result=packed.pack(arena.architecture)
		if result==OK:result=ResourceSaver.save(packed,"res://assets/arenas/geometry/map_%02d.scn"%index,ResourceSaver.FLAG_COMPRESS)
		if result!=OK:printerr("ARENA_BAKE_FAILED ",index," code=",result);quit(1);return
		var restored=load("res://assets/arenas/geometry/map_%02d.scn"%index).instantiate();root.add_child(restored)
		if physics_signature(arena.architecture)!=physics_signature(restored):printerr("ARENA_PHYSICS_MISMATCH ",index);quit(1);return
		restored.free()
		print("ARENA_BAKED ",index," ms=",Time.get_ticks_msec()-started)
		arena.free();await process_frame
	print("ARENAS_BUILT ",Rules.MAPS.size());quit()
