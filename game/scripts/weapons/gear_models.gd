class_name GearModels
extends RefCounted
## 1.4 cartoon gear: deployables (cover tiers, turret) and held gadgets. Chunky
## rounded forms, saturated tier/team colours, cel material with vertex colours.
## Gameplay collision is independent (fixed boxes in game.gd / Construction).
const M=preload("res://scripts/mesh_factory.gd")
const TEAM=[Color("3574d0"),Color("e2772a")]
const TEAM_LIGHT=[Color("86b8ea"),Color("f0b877")]
const INK=Color("262c38")
const STEEL=Color("5d6674")
const LIGHT=Color("c9d2dc")
const TIERS=[Color("f2c03e"),Color("4fae62"),Color("59606c")]
static func finish(node:Node3D,outlined:bool=false):
	M.merge_children(node)
	for mesh in node.get_children():
		if mesh is MeshInstance3D:
			mesh.material_override=HeroStyle.toon_material(outlined,.2);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
# --- Deployables -----------------------------------------------------------
# Cover: 3.4 m wide, 1.25 m high, depth .30/.55/.80 by tier (collision box).
static func cover(parent:Node3D,team:int,tier:int):
	var body=Node3D.new();body.name="CoverBody";parent.add_child(body)
	var depth=[.30,.55,.80][clampi(tier,0,2)];var color=TIERS[clampi(tier,0,2)];var dark=color.darkened(.35)
	# Rounded base sled and three stacked panels with a top rail.
	M.box(body,Vector3(0,.09,0),Vector3(3.4,.18,depth),dark,Vector3.ZERO,.5)
	for i in range(3):
		var x=-1.12+i*1.12
		M.box(body,Vector3(x,.66,0),Vector3(1.06,1.0,depth*.86),color,Vector3.ZERO,.35)
		M.box(body,Vector3(x,.66,-depth*.44),Vector3(.72,.6,.04),color.lightened(.22),Vector3.ZERO,.5)
		if tier>=1:M.box(body,Vector3(x,.9,-depth*.47),Vector3(.5,.06,.03),INK,Vector3.ZERO,.3)
		if tier>=2:
			for bolt in [-.36,.36]:M.sphere(body,Vector3(x+bolt,1.02,-depth*.45),Vector3(.06,.06,.04),LIGHT)
	M.box(body,Vector3(0,1.2,0),Vector3(3.44,.1,depth*.95),dark,Vector3.ZERO,.5)
	# Team stripe along the top rail.
	M.box(body,Vector3(0,1.21,-depth*.48),Vector3(3.3,.06,.03),TEAM[team],Vector3.ZERO,.3)
	for x in [-1.5,1.5]:M.box(body,Vector3(x,.12,0),Vector3(.26,.24,depth+.3),dark.darkened(.2),Vector3.ZERO,.5)
	finish(body)
# Turret: tripod, pedestal, "TurretHead" at 1.7 m that game.gd aims with look_at.
static func turret(parent:Node3D,team:int):
	var base=Node3D.new();base.name="TurretBase";parent.add_child(base)
	var color=TEAM[team];var light=TEAM_LIGHT[team]
	M.cylinder(base,Vector3(0,.12,0),.5,.2,STEEL,Vector3.ZERO,.42,14)
	for i in range(3):
		var a=TAU*i/3.
		M.box(base,Vector3(cos(a)*.42,.1,sin(a)*.42),Vector3(.2,.16,.75),INK,Vector3(0,-a+PI/2,0),.5)
		M.sphere(base,Vector3(cos(a)*.72,.07,sin(a)*.72),Vector3(.2,.12,.2),STEEL)
	M.cylinder(base,Vector3(0,.8,0),.14,1.2,STEEL,Vector3.ZERO,-1.,12)
	M.cylinder(base,Vector3(0,1.36,0),.26,.24,color,Vector3.ZERO,.2,16)
	finish(base)
	var head=Node3D.new();head.name="TurretHead";head.position.y=1.7;parent.add_child(head)
	M.box(head,Vector3(0,0,0),Vector3(.62,.4,.6),color,Vector3.ZERO,.6)
	M.box(head,Vector3(0,.2,.05),Vector3(.42,.12,.4),light,Vector3.ZERO,.6)
	M.box(head,Vector3(0,.04,-.31),Vector3(.36,.14,.04),INK,Vector3.ZERO,.5)
	M.sphere(head,Vector3(0,.04,-.33),Vector3(.2,.08,.03),Color("72eed4"))
	for x in [-.2,.2]:
		M.cylinder(head,Vector3(x,-.06,-.52),.06,.5,STEEL,Vector3(PI/2,0,0),-1.,12)
		M.cylinder(head,Vector3(x,-.06,-.79),.08,.08,INK,Vector3(PI/2,0,0),-1.,12)
		M.sphere(head,Vector3(x*1.6,0,.05),Vector3(.14,.26,.3),STEEL)
	M.cylinder(head,Vector3(.24,.34,.18),.012,.3,INK,Vector3.ZERO,-1.,8)
	M.sphere(head,Vector3(.24,.5,.18),Vector3(.05,.05,.05),Color("ff5b4a"))
	finish(head)
