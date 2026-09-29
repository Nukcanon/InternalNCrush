class_name HeroModel
extends RefCounted
## Cartoon operators on the shared pose rig (same joints, sockets and clips as
## the current operators), so animation, weapon grips and hit volumes follow.
## Layered gear gives each role a distinct silhouette; HEAD_SCALE records the
## enlarged head so hit volumes can be scaled to match.
const S=preload("res://scripts/style/hero_style.gd")
const HEAD_SCALE=1.3
static func build(role:int,team:int,outlined:bool=false) -> Node3D:
	var rig=HumanModel.pose_rig(role)
	rig.name="HeroRig";rig.set_meta("hero_style",true);rig.set_meta("head_scale",HEAD_SCALE)
	var hips=rig.get_node("Hips");var chest=hips.get_node("Chest");var head=chest.get_node("Head")
	var c={"main":S.TEAM_MAIN[team],"light":S.TEAM_LIGHT[team],"deep":S.TEAM_DEEP[team],"accent":S.ROLE_ACCENT[role],"skin":S.SKIN[role],"hair":S.HAIR[role]}
	var medic=role==5
	c.jacket=S.ROLE_SUIT[role]
	c.pants=(S.ROLE_SUIT[role].darkened(.35) if not medic else Color("3e4760"))
	torso(chest,hips,role,c)
	face(head,role,c)
	for side in [-1,1]:limbs(chest,hips,side,role,c)
	S.finish(rig,outlined)
	return rig
