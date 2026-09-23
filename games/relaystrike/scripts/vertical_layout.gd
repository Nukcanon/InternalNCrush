extends RefCounted
class_name VerticalLayout
# Exactly one level arena remains in each supported player-count group.
const FLAT_MAPS=[0,4,10,13]
static func enabled(which:int) -> bool:return which not in FLAT_MAPS
static func build(a:Node,which:int):
	var b=a.bounds;var style=which%4
	var wall=[Color("aab9b5"),Color("c8b494"),Color("82999d"),Color("ba9c7d")][style]
	var trim=[Color("506f79"),Color("646e63"),Color("4f626d"),Color("796655")][style]
	var upper=4.2;var basement=-3.2;var half_tunnel=minf(13.,b.y*.23);var run=9.6
	var hole=Rect2(-5.,-half_tunnel-run,10.,(half_tunnel+run)*2.)
	a.floor_holes.append(hole)
	# Cut the ground slab around the descending service passage.
	for side in [-1,1]:
		a.box(Vector3(side*(b.x+5)*.5,-.5,0),Vector3(b.x-5,1,b.y*2),Color("b5b2a3"))
		a.box(Vector3(0,-.5,side*(b.y+hole.end.y)*.5),Vector3(10,1,b.y-hole.end.y),Color("b5b2a3"))
	deck(a,Vector3(0,basement,0),Vector2(10,half_tunnel*2),trim)
	stairs(a,Vector3(0,0,-half_tunnel-run*.5),Vector2(10,run),0.,basement,wall)
	stairs(a,Vector3(0,0,half_tunnel+run*.5),Vector2(10,run),basement,0.,wall)
	for side in [-1,1]:
		a.box(Vector3(side*5.25,-1.55,0),Vector3(.5,3.3,hole.size.y),wall)
		for z in [-half_tunnel*.65,0,half_tunnel*.65]:
			a.detail(Vector3(side*4.9,-.65,z),Vector3(.10,.16,1.6),Color("a2d6d5"))
			a.pipe(Vector3(side*4.75,-1.15,z),.085,5.,trim,Vector3(PI/2,0,0))
	# A roof over the middle creates a real underground route, with open stair portals.
	deck(a,Vector3(0,.15,0),Vector2(10,half_tunnel*1.15),wall)
	a.text3d("SERVICE / -1",Vector3(0,1.9,-hole.end.y-.4),Color("c8eadf"),27)
	var cx=b.x*.48;var depth=minf(20.,b.y*.55);var width=clampf(b.x*.30,10.,22.);var dz=minf(4.,b.y*.10)
	for side in [-1,1]:
		var center=Vector3(side*cx,upper,side*dz)
		deck(a,center,Vector2(width,depth),wall)
		# Ground-floor rooms, with full-width central doorways at both ends.
		for edge in [-1,1]:
			a.box(Vector3(center.x+edge*(width*.5-.25),1.9,center.z),Vector3(.5,3.8,depth),wall)
			for x in [-1,1]:a.box(Vector3(center.x+x*(width*.25+1.5),1.9,center.z+edge*(depth*.5-.25)),Vector3(width*.5-3.,3.8,.5),wall)
			# Each upper floor has two independent stair approaches.
			stairs(a,Vector3(center.x,0,center.z+edge*(depth*.5+run*.5)),Vector2(5.2,run),0. if edge<0 else upper,upper if edge<0 else 0.,trim)
			for x in [-1,1]:a.box(Vector3(center.x+x*(width*.25+1.65),upper+.5,center.z+edge*(depth*.5-.15)),Vector3(width*.5-3.3,1.,.3),trim)
			for z in [-1,1]:a.box(Vector3(center.x+edge*(width*.5-.3),upper+1.3,center.z+z*(depth*.5-2.)),Vector3(.6,2.6,.6),wall)
		# Partial upper roof leaves the firing balcony visible and usable.
		a.box(center+Vector3(side*width*.28,3.,0),Vector3(width*.46,.35,depth),trim)
		a.cover(center+Vector3(side*width*.25,0,side*2.7),minf(3.,width*.3))
		a.crate(Vector3(center.x-side*width*.23,0,center.z+side*depth*.22),Vector3(1.8,1.15,2.0))
		a.text3d("02 / "+("WEST" if side<0 else "EAST"),center+Vector3(0,1.8,-side*depth*.35),Color("e9d69e"),30)
		# Bent ground flanks, asymmetric visual masses paired by half-turn.
		var flank=Vector3(side*b.x*.76,0,-side*b.y*.40)
		a.container_box(flank,Color("648e8d") if style%2==0 else Color("b48d62"),minf(8.,b.x*.19))
		a.solid_rotated(Vector3(side*b.x*.23,.65,-side*b.y*.62),Vector3(4.,1.3,.7),wall,side*.4)
		for z in [-b.y*.68,b.y*.68]:a.detail(Vector3(side*b.x*.50,.018,z),Vector3(b.x*.6,.028,2.),trim)
		for n in range(8):
			var spawn=Vector3(lerpf(-b.x*.57,b.x*.57,n/7.),.12,side*(b.y-7.))
			a.spawn_points[0 if side<0 else 1].append(spawn);a.ffa_spawns.append(spawn)
	# Raised crossing and two dogleg connectors; the lower street remains open.
	var bridge_z=(2.5 if style in [0,2] else -2.5)
	if style in [0,1]:deck(a,Vector3(0,upper,bridge_z),Vector2(cx*2.+width*.25,4.6),trim)
	elif style==2:
		deck(a,Vector3(0,upper,0),Vector2(10.,12.),wall)
		for side in [-1,1]:deck(a,Vector3(side*cx*.5,upper,side*3.),Vector2(cx+width*.25,4.6),trim)
	else:
		deck(a,Vector3(0,upper,0),Vector2(4.6,13.),trim)
		for side in [-1,1]:deck(a,Vector3(side*cx*.5,upper,side*4.2),Vector2(cx+width*.25,4.6),trim)
	if style==1:
		deck(a,Vector3(0,upper,4.5),Vector2(cx*2.+width*.25,4.2),trim)
		a.navigation_goals.append(Vector3(0,upper,4.5))
	for side in [-1,1]:
		for x in [-cx*.65,cx*.65]:a.box(Vector3(x,upper*.5,(signf(x)*(3. if style==2 else 4.2) if style in [2,3] else bridge_z)+side*1.95),Vector3(.5,upper,.5),wall)
		for x in ([] if style in [2,3] else [-(cx-width*.5)*.5,(cx-width*.5)*.5]):a.box(Vector3(x,upper+.42,bridge_z+side*2.25),Vector3((cx-width*.5)*.70,.84,.22),wall)
		if style in [0,1]:a.detail(Vector3(0,upper+.015,bridge_z+side*1.65),Vector3(cx*2.,.03,.12),Color("d6b36e"))
	# On selected larger arenas, a second balcony makes a third playable level.
	if which in [1,2,5,6,15,16,18]:
		var x=-cx+width*.24;var z=-dz-3.;var high=7.4
		deck(a,Vector3(x,high,z),Vector2(5.4,6.),trim)
		stairs(a,Vector3(x,0,z+6.5),Vector2(4.8,7.),high,upper,wall)
		for side in [-1,1]:a.box(Vector3(x+side*2.55,high+.5,z),Vector3(.22,1.,5.6),wall)
		a.navigation_goals.append(Vector3(x,high,z))
	a.sites=[Vector3(-cx-2. if which in [1,2,5,6,15,16,18] else -cx,upper,-dz),Vector3(cx,upper,dz)]
	a.zones=[a.sites[0],Vector3(0,basement,0),a.sites[1]]
	a.navigation_goals.append_array([Vector3(0,upper,0 if style in [2,3] else bridge_z),Vector3(0,basement,0),a.sites[0],a.sites[1]])
	for side in [-1,1]:
		var landmark=Vector3(side*b.x*.80,0,side*b.y*.66)
		match style:
			0:
				for x in [-1.4,1.4]:a.detail(landmark+Vector3(x,6,0),Vector3(.4,12,.5),Color("b39a68"))
				a.detail(landmark+Vector3(-side*3,12,0),Vector3(10,.5,2.),Color("c3a467"))
			1:
				for x in [-1.6,0,1.6]:a.pipe(landmark+Vector3(x,3.5,0),.55,7,trim)
				a.detail(landmark+Vector3(0,7.1,0),Vector3(5,.4,2),wall)
			2:
				for z in [-2,0,2]:a.detail(landmark+Vector3(0,2.5,z),Vector3(3,5,2),wall,Vector3(.10,side*.2,.1))
			3:
				for z in [-2,2]:a.detail(landmark+Vector3(0,3,z),Vector3(5,.18,2.4),Color("9a765e"),Vector3(.15,0,0))
	a.has_water=false
	a.set_meta("vertical_levels",[-3.2,0.,4.2,7.4] if which in [1,2,5,6,15,16,18] else [-3.2,0.,4.2])
