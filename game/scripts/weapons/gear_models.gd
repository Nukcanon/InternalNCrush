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
	# Nested groups (a tilted plate, a carried mini device) share the cel material;
	# glowing lamps keep their own.
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if mesh.has_meta("lamp"):continue
		mesh.material_override=HeroStyle.toon_material(outlined,.2);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
# --- Deployables -----------------------------------------------------------
const HAZARD=Color("f2c03e")
# Emissive lamps / sensor glass: kept out of the merged cel mesh (one small
# unshaded mesh per device part).
static func lamp(parent:Node3D,pos:Vector3,size:Vector3,color:Color,round:=false) -> MeshInstance3D:
	var node:MeshInstance3D=M.sphere(parent,pos,size,color) if round else M.box(parent,pos,size,color,Vector3.ZERO,.4)
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.set_meta("lamp",true)
	return node
static func finish_with_lamps(node:Node3D,lamps:Array):
	# Lamps are added after the merge so they keep their own glow material.
	finish(node)
	for spec in lamps:lamp(node,spec[0],spec[1],spec[2],spec.size()>3 and spec[3])
# Cover: 3.4 m wide, 1.25 m high, depth .30/.55/.80 by tier (collision box).
# 1.4.2 after the 1.3.5 assembly: a steel frame with end posts, three tier
# panels (ribbed, riveted, a vision slot on the heavier tiers), hazard-striped
# skids, carry handles, back braces; the heavy tier adds bolted armour plates
# and sandbags at its feet. The face toward the enemy is -Z.
static func cover(parent:Node3D,team:int,tier:int):
	var body=Node3D.new();body.name="CoverBody";parent.add_child(body)
	tier=clampi(tier,0,2)
	var depth=[.30,.55,.80][tier];var color=TIERS[tier];var dark=color.darkened(.35);var frame=Color("4a515c")
	var front=-depth*.5;var accent=TEAM[team]
	# Skids with hazard stripes, and the base beam.
	for x in [-1.46,1.46]:
		M.box(body,Vector3(x,.1,0),Vector3(.3,.2,depth+.34),frame.darkened(.25),Vector3.ZERO,.5)
		for k in range(3):M.box(body,Vector3(x-.1+k*.1,.1,-(depth+.34)*.5-.004),Vector3(.05,.14,.01),HAZARD if k%2==0 else INK,Vector3(0,0,.5),.3)
	M.box(body,Vector3(0,.17,0),Vector3(3.2,.14,depth*.9),frame,Vector3.ZERO,.4)
	# End posts with team caps.
	for x in [-1.62,1.62]:
		M.box(body,Vector3(x,.66,0),Vector3(.18,1.2,depth+.06),frame,Vector3.ZERO,.4)
		M.box(body,Vector3(x,1.28,0),Vector3(.24,.08,depth+.12),accent,Vector3.ZERO,.5)
	# Three panels.
	for i in range(3):
		var x=-1.04+i*1.04
		M.box(body,Vector3(x,.7,0),Vector3(1.0,1.02,depth*.82),color,Vector3.ZERO,.3)
		# Raised face plate with two horizontal ribs.
		M.box(body,Vector3(x,.7,front+.02),Vector3(.82,.82,.04),color.lightened(.14),Vector3.ZERO,.5)
		for y in [.48,.92]:M.box(body,Vector3(x,y,front-.005),Vector3(.72,.05,.03),dark,Vector3.ZERO,.3)
		# Corner rivets.
		for dx in [-.36,.36]:
			for y in [.34,1.06]:M.sphere(body,Vector3(x+dx,y,front-.004),Vector3(.045,.045,.03),LIGHT)
		if tier>=1 and i==1:
			# Vision slot with a steel hood.
			M.box(body,Vector3(x,1.02,front-.012),Vector3(.34,.06,.03),INK,Vector3.ZERO,.3)
			M.box(body,Vector3(x,1.07,front-.03),Vector3(.4,.035,.08),frame,Vector3(-.3,0,0),.3)
		if tier==2:
			# Bolted armour plate over the panel.
			M.box(body,Vector3(x,.62,front-.035),Vector3(.62,.5,.05),Color("6a717c"),Vector3.ZERO,.35)
			for dx in [-.26,.26]:
				for y in [.42,.82]:M.cylinder(body,Vector3(x+dx,y,front-.062),.022,.02,LIGHT,Vector3(PI/2,0,0),-1.,8)
	# Top rail, team stripe and carry handles.
	M.box(body,Vector3(0,1.24,0),Vector3(3.26,.09,depth*.92),dark,Vector3.ZERO,.5)
	M.box(body,Vector3(0,1.25,front+.005),Vector3(3.0,.05,.03),accent,Vector3.ZERO,.3)
	for x in [-.9,.9]:
		for dx in [-.12,.12]:M.box(body,Vector3(x+dx,1.33,0),Vector3(.035,.12,.035),frame,Vector3.ZERO,.3)
		M.box(body,Vector3(x,1.39,0),Vector3(.28,.035,.035),frame,Vector3.ZERO,.3)
	# Back braces (visible from the friendly side).
	for x in [-.52,.52]:
		M.box(body,Vector3(x,.62,depth*.5+.14),Vector3(.08,1.1,.08),frame,Vector3(-.42,0,0),.3)
		M.box(body,Vector3(x,.08,depth*.5+.36),Vector3(.2,.08,.14),frame.darkened(.2),Vector3.ZERO,.4)
	if tier==2:
		# Sandbags at the feet (enemy side).
		for k in range(5):
			M.box(body,Vector3(-1.2+k*.6,.14,front-.2),Vector3(.52,.24,.3),Color("b8a47a"),Vector3(0,(k%2-.5)*.12,0),.8)
		for k in range(4):
			M.box(body,Vector3(-.9+k*.6,.36,front-.19),Vector3(.5,.2,.28),Color("a8946a"),Vector3(0,(k%2-.5)*.1,0),.8)
	finish_with_lamps(body,[[Vector3(-1.62,1.1,front-.03),Vector3(.06,.06,.02),TEAM_LIGHT[team]],[Vector3(1.62,1.1,front-.03),Vector3(.06,.06,.02),TEAM_LIGHT[team]]])
