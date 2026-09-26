class_name MeleeVisual
extends Node3D
var tool=false
var pivot:Node3D
var hand:WeaponHand
var arm:Node3D
var palm:Marker3D
func build(wrench:bool,role:int,first_person:bool):
	tool=wrench;pivot=Node3D.new();add_child(pivot)
	var dark=Color("29353a");var steel=Color("a1b2bb")
	MeshFactory.cylinder(pivot,Vector3(0,-.035,0),.024,.155,dark)
	for y in [-.095,-.070,-.045,-.020,.005]:MeshFactory.cylinder(pivot,Vector3(0,y,0),.025,.008,Color("526067"))
	if tool:
		MeshFactory.box(pivot,Vector3(0,.105,0),Vector3(.038,.17,.023),steel)
		MeshFactory.box(pivot,Vector3(0,.205,0),Vector3(.105,.05,.035),steel)
		for side in [-1,1]:MeshFactory.box(pivot,Vector3(side*.048,.248,0),Vector3(.031,.085,.035),steel,Vector3(0,0,-side*.20))
		MeshFactory.box(pivot,Vector3(0,.207,-.019),Vector3(.063,.018,.005),Color("4e646e"))
	else:
		MeshFactory.box(pivot,Vector3(0,.048,0),Vector3(.105,.014,.044),dark)
		var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var verts=[Vector3(-.023,.065,0),Vector3(.023,.065,0),Vector3(0,.34,0),Vector3(0,.15,-.011),Vector3(0,.15,.011)]
		for triangle in [[0,3,2],[3,1,2],[0,1,3],[0,2,4],[4,2,1],[0,4,1]]:
			for index in triangle:surface.add_vertex(verts[index])
		surface.generate_normals();var blade=MeshInstance3D.new();blade.mesh=surface.commit();blade.material_override=MeshFactory.material(steel);pivot.add_child(blade)
	palm=Marker3D.new();pivot.add_child(palm);palm.position=Vector3(.035,-.028,.025)
	if first_person:
		hand=WeaponHand.new();pivot.add_child(hand);hand.position=palm.position;hand.build(false,false,role)
		# Close the trigger finger as well: a tool has a fist grip, no trigger.
		for material in hand.materials[0]:material.set_shader_parameter("curl",Vector3(.82,1.23,.66))
		arm=WeaponHand.forearm(self,role)
	pose(-1.)
func pose(age:float):
	var turn=0.;var extension=0.
	if age>=0. and age<MeleeCombat.DURATION:
		if age<MeleeCombat.CONTACT_START:turn=lerpf(0.,-.82,smoothstep(0.,MeleeCombat.CONTACT_START,age))
		elif age<=MeleeCombat.CONTACT_END:turn=lerpf(-.82,.82,(age-MeleeCombat.CONTACT_START)/(MeleeCombat.CONTACT_END-MeleeCombat.CONTACT_START))
		else:turn=lerpf(.82,0.,smoothstep(MeleeCombat.CONTACT_END,MeleeCombat.DURATION,age))
		extension=sin(clampf(age/.60,0.,1.)*PI)
	pivot.position=Vector3(-sin(turn)*.32,.015+extension*.035,-.09-extension*.22)
	pivot.rotation=Vector3(-.35-extension*.35,turn,-.25-turn*.5)
	if is_instance_valid(hand):
		var elbow=Vector3(.28,-.34,.27);var palm_point=pivot.transform*palm.position
		var wrist=WeaponHand.align_wrist(hand,palm_point,elbow,pivot.basis*Vector3(-1,0,-.2))
		WeaponHand.fit_forearm(arm,elbow,wrist)
		hand.constrain_contacts(hand.transform,[AABB(Vector3(-.026,-.12,-.026),Vector3(.052,.175,.052))])
