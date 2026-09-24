extends RefCounted
class_name PracticeLayout
const INDEX=31
static func build(a:Node):
	a.bounds=Vector2(44,48);a.has_water=false;a.indoors=false;a.vertical_map=true;a.set_meta("night",false)
	a.box(Vector3(0,-.4,0),Vector3(88,.8,96),Color("a2acaa"));a.build_perimeter(INDEX)
	var concrete=Color("b8b5a5");var trim=Color("536e7b")
	# Outdoor range, side service galleries and three genuinely walkable stories.
	for floor in [4.2,8.4,12.6]:
		for side in [-1,1]:
			var center=Vector3(side*25.,floor,0)
			VerticalLayout.deck(a,center,Vector2(14,42),concrete)
			for edge in [-1,1]:
				VerticalLayout.stairs(a,Vector3(side*25.,0,edge*27.),Vector2(5,12),floor-4.2 if edge<0 else floor,floor if edge<0 else floor-4.2,trim)
				# Return landings reach the foot of the next flight without walking
				# underneath an overlapping staircase.
				VerticalLayout.deck(a,Vector3(side*30.,floor,edge*27.),Vector2(5.,16.),trim)
				VerticalLayout.deck(a,Vector3(side*27.,floor,edge*35.),Vector2(12.,5.),trim)
				# Inner parapet only: the outer side is the return-landing entrance.
				a.box(center+Vector3(-side*4.8,.5,edge*20.8),Vector3(4.,1.,.3),trim)
			for z in [-16.,0.,16.]:a.box(center+Vector3(side*6.75,-2.1,z),Vector3(.5,4.2,.5),trim)
			a.navigation_goals.append(center)
			for z in [-12.,10.]:a.cover(center+Vector3(-side*2.,0,z),3.)
		VerticalLayout.deck(a,Vector3(0,floor,-18.),Vector2(38,6),trim)
		for x in [-12.,12.]:a.cover(Vector3(x,floor,-19.),3.)
		for side in [-1,1]:a.text3d("LEVEL %d"%int(floor/4.2+1),Vector3(side*25.,floor+2.,16.),Color("7bdac7"),40)
	for distance in [10,20,30,40,50]:
		var z=27.-distance
		a.detail(Vector3(0,.016,z),Vector3(28,.018,.08),Color("d8bd7c"));a.text3d(str(distance)+" m",Vector3(-14.,.7,z),Color("f2dcaa"),25)
	for side in [-1,1]:
		a.box(Vector3(side*17.,1.65,9),Vector3(.4,3.3,18),concrete)
		for z in [-12.,8.]:a.container_box(Vector3(side*37.,0,z),Color("608e90"),5.)
	for i in range(8):
		var spawn=Vector3((i%4-1.5)*1.4,.15,35.+(i/4)*1.6);a.spawn_points[0].append(spawn);a.spawn_points[1].append(Vector3(spawn.x,.15,-35));a.ffa_spawns.append(spawn)
	a.sites=[Vector3(-25.,4.2,0),Vector3(25.,8.4,0)];a.zones=[Vector3(-25.,0,0),Vector3(0,0,-18),Vector3(25.,0,0)]
	a.text3d("FIELD ACADEMY / 자유 훈련",Vector3(0,4.5,39.),Color("83e0cd"),55)
	a.text3d("거리 사격 · 이동 표적 · 고지대 · 스킬 및 가젯",Vector3(0,2.7,39.),Color("e4e7df"),28)
	a.set_meta("sight_blockers",10);a.set_meta("practice_levels",[0.,4.2,8.4,12.6])