static func torso(chest:Node3D,hips:Node3D,role:int,c:Dictionary):
	var heavy=role==2;var w=.45 if heavy else .4
	var plate=S.WHITE if role==5 else c.main
	# Pelvis: trousers, belt, buckle, utility pouches and front flap.
	S.ell(hips,Vector3(0,-.04,0),Vector3(.29,.24,.23),c.pants)
	S.rbox(hips,Vector3(0,.05,0),Vector3(.36,.07,.28),S.STRAP,Vector3.ZERO,.6)
	S.rbox(hips,Vector3(0,.05,-.14),Vector3(.075,.055,.02),S.METAL,Vector3.ZERO,.6)
	S.rbox(hips,Vector3(0,.05,-.152),Vector3(.03,.02,.01),c.accent,Vector3.ZERO,.9)
	for side in [-1,1]:
		S.rbox(hips,Vector3(side*.165,.0,-.03),Vector3(.08,.11,.13),S.SUIT_MID,Vector3.ZERO,.55)
		S.rbox(hips,Vector3(side*.165,.05,-.03),Vector3(.085,.03,.135),S.SUIT_MID.lightened(.12),Vector3.ZERO,.7)
		S.rbox(hips,Vector3(side*.08,.0,.13),Vector3(.09,.1,.05),S.SUIT_MID,Vector3.ZERO,.55)
	S.rbox(hips,Vector3(0,-.09,-.125),Vector3(.17,.14,.025),c.deep,Vector3(.1,0,0),.6)
	# Undersuit torso and waist.
	S.ell(chest,Vector3(0,.15,0),Vector3(w,.44,.28),c.jacket)
	S.ell(chest,Vector3(0,-.02,0),Vector3(w*.72,.2,.22),c.jacket.darkened(.1))
	# Armour vest: backing, front plate, seams, zipper and insignia.
	S.rbox(chest,Vector3(0,.17,-.1),Vector3(w*.74,.28,.08),c.deep,Vector3.ZERO,.75)
	S.rbox(chest,Vector3(0,.18,-.118),Vector3(w*.66,.24,.07),plate,Vector3.ZERO,.8)
	S.rbox(chest,Vector3(0,.075,-.153),Vector3(w*.62,.012,.01),c.deep,Vector3.ZERO,.9)
	S.rbox(chest,Vector3(0,.16,-.155),Vector3(.014,.25,.01),S.METAL,Vector3.ZERO,.9)
	S.rbox(chest,Vector3(-.085,.225,-.156),Vector3(.07,.045,.01),c.accent,Vector3.ZERO,.8)
	S.ell(chest,Vector3(.09,.225,-.155),Vector3(.035,.035,.012),c.light)
	for side in [-1,1]:
		S.rbox(chest,Vector3(side*.12,.03,-.13),Vector3(.075,.085,.05),S.SUIT_MID,Vector3.ZERO,.6)
		S.rbox(chest,Vector3(side*.12,.07,-.155),Vector3(.078,.02,.012),S.SUIT_MID.lightened(.15),Vector3.ZERO,.8)
		# Shoulder straps and two-layer pauldrons.
		S.rbox(chest,Vector3(side*.11,.3,0),Vector3(.055,.03,.3),S.STRAP,Vector3.ZERO,.5)
		var big=1.25 if heavy else 1.
		S.rbox(chest,Vector3(side*.205,.285,0),Vector3(.16,.06,.2)*big,plate,Vector3(0,0,side*-.38),.6)
		S.rbox(chest,Vector3(side*.228,.235,0),Vector3(.14,.05,.18)*big,c.deep,Vector3(0,0,side*-.5),.6)
		S.rbox(chest,Vector3(side*.2,.32,-.075),Vector3(.1,.018,.02),c.accent,Vector3(0,0,side*-.38),.8)
	S.ell(chest,Vector3(0,.31,0),Vector3(.22,.1,.2),c.jacket.darkened(.12))
	for side in [-1,1]:S.rbox(chest,Vector3(side*.055,.34,-.07),Vector3(.075,.06,.02),c.jacket,Vector3(-.3,side*.4,0),.7)
	# Role back pieces: the first thing read across a map.
	match role:
		0:
			S.rbox(chest,Vector3(0,.13,.16),Vector3(.26,.28,.1),S.SUIT_MID,Vector3.ZERO,.55)
			S.rbox(chest,Vector3(0,.2,.215),Vector3(.2,.08,.03),c.main,Vector3.ZERO,.7)
			for side in [-1,1]:S.cyl(chest,Vector3(side*.1,.05,.19),.035,.14,S.METAL)
		1:
			S.rbox(chest,Vector3(0,.11,.15),Vector3(.2,.24,.09),Color("58703f"),Vector3.ZERO,.55)
			S.rbox(chest,Vector3(0,.16,.2),Vector3(.16,.05,.02),Color("6d8a4e"),Vector3.ZERO,.7)
			S.cyl(chest,Vector3(.08,.34,.17),.01,.32,S.INK,Vector3(0,0,.12))
			S.ell(chest,Vector3(.1,.5,.17),Vector3(.025,.025,.025),c.accent)
		2:
			S.rbox(chest,Vector3(0,.13,.17),Vector3(.34,.33,.14),S.SUIT_MID,Vector3.ZERO,.5)
			for x in [-.09,0.,.09]:
				S.cyl(chest,Vector3(x,.16,.245),.028,.2,Color("262b38"))
				S.cyl(chest,Vector3(x,.16,.262),.018,.16,c.accent)
		3:
			S.rbox(chest,Vector3(0,.12,.16),Vector3(.26,.28,.12),S.SUIT_MID,Vector3.ZERO,.55)
			for side in [-1,1]:
				S.cyl(chest,Vector3(side*.07,.3,.17),.04,.16,c.accent)
				S.cyl(chest,Vector3(side*.07,.39,.17),.02,.03,S.METAL)
			S.cyl(chest,Vector3(.14,.02,.17),.018,.2,S.METAL,Vector3(0,0,.6))
		4:
			S.ell(chest,Vector3(0,.13,.14),Vector3(.36,.38,.12),Color("5d4c90"))
			S.rbox(chest,Vector3(0,.3,.14),Vector3(.3,.06,.12),Color("6d5aa8"),Vector3.ZERO,.7)
		5:
			S.rbox(chest,Vector3(0,.12,.15),Vector3(.24,.27,.11),S.WHITE,Vector3.ZERO,.55)
			S.rbox(chest,Vector3(0,.12,.21),Vector3(.085,.026,.01),Color("e04b5a"));S.rbox(chest,Vector3(0,.12,.21),Vector3(.026,.085,.01),Color("e04b5a"))
			S.rbox(chest,Vector3(-.085,.12,-.158),Vector3(.06,.018,.01),Color("e04b5a"));S.rbox(chest,Vector3(-.085,.12,-.158),Vector3(.018,.06,.01),Color("e04b5a"))
