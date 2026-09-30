extends SceneTree
## Debug: bone heights and torso weights of each hero body (fitted armour).
func _initialize():call_deferred("run")
func run():
	for role in range(6):
		var h=HeroCharacter.new();root.add_child(h);h.build(role,0,false)
		var body:MeshInstance3D
		for m in h.meshes():
			if str(m.name).ends_with("_Body"):body=m
		var skin=body.skin;var names={};var at={}
		for i in range(skin.get_bind_count()):
			var n=skin.get_bind_name(i)
			if n=="":n=h.skeleton.get_bone_name(skin.get_bind_bone(i))
			names[i]=n;at[n]=skin.get_bind_pose(i).affine_inverse().origin
		print("ROLE ",role," body=",body.name," xf=",body.transform," sk=",h.skeleton.transform," model=",h.model.scale)
		for n in ["Root","Body","Hips","Abdomen","Torso","Chest","Neck","Head","Shoulder.L","UpperArm.L"]:print("  ",n," ",at.get(n,"-"))
		var hist={}
		for s in range(body.mesh.get_surface_count()):
			var arr=body.mesh.surface_get_arrays(s);var v=arr[Mesh.ARRAY_VERTEX];var b=arr[Mesh.ARRAY_BONES];var w=arr[Mesh.ARRAY_WEIGHTS]
			var per=b.size()/v.size()
			for i in range(v.size()):
				var best="";var bw=0.
				for k in range(per):
					if w[i*per+k]>bw:bw=w[i*per+k];best=names.get(int(b[i*per+k]),"?")
				var band=snappedf(v[i].y,.1)
				var key=str(band)+" "+best
				hist[key]=hist.get(key,0)+1
		var keys=hist.keys();keys.sort()
		print("  ",keys.map(func(k):return k+"="+str(hist[k])))
		h.free()
	quit()
