extends RefCounted
class_name MapLayouts
static func room(a:Node,pos:Vector3,color:Color,size=Vector2(34,32)):
	for x in [-1,1]:
		for z in [-1,1]:a.box(pos+Vector3(x*size.x*.5,3,z*(size.y*.25+2)),Vector3(.7,6,size.y*.5-4),color)
	for z in [-1,1]:
		for x in [-1,1]:a.box(pos+Vector3(x*(size.x*.25+2),3,z*size.y*.5),Vector3(size.x*.5-4,6,.7),color)
		for x in [-4.3,4.3]:a.detail(pos+Vector3(x,2.2,z*size.y*.5),Vector3(.3,4.4,1),Color("566b75"))
		a.box(pos+Vector3(0,5.3,z*size.y*.5),Vector3(8,1.4,.7),color)
	a.detail(pos+Vector3(0,6.2,0),Vector3(size.x+1,.4,size.y+1),color.darkened(.28))
static func tank(a:Node,p:Vector3):
	a.box(p+Vector3(0,2,0),Vector3(4,4,4),Color("829b9d"))
	MeshFactory.cylinder(a.architecture,p+Vector3(0,4.1,0),2.,.8,Color("adc1c0"),Vector3.ZERO,1.3,16)
	for h in [1.,3.]:MeshFactory.cylinder(a.architecture,p+Vector3(0,h,0),2.04,.12,Color("4b6671"),Vector3.ZERO,-1,16)
