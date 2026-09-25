extends SceneTree
# Keep the authored near-view shape on Web. Lower-detail meshes are attached as
# distance LODs, never substituted permanently for the base mesh.
func _initialize():call_deferred("run")
func prepare_meshes(node:Node,add_lods:bool) -> int:
	var indices=0
	for visual in node.find_children("*","MeshInstance3D",true,false):
		if not visual.mesh is ArrayMesh:continue
		var importer=ImporterMesh.new()
		for surface_index in range(visual.mesh.get_surface_count()):
			var arrays=visual.mesh.surface_get_arrays(surface_index)
			if arrays[Mesh.ARRAY_INDEX]==null or arrays[Mesh.ARRAY_INDEX].is_empty():
				var surface=SurfaceTool.new();surface.create_from(visual.mesh,surface_index);surface.index()
				arrays=surface.commit().surface_get_arrays(0)
			indices+=arrays[Mesh.ARRAY_INDEX].size()
			if add_lods:importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},visual.mesh.surface_get_material(surface_index))
		if add_lods:
			importer.generate_lods(60.,60.,[]);visual.mesh=importer.get_mesh()
	WebMaterials.apply(node)
	return indices
func save_scene(node:Node,path:String) -> bool:
	MeshFactory.own_recursive(node,node);var packed=PackedScene.new()
	return packed.pack(node)==OK and ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS)==OK
func run():
	var operator_indices=0;var weapon_indices=0;var map_indices=0
	for role in range(6):
		for team in range(2):
			var path="res://assets/models/operator_%d_%d.scn"%[role,team]
			var node=load(path).instantiate();root.add_child(node)
			# Original comic geometry already has native distance LODs and skinning.
			operator_indices+=prepare_meshes(node,false)
			if not save_scene(node,path):quit(1);return
			node.free();await process_frame
	Catalog.load_all()
	for id in Catalog.weapons:
		var path="res://assets/models/weapon_"+id+".scn"
		var node=load(path).instantiate();root.add_child(node)
		weapon_indices+=prepare_meshes(node,true)
		if not save_scene(node,path):quit(1);return
		node.free();await process_frame
	for index in range(Rules.MAPS.size()):
		var path="res://assets/arenas/complete/map_%02d.scn"%index
		var node=load(path).instantiate();root.add_child(node)
		map_indices+=prepare_meshes(node,true)
		# Collision, navigation, cover and base visual surfaces remain unchanged.
		if not save_scene(node,path):quit(1);return
		node.free();await process_frame
	print("WEB_BASE_INDICES_PRESERVED operators=",operator_indices," weapons=",weapon_indices," arenas=",map_indices)
	quit()
