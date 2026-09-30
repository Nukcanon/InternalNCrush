extends SceneTree
# Hero body meshes per role: names, surfaces (material names), vertex counts,
# skin bind names and the torso bones' weight share (1.4.2 fitted armour).
func _initialize():call_deferred("run")
func run():
	for role in range(6):
		var h=HeroCharacter.new();root.add_child(h);h.build(role,0,false)
		for m in h.meshes():
			var mats=[];var verts=0
			for s in range(m.mesh.get_surface_count()):
				var mat=m.mesh.surface_get_material(s);mats.append(str(mat.resource_name) if mat else "-")
				verts+=m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size()
			print("ROLE ",role," ",HeroCharacter.OUTFITS[role]," mesh=",m.name," verts=",verts," mats=",mats," skin=",m.skin!=null)
		if role==0:
			var names=[];for i in range(h.skeleton.get_bone_count()):names.append(h.skeleton.get_bone_name(i))
			print("BONES ",names)
		h.free()
	quit()
