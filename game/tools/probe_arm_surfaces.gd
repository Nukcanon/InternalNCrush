extends SceneTree
# 1.4.5: which body-mesh surfaces (materials) carry the right arm's vertices,
# and over which part of the arm (fraction along shoulder -> wrist).
func _initialize():call_deferred("run")
func run():
	for role in range(6):
		var h=HeroCharacter.new();root.add_child(h);h.build(role,0,false)
		var body:MeshInstance3D
		for m in h.meshes():
			if str(m.name).ends_with("_Body") and m.skin:body=m;break
		var skin=body.skin;var pts={};var names={}
		for bind in range(skin.get_bind_count()):
			var nm=skin.get_bind_name(bind)
			if nm=="":nm=h.skeleton.get_bone_name(skin.get_bind_bone(bind))
			pts[nm]=skin.get_bind_pose(bind).affine_inverse().origin;names[bind]=nm
		var a:Vector3=pts["UpperArm.R"];var c:Vector3=pts["Wrist.R"];var total=a.distance_to(c)
		var line="SURF role %d %s:"%[role,body.name]
		for s in range(body.mesh.get_surface_count()):
			var arr=body.mesh.surface_get_arrays(s);var verts:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var bones=arr[Mesh.ARRAY_BONES];var weights=arr[Mesh.ARRAY_WEIGHTS]
			var per=bones.size()/maxi(1,verts.size());var lo=9.;var hi=-9.;var n=0
			for i in range(verts.size()):
				var w=0.
				for k in range(per):
					if str(names.get(bones[i*per+k],"")) in ["UpperArm.R","LowerArm.R"]:w+=weights[i*per+k]
				if w<.5:continue
				var u=(verts[i]-a).dot((c-a).normalized())/total;lo=minf(lo,u);hi=maxf(hi,u);n+=1
			var mat=body.mesh.surface_get_material(s)
			if n>0:line+="  [%d %s n=%d %.2f..%.2f]"%[s,str(mat.resource_name if mat else "-"),n,lo,hi]
		print(line);h.queue_free()
	quit()
