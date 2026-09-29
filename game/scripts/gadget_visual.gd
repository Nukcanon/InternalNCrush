class_name GadgetVisual
extends Node3D
var right_socket=Vector3.ZERO
var left_socket=Vector3.ZERO
var two_handed=false
# Procedural grips cost 70-170 ms per build. Held items are rebuilt whenever a
# player selects a gadget, so every peer caches finished assemblies instead.
static var templates={}
func build(role:int,variant:int,first_person:bool,turret:bool=false):
	var key=str([role,variant,first_person,turret,RenderStyle.web()])
	if not templates.has(key):
		var source=GadgetVisual.new();source.build_fresh(role,variant,first_person,turret)
		MeshFactory.own_recursive(source,source)
		var packed=PackedScene.new();packed.pack(source)
		templates[key]={"scene":packed,"right":source.right_socket,"left":source.left_socket,"two_handed":source.two_handed}
		source.free()
	var entry=templates[key];var copy:Node=entry.scene.instantiate()
	for child in copy.get_children():
		copy.remove_child(child);MeshFactory.own_recursive(child,null);child.owner=null;add_child(child)
	copy.free()
	right_socket=entry.right;left_socket=entry.left;two_handed=entry.two_handed
static func prepare(role:int,variant:int,first_person:bool,turret:bool=false):
	var probe=GadgetVisual.new();probe.build(role,variant,first_person,turret);probe.free()
func build_fresh(role:int,variant:int,first_person:bool,turret:bool=false):
	var object=Node3D.new();object.name="Payload";add_child(object)
	two_handed=turret or (role==3 and variant in [0,1,2])
	if turret:CombatFX.device(object,"turret",0)
	else:EquipmentPreview.gadget_model(object,role,variant)
	var small=variant==8 or (role==0 and variant==1) or role==4
	object.scale=Vector3.ONE*(.23 if turret else .60 if two_handed else .45 if small else .60)
	object.position=Vector3(-.14,-.21,-.34) if two_handed else Vector3(0,-.10,-.14)
	if turret:
		# Carry rails join the narrow turret chassis; no handles floating beside it.
		for y in [-.095,.035]:MeshFactory.box(self,Vector3(-.14,y,-.26),Vector3(.56,.03,.06),Color("52626a"))
		for x in [-.24,-.04]:MeshFactory.box(self,Vector3(x,-.15,-.28),Vector3(.045,.22,.09),Color("344049"))
	var radius=.020 if two_handed else .044 if small else .025
	var palms=[Vector3(.12,-.03,-.06),Vector3(-.40,-.03,-.06)] if two_handed else [Vector3(0,-.01,-.14) if small else Vector3(.04,.03,-.045)]
	for index in range(palms.size()):
		var palm:Vector3=palms[index];var side=1. if index==0 else -1.
		if not small:
			MeshFactory.cylinder(self,palm,radius,.13,Color("344049"))
			for y in [-.065,.065]:MeshFactory.box(self,palm+Vector3(0,y,-.10),Vector3(.04,.025,.24),Color("52626a"))
		var grip=HeldGrip.new();add_child(grip);grip.position=palm;grip.scale.x=side;grip.build(role,radius)
		var wrist=palm+Vector3(grip.wrist.x*side,grip.wrist.y,grip.wrist.z)
		if index==0:right_socket=palm+Vector3(.035,0,.02)
		else:left_socket=palm+Vector3(-.035,0,.02)
		if first_person:
			var arm=WeaponHand.forearm(self,role);WeaponHand.fit_forearm(arm,Vector3(.30 if index==0 else -.48,-.30,.30),wrist);arm.scale.x=1.4;arm.scale.z=1.4
		else:grip.visible=false
