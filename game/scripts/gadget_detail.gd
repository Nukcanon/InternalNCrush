class_name GadgetDetail
extends RefCounted
const M=preload("res://scripts/mesh_factory.gd")
static func finish(parent:Node3D,role:int,variant:int):
	var web=RenderStyle.web();var dark=Color("26343a");var steel=Color("939d9c");var trim=Color("d4b765")
	if variant==8 or (role==0 and variant==1):
		# Strong shell segmentation survives even the reduced browser mesh.
		for i in range(4 if web else 8):
			var angle=i*TAU/(4 if web else 8)
			M.box(parent,Vector3(cos(angle)*.091,.16,sin(angle)*.091),Vector3(.008,.19,.008),dark)
		return
	if variant==9:
		# Defusal kit: protected cable sockets, cutters and a distinct tool case.
		for x in [-.17,.17]:M.box(parent,Vector3(x,.04,-.167),Vector3(.045,.08,.017),steel)
		for x in [-.08,.08]:M.cylinder(parent,Vector3(x,.12,-.10),.022,.026,Color("c06445"),Vector3(PI/2,0,0),-1,8)
		M.box(parent,Vector3(0,.13,.07),Vector3(.26,.025,.05),dark)
		return
	if role==1:
		# Readable sensor face without text, dynamic lights or a live viewport.
		for i in range(3):M.box(parent,Vector3(-.045+i*.043,.255-i*.022,-.063),Vector3(.029,.035+i*.018,.003),Color("73bc9e"))
		for x in [-.064,0.,.064]:M.box(parent,Vector3(x,.105,-.055),Vector3(.033,.025,.012),trim)
		if not web:
			for x in [-.103,.103]:
				for y in [.055,.32]:M.cylinder(parent,Vector3(x,y,-.050),.006,.006,steel,Vector3(PI/2,0,0),-1,8)
	elif role==4:
		# Crimped ends and safety lever distinguish a grenade from a plain can.
		for y in [.05,.36]:M.cylinder(parent,Vector3(0,y,0),.105,.023,steel,Vector3.ZERO,-1,8 if web else 16)
		M.cylinder(parent,Vector3(0,.26,0),.101,.035,trim if variant==1 else Color("568b7c"),Vector3.ZERO,-1,8 if web else 16)
		M.box(parent,Vector3(.087,.275,0),Vector3(.023,.255,.05),steel,Vector3(0,0,.10))
		M.box(parent,Vector3(.044,.415,0),Vector3(.11,.018,.05),steel)
		var ring=TorusMesh.new();ring.inner_radius=.021;ring.outer_radius=.028;ring.rings=8 if web else 16;ring.ring_segments=4 if web else 6
		M.instance(parent,ring,Vector3(-.06,.405,0),steel,Vector3(PI/2,0,0))
		for x in [-.055,.055]:M.box(parent,Vector3(x,.20,-.088),Vector3(.018,.065,.009),dark)
		if not web:
			for y in [.115,.16,.31]:
				for x in [-.037,.0,.037]:M.box(parent,Vector3(x,y,-.099),Vector3(.016,.01,.004),dark)
	elif role==5:
		for x in [-.11,.11]:
			M.box(parent,Vector3(x,.22,-.098),Vector3(.026,.36,.017),dark)
			M.box(parent,Vector3(x,.456,0),Vector3(.032,.08,.06),dark)
		M.box(parent,Vector3(0,.493,0),Vector3(.25,.03,.06),dark)
		for x in [-.22,.22]:M.box(parent,Vector3(x,.40,-.10),Vector3(.07,.04,.02),steel)
		if not web:
			for x in [-.276,.276]:M.box(parent,Vector3(x,.19,0),Vector3(.015,.17,.13),Color("637e73"))
	elif role==0:
		for x in [-.13,.13]:M.box(parent,Vector3(x,.24,.056),Vector3(.043,.32,.025),dark)
		M.box(parent,Vector3(0,.40,-.068),Vector3(.19,.035,.012),trim)