static func deck(a:Node,center:Vector3,size:Vector2,color:Color,navigation=true):
	a.box(center-Vector3.UP*.18,Vector3(size.x,.36,size.y),color)
	if navigation:a.walk_surfaces.append({"rect":Rect2(Vector2(center.x-size.x*.5,center.z-size.y*.5),size),"low":center.y,"high":center.y})
static func stairs(a:Node,center:Vector3,size:Vector2,low:float,high:float,color:Color):
	# A continuous collision slope supports smooth capsule movement; visible risers are 17.5 cm.
	var body=StaticBody3D.new();a.architecture.add_child(body);body.collision_layer=1;body.collision_mask=0
	var points=PackedVector3Array()
	for z in [-1,1]:
		for x in [-1,1]:
			points.append(center+Vector3(x*size.x*.5,minf(low,high)-.4,z*size.y*.5));points.append(center+Vector3(x*size.x*.5,low if z<0 else high,z*size.y*.5))
	var shape=ConvexPolygonShape3D.new();shape.points=points;var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	var count=ceili(absf(high-low)/.175)
	for i in range(count):
		var t=(i+.5)/count;var y=lerpf(low,high,t);var z=-size.y*.5+size.y*t
		a.detail(center+Vector3(0,y-.075,z),Vector3(size.x,.15,size.y/count+.015),color)
		for x in [-size.x*.45,size.x*.45]:a.detail(center+Vector3(x,y+.003,z),Vector3(.08,.022,size.y/count*.92),Color("d9bd83"))
	a.walk_surfaces.append({"rect":Rect2(Vector2(center.x-size.x*.5,center.z-size.y*.5),size),"low":low,"high":high})
	a.set_meta("stair_count",int(a.get_meta("stair_count",0))+1)

