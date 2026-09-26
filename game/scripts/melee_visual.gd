class_name MeleeVisual
extends Node3D
var tool=false
var pivot:Node3D
var hand:HeldGrip
var arm:Node3D
var palm:Marker3D
func build(wrench:bool,role:int,first_person:bool):
	tool=wrench;pivot=Node3D.new();add_child(pivot)
	var dark=Color("29353a");var steel=Color("a1b2bb")
	MeshFactory.cylinder(pivot,Vector3(0,-.035,0),.024,.155,dark)
	for y in [-.095,-.070,-.045,-.020,.005]:MeshFactory.cylinder(pivot,Vector3(0,y,0),.025,.008,Color("526067"))
	if tool:
		var red=Color("b82725");var jaw=Color("353e42")
		MeshFactory.box(pivot,Vector3(0,.005,0),Vector3(.055,.26,.039),red,Vector3.ZERO,.28)
		MeshFactory.box(pivot,Vector3(0,.153,0),Vector3(.095,.095,.062),red,Vector3.ZERO,.34)
		# Fixed serrated jaw and offset adjustable hook form an open pipe mouth.
		MeshFactory.box(pivot,Vector3(.008,.210,0),Vector3(.078,.032,.062),jaw)
		MeshFactory.box(pivot,Vector3(-.052,.25,0),Vector3(.028,.16,.048),jaw)
		MeshFactory.box(pivot,Vector3(-.01,.320,0),Vector3(.110,.028,.056),jaw,Vector3(0,0,-.16))
		for x in [-.025,-.013,-.001,.011,.023]:
			MeshFactory.box(pivot,Vector3(x,.231,0),Vector3(.008,.01,.055),steel)
			MeshFactory.box(pivot,Vector3(x,.296,0),Vector3(.008,.01,.050),steel)
		MeshFactory.cylinder(pivot,Vector3(-.045,.16,0),.035,.045,jaw,Vector3(0,0,PI/2),-1.,12)
		for y in [.148,.160,.172]:MeshFactory.cylinder(pivot,Vector3(-.045,y,0),.036,.006,steel,Vector3.ZERO,-1.,12)
		MeshFactory.box(pivot,Vector3(0,-.104,0),Vector3(.06,.032,.042),red)

	else:
		MeshFactory.box(pivot,Vector3(0,-.035,0),Vector3(.045,.16,.044),Color("586747"),Vector3.ZERO,.32)
		for y in [-.09,.018]:MeshFactory.cylinder(pivot,Vector3(0,y,.024),.008,.006,steel,Vector3(PI/2,0,0),-1.,10)
		MeshFactory.box(pivot,Vector3(0,.052,0),Vector3(.11,.012,.055),dark)
		var outline=PackedVector2Array([Vector2(-.027,.060),Vector2(.025,.060),Vector2(.030,.26),Vector2(.016,.34),Vector2(-.014,.40),Vector2(-.027,.29)])
		var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var indices=Geometry2D.triangulate_polygon(outline)
		for side in [-1,1]:
			for i in range(0,indices.size(),3):
				for j in ([0,1,2] if side==1 else [2,1,0]):
					var point=outline[indices[i+j]];surface.add_vertex(Vector3(point.x,point.y,side*.004))
		for i in range(outline.size()):
			var a=outline[i];var b=outline[(i+1)%outline.size()]
			for point in [Vector3(a.x,a.y,-.004),Vector3(b.x,b.y,-.004),Vector3(a.x,a.y,.004),Vector3(a.x,a.y,.004),Vector3(b.x,b.y,-.004),Vector3(b.x,b.y,.004)]:surface.add_vertex(point)
		surface.generate_normals();var blade=MeshInstance3D.new();blade.mesh=surface.commit();blade.material_override=MeshFactory.material(Color("556068"));pivot.add_child(blade)
		for i in range(1,4):
			var a=outline[i];var b=outline[i+1];var edge=MeshFactory.cylinder(pivot,Vector3((a.x+b.x)*.5,(a.y+b.y)*.5,0),.0025,a.distance_to(b),steel,Vector3.ZERO,-1.,6);edge.quaternion=Quaternion(Vector3.UP,Vector3(b.x-a.x,b.y-a.y,0).normalized())

	palm=Marker3D.new();pivot.add_child(palm);palm.position=Vector3(.035,-.028,.025)
	if first_person:
		hand=HeldGrip.new();pivot.add_child(hand);hand.position=Vector3(0,-.035,0);hand.build(role,.030 if tool else .025)
		arm=WeaponHand.forearm(self,role)
	pose(-1.)
func pose(age:float):
	# Right-handed downward diagonal cut; parent mirroring supplies the left-hand version.
	var rest=Vector3(.16,-.08,-.08);var wind=Vector3(.38,.24,-.16);var finish=Vector3(-.40,-.30,-.42)
	var rest_rot=Vector3(-.35,0,-.20);var wind_rot=Vector3(.15,-.30,-.65);var finish_rot=Vector3(-1.1,.45,1.35)
	pivot.position=rest;pivot.rotation=rest_rot
	if age>=0. and age<MeleeCombat.DURATION:
		if age<MeleeCombat.CONTACT_START:
			var t=smoothstep(0.,MeleeCombat.CONTACT_START,age)
			pivot.position=rest.lerp(wind,t);pivot.rotation=rest_rot.lerp(wind_rot,t)
		elif age<=MeleeCombat.CONTACT_END:
			var t=clampf((age-MeleeCombat.CONTACT_START)/(MeleeCombat.CONTACT_END-MeleeCombat.CONTACT_START),0.,1.)
			pivot.position=wind.lerp(finish,t);pivot.rotation=wind_rot.lerp(finish_rot,t)
		else:
			# Low follow-through, then a curved recovery outside the next cutting arc.
			var t=smoothstep(MeleeCombat.CONTACT_END,MeleeCombat.DURATION,age)
			pivot.position=finish.lerp(rest,t)+Vector3(0,-.10*sin(t*PI),.13*sin(t*PI));pivot.rotation=finish_rot.lerp(rest_rot,t)
	if is_instance_valid(hand):
		var elbow=Vector3(.30,-.30,.29)
		var wrist=pivot.transform*(hand.position+hand.wrist)
		WeaponHand.fit_forearm(arm,elbow,wrist);arm.scale.x=1.4;arm.scale.z=1.4
