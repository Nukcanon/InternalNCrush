extends SceneTree
# 1.4.5: what takes the space in a packed arena (assets/arenas/complete)?
# Arg: map index. Prints bytes of mesh arrays by type, collision shapes, and the
# rest, from the instantiated scene.
func _initialize():call_deferred("run")
func run():
	var index=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 1
	var path="res://assets/arenas/complete/map_%02d.scn"%index
	var packed=load(path);var node=packed.instantiate()
	var sizes={"vertex":0,"normal":0,"tangent":0,"color":0,"uv":0,"uv2":0,"index":0,"custom":0,"bones":0,"shape_faces":0,"meshes":0,"surfaces":0,"shapes":0,"nodes":0,"textures":0}
	var seen={}
	var stack=[node]
	while not stack.is_empty():
		var n=stack.pop_back();sizes.nodes+=1
		for c in n.get_children():stack.append(c)
		if n is MeshInstance3D and n.mesh and not seen.has(n.mesh):
			seen[n.mesh]=true;sizes.meshes+=1
			for s in range(n.mesh.get_surface_count()):
				sizes.surfaces+=1
				var a=n.mesh.surface_get_arrays(s)
				if a[Mesh.ARRAY_VERTEX]:sizes.vertex+=a[Mesh.ARRAY_VERTEX].size()*12
				if a[Mesh.ARRAY_NORMAL]:sizes.normal+=a[Mesh.ARRAY_NORMAL].size()*12
				if a[Mesh.ARRAY_TANGENT]:sizes.tangent+=a[Mesh.ARRAY_TANGENT].size()*4
				if a[Mesh.ARRAY_COLOR]:sizes.color+=a[Mesh.ARRAY_COLOR].size()*16
				if a[Mesh.ARRAY_TEX_UV]:sizes.uv+=a[Mesh.ARRAY_TEX_UV].size()*8
				if a[Mesh.ARRAY_TEX_UV2]:sizes.uv2+=a[Mesh.ARRAY_TEX_UV2].size()*8
				if a[Mesh.ARRAY_INDEX]:sizes.index+=a[Mesh.ARRAY_INDEX].size()*4
				if a[Mesh.ARRAY_CUSTOM0]:sizes.custom+=a[Mesh.ARRAY_CUSTOM0].size()*4
				if a[Mesh.ARRAY_BONES]:sizes.bones+=a[Mesh.ARRAY_BONES].size()*4
				var mat=n.mesh.surface_get_material(s)
				if mat is BaseMaterial3D and mat.albedo_texture and not seen.has(mat.albedo_texture):
					seen[mat.albedo_texture]=true;sizes.textures+=1
		if n is CollisionShape3D and n.shape and not seen.has(n.shape):
			seen[n.shape]=true;sizes.shapes+=1
			if n.shape is ConcavePolygonShape3D:sizes.shape_faces+=n.shape.get_faces().size()*12
	var file=FileAccess.open(path,FileAccess.READ)
	print("SCN %s file %.2f MB %s"%[path,file.get_length()/1048576.,str(sizes)])
	for k in ["vertex","normal","tangent","color","uv","uv2","index","custom","bones","shape_faces"]:print("  %-12s %.2f MB"%[k,sizes[k]/1048576.])
	quit()
