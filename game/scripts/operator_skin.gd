extends RefCounted
class_name OperatorSkin
# The authoring hierarchy remains the animation/weapon socket rig. GPU skinning
# blends its anatomical joints instead of rotating disconnected rigid pieces.
const PATHS=["Hips","Hips/Chest","Hips/Chest/Head","Hips/Chest/LeftArm","Hips/Chest/LeftArm/Elbow","Hips/Chest/LeftArm/Elbow/Hand","Hips/Chest/RightArm","Hips/Chest/RightArm/Elbow","Hips/Chest/RightArm/Elbow/Hand","Hips/LeftLeg","Hips/LeftLeg/Knee","Hips/LeftLeg/Knee/Foot","Hips/RightLeg","Hips/RightLeg/Knee","Hips/RightLeg/Knee/Foot"]
static var templates={}
static func install(rig:Node3D,key:String) -> Skeleton3D:
	var skeleton=Skeleton3D.new();skeleton.name="DeformSkeleton";rig.add_child(skeleton)
	for i in range(PATHS.size()):skeleton.add_bone(PATHS[i].replace("/","_"));rig.get_node(PATHS[i]).set_meta("deform_bone",i)
	var rest=[]
	for i in range(PATHS.size()):
		var node:Node3D=rig.get_node(PATHS[i]);var parent=int(node.get_parent().get_meta("deform_bone",-1))
		if parent>=0:skeleton.set_bone_parent(i,parent)
		skeleton.set_bone_rest(i,node.transform);rest.append(_relative(node,rig))
	if not templates.has(key):
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(PATHS.size()):_append_geometry(rig.get_node(PATHS[i]),rig,i,rest,st)
		var fabric=SurfaceFinish.human_material()
		st.index();st.set_material(fabric);templates[key]=st.commit()
	for path in PATHS:_hide_geometry(rig.get_node(path))
	var skin=Skin.new()
	for i in range(PATHS.size()):skin.add_bind(i,rest[i].affine_inverse())
	var mesh=MeshInstance3D.new();mesh.name="ContinuousBody";mesh.mesh=templates[key];mesh.skin=skin;rig.add_child(mesh);mesh.skeleton=mesh.get_path_to(skeleton)
	sync(rig,skeleton)
	return skeleton
static func _relative(node:Node3D,root:Node3D) -> Transform3D:
	var transform=node.transform;var parent=node.get_parent()
	while parent!=root:transform=parent.transform*transform;parent=parent.get_parent()
	return transform
static func _hide_geometry(node:Node3D):
	for child in node.get_children():
		if child is MeshInstance3D:child.hide()
		elif child is Node3D and child.name not in ["Chest","Head","LeftArm","RightArm","Elbow","Hand","LeftLeg","RightLeg","Knee","Foot","WeaponSocket"]:_hide_geometry(child)
static func _weights(index:int,point:Vector3) -> Vector4:
	var path=PATHS[index];var other=index;var blend=0.
	if path.ends_with("Elbow") or path.ends_with("Knee"):
		other=index-1
		# 50/50 at the joint, completely attached below the joint.
		blend=clampf((point.y+.09)/.18,0.,.65)
	elif path.ends_with("Hand") or path.ends_with("Foot"):
		other=index-1;blend=clampf((point.y+.035)/.12,0.,.40)
	elif path.ends_with("Arm"):
		if point.y<-.19:other=index+1;blend=clampf((-point.y-.19)/.18,0.,.65)
		else:other=1;blend=clampf((point.y+.085)/.19,0.,.7)
	elif path.ends_with("Leg"):
		if point.y<-.31:other=index+1;blend=clampf((-point.y-.31)/.20,0.,.6)
		else:other=0;blend=clampf((point.y+.06)/.15,0.,.65)
	elif path=="Hips/Chest":
		if point.y<-.08:other=0;blend=clampf((-point.y-.08)/.25,0.,.7)
		elif point.y>.245:other=2;blend=clampf((point.y-.245)/.11,0.,.75)
		elif absf(point.x)>.12 and point.y>.025:other=3 if point.x<0 else 6;blend=smoothstep(.12,.235,absf(point.x))*smoothstep(.025,.13,point.y)*.62
	elif path=="Hips" and point.y<-.04:
		other=9 if point.x<0 else 12;blend=clampf((-point.y-.04)/.17,0.,.6)
	return Vector4(index,other,1.-blend,blend)
static func _append_geometry(node:Node3D,rig:Node3D,index:int,rest:Array,st:SurfaceTool):
	for child in node.get_children():
		if child is MeshInstance3D:
			var transform=_relative(child,rig)
			for surface in range(child.mesh.get_surface_count()):
				var a=child.mesh.surface_get_arrays(surface);var vertices=a[Mesh.ARRAY_VERTEX];var normals=a[Mesh.ARRAY_NORMAL];var indices=a[Mesh.ARRAY_INDEX];var colors=a[Mesh.ARRAY_COLOR];var uv2=a[Mesh.ARRAY_TEX_UV2]
				var material=child.material_override if child.material_override else child.mesh.surface_get_material(surface)
				var count=indices.size() if indices!=null and not indices.is_empty() else vertices.size()
				for j in range(count):
					var k=indices[j] if indices!=null and not indices.is_empty() else j
					var position=transform*vertices[k];var weights=_weights(index,rest[index].affine_inverse()*position)
					if child.has_meta("deform_shell"):
						var owner=1 if int(child.get_meta("deform_shell"))==0 else 0
						if owner==1 and absf(position.x)>.19:owner=3 if position.x<0 else 6
						if int(child.get_meta("deform_shell"))==1 and position.y<.865:owner=(9 if position.x<0 else 12)+(1 if position.y<.5 else 0)
						weights=_weights(owner,rest[owner].affine_inverse()*position)
					if child.has_meta("authored_anatomy"):
						st.set_bones(PackedInt32Array(a[Mesh.ARRAY_BONES].slice(k*4,k*4+4)));st.set_weights(PackedFloat32Array(a[Mesh.ARRAY_WEIGHTS].slice(k*4,k*4+4)))
					else:
						st.set_bones(PackedInt32Array([int(weights.x),int(weights.y),0,0]));st.set_weights(PackedFloat32Array([weights.z,weights.w,0.,0.]))
					st.set_color(colors[k] if colors!=null and not colors.is_empty() else material.albedo_color.srgb_to_linear() if material is StandardMaterial3D else Color.WHITE)
					st.set_uv2(uv2[k] if uv2!=null and not uv2.is_empty() else Vector2(.82,0.))
					st.set_normal((transform.basis.inverse().transposed()*normals[k]).normalized());st.add_vertex(position)
		elif child is Node3D and not child.has_meta("deform_bone") and child.name!="WeaponSocket":_append_geometry(child,rig,index,rest,st)
static func sync(rig:Node3D,skeleton:Skeleton3D):
	for i in range(PATHS.size()):
		var node:Node3D=rig.get_node(PATHS[i]);var pose=node.transform
		skeleton.set_bone_pose_position(i,pose.origin);skeleton.set_bone_pose_rotation(i,pose.basis.orthonormalized().get_rotation_quaternion());skeleton.set_bone_pose_scale(i,pose.basis.get_scale())
