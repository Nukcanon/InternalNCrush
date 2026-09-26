extends Node3D
class_name WeaponVisual
const M=preload("res://scripts/mesh_factory.gd")
var magazine:Node3D
var action_part:Node3D
var left_hand:Node3D
var right_hand:Node3D
var support_rig:WeaponHand
var firing_rig:WeaponHand
var support_arm:Node3D
var firing_arm:Node3D
var barrel_group:Node3D
var muzzle:Marker3D
var flash:Node3D
var spec={}
var mag_origin=Vector3.ZERO
var action_origin=Vector3.ZERO
var hand_origin=Vector3.ZERO
var trigger_origin=Vector3.ZERO
var trigger_origin_set=false
var reload_round:Node3D
var rocket_grip:HeldGrip
var grip_boxes:Array=[]
var length=.7
var reload_style="rifle"
var reload_round_count=3
var metal=Color("202b33")
var edge=Color("586773")
var light=Color("9baeb6")
var accent=Color("62bcb3")
const LENGTHS={"VECTOR-24":.66,"RAPID-9":.59,"ATLAS":.76,"TRIAD":.68,"SCOUT":.88,"MONOLITH":1.06,"ECHO":.79,"LARK":.7,"KESTREL":.84,"ANCHOR":.78,"BASTION":.9,"PULSE":.83,"TIDAL":.68,"FOLD":.44,"SWIFT":.43,"FLUX":.42,"LINE":.53,"HIVE":.55,"PIPER":.59,"MENDER":.83,"COMET":.95}
func build_pose(w:Dictionary):
	# Identical sockets/reload nodes without GPU geometry, for dedicated hit poses.
	spec=w;name=w.name;reload_style=str(w.reload_style)
	if w.name in ["HIVE","TIDAL"]:reload_style="drum"
	elif w.name in ["RAPID-9","KESTREL","FLUX"]:reload_style="bullpup"
	elif w.name in ["SCOUT","MONOLITH"]:reload_style="bolt"
	elif w.name=="CHIME":reload_style="revolver"
	var pistol=int(w.slot)==1 and w.kind=="gun"
	length=(.4 if w.name=="CHIME" else .32 if w.name=="SPARK" else .3) if pistol else .43 if w.kind=="heal" else .29 if w.kind=="repair" else .30 if w.kind=="remote" else LENGTHS.get(w.name,.65)
	barrel_group=piece("Barrel");magazine=piece("Magazine",Vector3(0,-.09,-.18));action_part=piece("Action",Vector3(0,.027,-.17))
	if pistol:magazine.position=Vector3(0,-.013,-.073) if w.name=="CHIME" else Vector3(0,-.19,.046)
	elif w.kind=="repair":magazine.position=Vector3(0,-.13,-.15)
	elif w.kind!="heal":magazine.position=Vector3(0,-.087,.05 if w.name in ["RAPID-9","KESTREL","FLUX"] else -.17)
	mag_origin=magazine.position;action_origin=action_part.position
	left_hand=piece("LeftHand",Vector3(-.057,-.125,.055) if pistol else Vector3(-.065,-.073,-length*.59));hand_origin=left_hand.position
	right_hand=piece("RightHand",Vector3(.044,-.120,-.15 if w.name in ["RAPID-9","KESTREL","FLUX"] else .035))
	calibrate_grips(false)
func block(parent:Node,pos:Vector3,size:Vector3,color:Color,tilt=0.) -> MeshInstance3D:return M.box(parent,pos,size,color,Vector3(tilt,0,0),.48)
func tube(parent:Node,pos:Vector3,radius:float,depth:float,color:Color) -> MeshInstance3D:return M.cylinder(parent,pos,radius,depth,color,Vector3(PI/2,0,0))
func shell(parent:Node,pos:Vector3,size:Vector3,color:Color) -> MeshInstance3D:
	var rings=[Vector4(-size.z*.5,size.x*.33,size.y*.34,0),Vector4(-size.z*.42,size.x*.49,size.y*.48,0),Vector4(size.z*.30,size.x*.50,size.y*.50,0),Vector4(size.z*.5,size.x*.37,size.y*.39,0)]
	var mesh=HumanModel.loft(parent,pos,rings,color,20);mesh.rotation.x=PI/2;return mesh
func piece(name:String,pos=Vector3.ZERO) -> Node3D:
	var n=Node3D.new();n.name=name;n.position=pos;add_child(n);return n
func rail(z:float,count:int):
	block(self,Vector3(0,.072,z),Vector3(.065,.025,count*.03),metal)
	for i in range(count):block(self,Vector3(0,.087,z+(i-count*.5)*.029),Vector3(.078,.012,.015),edge)
