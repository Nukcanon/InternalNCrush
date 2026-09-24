extends SceneTree
func _initialize():call_deferred("run")
func run():
	var before=0;var after=0
	for role in range(6):
		for team in range(2):
			var path="res://assets/models/operator_%d_%d.scn"%[role,team]
			var node=load(path).instantiate();root.add_child(node)
			var body=node.get_node("ContinuousBody");var old=body.mesh
			var arrays=old.surface_get_arrays(0);var original=arrays[Mesh.ARRAY_INDEX].size();before+=original
			var importer=ImporterMesh.new();importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays)
			importer.generate_lods(60.,60.,[])
			var selected=arrays[Mesh.ARRAY_INDEX]
			for lod in range(importer.get_surface_lod_count(0)):
				var indices=importer.get_surface_lod_indices(0,lod)
				if indices.size()>=6000 and indices.size()<selected.size():selected=indices
			arrays[Mesh.ARRAY_INDEX]=selected
			var intermediate=ArrayMesh.new();intermediate.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var surface=SurfaceTool.new();surface.create_from(intermediate,0);surface.deindex();surface.index()
			surface.set_material(old.surface_get_material(0));body.mesh=surface.commit();after+=selected.size()
			WebMaterials.apply(node);MeshFactory.own_recursive(node,node);var packed=PackedScene.new();packed.pack(node)
			if ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS)!=OK:quit(1);return
			node.free();await process_frame
	print("WEB_MODEL_INDICES ",before," -> ",after)
	var map_before=0;var map_after=0
	for index in range(Rules.MAPS.size()):
		var path="res://assets/arenas/complete/map_%02d.scn"%index
		var node=load(path).instantiate()
		for visual in node.find_children("*","MeshInstance3D",true,false):
			if not visual.mesh is ArrayMesh:continue
			var mesh=ArrayMesh.new()
			for surface_index in range(visual.mesh.get_surface_count()):
				var arrays=visual.mesh.surface_get_arrays(surface_index)
				if arrays[Mesh.ARRAY_INDEX]==null or arrays[Mesh.ARRAY_INDEX].is_empty():
					var indexed=SurfaceTool.new();indexed.create_from(visual.mesh,surface_index);indexed.index()
					arrays=indexed.commit().surface_get_arrays(0)
				var original=arrays[Mesh.ARRAY_INDEX].size()
				var importer=ImporterMesh.new();importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays);importer.generate_lods(60.,60.,[])
				var selected=arrays[Mesh.ARRAY_INDEX]
				for lod in range(importer.get_surface_lod_count(0)):
					var indices=importer.get_surface_lod_indices(0,lod)
					if indices.size()>=maxi(120,int(original*.25)) and indices.size()<selected.size():selected=indices
				arrays[Mesh.ARRAY_INDEX]=selected
				var intermediate=ArrayMesh.new();intermediate.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var surface=SurfaceTool.new();surface.create_from(intermediate,0);surface.deindex();surface.index();surface.set_material(visual.mesh.surface_get_material(surface_index));surface.commit(mesh)
				map_before+=original;map_after+=selected.size()
			if mesh.get_surface_count()>0:visual.mesh=mesh
		# Only visual meshes change: collision, navigation and gameplay cover remain intact.
		WebMaterials.apply(node);MeshFactory.own_recursive(node,node);var packed=PackedScene.new();packed.pack(node)
		if ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS)!=OK:quit(1);return
		node.free();await process_frame
	print("WEB_ARENA_INDICES ",map_before," -> ",map_after);quit()
