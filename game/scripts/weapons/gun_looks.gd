class_name GunLooks
extends RefCounted
## Per-weapon look over the baked Toon Shooter bases: base, scale, palette and
## simple cartoon attachments. Gameplay data stays in weapons.json.
const STEEL=Color("5d6674")
const DARK=Color("2e333d")
const LIGHT=Color("b8c2cc")
const WOOD=Color("b0763c")
const MEDIC_WHITE=Color("e9eef2")
const PISTOL_GRIP_AT=Vector3(0,-.15,-.30) # MENDER's pistol grip centre (Shotgun base units, behind the guard)
const MEDIC_GREEN=Color("3fcf8e")
const REMOTE_GRIP_TILT=-.35 # TETHER grips rake back like pistol grips
static func palette(main:Color,dark:Color,light:Color,wood:Color=WOOD) -> Dictionary:
	return {"Grey":main,"Grey2":light,"LightGrey":light,"DarkGrey":dark,"Black":dark.darkened(.25),"Wood":wood,"DarkWood":wood.darkened(.3),"Red":Color("d9483b"),"DarkRed":Color("8e2a24"),"Green":Color("5a8a3a"),"DarkGreen":Color("355228")}
# Looks keyed by weapon name (weapons.json "name").
static var LOOKS={
	"VECTOR-24":{"base":"AK","scale":1.058,"palette":palette(Color("64707e"),DARK,Color("9fb0bf"),Color("3a4552")),"attach":["iron_flip","rail","quadrail","brake"]},
	"RAPID-9":{"base":"AK","scale":1.012,"palette":palette(Color("56606c"),DARK,Color("f2b233"),DARK),"attach":["iron_ak","ribbed","roundguard","suppressor"]},
	# ATLAS aims as a semi-sniper without optics (weapons.json "semi_scope").
	"ATLAS":{"base":"AK","scale":1.116,"palette":palette(Color("7c6f5c"),DARK,Color("c9b08a")),"attach":["iron_ghost","panels","shroud","longbarrel"]},
	"TRIAD":{"base":"AK","scale":1.093,"palette":palette(Color("3f4c5f"),DARK,Color("e36b4f"),DARK),"attach":["iron","slope","shortguard","flashhider"]},
	"SCOUT":{"base":"Sniper_2","scale":1.097,"palette":palette(Color("6b7d5a"),DARK,LIGHT,Color("8a6a44"))},
	"MONOLITH":{"base":"Sniper","scale":1.,"palette":palette(Color("3e4652"),DARK,Color("8fa0b2"))},
	"ECHO":{"base":"Sniper_2","scale":1.058,"palette":palette(Color("56627a"),DARK,Color("9fd0ff"),DARK),"attach":["sunshade","panels","suppressor"]},
	"LARK":{"base":"AK","scale":1.209,"palette":palette(Color("8b8f99"),DARK,LIGHT,Color("6d4a2e")),"attach":["scope"]},
	"KESTREL":{"base":"Sniper_2","scale":1.029,"palette":palette(Color("7a6a55"),DARK,Color("d7c29e")),"attach":["scopecaps","brake"]},
	"ANCHOR":{"base":"AK","scale":1.14,"palette":palette(Color("4a5446"),DARK,Color("8d9a78"),DARK),"attach":["feedcover","jacket","brake"]}, # (1.5.0: the loose ammo box in front of the magazine is gone - it hung in the air)
	"BASTION":{"base":"AK","scale":1.186,"palette":palette(Color("3c3f47"),DARK,Color("a5a9b3"),DARK),"attach":["carry","panels","fins","flashhider"]},
	"PULSE":{"base":"Shotgun","scale":.816,"palette":palette(STEEL,DARK,LIGHT)},
	"TIDAL":{"base":"Shotgun","scale":.755,"palette":palette(Color("4f6b86"),DARK,Color("9cc6e8"),DARK),"attach":["shotmag"]},
	"FOLD":{"base":"ShortCannon","scale":1.139,"palette":palette(Color("6b5f58"),DARK,LIGHT)},
	"SWIFT":{"base":"SMG","scale":1.103,"palette":palette(STEEL,DARK,LIGHT),"attach":["iron_flip","rail","brake"]},
	"FLUX":{"base":"SMG","scale":1.034,"palette":palette(Color("5b5374"),DARK,Color("b7a6f2")),"attach":["iron","panels","suppressor"]},
	"LINE":{"base":"SMG","scale":1.172,"palette":palette(Color("4e5a52"),DARK,Color("a8c49a")),"attach":["iron_ghost","ribbed","roundguard","fins"]},
	"HIVE":{"base":"SMG","scale":1.069,"palette":palette(Color("6e5a2f"),DARK,Color("f0c040")),"attach":["iron_ak","drum","flashhider"]},
	"PIPER":{"base":"SMG","scale":1.138,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a")),"attach":["iron_dots"]},
	"SIDE":{"base":"Pistol","scale":1.,"palette":palette(STEEL,DARK,LIGHT,DARK)},
	"CHIME":{"base":"Revolver","scale":1.,"palette":palette(Color("8a8f98"),DARK,LIGHT)},
	"SPARK":{"base":"Pistol","scale":1.05,"palette":palette(Color("5a6270"),DARK,Color("7fd0ff"),DARK),"attach":["comp","extmag"]}, # (1.5.0: it looked just like SIDE - a compensator and an extended magazine for the machine pistol)
	"RIVET":{"base":"Revolver_Small","scale":1.,"palette":palette(Color("d9a93a"),DARK,Color("f3d27a"),DARK),"attach":["rivet"]},
	"TRIO":{"base":"Pistol","scale":1.02,"palette":palette(Color("6a4f63"),DARK,Color("f08fb8"),DARK),"attach":["trio"]},
	"FEATHER":{"base":"Pistol","scale":.98,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a")),"attach":["feather"]},
	"DUET":{"base":"Revolver_Small","scale":.95,"palette":palette(Color("7a808a"),DARK,Color("ffcf6b"),DARK)},
	# 1.4.5: remodelled with a pistol grip (the medic's hand went through the
	# wide stock wrist) and its own hand set-up on that grip.
	"MENDER":{"base":"Shotgun","scale":.786,"palette":palette(MEDIC_WHITE,Color("55606a"),MEDIC_GREEN,Color("55606a")),"attach":["pistolgrip"],
		"hand":{"right":PISTOL_GRIP_AT+Vector3(0,.01,.004),"tilt":.28,"grip":Vector3(.018,.058,.025),"round":.012}},
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
const MUZZLE_GAIN=.012 # 1.5.0: how far a muzzle device reaches past the bare muzzle
# 1.5.2: a pistol's slide-mounted parts go on the slide (it locks back and runs forward); the
# node is placed so its children use gun space like every attachment.
static func slide_part(gun:GunModel,part:Node3D) -> Node3D:
	if not is_instance_valid(gun.slide):return part
	var on=Node3D.new();on.name=part.name+"OnSlide";gun.slide.add_child(on)
	on.transform=GunModel.relative(gun.slide,gun).affine_inverse();part.set_meta("on_slide",on)
	return on
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
	# 1.5.1: receiver anchors (gun space) - its top, its front end and half width
	var base_name=str(l.get("base",""));var sz=gun.base.scale.z
	var rt=top+float({"AK":.08,"SMG":.05,"Sniper_2":.07}.get(base_name,.05))*gun.base.scale.y
	var front_z=grip_z+float({"AK":-.39,"SMG":-.35}.get(base_name,-.35))*sz
	var half_w=float({"AK":.034,"SMG":.024,"Sniper_2":.034}.get(base_name,.03))*gun.base.scale.x
	# a gun given its own sight loses the base's sight block (base units, tools/_probe_profile)
	const OWN_SIGHTS=["holo","tubedot","acog","iron","iron_ak","iron_flip","iron_ghost","iron_dots","carry","feedcover"]
	const BASE_SIGHT={"AK":AABB(Vector3(-.036,.074,-.62),Vector3(.072,.056,.08)),"SMG":AABB(Vector3(-.026,.054,-.38),Vector3(.052,.022,.05))}
	if BASE_SIGHT.has(base_name) and l.get("attach",[]).any(func(k):return k in OWN_SIGHTS):
		var old_sight=gun.split_part(BASE_SIGHT[base_name],"BaseSight")
		if old_sight:old_sight.visible=false
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
				# 1.5.0 (the user: a part not joined to the gun): the drum is the magazine's
				# own lower end (a drum magazine), on the magazine node so it reloads with it
				if is_instance_valid(gun.magazine):
					part.queue_free()
					var box=AABB()
					for mm in gun.magazine.find_children("*","MeshInstance3D",true,false)+([gun.magazine] if gun.magazine is MeshInstance3D else []):
						if mm.mesh:box=GunModel.relative(mm,gun.magazine)*mm.get_aabb() if box.size==Vector3.ZERO else box.merge(GunModel.relative(mm,gun.magazine)*mm.get_aabb())
					# built in gun space (the magazine node is scaled) and carried by the magazine
					var to_gun=GunModel.relative(gun.magazine,gun);box=to_gun*box
					var drum=Node3D.new();drum.name="Drum";gun.magazine.add_child(drum);drum.transform=to_gun.affine_inverse()
					var r=clampf(box.size.z*.5,.035,.055);var at=Vector3(box.get_center().x,box.position.y+r*.9,box.get_center().z)
					MeshFactory.cylinder(drum,at,r,maxf(box.size.x*1.5,.045),dark.lightened(.08),Vector3(0,0,PI/2),-1.,16)
					for s in [-1.,1.]:MeshFactory.cylinder(drum,at+Vector3(s*maxf(box.size.x*.75,.0225),0,0),r*.45,.006,accent.darkened(.2),Vector3(0,0,PI/2),-1.,12)
					MeshFactory.merge_children(drum)
					for mesh in drum.get_children():
						if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					continue
			"bipod":
				# 1.4.5: the gadget's bipod (GearModels.bipod), folded forward under the barrel
				GearModels.bipod(part,Vector3(0,top+.014,left_z+.04),1.,dark,dark.lightened(.25),accent,true)
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
			"pistolgrip":
				# 1.4.5 MENDER: a pistol grip behind the trigger guard (base units,
				# under the scaled base), so the medic's smaller hand holds a grip
				# rather than closing round the wide stock wrist.
				part.queue_free()
				var g=Node3D.new();g.name="PistolGrip";gun.base.add_child(g)
				MeshFactory.box(g,PISTOL_GRIP_AT,Vector3(.036,.13,.05),dark,Vector3(-.28,0,0),.45)
				MeshFactory.box(g,PISTOL_GRIP_AT+Vector3(0,-.066,.018),Vector3(.04,.012,.056),accent.darkened(.2),Vector3(-.28,0,0),.3)
				MeshFactory.merge_children(g)
				for mesh in g.get_children():
					if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				continue
			"comp":
				# a ported compensator on the muzzle (machine pistol)
				var m:Vector3=gun.muzzle.position*gun.base.scale
				MeshFactory.box(part,m+Vector3(0,-.002,-.028),Vector3(.036,.03,.058),dark,Vector3.ZERO,.35)
				for k in range(3):MeshFactory.box(part,m+Vector3(0,.0135,-.012-k*.017),Vector3(.02,.004,.008),accent,Vector3.ZERO,.2)
				gun.muzzle.position.z-=.056/maxf(.01,gun.base.scale.z)
			"extmag":
				# an extended magazine: its base reaches well below the grip (on the magazine node, so it reloads with it)
				if is_instance_valid(gun.magazine):
					part.queue_free()
					var box=AABB()
					for mm in gun.magazine.find_children("*","MeshInstance3D",true,false)+([gun.magazine] if gun.magazine is MeshInstance3D else []):
						if mm.mesh:box=GunModel.relative(mm,gun.magazine)*mm.get_aabb() if box.size==Vector3.ZERO else box.merge(GunModel.relative(mm,gun.magazine)*mm.get_aabb())
					var ext=Node3D.new();ext.name="Extension";gun.magazine.add_child(ext)
					var bottom=Vector3(box.get_center().x,box.position.y,box.get_center().z)
					MeshFactory.box(ext,bottom+Vector3(0,-.028,0),Vector3(box.size.x*.92,.06,box.size.z*.92),dark,Vector3.ZERO,.3)
					MeshFactory.box(ext,bottom+Vector3(0,-.062,.002),Vector3(box.size.x*1.15,.012,box.size.z*1.15),accent,Vector3.ZERO,.3)
					MeshFactory.merge_children(ext)
					for mesh in ext.get_children():
						if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(gun.outlined,.25);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					continue
			# 1.5.0 (the user: guns of a role differed only by colour) - muzzle and barrel
			# parts, each joined to the barrel. Muzzle devices sit back over the barrel and reach only
			# MUZZLE_GAIN past it (the gun lengths keep their class/damage order, test_v142).
			"suppressor":
				var m:Vector3=gun.muzzle.position*gun.base.scale+Vector3(0,0,.17-MUZZLE_GAIN)
				MeshFactory.cylinder(part,m+Vector3(0,0,-.085),.024,.17,dark,Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(part,m+Vector3(0,0,-.006),.026,.012,accent.darkened(.3),Vector3(PI/2,0,0),-1.,14)
				gun.muzzle.position.z-=MUZZLE_GAIN/maxf(.01,gun.base.scale.z)
			"brake":
				var m:Vector3=gun.muzzle.position*gun.base.scale+Vector3(0,0,.068-MUZZLE_GAIN)
				MeshFactory.box(part,m+Vector3(0,0,-.034),Vector3(.034,.03,.068),dark,Vector3.ZERO,.3)
				for k in range(2):
					for s in [-1.,1.]:MeshFactory.box(part,m+Vector3(s*.0172,0,-.02-k*.026),Vector3(.004,.018,.012),accent.darkened(.35),Vector3.ZERO,.2)
				gun.muzzle.position.z-=MUZZLE_GAIN/maxf(.01,gun.base.scale.z)
			"flashhider":
				var m:Vector3=gun.muzzle.position*gun.base.scale+Vector3(0,0,.064-MUZZLE_GAIN)
				MeshFactory.cylinder(part,m+Vector3(0,0,-.03),.017,.06,dark,Vector3(PI/2,0,0),-1.,6)
				for k in range(3):
					var a=TAU*k/3.;MeshFactory.box(part,m+Vector3(cos(a)*.016,sin(a)*.016,-.05),Vector3(.006,.006,.03),accent.darkened(.3),Vector3.ZERO,.2)
				gun.muzzle.position.z-=MUZZLE_GAIN/maxf(.01,gun.base.scale.z)
			"longbarrel":
				var m:Vector3=gun.muzzle.position*gun.base.scale+Vector3(0,0,.14-MUZZLE_GAIN)
				MeshFactory.cylinder(part,m+Vector3(0,0,-.07),.011,.14,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,m+Vector3(0,.022,-.12),Vector3(.008,.03,.012),dark,Vector3.ZERO,.2) # front sight post
				MeshFactory.cylinder(part,m+Vector3(0,0,-.13),.015,.02,accent.darkened(.25),Vector3(PI/2,0,0),-1.,10)
				gun.muzzle.position.z-=MUZZLE_GAIN/maxf(.01,gun.base.scale.z)
			"jacket":
				# a big perforated cooling jacket round the barrel (machine gun)
				var m:Vector3=gun.muzzle.position*gun.base.scale
				MeshFactory.cylinder(part,m+Vector3(0,0,.2),.04,.3,dark.lightened(.1),Vector3(PI/2,0,0),-1.,16)
				MeshFactory.cylinder(part,m+Vector3(0,0,.045),.044,.016,accent.darkened(.25),Vector3(PI/2,0,0),-1.,16)
				for k in range(5):
					for s in [-1.,1.]:MeshFactory.box(part,m+Vector3(s*.039,0,.09+k*.052),Vector3(.006,.016,.026),dark.darkened(.45),Vector3.ZERO,.2)
					MeshFactory.box(part,m+Vector3(0,.039,.09+k*.052),Vector3(.016,.006,.026),dark.darkened(.45),Vector3.ZERO,.2)
			"fins":
				# heat-sink rings round the barrel ahead of the handguard
				var m:Vector3=gun.muzzle.position*gun.base.scale
				for k in range(5):MeshFactory.cylinder(part,m+Vector3(0,0,.2+k*.028),.026,.008,accent.darkened(.2),Vector3(PI/2,0,0),-1.,12)
			"shroud":
				# a perforated tube round the barrel
				var m:Vector3=gun.muzzle.position*gun.base.scale
				MeshFactory.cylinder(part,m+Vector3(0,0,.2),.027,.26,dark.lightened(.12),Vector3(PI/2,0,0),-1.,12)
				for k in range(5):
					for s in [-1.,1.]:MeshFactory.box(part,m+Vector3(s*.027,0,.1+k*.05),Vector3(.004,.012,.022),dark.darkened(.4),Vector3.ZERO,.2)
			"shortguard":
				# a short ribbed handguard box over the barrel
				var m:Vector3=gun.muzzle.position*gun.base.scale
				MeshFactory.box(part,m+Vector3(0,.004,.26),Vector3(.06,.06,.2),dark.lightened(.1),Vector3.ZERO,.4)
				for k in range(5):MeshFactory.box(part,m+Vector3(0,.036,.18+k*.04),Vector3(.064,.006,.014),accent.darkened(.25),Vector3.ZERO,.2)
			# 1.5.1 (the user: guns of a role still looked alike - only the barrel differed):
			# sights, receiver covers and handguards. The trigger, grip, stock and magazine
			# stay as they are (the hands are fitted to them). A sight sets the aim point.
			"holo":
				var z=grip_z-.11*sz
				MeshFactory.box(part,Vector3(0,rt+.008,z),Vector3(.034,.016,.08),dark,Vector3.ZERO,.4)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.019,rt+.036,z-.004),Vector3(.006,.042,.05),dark,Vector3.ZERO,.3)
				MeshFactory.box(part,Vector3(0,rt+.058,z-.004),Vector3(.044,.006,.05),dark,Vector3.ZERO,.3)
				MeshFactory.box(part,Vector3(.024,rt+.014,z+.022),Vector3(.01,.012,.026),accent,Vector3.ZERO,.3)
				gun.set_meta("sight_aim",Vector3(0,rt+.034,z))
			"tubedot":
				var z=grip_z-.10*sz
				MeshFactory.box(part,Vector3(0,rt+.01,z),Vector3(.026,.02,.05),dark,Vector3.ZERO,.4)
				MeshFactory.cylinder(part,Vector3(0,rt+.04,z),.021,.1,dark,Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(part,Vector3(0,rt+.04,z-.052),.024,.012,accent.darkened(.2),Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(part,Vector3(.024,rt+.04,z),.008,.014,dark,Vector3(0,0,PI/2),-1.,10)
				gun.set_meta("sight_aim",Vector3(0,rt+.04,z))
			"acog":
				var z=grip_z-.10*sz
				MeshFactory.box(part,Vector3(0,rt+.012,z),Vector3(.03,.024,.07),dark,Vector3.ZERO,.4)
				MeshFactory.box(part,Vector3(0,rt+.042,z),Vector3(.042,.036,.07),dark.lightened(.06),Vector3.ZERO,.5)
				MeshFactory.cylinder(part,Vector3(0,rt+.044,z-.055),.026,.045,dark,Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(part,Vector3(0,rt+.044,z+.045),.017,.03,dark,Vector3(PI/2,0,0),-1.,12)
				MeshFactory.box(part,Vector3(0,rt+.064,z-.01),Vector3(.006,.008,.05),accent,Vector3.ZERO,.2)
				ScopeVisual.lens_disc(part,Vector3(0,rt+.044,z+.0605),Vector3(0,0,1),.015,"OcularGlass")
				ScopeVisual.lens_disc(part,Vector3(0,rt+.044,z-.0785),Vector3(0,0,-1),.023,"ObjectiveGlass")
				gun.set_meta("sight_aim",Vector3(0,rt+.044,z))
			"iron":
				# a rear aperture over the grip and a front post with guards on the barrel
				var zr=grip_z+.01*sz;var zf=front_z-.06*sz
				MeshFactory.box(part,Vector3(0,rt+.01,zr),Vector3(.03,.02,.03),dark,Vector3.ZERO,.3)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.011,rt+.032,zr),Vector3(.007,.026,.012),dark,Vector3.ZERO,.2)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.02,.03,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+rt+.03)*.5,zf),Vector3(.012,rt+.03-top,.016),dark,Vector3.ZERO,.2)
				MeshFactory.box(part,Vector3(0,rt+.036,zf),Vector3(.004,.014,.004),accent,Vector3.ZERO,.1)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.013,rt+.034,zf),Vector3(.004,.024,.012),dark,Vector3.ZERO,.2)
				gun.set_meta("sight_aim",Vector3(0,rt+.032,zr))
			"carry":
				# a carry handle over the receiver with its own rear sight, and a tall front post
				var z0=grip_z+.02*sz;var z1=grip_z-.17*sz;var h=rt+.055;var zf=front_z-.06*sz
				for z in [z0,z1]:MeshFactory.box(part,Vector3(0,(rt+h)*.5,z),Vector3(.022,h-rt,.02),dark,Vector3.ZERO,.3)
				MeshFactory.box(part,Vector3(0,h,(z0+z1)*.5),Vector3(.026,.014,z0-z1+.02),dark,Vector3.ZERO,.4)
				MeshFactory.box(part,Vector3(0,h+.016,z0),Vector3(.02,.018,.012),dark,Vector3.ZERO,.2)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.022,.03,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+h+.02)*.5,zf),Vector3(.012,h+.02-top,.016),dark,Vector3.ZERO,.2)
				gun.set_meta("sight_aim",Vector3(0,h+.018,z0))
			"feedcover":
				# a machine gun's hinged feed cover on the receiver, its rear sight on top
				var z=grip_z-.20*sz;var zf=front_z-.06*sz
				MeshFactory.box(part,Vector3(0,rt+.018,z),Vector3(.086,.04,.2*sz),dark.lightened(.08),Vector3.ZERO,.45)
				MeshFactory.cylinder(part,Vector3(0,rt+.01,z-.105*sz),.012,.09,dark,Vector3(0,0,PI/2),-1.,10)
				MeshFactory.box(part,Vector3(0,rt+.03,z+.105*sz),Vector3(.03,.018,.016),accent.darkened(.2),Vector3.ZERO,.3)
				for k in range(4):MeshFactory.box(part,Vector3(0,rt+.039,z-.06*sz+k*.04*sz),Vector3(.07,.004,.012),dark.darkened(.3),Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,rt+.052,z+.08*sz),Vector3(.022,.026,.012),dark,Vector3.ZERO,.2)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.022,.03,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+rt+.07)*.5,zf),Vector3(.012,rt+.07-top,.016),dark,Vector3.ZERO,.2)
				gun.set_meta("sight_aim",Vector3(0,rt+.062,z+.08*sz))
			"rail":
				# an accessory rail along the receiver top, ahead of the sight
				var z0=grip_z-.17*sz;var z1=front_z+.01*sz;var length=z0-z1
				MeshFactory.box(part,Vector3(0,rt+.005,(z0+z1)*.5),Vector3(.024,.01,length),dark,Vector3.ZERO,.2)
				for k in range(int(length/.022)):MeshFactory.box(part,Vector3(0,rt+.012,z0-.011-k*.022),Vector3(.028,.006,.01),accent.darkened(.3),Vector3.ZERO,.1)
			"ribbed":
				# a ribbed dust cover over the front of the receiver
				var z0=grip_z-.17*sz;var z1=front_z+.01*sz;var length=z0-z1
				MeshFactory.box(part,Vector3(0,rt+.004,(z0+z1)*.5),Vector3(half_w*1.9,.014,length),dark.lightened(.1),Vector3.ZERO,.5)
				for k in range(int(length/.03)):MeshFactory.box(part,Vector3(0,rt+.012,z0-.015-k*.03),Vector3(half_w*2.,.008,.009),dark.darkened(.3),Vector3.ZERO,.1)
			"panels":
				# vented side plates on the receiver (above the magazine, clear of the hands)
				var z=(grip_z+front_z)*.5-.03*sz;var length=(grip_z-front_z)*.55
				var side=float({"AK":.05,"SMG":.035}.get(base_name,.04))*gun.base.scale.x
				for sx in [-1.,1.]:
					MeshFactory.box(part,Vector3(sx*(side+.003),rt-.035,z),Vector3(.006,.04,length),accent.darkened(.15),Vector3.ZERO,.4)
					for k in range(3):MeshFactory.box(part,Vector3(sx*(side+.0065),rt-.035,z-length*.3+k*length*.3),Vector3(.003,.02,.03),dark.darkened(.3),Vector3.ZERO,.1)
			"slope":
				# an angled cover over the front of the receiver
				var main:Color=l.get("palette",{}).get("Grey",STEEL)
				MeshFactory.box(part,Vector3(0,rt-.006,front_z+.075*sz),Vector3(half_w*2.05,.034,.15*sz),main.darkened(.1),Vector3(.2,0,0),.5)
				MeshFactory.box(part,Vector3(0,rt+.012,front_z+.12*sz),Vector3(half_w*1.4,.006,.05),accent.darkened(.2),Vector3(.2,0,0),.2)
			"quadrail":
				# a square railed handguard round the barrel, ahead of the receiver
				var z=front_z-.11*sz
				MeshFactory.box(part,Vector3(0,top+.004,z),Vector3(.056,.056,.22*sz),dark.lightened(.08),Vector3.ZERO,.4)
				for r in [Vector3(0,.031,0),Vector3(0,-.023,0),Vector3(.031,.004,0),Vector3(-.031,.004,0)]:
					var size=Vector3(.016,.008,.2*sz) if r.x==0. else Vector3(.008,.016,.2*sz)
					MeshFactory.box(part,Vector3(0,top,z)+r,size,dark,Vector3.ZERO,.1)
			"roundguard":
				# a slim round handguard with long slots
				var z=front_z-.11*sz
				MeshFactory.cylinder(part,Vector3(0,top+.004,z),.031,.22*sz,dark.lightened(.1),Vector3(PI/2,0,0),-1.,14)
				for k in range(3):
					for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.03,top+.004,z-.06*sz+k*.06*sz),Vector3(.004,.01,.04),dark.darkened(.4),Vector3.ZERO,.1)
			"sunshade":
				# sniper scope: a long sun shade on the objective and large turrets
				# (Sniper_2 scope, base units: axis y .12, objective front z -.603, ocular z -.307)
				var y=.12*gun.base.scale.y;var zo=-.603*sz;var zm=-.47*sz
				MeshFactory.cylinder(part,Vector3(0,y,zo-.05),.048*sz,.1,dark,Vector3(PI/2,0,0),-1.,16)
				MeshFactory.cylinder(part,Vector3(0,y,zo-.1),.05*sz,.012,accent.darkened(.2),Vector3(PI/2,0,0),-1.,16)
				MeshFactory.cylinder(part,Vector3(0,y+.058*sz,zm),.02,.034,accent.darkened(.2),Vector3.ZERO,-1.,12)
				MeshFactory.cylinder(part,Vector3(.058*sz,y,zm),.02,.034,accent.darkened(.2),Vector3(0,0,PI/2),-1.,12)
			"scopecaps":
				# sniper scope: flip-up lens caps, open
				var y=.12*gun.base.scale.y;var zo=-.603*sz;var zr=-.307*sz
				MeshFactory.cylinder(part,Vector3(0,y,zo-.008),.05*sz,.016,dark,Vector3(PI/2,0,0),-1.,16)
				# (1.5.2, the user: the caps are round) open discs on a little hinge above each lens
				MeshFactory.cylinder(part,Vector3(0,y+.085*sz,zo-.03),.046*sz,.008,accent.darkened(.1),Vector3(PI/2-.35,0,0),-1.,20)
				MeshFactory.box(part,Vector3(0,y+.046*sz,zo-.014),Vector3(.016,.012,.012),dark,Vector3.ZERO,.2)
				MeshFactory.cylinder(part,Vector3(0,y,zr+.008),.04*sz,.016,dark,Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(part,Vector3(0,y+.07*sz,zr+.03),.036*sz,.008,accent.darkened(.1),Vector3(PI/2+.35,0,0),-1.,18)
				MeshFactory.box(part,Vector3(0,y+.036*sz,zr+.014),Vector3(.014,.012,.012),dark,Vector3.ZERO,.2)
			# 1.5.1 round 2 (the user: only snipers, DMRs and the ARC carry scopes - every other
			# gun has iron sights): iron sight styles, so guns of a role still differ.
			"iron_ak":
				# a tangent leaf with a V notch on the receiver, a hooded round post on the barrel
				var zr=grip_z-.22*sz;var zf=front_z-.06*sz;var h=rt+.03
				MeshFactory.box(part,Vector3(0,rt+.006,zr),Vector3(.03,.012,.05),dark,Vector3.ZERO,.3)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.011,rt+.022,zr-.02),Vector3(.012,.022,.006),dark,Vector3.ZERO,.2)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.02,.03,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+h)*.5,zf),Vector3(.006,h-top,.008),dark,Vector3.ZERO,.1)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.014,(top+h+.01)*.5,zf),Vector3(.004,h+.01-top,.014),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,h+.012,zf),Vector3(.032,.004,.014),dark,Vector3.ZERO,.1)
				gun.set_meta("sight_aim",Vector3(0,h,zr))
			"iron_flip":
				# low folding rail sights, raised: an aperture leaf at the back, a winged post in front
				var zr=grip_z+.0*sz;var zf=front_z+.03*sz;var h=rt+.036
				for z in [zr,zf]:MeshFactory.box(part,Vector3(0,rt+.008,z),Vector3(.026,.016,.026),dark,Vector3.ZERO,.3)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.01,h,zr),Vector3(.005,.026,.005),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,h+.012,zr),Vector3(.025,.004,.005),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,h-.012,zr),Vector3(.025,.004,.005),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,(rt+.016+h)*.5,zf),Vector3(.005,h-rt-.016,.006),dark,Vector3.ZERO,.1)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.012,rt+.026,zf),Vector3(.004,.022,.016),dark,Vector3(0,0,-sx*.35),.1)
				gun.set_meta("sight_aim",Vector3(0,h,zr))
			"iron_ghost":
				# a thick ghost ring between tall guards, a square post in a box guard
				var zr=grip_z+.0*sz;var zf=front_z-.05*sz;var h=rt+.034
				MeshFactory.box(part,Vector3(0,rt+.008,zr),Vector3(.044,.016,.03),dark,Vector3.ZERO,.3)
				for sx in [-1.,1.]:
					MeshFactory.box(part,Vector3(sx*.0145,h,zr),Vector3(.009,.038,.01),dark,Vector3.ZERO,.1)
					MeshFactory.box(part,Vector3(sx*.026,h+.004,zr),Vector3(.006,.05,.024),dark.lightened(.1),Vector3.ZERO,.2)
				for sy in [-1.,1.]:MeshFactory.box(part,Vector3(0,h+sy*.0145,zr),Vector3(.02,.009,.01),dark,Vector3.ZERO,.1)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.021,.03,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+h)*.5,zf),Vector3(.007,h-top,.007),dark,Vector3.ZERO,.1)
				for sx in [-1.,1.]:MeshFactory.box(part,Vector3(sx*.016,(top+h+.012)*.5,zf),Vector3(.005,h+.012-top,.02),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,h+.014,zf),Vector3(.037,.005,.02),dark,Vector3.ZERO,.1)
				gun.set_meta("sight_aim",Vector3(0,h,zr))
			"iron_dots":
				# a low notch and post with bright dots (the medic's SMG)
				var zr=grip_z-.02*sz;var zf=front_z-.04*sz;var h=rt+.022
				MeshFactory.box(part,Vector3(0,rt+.006,zr),Vector3(.03,.012,.026),dark,Vector3.ZERO,.3)
				for sx in [-1.,1.]:
					MeshFactory.box(part,Vector3(sx*.01,h-.002,zr),Vector3(.01,.016,.01),dark,Vector3.ZERO,.1)
					MeshFactory.box(part,Vector3(sx*.01,h+.002,zr+.0052),Vector3(.004,.004,.001),accent,Vector3.ZERO,0.)
				MeshFactory.cylinder(part,Vector3(0,top,zf),.019,.026,dark,Vector3(PI/2,0,0),-1.,10)
				MeshFactory.box(part,Vector3(0,(top+h)*.5,zf),Vector3(.007,h-top,.008),dark,Vector3.ZERO,.1)
				MeshFactory.box(part,Vector3(0,h-.003,zf+.0045),Vector3(.004,.004,.001),accent,Vector3.ZERO,0.)
				gun.set_meta("sight_aim",Vector3(0,h,zr))
			# 1.5.2 (the user: FEATHER, RIVET and TRIO looked like the other pistols): their own
			# parts, the trigger guard, grip and action kept. Parts on a moving slide ride it.
			"feather":
				var m:Vector3=gun.muzzle.position*gun.base.scale;var on=slide_part(gun,part)
				for sx in [-1.,1.]:
					for k in range(3):MeshFactory.box(on,Vector3(sx*.0175,.044-k*.004,-.03-k*.045),Vector3(.004,.01,.05),accent,Vector3(0,0,sx*.25),.3)
					MeshFactory.box(on,Vector3(sx*.0185,.03,-.12),Vector3(.002,.016,.005),accent,Vector3.ZERO,0.)
					MeshFactory.box(on,Vector3(sx*.0185,.03,-.12),Vector3(.002,.005,.016),accent,Vector3.ZERO,0.)
				MeshFactory.cylinder(on,m+Vector3(0,0,-.018),.013,.036,MEDIC_WHITE.darkened(.05),Vector3(PI/2,0,0),-1.,14)
				MeshFactory.cylinder(on,m+Vector3(0,0,-.038),.0145,.006,accent,Vector3(PI/2,0,0),-1.,14)
				MeshFactory.box(part,Vector3(0,-.03,-.15),Vector3(.022,.02,.05),accent.darkened(.1),Vector3.ZERO,.5)
				MeshFactory.box(part,Vector3(0,-.03,-.177),Vector3(.014,.012,.004),Color("eafff3"),Vector3.ZERO,0.)
				# a green heal vial along the frame's left side, capped at both ends
				MeshFactory.cylinder(part,Vector3(-.026,-.02,-.105),.0095,.075,Color("62e39f"),Vector3(PI/2,0,0),-1.,12)
				for z in [-.068,-.142]:MeshFactory.cylinder(part,Vector3(-.026,-.02,z),.011,.008,MEDIC_WHITE.darkened(.15),Vector3(PI/2,0,0),-1.,12)
				gun.muzzle.position.z-=.04/maxf(.01,gun.base.scale.z)
			"trio":
				var m:Vector3=gun.muzzle.position*gun.base.scale;var on=slide_part(gun,part)
				MeshFactory.box(on,m+Vector3(0,.002,-.02),Vector3(.03,.03,.04),dark,Vector3.ZERO,.3)
				for k in range(3):MeshFactory.box(on,m+Vector3(0,.0175,-.008-k*.012),Vector3(.016,.004,.006),accent,Vector3.ZERO,0.)
				for sx in [-1.,1.]:
					for k in range(3):MeshFactory.box(on,Vector3(sx*.0185,.036,-.05-k*.035),Vector3(.003,.012,.02),dark.darkened(.3),Vector3(0,0,0),0.)
				for k in range(3):MeshFactory.box(part,Vector3(0,-.032,-.14-k*.022),Vector3(.026,.008,.012),accent.darkened(.2),Vector3.ZERO,.2)
				for sx in [-1.,1.]:MeshFactory.box(on,Vector3(sx*.0188,.022,-.095),Vector3(.002,.005,.17),accent,Vector3.ZERO,0.)
				for sx in [-1.,1.]:
					for k in range(3):MeshFactory.box(on,m+Vector3(sx*.0152,.002,-.01-k*.011),Vector3(.003,.012,.006),accent.darkened(.25),Vector3.ZERO,0.)
				MeshFactory.box(part,Vector3(0,-.026,-.162),Vector3(.02,.008,.07),dark,Vector3.ZERO,.2)
				gun.muzzle.position.z-=.04/maxf(.01,gun.base.scale.z)
			"rivet":
				var m:Vector3=gun.muzzle.position*gun.base.scale
				MeshFactory.box(part,m+Vector3(0,.006,.07),Vector3(.034,.034,.13),dark.lightened(.1),Vector3.ZERO,.4)
				for sx in [-1.,1.]:
					for k in range(4):MeshFactory.cylinder(part,m+Vector3(sx*.018,.006,.025+k*.03),.0045,.004,accent.lightened(.2),Vector3(0,0,PI/2),-1.,8)
				MeshFactory.cylinder(part,m+Vector3(0,0,-.012),.016,.024,dark,Vector3(PI/2,0,0),.021,12)
				for k in range(6):MeshFactory.box(part,m+Vector3(0,.0245,.02+k*.02),Vector3(.037,.005,.02),Color("1c1d22") if k%2==0 else Color("f2c230"),Vector3.ZERO,0.)
				MeshFactory.box(part,Vector3(-.026,.01,-.06),Vector3(.006,.014,.07),dark,Vector3.ZERO,.2)
				# a rivet feed tube along the barrel's right side, rivet heads showing
				MeshFactory.cylinder(part,m+Vector3(.026,-.004,.075),.008,.12,dark,Vector3(PI/2,0,0),-1.,10)
				for k in range(5):MeshFactory.cylinder(part,m+Vector3(.034,-.004,.03+k*.022),.0055,.006,accent.lightened(.25),Vector3(0,0,PI/2),-1.,8)
				gun.muzzle.position.z-=.024/maxf(.01,gun.base.scale.z)
			"coils":
				for i in range(3):
					var ring=MeshFactory.cylinder(part,Vector3(0,top,left_z-.11-i*.07),.032,.022,Color("c79bff"),Vector3(PI/2,0,0),-1.,12)
					ring.set_meta("glow",true)
		for holder in [part]+([part.get_meta("on_slide")] if part.has_meta("on_slide") else []):
			MeshFactory.merge_children(holder)
			for mesh in holder.get_children():
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
			# 1.4.5: a full trigger guard (bottom bar and front post, closed to the
			# receiver) and a larger, lighter trigger blade, so both read in view.
			m.box(body,Vector3(0,-.046,-.096),Vector3(.012,.036,.012),Color("8a7fb0"),Vector3(.3,0,0),.3)
			m.box(body,Vector3(0,-.073,-.104),Vector3(.016,.009,.084),deep,Vector3.ZERO,.3)
			m.box(body,Vector3(0,-.05,-.142),Vector3(.016,.05,.009),deep,Vector3(-.15,0,0),.3)
			# (1.4.5: taller, up round the barrel - it hung below it)
			m.box(body,Vector3(0,-.008,-.47),Vector3(.062,.074,.16),main,Vector3.ZERO,.4)
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