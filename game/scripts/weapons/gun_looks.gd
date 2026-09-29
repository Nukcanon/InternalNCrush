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
static func palette(main:Color,dark:Color,light:Color,wood:Color=WOOD) -> Dictionary:
	return {"Grey":main,"Grey2":light,"LightGrey":light,"DarkGrey":dark,"Black":dark.darkened(.25),"Wood":wood,"DarkWood":wood.darkened(.3),"Red":Color("d9483b"),"DarkRed":Color("8e2a24"),"Green":Color("5a8a3a"),"DarkGreen":Color("355228")}
# Looks keyed by weapon name (weapons.json "name").
static var LOOKS={
	"VECTOR-24":{"base":"AK","scale":.9,"palette":palette(Color("64707e"),DARK,Color("9fb0bf"),Color("3a4552")),"attach":["dot"]},
	"RAPID-9":{"base":"SMG","scale":1.12,"palette":palette(Color("56606c"),DARK,Color("f2b233"),DARK),"attach":["dot"]},
	"ATLAS":{"base":"AK","scale":.98,"palette":palette(Color("7c6f5c"),DARK,Color("c9b08a")),"attach":["scope"]},
	"TRIAD":{"base":"AK","scale":.86,"palette":palette(Color("3f4c5f"),DARK,Color("e36b4f"),DARK),"attach":["dot"]},
	"SCOUT":{"base":"Sniper_2","scale":.95,"palette":palette(Color("6b7d5a"),DARK,LIGHT,Color("8a6a44"))},
	"MONOLITH":{"base":"Sniper","scale":1.,"palette":palette(Color("3e4652"),DARK,Color("8fa0b2"))},
	"ECHO":{"base":"Sniper_2","scale":.86,"palette":palette(Color("56627a"),DARK,Color("9fd0ff"),DARK)},
	"LARK":{"base":"AK","scale":.92,"palette":palette(Color("8b8f99"),DARK,LIGHT,Color("6d4a2e")),"attach":["scope"]},
	"KESTREL":{"base":"Sniper_2","scale":.9,"palette":palette(Color("7a6a55"),DARK,Color("d7c29e"))},
	"ANCHOR":{"base":"AK","scale":1.02,"palette":palette(Color("4a5446"),DARK,Color("8d9a78"),DARK),"attach":["box","bipod"]},
	"BASTION":{"base":"AK","scale":1.12,"palette":palette(Color("3c3f47"),DARK,Color("a5a9b3"),DARK),"attach":["box","bipod","dot"]},
	"PULSE":{"base":"Shotgun","scale":.95,"palette":palette(STEEL,DARK,LIGHT)},
	"TIDAL":{"base":"Shotgun","scale":.82,"palette":palette(Color("4f6b86"),DARK,Color("9cc6e8"),DARK)},
	"FOLD":{"base":"ShortCannon","scale":.85,"palette":palette(Color("6b5f58"),DARK,LIGHT)},
	"SWIFT":{"base":"SMG","scale":.9,"palette":palette(STEEL,DARK,LIGHT)},
	"FLUX":{"base":"SMG","scale":.88,"palette":palette(Color("5b5374"),DARK,Color("b7a6f2"))},
	"LINE":{"base":"SMG","scale":1.,"palette":palette(Color("4e5a52"),DARK,Color("a8c49a")),"attach":["dot"]},
	"HIVE":{"base":"SMG","scale":1.02,"palette":palette(Color("6e5a2f"),DARK,Color("f0c040")),"attach":["drum"]},
	"PIPER":{"base":"SMG","scale":1.04,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a")),"attach":["dot"]},
	"SIDE":{"base":"Pistol","scale":1.,"palette":palette(STEEL,DARK,LIGHT,DARK)},
	"CHIME":{"base":"Revolver","scale":1.,"palette":palette(Color("8a8f98"),DARK,LIGHT)},
	"SPARK":{"base":"Pistol","scale":1.05,"palette":palette(Color("5a6270"),DARK,Color("7fd0ff"),DARK)},
	"RIVET":{"base":"Revolver_Small","scale":1.,"palette":palette(Color("d9a93a"),DARK,Color("f3d27a"),DARK)},
	"TRIO":{"base":"Pistol","scale":1.02,"palette":palette(Color("6a4f63"),DARK,Color("f08fb8"),DARK)},
	"FEATHER":{"base":"Pistol","scale":.98,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a"))},
	"DUET":{"base":"Revolver_Small","scale":.95,"palette":palette(Color("7a808a"),DARK,Color("ffcf6b"),DARK)},
	"MENDER":{"base":"Shotgun","scale":.88,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a"))},
	# 1.4.1: launchers are built in code (LauncherModels) so the tubes show the rockets they hold.
	"COMET":{"launcher":"comet","scale":.9,"palette":{},"shoulder":true},
	"QUAD":{"launcher":"quad","scale":1.,"palette":{}},
	"LINK":{"tool":"link","palette":{}},
	"FIX · 원격 수리 도구":{"tool":"fix","palette":{}},
	"TETHER · 포탑 원격 조종기":{"tool":"tether","palette":{}},
	"ARC":{"base":"Sniper_2","scale":.94,"palette":palette(Color("4a3f6b"),Color("241d38"),Color("b98cff"),Color("241d38")),"attach":["coils"]}}
static func look(w:Dictionary) -> Dictionary:
	return LOOKS.get(str(w.get("name","")),{"base":"Pistol" if int(w.get("slot",0))==1 else "AK","scale":1.,"palette":palette(STEEL,DARK,LIGHT)})
static func hold_kind(w:Dictionary) -> String:
	if look(w).has("tool"):return "item" if look(w).tool=="tether" else "pistol"
	var b=str(look(w).get("base",""))
	if b in ["Pistol","Revolver","Revolver_Small"]:return "pistol"
	if bool(look(w).get("shoulder",false)):return "shoulder"
	return "rifle"
# Small rounded attachments in the cartoon style, placed relative to markers.
static func attach(gun:GunModel,l:Dictionary):
	var accent:Color=l.get("palette",{}).get("Grey2",LIGHT)
	var dark:Color=l.get("palette",{}).get("DarkGrey",DARK)
	var top=gun.muzzle.position.y*gun.base.scale.y
	var grip_z=gun.right_grip.position.z*gun.base.scale.z;var left_z=gun.left_grip.position.z*gun.base.scale.z
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
			"box":
				MeshFactory.box(part,Vector3(0,top-.13,left_z+.12),Vector3(.075,.11,.1),accent.darkened(.25),Vector3.ZERO,.35)
			"drum":
				MeshFactory.cylinder(part,Vector3(0,top-.13,left_z+.05),.06,.06,accent.darkened(.2),Vector3(0,0,PI/2),-1.,14)
			"bipod":
				for side in [-1,1]:MeshFactory.box(part,Vector3(side*.03,top-.1,left_z-.12),Vector3(.014,.16,.014),dark,Vector3(0,0,side*.35),.3)
			"coils":
				for i in range(3):
					var ring=MeshFactory.cylinder(part,Vector3(0,top,left_z-.07-i*.07),.032,.022,Color("c79bff"),Vector3(PI/2,0,0),-1.,12)
					ring.set_meta("glow",true)
		MeshFactory.merge_children(part)
		for mesh in part.get_children():
			if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
# Support tools have no Toon Shooter source: small rounded cartoon builds with
# the same markers as the baked guns (origin at the grip, muzzle -Z).
static func build_tool(kind:String) -> Node3D:
	var root=Node3D.new();root.name=kind
	var body=Node3D.new();body.name="Body";root.add_child(body)
	var m=MeshFactory
	var muzzle=Vector3.ZERO;var right=Vector3(0,-.02,.02);var left=Vector3(-.03,-.05,.03)
	match kind:
		"link":
			m.box(body,Vector3(0,.04,-.08),Vector3(.07,.08,.2),MEDIC_WHITE,Vector3.ZERO,.6)
			m.box(body,Vector3(0,-.04,0),Vector3(.045,.11,.05),Color("55606a"),Vector3(-.25,0,0),.5)
			m.cylinder(body,Vector3(0,.04,-.2),.045,.05,MEDIC_GREEN,Vector3(PI/2,0,0),-1.,14)
			m.box(body,Vector3(0,.09,-.08),Vector3(.018,.018,.06),MEDIC_GREEN,Vector3.ZERO,.3)
			m.box(body,Vector3(0,.09,-.08),Vector3(.06,.018,.018),MEDIC_GREEN,Vector3.ZERO,.3)
			muzzle=Vector3(0,.04,-.23)
		"fix":
			m.box(body,Vector3(0,.04,-.07),Vector3(.075,.085,.18),Color("f0a000"),Vector3.ZERO,.55)
			m.box(body,Vector3(0,-.04,0),Vector3(.045,.11,.05),DARK,Vector3(-.25,0,0),.5)
			m.cylinder(body,Vector3(0,.04,-.19),.022,.08,STEEL,Vector3(PI/2,0,0),-1.,10)
			m.box(body,Vector3(0,.1,-.04),Vector3(.05,.04,.09),Color("3a4552"),Vector3.ZERO,.5)
			m.box(body,Vector3(0,.125,-.04),Vector3(.03,.012,.05),Color("7fe0ff"),Vector3.ZERO,.3)
			muzzle=Vector3(0,.04,-.23)
		_:
			# Two-handed remote: rounded pad, screen and antenna.
			m.box(body,Vector3(0,0,-.1),Vector3(.2,.03,.12),Color("3f4c5f"),Vector3(.5,0,0),.6)
			m.box(body,Vector3(0,.018,-.1),Vector3(.12,.006,.07),Color("7fe0ff"),Vector3(.5,0,0),.3)
			m.cylinder(body,Vector3(.07,.06,-.13),.006,.1,DARK,Vector3.ZERO,-1.,8)
			m.sphere(body,Vector3(.07,.11,-.13),Vector3(.02,.02,.02),Color("ff983e"))
			right=Vector3(.1,-.02,-.08);left=Vector3(-.1,-.02,-.08);muzzle=Vector3(0,.02,-.17)
	MeshFactory.merge_children(body)
	for marker in [["Muzzle",muzzle],["RightGrip",right],["LeftGrip",left]]:
		var node=Marker3D.new();node.name=marker[0];node.position=marker[1];root.add_child(node)
	return root