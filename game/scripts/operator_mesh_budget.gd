class_name OperatorMeshBudget
extends RefCounted
## Offline/baked Web anatomy: keep the real silhouette, reduce triangles and
## discard unused vertices. Bone weights and authored face UVs are preserved.
static func web_mesh(source:ArrayMesh) -> ArrayMesh:
	var arrays=source.surface_get_arrays(0);var material=source.surface_get_material(0)
	var protected=PackedInt32Array();var body=PackedInt32Array();var original=arrays[Mesh.ARRAY_INDEX]
	for i in range(0,original.size(),3):
		var tri=original.slice(i,i+3)
		if maxf(arrays[Mesh.ARRAY_VERTEX][tri[0]].y,maxf(arrays[Mesh.ARRAY_VERTEX][tri[1]].y,arrays[Mesh.ARRAY_VERTEX][tri[2]].y))>=1.49:protected.append_array(tri)
		else:body.append_array(tri)
	arrays[Mesh.ARRAY_INDEX]=body
	var importer=ImporterMesh.new();importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},material);importer.generate_lods(60.,60.,[])
	var chosen=arrays[Mesh.ARRAY_INDEX]
	for i in range(importer.get_surface_lod_count(0)):
		var candidate=importer.get_surface_lod_indices(0,i)
		if candidate.size()<=9000 and (chosen.size()>9000 or candidate.size()>chosen.size()):chosen=candidate
	chosen.append_array(protected);arrays[Mesh.ARRAY_INDEX]=chosen
	var reduced=ArrayMesh.new();reduced.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var compact=SurfaceTool.new();compact.create_from(reduced,0);compact.deindex();compact.index();compact.set_material(material)
	return compact.commit()
