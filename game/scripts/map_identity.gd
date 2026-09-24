extends RefCounted
class_name MapIdentity
# Exactly two rectangular competitive footprints per capacity tier; training is separate.
const RECTANGLES=[0,1,2,4,8,10,13,14,25,26]
const WINGS=[.48,.44,.50,.45,.48,.54,.43,.48,.45,.51,.48,.43,.46,.48,.51,.44,.48,.52,.45]
const DEPTHS=[.55,.50,.44,.52,.55,.43,.52,.47,.56,.43,.55,.47,.50,.55,.44,.52,.47,.43,.53]
static func perimeter(which:int,b:Vector2) -> PackedVector2Array:
	if which in RECTANGLES or which==31:return PackedVector2Array([Vector2(-b.x,-b.y),Vector2(b.x,-b.y),Vector2(b.x,b.y),Vector2(-b.x,b.y)])
	var east=.70+float(which%3)*.055;var west=.71+float((which+1)%3)*.055;var z=-.34+float(which%5)*.065
	var shape=PackedVector2Array([Vector2(-.72,-1),Vector2(.70,-1),Vector2(1,-.64),Vector2(1,z-.10),Vector2(east,z-.10),Vector2(east,z+.22),Vector2(.95,z+.38),Vector2(.95,.61),Vector2(.73,1),Vector2(-.72,1),Vector2(-1,.63),Vector2(-1,.32),Vector2(-west,.16),Vector2(-west,-.14),Vector2(-1,-.25),Vector2(-1,-.60)])
	for i in range(shape.size()):shape[i]*=b
	return shape
static func renew(a:Node):
	if a.map_index>=19:return
	var k=a.map_index;var roof=Color("536e7b");var stone=Color("acb5ad")
	a.set_meta("rectangular_footprint",k in RECTANGLES);a.set_meta("hybrid",true)
	if a.vertical_map:
		var wings=a.get_meta("main_wings",[])
		for center in wings:
			var side=signf(center.x);var third=Vector3(center.x+side*2.,8.4,center.z)
			# Stair runs on the second-storey deck, with a full 4.2m head clearance.
			VerticalLayout.deck(a,third+Vector3(0,0,-5.),Vector2(4.6,4.8),stone)
			VerticalLayout.stairs(a,Vector3(third.x,0,center.z+2.5),Vector2(3.6,10.),8.4,4.2,roof)
			if float(a.get_meta("wing_depth",20.))<15.:
				VerticalLayout.deck(a,Vector3(third.x,4.2,center.z+7.),Vector2(7.,6.),stone)
			for edge in [-1,1]:a.box(third+Vector3(edge*2.15,.5,-5.),Vector3(.28,1.,4.6),roof)
			a.box(third+Vector3(0,.5,-7.3),Vector3(4.5,1.,.28),roof)
			a.navigation_goals.append(third+Vector3(0,0,-5.))
			a.text3d("03 / "+["OBSERVATION","SERVICE","GALLERY","CONTROL"][k%4],third+Vector3(0,1.8,-6.),Color("d3decf"),27)
			# A short canopy shades the lower route without covering the third-floor firing deck.
			a.box(Vector3(center.x-side*3.5,3.2,center.z),Vector3(3.2,.25,5.+float(k%3)),roof)
			a.set_meta("vertical_levels",[-3.2,0.,4.2,8.4])
	else:
		# Flat arenas retain level gameplay, but alternate open courtyards and covered flanks.
		for side in [-1,1]:
			var point=Vector3(side*a.bounds.x*.58,0,side*a.bounds.y*.36)
			a.detail(point+Vector3.UP*4.8,Vector3(9,.28,7),roof)
			for x in [-4.,4.]:
				for z in [-3.,3.]:a.detail(point+Vector3(x,2.4,z),Vector3(.24,4.8,.24),roof)
	var identity=["PORT AUTHORITY","FREIGHT / 09","SMELTER WORKS","BIO RESEARCH","RELAY STATION","CANAL LOCK","TRANSIT AUTHORITY","CIVIC COURT","MOTOR WORKS","OLD QUARTER","ORCHARD CO-OP","GRID CONTROL","FOUNTAIN WALK","CARGO TRANSFER","NEUROSCIENCE","EAST FOUNDRY","SKYLINE ACCESS","MARKET DISTRICT","QUARRY OFFICE"][k]
	for side in [-1,1]:
		a.text3d(identity,Vector3(side*a.bounds.x*.62,3.,side*(a.bounds.y-3.)),Color("d9e2cf"),32)
