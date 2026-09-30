extends SceneTree
# Radius of the rig's upper arm / forearm / hand about their bone axes (model space, scale 1).
func _initialize():call_deferred("run")
func run():
	for role in range(6):
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,0,false)
		var body:MeshInstance3D
		for m in hero.meshes():
			if str(m.name).ends_with("_Body"):body=m
		var skin=body.skin;var axes={}
		for bind in range(skin.get_bind_count()):
			var name=skin.get_bind_name(bind)
			if name=="":name=hero.skeleton.get_bone_name(skin.get_bind_bone(bind))
			if name in ["UpperArm.R","LowerArm.R","Wrist.R"]:
				var bone:Transform3D=skin.get_bind_pose(bind).affine_inverse()
				axes[bind]=[name,bone.origin,bone.basis.y.normalized()]
		var stats={}
		for s in range(body.mesh.get_surface_count()):
			var arrays=body.mesh.surface_get_arrays(s)
			var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
			var per=bones.size()/maxi(1,verts.size())
			for i in range(verts.size()):
				var best=-1;var bw=-1.
				for k in range(per):
					if weights[i*per+k]>bw:bw=weights[i*per+k];best=bones[i*per+k]
				if not axes.has(best) or bw<.8:continue
				var name=axes[best][0];var rel=verts[i]-axes[best][1];var y:Vector3=axes[best][2]
				var r=(rel-y*rel.dot(y)).length()
				if not stats.has(name):stats[name]={"max":0.,"sum":0.,"n":0}
				stats[name].max=maxf(stats[name].max,r);stats[name].sum+=r;stats[name].n+=1
		var line="GIRTH role %d scale %.3f"%[role,hero.model.scale.y]
		for name in stats:line+=" %s max=%.3f mean=%.3f n=%d"%[name,stats[name].max,stats[name].sum/stats[name].n,stats[name].n]
		print(line)
		hero.queue_free()
	quit()
