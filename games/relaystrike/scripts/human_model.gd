extends RefCounted
class_name HumanModel
const M=preload("res://scripts/mesh_factory.gd")
const HEIGHTS=[1.80,1.72,1.88,1.76,1.83,1.70]
const WIDTHS=[1.0,.94,1.08,1.01,.98,.95]
static func joint(parent:Node,label:String,pos:Vector3) -> Node3D:
	var n=Node3D.new();n.name=label;n.position=pos;parent.add_child(n);return n
# Elliptical cross sections make anatomical volumes and fabric, with continuous normals.
# Each ring is (height, half-width, half-depth, depth-offset).
static func loft(parent:Node,pos:Vector3,rings:Array,color:Color,sides:int=16) -> MeshInstance3D:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
	for j in range(rings.size()-1):
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var r=rings[j];var s=rings[j+1]
			var p=Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w)
			var q=Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w)
			var u=Vector3(cos(a)*s.y,s.x,sin(a)*s.z+s.w)
			var v=Vector3(cos(b)*s.y,s.x,sin(b)*s.z+s.w)
			for point in [p,q,u,q,v,u]:st.add_vertex(point)
	st.generate_normals();return M.instance(parent,st.commit(),pos,color)
static func oval(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.;mesh.radial_segments=20;mesh.rings=12
	var n=M.instance(parent,mesh,pos,color);n.scale=size;return n
static func cord(parent:Node,a:Vector3,b:Vector3,radius:float,color:Color):
	var mesh=CapsuleMesh.new();mesh.radius=radius;mesh.height=a.distance_to(b)+radius*2.;mesh.radial_segments=12;mesh.rings=4
	var n=M.instance(parent,mesh,(a+b)*.5,color);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized());return n
static func hand(parent:Node,skin:Color,glove:Color,side:float):
	oval(parent,Vector3(0,-.01,0),Vector3(.085,.105,.055),glove)
	oval(parent,Vector3(0,.025,.022),Vector3(.075,.04,.025),skin)
	for finger in range(4):
		var x=(finger-1.5)*.019;var length=.033+(.008 if finger in [1,2] else 0.)
		cord(parent,Vector3(x,-.044,0),Vector3(x,-.044-length,-.01),.010,glove)
		cord(parent,Vector3(x,-.044-length,-.01),Vector3(x,-.052-length,-.028),.009,skin)
	cord(parent,Vector3(side*.039,.005,-.008),Vector3(side*.052,-.025,-.032),.014,glove)
static func face(parent:Node,which:int,skin:Color,hair:Color):
	# Open face, jaw, cheekbones, ears, nose bridge, eyelids and lips.
	loft(parent,Vector3.ZERO,[Vector4(-.105,.028,.040,-.012),Vector4(-.09,.063,.067,-.01),Vector4(-.045,.098,.086,0),Vector4(.018,.113,.102,.004),Vector4(.065,.109,.106,.007),Vector4(.115,.091,.091,.014),Vector4(.143,.046,.051,.018),Vector4(.150,.002,.002,.018)],skin,24)
	for side in [-1,1]:
		oval(parent,Vector3(side*.11,.006,.008),Vector3(.039,.070,.038),skin)
		oval(parent,Vector3(side*.117,.008,-.011),Vector3(.014,.038,.016),skin.darkened(.18))
		oval(parent,Vector3(side*.043,.044,-.095),Vector3(.035,.014,.012),Color("d7cebc"))
		oval(parent,Vector3(side*.043,.044,-.103),Vector3(.014,.015,.005),Color("526466") if which%2==0 else Color("685242"))
		oval(parent,Vector3(side*.043,.044,-.106),Vector3(.006,.009,.002),Color("233238"))
		cord(parent,Vector3(side*.027,.063,-.097),Vector3(side*.065,.065,-.088),.004,hair)
		cord(parent,Vector3(side*.026,.052,-.102),Vector3(side*.062,.053,-.097),.0025,skin.darkened(.3))
	oval(parent,Vector3(0,.015,-.099),Vector3(.025,.067,.034),skin)
	oval(parent,Vector3(0,-.010,-.119),Vector3(.035,.025,.038),skin.lightened(.035))
	cord(parent,Vector3(-.024,-.055,-.081),Vector3(.024,-.055,-.081),.004,skin.darkened(.28))
	oval(parent,Vector3(0,-.064,-.077),Vector3(.041,.010,.011),skin.darkened(.09))
	if which in [0,3,4]:
		loft(parent,Vector3(0,0,.003),[Vector4(-.090,.041,.044,-.01),Vector4(-.070,.067,.071,0),Vector4(-.039,.079,.079,0)],hair.lightened(.12),20)
	# A fitted scalp follows the skull; no full-face visor or box helmet.
	loft(parent,Vector3(0,0,.007),[Vector4(.070,.108,.108,.009),Vector4(.115,.098,.100,.012),Vector4(.151,.055,.068,.014),Vector4(.16,.002,.002,.014)],hair,24)
	for i in range(5):
		cord(parent,Vector3(-.075+i*.029,.115,-.063),Vector3(-.046+i*.024,.151,.012),.008,hair.lightened(.10))
	if which==1:
		oval(parent,Vector3(0,.123,.018),Vector3(.27,.09,.23),Color("5c6954"))
		oval(parent,Vector3(.028,.165,.010),Vector3(.15,.025,.15),Color("6e7b5e"))
	elif which==2:
		loft(parent,Vector3(0,.012,.014),[Vector4(.067,.119,.117,0),Vector4(.093,.124,.12,0),Vector4(.151,.085,.092,0),Vector4(.17,.008,.014,0)],Color("5c696b"),24)
	elif which==3:
		oval(parent,Vector3(0,.14,0),Vector3(.25,.07,.24),Color("bb955c"))
		oval(parent,Vector3(0,.108,-.117),Vector3(.21,.018,.12),Color("a5804f"))
	elif which==5:
		oval(parent,Vector3(0,.133,.002),Vector3(.24,.058,.23),Color("d1c9ab"))
		oval(parent,Vector3(0,.111,-.115),Vector3(.18,.016,.095),Color("c7c3ae"))
	# Small communication headset leaves the face and human silhouette readable.
	oval(parent,Vector3(.118,.012,.014),Vector3(.038,.059,.051),Color("414947"))
	cord(parent,Vector3(.125,-.004,0),Vector3(.061,-.055,-.10),.005,Color("383f3f"))
