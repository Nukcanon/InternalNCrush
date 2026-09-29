extends RefCounted
class_name ScopeReticle
## Original vector optics: five readable patterns, no bitmap or extra viewport.
static func style(weapon:Dictionary) -> int:
	return {"SCOUT":0,"MONOLITH":1,"ECHO":2,"LARK":3,"KESTREL":4}.get(str(weapon.get("name","")),0)
static func draw_on(canvas:Control,center:Vector2,radius:float,weapon:Dictionary):
	if weapon.get("laser",false):
		canvas.draw_arc(center,radius*.04,0,TAU,48,Color("985bd1"),1.5,true)
		canvas.draw_circle(center,2.,Color("bc81f5"),true,-1.,true)
		# Short bold posts near the centre, fine lines out to the scope rim.
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP]:
			canvas.draw_line(center+direction*radius*.07,center+direction*radius*.28,Color("27353c"),1.5,true)
			canvas.draw_line(center+direction*radius*.28,center+direction*radius*1.01,Color("27353c"),1.,true)
		return
	var design=style(weapon);var ink=Color(.025,.045,.055,.92);var red=Color(.8,.13,.09,.86)
	var unit=radius/10.;var thin=clampf(radius/330.,1.,1.6)
	for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var inner=unit*.65 if design==3 else unit*.28
		# Every line runs out to the rim of the visible circle (drawn under the rim ring).
		canvas.draw_line(center+d*inner,center+d*radius*1.01,ink,thin,true)
		if design in [0,2,4]:canvas.draw_line(center+d*radius*.58,center+d*radius*1.01,ink,thin*3.,true)
	match design:
		0: # Fine duplex, lower holdover graduations.
			for i in range(1,6):canvas.draw_line(center+Vector2(-unit*.17,unit*i),center+Vector2(unit*.17,unit*i),ink,thin,true)
		1: # Mil dots and a restrained lower windage ladder.
			for i in range(-5,6):
				if i==0:continue
				canvas.draw_circle(center+Vector2(unit*i,0),thin*1.5,ink,true,-1.,true)
				canvas.draw_circle(center+Vector2(0,unit*i),thin*1.5,ink,true,-1.,true)
			for row in range(2,6):
				for col in range(-row,row+1):
					if col!=0:canvas.draw_circle(center+Vector2(col*unit*.5,row*unit),thin,ink,true,-1.,true)
		2: # Illuminated center ring and short range marks.
			canvas.draw_arc(center,unit*.55,0,TAU,40,red,thin,true)
			for i in range(1,5):canvas.draw_line(center+Vector2(-unit*.23,unit*i),center+Vector2(unit*.23,unit*i),ink,thin,true)
		3: # Open chevron and ballistic-drop bars.
			canvas.draw_polyline(PackedVector2Array([center+Vector2(-unit*.32,unit*.34),center,center+Vector2(unit*.32,unit*.34)]),red,thin*1.7,true)
			for i in range(1,5):
				var half=unit*(.55-.075*i)
				canvas.draw_line(center+Vector2(-half,unit*i),center+Vector2(half,unit*i),ink,thin,true)
		4: # Circle-dot with ranging ticks on horizontal and vertical axes.
			canvas.draw_arc(center,unit*1.1,0,TAU,48,red,thin,true)
			for i in [-4,-3,-2,2,3,4]:
				canvas.draw_line(center+Vector2(unit*i,-unit*.15),center+Vector2(unit*i,unit*.15),ink,thin,true)
				canvas.draw_line(center+Vector2(-unit*.15,unit*i),center+Vector2(unit*.15,unit*i),ink,thin,true)
	if design!=3:canvas.draw_circle(center,thin*1.35,red if design in [2,4] else ink,true,-1.,true)
