class_name HeroModel
extends RefCounted
## Cartoon operators on the shared pose rig (same joints, sockets and clips as
## the current operators), so animation, weapon grips and hit volumes follow.
## Head and hands are enlarged for readability; HEAD_SCALE records the change.
const S=preload("res://scripts/style/hero_style.gd")
const HEAD_SCALE=1.32
static func build(role:int,team:int,outlined:bool=false) -> Node3D:
	var rig=HumanModel.pose_rig(role)
	rig.name="HeroRig";rig.set_meta("hero_style",true);rig.set_meta("head_scale",HEAD_SCALE)
	var hips=rig.get_node("Hips");var chest=hips.get_node("Chest");var head=chest.get_node("Head")
	var main=S.TEAM_MAIN[team];var light=S.TEAM_LIGHT[team];var deep=S.TEAM_DEEP[team];var accent=S.ROLE_ACCENT[role]
	var skin=S.SKIN[role];var hair=S.HAIR[role];var female=role in HumanModel.FEMALE_ROLES
	var heavy=role==2;var medic=role==5
	var jacket=S.WHITE if medic else main
	var trim=main if medic else S.WHITE
	var pants=Color("3b4660") if not heavy else Color("343b4f")
	# Pelvis: trousers seat, belt with buckle and side pouches.
	S.ell(hips,Vector3(0,-.04,0),Vector3(.33,.26,.25),pants)
	S.rbox(hips,Vector3(0,.05,0),Vector3(.35,.07,.27),S.SUIT,Vector3.ZERO,.6)
	S.rbox(hips,Vector3(0,.05,-.135),Vector3(.08,.055,.02),accent,Vector3.ZERO,.7)
	for side in [-1,1]:S.rbox(hips,Vector3(side*.17,-.01,-.02),Vector3(.075,.1,.13),S.SUIT_MID,Vector3.ZERO,.6)
	# Jacket torso: broad chest tapering to the waist, trim stripes and collar.
	var width=.44 if heavy else .39
	S.ell(chest,Vector3(0,.15,0),Vector3(width,.44,.29 if heavy else .27),jacket)
	S.ell(chest,Vector3(0,-.02,0),Vector3(width*.8,.2,.24),jacket.darkened(.08))
	S.rbox(chest,Vector3(0,.14,-.132),Vector3(.035,.3,.02),trim,Vector3.ZERO,.8)
	S.rbox(chest,Vector3(-.09,.2,-.125),Vector3(.1,.07,.03),S.SUIT_MID,Vector3.ZERO,.7)
	S.rbox(chest,Vector3(.1,.2,-.125),Vector3(.075,.045,.02),accent,Vector3.ZERO,.8)
	if medic:
		S.rbox(chest,Vector3(-.1,.21,-.14),Vector3(.07,.02,.01),Color("ff5a6a"));S.rbox(chest,Vector3(-.1,.21,-.14),Vector3(.02,.07,.01),Color("ff5a6a"))
	S.ell(chest,Vector3(0,.31,0),Vector3(.22,.09,.2),trim if not medic else main)
	for side in [-1,1]:
		var pad=Vector3(.2,.1,.2) if heavy else Vector3(.15,.08,.17)
		S.ell(chest,Vector3(side*.2,.29,0),pad,deep if not medic else main)
		S.rbox(chest,Vector3(side*.2,.33,-.02),Vector3(.1,.02,.06),accent,Vector3(0,0,side*-.3),.8)
	# Role silhouettes: back pieces are the first thing seen across a map.
	match role:
		0:S.rbox(chest,Vector3(0,.12,.15),Vector3(.24,.26,.1),S.SUIT_MID,Vector3.ZERO,.6)
		1:
			S.rbox(chest,Vector3(0,.1,.15),Vector3(.18,.22,.08),Color("5c7a45"),Vector3.ZERO,.6)
			S.cyl(chest,Vector3(.07,.3,.17),.012,.28,S.INK,Vector3(0,0,.1))
		2:
			S.rbox(chest,Vector3(0,.13,.17),Vector3(.32,.32,.14),S.SUIT_MID,Vector3.ZERO,.6)
			S.rbox(chest,Vector3(0,.16,-.15),Vector3(.3,.22,.06),light,Vector3.ZERO,.7)
			S.rbox(chest,Vector3(0,.16,-.182),Vector3(.2,.04,.01),accent,Vector3.ZERO,.8)
		3:
			S.rbox(chest,Vector3(0,.12,.16),Vector3(.26,.28,.12),S.SUIT_MID,Vector3.ZERO,.6)
			S.cyl(chest,Vector3(-.08,.32,.17),.035,.14,accent);S.cyl(chest,Vector3(.08,.32,.17),.035,.14,accent)
		4:S.ell(chest,Vector3(0,.14,.14),Vector3(.34,.36,.12),Color("6f5aa8"))
		5:
			S.rbox(chest,Vector3(0,.12,.15),Vector3(.22,.26,.1),S.WHITE,Vector3.ZERO,.6)
			S.rbox(chest,Vector3(0,.12,.205),Vector3(.08,.025,.01),Color("ff5a6a"));S.rbox(chest,Vector3(0,.12,.205),Vector3(.025,.08,.01),Color("ff5a6a"))
	# Head: large, round and friendly; painted eyes, brows and role headgear.
	head.scale=Vector3.ONE*HEAD_SCALE
	S.cyl(head,Vector3(0,.015,0),.046,.07,skin)
	S.ell(head,Vector3(0,.115,-.004),Vector3(.2,.22,.2),skin)
	S.ell(head,Vector3(0,.07,-.03),Vector3(.17,.13,.16),skin)
	for side in [-1,1]:
		S.ell(head,Vector3(side*.042,.118,-.088),Vector3(.036,.052,.016),S.INK)
		S.ell(head,Vector3(side*.037,.13,-.096),Vector3(.013,.015,.006),Color.WHITE)
		S.rbox(head,Vector3(side*.045,.162,-.09),Vector3(.048,.012,.012),hair.darkened(.15),Vector3(0,0,side*-.18),.9)
		S.ell(head,Vector3(side*.1,.108,-.008),Vector3(.026,.046,.036),skin.darkened(.05))
		S.ell(head,Vector3(side*.062,.083,-.083),Vector3(.03,.016,.01),Color("ff9f8f").lerp(skin,.35))
	S.ell(head,Vector3(0,.092,-.1),Vector3(.022,.02,.02),skin.darkened(.08))
	S.rbox(head,Vector3(0,.058,-.09),Vector3(.04,.01,.01),Color("9a4f4a"),Vector3.ZERO,.9)
	match role:
		0:
			S.ell(head,Vector3(0,.165,.01),Vector3(.222,.17,.222),main)
			S.rbox(head,Vector3(0,.2,-.098),Vector3(.18,.05,.04),Color("7fe8ff"),Vector3(-.35,0,0),.8)
			S.rbox(head,Vector3(0,.245,-.02),Vector3(.035,.035,.17),accent,Vector3.ZERO,.8)
		1:
			S.ell(head,Vector3(0,.162,.014),Vector3(.222,.19,.222),hair)
			S.ell(head,Vector3(-.03,.16,-.08),Vector3(.13,.06,.06),hair,Vector3(0,0,.3))
			S.ell(head,Vector3(0,.13,.12),Vector3(.08,.19,.08),hair,Vector3(.5,0,0))
			S.rbox(head,Vector3(0,.2,-.09),Vector3(.21,.042,.035),accent,Vector3(-.2,0,0),.8)
		2:
			S.rbox(head,Vector3(0,.155,.0),Vector3(.24,.21,.24),S.SUIT_MID,Vector3.ZERO,.75)
			S.rbox(head,Vector3(0,.13,-.114),Vector3(.2,.05,.02),Color("7fe8ff"),Vector3.ZERO,.8)
			S.rbox(head,Vector3(0,.24,0),Vector3(.07,.05,.24),main,Vector3.ZERO,.8)
		3:
			S.ell(head,Vector3(0,.19,.0),Vector3(.222,.12,.222),accent)
			S.rbox(head,Vector3(0,.175,-.105),Vector3(.16,.02,.11),accent.darkened(.2),Vector3(.2,0,0),.8)
			for side in [-1,1]:S.cyl(head,Vector3(side*.036,.212,-.098),.024,.02,Color("7fe8ff"),Vector3(PI/2,0,0))
		4:
			S.ell(head,Vector3(0,.158,.012),Vector3(.216,.18,.216),hair)
			S.ell(head,Vector3(.02,.222,0),Vector3(.24,.075,.23),accent,Vector3(0,0,-.2))
		5:
			S.ell(head,Vector3(0,.162,.014),Vector3(.222,.19,.222),hair)
			S.ell(head,Vector3(0,.25,.07),Vector3(.105,.105,.105),hair)
			S.ell(head,Vector3(.03,.16,-.082),Vector3(.12,.06,.06),hair,Vector3(0,0,-.3))
			S.rbox(head,Vector3(0,.205,-.08),Vector3(.2,.03,.04),accent,Vector3(-.15,0,0),.8)
	if female:
		for side in [-1,1]:S.ell(head,Vector3(side*.1,.1,-.002),Vector3(.034,.11,.055),hair)
	# Limbs: full sleeves, chunky gloves, cargo trousers and big boots.
	for side in [-1,1]:
		var prefix="Left" if side<0 else "Right"
		var arm=chest.get_node(prefix+"Arm");var elbow=arm.get_node("Elbow");var hand=elbow.get_node("Hand")
		S.ell(arm,Vector3(0,-.13,0),Vector3(.13 if heavy else .12,.31,.13 if heavy else .12),jacket)
		S.ell(elbow,Vector3(0,-.1,0),Vector3(.11,.24,.11),jacket.darkened(.06))
		S.cyl(elbow,Vector3(0,-.215,0),.06,.07,trim if not medic else accent)
		S.ell(hand,Vector3(0,-.035,-.01),Vector3(.115,.12,.1),S.SUIT)
		var leg=hips.get_node(prefix+"Leg");var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
		S.ell(leg,Vector3(0,-.2,0),Vector3(.19,.46,.19),pants)
		S.rbox(leg,Vector3(side*.09,-.22,0),Vector3(.05,.13,.12),pants.darkened(.2),Vector3.ZERO,.6)
		S.rbox(knee,Vector3(0,-.02,-.075),Vector3(.12,.11,.05),light if not medic else accent,Vector3(-.15,0,0),.7)
		S.ell(knee,Vector3(0,-.19,0),Vector3(.16,.4,.16),pants)
		S.rbox(foot,Vector3(0,.02,-.05),Vector3(.16,.15,.3),S.SUIT_MID,Vector3.ZERO,.7)
		S.rbox(foot,Vector3(0,-.05,-.05),Vector3(.17,.045,.31),S.WHITE,Vector3.ZERO,.6)
		S.rbox(foot,Vector3(0,.06,-.15),Vector3(.12,.035,.07),main,Vector3.ZERO,.8)
	S.finish(rig,outlined)
	return rig