func stock(style:String):
	if style=="wire":
		for x in [-.035,.035]:block(self,Vector3(x,-.005,.078),Vector3(.014,.025,.2),light)
		block(self,Vector3(0,-.03,.172),Vector3(.085,.14,.03),metal)
	elif style=="solid":
		var shoulder=shell(self,Vector3(0,-.038,.082),Vector3(.085,.125,.22),edge);shoulder.rotate_x(-.12)
		block(self,Vector3(0,-.048,.182),Vector3(.095,.17,.032),metal)
	elif style=="wood":
		var shoulder=shell(self,Vector3(0,-.045,.065),Vector3(.083,.12,.23),Color("94714e"));shoulder.rotate_x(-.2)
		block(self,Vector3(0,-.068,.18),Vector3(.09,.15,.036),metal)
	else:
		block(self,Vector3(0,.003,.07),Vector3(.046,.045,.2),metal)
		block(self,Vector3(0,-.038,.14),Vector3(.085,.12,.095),edge,-.14)
func sight(scoped:bool,compact=false):
	if scoped:
		block(self,Vector3(0,.095,-.19),Vector3(.032,.075,.19),metal)
		tube(self,Vector3(0,.143,-.22),.04 if compact else .049,.19 if compact else .31,edge)
		for z in [-.115,-.29]:tube(self,Vector3(0,.143,z),.055,.025,metal)
		tube(self,Vector3(0,.143,-.383 if not compact else -.327),.045,.012,Color("438a9c"))
		M.cylinder(self,Vector3(0,.197,-.21),.024,.034,metal)
	else:
		for x in [-.027,.027]:block(self,Vector3(x,.085,-.09),Vector3(.0035,.025,.014),light)
		block(self,Vector3(0,.076,-length*.82),Vector3(.003,.023,.010),accent)
func magazine_shape(style:String):
	match style:
		"drum":
			tube(magazine,Vector3(0,-.04,0),.105,.095,metal);tube(magazine,Vector3(0,-.04,-.054),.074,.016,edge)
		"box":
			block(magazine,Vector3(0,-.06,0),Vector3(.18,.17,.145),Color("64745e"))
			block(magazine,Vector3(0,-.062,-.078),Vector3(.14,.085,.012),Color("8e9a79"))
		"curve":
			block(magazine,Vector3(0,-.045,0),Vector3(.054,.1,.093),edge,-.13)
			block(magazine,Vector3(0,-.127,.02),Vector3(.056,.09,.091),edge,-.35)
			block(magazine,Vector3(0,-.172,.039),Vector3(.065,.025,.1),metal,-.35)
		"pistol":block(magazine,Vector3(0,-.045,0),Vector3(.06,.078,.077),edge,-.14)
		"tube":tube(magazine,Vector3(0,0,-.1),.025,.3,edge)
		_:
			block(magazine,Vector3(0,-.062,0),Vector3(.055,.175,.085),edge,-.09)
			for y in [-.02,-.06,-.1]:block(magazine,Vector3(.029,y,-.003),Vector3(.006,.006,.069),metal)
			block(magazine,Vector3(0,-.15,.012),Vector3(.067,.023,.094),metal)
