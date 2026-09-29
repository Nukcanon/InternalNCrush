extends RefCounted
## Measures hero hit volumes from the skinned mesh in its bind pose. Every
## vertex belongs to its dominant bone; each volume is fitted in its bone's
## local bind frame, so at runtime it simply follows that bone's pose.
## Output: res://assets/heroes/hitboxes.json  {outfit: [volume...]}
##  capsule: {bone, zone, type:"capsule", a, b, r}   ellipsoid: {bone, zone, type:"ellipsoid", c, e}
## The head is shared (median of all outfits) so a helmet never makes a role
## easier to headshot.
const GROUPS=[
	["Head","head","ellipsoid",["Head"]],
	["Neck","torso","capsule",["Neck"],"Head"],
	["Chest","torso","ellipsoid",["Chest","Torso","Shoulder.L","Shoulder.R"]],
	["Hips","torso","ellipsoid",["Hips","Abdomen","Body"]],
	["UpperArm.L","arms","capsule",["UpperArm.L"],"LowerArm.L"],["UpperArm.R","arms","capsule",["UpperArm.R"],"LowerArm.R"],
	["LowerArm.L","arms","capsule",["LowerArm.L"],"Wrist.L"],["LowerArm.R","arms","capsule",["LowerArm.R"],"Wrist.R"],
	["Wrist.L","hands","ellipsoid",["Wrist.L"],"",true],["Wrist.R","hands","ellipsoid",["Wrist.R"],"",true],
	["UpperLeg.L","legs","capsule",["UpperLeg.L"],"LowerLeg.L"],["UpperLeg.R","legs","capsule",["UpperLeg.R"],"LowerLeg.R"],
	["LowerLeg.L","legs","capsule",["LowerLeg.L"],"Foot.L"],["LowerLeg.R","legs","capsule",["LowerLeg.R"],"Foot.R"],
	["Foot.L","feet","ellipsoid",["Foot.L"]],["Foot.R","feet","ellipsoid",["Foot.R"]]]
static func percentile(values:Array,q:float) -> float:
	if values.is_empty():return 0.
	values.sort();return values[clampi(int(q*(values.size()-1)),0,values.size()-1)]
static func measure(skel:Skeleton3D) -> Array:
	# Bind (T-pose) transforms of every bone, skeleton space.
	var bind={}
	var skin:Skin
	for body in skel.get_children():
		if body is MeshInstance3D and body.skin:skin=body.skin;break
	for b in range(skin.get_bind_count()):
		var name=skin.get_bind_name(b) if skin.get_bind_name(b)!="" else skel.get_bone_name(skin.get_bind_bone(b))
		bind[name]=skin.get_bind_pose(b).affine_inverse()
	# Skeleton-space bind vertices grouped by dominant bone name.
	var points={}
	for body in skel.get_children():
		if not body is MeshInstance3D or body.skin==null or body.name=="FPArms":continue
		var mesh:Mesh=body.mesh;var body_skin:Skin=body.skin
		for s in range(mesh.get_surface_count()):
			var arrays=mesh.surface_get_arrays(s)
			var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
			if bones==null or bones.is_empty():continue
			var per=bones.size()/verts.size()
			for i in range(verts.size()):
				var best=0;var best_w=-1.
				for k in range(per):
					if weights[i*per+k]>best_w:best_w=weights[i*per+k];best=bones[i*per+k]
				var bone_name=body_skin.get_bind_name(best) if body_skin.get_bind_name(best)!="" else skel.get_bone_name(body_skin.get_bind_bone(best))
				if bone_name.begins_with("Index") or bone_name.begins_with("Middle") or bone_name.begins_with("Ring") or bone_name.begins_with("Pinky") or bone_name.begins_with("Thumb"):
					bone_name="Wrist."+bone_name.get_slice(".",1)
				if not points.has(bone_name):points[bone_name]=PackedVector3Array()
				points[bone_name].append(body.transform*verts[i])
	var out=[]
	for g in GROUPS:
		var frame:Transform3D=bind[g[0]]
		var local=[]
		for source in g[3]:
			for p in points.get(source,PackedVector3Array()):local.append(frame.affine_inverse()*p)
		if local.size()<8:continue
		if g[2]=="ellipsoid":
			var xs=[];var ys=[];var zs=[]
			for p in local:xs.append(p.x);ys.append(p.y);zs.append(p.z)
			var lo=Vector3(percentile(xs,.03),percentile(ys,.03),percentile(zs,.03));var hi=Vector3(percentile(xs,.97),percentile(ys,.97),percentile(zs,.97))
			var shrink=1. if g.size()>5 else .92
			out.append({"bone":g[0],"zone":g[1],"type":"ellipsoid","c":vec((lo+hi)*.5),"e":vec((hi-lo)*.5*shrink)})
		else:
			var tip:Vector3=frame.affine_inverse()*bind[g[4]].origin
			var axis=tip.normalized();var length=tip.length()
			var radial=[];var along=[]
			for p in local:
				var t=clampf(p.dot(axis),0.,length);along.append(p.dot(axis));radial.append((p-axis*t).length())
			var r=percentile(radial,.70)*.9
			out.append({"bone":g[0],"zone":g[1],"type":"capsule","a":vec(axis*maxf(0.,percentile(along,.02))),"b":vec(axis*minf(length,percentile(along,.98))),"r":r})
	var thigh=out.filter(func(v):return v.bone=="UpperLeg.L")
	if not thigh.is_empty():out.append(groin(bind,float(thigh[0].r)))
	return out
# Groin/pelvis floor: crotch vertices belong to the thigh bones, so neither the
# hip ellipsoid nor the thigh capsules close the gap between the hip joints.
# Hit rays through the lower pelvis must not pass between the legs.
static func groin(bind:Dictionary,thigh_radius:float) -> Dictionary:
	var frame:Transform3D=bind["Hips"]
	var l=frame.affine_inverse()*bind["UpperLeg.L"].origin;var r=frame.affine_inverse()*bind["UpperLeg.R"].origin
	var mid=(l+r)*.5
	return {"bone":"Hips","zone":"torso","type":"ellipsoid","part":"groin","c":vec(mid+Vector3(0,-.05,0)),"e":vec(Vector3((l-r).length()*.5+thigh_radius*.7,.12,thigh_radius*1.1))}
static func vec(v:Vector3) -> Array:return [snappedf(v.x,.0001),snappedf(v.y,.0001),snappedf(v.z,.0001)]
static func save_all(all:Dictionary):
	# Shared head: component-wise median of every outfit's head ellipsoid.
	var cs=[[],[],[]];var es=[[],[],[]]
	for outfit in all:
		for v in all[outfit]:
			if v.zone=="head":
				for k in range(3):cs[k].append(v.c[k]);es[k].append(v.e[k])
	var c=[];var e=[]
	for k in range(3):c.append(percentile(cs[k],.5));e.append(percentile(es[k],.5))
	for outfit in all:
		for v in all[outfit]:
			if v.zone=="head":v.c=c;v.e=e
	var f=FileAccess.open("res://assets/heroes/hitboxes.json",FileAccess.WRITE);f.store_string(JSON.stringify(all,"",false));f.close()
	print("hitboxes: shared head c=",c," e=",e)
