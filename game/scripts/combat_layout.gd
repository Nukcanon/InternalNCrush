extends RefCounted
class_name CombatLayout
const INDOOR=[2,3,8,11,14,15]
const NIGHT=[1,6,9,16,17]
static func valid(a:Node,pos:Vector3,half:Vector2) -> bool:
	if absf(pos.x)+half.x>a.bounds.x-5. or absf(pos.z)+half.y>a.bounds.y-12.:return false
	if a.wading(pos):return false
	if a.vertical_map:
		for surface in a.walk_surfaces:
			if surface.low!=surface.high and surface.rect.grow(1.6).intersects(Rect2(Vector2(pos.x,pos.z)-half,half*2.)):return false
		if absf(a.walk_height(pos))>.1:return false
	for goal in a.zones+a.sites+a.ffa_spawns+a.navigation_goals:
		if absf(goal.y-pos.y)>2.:continue
		if Vector2(pos.x-goal.x,pos.z-goal.z).length()<half.length()+2.5:return false
	for rect in a.obstacles:
		if rect.grow(1.6).intersects(Rect2(Vector2(pos.x,pos.z)-half,half*2.)):return false
	return true
static func build(a:Node):
	var indoor=a.map_index in INDOOR;a.indoors=indoor;a.set_meta("night",a.map_index in NIGHT)
	var wall=Color("788d94") if indoor else Color("b8aa90");var trim=Color("3a515b")
	var spacing=23. if a.bounds.x>70 else 15. if a.bounds.x>40 else 10.
	var count=0;var pairs=[]
	# Rotationally paired sight blockers keep each team's first routes comparable.
	for x in range(1,int(a.bounds.x/spacing)+1):
		for z in range(-int(a.bounds.y/spacing)+1,int(a.bounds.y/spacing)):
			var pos=Vector3(x*spacing-spacing*.45,0,z*spacing+(spacing*.22 if x%2 else -spacing*.22))
			var half=Vector2(3.3,2.6) if a.bounds.x>70 else Vector2(2.2,1.15)
			if not valid(a,pos,half) or not valid(a,-pos,half):continue
			pairs.append(pos)
	for pos in pairs:
		for side in [-1,1]:
			var point=pos*side
			var size=Vector3(6.6,3.3,5.2) if a.bounds.x>70 else Vector3(4.4,2.8,2.3)
			# Closed service island, with a broad route on both sides; no single pixel head peek.
			if pos==pairs[0]:
				# A readable, usable service room with two exits instead of a solid block.
				for edge in [-1,1]:
					a.box(point+Vector3(edge*(size.x*.5-.12),1.4,0),Vector3(.24,2.8,size.z),wall)
					for xside in [-1,1]:a.box(point+Vector3(xside*(size.x*.25+.61),1.4,edge*size.z*.5),Vector3(size.x*.5-1.22,2.8,.24),wall)
					a.add_door(point+Vector3(0,0,edge*(size.z*.5+.04)),PI if edge>0 else 0.)
				a.box(point+Vector3(0,2.93,0),Vector3(size.x,.26,size.z+.3),wall)
			else:a.box(point+Vector3.UP*size.y*.5,size,wall)
			a.detail(point+Vector3.UP*(size.y+.07),Vector3(size.x+.3,.14,size.z+.3),trim)
			for edge in [-1,1]:
				a.detail(point+Vector3(edge*(size.x*.5+.03),1.8,0),Vector3(.06,1.7,size.z*.65),Color("47636c"))
				for y in [1.15,1.55,1.95,2.35]:a.detail(point+Vector3(edge*(size.x*.5+.08),y,0),Vector3(.04,.06,size.z*.58),trim)
			count+=1
	if a.doors.is_empty() and a.vertical_map:
		for side in [-1,1]:
			var point=Vector3(side*a.bounds.x*MapIdentity.WINGS[a.map_index],0,side*minf(4.,a.bounds.y*.10)-float(a.get_meta("wing_depth",20.))*.5-.18)
			for edge in [-1,1]:a.box(point+Vector3(edge*2.14,1.4,0),Vector3(1.74,2.8,.28),wall)
			a.add_door(point)
	# Break the straight elevated firing lane without closing the 4.6m-wide crossing.
	if a.vertical_map:
		var style=a.map_index%4;var center_z=2.5 if style==0 else -2.5 if style==1 else 0.
		if style in [0,1]:
			for side in [-1,1]:
				var x=side*minf(6.,a.bounds.x*.20)
				a.box(Vector3(x,5.45,center_z+side*1.28),Vector3(.45,2.5,1.65),trim)
				count+=1
	if indoor:
		var height=10.8
		a.box(Vector3(0,height+.2,0),Vector3(a.bounds.x*1.25,.4,a.bounds.y*1.25),Color("586a76"))
		for side in [-1,1]:
			a.box(Vector3(side*(a.bounds.x-1.),height*.5,0),Vector3(1.,height,a.bounds.y*2.),wall)
			a.box(Vector3(0,height*.5,side*(a.bounds.y-1.)),Vector3(a.bounds.x*2.,height,1.),wall)
		for x in [-a.bounds.x*.6,0.,a.bounds.x*.6]:
			a.detail(Vector3(x,height-.24,0),Vector3(.45,.42,a.bounds.y*1.9),trim)
		a.set_meta("enclosed_roof_height",height)
	a.set_meta("sight_blockers",count)
