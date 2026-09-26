extends RefCounted
class_name HumanModel
const M=preload("res://scripts/mesh_factory.gd")
const HEIGHTS=[1.80,1.72,1.88,1.76,1.83,1.70]
const WIDTHS=[1.0,.95,1.08,1.01,.98,.95]
const FEMALE_ROLES=[1,5]
const IDENTITIES=["MASON", "SERA", "BRIGGS", "REED", "VALE", "MINA"]
const SKIN_COLORS=[Color("b3a28c"),Color("c7b69f"),Color("89765f"),Color("b9a48a"),Color("9b866e"),Color("c2b099")]
static func joint(parent:Node,label:String,pos:Vector3) -> Node3D:
	var n=Node3D.new();n.name=label;n.position=pos;parent.add_child(n);return n
static func pose_rig(which:int) -> Node3D:
	var rig=Node3D.new();rig.scale=Vector3(WIDTHS[which],HEIGHTS[which]/1.8,1.0 if which in FEMALE_ROLES else WIDTHS[which])
	var hips=joint(rig,"Hips",Vector3(0,.94,0));var chest=joint(hips,"Chest",Vector3(0,.3,0))
	joint(chest,"Head",Vector3(0,.36,0));joint(chest,"WeaponSocket",Vector3(.07,-.09,-.07))
	for side in [-1,1]:
		var prefix="Left" if side<0 else "Right"
		var arm=joint(chest,prefix+"Arm",Vector3(side*.207,.105,0))
		var elbow=joint(arm,"Elbow",Vector3(0,-.28,0));joint(elbow,"Hand",Vector3(0,-.275,0))
		var leg=joint(hips,prefix+"Leg",Vector3(side*.099,-.025,0));var knee=joint(leg,"Knee",Vector3(0,-.415,0));joint(knee,"Foot",Vector3(0,-.415,0))
	return rig
# Elliptical cross sections make anatomical volumes and fabric, with continuous normals.
# Each ring is (height, half-width, half-depth, depth-offset).
static func loft(parent:Node,pos:Vector3,rings:Array,color:Color,sides:int=20,sculpt:bool=false) -> MeshInstance3D:
	var smooth=[]
	for j in range(rings.size()-1):
		var a:Vector4=rings[maxi(0,j-1)];var b:Vector4=rings[j];var c:Vector4=rings[j+1];var d:Vector4=rings[mini(rings.size()-1,j+2)]
		for step in range(3):
			var t=step/3.;var point=(b*2.+(c-a)*t+(a*2.-b*5.+c*4.-d)*t*t+(-a+b*3.-c*3.+d)*t*t*t)*.5
			point.y=maxf(.001,point.y);point.z=maxf(.001,point.z);smooth.append(point)
	smooth.append(rings[-1]);rings=smooth
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
	for j in range(rings.size()-1):
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var r=rings[j];var s=rings[j+1]
			var p=Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w)
			var q=Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w)
			var u=Vector3(cos(a)*s.y,s.x,sin(a)*s.z+s.w)
			var v=Vector3(cos(b)*s.y,s.x,sin(b)*s.z+s.w)
			for point in [p,q,u,q,v,u]:st.add_vertex(sculpt_face(point) if sculpt else point)
	# Every loft is a closed solid, including the stock/receiver seen from behind.
	# Separate smoothing groups keep end caps from rounding side normals.
	st.set_smooth_group(-1)
	for end in [0,rings.size()-1]:
		var r=rings[end];var center=Vector3(0,r.x,r.w)
		for i in range(sides):
			var a=TAU*i/sides;var b=TAU*(i+1)/sides
			var p=Vector3(cos(a)*r.y,r.x,sin(a)*r.z+r.w);var q=Vector3(cos(b)*r.y,r.x,sin(b)*r.z+r.w)
			for point in ([center,q,p] if end==0 else [center,p,q]):st.add_vertex(point)
	st.generate_normals();st.index();return M.instance(parent,st.commit(),pos,color)
