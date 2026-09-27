class_name CartoonModel
extends RefCounted
## Original angular comic operators. Same skeleton, scale and weapon sockets;
## no skin photographs, pores, eye spheres, implicit surfaces or finger chains.
static func box(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=size
	return MeshFactory.instance(parent,mesh,pos,color)
static func form(parent:Node,rings:Array,color:Color,sides:int=8,hair_role:int=-1):
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
	for level in range(rings.size()-1):
		var low:Vector3=rings[level];var high:Vector3=rings[level+1]
		for i in range(sides):
			var angle=i*TAU/sides;var next=(i+1)*TAU/sides
			var a=Vector3(cos(angle)*low.y,low.x,sin(angle)*low.z)
			var b=Vector3(cos(next)*low.y,low.x,sin(next)*low.z)
			var c=Vector3(cos(angle)*high.y,high.x,sin(angle)*high.z)
			var d=Vector3(cos(next)*high.y,high.x,sin(next)*high.z)
			if hair_role>=0:
				paint_head_face(st,[a,b,c],color,hair_role);paint_head_face(st,[b,d,c],color,hair_role)
			else:
				for point in [a,b,c,b,d,c]:st.add_vertex(point)
	for end in [0,rings.size()-1]:
		var ring:Vector3=rings[end]
		for i in range(sides):
			var a=Vector3(cos(i*TAU/sides)*ring.y,ring.x,sin(i*TAU/sides)*ring.z)
			var b=Vector3(cos((i+1)*TAU/sides)*ring.y,ring.x,sin((i+1)*TAU/sides)*ring.z)
			var triangle=[Vector3(0,ring.x,0),b,a] if end==0 else [Vector3(0,ring.x,0),a,b]
			if hair_role>=0:paint_head_face(st,triangle,color,hair_role)
			else:
				for point in triangle:st.add_vertex(point)
	st.generate_normals();st.index()
	var mesh=MeshFactory.instance(parent,st.commit(),Vector3.ZERO,color)
	if hair_role>=0:
		mesh.material_override=ToonMaterials.vertex_material()
static func paint_head_face(st:SurfaceTool,triangle:Array,skin:Color,role:int):
	# Split on the hairline before baking vertex colors: no floating shell,
	# z-fighting, extra material or added runtime draw call.
	var signed=[]
	for p in triangle:
		var front=clampf(-sin(atan2(p.z,p.x)),0.,1.)
		signed.append(p.y-lerpf(-.007,.078 if role==1 else .083,smoothstep(.15,.55,front)))
	for hair in [false,true]:
		var polygon=[]
		for i in range(3):
			var j=(i+1)%3;var a:Vector3=triangle[i];var b:Vector3=triangle[j]
			var inside=signed[i]>=0. if hair else signed[i]<=0.;var next=signed[j]>=0. if hair else signed[j]<=0.
			if inside:polygon.append(a)
			if inside!=next:polygon.append(a.lerp(b,signed[i]/(signed[i]-signed[j])))
		var color=Color("393a43") if role==1 else Color("453b3e")
		for i in range(1,polygon.size()-1):
			for p in [polygon[0],polygon[i],polygon[i+1]]:
				st.set_color((color if hair else skin).srgb_to_linear());st.add_vertex(p)
static func build(role:int,team:int) -> Node3D:
	var rig=HumanModel.pose_rig(role)
	rig.set_meta("height_m",HumanModel.HEIGHTS[role]);rig.set_meta("identity",HumanModel.IDENTITIES[role]);rig.set_meta("gender","female" if role in HumanModel.FEMALE_ROLES else "male")
	var hips=rig.get_node("Hips");var chest=hips.get_node("Chest");var head=chest.get_node("Head")
	var shirt=Color("527f9c") if team==0 else Color("c4844d")
	var trousers=Color("304e69") if team==0 else Color("79523b")
	var accent=Color("65d7ff") if team==0 else Color("ffbc65")
	var skin=HumanModel.SKIN_COLORS[role].lightened(.12);var ink=Color("26303d")
	form(hips,[Vector3(-.12,.14,.11),Vector3(.10,.17,.12)],trousers)
	form(chest,[Vector3(-.21,.145,.11),Vector3(.10,.20,.13),Vector3(.22,.10,.09)],shirt)
	form(chest,[Vector3(.20,.055,.05),Vector3(.30,.055,.05)],skin)
	var female=role in HumanModel.FEMALE_ROLES
	form(head,[Vector3(-.073,.036,.055),Vector3(-.052,.049,.069),Vector3(-.022,.061,.067),Vector3(.055,.081,.083),Vector3(.13,.08,.078),Vector3(.18,.052,.053)],skin,12,role) if female else form(head,[Vector3(-.09,.055,.065),Vector3(-.04,.085,.085),Vector3(.10,.087,.088),Vector3(.18,.055,.055)],skin)
	# Flat painted eyes/brows and one small nose, no glossy eyeballs or skin maps.
	for side in [-1,1]:
		box(head,Vector3(side*.038,.045,-.083),Vector3(.026,.012,.009),ink)
		if female:
			box(head,Vector3(side*.038,.043,-.089),Vector3(.020,.009,.003),Color("d1c6b3"))
			box(head,Vector3(side*.038,.043,-.092),Vector3(.008,.009,.003),Color("473a31"))
		box(head,Vector3(side*.038,.071,-.080),Vector3(.035,.008,.008),ink)
	box(head,Vector3(0,.006,-.091),Vector3(.017,.032,.018),skin.darkened(.08))
	box(head,Vector3(0,-.031,-.069 if female else -.079),Vector3(.031,.006,.009),Color("785548"))
	var hat=[ink,Color("50715b"),ink,Color("e2b34c"),ink,Color("f1e9ce")][role]
	if female:OperatorHair.build(head,role,true)
	else:
		form(head,[Vector3(.10,.092,.095),Vector3(.18,.082,.080),Vector3(.205,.055,.055)],hat)
		if role==3:box(head,Vector3(0,.103,-.091),Vector3(.19,.015,.085),hat)
	for side in [-1,1]:
		var prefix="Left" if side<0 else "Right"
		var arm=chest.get_node(prefix+"Arm");var elbow=arm.get_node("Elbow");var hand=elbow.get_node("Hand")
		form(arm,[Vector3(-.28,.046,.05),Vector3(-.03,.072,.07),Vector3(.02,.060,.06)],shirt)
		box(arm,Vector3(0,-.15,-.057),Vector3(.095,.045,.026),accent)
		form(elbow,[Vector3(-.27,.032,.034),Vector3(-.02,.052,.052)],skin)
		box(hand,Vector3(0,-.015,-.012),Vector3(.07,.10,.055),ink)
		var leg=hips.get_node(prefix+"Leg");var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
		form(leg,[Vector3(-.415,.06,.065),Vector3(-.02,.09,.09)],trousers)
		form(knee,[Vector3(-.40,.043,.048),Vector3(-.02,.061,.067)],trousers)
		box(knee,Vector3(0,-.05,-.065),Vector3(.10,.13,.028),ink)
		box(foot,Vector3(0,.015,-.055),Vector3(.14,.12,.24),ink)
	if role==2:box(chest,Vector3(0,0,.16),Vector3(.32,.36,.14),ink)
	if role==3:box(hips,Vector3(.20,-.02,0),Vector3(.10,.20,.16),hat)
	if role==4:box(chest,Vector3(0,0,.16),Vector3(.27,.30,.13),Color("798260"))
	if role==5:
		box(chest,Vector3(0,0,.16),Vector3(.28,.29,.13),Color("e8dcc2"))
	return rig