# Turret: tripod, pedestal, "TurretHead" at 1.7 m that game.gd aims with look_at.
# 1.4.2 after the 1.3.5 assembly: a broad anchored base with three splayed
# legs and feet, a tapered team-coloured body with side braces and an ammo
# box, a yaw ring; the head has armoured cheeks with vents, twin barrels with
# cooling rings and muzzle brakes, a sensor block with a glowing eye, a rear
# counterweight and an antenna.
static func turret(parent:Node3D,team:int):
	var base=Node3D.new();base.name="TurretBase";parent.add_child(base)
	var color=TEAM[team];var light=TEAM_LIGHT[team];var metal=Color("4a515c");var pale=Color("9aa6ad")
	M.cylinder(base,Vector3(0,.1,0),.62,.16,metal,Vector3.ZERO,.52,18)
	M.cylinder(base,Vector3(0,.19,0),.5,.04,HAZARD,Vector3.ZERO,-1.,18)
	for i in range(3):
		var a=TAU*i/3.+PI/6.
		var dir=Vector3(cos(a),0,sin(a))
		M.box(base,dir*.55+Vector3(0,.16,0),Vector3(.16,.12,.6),INK,Vector3(0,-a+PI/2,0),.5)
		M.box(base,dir*.86+Vector3(0,.06,0),Vector3(.3,.1,.3),metal,Vector3(0,-a,0),.6)
		M.cylinder(base,dir*.86+Vector3(0,.12,0),.035,.06,pale,Vector3.ZERO,-1.,8)
	# Tapered body with side braces and an ammo box.
	M.tapered(base,Vector3(0,.58,0),Vector3(.62,.72,.56),color,.72)
	for side in [-1,1]:
		M.box(base,Vector3(side*.34,.66,0),Vector3(.1,.6,.22),metal,Vector3(0,0,side*-.2),.4)
		M.cylinder(base,Vector3(side*.3,.98,0),.09,.1,pale,Vector3(0,0,PI/2),-1.,12)
	M.box(base,Vector3(.36,.4,.18),Vector3(.2,.28,.3),Color("5b6b3a"),Vector3.ZERO,.4)
	M.box(base,Vector3(.36,.56,.18),Vector3(.22,.04,.32),INK,Vector3.ZERO,.3)
	# Status panel on the front of the body.
	M.box(base,Vector3(0,.62,-.3),Vector3(.36,.18,.03),metal,Vector3.ZERO,.3)
	# Yaw ring.
	M.cylinder(base,Vector3(0,1.02,0),.3,.12,pale,Vector3.ZERO,-1.,18)
	M.cylinder(base,Vector3(0,1.3,0),.16,.44,metal,Vector3.ZERO,.2,14)
	M.cylinder(base,Vector3(0,1.5,0),.24,.07,pale,Vector3.ZERO,-1.,18)
	finish_with_lamps(base,[[Vector3(-.09,.63,-.318),Vector3(.05,.05,.012),light],[Vector3(0,.63,-.318),Vector3(.05,.05,.012),Color("7dff9a")],[Vector3(.09,.63,-.318),Vector3(.05,.05,.012),light]])
	var head=Node3D.new();head.name="TurretHead";head.position.y=1.7;parent.add_child(head)
	M.box(head,Vector3(0,0,0),Vector3(.56,.36,.56),color,Vector3.ZERO,.55)
	M.box(head,Vector3(0,.2,.06),Vector3(.4,.1,.38),light,Vector3.ZERO,.6)
	for side in [-1,1]:
		# Armoured cheek with three vents and a trunnion.
		M.box(head,Vector3(side*.36,-.02,.04),Vector3(.18,.4,.5),metal,Vector3.ZERO,.5)
		for z in [-.08,.04,.16]:M.box(head,Vector3(side*.456,.08,z),Vector3(.02,.06,.07),INK,Vector3.ZERO,.3)
		M.cylinder(head,Vector3(side*.29,-.02,.04),.1,.08,pale,Vector3(0,0,PI/2),-1.,14)
		# Barrel: shroud, cooling rings, muzzle brake.
		var x=side*.15
		M.cylinder(head,Vector3(x,-.05,-.34),.07,.2,metal,Vector3(PI/2,0,0),-1.,14)
		M.cylinder(head,Vector3(x,-.05,-.6),.038,.56,pale,Vector3(PI/2,0,0),-1.,12)
		for k in range(4):M.cylinder(head,Vector3(x,-.05,-.5-k*.07),.055,.018,INK,Vector3(PI/2,0,0),-1.,12)
		M.box(head,Vector3(x,-.05,-.9),Vector3(.1,.08,.1),metal,Vector3.ZERO,.4)
		M.cylinder(head,Vector3(x,-.05,-.955),.03,.012,Color("11181c"),Vector3(PI/2,0,0),-1.,10)
	# Sensor block, rear counterweight, antenna.
	M.box(head,Vector3(0,.2,-.18),Vector3(.22,.16,.2),metal,Vector3.ZERO,.5)
	M.box(head,Vector3(0,.02,.34),Vector3(.36,.24,.16),metal.darkened(.2),Vector3.ZERO,.5)
	M.cylinder(head,Vector3(.2,.38,.2),.012,.3,INK,Vector3.ZERO,-1.,8)
	finish_with_lamps(head,[[Vector3(0,.2,-.285),Vector3(.12,.08,.02),Color("72eed4"),true],[Vector3(.2,.54,.2),Vector3(.05,.05,.05),Color("ff5b4a"),true]])