static func face(head:Node3D,role:int,c:Dictionary):
	head.scale=Vector3.ONE*HEAD_SCALE
	var skin:Color=c.skin;var hair:Color=c.hair;var female=role in HumanModel.FEMALE_ROLES
	S.cyl(head,Vector3(0,.015,0),.046,.07,skin.darkened(.05))
	S.ell(head,Vector3(0,.115,-.004),Vector3(.2,.22,.2),skin)
	S.ell(head,Vector3(0,.07,-.03),Vector3(.17,.13,.16),skin)
	for side in [-1,1]:
		S.ell(head,Vector3(side*.042,.118,-.088),Vector3(.036,.052,.016),S.INK)
		S.ell(head,Vector3(side*.037,.131,-.096),Vector3(.013,.015,.006),Color.WHITE)
		S.rbox(head,Vector3(side*.045,.163,-.09),Vector3(.05,.013,.012),hair.darkened(.2),Vector3(0,0,side*-.18),.9)
		S.ell(head,Vector3(side*.1,.108,-.008),Vector3(.026,.046,.036),skin.darkened(.06))
		S.ell(head,Vector3(side*.062,.084,-.083),Vector3(.03,.016,.01),Color("e8897c").lerp(skin,.45))
	S.ell(head,Vector3(0,.092,-.1),Vector3(.022,.02,.02),skin.darkened(.08))
	S.rbox(head,Vector3(0,.058,-.09),Vector3(.04,.01,.01),Color("8a4744"),Vector3.ZERO,.9)
	# Hair: cap plus tufts so the silhouette is not a plain sphere.
	if role!=2:
		S.ell(head,Vector3(0,.162,.014),Vector3(.222,.19,.222),hair)
		for i in range(5):
			var x=-.07+i*.035
			S.ell(head,Vector3(x,.19-absf(x)*.3,-.075),Vector3(.055,.07,.05),hair,Vector3(-.4,0,x*3.))
		S.ell(head,Vector3(0,.13,.08),Vector3(.2,.18,.12),hair)
	if female:
		for side in [-1,1]:S.ell(head,Vector3(side*.1,.09,-.0),Vector3(.036,.12,.06),hair)
	match role:
		0:
			S.ell(head,Vector3(0,.17,.012),Vector3(.23,.16,.23),c.main)
			S.rbox(head,Vector3(0,.155,-.105),Vector3(.2,.03,.05),c.deep,Vector3(-.1,0,0),.8)
			S.rbox(head,Vector3(0,.205,-.1),Vector3(.18,.05,.04),Color("6fd4ee"),Vector3(-.35,0,0),.8)
			S.rbox(head,Vector3(0,.252,-.01),Vector3(.035,.035,.18),c.accent,Vector3.ZERO,.8)
			S.cyl(head,Vector3(.115,.11,0),.035,.03,S.SUIT_MID,Vector3(0,0,PI/2))
			S.cyl(head,Vector3(.125,.18,.03),.006,.12,S.INK)
		1:
			S.ell(head,Vector3(0,.13,.13),Vector3(.085,.2,.085),hair,Vector3(.5,0,0))
			S.rbox(head,Vector3(0,.2,-.02),Vector3(.23,.022,.21),S.STRAP,Vector3(-.15,0,0),.7)
			for side in [-1,1]:
				S.cyl(head,Vector3(side*.042,.205,-.098),.03,.03,S.SUIT_MID,Vector3(PI/2-.3,0,0))
				S.cyl(head,Vector3(side*.042,.206,-.114),.022,.006,c.accent,Vector3(PI/2-.3,0,0))
		2:
			S.rbox(head,Vector3(0,.155,.0),Vector3(.24,.21,.24),S.SUIT_MID,Vector3.ZERO,.75)
			S.rbox(head,Vector3(0,.13,-.116),Vector3(.2,.05,.02),Color("6fd4ee"),Vector3.ZERO,.8)
			for y in [.06,.085]:S.rbox(head,Vector3(0,y,-.118),Vector3(.12,.01,.02),S.INK,Vector3.ZERO,.9)
			S.rbox(head,Vector3(0,.245,0),Vector3(.07,.05,.25),c.main,Vector3.ZERO,.8)
			for side in [-1,1]:S.cyl(head,Vector3(side*.122,.13,0),.04,.03,c.deep,Vector3(0,0,PI/2))
		3:
			S.ell(head,Vector3(0,.195,.0),Vector3(.225,.12,.225),c.accent)
			S.rbox(head,Vector3(0,.18,-.108),Vector3(.17,.02,.11),c.accent.darkened(.25),Vector3(.2,0,0),.8)
			S.ell(head,Vector3(0,.215,-.1),Vector3(.05,.03,.01),Color.WHITE)
			for side in [-1,1]:S.cyl(head,Vector3(side*.115,.12,0),.042,.03,S.SUIT_MID,Vector3(0,0,PI/2))
		4:
			S.ell(head,Vector3(.02,.224,0),Vector3(.25,.075,.235),c.accent.darkened(.2),Vector3(0,0,-.2))
			S.ell(head,Vector3(-.07,.24,-.07),Vector3(.03,.03,.012),Color("f2c03e"))
			S.strip(head,Vector3(.11,.12,0),Vector3(.07,.06,-.08),.012,.012,S.INK)
		5:
			S.ell(head,Vector3(0,.255,.07),Vector3(.11,.11,.11),hair)
			S.rbox(head,Vector3(0,.205,-.078),Vector3(.2,.03,.04),c.accent,Vector3(-.15,0,0),.8)
			S.rbox(head,Vector3(0,.22,-.1),Vector3(.03,.01,.01),Color("e04b5a"),Vector3.ZERO,.9);S.rbox(head,Vector3(0,.22,-.1),Vector3(.01,.03,.01),Color("e04b5a"),Vector3.ZERO,.9)