static var web_templates={}
func build(w:Dictionary,hands=true,use_cache=true):
	if use_cache and restore_web_model(w,hands):return
	spec=w;name=w.name
	for color in [metal,edge,light]:
		var surface=M.material(color);surface.metallic=.55;surface.roughness=.46
	var idx=int(w.model_index);var role=int(w.role);var pistol=int(w.slot)==1 and w.kind=="gun"
	accent=[Color("72b7a9"),Color("b0c195"),Color("d6b66b"),Color("dc9c59"),Color("969bca"),Color("69c6ac")][role]
	reload_style=str(w.reload_style)
	if w.name in ["HIVE","TIDAL"]:reload_style="drum"
	elif w.name in ["RAPID-9","KESTREL","FLUX"]:reload_style="bullpup"
	elif w.name in ["SCOUT","MONOLITH"]:reload_style="bolt"
	elif w.name=="CHIME":reload_style="revolver"
	barrel_group=piece("Barrel");magazine=piece("Magazine",Vector3(0,-.09,-.18));action_part=piece("Action",Vector3(0,.027,-.17))
	var model=w.name
	if pistol:
		length=.3 if model!="CHIME" else .4
		block(self,Vector3(0,-.022,-.10),Vector3(.078,.085,.25),metal)
		block(action_part,Vector3(0,.024,.026),Vector3(.081,.074,length*.8),edge)
		block(self,Vector3(0,-.13,.025),Vector3(.073,.18,.088),metal,-.19)
		block(self,Vector3(0,-.118,-.066),Vector3(.067,.014,.105),metal)
		block(self,Vector3(0,-.078,-.112),Vector3(.064,.08,.014),metal)
		block(self,Vector3(0,-.083,-.050),Vector3(.012,.046,.016),light,-.2)
		tube(barrel_group,Vector3(0,.022,-length*.7),.021,.14,metal)
		magazine.position=Vector3(0,-.19,.046);magazine_shape("pistol")
		if model=="CHIME":
			for child in magazine.get_children():child.free()
			magazine.position=Vector3(0,-.013,-.073)
			tube(magazine,Vector3.ZERO,.064,.105,Color("84918e"))
			block(self,Vector3(0,.069,-.19),Vector3(.082,.034,.28),edge)
		elif model=="SPARK":block(self,Vector3(0,-.012,-.17),Vector3(.11,.115,.16),edge);length=.32
		elif model=="RIVET":tube(self,Vector3(0,.021,-.32),.045,.1,edge)
		elif model=="TRIO":block(self,Vector3(0,.079,-.12),Vector3(.064,.028,.11),accent)
		elif model=="FEATHER":metal=Color("7b9994");block(self,Vector3(0,.048,-.1),Vector3(.083,.04,.22),metal)
		sight(false)
	elif w.get("rocket",false):
		length=.95
		var launch_tube=tube(self,Vector3(0,.065,-.37),.09,1.04,Color("596d51"));launch_tube.mesh=launch_tube.mesh.duplicate();launch_tube.mesh.cap_top=false;launch_tube.mesh.cap_bottom=false
		var liner=tube(self,Vector3(0,.065,-.37),.087,1.04,Color("303c2b"));liner.mesh=liner.mesh.duplicate();liner.mesh.cap_top=false;liner.mesh.cap_bottom=false;liner.mesh.flip_faces=true
		for z in [-.87,.10]:
			var collar=tube(self,Vector3(0,.065,z),.108,.075,metal);collar.mesh=collar.mesh.duplicate();collar.mesh.cap_top=false;collar.mesh.cap_bottom=false
			var rim=TorusMesh.new();rim.inner_radius=.087;rim.outer_radius=.108;rim.rings=24;rim.ring_segments=8;M.instance(self,rim,Vector3(0,.065,z),edge,Vector3(PI/2,0,0))
		tube(self,Vector3(0,.065,-.912),.084,.007,Color("10191e"))
		block(self,Vector3(0,-.10,.014),Vector3(.075,.20,.09),metal,-.15)
		block(self,Vector3(0,-.11,-.48),Vector3(.072,.18,.09),edge)
		block(self,Vector3(0,-.138,-.065),Vector3(.075,.018,.10),metal)
		block(self,Vector3(0,-.10,-.055),Vector3(.01,.046,.02),light)
		block(self,Vector3(.11,.075,-.22),Vector3(.032,.16,.08),edge)
		block(self,Vector3(.11,.17,-.22),Vector3(.065,.035,.035),light)
		block(self,Vector3(0,-.058,.10),Vector3(.17,.07,.24),Color("344049"))
	elif w.kind=="remote":
		length=.30
		block(self,Vector3(0,-.10,.01),Vector3(.075,.18,.10),metal,-.12)
		block(self,Vector3(0,.0,-.12),Vector3(.18,.09,.30),edge)
		block(self,Vector3(0,.058,-.10),Vector3(.13,.025,.16),accent,-.15)
		M.cylinder(self,Vector3(.08,.125,-.22),.009,.23,metal)
		M.sphere(self,Vector3(.08,.24,-.22),Vector3.ONE*.025,accent)
		M.cylinder(self,Vector3(0,.081,.0),.018,.10,metal)
		M.sphere(self,Vector3(0,.139,0),Vector3(.05,.025,.05),Color("d59048"))
	elif w.kind in ["heal","repair"]:
		length=.43 if w.kind=="heal" else .29
		shell(self,Vector3(0,0,-.12),Vector3(.15,.17,.34),Color("d1dad2"))
		block(self,Vector3(0,-.13,.005),Vector3(.08,.17,.11),metal,-.12)
		for x in [-.086,.086]:tube(self,Vector3(x,.006,-.15),.056,.23,accent)
		block(self,Vector3(0,.096,-.15),Vector3(.085,.025,.14),Color("223a44"));block(self,Vector3(0,.111,-.15),Vector3(.062,.006,.09),accent)
		if w.kind=="heal":
			for x in [-.054,.054]:tube(barrel_group,Vector3(x,.025,-.365),.025,.11,light)
			M.box(self,Vector3(.139,.02,-.12),Vector3(.008,.10,.028),Color.WHITE);M.box(self,Vector3(.140,.02,-.12),Vector3(.008,.028,.10),Color.WHITE)
		else:
			for x in [-.06,.06]:block(barrel_group,Vector3(x,0,-.30),Vector3(.025,.04,.18),light)
			magazine.position=Vector3(0,-.13,-.15);block(magazine,Vector3.ZERO,Vector3(.12,.095,.18),accent)
	else:
		length=LENGTHS.get(model,.65)
		var bullpup=model in ["RAPID-9","KESTREL","FLUX"]
		var receiver_width=.14 if role==2 else .115 if model in ["TIDAL","HIVE"] else .095
		shell(self,Vector3(0,0,-.20),Vector3(receiver_width,.14,.39),metal)
		block(self,Vector3(0,-.037,-.33),Vector3(receiver_width*.83,.1,.21),edge)
		block(self,Vector3(0,-.14,.014 if not bullpup else -.16),Vector3(.064,.17,.09),metal,-.2)
		block(self,Vector3(0,-.104,-.065 if not bullpup else -.24),Vector3(.075,.018,.085),edge)
		stock("wood" if model in ["ATLAS","PULSE"] else "wire" if model in ["SWIFT","LINE","SCOUT"] else "solid" if bullpup or role==2 else "adjustable")
		var handguard=Vector3(receiver_width*.9,.11,length*.3)
		shell(barrel_group,Vector3(0,.006,-length*.60),handguard,Color("ab855d") if model in ["PULSE","MENDER"] else edge)
		tube(barrel_group,Vector3(0,.025,-length*.78),.025 if role!=3 else .033,length*.34,metal)
		tube(barrel_group,Vector3(0,.025,-length*.955),.035 if role!=3 else .041,.06,edge)
		for i in range(4):
			block(barrel_group,Vector3(handguard.x*.52,.018,-length*(.50+i*.045)),Vector3(.005,.027,.018),metal)
		magazine.position=Vector3(0,-.087,.05 if bullpup else -.17)
		magazine_shape("box" if role==2 else "drum" if model in ["HIVE","TIDAL"] else "tube" if model in ["PULSE","MENDER","FOLD"] else "curve" if model in ["ATLAS","PIPER"] else "straight")
		rail(-.17,6 if role!=4 else 4);sight(role==1,model in ["LARK","KESTREL"])
		block(action_part,Vector3(.045,0,0),Vector3(.037,.033,.10),light)
		if model=="MONOLITH":
			block(self,Vector3(0,-.045,-.45),Vector3(.13,.075,.47),Color("798b86"))
			for x in [-.075,.075]:block(self,Vector3(x,-.14,-.62),Vector3(.018,.22,.025),metal,.35)
		elif model=="SCOUT":tube(self,Vector3(.075,.012,-.08),.022,.095,light)
		elif model=="TRIAD":block(self,Vector3(.064,.01,-.17),Vector3(.032,.088,.17),accent)
		elif model=="BASTION":
			block(self,Vector3(0,.11,-.20),Vector3(.035,.11,.16),metal)
			for i in range(5):tube(self,Vector3(-.085-i*.014,-.025,-.19),.008,.09,Color("bdac74"))
		elif model=="FOLD":
			stock("wood");tube(barrel_group,Vector3(.063,.025,-.31),.033,.26,edge)
		elif model=="FLUX":block(self,Vector3(0,.105,-.15),Vector3(.038,.035,.3),light)
		elif model=="HIVE":tube(self,Vector3(0,.105,-.26),.042,.27,accent)
		elif model=="PIPER":
			block(self,Vector3(.053,0,-.2),Vector3(.018,.093,.29),Color("c9d8d0"));tube(self,Vector3(-.08,-.03,-.18),.035,.19,accent)
		block(self,Vector3(receiver_width*.51,.025,-.1),Vector3(.008,.025,.086),accent)
	muzzle=Marker3D.new();muzzle.name="Muzzle";muzzle.position=Vector3(0,.025,-length);barrel_group.add_child(muzzle)
	mag_origin=magazine.position;action_origin=action_part.position
	left_hand=piece("LeftHand",Vector3(-.057,-.125,.055) if pistol else Vector3(-.065,-.073,-length*.59));hand_origin=left_hand.position
	right_hand=piece("RightHand",Vector3(.044,-.120,-.15 if model in ["RAPID-9","KESTREL","FLUX"] else .035))
	add_surface_details(pistol,role)
	M.merge_rig(self)
	for part in [self,barrel_group,magazine,action_part]:
		var geo=part.get_node_or_null("Geometry")
		if geo:geo.material_override=SurfaceFinish.equipment_material()
	calibrate_grips()
	if hands:
		support_rig=WeaponHand.new();left_hand.add_child(support_rig);support_rig.build(true,pistol,role)
		firing_rig=WeaponHand.new();right_hand.add_child(firing_rig);firing_rig.build(false,pistol,role)
		support_arm=WeaponHand.forearm(self,role);firing_arm=WeaponHand.forearm(self,role);update_hands(-1.,0.,10.)
		for mesh in find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash=Node3D.new();flash.name="MuzzleFlash";muzzle.add_child(flash)
	M.cylinder(flash,Vector3(0,0,-.08),.058,.16,Color("ffeac0"),Vector3(PI/2,0,0),.012,5)
	flash.visible=false
	WebMaterials.apply(self)
	if hands:
		for mesh in find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func restore_web_model(w:Dictionary,hands:bool) -> bool:
	var id=""
	for key in Catalog.weapons:
		if Catalog.weapons[key].name==w.name:id=key;break
	var path="res://assets/models/weapon_"+id+".scn"
	if id.is_empty() or not ResourceLoader.exists(path):return false
	if not web_templates.has(id):web_templates[id]=load(path)
	# Reuse the baked receiver/magazine/action, preserving every animation socket.
	build_pose(w)
	for child in get_children():child.free()
	var baked=web_templates[id].instantiate()
	for child in baked.find_children("*","",true,false):child.owner=null
	for child in baked.get_children():baked.remove_child(child);add_child(child)
	baked.free()
	barrel_group=get_node("Barrel");magazine=get_node("Magazine");action_part=get_node("Action")
	left_hand=get_node("LeftHand");right_hand=get_node("RightHand");muzzle=barrel_group.get_node("Muzzle");flash=muzzle.get_node("MuzzleFlash")
	length=-muzzle.position.z;mag_origin=magazine.position;action_origin=action_part.position;hand_origin=left_hand.position
	calibrate_grips()
	if hands:
		var pistol=int(w.slot)==1 and w.kind=="gun";var role=int(w.role)
		support_rig=WeaponHand.new();left_hand.add_child(support_rig);support_rig.build(true,pistol,role)
		firing_rig=WeaponHand.new();right_hand.add_child(firing_rig);firing_rig.build(false,pistol,role)
		support_arm=WeaponHand.forearm(self,role);firing_arm=WeaponHand.forearm(self,role);update_hands(-1.,0.,10.)
	WebMaterials.apply(self)
	if hands:
		for mesh in find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return true
