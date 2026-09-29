extends SceneTree
# Hand mesh geometry in bone space (bind pose): for vertices mostly weighted to
# the right wrist and each finger bone, the extent along the bone (+Y) and the
# distance off the bone axis on the palm (-Z) / back (+Z) / sides (X).
# Used to size the procedural grips (palm skin offset, finger thickness, tips).
func _initialize():call_deferred("run")
func run():
	for role in [0,1,2,3,4,5]:
		var hero=HeroCharacter.new();root.add_child(hero);hero.build(role,0,false)
		var sk=hero.skeleton
		print("== role ",role," skeleton global scale ",sk.global_transform.basis.get_scale()," model scale ",hero.model.scale)
		var stats={}
		for mesh in hero.meshes():
			if mesh.skin==null or not mesh.visible:continue
			var skin:Skin=mesh.skin
			var bind_bone={}
			for i in range(skin.get_bind_count()):
				var b=skin.get_bind_bone(i) if skin.get_bind_name(i)=="" else sk.find_bone(skin.get_bind_name(i))
				bind_bone[i]=[b,skin.get_bind_pose(i)]
			for s in range(mesh.mesh.get_surface_count()):
				var arrays=mesh.mesh.surface_get_arrays(s)
				var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
				if bones==null or bones.size()==0:continue
				var per=bones.size()/v.size()
				for i in range(v.size()):
					var best=-1;var bw=0.
					for k in range(per):
						if weights[i*per+k]>bw:bw=weights[i*per+k];best=int(bones[i*per+k])
					if best<0 or not bind_bone.has(best):continue
					var bone_index=int(bind_bone[best][0]);var name=sk.get_bone_name(bone_index)
					if not name.ends_with(".R"):continue
					if not (name.begins_with("Wrist") or name.begins_with("Index") or name.begins_with("Middle") or name.begins_with("Ring") or name.begins_with("Pinky") or name.begins_with("Thumb") or name.begins_with("LowerArm")):continue
					var p:Vector3=bind_bone[best][1]*v[i]
					if not stats.has(name):stats[name]=[99.,-99.,99.,-99.,99.,-99.,0]
					var st=stats[name]
					st[0]=minf(st[0],p.x);st[1]=maxf(st[1],p.x);st[2]=minf(st[2],p.y);st[3]=maxf(st[3],p.y);st[4]=minf(st[4],p.z);st[5]=maxf(st[5],p.z);st[6]+=1
		var names=stats.keys();names.sort()
		for n in names:
			var st=stats[n]
			print("  %-11s x %.4f..%.4f  y %.4f..%.4f  z %.4f..%.4f  n=%d"%[n,st[0],st[1],st[2],st[3],st[4],st[5],st[6]])
		hero.queue_free()
		if role>0:continue
	print("HAND_MESH_OK");quit()
