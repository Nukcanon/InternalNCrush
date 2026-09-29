class_name HeroWeapon
extends RefCounted
## Chunky toy-like weapon silhouettes (muzzle toward -Z, grip at origin).
const S=preload("res://scripts/style/hero_style.gd")
const BODY=Color("eef1f5")
const DARK=Color("2e3547")
const MID=Color("5b6478")
const GLOW=Color("5ff0e0")
static func build(kind:String,accent:Color=Color("ff8a2e")) -> Node3D:
	var root=Node3D.new();root.name="HeroWeapon_"+kind
	match kind:
		"rifle":
			S.rbox(root,Vector3(0,.03,-.16),Vector3(.085,.12,.36),BODY)
			S.rbox(root,Vector3(0,.10,-.2),Vector3(.04,.03,.26),DARK)
			S.rbox(root,Vector3(0,.03,-.37),Vector3(.075,.085,.12),accent)
			S.cyl(root,Vector3(0,.035,-.5),.022,.2,DARK,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.035,-.61),.034,.05,accent,Vector3(PI/2,0,0))
			S.rbox(root,Vector3(0,-.08,-.14),Vector3(.06,.16,.075),accent,Vector3(-.25,0,0))
			S.rbox(root,Vector3(0,-.06,.0),Vector3(.05,.12,.06),DARK,Vector3(.35,0,0))
			S.rbox(root,Vector3(0,.0,.14),Vector3(.065,.1,.2),MID)
			S.ell(root,Vector3(0,.135,-.12),Vector3(.05,.05,.1),DARK)
			S.ell(root,Vector3(0,.135,-.17),Vector3(.035,.035,.01),GLOW)
			S.rbox(root,Vector3(.045,.04,-.2),Vector3(.01,.02,.12),GLOW)
		"shotgun":
			S.rbox(root,Vector3(0,.035,-.12),Vector3(.11,.14,.3),BODY)
			S.cyl(root,Vector3(0,.07,-.42),.045,.34,DARK,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,-.01,-.38),.04,.26,MID,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,-.01,-.36),.052,.12,accent,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.07,-.6),.056,.04,accent,Vector3(PI/2,0,0))
			S.rbox(root,Vector3(0,-.07,.0),Vector3(.055,.13,.065),DARK,Vector3(.35,0,0))
			S.rbox(root,Vector3(0,.0,.14),Vector3(.075,.11,.2),accent.darkened(.3))
			for i in range(3):S.ell(root,Vector3(.058,.035,-.06-i*.05),Vector3(.02,.03,.03),Color("ff5a6a"))
		"sniper":
			S.rbox(root,Vector3(0,.03,-.14),Vector3(.075,.11,.4),BODY)
			S.cyl(root,Vector3(0,.04,-.6),.02,.55,DARK,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.04,-.88),.03,.07,accent,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.14,-.16),.035,.28,DARK,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.14,-.31),.045,.03,accent,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.14,-.327),.036,.006,GLOW,Vector3(PI/2,0,0))
			S.rbox(root,Vector3(0,-.07,-.02),Vector3(.05,.13,.06),DARK,Vector3(.35,0,0))
			S.rbox(root,Vector3(0,-.0,.17),Vector3(.07,.13,.26),accent)
			S.rbox(root,Vector3(0,-.08,-.2),Vector3(.05,.1,.06),MID)
		"pistol":
			S.rbox(root,Vector3(0,.06,-.07),Vector3(.07,.1,.2),BODY)
			S.cyl(root,Vector3(0,.075,-.2),.028,.08,accent,Vector3(PI/2,0,0))
			S.rbox(root,Vector3(0,-.04,.01),Vector3(.055,.13,.07),DARK,Vector3(.3,0,0))
			S.ell(root,Vector3(0,.12,-.05),Vector3(.035,.02,.08),GLOW)
		"launcher":
			S.cyl(root,Vector3(0,.07,-.2),.075,.7,Color("7a8a4a"),Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.07,-.56),.09,.06,accent,Vector3(PI/2,0,0))
			S.cyl(root,Vector3(0,.07,.16),.085,.06,accent,Vector3(PI/2,0,0))
			S.rbox(root,Vector3(0,-.05,-.05),Vector3(.05,.13,.06),DARK,Vector3(.3,0,0))
			S.rbox(root,Vector3(.09,.12,-.12),Vector3(.05,.07,.12),DARK)
	S.finish(root,false,.6)
	return root
