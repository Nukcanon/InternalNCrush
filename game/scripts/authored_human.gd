extends RefCounted
class_name AuthoredHuman
# CC0 anatomical mesh data, retargeted offline. See assets/human/source/LICENSE.md.
static var data={}
static var meshes={}
static func surface_point(which:int,info:Dictionary,index:int) -> Vector3:
	var v=info.vertices[index];var p=Vector3(v[0],v[1]-1.6,v[2])
	if which in HumanModel.FEMALE_ROLES and p.y>-.14:
		# Undo the older offline elongated-chin morph before applying identity.
		# The original face coordinates retain the anatomical lip/chin relationship.
		var q=info.face_coordinates[index]
		p=p.lerp(Vector3(q[0],q[1],q[2]),smoothstep(-.14,-.07,p.y))
	return face_point(which,p)
static func source(which:int) -> Dictionary:
	var gender="female" if which in HumanModel.FEMALE_ROLES else "male"
	if not data.has(gender):data[gender]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/human/"+gender+".json"))
	return data[gender]
static func eyes(which:int) -> Array:
	var out=[]
	for eye in source(which).eyes:
		var p=face_point(which,Vector3(eye[0],eye[1],eye[2]))
		out.append([p.x,p.y,p.z])
	return out
# Small anatomical morphs share the original rig and eye sockets.
static func face_point(which:int,p:Vector3) -> Vector3:
	var jaw=smoothstep(.012,-.090,p.y)
	var widths=[1.03,.95,1.12,.98,1.045,.98]
	var jaw_width=[1.05,.90,1.12,.94,.98,.92]
	var strength=smoothstep(-.15,-.085,p.y)
	var shaped=p
	shaped.x*=widths[which]*lerpf(1.,jaw_width[which],jaw)
	shaped.y*= [1.,1.015,.97,1.055,1.035,.97][which]
	shaped.z*= [1.02,.96,1.045,1.01,.95,.98][which]
	var nose=exp(-pow(p.x/.018,2)-pow((p.y+.006)/.028,2))*smoothstep(.04,.075,-p.z)
	shaped.z-=[.004,-.001,.002,.008,.003,-.002][which]*nose
	if which in HumanModel.FEMALE_ROLES:
		shaped.y+=maxf(0.,-p.y)*.05
		shaped.z+=nose*.006
		# Retract the lower facial plane, leaving the throat and eye sockets intact.
		var lower=smoothstep(.005,-.067,p.y)*smoothstep(-.14,-.08,p.y)
		var front=smoothstep(.025,.075,-p.z)
		shaped.z+=lower*front*.006
		shaped.y+=lower*.002
		shaped.x*=1.-lower*.045
		var cheek=exp(-pow((absf(p.x)-.044)/.026,2)-pow((p.y+.005)/.027,2))
		shaped.x+=signf(p.x)*cheek*.003
		var mouth=exp(-pow(p.x/.032,4)-pow((p.y+.027)/.011,4))*smoothstep(.055,.085,-p.z)
		shaped.y+=mouth*pow(clampf(absf(p.x)/.026,0.,1.),2)*.003
		# Open the eyelid aperture without changing eye-socket centers or rig size.
		var eye_y=.028345;var eye_x=.02885
		var eyelid=exp(-pow((absf(p.x)-eye_x)/.018,4)-pow((p.y-eye_y)/.013,4))*smoothstep(.045,.075,-p.z)
		shaped.y+=(p.y-eye_y)*.08*eyelid
		shaped.x+=signf(p.x)*(absf(p.x)-eye_x)*.12*eyelid
	var result=p.lerp(shaped,strength)
	if which in HumanModel.FEMALE_ROLES:
		result.x*=.95/.88;result.y*=(1.72 if which==1 else 1.70)/HumanModel.HEIGHTS[which]
	return result