func add_surface_details(pistol:bool,role:int):
	# Tools and launchers have their own complete assemblies: rifle butt pads,
	# sling loops and barrel ornaments otherwise float behind their short housing.
	if spec.kind in ["heal","repair","remote"] or spec.get("rocket",false):return
	var trigger_shift=-.175 if spec.name in ["RAPID-9","KESTREL","FLUX"] else 0.
	var side=.046 if pistol else .073 if role==2 else .054
	for sign_x in [-1,1]:
		for z in [-.065,-.235]:
			M.cylinder(self,Vector3(side*sign_x,.004,z),.009,.008,light,Vector3(0,0,PI/2),-1.,8)
		# Dark inset, machined slide serrations and receiver panel seams.
		block(self,Vector3(side*sign_x,.033,-.18),Vector3(.008,.029,.075),metal.darkened(.35))
		for i in range(5):block(self,Vector3(side*sign_x,.025,-.04-i*.017),Vector3(.005,.045,.006),light.darkened(.1),.15)
	if not pistol:
		for i in range(5):tube(barrel_group,Vector3(0,.025,-length*.84-i*.015),.028,.005,light.darkened(.2))
		block(self,Vector3(.016,-.1,-.078+trigger_shift),Vector3(.012,.052,.021),light,.2)
		block(self,Vector3(0,-.129,-.068+trigger_shift),Vector3(.055,.012,.09),metal)
		for i in range(4):block(self,Vector3(0,-.13+i*.022,.063),Vector3(.066,.009,.008),edge)
	# Receiver controls, trigger guard, inspection markings and machined muzzle.
	var polymer=Color("344049")
	for sign_x in [-1,1]:
		block(self,Vector3(side*sign_x,-.035,-.115),Vector3(.008,.047,.16),polymer)
		for i in range(3):block(self,Vector3(side*sign_x,-.03,-.07-i*.011),Vector3(.009,.004,.005),light)
		M.cylinder(self,Vector3(side*sign_x,-.026,-.015),.013,.013,metal,Vector3(0,0,PI/2),-1,12)
		block(self,Vector3(side*sign_x,-.016,-.028),Vector3(.012,.01,.039),edge,.25)
	block(self,Vector3(side+.009,.019,-.19),Vector3(.013,.036,.089),Color("111b22"))
	block(action_part,Vector3(side+.006,0,-.025),Vector3(.012,.023,.051),light)
	if not pistol:
		for x in [-.030,.030]:block(self,Vector3(x,-.108,-.068+trigger_shift),Vector3(.009,.055,.10),metal,.12)
		block(self,Vector3(0,-.136,-.055+trigger_shift),Vector3(.066,.01,.08),metal)
		block(self,Vector3(0,-.11,-.06+trigger_shift),Vector3(.01,.04,.015),light,-.3)
	tube(barrel_group,Vector3(0,.025,-length-.002),.026 if pistol else .028,.006,Color("10191e"))
	if not pistol:
		var guard_z=-length*.6
		for x in [-.055,.055]:
			for i in range(6):block(barrel_group,Vector3(x,-.005,guard_z+.075-i*.025),Vector3(.006,.024,.017),Color("17232b"))
		for i in range(5):block(self,Vector3(0,-.04+i*.022,.192),Vector3(.081,.009,.016),polymer)
		M.cylinder(self,Vector3(-.052,-.026,.123),.015,.012,light,Vector3(0,0,PI/2),-1,12)
		# A raised hand stop makes the front grip read clearly in first person.
		block(barrel_group,Vector3(0,-.085,guard_z+.02),Vector3(.054,.08,.047),polymer,.12)
	else:
		for i in range(6):block(self,Vector3(0,-.085-i*.017,.071),Vector3(.068,.007,.008),edge)