static func limbs(chest:Node3D,hips:Node3D,side:int,role:int,c:Dictionary):
	var prefix="Left" if side<0 else "Right";var heavy=role==2
	var arm=chest.get_node(prefix+"Arm");var elbow=arm.get_node("Elbow");var hand=elbow.get_node("Hand")
	S.ell(arm,Vector3(0,-.13,0),Vector3(.13 if heavy else .12,.31,.13 if heavy else .12),c.jacket)
	S.cyl(arm,Vector3(0,-.1,0),.064,.035,c.main if role!=5 else c.accent)
	S.rbox(arm,Vector3(side*.035,-.1,-.01),Vector3(.02,.05,.06),c.accent,Vector3.ZERO,.8)
	S.rbox(elbow,Vector3(0,.0,.045),Vector3(.085,.08,.05),S.SUIT_MID,Vector3.ZERO,.6)
	S.ell(elbow,Vector3(0,-.1,0),Vector3(.11,.24,.11),c.jacket.darkened(.08))
	S.cyl(elbow,Vector3(0,-.16,0),.06,.11,S.SUIT_MID)
	S.cyl(elbow,Vector3(0,-.18,0),.062,.02,c.accent)
	S.ell(hand,Vector3(0,-.035,-.01),Vector3(.115,.12,.1),S.SUIT)
	S.rbox(hand,Vector3(0,-.07,-.045),Vector3(.095,.03,.045),S.METAL,Vector3.ZERO,.7)
	S.cyl(hand,Vector3(0,.005,0),.058,.035,S.SUIT_MID)
	var leg=hips.get_node(prefix+"Leg");var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
	S.ell(leg,Vector3(0,-.2,0),Vector3(.19,.46,.19),c.pants)
	S.rbox(leg,Vector3(side*.09,-.22,.0),Vector3(.05,.14,.12),c.pants.darkened(.2),Vector3.ZERO,.6)
	S.rbox(leg,Vector3(side*.096,-.16,.0),Vector3(.052,.025,.12),c.pants.darkened(.3),Vector3.ZERO,.8)
	S.cyl(leg,Vector3(0,-.12,0),.098,.025,S.STRAP)
	if side>0:S.rbox(leg,Vector3(.085,-.1,-.035),Vector3(.05,.15,.08),S.STRAP,Vector3.ZERO,.6)
	S.rbox(knee,Vector3(0,-.02,-.078),Vector3(.125,.13,.05),c.light if role!=5 else c.accent,Vector3(-.15,0,0),.7)
	S.rbox(knee,Vector3(0,-.02,-.098),Vector3(.08,.03,.02),c.deep,Vector3(-.15,0,0),.8)
	S.ell(knee,Vector3(0,-.19,0),Vector3(.16,.4,.16),c.pants)
	S.cyl(knee,Vector3(0,-.33,0),.088,.14,S.SUIT_MID)
	S.rbox(foot,Vector3(0,.02,-.05),Vector3(.16,.15,.3),S.SUIT_MID,Vector3.ZERO,.7)
	S.rbox(foot,Vector3(0,-.055,-.05),Vector3(.175,.045,.32),S.INK,Vector3.ZERO,.6)
	S.rbox(foot,Vector3(0,.0,-.18),Vector3(.15,.09,.06),S.SUIT_MID.lightened(.1),Vector3.ZERO,.8)
	for i in range(3):S.rbox(foot,Vector3(0,.075-i*.02,-.1+i*.03),Vector3(.09,.012,.015),c.light,Vector3(.5,0,0),.9)
	S.rbox(foot,Vector3(0,.03,.1),Vector3(.12,.07,.03),c.main,Vector3.ZERO,.8)