# --- Held gadgets ----------------------------------------------------------
## Returns {"node":Node3D,"right":Vector3,"left":Vector3,"two_handed":bool} in
## the node's space. Items sit in front of the chest; grips are wrist targets.
static func held(parent:Node3D,role:int,variant:int,turret_carry:bool=false) -> Dictionary:
	var node=Node3D.new();node.name="Payload";parent.add_child(node)
	var right=Vector3(.03,-.02,.03);var left=Vector3(-.05,-.04,.04);var two=false;var grip={}
	var accent:Color=HeroStyle.ROLE_ACCENT[clampi(role,0,5)]
	if turret_carry:
		var mini=Node3D.new();node.add_child(mini);turret(mini,0);mini.scale=Vector3.ONE*.24;mini.position=Vector3(0,-.25,-.12)
		# Carried by its mast (radius .034 at this scale), one fist above the other.
		return {"node":node,"right":Vector3(0,.0,-.12),"left":Vector3(0,-.13,-.12),"two_handed":true,"grip":sides("pistol",Vector3(.034,.05,.034))}
	if variant==8 or (role==0 and variant==1):
		grenade(node,"frag");return {"node":node,"right":GRENADE_GRIP,"left":left,"two_handed":false,"grip":ball()}
	if variant==9:
		M.box(node,Vector3(0,0,-.05),Vector3(.3,.16,.2),Color("6f7d4a"),Vector3.ZERO,.5)
		M.box(node,Vector3(0,.09,-.05),Vector3(.2,.03,.12),Color("f2c03e"),Vector3.ZERO,.4)
		finish(node);return {"node":node,"right":Vector3(.15,0,-.05),"left":Vector3(-.15,0,-.05),"two_handed":true,"grip":sides("pistol",Vector3(.015,.07,.09))}
	match role:
		0:
			# Armour plate: rounded curved slab with a chevron.
			M.box(node,Vector3(0,.04,-.06),Vector3(.28,.34,.06),Color("6e8aa8"),Vector3(.1,0,0),.7)
			M.box(node,Vector3(0,.07,-.1),Vector3(.12,.03,.02),accent,Vector3(0,0,.5),.4)
			M.box(node,Vector3(0,.04,-.1),Vector3(.12,.03,.02),accent,Vector3(0,0,-.5),.4)
			right=Vector3(.14,.02,-.06);left=Vector3(-.14,.02,-.06);two=true;grip=sides("pistol",Vector3(.012,.1,.03))
		1:
			# Marker: rugged tablet with antenna and glowing screen.
			M.box(node,Vector3(0,.02,-.08),Vector3(.2,.13,.04),INK,Vector3(.5,0,0),.6)
			M.box(node,Vector3(0,.025,-.1),Vector3(.15,.09,.01),Color("7fe0ff"),Vector3(.5,0,0),.3)
			M.cylinder(node,Vector3(.08,.1,-.07),.007,.12,INK,Vector3.ZERO,-1.,8)
			M.sphere(node,Vector3(.08,.16,-.07),Vector3(.025,.025,.025),accent)
			right=Vector3(.1,.02,-.08);left=Vector3(-.1,.02,-.08);two=true;grip=sides("pistol",Vector3(.01,.06,.02))
		2:
			# Folding bipod: clamp block and two splayed legs.
			M.box(node,Vector3(0,.02,-.1),Vector3(.1,.05,.08),INK,Vector3.ZERO,.5)
			for side in [-1,1]:
				M.box(node,Vector3(side*.05,-.08,-.1),Vector3(.025,.2,.025),STEEL,Vector3(0,0,side*.3),.4)
				M.sphere(node,Vector3(side*.09,-.18,-.1),Vector3(.04,.03,.04),INK)
			right=Vector3(0,.02,-.1);grip={"R":{"style":"hold","shape":{"half":Vector3(.05,.025,.04),"round":.02}}}
		3:
			var mini=Node3D.new();node.add_child(mini);cover(mini,0,clampi(variant,0,2));mini.scale=Vector3.ONE*.18;mini.position=Vector3(0,-.12,-.18)
			return {"node":node,"right":Vector3(.28,-.04,-.14),"left":Vector3(-.28,-.04,-.14),"two_handed":true,"grip":sides("pistol",Vector3(.015,.05,.04))}
		4:
			grenade(node,"flash" if variant==1 else "smoke");return {"node":node,"right":GRENADE_GRIP,"left":left,"two_handed":false,"grip":ball()}
		5:
			# Medkit: white rounded case with a green cross and handle, carried low
			# in front of the belly with both hands on its sides.
			var low=Vector3(0,-MEDKIT_DROP,0)
			M.box(node,low+Vector3(0,0,-.08),Vector3(.26,.18,.1),Color("eef2f5"),Vector3.ZERO,.6)
			M.box(node,low+Vector3(0,0,-.135),Vector3(.1,.03,.01),Color("3fcf8e"),Vector3.ZERO,.3)
			M.box(node,low+Vector3(0,0,-.135),Vector3(.03,.1,.01),Color("3fcf8e"),Vector3.ZERO,.3)
			M.box(node,low+Vector3(0,.12,-.08),Vector3(.12,.03,.03),INK,Vector3.ZERO,.5)
			right=low+Vector3(.13,0,-.08);left=low+Vector3(-.13,0,-.08);two=true;grip=sides("pistol",Vector3(.012,.07,.045))
	finish(node)
	return {"node":node,"right":right,"left":left,"two_handed":two,"grip":grip,"view_lift":MEDKIT_DROP if role==5 else 0.}