func calibrate_grips(visible_round=true):
	var pistol=int(spec.slot)==1 and spec.kind=="gun"
	var bullpup=spec.name in ["RAPID-9","KESTREL","FLUX"]
	var grip_z=-.16 if bullpup else .025 if pistol else .005 if spec.kind in ["heal","repair","remote"] else .014
	var width=.14 if int(spec.role)==2 else .115 if spec.name in ["TIDAL","HIVE"] else .095
	right_hand.position=Vector3(.074,-.135,grip_z+.008)
	left_hand.position=Vector3(-.082,-.158,.052) if pistol else Vector3(-width*.35,-.137,-length*.62)
	if spec.kind in ["heal","repair","remote"]:left_hand.position=Vector3(-.11,-.112,-length*.62)
	if spec.get("rocket",false):left_hand.position=Vector3(-.082,-.14,-.48)
	if spec.name=="MONOLITH":left_hand.position=Vector3(-.075,-.155,-.49)
	if spec.name=="FOLD":left_hand.position=Vector3(-.058,-.14,-.25)
	hand_origin=left_hand.position;trigger_origin=right_hand.position;trigger_origin_set=true
	var receiver=AABB(Vector3(-.045,-.065,-.27),Vector3(.09,.14,.30)) if pistol else AABB(Vector3(-width*.5,-.07,-.395),Vector3(width,.145,.39))
	var grip=AABB(Vector3(-.036,-.225,grip_z-.048),Vector3(.072,.17,.096))
	grip_boxes=[receiver,grip]
	if visible_round and spec.kind=="gun" and reload_style in ["shell","break","revolver","rocket"]:
		var previous=get_node_or_null("ReloadRound")
		if previous:remove_child(previous);previous.free()
		reload_round=Node3D.new();reload_round.name="ReloadRound";add_child(reload_round)
		if reload_style=="rocket":
			tube(reload_round,Vector3.ZERO,.06,.36,Color("6e805b"))
			tube(reload_round,Vector3(0,0,.225),.023,.13,Color("45513c"))
			M.cylinder(reload_round,Vector3(0,0,-.23),.06,.10,Color("bdab76"),Vector3(PI/2,0,0),.008,12)
			for x in [-1,1]:block(reload_round,Vector3(x*.066,0,.13),Vector3(.035,.008,.09),edge)
		elif reload_style=="revolver":
			for i in range(6):
				var offset=Vector3(cos(i*TAU/6.)*.035,sin(i*TAU/6.)*.035,0.)
				tube(reload_round,offset,.009,.045,Color("b4a16d"))
		else:
			tube(reload_round,Vector3.ZERO,.012,.07,Color("b4a16d"));tube(reload_round,Vector3(0,0,-.037),.010,.01,Color("714c38"))
		reload_round.hide()