static func install(root:Node3D,which:int,team:int,skin:Color,shirt:Color,trousers:Color):
	_remove_base(root,[skin,shirt,trousers])
	var key=str(which)+"_"+str(team)
	if not meshes.has(key):
		var info=source(which);var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
		var palette=[skin,shirt,trousers,Color("353b37"),Color("343832")]
		for face_id in range(info.faces.size()):
			var face=info.faces[face_id]
			# Atlas IDs are discrete: interpolating skin (4) into fabric (1)
			# produced random leather/hair triangles along the neck seam.
			var kinds=[int(info.kinds[face[0]]),int(info.kinds[face[1]]),int(info.kinds[face[2]])]
			var face_kind=kinds[0] if kinds[0]==kinds[1] or kinds[0]==kinds[2] else kinds[1]
			var face_height=(float(info.vertices[face[0]][1])+float(info.vertices[face[1]][1])+float(info.vertices[face[2]][1]))/3.
			if face_height>1.405:face_kind=0 if face_height>=float(info.get("neckline_height",1.48)) else 1
			for corner in range(3):
				var index=face[corner]
				var p=info.vertices[index];var kind=face_kind;var color:Color=palette[kind];var q=info.face_coordinates[index]
				var surface_kind=4 if face_kind==0 else 2 if face_kind in [3,4] else 1
				if kind==2 and p[1]>.99:
					color=color.lerp(Color("383d39"),smoothstep(.99,1.,p[1]));surface_kind=2
				# Muted lip/ear coloration is part of the surface, never floating spheres.
				if kind==0 and p[1]>1.48:
					var lip=exp(-pow(float(q[0])/.025,4)-pow((float(q[1])+.027)/.003,4))*smoothstep(.065,.10,-float(q[2]))
					color=color.lerp(Color("946b60") if which not in [2,4] else Color("68483f"),lip*(.55 if which in HumanModel.FEMALE_ROLES else .30))
					var cheek=exp(-pow((absf(q[0])-.045)/.035,2)-pow((q[1]+.008)/.03,2))*smoothstep(.04,.08,-q[2])
					color=color.lerp(color*Color(1.,.94,.91),cheek*.28)
					var hairline=.091 if q[2]<-.040 else .050 if absf(q[0])>.055 else .004
					if q[1]>hairline:
						var hair_color=[Color("463931"),Color("352f2d"),Color("302927"),Color("655346"),Color("55514b"),Color("583f31")][which]
						color=color.lerp(hair_color,smoothstep(hairline,hairline+.008,q[1]))
				var bones=PackedInt32Array([0,0,0,0]);var weights=PackedFloat32Array([0,0,0,0]);var count=0
				for w in info.weights[index]:bones[count]=int(w[0]);weights[count]=float(w[1]);count+=1
				var uv=info.face_uvs[face_id][corner]
				st.set_uv(Vector2(uv[0],uv[1]))
				st.set_bones(bones);st.set_weights(weights);st.set_color(color.srgb_to_linear());st.set_uv2(Vector2(.67 if surface_kind==0 else .9,float(surface_kind)+.01))
				var point=Vector3(p[0],p[1]-.94,p[2])
				if which in HumanModel.FEMALE_ROLES:
					var hip=exp(-pow((p[1]-.93)/.16,2));point.x*=1.+hip*.13
				if p[1]>1.45:
					var shaped=surface_point(which,info,index)
					point=shaped+Vector3(0,.66,0)
				st.add_vertex(point)
		st.generate_normals();st.index();meshes[key]=st.commit()
	var mesh=MeshInstance3D.new();mesh.name="SculptedShirt";mesh.mesh=meshes[key];mesh.material_override=SurfaceFinish.human_material(which);mesh.set_meta("authored_anatomy",true);root.get_node("Hips").add_child(mesh)
static func _remove_base(node:Node3D,colors:Array):
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D and child.material_override.albedo_color in colors:
			node.remove_child(child);child.free()
		elif child is Node3D:_remove_base(child,colors)