static func sculpt_face(point:Vector3) -> Vector3:
	if point.z>=0:return point
	var x=point.x;var y=point.y;var front=smoothstep(.015,.065,-point.z)
	var eye=exp(-pow((absf(x)-.043)/.024,2)-pow((y-.037)/.018,2))
	var brow=exp(-pow((absf(x)-.038)/.035,2)-pow((y-.064)/.015,2))
	var cheek=exp(-pow((absf(x)-.057)/.027,2)-pow((y+.010)/.025,2))
	var bridge=exp(-pow(x/.012,2)-pow((y-.025)/.035,2))
	var tip=exp(-pow(x/.019,2)-pow((y+.008)/.016,2))
	point.z+=front*(eye*.009-brow*.006-cheek*.006-bridge*.013-tip*.017)
	return point
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
	var female=which in FEMALE_ROLES
	var jaw=.052 if female else .063+which*.001
	var eye_color=[Color("5d725f"),Color("796046"),Color("4c382b"),Color("6c858a"),Color("89734f"),Color("483b34")][which]
	# Eyelids, nose, lips, ears and jaw are now the continuous authored mesh.
	for eye in AuthoredHuman.eyes(which):
		var center=Vector3(eye[0],eye[1],eye[2]);var side=signf(center.x)
		oval(parent,center,Vector3(.022,.022,.022),Color("c4c5b9"))
		oval(parent,center+Vector3(0,0,-.0108),Vector3(.009,.009,.002),eye_color)
		oval(parent,center+Vector3(0,0,-.012),Vector3(.004,.004,.001),Color("182023"))
		oval(parent,center+Vector3(-.001,.002,-.0125),Vector3(.0012,.0012,.0006),Color("e5ddd0"))
		cord(parent,center+Vector3(-side*.013,.017,-.002),center+Vector3(side*.010,.019,.003),.0024,hair)
	if female:
		for side in [-1,1]:
			oval(parent,Vector3(side*.072,.022,.048),Vector3(.030,.15 if which==5 else .12,.08),hair)
		if which==1:
			oval(parent,Vector3(0,.066,.133),Vector3(.090,.12,.10),hair)
			cord(parent,Vector3(0,.03,.143),Vector3(0,-.11,.153),.027,hair)
			cord(parent,Vector3(-.028,.015,.15),Vector3(.028,.015,.15),.008,Color("779085"))
	if which==1:
		# Fitted beret: a band wraps the temples and the asymmetric crown rests on it.
		loft(parent,Vector3(0,0,.013),[Vector4(.071,.090,.103,0),Vector4(.090,.091,.105,0),Vector4(.099,.089,.103,0)],Color("455447"),28)
		var crown=loft(parent,Vector3(-.009,0,.013),[Vector4(.089,.091,.103,0),Vector4(.125,.108,.108,.006),Vector4(.159,.076,.079,.01),Vector4(.171,.006,.008,.012)],Color("5c6954"),28);crown.rotation.z=-.10
	elif which==2:
		loft(parent,Vector3(0,.012,.014),[Vector4(.067,.094,.10,0),Vector4(.093,.098,.101,0),Vector4(.145,.065,.08,0),Vector4(.155,.008,.014,0)],Color("5c696b"),24)
	elif which==3:
		loft(parent,Vector3(0,0,.012),[Vector4(.073,.095,.109,0),Vector4(.112,.094,.109,0),Vector4(.145,.078,.088,.006),Vector4(.164,.010,.014,.008)],Color("bb955c"),28)
		oval(parent,Vector3(0,.079,-.115),Vector3(.192,.018,.135),Color("a5804f"))
	elif which==5:
		loft(parent,Vector3(0,0,.014),[Vector4(.070,.085,.101,0),Vector4(.104,.086,.102,0),Vector4(.147,.067,.081,0),Vector4(.162,.009,.012,0)],Color("d1c9ab"),28)
	# Small communication headset leaves the face and human silhouette readable.
	oval(parent,Vector3(.092,.012,.014),Vector3(.038,.059,.051),Color("414947"))
	cord(parent,Vector3(.099,-.004,0),Vector3(.061,-.055,-.10),.005,Color("383f3f"))
