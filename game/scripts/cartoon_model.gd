class_name CartoonModel
extends RefCounted
## Original angular comic operators. Same skeleton, scale and weapon sockets;
## no skin photographs, pores, eye spheres, implicit surfaces or finger chains.
static func box(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=size
	return MeshFactory.instance(parent,mesh,pos,color)
static func form(parent:Node,rings:Array,color:Color,sides:int=8):
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
	for level in range(rings.size()-1):
		var low:Vector3=rings[level];var high:Vector3=rings[level+1]
		for i in range(sides):
			var angle=i*TAU/sides;var next=(i+1)*TAU/sides
			var a=Vector3(cos(angle)*low.y,low.x,sin(angle)*low.z)
			var b=Vector3(cos(next)*low.y,low.x,sin(next)*low.z)
			var c=Vector3(cos(angle)*high.y,high.x,sin(angle)*high.z)
			var d=Vector3(cos(next)*high.y,high.x,sin(next)*high.z)
			for point in [a,b,c,b,d,c]:st.add_vertex(point)
	for end in [0,rings.size()-1]:
		var ring:Vector3=rings[end]
		for i in range(sides):
			var a=Vector3(cos(i*TAU/sides)*ring.y,ring.x,sin(i*TAU/sides)*ring.z)
			var b=Vector3(cos((i+1)*TAU/sides)*ring.y,ring.x,sin((i+1)*TAU/sides)*ring.z)
			for point in ([Vector3(0,ring.x,0),b,a] if end==0 else [Vector3(0,ring.x,0),a,b]):st.add_vertex(point)
	st.generate_normals();st.index();MeshFactory.instance(parent,st.commit(),Vector3.ZERO,color)
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
	form(head,[Vector3(-.09,.055,.065),Vector3(-.04,.085,.085),Vector3(.10,.087,.088),Vector3(.18,.055,.055)],skin)
	# Flat painted eyes/brows and one small nose, no glossy eyeballs or skin maps.
	for side in [-1,1]:
		box(head,Vector3(side*.038,.045,-.083),Vector3(.026,.012,.009),ink)
		box(head,Vector3(side*.038,.071,-.080),Vector3(.035,.008,.008),ink)
	box(head,Vector3(0,.006,-.091),Vector3(.017,.032,.018),skin.darkened(.08))
	box(head,Vector3(0,-.038,-.079),Vector3(.031,.006,.009),Color("785548"))
	var hat=[ink,Color("50715b"),ink,Color("e2b34c"),ink,Color("f1e9ce")][role]
	form(head,[Vector3(.10,.092,.095),Vector3(.18,.082,.080),Vector3(.205,.055,.055)],hat)
	if role in [1,3,5]:box(head,Vector3(0,.103,-.091),Vector3(.19,.015,.085),hat)
	if role in HumanModel.FEMALE_ROLES:box(head,Vector3(0,.01,.075),Vector3(.15,.20,.055),ink)
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
		box(chest,Vector3(0,.015,-.18),Vector3(.10,.025,.02),Color("f17669"))
		box(chest,Vector3(0,.015,-.183),Vector3(.025,.10,.02),Color("f17669"))
	return rig
