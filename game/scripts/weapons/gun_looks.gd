class_name GunLooks
extends RefCounted
## Per-weapon look over the baked Toon Shooter bases: base, scale, palette and
## simple cartoon attachments. Gameplay data stays in weapons.json.
const STEEL=Color("5d6674")
const DARK=Color("2e333d")
const LIGHT=Color("b8c2cc")
const WOOD=Color("b0763c")
const MEDIC_WHITE=Color("e9eef2")
const MEDIC_GREEN=Color("3fcf8e")
const REMOTE_GRIP_TILT=-.35 # TETHER grips rake back like pistol grips
static func palette(main:Color,dark:Color,light:Color,wood:Color=WOOD) -> Dictionary:
	return {"Grey":main,"Grey2":light,"LightGrey":light,"DarkGrey":dark,"Black":dark.darkened(.25),"Wood":wood,"DarkWood":wood.darkened(.3),"Red":Color("d9483b"),"DarkRed":Color("8e2a24"),"Green":Color("5a8a3a"),"DarkGreen":Color("355228")}
# Looks keyed by weapon name (weapons.json "name").
static var LOOKS={
	"VECTOR-24":{"base":"AK","scale":1.058,"palette":palette(Color("64707e"),DARK,Color("9fb0bf"),Color("3a4552")),"attach":["dot"]},
	"RAPID-9":{"base":"AK","scale":1.012,"palette":palette(Color("56606c"),DARK,Color("f2b233"),DARK),"attach":["dot"]},
	# ATLAS aims as a semi-sniper without optics (weapons.json "semi_scope").
	"ATLAS":{"base":"AK","scale":1.116,"palette":palette(Color("7c6f5c"),DARK,Color("c9b08a"))},
	"TRIAD":{"base":"AK","scale":1.093,"palette":palette(Color("3f4c5f"),DARK,Color("e36b4f"),DARK),"attach":["dot"]},
	"SCOUT":{"base":"Sniper_2","scale":1.097,"palette":palette(Color("6b7d5a"),DARK,LIGHT,Color("8a6a44"))},
	"MONOLITH":{"base":"Sniper","scale":1.,"palette":palette(Color("3e4652"),DARK,Color("8fa0b2"))},
	"ECHO":{"base":"Sniper_2","scale":1.058,"palette":palette(Color("56627a"),DARK,Color("9fd0ff"),DARK)},
	"LARK":{"base":"AK","scale":1.209,"palette":palette(Color("8b8f99"),DARK,LIGHT,Color("6d4a2e")),"attach":["scope"]},
	"KESTREL":{"base":"Sniper_2","scale":1.029,"palette":palette(Color("7a6a55"),DARK,Color("d7c29e"))},
	"ANCHOR":{"base":"AK","scale":1.14,"palette":palette(Color("4a5446"),DARK,Color("8d9a78"),DARK),"attach":["box","bipod"]},
	"BASTION":{"base":"AK","scale":1.186,"palette":palette(Color("3c3f47"),DARK,Color("a5a9b3"),DARK),"attach":["box","bipod","dot"]},
	"PULSE":{"base":"Shotgun","scale":.816,"palette":palette(STEEL,DARK,LIGHT)},
	"TIDAL":{"base":"Shotgun","scale":.755,"palette":palette(Color("4f6b86"),DARK,Color("9cc6e8"),DARK),"attach":["shotmag"]},
	"FOLD":{"base":"ShortCannon","scale":1.139,"palette":palette(Color("6b5f58"),DARK,LIGHT)},
	"SWIFT":{"base":"SMG","scale":1.103,"palette":palette(STEEL,DARK,LIGHT)},
	"FLUX":{"base":"SMG","scale":1.034,"palette":palette(Color("5b5374"),DARK,Color("b7a6f2"))},
	"LINE":{"base":"SMG","scale":1.172,"palette":palette(Color("4e5a52"),DARK,Color("a8c49a")),"attach":["dot"]},
	"HIVE":{"base":"SMG","scale":1.069,"palette":palette(Color("6e5a2f"),DARK,Color("f0c040")),"attach":["drum"]},
	"PIPER":{"base":"SMG","scale":1.138,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a")),"attach":["dot"]},
	"SIDE":{"base":"Pistol","scale":1.,"palette":palette(STEEL,DARK,LIGHT,DARK)},
	"CHIME":{"base":"Revolver","scale":1.,"palette":palette(Color("8a8f98"),DARK,LIGHT)},
	"SPARK":{"base":"Pistol","scale":1.05,"palette":palette(Color("5a6270"),DARK,Color("7fd0ff"),DARK)},
	"RIVET":{"base":"Revolver_Small","scale":1.,"palette":palette(Color("d9a93a"),DARK,Color("f3d27a"),DARK)},
	"TRIO":{"base":"Pistol","scale":1.02,"palette":palette(Color("6a4f63"),DARK,Color("f08fb8"),DARK)},
	"FEATHER":{"base":"Pistol","scale":.98,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a"))},
	"DUET":{"base":"Revolver_Small","scale":.95,"palette":palette(Color("7a808a"),DARK,Color("ffcf6b"),DARK)},
	"MENDER":{"base":"Shotgun","scale":.786,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a"))},
	# 1.4.1: launchers are built in code (LauncherModels) so the tubes show the rockets they hold.
	"COMET":{"launcher":"comet","scale":.9,"palette":{},"shoulder":true},
	"QUAD":{"launcher":"quad","scale":1.,"palette":{}},
	"LINK":{"tool":"link","palette":{}},
	"FIX · 원격 수리 도구":{"tool":"fix","palette":{}},
	"TETHER · 포탑 원격 조종기":{"tool":"tether","palette":{}},
	# 1.4.4: the ARC is built in code again, after the 1.3 futuristic laser
	# rifle (power cell under the receiver, side capacitors, coil emitter).
	"ARC":{"tool":"arc","palette":{}}}
static func look(w:Dictionary) -> Dictionary:
	return LOOKS.get(str(w.get("name","")),{"base":"Pistol" if int(w.get("slot",0))==1 else "AK","scale":1.,"palette":palette(STEEL,DARK,LIGHT)})
static func hold_kind(w:Dictionary) -> String:
	if look(w).has("tool"):return "item" if look(w).tool=="tether" else "rifle" if look(w).tool in ["link","arc"] else "pistol"
	var b=str(look(w).get("base",""))
	if b in ["Pistol","Revolver","Revolver_Small"]:return "pistol"
	if bool(look(w).get("shoulder",false)):return "shoulder"
	return "rifle"
# Small rounded attachments in the cartoon style, placed relative to markers.
static func attach(gun:GunModel,l:Dictionary):
	var accent:Color=l.get("palette",{}).get("Grey2",LIGHT)
	var dark:Color=l.get("palette",{}).get("DarkGrey",DARK)
	var top=gun.muzzle.position.y*gun.base.scale.y
	var handles:Dictionary=GunModel.handles(str(l.get("base","")))
	# Attachments hang from the front of the gun ("front"), not from wherever
	# the support hand holds (the AK base's hand is on the magazine).
	var grip_z=gun.right_grip.position.z*gun.base.scale.z;var left_z=Vector3(handles.get("front",gun.left_grip.position)).z*gun.base.scale.z
	if handles.has("handguard"):
		# 1.4.2 forend over the bare barrel (the support hand's place).
		var h:Array=handles.handguard;var s:Vector3=gun.base.scale;var main:Color=l.get("palette",{}).get("Grey",STEEL)
		var guard=Node3D.new();guard.name="Handguard";gun.add_child(guard)
		var centre=Vector3(0,(h[2]+h[3])*.5,(h[0]+h[1])*.5)*s;var size=Vector3(h[4]*2.,h[3]-h[2],absf(h[1]-h[0]))*s
		MeshFactory.box(guard,centre,size,main,Vector3.ZERO,.45)
		for side in [-1.,1.]:
			for k in range(3):MeshFactory.box(guard,centre+Vector3(side*size.x*.5,.004,(k-1)*size.z*.26),Vector3(.004,size.y*.34,size.z*.14),dark,Vector3.ZERO,.3)
		MeshFactory.box(guard,centre+Vector3(0,-size.y*.5,0),Vector3(size.x*.7,.006,size.z*.9),dark,Vector3.ZERO,.3)
		MeshFactory.merge_children(guard)
		for mesh in guard.get_children():
			if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for kind in l.get("attach",[]):
		var part=Node3D.new();part.name="Attach_"+kind;gun.add_child(part)
		match kind:
			"dot":
				MeshFactory.box(part,Vector3(0,top+.055,grip_z-.08),Vector3(.035,.04,.07),dark,Vector3.ZERO,.5)
				MeshFactory.box(part,Vector3(0,top+.07,grip_z-.115),Vector3(.022,.022,.006),accent,Vector3.ZERO,.5)
			"scope":
				MeshFactory.cylinder(part,Vector3(0,top+.075,grip_z-.09),.026,.22,dark,Vector3(PI/2,0,0),-1.,12)
				MeshFactory.cylinder(part,Vector3(0,top+.075,grip_z-.205),.032,.03,accent,Vector3(PI/2,0,0),-1.,12)
				MeshFactory.box(part,Vector3(0,top+.035,grip_z-.09),Vector3(.02,.04,.08),dark,Vector3.ZERO,.4)
				ScopeVisual.lens_disc(part,Vector3(0,top+.075,grip_z+.0205),Vector3(0,0,1),.022,"OcularGlass")
				ScopeVisual.lens_disc(part,Vector3(0,top+.075,grip_z-.2205),Vector3(0,0,-1),.028,"ObjectiveGlass")
			"box":
				MeshFactory.box(part,Vector3(0,top-.13,left_z+.12),Vector3(.075,.11,.1),accent.darkened(.25),Vector3.ZERO,.35)
			"drum":
				MeshFactory.cylinder(part,Vector3(0,top-.13,left_z+.05),.06,.06,accent.darkened(.2),Vector3(0,0,PI/2),-1.,14)
			"bipod":
				for side in [-1,1]:MeshFactory.box(part,Vector3(side*.03,top-.1,left_z-.12),Vector3(.014,.16,.014),dark,Vector3(0,0,side*.35),.3)
			"shotmag":
				# 1.4.2 TIDAL: a box magazine ahead of the trigger guard (base units,
				# under the scaled base so it reloads like the other magazines).
				part.queue_free()
				var mag=Node3D.new();mag.name="Magazine";gun.base.add_child(mag);mag.position=Vector3(0,-.08,-.515)
				MeshFactory.box(mag,Vector3(0,-.085,0),Vector3(.046,.17,.085),dark,Vector3(-.12,0,0),.3)
				MeshFactory.box(mag,Vector3(0,-.172,.01),Vector3(.052,.02,.09),accent.darkened(.2),Vector3(-.12,0,0),.3)
				MeshFactory.box(mag,Vector3(0,-.06,-.044),Vector3(.036,.09,.004),accent.darkened(.35),Vector3(-.12,0,0),.3)
				MeshFactory.merge_children(mag)
				for mesh in mag.get_children():
					if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				gun.magazine=mag;gun.mag_rest=mag.transform
				continue
			"coils":
				for i in range(3):
					var ring=MeshFactory.cylinder(part,Vector3(0,top,left_z-.11-i*.07),.032,.022,Color("c79bff"),Vector3(PI/2,0,0),-1.,12)
					ring.set_meta("glow",true)
		MeshFactory.merge_children(part)
		for mesh in part.get_children():
			if mesh is MeshInstance3D and not mesh.has_meta("scope_lens"):mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
# Support tools have no Toon Shooter source: small rounded cartoon builds with
# the same markers as the baked guns (origin at the grip, muzzle -Z).
static func build_tool(kind:String) -> Node3D:
	var root=Node3D.new();root.name=kind
	var body=Node3D.new();body.name="Body";root.add_child(body)
	var m=MeshFactory
	var muzzle=Vector3.ZERO;var right=Vector3(0,-.02,.02);var left=Vector3(-.03,-.05,.03)
	match kind:
		"link":
			# 1.4.2: two-handed medical beam gun after the 1.3.5 model: white
			# body with green canisters on both sides, a top display and cross,
			# twin emitter prongs, a pistol grip at the rear and a rubber
			# support rail under the front for the other hand.
			var grey=Color("55606a")
			# Rear receiver as narrow as a rifle's (the thumb wraps it), the wide
			# canister section ahead of it, a vertical foregrip underneath.
			m.box(body,Vector3(0,.02,-.215),Vector3(.05,.1,.11),MEDIC_WHITE,Vector3.ZERO,.35)
			m.box(body,Vector3(0,.018,-.163),Vector3(.042,.08,.016),grey,Vector3.ZERO,.4)
			m.box(body,Vector3(0,.015,-.375),Vector3(.085,.11,.23),MEDIC_WHITE,Vector3.ZERO,.35)
			for side in [-1,1]:
				m.cylinder(body,Vector3(side*.05,.0,-.375),.03,.19,MEDIC_GREEN,Vector3(PI/2,0,0),-1.,14)
				for z in [-.28,-.47]:m.cylinder(body,Vector3(side*.05,.0,z),.033,.016,grey,Vector3(PI/2,0,0),-1.,14)
			m.box(body,Vector3(0,.076,-.37),Vector3(.05,.014,.13),DARK,Vector3.ZERO,.3)
			m.box(body,Vector3(0,.084,-.37),Vector3(.036,.004,.095),Color("7fffd4"),Vector3.ZERO,.2)
			m.box(body,Vector3(0,.074,-.215),Vector3(.012,.008,.04),MEDIC_GREEN,Vector3.ZERO,.3)
			m.box(body,Vector3(0,.074,-.215),Vector3(.04,.008,.012),MEDIC_GREEN,Vector3.ZERO,.3)
			m.cylinder(body,Vector3(0,.015,-.515),.042,.045,grey,Vector3(PI/2,0,0),-1.,16)
			m.cylinder(body,Vector3(0,.015,-.542),.025,.016,MEDIC_GREEN,Vector3(PI/2,0,0),-1.,14)
			for side in [-1,1]:m.cylinder(body,Vector3(side*.028,.015,-.575),.01,.09,Color("b1bec3"),Vector3(PI/2,0,0),-1.,10)
			m.box(body,Vector3(0,-.095,-.42),Vector3(.034,.1,.04),grey,Vector3(.15,0,0),.5)
			m.box(body,Vector3(0,-.085,-.215),Vector3(.042,.11,.048),grey,Vector3(-.25,0,0),.5)
			m.box(body,Vector3(0,-.056,-.258),Vector3(.01,.03,.009),DARK,Vector3(.3,0,0),.3)
			m.box(body,Vector3(0,-.074,-.255),Vector3(.012,.006,.056),grey,Vector3.ZERO,.3)
			muzzle=Vector3(0,.015,-.6);right=Vector3(0,-.085,-.215);left=Vector3(0,-.095,-.42)
		"arc":
			# 1.4.4 ARC after the 1.3 model: a long violet receiver with a stock,
			# a dark rail and sight block on top, lilac capacitor tubes along both
			# sides, a coil emitter ahead of the handguard and a big power cell
			# under the receiver (the magazine: the reload swaps the cell).
			var main=Color("4a3f6b");var deep=Color("241d38");var lilac=Color("b98cff");var glow=Color("c79bff")
			m.box(body,Vector3(0,.03,-.20),Vector3(.07,.11,.44),main,Vector3.ZERO,.35)
			m.box(body,Vector3(0,.0,.12),Vector3(.06,.10,.22),main,Vector3(.06,0,0),.4)
			m.box(body,Vector3(0,0,.235),Vector3(.062,.12,.03),deep,Vector3.ZERO,.3)
			m.box(body,Vector3(0,.095,-.20),Vector3(.036,.02,.30),deep,Vector3.ZERO,.3)
			m.box(body,Vector3(0,.12,-.14),Vector3(.05,.04,.11),deep,Vector3.ZERO,.35)
			m.box(body,Vector3(0,.128,-.14),Vector3(.034,.006,.08),lilac,Vector3.ZERO,.2)
			m.cylinder(body,Vector3(0,.14,-.25),.012,.05,glow,Vector3(PI/2,0,0),-1.,10)
			for side in [-1,1]:
				m.cylinder(body,Vector3(side*.058,.02,-.24),.026,.24,lilac,Vector3(PI/2,0,0),-1.,14)
				for z in [-.14,-.34]:m.cylinder(body,Vector3(side*.058,.02,z),.03,.02,deep,Vector3(PI/2,0,0),-1.,14)
			# Pistol grip (leaning back), trigger guard, handguard and barrel.
			m.box(body,Vector3(0,-.085,-.05),Vector3(.04,.11,.046),deep,Vector3(-.25,0,0),.5)
			m.box(body,Vector3(0,-.045,-.095),Vector3(.01,.03,.01),deep,Vector3(.3,0,0),.3)
			m.box(body,Vector3(0,-.065,-.095),Vector3(.014,.006,.06),deep,Vector3.ZERO,.3)
			m.box(body,Vector3(0,-.02,-.47),Vector3(.062,.05,.16),main,Vector3.ZERO,.4)
			for side in [-1.,1.]:
				for k in range(3):m.box(body,Vector3(side*.031,-.02,-.42-k*.04),Vector3(.004,.02,.02),deep,Vector3.ZERO,.3)
			m.cylinder(body,Vector3(0,.03,-.56),.024,.34,deep,Vector3(PI/2,0,0),-1.,14)
			for i in range(3):
				var ring=m.cylinder(body,Vector3(0,.03,-.60-i*.05),.04,.022,glow,Vector3(PI/2,0,0),-1.,14)
				ring.set_meta("glow",true)
			m.cylinder(body,Vector3(0,.03,-.735),.03,.03,deep,Vector3(PI/2,0,0),-1.,14)
			m.cylinder(body,Vector3(0,.03,-.752),.018,.008,glow,Vector3(PI/2,0,0),-1.,12)
			# Power cell: a fat accent block with dark bands and a charge strip.
			var cell=Node3D.new();cell.name="Magazine";root.add_child(cell);cell.position=Vector3(0,-.05,-.24)
			m.box(cell,Vector3(0,-.055,0),Vector3(.09,.11,.17),lilac,Vector3.ZERO,.4)
			for z in [-.06,.06]:m.box(cell,Vector3(0,-.055,z),Vector3(.094,.112,.02),deep,Vector3.ZERO,.3)
			m.box(cell,Vector3(-.047,-.05,0),Vector3(.004,.06,.03),glow,Vector3.ZERO,.2)
			m.box(cell,Vector3(0,-.113,0),Vector3(.07,.008,.14),deep,Vector3.ZERO,.3)
			MeshFactory.merge_children(cell)
			# Authored butt-at-origin like the baked rifles (the third-person frame
			# puts the origin at the shoulder): the whole gun sits 25 cm forward.
			body.position.z=-.25;cell.position.z-=.25
			muzzle=Vector3(0,.03,-1.01);right=Vector3(0,-.085,-.30);left=Vector3(0,-.02,-.72)
		"fix":
			m.box(body,Vector3(0,.04,-.07),Vector3(.075,.085,.18),Color("f0a000"),Vector3.ZERO,.55)
			m.box(body,Vector3(0,-.04,0),Vector3(.045,.11,.05),DARK,Vector3(-.25,0,0),.5)
			m.cylinder(body,Vector3(0,.04,-.19),.022,.08,STEEL,Vector3(PI/2,0,0),-1.,10)
			m.box(body,Vector3(0,.1,-.04),Vector3(.05,.04,.09),Color("3a4552"),Vector3.ZERO,.5)
			m.box(body,Vector3(0,.125,-.04),Vector3(.03,.012,.05),Color("7fe0ff"),Vector3.ZERO,.3)
			m.box(body,Vector3(0,-.012,-.045),Vector3(.01,.026,.009),DARK,Vector3(.3,0,0),.3)
			muzzle=Vector3(0,.04,-.23)
		_:
			# Two-handed remote: rounded pad, screen and antenna.
			m.box(body,Vector3(0,0,-.1),Vector3(.2,.03,.12),Color("3f4c5f"),Vector3(.5,0,0),.6)
			m.box(body,Vector3(0,.018,-.1),Vector3(.12,.006,.07),Color("7fe0ff"),Vector3(.5,0,0),.3)
			m.cylinder(body,Vector3(.07,.06,-.13),.006,.1,DARK,Vector3.ZERO,-1.,8)
			m.sphere(body,Vector3(.07,.11,-.13),Vector3(.02,.02,.02),Color("ff983e"))
			# Game-pad grips under both ends, leaning back toward the player.
			for side in [-1,1]:m.box(body,Vector3(side*.085,-.07,-.04),Vector3(.044,.11,.042),Color("35404f"),Vector3(REMOTE_GRIP_TILT,0,0),.8)
			right=Vector3(.085,-.07,-.04);left=Vector3(-.085,-.07,-.04);muzzle=Vector3(0,.02,-.17)
	MeshFactory.merge_children(body)
	for marker in [["Muzzle",muzzle],["RightGrip",right],["LeftGrip",left]]:
		var node=Marker3D.new();node.name=marker[0];node.position=marker[1];root.add_child(node)
	if kind=="link":
		# Rifle hold: pistol grip (leaning .25), trigger ahead of its top, and a
		# fist round the vertical foregrip; eye just over the display.
		var grip:Marker3D=root.get_node("RightGrip");grip.rotation.x=-.25
		root.get_node("LeftGrip").rotation.x=.15
		root.set_meta("grip_shapes",{"R":{"half":Vector3(.021,.055,.024),"round":.012,"trigger":Vector3(0,-.054,-.258)},
			"L":{"half":Vector3(.017,.05,.02),"round":.012}})
		root.set_meta("grip_styles",{"R":"pistol","L":"pistol"})
		var eye=Marker3D.new();eye.name="AimPoint";eye.position=Vector3(0,.13,-.22);root.add_child(eye)
	elif kind=="arc":
		# Rifle hold: pistol grip (leaning .25), trigger ahead of its top, the
		# support hand under the handguard; the eye over the top rail's sight.
		var grip:Marker3D=root.get_node("RightGrip");grip.rotation.x=-.25
		root.set_meta("grip_shapes",{"R":{"half":Vector3(.02,.055,.023),"round":.012,"trigger":Vector3(0,-.045,-.345)},
			"L":{"half":Vector3(.031,.025,.08),"round":.02}})
		root.set_meta("grip_styles",{"R":"pistol","L":"support"})
		var eye=Marker3D.new();eye.name="AimPoint";eye.position=Vector3(0,.14,-.40);root.add_child(eye)
	elif kind=="fix":
		# Pistol grip (leaning .25) with the trigger just ahead of its top.
		var grip:Marker3D=root.get_node("RightGrip");grip.position=Vector3(0,-.04,0);grip.rotation.x=-.25
		root.set_meta("grip_shapes",{"R":{"half":Vector3(.0225,.055,.025),"round":.012,"trigger":Vector3(0,-.01,-.045)}})
	else:
		# Remote: held like a game pad. Each hand makes a fist around one of
		# the grips under the ends (palm on its outer side, fingers round the
		# front, thumb up on the pad) with the forearms coming from behind.
		for grip in [root.get_node("RightGrip"),root.get_node("LeftGrip")]:grip.rotation=Vector3(REMOTE_GRIP_TILT,0,0)
		var end={"half":Vector3(.022,.055,.021),"round":.016}
		root.set_meta("grip_shapes",{"R":end,"L":end.duplicate()})
		root.set_meta("grip_styles",{"R":"pistol","L":"pistol"})
	return root