# Grip styles and shapes (handle frame) for held gear: a fist on each side
# edge, or a small ball cupped in the palm.
static func sides(style:String,half:Vector3) -> Dictionary:
	var shape={"half":half,"round":minf(half.x,minf(half.y,half.z))}
	return {"R":{"style":style,"shape":shape},"L":{"style":style,"shape":shape}}
# Grenade body: measured Toon Shooter shapes (tools/probe_gear_bounds.gd) are
# about 8 cm across around (0,.02,-.02); the fist closes on that sphere.
static func ball() -> Dictionary:return {"R":{"style":"hold","shape":{"half":Vector3.ONE*.037,"round":.037}}}
const GRENADE_GRIP=Vector3(0,.018,-.02)
const MEDKIT_DROP=.16
# Throwables reuse the Toon Shooter (CC0) grenade shapes, repainted.
static func grenade(parent:Node3D,kind:String):
	# Copy the meshes only: a nested scene instance would not survive template packing.
	var source:Node3D=GunModel.base_scene("FireGrenade" if kind!="frag" else "Grenade").instantiate()
	var base=Node3D.new();base.name="Grenade";parent.add_child(base)
	for original in source.find_children("*","MeshInstance3D",true,false):
		var copy=MeshInstance3D.new();copy.mesh=original.mesh;copy.transform=original.transform;base.add_child(copy)
	source.free()
	var palette={"frag":{"Green":Color("6f8a4a"),"DarkGreen":Color("40552c"),"DarkGrey":INK},
		"smoke":{"Red":Color("8fa7ad"),"DarkRed":Color("56707a"),"Black":INK,"Grey":LIGHT},
		"flash":{"Red":Color("f2d25a"),"DarkRed":Color("c9962d"),"Black":INK,"Grey":LIGHT}}[kind]
	for mesh in base.find_children("*","MeshInstance3D",true,false):
		for s in range(mesh.mesh.get_surface_count()):
			var authored:Material=mesh.mesh.surface_get_material(s)
			var color:Color=palette.get(authored.resource_name if authored else "",authored.albedo_color if authored is BaseMaterial3D else Color.GRAY)
			mesh.set_surface_override_material(s,HeroStyle.tinted(color,false,.2))
	base.position=Vector3(0,.02,-.02)
# --- Armour vest -----------------------------------------------------------
## Fitted to the outfit's chest volume (hitboxes.json, Chest bone frame: +Y up
## the spine, +Z forward). Tier 1: front/back plates and straps; tier 2 adds
## pouches and shoulder guards. Team colour on the collar stripe.
static func vest(parent:Node3D,level:int,team:int,center:Vector3,radii:Vector3):
	var body=Node3D.new();body.name="Vest";parent.add_child(body)
	var shell=Color("3b4352") if level<2 else Color("2a303b");var trim=Color("59606c")
	var w=radii.x*1.9;var h=radii.y*1.35;var t=.035+.012*level
	var cy=center.y-radii.y*.1
	for side in [1,-1]:
		var z=center.z+side*(radii.z+t*.5-.005)
		M.box(body,Vector3(center.x,cy,z),Vector3(w,h,t),shell,Vector3.ZERO,.6)
		M.box(body,Vector3(center.x,cy+h*.5-.02,z+side*.004),Vector3(w*.62,.03,t*.6),TEAM[team],Vector3.ZERO,.4)
	for side in [-1,1]:
		# Straps over the shoulders and side closures.
		M.box(body,Vector3(center.x+side*w*.3,cy+h*.5+.02,center.z),Vector3(.06,.035,radii.z*2.+t*2.),trim,Vector3.ZERO,.4)
		M.box(body,Vector3(center.x+side*(w*.5+.005),cy-h*.1,center.z),Vector3(.03,h*.55,radii.z*1.7),trim,Vector3.ZERO,.4)
	if level>=2:
		for i in range(3):
			M.box(body,Vector3(center.x-w*.28+i*w*.28,cy-h*.28,center.z+radii.z+t+.022),Vector3(w*.24,h*.3,.045),Color("4e5a4a"),Vector3.ZERO,.5)
		for side in [-1,1]:
			M.sphere(body,Vector3(center.x+side*(w*.5+.03),cy+h*.42,center.z),Vector3(.09,.05,radii.z*1.6),shell)
	finish(body)