# --- Held gadgets ----------------------------------------------------------
## Returns {"node":Node3D,"right":Vector3,"left":Vector3,"two_handed":bool} in
## the node's space. Items sit in front of the chest; grips are wrist targets.
static func held(parent:Node3D,role:int,variant:int,turret_carry:bool=false,pull_ring:bool=false) -> Dictionary:
	var node=Node3D.new();node.name="Payload";parent.add_child(node)
	var right=Vector3(.03,-.02,.03);var left=Vector3(-.05,-.04,.04);var two=false;var grip={}
	var accent:Color=HeroStyle.ROLE_ACCENT[clampi(role,0,5)]
	if turret_carry:
		var mini=Node3D.new();node.add_child(mini);turret(mini,0);mini.scale=Vector3.ONE*.24;mini.position=Vector3(0,-.25,-.12)
		# Carried by its mast (radius .034 at this scale), one fist above the other.
		return {"node":node,"right":Vector3(0,.0,-.12),"left":Vector3(0,-.13,-.12),"two_handed":true,"grip":sides("pistol",Vector3(.034,.05,.034))}
	if variant==8 or (role==0 and variant==1):
		grenade(node,"frag",pull_ring);return {"node":node,"right":GRENADE_GRIP,"left":left,"two_handed":false,"grip":ball()}
	if variant==9:
		M.box(node,Vector3(0,0,-.05),Vector3(.3,.16,.2),Color("6f7d4a"),Vector3.ZERO,.5)
		M.box(node,Vector3(0,.09,-.05),Vector3(.2,.03,.12),Color("f2c03e"),Vector3.ZERO,.4)
		finish(node);return {"node":node,"right":Vector3(.15,0,-.05),"left":Vector3(-.15,0,-.05),"two_handed":true,"grip":sides("pistol",Vector3(.015,.07,.09))}
	match role:
		0:
			# 1.4.2 armour plate insert: shooter's-cut outline (narrower top with
			# angled corners), slight curve, rubber edge, fabric cover with a
			# label patch and the class chevron, strap loops on the back.
			var pivot=Node3D.new();pivot.position=Vector3(0,.04,-.06);pivot.rotation.x=.1;node.add_child(pivot)
			var cover_color=Color("4f5d6e");var edge=Color("262c38")
			M.box(pivot,Vector3(0,-.04,0),Vector3(.28,.26,.05),cover_color,Vector3.ZERO,.5)
			M.box(pivot,Vector3(0,.12,0),Vector3(.18,.1,.05),cover_color,Vector3.ZERO,.5)
			for side in [-1,1]:
				M.box(pivot,Vector3(side*.098,.11,0),Vector3(.06,.12,.049),cover_color,Vector3(0,0,side*.72),.5)
				# Curve: the side thirds fold back a little.
				M.box(pivot,Vector3(side*.12,-.04,.012),Vector3(.05,.25,.045),cover_color.darkened(.08),Vector3(0,side*-.25,0),.5)
			# Rubber edge along the bottom and sides.
			M.box(pivot,Vector3(0,-.172,0),Vector3(.29,.022,.056),edge,Vector3.ZERO,.5)
			for side in [-1,1]:M.box(pivot,Vector3(side*.142,-.05,0),Vector3(.02,.24,.056),edge,Vector3.ZERO,.5)
			# Label patch and chevron on the front (-Z).
			M.box(pivot,Vector3(0,.06,-.027),Vector3(.12,.05,.006),Color("e6e0cf"),Vector3.ZERO,.3)
			M.box(pivot,Vector3(0,.064,-.031),Vector3(.08,.012,.004),INK,Vector3.ZERO,.2)
			M.box(pivot,Vector3(-.025,-.06,-.03),Vector3(.07,.025,.008),accent,Vector3(0,0,.55),.4)
			M.box(pivot,Vector3(.025,-.06,-.03),Vector3(.07,.025,.008),accent,Vector3(0,0,-.55),.4)
			# Strap loops on the back.
			for y in [-.1,.03]:M.box(pivot,Vector3(0,y,.03),Vector3(.2,.02,.012),edge,Vector3.ZERO,.3)
			M.merge_children(pivot)
			right=Vector3(.14,.02,-.06);left=Vector3(-.14,.02,-.06);two=true;grip=sides("pistol",Vector3(.012,.1,.03))
			for s in grip:grip[s].shape.thumb_flat=true # (1.5.4, the user: thumbs out to the side, not bent down over the edge)
		1:
			# Marker: rugged tablet with antenna and glowing screen.
			# 1.4.6 (the user): the screen faces the holder - on the near (+Z) face,
			# the tablet tilted up toward the eye.
			M.box(node,Vector3(0,.02,-.08),Vector3(.2,.13,.04),INK,Vector3(-.5,0,0),.6)
			M.box(node,Vector3(0,.031,-.061),Vector3(.15,.09,.01),Color("7fe0ff"),Vector3(-.5,0,0),.3)
			M.cylinder(node,Vector3(.08,.1,-.07),.007,.12,INK,Vector3.ZERO,-1.,8)
			M.sphere(node,Vector3(.08,.16,-.07),Vector3(.025,.025,.025),accent)
			right=Vector3(.1,.02,-.08);left=Vector3(-.1,.02,-.08);two=true;grip=sides("pistol",Vector3(.01,.06,.02))
		2:
			# 1.4.5 (the user: a cooler bipod): rail clamp with a QD lever, hinge
			# yoke, two-stage telescoping legs with lock collars, rubber feet.
			bipod(node,Vector3(0,.045,-.1),1.15,INK,STEEL,accent,false)
			right=Vector3(0,.02,-.1);grip={"R":{"style":"hold","shape":{"half":Vector3(.05,.025,.04),"round":.02}}}
		3:
			var mini=Node3D.new();node.add_child(mini);cover(mini,0,clampi(variant,0,2));mini.scale=Vector3.ONE*.18;mini.position=Vector3(0,-.12,-.18)
			return {"node":node,"right":Vector3(.28,-.04,-.14),"left":Vector3(-.28,-.04,-.14),"two_handed":true,"grip":sides("pistol",Vector3(.015,.05,.04))}
		4:
			grenade(node,"flash" if variant==1 else "smoke",pull_ring);return {"node":node,"right":GRENADE_GRIP,"left":left,"two_handed":false,"grip":ball()}
		5:
			# Medkit: white rounded case with a green cross and handle, carried low
			# in front of the belly with both hands on its sides.
			var low=Vector3(0,-MEDKIT_DROP,0)
			# 1.4.2: hard case in two halves (seam and hinge), corner bumpers,
			# two latches, a padded handle on posts, a green cross on the lid
			# and on the top, and a small label strip.
			var c=low+Vector3(0,0,-.08);var white=Color("eef2f5");var green=Color("3fcf8e");var bumper=Color("2f9a6a")
			M.box(node,c,Vector3(.26,.18,.1),white,Vector3.ZERO,.55)
			M.box(node,c+Vector3(0,0,.0),Vector3(.262,.012,.102),Color("c9d2da"),Vector3.ZERO,.2) # seam between the halves
			M.box(node,c+Vector3(0,-.02,.052),Vector3(.2,.02,.012),Color("9aa6ad"),Vector3.ZERO,.3) # hinge (back)
			for sx in [-1,1]:
				for sy in [-1,1]:M.box(node,c+Vector3(sx*.118,sy*.078,0),Vector3(.034,.034,.106),bumper,Vector3.ZERO,.6)
			for sx in [-.07,.07]:
				M.box(node,c+Vector3(sx,.02,-.054),Vector3(.034,.05,.014),Color("9aa6ad"),Vector3.ZERO,.4) # latch
				M.box(node,c+Vector3(sx,.044,-.058),Vector3(.02,.01,.008),INK,Vector3.ZERO,.2)
			M.box(node,c+Vector3(0,-.02,-.052),Vector3(.1,.03,.008),green,Vector3.ZERO,.3)
			M.box(node,c+Vector3(0,-.02,-.052),Vector3(.03,.09,.008),green,Vector3.ZERO,.3)
			M.box(node,c+Vector3(0,.092,.0),Vector3(.06,.004,.018),green,Vector3.ZERO,.2)
			M.box(node,c+Vector3(0,.092,.0),Vector3(.018,.004,.06),green,Vector3.ZERO,.2)
			M.box(node,c+Vector3(0,-.07,-.052),Vector3(.12,.018,.006),Color("d8dde2"),Vector3.ZERO,.2)
			for sx in [-.05,.05]:M.box(node,c+Vector3(sx,.105,0),Vector3(.018,.03,.02),INK,Vector3.ZERO,.4)
			M.box(node,c+Vector3(0,.125,0),Vector3(.13,.026,.032),Color("3a4046"),Vector3.ZERO,.6)
			right=low+Vector3(.13,0,-.08);left=low+Vector3(-.13,0,-.08);two=true;grip=sides("pistol",Vector3(.012,.07,.045))
	finish(node)
	return {"node":node,"right":right,"left":left,"two_handed":two,"grip":grip,"view_lift":MEDKIT_DROP if role==5 else 0.}
