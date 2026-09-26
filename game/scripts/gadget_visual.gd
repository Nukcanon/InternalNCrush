class_name GadgetVisual
extends Node3D
var right_socket=Vector3.ZERO
var left_socket=Vector3.ZERO
func build(role:int,variant:int,first_person:bool):
	var object=Node3D.new();add_child(object);EquipmentPreview.gadget_model(object,role,variant)
	var small=variant==8 or (role==0 and variant==1) or role==4
	object.scale=Vector3.ONE*(.55 if small else .60);object.position=Vector3(0,-.10,-.14)
	var radius=.055 if small else .03
	var palm=Vector3(0,-.01,-.14) if small else Vector3(.11,-.03,-.14)
	if not small:
		# Visible carrying handle fixed to both the case/plate and the fist.
		MeshFactory.cylinder(self,palm,radius,.12,Color("344049"))
		for y in [-.06,.06]:MeshFactory.box(self,palm+Vector3(-.035,y,0),Vector3(.08,.015,.03),Color("344049"))
	var grip=HeldGrip.new();add_child(grip);grip.position=palm;grip.build(role,radius)
	right_socket=palm+grip.wrist
	left_socket=Vector3(-.16,-.10,-.14)
	if first_person:
		var arm=WeaponHand.forearm(self,role);WeaponHand.fit_forearm(arm,Vector3(.30,-.30,.30),right_socket);arm.scale.x=1.4;arm.scale.z=1.4
	else:grip.visible=false # Third-person character hand meets this exact socket.
