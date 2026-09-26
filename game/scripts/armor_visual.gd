class_name ArmorVisual
extends RefCounted
static var fabric:ShaderMaterial
# Shared plate-carrier silhouette; native adds stitched edging, MOLLE and hardware.
static func build(parent:Node3D,level:int,web:bool) -> Node3D:
	var root=Node3D.new();root.name="PlateCarrier";parent.add_child(root)
	var m=MeshFactory;var cloth=Color("7d8b6b") if level<2 else Color("596b56")
	var trim=cloth.darkened(.28);var stitch=cloth.lightened(.24);var buckle=Color("252d2b")
	if level==0:
		HumanModel.loft(root,Vector3.ZERO,[Vector4(-.23,.147,.112,0),Vector4(.08,.192,.133,0),Vector4(.20,.172,.105,0),Vector4(.245,.065,.055,0)],Color("718891"),16)
		return root
	# Cut shoulders and bevelled upper corners, front and rear plate bags.
	for side in [-1,1]:
		var z=side*(.16 if side<0 else .137)
		plate(root,Vector3(0,-.014,z),.316,.354,.048 if level==1 else .061,cloth)
		if not web:
			plate(root,Vector3(0,-.014,z+side*.028),.298,.336,.009,stitch)
			plate(root,Vector3(0,-.014,z+side*.034),.286,.324,.01,cloth)
	for side in [-1,1]:
		# Shoulder straps loop over the shoulder; side cummerbund closes the carrier.
		m.box(root,Vector3(side*.114,.175,-.008),Vector3(.058,.034,.34),cloth,Vector3(.10,0,side*.05),.15)
		m.box(root,Vector3(side*.172,-.065,-.005),Vector3(.038,.145,.30),trim,Vector3.ZERO,.14)
		m.box(root,Vector3(side*.118,.117,-.191),Vector3(.062,.04,.014),buckle,Vector3.ZERO,.08)
		if not web:
			m.box(root,Vector3(side*.118,.117,-.200),Vector3(.035,.017,.005),stitch)
			for y in [-.108,-.064,-.020]:m.box(root,Vector3(side*.192,y,-.01),Vector3(.008,.019,.25),cloth)
	var front=-.202 if level==1 else -.211
	# Flat Velcro patch and horizontal webbing, never inflated spheres.
	m.box(root,Vector3(0,.095,front),Vector3(.178,.052,.009),trim,Vector3.ZERO,.06)
	for y in ([-.01,-.075] if web else [.030,-.016,-.062,-.108]):
		m.box(root,Vector3(0,y,front),Vector3(.27,.018,.008),stitch,Vector3.ZERO,.02)
		if not web:
			for x in [-.112,-.056,0.,.056,.112]:m.box(root,Vector3(x,y,front-.005),Vector3(.007,.023,.005),trim)
	if level==2:
		for x in [-.092,0.,.092]:
			m.box(root,Vector3(x,-.119,front-.023),Vector3(.078,.14,.047),cloth,Vector3.ZERO,.10)
			m.box(root,Vector3(x,-.059,front-.049),Vector3(.078,.038,.009),trim,Vector3.ZERO,.08)
			if not web:m.box(root,Vector3(x,-.104,front-.050),Vector3(.014,.083,.008),stitch)
		plate(root,Vector3(0,-.235,-.148),.22,.105,.036,cloth)
	if not web:
		# Rear drag handle, bar tacks, plate access flap and fastener studs.
		for x in [-.063,.063]:m.box(root,Vector3(x,.135,.184),Vector3(.025,.048,.020),trim)
		m.box(root,Vector3(0,.155,.192),Vector3(.15,.021,.020),trim)
		m.box(root,Vector3(0,-.178,front-.008),Vector3(.25,.022,.011),trim)
		for x in [-.12,.12]:m.cylinder(root,Vector3(x,-.157,front-.014),.006,.005,buckle,Vector3(PI/2,0,0),-1.,8)
	m.merge_children(root)
	if fabric==null:
		var shader=Shader.new();shader.code="shader_type spatial; render_mode cull_disabled; void fragment(){vec3 cloth=COLOR.rgb;if(OUTPUT_IS_SRGB){cloth=pow(max(cloth,vec3(0.001)),vec3(1.0/2.2));}ALBEDO=cloth;EMISSION=cloth*0.10;ROUGHNESS=0.98;SPECULAR=0.0;}"
		fabric=ShaderMaterial.new();fabric.shader=shader
	for mesh in root.get_children():
		if mesh is MeshInstance3D:mesh.material_override=fabric
	return root
static func plate(parent:Node3D,pos:Vector3,width:float,height:float,depth:float,color:Color):
	var corners=[Vector2(-.5,-.5),Vector2(.5,-.5),Vector2(.5,.25),Vector2(.30,.5),Vector2(-.30,.5),Vector2(-.5,.25)]
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for i in range(corners.size()):
			var a=corners[i];var b=corners[(i+1)%corners.size()]
			var tri=[Vector3(0,0,side*depth*.5),Vector3(a.x*width,a.y*height,side*depth*.5),Vector3(b.x*width,b.y*height,side*depth*.5)]
			if side<0:tri.reverse()
			st.set_normal(Vector3(0,0,side))
			for v in tri:st.add_vertex(v)
	for i in range(corners.size()):
		var a=corners[i]*Vector2(width,height);var b=corners[(i+1)%corners.size()]*Vector2(width,height)
		st.set_normal(Vector3(b.y-a.y,a.x-b.x,0).normalized())
		for v in [Vector3(a.x,a.y,-depth*.5),Vector3(b.x,b.y,-depth*.5),Vector3(b.x,b.y,depth*.5),Vector3(a.x,a.y,-depth*.5),Vector3(b.x,b.y,depth*.5),Vector3(a.x,a.y,depth*.5)]:st.add_vertex(v)
	MeshFactory.instance(parent,st.commit(),pos,color)