static func build(which:int,team:int) -> Node3D:
	var root=Node3D.new();root.name="Operator";root.scale=Vector3(WIDTHS[which],HEIGHTS[which]/1.8,1.0 if which in FEMALE_ROLES else WIDTHS[which]);root.set_meta("height_m",HEIGHTS[which]);root.set_meta("gender","female" if which in FEMALE_ROLES else "male");root.set_meta("identity",IDENTITIES[which])
	var skin=SKIN_COLORS[which]
	var hair=[Color("463931"),Color("352f2d"),Color("302927"),Color("655346"),Color("55514b"),Color("583f31")][which]
	var shirt=Color("718891") if team==0 else Color("98806a")
	var trousers=Color("475963") if team==0 else Color("655e50")
	var vest=Color("596552") if which!=5 else Color("b1b19b")
	var team_color=Color("4d9ac0") if team==0 else Color("d29358")
	var dark=Color("383d39")
	var hips=joint(root,"Hips",Vector3(0,.94,0));var chest=joint(hips,"Chest",Vector3(0,.3,0))
	loft(hips,Vector3.ZERO,[Vector4(-.15,.10,.10,0),Vector4(-.09,.168,.127,.01),Vector4(.02,.172,.13,0),Vector4(.105,.158,.115,0)],trousers)
	loft(chest,Vector3.ZERO,[Vector4(-.23,.145,.101,0),Vector4(-.13,.156,.108,.009),Vector4(.01,.181,.125,0),Vector4(.115,.192,.126,0),Vector4(.19,.169,.097,0),Vector4(.245,.062,.055,0)],shirt,24)
	loft(chest,Vector3(0,.248,0),[Vector4(-.025,.073,.063,0),Vector4(.009,.066,.056,0)],shirt.darkened(.12),28)

	for side in [-1,1]:
		var arm=joint(chest,"LeftArm" if side<0 else "RightArm",Vector3(side*.207,.105,0))
		oval(arm,Vector3(-side*.028,-.025,0),Vector3(.119,.15,.131),shirt)
		loft(arm,Vector3.ZERO,[Vector4(-.285,.046,.048,0),Vector4(-.20,.058,.058,0),Vector4(-.12,.061,.062,0),Vector4(-.045,.065,.068,0),Vector4(.016,.05,.056,0)],shirt)
		loft(arm,Vector3.ZERO,[Vector4(-.19,.069,.069,0),Vector4(-.155,.075,.074,0)],team_color)
		for y in [-.21,-.24]:loft(arm,Vector3.ZERO,[Vector4(y-.008,.056,.057,0),Vector4(y,.061,.061,0),Vector4(y+.008,.056,.057,0)],shirt.darkened(.04))
		var elbow=joint(arm,"Elbow",Vector3(0,-.28,0))
		loft(elbow,Vector3.ZERO,[Vector4(-.275,.031,.034,0),Vector4(-.22,.04,.043,0),Vector4(-.10,.059,.056,0),Vector4(-.02,.053,.052,0),Vector4(.02,.043,.044,0)],skin)
		loft(elbow,Vector3.ZERO,[Vector4(-.065,.058,.057,0),Vector4(-.020,.058,.057,0),Vector4(.008,.052,.051,0)],shirt)
		var palm=joint(elbow,"Hand",Vector3(0,-.275,0));pass # Hand geometry is weighted in AuthoredHuman.
		var leg=joint(hips,"LeftLeg" if side<0 else "RightLeg",Vector3(side*.099,-.025,0))
		loft(leg,Vector3.ZERO,[Vector4(-.43,.064,.069,0),Vector4(-.34,.068,.074,0),Vector4(-.17,.088,.093,.009),Vector4(-.03,.105,.102,0),Vector4(.02,.087,.096,0)],trousers)
		oval(leg,Vector3(side*.065,-.19,.022),Vector3(.047,.13,.10),trousers.lightened(.06))
		var knee=joint(leg,"Knee",Vector3(0,-.415,0))
		loft(knee,Vector3.ZERO,[Vector4(-.407,.044,.049,.015),Vector4(-.31,.05,.06,.020),Vector4(-.17,.067,.074,.01),Vector4(-.05,.065,.065,0),Vector4(.023,.059,.062,0)],trousers)
		oval(knee,Vector3(0,-.025,-.059),Vector3(.108,.126,.040),vest)
		for y in [-.31,-.34]:loft(knee,Vector3.ZERO,[Vector4(y-.008,.049,.058,.01),Vector4(y,.055,.063,.01),Vector4(y+.01,.049,.058,.01)],trousers.lightened(.07))
		var foot=joint(knee,"Foot",Vector3(0,-.415,0))
		oval(foot,Vector3(0,.025,-.065),Vector3(.155,.14,.27),dark)
		loft(foot,Vector3(0,0,-.06),[Vector4(-.045,.052,.08,0),Vector4(-.032,.079,.138,0),Vector4(-.015,.079,.136,0)],dark.darkened(.28))
		for k in range(3):cord(foot,Vector3(-.038,.078,-.035-k*.025),Vector3(.038,.078,-.035-k*.025),.004,Color("9c947b"))
	loft(hips,Vector3.ZERO,[Vector4(.066,.175,.137,0),Vector4(.103,.165,.124,0)],dark)
	M.box(hips,Vector3(0,.083,-.13),Vector3(.047,.03,.018),Color("9b9d89"),Vector3.ZERO,.6)
	loft(chest,Vector3(0,.256,0),[Vector4(-.025,.059,.056,0),Vector4(.07,.055,.054,0)],skin)
	var head=joint(chest,"Head",Vector3(0,.36,0));face(head,which,skin,hair)
	if which in FEMALE_ROLES:
		pass # Authored female anatomy shares the animation skeleton.
	# Role-specific soft gear: radio, scout scarf, padded vest, tool roll, satchel, medical bag.
	if which==1:
		# A fitted collar replaces the broad floating scarf below the scout's neck.
		loft(chest,Vector3(0,.225,0),[Vector4(-.012,.070,.061,0),Vector4(.012,.065,.058,0)],Color("71806a"))
	if which==2:oval(chest,Vector3(0,-.015,.16),Vector3(.34,.40,.19),Color("6a715e"))
	if which==3:
		oval(hips,Vector3(.213,-.105,.028),Vector3(.10,.19,.19),Color("987851"))
		for i in range(3):cord(hips,Vector3(.26,-.12,.0+i*.04),Vector3(.26,.07,.0+i*.04),.011,Color("a8aa9b"))
	if which==4:oval(chest,Vector3(-.10,-.1,.167),Vector3(.26,.31,.16),Color("797970"))
	if which==5:
		oval(chest,Vector3(0,-.04,.17),Vector3(.32,.36,.18),Color("bbb8a0"))
		M.box(chest,Vector3(0,.06,-.192),Vector3(.027,.10,.01),Color("c87360"));M.box(chest,Vector3(0,.06,-.197),Vector3(.095,.028,.01),Color("c87360"))
	if which in [0,4]:
		oval(chest,Vector3(.16,.06,.133),Vector3(.09,.16,.085),dark)
		cord(chest,Vector3(.16,.13,.14),Vector3(.16,.29,.14),.004,dark)
	joint(chest,"WeaponSocket",Vector3(.07,-.09,-.07))
	AuthoredHuman.install(root,which,team,skin,shirt,trousers)
	return root
