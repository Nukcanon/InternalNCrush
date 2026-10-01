extends SceneTree
# 1.4.5: girth profile of the first-person arm mesh along the right arm
# (shoulder -> elbow -> wrist), source outfit mesh vs the built FP mesh, in
# first-person metres. Shows pinches / steps at the elbow. Args: roles.
func _initialize():call_deferred("run")
func profile(mesh:Mesh,skin:Skin,sk:Skeleton3D,unit:float) -> Array:
	var pts={};var names={}
	for bind in range(skin.get_bind_count()):
		var name=skin.get_bind_name(bind)
		if name=="":name=sk.get_bone_name(skin.get_bind_bone(bind))
		pts[name]=skin.get_bind_pose(bind).affine_inverse().origin;names[bind]=name
	var a:Vector3=pts["UpperArm.R"];var b:Vector3=pts["LowerArm.R"];var c:Vector3=pts["Wrist.R"]
	var la=a.distance_to(b);var lb=b.distance_to(c);var total=la+lb
	var bins=[];for i in range(24):bins.append([0.,0])
	for s in range(mesh.get_surface_count()):
		var arr=mesh.surface_get_arrays(s);var verts:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
		var bones=arr[Mesh.ARRAY_BONES];var weights=arr[Mesh.ARRAY_WEIGHTS]
		if bones==null:continue
		var per=bones.size()/maxi(1,verts.size())
		for i in range(verts.size()):
			# only arm-bone vertices of the right arm
			var w=0.
			for k in range(per):
				if str(names.get(bones[i*per+k],"")) in ["UpperArm.R","LowerArm.R"]:w+=weights[i*per+k]
			if w<.5:continue
			var v=verts[i];var t1=clampf((v-a).dot(b-a)/(la*la),0.,1.);var t2=clampf((v-b).dot(c-b)/(lb*lb),0.,1.)
			var p1=a+(b-a)*t1;var p2=b+(c-b)*t2
			var d1=v.distance_to(p1);var d2=v.distance_to(p2)
			var along=t1*la if d1<d2 else la+t2*lb
			var r=minf(d1,d2)
			var bi=clampi(int(along/total*24.),0,23);bins[bi][0]+=r;bins[bi][1]+=1
	var out=[]
	for x in bins:out.append(x[0]/x[1]*unit if x[1]>0 else -1.)
	return [out,la/total]
func run():
	var roles=OS.get_cmdline_user_args()
	if roles.is_empty():roles=["0","1","2","3","4","5"]
	for rs in roles:
		var role=int(rs)
		for team in [0]:
			var h=HeroCharacter.new();root.add_child(h);h.build(role,team,false)
			var body:MeshInstance3D
			for m in h.meshes():
				if str(m.name).ends_with("_Body") and m.skin:body=m;break
			h.first_person_only()
			var arms:MeshInstance3D=h.skeleton.get_node("FPArms")
			var unit=absf((h.model.transform*h.skeleton.transform).basis.get_scale().y)*HeroCharacter.FP_BODY_SCALE
			var src=profile(body.mesh,body.skin,h.skeleton,unit);var fp=profile(arms.mesh,body.skin,h.skeleton,unit)
			var line="ARM role %d %s elbow at %.0f%%\n  src:"%[role,str(body.name),src[1]*100.]
			for x in src[0]:line+=" %4.3f"%x
			line+="\n  fp: "
			for x in fp[0]:line+=" %4.3f"%x
			print(line)
			h.queue_free()
	quit()