func magazine_contact_box() -> AABB:
	var bounds=AABB(Vector3(-.034,-.17,-.047),Vector3(.068,.18,.105))
	if reload_style=="revolver":bounds=AABB(Vector3(-.066,-.066,-.055),Vector3(.132,.132,.11))
	elif reload_style=="pistol":bounds=AABB(Vector3(-.032,-.087,-.042),Vector3(.064,.09,.085))
	elif reload_style=="drum":bounds=AABB(Vector3(-.108,-.148,-.057),Vector3(.216,.216,.114))
	elif reload_style=="box":bounds=AABB(Vector3(-.092,-.147,-.074),Vector3(.184,.175,.148))
	elif reload_style in ["shell","break"]:bounds=AABB(Vector3(-.027,-.027,-.25),Vector3(.054,.054,.30))
	return magazine.transform*bounds
func update_hands(t:float,recoil:float,shot_age:float):
	if not is_instance_valid(support_rig):return
	var release=sin(clampf(t/.15,0.,1.)*PI)*.75 if t>=0 and t<.15 else sin(clampf((t-.65)/.12,0.,1.)*PI)*.65 if t>=.65 and t<.77 else 0.
	support_rig.pose(release,0.);firing_rig.pose(sin(clampf((t-.70)/.30,0.,1.)*PI)*.55 if t>=.70 and reload_style=="bolt" else 0.,maxf(0.,1.-shot_age/.12))
	var support_elbow=Vector3(-.30,-.28,.12).lerp(Vector3(-.24,-.34,.22),release*.5)
	var firing_elbow=Vector3(.27,-.27,.29)
	if reload_style=="rocket":support_elbow.z-=position.z;firing_elbow.z-=position.z
	var support_wrist=WeaponHand.align_wrist(support_rig,left_hand.position,support_elbow,Vector3(1.,.08,.12) if int(spec.slot)==1 else Vector3(.8,.65,.08))
	var firing_wrist=WeaponHand.align_wrist(firing_rig,right_hand.position,firing_elbow,Vector3(-1.,.1,.15))
	WeaponHand.fit_forearm(support_arm,support_elbow,support_wrist)
	WeaponHand.fit_forearm(firing_arm,firing_elbow,firing_wrist)
	var boxes=grip_boxes+[magazine_contact_box()]
	support_rig.constrain_contacts(left_hand.transform*support_rig.transform,boxes)
	firing_rig.constrain_contacts(right_hand.transform*firing_rig.transform,boxes)
	if reload_style=="rocket":
		var gripping=t>.12 and t<.74 and is_instance_valid(reload_round)
		support_rig.visible=not gripping
		if gripping and not is_instance_valid(rocket_grip):
			rocket_grip=HeldGrip.new();add_child(rocket_grip);rocket_grip.build(int(spec.role),.024);rocket_grip.rotation.x=PI/2;rocket_grip.scale.x=-1.
		if is_instance_valid(rocket_grip):
			rocket_grip.visible=gripping
			if gripping:
				rocket_grip.position=reload_round.position+Vector3(0,0,.225);rocket_grip.position.z=maxf(.24,rocket_grip.position.z)
				WeaponHand.fit_forearm(support_arm,Vector3(-.30,-.28,.12-position.z),rocket_grip.transform*rocket_grip.wrist)
