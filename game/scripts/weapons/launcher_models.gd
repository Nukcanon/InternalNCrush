class_name LauncherModels
extends RefCounted
## 1.4.1 cartoon rocket launchers, built in code (no Toon Shooter base): the
## single-tube shoulder COMET and the four-tube QUAD. Same frame as the baked
## guns (muzzle -Z, butt at the origin, markers RightGrip / LeftGrip / Muzzle /
## AimPoint). Loaded rockets are separate "Round<i>" nodes so the tubes show
## exactly how many rockets are left. Rockets point nose-first at the muzzle
## (-Z) and are loaded through the open rear end of their tube (root meta
## "rear": z of that opening).
const M=preload("res://scripts/mesh_factory.gd")
const DARK=Color("2e333d")
const STEEL=Color("5d6674")
const ACCENT=Color("f0c24f")
const BORE=Color("14171c")
const ROCKET_BODY=Color("9aa4ae")
const ROCKET_NOSE=Color("d9483b")
# Cylinders are built along +Y; FORWARD lays them along the barrel with their
# top (the narrow end of a cone) at the muzzle side, BACKWARD the other way.
const FORWARD=Vector3(-PI/2,0,0)
const BACKWARD=Vector3(PI/2,0,0)
static func build(kind:String) -> Node3D:
	var root=Node3D.new();root.name=kind
	var body=Node3D.new();body.name="Body";root.add_child(body)
	var rounds:Array=[];var markers={};var rear=0.;var grip=Vector3.ZERO;var fore=Vector3.ZERO
	match kind:
		"comet":
			# One fat tube over the shoulder: flared open rear, shoulder pad,
			# pistol grip, vertical foregrip and a folding sight on top.
			M.cylinder(body,Vector3(0,0,-.475),.065,.95,Color("56606c"),FORWARD,-1.,18)
			M.cylinder(body,Vector3(0,0,-.05),.088,.10,DARK,BACKWARD,.066,18)
			M.cylinder(body,Vector3(0,0,.0005),.058,.003,BORE,FORWARD,-1.,18)
			M.cylinder(body,Vector3(0,0,-.92),.082,.07,ACCENT,FORWARD,-1.,18)
			M.box(body,Vector3(0,-.09,-.30),Vector3(.10,.05,.24),DARK,Vector3.ZERO,.5)
			M.box(body,Vector3(0,-.15,-.44),Vector3(.05,.15,.065),DARK,Vector3(-.22,0,0),.5)
			M.box(body,Vector3(0,-.13,-.68),Vector3(.045,.12,.05),DARK,Vector3(.18,0,0),.5)
			# 1.4.5: a mount block joins the foregrip to the tube (it hung just
			# below it, rounded corners making a visible gap)
			M.box(body,Vector3(0,-.068,-.68),Vector3(.05,.03,.08),DARK,Vector3.ZERO,.25)
			M.box(body,Vector3(0,.095,-.55),Vector3(.03,.06,.08),DARK,Vector3.ZERO,.4)
			M.box(body,Vector3(0,.13,-.55),Vector3(.024,.018,.05),ACCENT,Vector3.ZERO,.3)
			M.box(body,Vector3(0,.075,-.30),Vector3(.06,.03,.16),STEEL,Vector3.ZERO,.5)
			trigger_guard(body,Vector3(0,-.075,-.44))
			# Seated with the nose tip just inside the muzzle.
			rounds.append(rocket(root,0,Vector3(0,0,-.66),.05,.30,.13))
			markers={"Muzzle":Vector3(0,0,-.95),"RightGrip":Vector3(0,-.15,-.44),"LeftGrip":Vector3(0,-.13,-.68),"AimPoint":Vector3(0,.145,-.55)}
			grip=Vector3(0,-.15,-.44);fore=Vector3(0,-.13,-.68)
			rear=0.
		_:
			# QUAD: four tubes in a square, open at the rear. The skeleton stock
			# runs under the tubes so nothing blocks the loading side.
			var c=.11 # height of the tube cluster's centre over the butt
			for i in range(4):
				var o=Vector3(-.05+.10*(i%2),c+.05-.10*(i/2),-.45)
				M.cylinder(body,o,.042,.62,Color("5c6b4a"),FORWARD,-1.,14)
				M.cylinder(body,Vector3(o.x,o.y,-.1295),.033,.003,BORE,FORWARD,-1.,14)
			M.box(body,Vector3(0,c,-.75),Vector3(.17,.17,.035),ACCENT,Vector3.ZERO,.4)
			M.box(body,Vector3(0,c,-.15),Vector3(.17,.17,.04),STEEL,Vector3.ZERO,.4)
			M.box(body,Vector3(0,c,-.45),Vector3(.05,.05,.56),DARK,Vector3.ZERO,.3)
			M.box(body,Vector3(0,c-.165,-.30),Vector3(.05,.15,.065),DARK,Vector3(-.22,0,0),.5)
			M.box(body,Vector3(0,c-.15,-.55),Vector3(.045,.11,.05),DARK,Vector3(.18,0,0),.5)
			M.box(body,Vector3(0,c-.098,-.55),Vector3(.05,.05,.08),DARK,Vector3.ZERO,.25) # 1.4.5: mount up to the lower tubes
			M.box(body,Vector3(0,c-.125,-.13),Vector3(.03,.03,.30),DARK,Vector3.ZERO,.3)
			M.box(body,Vector3(0,c-.155,.0),Vector3(.05,.11,.035),STEEL,Vector3.ZERO,.5)
			M.box(body,Vector3(0,c+.115,-.32),Vector3(.03,.06,.08),DARK,Vector3.ZERO,.4)
			M.box(body,Vector3(0,c+.15,-.32),Vector3(.024,.018,.05),ACCENT,Vector3.ZERO,.3)
			trigger_guard(body,Vector3(0,c-.09,-.30))
			for i in range(4):
				var o=Vector3(-.05+.10*(i%2),c+.05-.10*(i/2),-.54)
				rounds.append(rocket(root,i,o,.034,.22,.10))
			markers={"Muzzle":Vector3(0,c,-.78),"RightGrip":Vector3(0,c-.165,-.30),"LeftGrip":Vector3(0,c-.15,-.55),"AimPoint":Vector3(0,c+.165,-.32)}
			grip=Vector3(0,c-.165,-.30);fore=Vector3(0,c-.15,-.55)
			rear=-.13
	MeshFactory.merge_children(body)
	for name in markers:
		var m=Marker3D.new();m.name=name;m.position=markers[name];root.add_child(m)
	# Grips lean like their meshes: the pistol grip's bottom back, the vertical
	# foregrip's bottom forward. Shapes: half extents, rounding, trigger.
	root.get_node("RightGrip").rotation.x=-.22;root.get_node("LeftGrip").rotation.x=.18
	root.set_meta("grip_shapes",{"R":{"half":Vector3(.025,.075,.0325),"round":.015,"trigger":grip+Vector3(0,.06,-.05)},"L":{"half":Vector3(.0225,.06,.025),"round":.014}})
	root.set_meta("rounds",rounds.size());root.set_meta("rear",rear)
	return root
