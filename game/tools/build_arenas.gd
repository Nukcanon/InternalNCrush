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
	DirAccess.make_dir_recursive_absolute("res://assets/arenas/complete")
	var indices=range(Rules.MAPS.size())
	var signatures={}
	if FileAccess.file_exists("res://assets/arenas/physics_signatures.json"):
		signatures=JSON.parse_string(FileAccess.get_file_as_string("res://assets/arenas/physics_signatures.json"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			indices=[]
			for entry in arg.trim_prefix("--maps=").split(","):indices.append(int(entry))
	for index in indices:
		var started=Time.get_ticks_msec();var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		MeshFactory.own_recursive(arena.architecture,arena.architecture)
		var packed=PackedScene.new();var result=packed.pack(arena.architecture)
		if result==OK:result=ResourceSaver.save(packed,"res://assets/arenas/geometry/map_%02d.scn"%index,ResourceSaver.FLAG_COMPRESS)
		if result!=OK:printerr("ARENA_BAKE_FAILED ",index," code=",result);quit(1);return
		var restored=load("res://assets/arenas/geometry/map_%02d.scn"%index).instantiate();root.add_child(restored)
		if physics_signature(arena.architecture)!=physics_signature(restored):printerr("ARENA_PHYSICS_MISMATCH ",index);quit(1);return
		signatures[str(index)]=physics_signature(arena.architecture)
		restored.free()
		if ArenaCache.save(arena,"res://assets/arenas/complete/map_%02d.scn"%index)!=OK:quit(2);return
		if index==PracticeLayout.INDEX:
			var preview_path="res://assets/arenas/districts/plan_31.json"
			var preview=JSON.parse_string(FileAccess.get_file_as_string(preview_path));preview.triangles.upper=[]
			for surface in arena.walk_surfaces:
				var r:Rect2=surface.rect
				for p in [r.position,Vector2(r.end.x,r.position.y),r.end,r.position,r.end,Vector2(r.position.x,r.end.y)]:preview.triangles.upper.append([p.x,p.y])
			preview.spawns=[[0,35],[0,-35]];preview.targets=[[-25,0],[25,0],[0,-18]]
			var file=FileAccess.open(preview_path,FileAccess.WRITE);file.store_string(JSON.stringify(preview));file.close()
		print("ARENA_BAKED ",index," ms=",Time.get_ticks_msec()-started)
		arena.free();await process_frame
	FileAccess.open("res://assets/arenas/physics_signatures.json",FileAccess.WRITE).store_string(JSON.stringify(signatures,"  "))
	print("ARENAS_BUILT ",indices.size());quit()