func animate_reload(t:float,recoil:float,shot_age=10.):
	if not trigger_origin_set:trigger_origin=right_hand.position;trigger_origin_set=true
	right_hand.position=trigger_origin
	magazine.position=mag_origin;magazine.rotation=Vector3.ZERO;action_part.position=action_origin;action_part.rotation=Vector3.ZERO;left_hand.position=hand_origin;left_hand.rotation=Vector3.ZERO;barrel_group.rotation=Vector3.ZERO
	if is_instance_valid(flash):flash.visible=shot_age<.045;flash.rotation.z=shot_age*100
	if is_instance_valid(reload_round):reload_round.hide()
	if t<0:
		if reload_style=="rocket":position.z=0.
		action_part.position.z+=recoil*.045
		if spec.name in ["PULSE","MENDER"]:
			var pump=maxf(0,sin(clampf((shot_age-.12)/.45,0,1)*PI))*.075;left_hand.position.z+=pump
		if spec.name in ["SCOUT","MONOLITH"]:action_part.position.z+=maxf(0,sin(clampf((shot_age-.15)/.55,0,1)*PI))*.08
		update_hands(t,recoil,shot_age)
		return
	if reload_style=="rocket":position.z=-.40*smoothstep(.03,.20,t)*(1.-smoothstep(.76,.96,t))
	var u=clampf(t/.70,0,1);var contact=smoothstep(.02,.18,u)*(1.-smoothstep(.78,.98,u));var remove=smoothstep(.15,.4,u)*(1.-smoothstep(.52,.76,u));var latch=sin(clampf((u-.78)/.22,0,1)*PI)
	match reload_style:
		"rocket":
			# Rear-load through the open breech, within the support arm reach.
			var take=smoothstep(.05,.25,t);var insert=smoothstep(.32,.72,t);var release=smoothstep(.74,.94,t)
			var round_pos=Vector3(-.23,-.24,.20).lerp(Vector3(0,.065,.35),take).lerp(Vector3(0,.065,-.10),insert)
			left_hand.position=hand_origin.lerp(round_pos+Vector3(-.065,-.015,.30),take)
			if t>=.72:left_hand.position=Vector3(-.25,-.13,.26).lerp(hand_origin,smoothstep(.82,.98,t))
			if is_instance_valid(reload_round):reload_round.position=round_pos;reload_round.visible=t>.08 and t<.74
		"revolver":
			var opened=smoothstep(.0,.18,t)*(1.-smoothstep(.76,.94,t))
			magazine.position=mag_origin+Vector3(-.10,0.,0.)*opened
			var seat=smoothstep(.32,.60,t)
			var pickup=smoothstep(.15,.30,t)*(1.-smoothstep(.65,.80,t))
			var rounds=magazine.position+Vector3(0,0,.14*(1.-seat))
			left_hand.position=hand_origin.lerp(rounds+Vector3(-.082,-.024,.025),pickup)
			if is_instance_valid(reload_round):reload_round.position=rounds;reload_round.visible=t>.20 and t<.60
		"shell":
			var cycle=fposmod(clampf((t-.08)/.72,0.,.999)*maxi(1,reload_round_count),1.)
			var reach=smoothstep(.12,.55,cycle);var retreat=smoothstep(.68,1.,cycle)
			var port=Vector3(-.055,-.125,-.19)
			left_hand.position=hand_origin.lerp(port,reach*(1.-retreat))
			if is_instance_valid(reload_round):
				reload_round.visible=t>.08 and t<.80 and cycle<.72
				reload_round.position=left_hand.position+Vector3(.044,.021,-.045)
			if t>.82:
				var pump=sin(clampf((t-.82)/.16,0.,1.)*PI)
				action_part.position=action_origin+Vector3(0,0,.09)*pump
				left_hand.position=hand_origin+Vector3(0,0,.09)*pump
		"break":
			var opened=smoothstep(.0,.2,t)*(1.-smoothstep(.75,.95,t))
			barrel_group.rotation.x=-.50*opened
			var port=barrel_group.transform*Vector3(-.02,.025,-.17)
			var reach=smoothstep(.25,.50,t)*(1.-smoothstep(.64,.78,t))
			left_hand.position=hand_origin.lerp(port+Vector3(-.09,-.04,.03),reach)
			if is_instance_valid(reload_round):
				reload_round.visible=t>.2 and t<.64
				reload_round.position=left_hand.position+Vector3(.06,.025,-.03)
				reload_round.rotation=barrel_group.rotation
		"box":
			action_part.rotation.x=-sin(u*PI)*1.3;magazine.position+=Vector3(-.21,-.11,0)*remove;left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.14,-.06,.025),contact);left_hand.position.y+=latch*.12
		"drum":
			magazine.position+=Vector3(-.12,-.22,.04)*remove;magazine.rotation.z=remove*.38
			left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.15,-.065,.015),smoothstep(.04,.2,u)*(1.-smoothstep(.77,.94,u)));action_part.position.z+=latch*.07
		"bullpup":
			magazine.position+=Vector3(-.07,-.25,.035)*remove;magazine.rotation.z=-remove*.16
			left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.083,-.07,.012),smoothstep(.02,.17,u)*(1.-smoothstep(.76,.94,u)));action_part.position.z+=latch*.075
		"bolt":
			action_part.position.z+=smoothstep(.02,.12,u)*(1.-smoothstep(.82,.95,u))*.11;action_part.rotation.z=-sin(u*PI)*.6
			magazine.position+=Vector3(-.04,-.20,.015)*remove;left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.083,-.08,0),contact)
		"pistol":
			magazine.position+=Vector3(0,-.22,.04)*remove;left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.085,-.055,.015),contact);action_part.position.z+=latch*.065
		_:
			magazine.position+=Vector3(-.06,-.25,.06)*remove;magazine.rotation.x=-remove*.18;left_hand.position=hand_origin.lerp(magazine.transform*Vector3(-.084,-.085,0),contact);left_hand.position+=Vector3(-.04,.15,0)*latch;action_part.position.z+=latch*.07
	if t>=.70 and spec.kind=="gun" and reload_style not in ["shell","break","box","revolver","rocket"]:
		# Final 30%: reach charging control, pull, release, then return to grip.
		# Actor handedness mirrors receiver and both arms together.
		var v=clampf((t-.70)/.30,0.,1.)
		var reach=smoothstep(0.,.20,v)*(1.-smoothstep(.78,1.,v))
		var pull=smoothstep(.22,.48,v)*(1.-smoothstep(.52,.74,v))
		action_part.position=action_origin+Vector3(0,0,.085 if reload_style=="pistol" else .11)*pull
		action_part.rotation=Vector3(0,0,-.65*sin(v*PI) if reload_style=="bolt" else 0.)
		var grip=action_part.position+Vector3(-.095,.04,-.018)
		if reload_style=="bolt":grip=action_part.position+Vector3(.075,.025,-.018)
		if reload_style=="bolt":right_hand.position=trigger_origin.lerp(grip,reach)
		else:left_hand.position=hand_origin.lerp(grip,reach)
	# Swing around the receiver only during transfers; maintain contact while holding.
	var phase=clampf((t-.70)/.30,0.,1.) if t>=.70 else u
	var travel=sin(clampf(phase/.20,0.,1.)*PI)+sin(clampf((phase-.78)/.22,0.,1.)*PI)
	if reload_style!="rocket":left_hand.position.x-=.09*travel
	if reload_style=="pistol":left_hand.position.y-=.04*travel
	update_hands(t,recoil,shot_age)