# Bipod (1.4.5): the clamp's top centre at `at`, k = size. Deployed: legs down
# and splayed with a little forward rake; folded: legs forward along the barrel
# (the guns that carry one, GunLooks "bipod").
# fold_back: folded legs lie back along the barrel (a bipod near the muzzle, 1.5.4); splay: how far
# folded legs part (wide enough to pass either side of a launcher's front grip)
static func bipod(parent:Node3D,at:Vector3,k:float,dark:Color,steel:Color,accent:Color,folded:bool,fold_back:=false,splay:=.07):
	# clamp on the rail: block, jaw lip, QD lever on the right, tension knob on the left
	M.box(parent,at+Vector3(0,-.018,0)*k,Vector3(.058,.03,.068)*k,dark,Vector3.ZERO,.45)
	M.box(parent,at+Vector3(0,-.004,0)*k,Vector3(.066,.008,.072)*k,steel,Vector3.ZERO,.3)
	M.box(parent,at+Vector3(.036,-.02,.006)*k,Vector3(.008,.014,.056)*k,accent,Vector3(.18,0,0),.4)
	M.cylinder(parent,at+Vector3(-.036,-.02,0)*k,.012*k,.012*k,accent,Vector3(0,0,PI/2),-1.,10)
	# hinge yoke and barrel across
	var pivot=at+Vector3(0,-.045,0)*k
	M.box(parent,pivot+Vector3(0,.006,0)*k,Vector3(.07,.02,.04)*k,steel,Vector3.ZERO,.4)
	M.cylinder(parent,pivot,.011*k,.088*k,dark,Vector3(0,0,PI/2),-1.,10)
	for side in [-1.,1.]:
		var rot=Vector3((PI/2-.12)*(-1. if fold_back else 1.),0,side*.07) if folded else Vector3(-.16,0,side*.42)
		if folded:rot.z=side*splay
		var d=Basis.from_euler(rot)*Vector3.DOWN
		var root=pivot+Vector3(side*.03,0,0)*k
		# outer tube, lock collar, inner leg with notches, rubber foot
		M.cylinder(parent,root+d*.055*k,.0095*k,.11*k,dark,rot,-1.,8)
		M.cylinder(parent,root+d*.112*k,.0125*k,.014*k,accent,rot,-1.,8)
		M.cylinder(parent,root+d*.16*k,.0068*k,.09*k,steel,rot,-1.,8)
		for n in [.135,.155,.175]:M.cylinder(parent,root+d*n*k,.0078*k,.004*k,dark,rot,-1.,8)
		M.sphere(parent,root+d*.208*k,Vector3(.026,.02,.026)*k,dark.darkened(.25))
	# return spring between the legs
	M.cylinder(parent,pivot+Vector3(0,-.012,.0)*k,.0035*k,.05*k,steel,Vector3(0,0,PI/2),-1.,6)
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
static func grenade(parent:Node3D,kind:String,pull_ring:bool=false):
	# Copy the meshes only: a nested scene instance would not survive template packing.
	var source:Node3D=GunModel.base_scene("FireGrenade" if kind!="frag" else "Grenade").instantiate()
	var base=Node3D.new();base.name="Grenade";parent.add_child(base)
	var ring:MeshInstance3D
	for original in source.find_children("*","MeshInstance3D",true,false):
		var copy=MeshInstance3D.new();copy.mesh=original.mesh;copy.transform=original.transform;base.add_child(copy)
		# 1.4.5: the pull ring is its own piece, pulled off by the free hand
		# before the throw (Actor.update_throw_hands).
		var parts=split_ring(original.mesh,"frag" if kind=="frag" else "fire") if pull_ring else []
		if not parts.is_empty():
			copy.mesh=parts[0];ring=MeshInstance3D.new();ring.name="PullRing";ring.mesh=parts[1];ring.transform=original.transform;base.add_child(ring)
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
# The ring is the small connected piece at the top of the lever's surface
# (tools/probe_grenade_parts.gd: 96 triangles about 4 cm across). Returns
# [body mesh without it, ring mesh] or [] when there is none.
static var ring_cache={}
static func split_ring(mesh:Mesh,kind:String) -> Array:
	var key=kind+str(mesh.get_rid().get_id())
	if ring_cache.has(key):return ring_cache[key]
	var result=[]
	var target=-1
	for s in range(mesh.get_surface_count()):
		var mat=mesh.surface_get_material(s)
		if mat and mat.resource_name==("DarkGrey" if kind=="frag" else "Black"):target=s
	if target>=0:
		var arr=mesh.surface_get_arrays(target);var v:PackedVector3Array=arr[Mesh.ARRAY_VERTEX];var idx=arr[Mesh.ARRAY_INDEX]
		if idx==null or idx.is_empty():
			idx=PackedInt32Array();for i in range(v.size()):idx.append(i)
		var parent={};var keys=[]
		for i in range(v.size()):
			var k=v[i].snapped(Vector3.ONE*.0005);keys.append(k);parent[k]=k
		var root_of=func(x):
			while parent[x]!=x:x=parent[x]
			return x
		for t in range(0,idx.size(),3):
			var a=root_of.call(keys[idx[t]])
			for j in [1,2]:
				var b=root_of.call(keys[idx[t+j]])
				if a!=b:parent[b]=a
		var boxes={};var tris={}
		for t in range(0,idx.size(),3):
			var r=root_of.call(keys[idx[t]])
			if not boxes.has(r):boxes[r]=AABB(v[idx[t]],Vector3.ZERO);tris[r]=[]
			tris[r].append(t)
			for j in range(3):boxes[r]=boxes[r].expand(v[idx[t+j]])
		var ring_root=null
		for r in boxes:
			var box:AABB=boxes[r]
			if tris[r].size()>=60 and box.get_center().y>.02 and box.size.x<.05 and box.size.y<.05:ring_root=r
		if ring_root!=null:
			var keep=PackedInt32Array();var ring_idx=PackedInt32Array()
			for r in tris:
				for t in tris[r]:
					var into=ring_idx if r==ring_root else keep
					into.append(idx[t]);into.append(idx[t+1]);into.append(idx[t+2])
			var body=ArrayMesh.new();var ring_mesh=ArrayMesh.new()
			for s in range(mesh.get_surface_count()):
				var sa=mesh.surface_get_arrays(s)
				if s==target:sa[Mesh.ARRAY_INDEX]=keep
				body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,sa);body.surface_set_material(s,mesh.surface_get_material(s))
			var ra=mesh.surface_get_arrays(target);ra[Mesh.ARRAY_INDEX]=ring_idx
			ring_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,ra);ring_mesh.surface_set_material(0,mesh.surface_get_material(target))
			# 1.5.0: the ring mesh shares the whole surface's vertices, so its AABB is the
			# grenade's - the hand pinched the grenade's middle. Its own centre is kept here.
			ring_mesh.set_meta("ring_centre",Vector3(boxes[ring_root].get_center()))
			result=[body,ring_mesh]
	ring_cache[key]=result
	return result
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
