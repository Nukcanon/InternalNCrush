extends RefCounted
class_name AuthoredHuman
# CC0 anatomical mesh data, retargeted offline. See assets/human/source/LICENSE.md.
static var data={}
static var meshes={}
static func source(which:int) -> Dictionary:
	var gender="female" if which in HumanModel.FEMALE_ROLES else "male"
	if not data.has(gender):data[gender]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/human/"+gender+".json"))
	return data[gender]
static func eyes(which:int) -> Array:
	return source(which).eyes
static func install(root:Node3D,which:int,team:int,skin:Color,shirt:Color,trousers:Color):
	_remove_base(root,[skin,shirt,trousers])
	var key=str(which)+"_"+str(team)
	if not meshes.has(key):
		var info=source(which);var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
		var palette=[skin,shirt,trousers,Color("353b37"),Color("343832")]
		for face_id in range(info.faces.size()):
			var face=info.faces[face_id]
			for corner in range(3):
				var index=face[corner]
				var p=info.vertices[index];var kind=int(info.kinds[index]);var color:Color=palette[kind];var q=info.face_coordinates[index]
				var surface_kind=0 if kind==0 else 2 if kind in [3,4] else 1
				# Muted lip/ear coloration is part of the surface, never floating spheres.
				if kind==0 and p[1]>1.48:
					var lip=exp(-pow(float(q[0])/.025,4)-pow((float(q[1])+.050)/.011,4))*smoothstep(.065,.10,-float(q[2]))
					color=color.lerp(Color("946b60") if which not in [2,4] else Color("68483f"),lip*.53)
					var cheek=exp(-pow((absf(q[0])-.045)/.035,2)-pow((q[1]+.008)/.03,2))*smoothstep(.04,.08,-q[2])
					color=color.lerp(color*Color(1.,.94,.91),cheek*.28)
					var hairline=.091 if q[2]<-.040 else .050 if absf(q[0])>.055 else .004
					if q[1]>hairline:
						var hair_color=[Color("463931"),Color("352f2d"),Color("302927"),Color("655346"),Color("55514b"),Color("583f31")][which]
						color=color.lerp(hair_color,smoothstep(hairline,hairline+.008,q[1]))
						if q[1]>hairline+.008:surface_kind=3
				var bones=PackedInt32Array([0,0,0,0]);var weights=PackedFloat32Array([0,0,0,0]);var count=0
				for w in info.weights[index]:bones[count]=int(w[0]);weights[count]=float(w[1]);count+=1
				var uv=info.face_uvs[face_id][corner]
				st.set_uv(Vector2(uv[0],uv[1]))
				st.set_bones(bones);st.set_weights(weights);st.set_color(color.srgb_to_linear());st.set_uv2(Vector2(.67 if surface_kind==0 else .9,float(surface_kind)+.01))
				var neck_adjust=0.
				st.add_vertex(Vector3(p[0],p[1]-.94-neck_adjust,p[2]))
		st.generate_normals();st.index();meshes[key]=st.commit()
	var mesh=MeshInstance3D.new();mesh.name="SculptedShirt";mesh.mesh=meshes[key];mesh.material_override=SurfaceFinish.human_material(which);mesh.set_meta("authored_anatomy",true);root.get_node("Hips").add_child(mesh)
static func _remove_base(node:Node3D,colors:Array):
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D and child.material_override.albedo_color in colors:
			node.remove_child(child);child.free()
		elif child is Node3D:_remove_base(child,colors)