static func build(a:Node,which:int):
	var indoor=which in [2,3]
	if indoor:
		for x in [-98,98]:a.box(Vector3(x,4.5,0),Vector3(2,9,178),Color("75858c"))
		for z in [-88,88]:a.box(Vector3(0,4.5,z),Vector3(198,9,2),Color("75858c"))
		for x in [-75,-25,25,75]:a.detail(Vector3(x,10.6,0),Vector3(42,.5,176),Color("465962") if which==2 else Color("acb9bd"))
		for x in [-85,-45,0,45,85]:
			for z in [-65,-32,0,32,65]:
				a.detail(Vector3(x,9.8,z),Vector3(7,.1,.5),Color("e2f2e8"))
				if x!=0 and z!=0:a.box(Vector3(x,4.6,z),Vector3(1.2,9.2,1.2),Color("536c76"))
	match which:
		2:
			for sx in [-1,1]:
				for sz in [-1,1]:
					var p=Vector3(sx*34,0,sz*44)
					a.box(p+Vector3(0,1.2,0),Vector3(14,2.4,10),Color("657f85"))
					a.detail(p+Vector3(0,2.6,0),Vector3(12,.35,8),Color("b6bcb4"))
					for k in [-4,0,4]:a.pipe(p+Vector3(k,3,0),.45,8,Color("6a9b9d"),Vector3(PI/2,0,0))
					tank(a,Vector3(sx*73,0,sz*48));a.crate(Vector3(sx*58,0,sz*10),Vector3(4,1.7,4))
				for z in [-48,0,48]:a.cover(Vector3(sx*15,0,z),6)
				for z in [-56,0,56]:a.pipe(Vector3(0,9.4,z),.4,185,Color("cc9e53"),Vector3(0,0,PI/2))
				a.detail(Vector3(sx*50,.02,0),Vector3(52,.025,12),Color("8a9999"))
			for x in [-66,66]:a.box(Vector3(x,1.3,0),Vector3(8,2.6,8),Color("446978"))
		3:
			for sx in [-1,1]:
				for sz in [-1,1]:
					var p=Vector3(sx*47,0,sz*40);room(a,p,Color("c8d9d6"),Vector2(42,36))
					for x in [-10,10]:
						a.box(p+Vector3(x,.75,5),Vector3(5,1.5,3),Color("789296"));a.detail(p+Vector3(x,1.57,5),Vector3(5.2,.14,3.2),Color("e2e7dc"))
						a.detail(p+Vector3(x,2.,5.4),Vector3(1.4,.9,.14),Color("3b7484"))
					a.box(p+Vector3(-14,1.4,-9),Vector3(3,2.8,5),Color("506e7b"))
					a.detail(p+Vector3(-14,1.4,-11.54),Vector3(2.4,2.3,.06),Color("77b4b6"))
					a.text3d("LAB 0"+str(1+(1 if sx>0 else 0)+(2 if sz>0 else 0)),p+Vector3(0,4.6,-18.5),Color("f1f8e8"),40)
			for z in [-50,0,50]:a.cover(Vector3(0,0,z),7)
			for x in [-78,78]:a.crate(Vector3(x,0,0),Vector3(4,1.5,7))
		4:
			for sx in [-1,1]:
				for sz in [-1,1]:
					var p=Vector3(sx*49,0,sz*48);room(a,p,Color("c69b70"),Vector2(32,28))
					for x in [-10,10]:a.detail(p+Vector3(x,6.8,0),Vector3(.8,1,28),Color("986d4e"))
					a.container_box(Vector3(sx*77,0,sz*28),Color("80989a"),11)
					for k in range(3):
						var r=Vector3(sx*(85+k*3),0,sz*(58+k*5));a.box(r+Vector3(0,1,0),Vector3(4,2,5),Color("aa8462"));MeshFactory.sphere(a.architecture,r+Vector3(0,2,0),Vector3(6,5+k,7),Color("b89a74"))
					a.cover(Vector3(sx*22,0,sz*20),7)
				for z in [-12,12]:a.crate(Vector3(sx*54,0,z),Vector3(4,1.5,5))
				a.pipe(Vector3(sx*89,8,0),.4,16,Color("b9c8c3"));MeshFactory.sphere(a.architecture,Vector3(sx*89,14,0),Vector3(5,3,5),Color("d7e0d7"))
		5:
			for sx in [-1,1]:
				for sz in [-1,1]:
					var p=Vector3(sx*50,0,sz*48);room(a,p,Color("d2c5aa") if sx<0 else Color("a7c0c1"),Vector2(36,28))
					for h in [2.,4.5]:
						for x in [-12,-8,8,12]:a.detail(p+Vector3(x,h,-14.4),Vector3(2.3,1.7,.2),Color("547485"))
					a.detail(p+Vector3(0,4.,-17),Vector3(14,.2,5),Color("5d9188"))
					a.crate(Vector3(sx*72,0,sz*20),Vector3(5,1.7,4));a.cover(Vector3(sx*26,0,sz*17),6)
					for x in [74,87]:a.tree(Vector3(sx*x,0,sz*65))
				for z in [-16,16]:a.cover(Vector3(sx*52,0,z),6)
			a.make_water()
			for z in [-27,0,27]:a.bridge(z)
	for side in [0,1]:
		for x in [-76,-54,-30,0,30,54,76]:a.spawn_points[side].append(Vector3(x,.1,-77 if side==0 else 77))
	for x in [-80,-46,0,46,80]:
		for z in [-76,-14,14,76]:
			var point=Vector3(x,.1,z)
			if a.point_clear(point):a.ffa_spawns.append(point)