# Trigger blade and guard loop ahead of a pistol grip whose top is at `top`.
static func trigger_guard(body:Node3D,top:Vector3):
	M.box(body,top+Vector3(0,-.018,-.05),Vector3(.01,.03,.009),DARK,Vector3(.3,0,0),.3)
	M.box(body,top+Vector3(0,-.045,-.055),Vector3(.014,.008,.075),DARK,Vector3.ZERO,.3)
	M.box(body,top+Vector3(0,-.022,-.092),Vector3(.014,.05,.008),DARK,Vector3.ZERO,.3)
# A rocket centred on `seat`: body, nose cone toward the muzzle (-Z), fins at
# the tail. The node remembers its seat and how far it reaches ahead of /
# behind its origin, so the loading animation can feed it in from the rear.
static func rocket(parent:Node3D,index:int,seat:Vector3,radius:float,length:float,nose:float) -> Node3D:
	var node=Node3D.new();node.name="Round%d"%index;parent.add_child(node);node.position=seat
	parts(node,radius,length,nose)
	node.set_meta("seat",seat);node.set_meta("length",length+nose);node.set_meta("radius",radius);node.set_meta("front",length*.5+nose);node.set_meta("back",length*.5)
	return node
static func parts(node:Node3D,radius:float,length:float,nose:float):
	M.cylinder(node,Vector3.ZERO,radius,length,ROCKET_BODY,FORWARD,-1.,14)
	M.cylinder(node,Vector3(0,0,-length*.5-nose*.5),radius,nose,ROCKET_NOSE,FORWARD,radius*.12,14)
	M.cylinder(node,Vector3(0,0,length*.5-.012),radius*.72,.03,DARK,FORWARD,-1.,12)
	for side in range(3):
		var angle=side*TAU/3.
		M.box(node,Vector3(cos(angle)*radius*.9,sin(angle)*radius*.9,length*.38),Vector3(.012,radius*.9,.06),DARK,Vector3(0,0,angle),.2)
	MeshFactory.merge_children(node)