static func build(which:int,team:int) -> Node3D:
	var root=Node3D.new();root.name="Operator";root.scale=Vector3(WIDTHS[which],HEIGHTS[which]/1.8,WIDTHS[which]);root.set_meta("height_m",HEIGHTS[which])
	var skin=[Color("bd9278"),Color("d8b098"),Color("91674f"),Color("c69b77"),Color("a5775c"),Color("d0aa91")][which]
	var hair=[Color("463931"),Color("352f2d"),Color("302927"),Color("655346"),Color("55514b"),Color("583f31")][which]
	var shirt=Color("718891") if team==0 else Color("98806a")
	var trousers=Color("475963") if team==0 else Color("655e50")
	var vest=Color("596552") if which!=5 else Color("b1b19b")
	var team_color=Color("4d9ac0") if team==0 else Color("d29358")
	var dark=Color("383d39")
	var hips=joint(root,"Hips",Vector3(0,.94,0));var chest=joint(hips,"Chest",Vector3(0,.3,0))
	loft(hips,Vector3.ZERO,[Vector4(-.12,.11,.10,0),Vector4(-.08,.183,.127,.01),Vector4(.02,.19,.13,0),Vector4(.105,.17,.115,0)],trousers)
	loft(chest,Vector3.ZERO,[Vector4(-.22,.16,.107,0),Vector4(-.12,.181,.12,.01),Vector4(.02,.214,.132,0),Vector4(.14,.235,.128,0),Vector4(.20,.211,.103,0),Vector4(.245,.075,.065,0)],shirt,20)
	loft(chest,Vector3(0,0,-.010),[Vector4(-.17,.172,.124,0),Vector4(-.1,.190,.138,0),Vector4(.06,.220,.145,0),Vector4(.15,.196,.128,0)],vest,20)
	for side in [-1,1]:
		cord(chest,Vector3(side*.15,-.12,-.119),Vector3(side*.148,.192,-.076),.023,vest.lightened(.12))
		var arm=joint(chest,"LeftArm" if side<0 else "RightArm",Vector3(side*.26,.13,0))
		oval(arm,Vector3(-side*.026,-.014,0),Vector3(.16,.17,.16),shirt)
		loft(arm,Vector3.ZERO,[Vector4(-.285,.049,.051,0),Vector4(-.20,.065,.064,0),Vector4(-.12,.078,.076,0),Vector4(-.045,.088,.083,0),Vector4(.016,.052,.058,0)],shirt)
		loft(arm,Vector3.ZERO,[Vector4(-.19,.069,.069,0),Vector4(-.155,.075,.074,0)],team_color)
		for y in [-.21,-.24]:loft(arm,Vector3.ZERO,[Vector4(y-.01,.061,.061,0),Vector4(y,.068,.067,0),Vector4(y+.01,.061,.061,0)],shirt.darkened(.05))
		var elbow=joint(arm,"Elbow",Vector3(0,-.28,0))
		loft(elbow,Vector3.ZERO,[Vector4(-.275,.031,.034,0),Vector4(-.22,.04,.043,0),Vector4(-.10,.059,.056,0),Vector4(-.02,.053,.052,0),Vector4(.02,.043,.044,0)],skin)
		loft(elbow,Vector3.ZERO,[Vector4(-.065,.058,.057,0),Vector4(-.020,.058,.057,0),Vector4(.008,.052,.051,0)],shirt)
		var palm=joint(elbow,"Hand",Vector3(0,-.275,0));hand(palm,skin,dark,side)
		var leg=joint(hips,"LeftLeg" if side<0 else "RightLeg",Vector3(side*.128,-.025,0))
		loft(leg,Vector3.ZERO,[Vector4(-.43,.064,.069,0),Vector4(-.34,.068,.074,0),Vector4(-.17,.088,.093,.009),Vector4(-.03,.105,.102,0),Vector4(.02,.087,.096,0)],trousers)
		oval(leg,Vector3(side*.078,-.19,.012),Vector3(.065,.15,.12),trousers.lightened(.12))
		var knee=joint(leg,"Knee",Vector3(0,-.415,0))
		loft(knee,Vector3.ZERO,[Vector4(-.407,.044,.049,.015),Vector4(-.31,.05,.06,.020),Vector4(-.17,.067,.074,.01),Vector4(-.05,.065,.065,0),Vector4(.023,.059,.062,0)],trousers)
		oval(knee,Vector3(0,-.025,-.059),Vector3(.108,.126,.040),vest)
		for y in [-.31,-.34]:loft(knee,Vector3.ZERO,[Vector4(y-.008,.049,.058,.01),Vector4(y,.055,.063,.01),Vector4(y+.01,.049,.058,.01)],trousers.lightened(.07))
		var foot=joint(knee,"Foot",Vector3(0,-.415,0))
		oval(foot,Vector3(0,.025,-.065),Vector3(.155,.14,.27),dark)
		loft(foot,Vector3(0,0,-.06),[Vector4(-.045,.052,.08,0),Vector4(-.032,.079,.138,0),Vector4(-.015,.079,.136,0)],dark.darkened(.28))
		for k in range(3):cord(foot,Vector3(-.038,.078,-.035-k*.025),Vector3(.038,.078,-.035-k*.025),.004,Color("9c947b"))
	loft(hips,Vector3.ZERO,[Vector4(.066,.191,.137,0),Vector4(.103,.181,.124,0)],dark)
	M.box(hips,Vector3(0,.083,-.13),Vector3(.047,.03,.018),Color("9b9d89"),Vector3.ZERO,.6)
	for x in [-.12,0,.12]:
		oval(chest,Vector3(x,-.112,-.143),Vector3(.101,.15,.066),vest.darkened(.13))
		cord(chest,Vector3(x-.035,-.045,-.15),Vector3(x+.035,-.045,-.15),.006,vest.lightened(.25))
	loft(chest,Vector3(0,.256,0),[Vector4(-.025,.059,.056,0),Vector4(.07,.055,.054,0)],skin)
	var head=joint(chest,"Head",Vector3(0,.36,0));face(head,which,skin,hair)
	# Role-specific soft gear: radio, scout scarf, padded vest, tool roll, satchel, medical bag.
	if which==1:
		loft(chest,Vector3(0,.23,0),[Vector4(-.035,.11,.085,0),Vector4(.01,.075,.073,0)],Color("899274"))
	if which==2:oval(chest,Vector3(0,-.015,.16),Vector3(.34,.40,.19),Color("6a715e"))
	if which==3:
		oval(hips,Vector3(.213,-.105,.028),Vector3(.10,.19,.19),Color("987851"))
		for i in range(3):cord(hips,Vector3(.26,-.12,.0+i*.04),Vector3(.26,.07,.0+i*.04),.011,Color("a8aa9b"))
	if which==4:oval(chest,Vector3(-.10,-.1,.167),Vector3(.26,.31,.16),Color("797970"))
	if which==5:
		oval(chest,Vector3(0,-.04,.17),Vector3(.32,.36,.18),Color("bbb8a0"))
		M.box(chest,Vector3(0,.06,-.155),Vector3(.027,.10,.01),Color("c87360"));M.box(chest,Vector3(0,.06,-.16),Vector3(.095,.028,.01),Color("c87360"))
	if which in [0,4]:
		oval(chest,Vector3(.16,.06,.133),Vector3(.09,.16,.085),dark)
		cord(chest,Vector3(.16,.13,.14),Vector3(.16,.29,.14),.004,dark)
	joint(chest,"WeaponSocket",Vector3(.07,-.09,-.07))
	return root
