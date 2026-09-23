extends RefCounted
class_name UrbanLayout
## Original compact combat spaces: bent lanes, terraces, roof access and courtyards.
static func build(a:Node,which:int):
	var b=a.bounds
	var sandstone=Color("c7b797") if which%2 else Color("afbdb8")
	var trim=Color("516772");var teal=Color("527e82");var rust=Color("a16d53")
	a.sites=[Vector3(-b.x*.44,0,-b.y*.16),Vector3(b.x*.44,0,b.y*.16)]
	a.zones=[a.sites[0],Vector3.ZERO,a.sites[1]]
	# Offset masses create different sight lines from each approach; 180-degree
	# rotational symmetry preserves equivalent team routes without a square arena.
	for side in [-1,1]:
		var p=Vector3(side*b.x*.32,0,side*b.y*.48)
		building(a,p,Vector3(b.x*.30,5.4,b.y*.18),sandstone,trim,side*.12)
		p=Vector3(side*b.x*.73,0,-side*b.y*.47)
		building(a,p,Vector3(b.x*.22,4.,b.y*.19),teal if side<0 else rust,trim,-side*.22)
		# Bent flank: a usable terrace with two sloped entrances, rather than a
		# decorative roof. The navigation grid samples the same physical height.
		var terrace=Vector3(side*b.x*.78,0,side*b.y*.025)
		var width=4.5;var depth=8.;var height=2.1 if which==16 else 1.65
		a.terrace(terrace,Vector2(width,depth),height,sandstone)
		a.ramp(terrace+Vector3(0,0,-depth*.5-3.5),Vector2(width,7.),0.,height,trim)
		a.ramp(terrace+Vector3(0,0,depth*.5+3.5),Vector2(width,7.),height,0.,trim)
		for dz in [-2.6,2.6]:a.cover(terrace+Vector3(side*.75,height,dz),2.2)
		# Narrow sight breaks leave the mid courtyard and both objectives clear.
		a.solid_rotated(Vector3(side*b.x*.17,.75,-side*b.y*.19),Vector3(4.,1.5,1.1),sandstone,side*.38)
		a.crate(Vector3(side*b.x*.34,0,-side*b.y*.37),Vector3(1.8,1.25,1.7))
		a.crate(Vector3(side*b.x*.34+1.7,0,-side*b.y*.37+.6),Vector3(1.2,.85,1.2))
		for z in [-b.y*.75,b.y*.75]:
			a.detail(Vector3(side*b.x*.42,.018,z),Vector3(b.x*.60,.025,3.),Color("a49e8e"),Vector3(0,side*.12,0))
		for x in [b.x*.1,b.x*.4]:
			a.pipe(Vector3(side*x,3.4,-side*b.y*.72),.055,6.8,trim)
			a.detail(Vector3(side*x,6.8,-side*b.y*.72),Vector3(1.1,.12,.32),Color("ebdec1"))
		if which==17:
			var stall=Vector3(side*b.x*.35,0,side*b.y*.20)
			a.box(stall+Vector3(0,.55,0),Vector3(3.,1.1,1.2),rust)
			for x in [-1.6,1.6]:a.box(stall+Vector3(x,1.5,0),Vector3(.12,3.,.12),trim)
			a.detail(stall+Vector3(0,3.05,0),Vector3(3.5,.12,2.),teal,Vector3(.12,0,0))
		elif which==16:
			a.box(Vector3(side*b.x*.34,.8,side*b.y*.22),Vector3(3.,1.6,2.),trim)
			for i in range(5):a.detail(Vector3(side*b.x*.34,1.64,side*b.y*.22-.65+i*.32),Vector3(2.8,.08,.08),sandstone)
	if which==16:
		a.terrace(Vector3.ZERO,Vector2(6.,6.),2.4,trim)
		a.ramp(Vector3(0,0,-7.),Vector2(5.,8.),0.,2.4,trim)
		a.ramp(Vector3(0,0,7.),Vector2(5.,8.),2.4,0.,trim)
		a.zones[1]=Vector3(0,2.4,0)
		for side in [-1,1]:
			a.pipe(Vector3(side*2.9,3.0,0),.05,5.,sandstone,Vector3(PI/2,0,0))
			for z in [-2.3,2.3]:a.pipe(Vector3(side*2.9,2.75,z),.05,.7,sandstone)
	elif which==9:
		for side in [-1,1]:
			a.solid_rotated(Vector3(side*2.2,1.7,side*b.y*.32),Vector3(8.,3.4,.65),rust,side*.42)
			a.detail(Vector3(side*2.2,3.47,side*b.y*.32),Vector3(8.2,.16,.95),trim,Vector3(0,side*.42,0))
	elif which==7:
		for side in [-1,1]:
			for x in [-4.4,4.4]:a.box(Vector3(x,2.2,side*(b.y*.73)),Vector3(.6,4.4,.75),sandstone)
			a.box(Vector3(0,4.25,side*b.y*.73),Vector3(9.4,.6,1.),sandstone)
			a.detail(Vector3(0,4.6,side*b.y*.73),Vector3(9.7,.12,1.3),trim)
	# Arc paving articulates the court while remaining traversable.
	for i in range(18):
		var angle=TAU*i/18.
		a.detail(Vector3(cos(angle)*4.,.025,sin(angle)*4.),Vector3(.75,.03,.22),Color("d4c9ae"),Vector3(0,-angle+PI/2,0))
	for team in [0,1]:
		var sign_z=-1 if team==0 else 1
		for n in range(7):a.spawn_points[team].append(Vector3(lerpf(-b.x+8,b.x-8,n/6.),.12,sign_z*(b.y-8)))
		var color=Color("48cfff") if team==0 else Color("ffb149")
		a.text3d("BLUE ENTRY" if team==0 else "ORANGE ENTRY",Vector3(0,3.,sign_z*(b.y-2)),color,32)
	for x in [-b.x*.55,0,b.x*.55]:
		for z in [-b.y*.7,0,b.y*.7]:
			var p=Vector3(x,.12,z)
			if a.point_clear(p):a.ffa_spawns.append(p)
static func building(a:Node,p:Vector3,size:Vector3,wall:Color,trim:Color,yaw:float):
	a.solid_rotated(p+Vector3.UP*size.y*.5,size,wall,yaw)
	var basis=Basis(Vector3.UP,yaw)
	a.detail(p+Vector3.UP*(size.y+.1),Vector3(size.x+.25,.22,size.z+.25),trim,Vector3(0,yaw,0))
	for side in [-1,1]:
		for i in range(maxi(2,int(size.x/2.))):
			var x=-size.x*.5+1.+i*(size.x-2.)/maxf(1.,int(size.x/2.)-1.)
			var at=p+basis*Vector3(x,size.y*.61,side*(size.z*.5+.035))
			a.detail(at,Vector3(.95,1.1,.06),trim,Vector3(0,yaw,0))
			a.detail(at+basis*Vector3(0,0,side*.04),Vector3(.79,.91,.02),Color("8fbbb9"),Vector3(0,yaw,0))
			a.detail(at+basis*Vector3(0,0,side*.06),Vector3(.055,.99,.025),wall,Vector3(0,yaw,0))
		a.detail(p+basis*Vector3(0,.24,side*(size.z*.5+.025)),Vector3(size.x,.48,.07),trim,Vector3(0,yaw,0))
	var sign_pos=p+basis*Vector3(0,size.y-.5,-size.z*.5-.06)
	a.detail(sign_pos,Vector3(size.x*.5,.38,.04),Color("be9c63"),Vector3(0,yaw,0))