static func finish_detail(a:Node,which:int):
	# Original modular architecture: real proportions, framing, service details and landmarks.
	if which in [2,3]:
		for x in [-4.1,4.1]:a.detail(Vector3(x,10.6,0),Vector3(.28,.7,176),Color("627d86"))
		for z in range(-80,81,10):
			a.detail(Vector3(0,10.5,z),Vector3(9,.25,.3),Color("78939b"))
			for x in [-74,74]:
				a.pipe(Vector3(x,8.7,z),.08,2.2,Color("516c75"));a.detail(Vector3(x,7.6,z),Vector3(3.2,.18,1.3),Color("eff3cd"))
		for side in [-1,1]:
			for z in range(-70,71,10):
				a.detail(Vector3(side*97.2,2.8,z),Vector3(.25,2.1,6),Color("466a7a"));a.detail(Vector3(side*97,2.8,z),Vector3(.2,.09,6.1),Color("afc5bf"))
			for x in [-70,0,70]:
				a.detail(Vector3(x,2.7,side*86.6),Vector3(5.5,5.4,.18),Color("405c69"))
				for y in range(1,6):a.detail(Vector3(x,y,side*86.4),Vector3(5.4,.045,.04),Color("8b9b97"))
		if which==2:
			for z in [-35,35]:
				a.detail(Vector3(0,8.2,z),Vector3(130,1.,1.1),Color("ba8b41"))
				for x in [-60,60]:a.detail(Vector3(x,4.1,z),Vector3(1,8.2,1),Color("677e85"))
				a.pipe(Vector3(12,6.2,z),.06,3.,Color("344c57"));a.pipe(Vector3(12,4.8,z),.25,.25,Color("e4b756"))
			for sx in [-1,1]:
				for sz in [-1,1]:
					var pos=Vector3(sx*34,0,sz*44)
					for x in [-4,0,4]:
						a.detail(pos+Vector3(x,1.25,-5.08),Vector3(3.4,1.8,.12),Color("3e5e69"))
						for y in [.8,1.1,1.4]:a.detail(pos+Vector3(x,y,-5.16),Vector3(2.4,.07,.035),Color("8da6a3"))
					a.detail(pos+Vector3(5,2.1,-5.4),Vector3(2,.8,.2),Color("a9bbb6"),Vector3(-.3,0,0));a.detail(pos+Vector3(5,2.2,-5.56),Vector3(1.3,.35,.035),Color("467f8e"))
	else:
		for sx in [-1,1]:
			for sz in [-1,1]:
				var pos=Vector3(sx*(50 if which==5 else 49),0,sz*48)
				if which<4:pos=Vector3(sx*43,0,sz*51)
				if which>=4:
					var width=36 if which==5 else 32;var facade=Color("c6b89c") if which==5 else Color("c49973")
					a.detail(pos+Vector3(0,7.6,0),Vector3(width,2.9,28),facade);a.detail(pos+Vector3(0,9.15,0),Vector3(width+1,.3,29),Color("768a87") if which==5 else Color("ac7953"))
					for side in [-1,1]:
						for x in [-12,-6,0,6,12]:
							a.detail(pos+Vector3(x,7.7,side*14.15),Vector3(2.6,1.7,.18),Color("e2dcca"));a.detail(pos+Vector3(x,7.7,side*14.27),Vector3(2.2,1.38,.10),Color("3c6375"));a.detail(pos+Vector3(x,7.7,side*14.34),Vector3(.07,1.4,.04),Color("b2c1b9"))
					for x in [-width*.5,width*.5]:a.pipe(pos+Vector3(x,3.,14.5),.11,6.,Color("647d80"))
					for x in [-6,6]:
						a.detail(pos+Vector3(x,9.65,0),Vector3(3,1,2.8),Color("9ca9a3"))
						for z in [-.8,-.4,0,.4,.8]:a.detail(pos+Vector3(x,10.17,z),Vector3(2.6,.025,.07),Color("4d6872"))
				if which==5:
					var lamp=Vector3(sx*18,0,sz*49);a.pipe(lamp+Vector3(0,2.6,0),.09,5.2,Color("4d6976"));a.detail(lamp+Vector3(-sx*.8,5.2,0),Vector3(1.8,.1,.15),Color("4d6976"));a.detail(lamp+Vector3(-sx*1.45,5.1,0),Vector3(.75,.12,.5),Color("ebdfb1"))
		if which==5:
			for x in [-12,12]:a.detail(Vector3(x,.04,0),Vector3(4,.08,65),Color("c5c6b3"))
			for z in [-27,0,27]:
				for x in [-7,-3,3,7]:a.detail(Vector3(x,.615,z),Vector3(.045,.02,4.5),Color("788e90"))
		for z in range(-74,75,8):
			for x in [-78,78]:a.detail(Vector3(x,.024,z),Vector3(.14,.02,3),Color("e1d7ab"))

