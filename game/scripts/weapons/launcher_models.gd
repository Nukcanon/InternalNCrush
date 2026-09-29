class_name LauncherModels
extends RefCounted
## 1.4.1 cartoon rocket launchers, built in code (no Toon Shooter base): the
## single-tube shoulder COMET and the four-tube QUAD. Same frame as the baked
## guns (muzzle -Z, butt at the origin, markers RightGrip / LeftGrip / Muzzle /
## AimPoint). Loaded rockets are separate "Round<i>" nodes so the tubes show
## exactly how many rockets are left, and the round being loaded can travel in.
const M=preload("res://scripts/mesh_factory.gd")
const DARK=Color("2e333d")
const STEEL=Color("5d6674")
const ACCENT=Color("f0c24f")
const ROCKET_BODY=Color("9aa4ae")
const ROCKET_NOSE=Color("d9483b")
static func build(kind:String) -> Node3D:
	var root=Node3D.new();root.name=kind
	var body=Node3D.new();body.name="Body";root.add_child(body)
	var rounds:Array=[];var markers={}
	match kind:
		"comet":
			# One fat tube over the shoulder: rear flare, shoulder pad, pistol grip,
			# vertical foregrip and a folding sight on top.
			M.cylinder(body,Vector3(0,0,-.475),.065,.95,Color("56606c"),Vector3(PI/2,0,0),-1.,18)
			M.cylinder(body,Vector3(0,0,-.05),.085,.10,DARK,Vector3(PI/2,0,0),.065,18)
			M.cylinder(body,Vector3(0,0,-.92),.082,.07,ACCENT,Vector3(PI/2,0,0),-1.,18)
			M.box(body,Vector3(0,-.09,-.30),Vector3(.10,.05,.24),DARK,Vector3.ZERO,.5)
			M.box(body,Vector3(0,-.15,-.44),Vector3(.05,.15,.065),DARK,Vector3(-.22,0,0),.5)
			M.box(body,Vector3(0,-.13,-.68),Vector3(.045,.12,.05),DARK,Vector3(.18,0,0),.5)
			M.box(body,Vector3(0,.095,-.55),Vector3(.03,.06,.08),DARK,Vector3.ZERO,.4)
			M.box(body,Vector3(0,.13,-.55),Vector3(.024,.018,.05),ACCENT,Vector3.ZERO,.3)
			M.box(body,Vector3(0,.075,-.30),Vector3(.06,.03,.16),STEEL,Vector3.ZERO,.5)
			rounds.append(rocket(root,0,Vector3(0,0,-.86),.05,.30,.13))
			markers={"Muzzle":Vector3(0,0,-.95),"RightGrip":Vector3(0,-.15,-.44),"LeftGrip":Vector3(0,-.13,-.68),"AimPoint":Vector3(0,.145,-.55)}
		_:
			# QUAD: four tubes in a square, a stock, pistol grip, foregrip and sight.
			M.box(body,Vector3(0,-.02,-.08),Vector3(.11,.13,.16),DARK,Vector3.ZERO,.5)
			for i in range(4):
				var o=Vector3(-.05+.10*(i%2),.05-.10*(i/2),-.47)
				M.cylinder(body,o,.042,.62,Color("5c6b4a"),Vector3(PI/2,0,0),-1.,14)
			M.box(body,Vector3(0,0,-.77),Vector3(.17,.17,.035),ACCENT,Vector3.ZERO,.4)
			M.box(body,Vector3(0,0,-.17),Vector3(.17,.17,.04),STEEL,Vector3.ZERO,.4)
			M.box(body,Vector3(0,-.165,-.30),Vector3(.05,.15,.065),DARK,Vector3(-.22,0,0),.5)
			M.box(body,Vector3(0,-.15,-.55),Vector3(.045,.11,.05),DARK,Vector3(.18,0,0),.5)
			M.box(body,Vector3(0,.115,-.32),Vector3(.03,.06,.08),DARK,Vector3.ZERO,.4)
			M.box(body,Vector3(0,.15,-.32),Vector3(.024,.018,.05),ACCENT,Vector3.ZERO,.3)
			for i in range(4):
				var o=Vector3(-.05+.10*(i%2),.05-.10*(i/2),-.72)
				rounds.append(rocket(root,i,o,.034,.22,.10))
			markers={"Muzzle":Vector3(0,0,-.80),"RightGrip":Vector3(0,-.165,-.30),"LeftGrip":Vector3(0,-.15,-.55),"AimPoint":Vector3(0,.165,-.32)}
	MeshFactory.merge_children(body)
	for name in markers:
		var m=Marker3D.new();m.name=name;m.position=markers[name];root.add_child(m)
	root.set_meta("rounds",rounds.size())
	return root
# A rocket (body + nose) centred on `seat`; the node remembers its seated
# position so the loading animation can slide it in from the front.
static func rocket(parent:Node3D,index:int,seat:Vector3,radius:float,length:float,nose:float) -> Node3D:
	var node=Node3D.new();node.name="Round%d"%index;parent.add_child(node);node.position=seat
	M.cylinder(node,Vector3.ZERO,radius,length,ROCKET_BODY,Vector3(PI/2,0,0),-1.,14)
	M.cylinder(node,Vector3(0,0,-length*.5-nose*.5),radius,nose,ROCKET_NOSE,Vector3(PI/2,0,0),0.,14)
	for side in range(3):
		var angle=side*TAU/3.
		M.box(node,Vector3(cos(angle)*radius*.9,sin(angle)*radius*.9,length*.38),Vector3(.012,radius*.9,.06),DARK,Vector3(0,0,angle),.2)
	MeshFactory.merge_children(node)
	node.set_meta("seat",seat);node.set_meta("length",length+nose)
	return node