static func extent(which:int) -> Vector2:
	if which<6:return Vector2(100,90)
	if which==6:return Vector2(72,64)
	return Vector2(26,30) if which<13 else Vector2(36,42)

# Each row is a distinct layout: normalized x/z center and width/depth.
# Coordinates reserve a central crossing, side routes and objective pockets.
const SIZED_LAYOUTS=[
	[[.35,.55,.32,.10],[-.35,-.55,.32,.10],[-.68,.30,.10,.35],[.68,-.30,.10,.35],[.23,-.30,.12,.22],[-.23,.30,.12,.22]],
	[[.48,.42,.28,.12],[-.48,-.42,.28,.12],[.55,-.45,.13,.24],[-.55,.45,.13,.24]],
	[[-.43,-.44,.38,.12],[.43,.44,.38,.12],[-.60,.3,.13,.25],[.60,-.3,.13,.25]],
	[[-.4,-.45,.46,.10],[.4,-.05,.46,.10],[-.4,.40,.46,.10],[.6,.48,.12,.13]],
	[[-.57,-.50,.15,.17],[.57,.50,.15,.17],[-.57,.10,.15,.17],[.57,-.10,.15,.17],[-.12,.48,.14,.15],[.12,-.48,.14,.15]],
	[[-.53,-.34,.18,.38],[.53,.34,.18,.38],[.45,-.53,.3,.10],[-.45,.53,.3,.10]],
	[[-.35,-.42,.18,.14],[.35,.42,.18,.14],[-.60,.25,.14,.16],[.60,-.25,.14,.16]],
	[[-.55,-.45,.40,.11],[.4,-.12,.35,.11],[-.4,.12,.35,.11],[.55,.45,.40,.11],[.63,-.52,.12,.16],[-.63,.52,.12,.16]],
	[[-.53,-.40,.12,.34],[.53,.40,.12,.34],[-.23,-.54,.35,.1],[.23,.54,.35,.1],[-.64,.4,.20,.12],[.64,-.4,.20,.12]],
	[[-.50,-.45,.27,.18],[.50,.45,.27,.18],[-.60,.35,.18,.2],[.60,-.35,.18,.2],[.15,-.5,.10,.28],[-.15,.5,.10,.28]],
	[[-.54,-.45,.32,.12],[.54,.45,.32,.12],[-.56,.40,.15,.20],[.56,-.40,.15,.20],[.30,.04,.10,.20],[-.30,-.04,.10,.20]],
	[[-.56,-.44,.18,.21],[.56,.44,.18,.21],[-.56,.44,.18,.21],[.56,-.44,.18,.21],[-.25,-.48,.14,.12],[.25,.48,.14,.12]],
	[[-.50,-.48,.32,.23],[.50,.48,.32,.23],[-.64,.30,.12,.28],[.64,-.30,.12,.28],[-.22,.35,.12,.15],[.22,-.35,.12,.15]]
]
static func build_sized(a:Node,which:int):
	var b=a.bounds;var theme=(which-6)%6
	var walls=[Color("c2c9c8"),Color("cdbb9a"),Color("aabec7"),Color("b1b7a2"),Color("c8bbac"),Color("c1d0cb")]
	var accent=[Color("63899a"),Color("b19762"),Color("789794"),Color("82926c"),Color("aa8866"),Color("698f9a")]
	a.sites=[Vector3(-b.x*.44,0,-b.y*.16),Vector3(b.x*.44,0,b.y*.16)]
	a.zones=[a.sites[0],Vector3.ZERO,a.sites[1]]
	for x in [-b.x*.72,0,b.x*.72]:a.detail(Vector3(x,.016,0),Vector3(3,.025,b.y*2-5),walls[theme].darkened(.12))
	for z in [-b.y*.66,0,b.y*.66]:a.detail(Vector3(0,.018,z),Vector3(b.x*2-4,.027,3),walls[theme].darkened(.12))
	var index=0
	for row in SIZED_LAYOUTS[which-6]:
		var pos=Vector3(row[0]*b.x,0,row[1]*b.y);var size=Vector3(row[2]*b.x,1.6 if index%3==0 else 3.2,row[3]*b.y)
		var too_close=false
		for objective in a.zones:
			if Rect2(Vector2(pos.x-size.x*.5,pos.z-size.z*.5),Vector2(size.x,size.z)).grow(3.5).has_point(Vector2(objective.x,objective.z)):too_close=true
		if too_close:pos.z+=signf(pos.z if pos.z!=0 else 1.)*4.
		if theme in [0,2]:
			a.box(pos+Vector3.UP*size.y*.5,size,accent[theme]);a.detail(pos+Vector3(0,size.y+.10,0),Vector3(size.x+.15,.20,size.z+.15),walls[theme])
			for x in [-size.x*.35,size.x*.35]:a.detail(pos+Vector3(x,size.y*.5,-size.z*.5-.025),Vector3(.08,size.y-.2,.07),Color("e0dcc7"))
		elif theme==1 or theme==4:a.crate(pos,size)
		else:
			a.box(pos+Vector3.UP*size.y*.5,size,accent[theme]);a.detail(pos+Vector3(0,size.y+.12,0),Vector3(size.x*.92,.22,size.z*.92),Color("99ae83") if theme==3 else walls[theme])
		index+=1
	# Distinct center landmarks preserve the crossing underneath.
	if which in [6,8,14,15]:
		for side in [-1,1]:
			a.box(Vector3(side*b.x*.78,3.5,0),Vector3(1.,7.,1.),accent[theme]);a.detail(Vector3(side*b.x*.40,7.2,0),Vector3(b.x*.8,.45,1.2),accent[theme])
	elif which==12:
		for side in [-1,1]:a.box(Vector3(side*5,.5,0),Vector3(1.5,1.,4.5),Color("b2c9ce"))
	elif which==10:
		for x in [-b.x*.78,b.x*.78]:
			for z in [-b.y*.42,b.y*.42]:a.tree(Vector3(x,0,z))
	elif which==16:
		for side in [-1,1]:a.pipe(Vector3(side*b.x*.65,1.1,side*b.y*.55),.35,2.2,Color("91a8ad"))
	if a.indoors:
		for x in [-b.x*.55,b.x*.55]:a.detail(Vector3(x,7.8,0),Vector3(b.x*.8,.4,b.y*2),walls[theme].darkened(.15))
		for z in [-b.y*.6,0,b.y*.6]:a.detail(Vector3(0,7.8,z),Vector3(b.x*2,.45,.6),accent[theme])
		for x in [-b.x*.58,b.x*.58]:
			for z in [-b.y*.55,0,b.y*.55]:a.detail(Vector3(x,7.5,z),Vector3(3.5,.08,.45),Color("f1f4dd"))
	else:
		for side in [-1,1]:
			a.detail(Vector3(side*(b.x+4),5,0),Vector3(5,10,b.y*.7),walls[theme]);a.detail(Vector3(0,6,side*(b.y+4)),Vector3(b.x*.75,12,5),walls[theme])
	for team in [0,1]:
		var side=-1 if team==0 else 1
		for n in range(7):a.spawn_points[team].append(Vector3(lerpf(-b.x+8,b.x-8,n/6.),.12,side*(b.y-8)))
		var color=Color("48cfff") if team==0 else Color("ffb149")
		a.text3d("BLUE" if team==0 else "ORANGE",Vector3(0,3.8,side*(b.y-2)),color,42)
		a.detail(Vector3(0,.03,side*(b.y-6)),Vector3(b.x*2-6,.04,.22),color)
	for x in [-b.x*.72,0,b.x*.72]:
		for z in [-b.y*.7,0,b.y*.7]:
			var pos=Vector3(x,.12,z)
			if a.point_clear(pos):a.ffa_spawns.append(pos)
