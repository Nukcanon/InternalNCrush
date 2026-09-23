extends Node3D
class_name PhysicsRagdoll
var bodies:Array=[]
var age=0.
const PARTS=[
	["Hips","",.20,.15,0.,12.], ["Hips/Chest","Hips",.34,.18,.10,18.],
	["Hips/Chest/Head","Hips/Chest",.24,.105,.02,5.],
	["Hips/Chest/LeftArm","Hips/Chest",.28,.072,-.14,3.], ["Hips/Chest/LeftArm/Elbow","Hips/Chest/LeftArm",.29,.06,-.14,2.],
	["Hips/Chest/RightArm","Hips/Chest",.28,.072,-.14,3.], ["Hips/Chest/RightArm/Elbow","Hips/Chest/RightArm",.29,.06,-.14,2.],
	["Hips/LeftLeg","Hips",.41,.087,-.205,7.], ["Hips/LeftLeg/Knee","Hips/LeftLeg",.45,.072,-.225,4.],
	["Hips/RightLeg","Hips",.41,.087,-.205,7.], ["Hips/RightLeg/Knee","Hips/RightLeg",.45,.072,-.225,4.]]
func build(source:CharacterVisual,pos:Vector3,push:Vector3,role:int,team:int,facing:float,crouched:bool,velocity:Vector3):
	var model=CharacterVisual.new();add_child(model);model.build(role,team);model.global_position=pos;model.rotation.y=facing
	if is_instance_valid(source):
		model.scale=source.scale
		for path in PARTS:
			var original=source.rig.get_node(path[0]);model.rig.get_node(path[0]).transform=original.transform
	elif crouched:model.update_pose(.016,Vector3.ZERO,false,true,true,0.,-1.,0.,0.)
	var paths={};var joints={}
	for part in PARTS:paths[model.rig.get_node(part[0])]=part[0]
	for part in PARTS:
		var bone:Node3D=model.rig.get_node(part[0]);var body=RigidBody3D.new();body.name="Body"+str(bodies.size());add_child(body)
		body.global_position=bone.to_global(Vector3(0,part[4],0));body.global_basis=bone.global_basis.orthonormalized()
		if body.global_basis.determinant()<0:var b=body.global_basis;b.x=-b.x;body.global_basis=b
		body.mass=part[5];body.collision_layer=16;body.collision_mask=1|4|8;body.linear_damp=.55;body.angular_damp=2.6;body.continuous_cd=true
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=part[3];capsule.height=maxf(part[2],part[3]*2.01);shape.shape=capsule;body.add_child(shape)
		var physics=PhysicsMaterial.new();physics.friction=.85;physics.bounce=.02;body.physics_material_override=physics
		copy_geometry(bone,body,paths,bone)
		body.linear_velocity=velocity.limit_length(12.)*.8+push.limit_length(1.)*2.2;body.angular_velocity=Vector3(push.z,0,-push.x)*1.5
		bodies.append(body);joints[part[0]]={"body":body,"anchor":bone.global_position}
	for part in PARTS:
		if part[1]=="":continue
		var joint=ConeTwistJoint3D.new();add_child(joint);joint.global_position=joints[part[0]].anchor;joint.rotation.z=PI/2
		joint.node_a=joint.get_path_to(joints[part[1]].body);joint.node_b=joint.get_path_to(joints[part[0]].body)
		joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,.60 if part[0].ends_with("Chest") else .65 if part[0].ends_with("Head") else 1.25)
		joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,.35 if part[0].ends_with("Knee") or part[0].ends_with("Elbow") else .6)
	model.queue_free()
func copy_geometry(node:Node3D,body:RigidBody3D,paths:Dictionary,start:Node3D):
	for child in node.get_children():
		if paths.has(child) and child!=start:continue
		if child is MeshInstance3D:
			var copy=child.duplicate();body.add_child(copy);copy.global_transform=child.global_transform
		elif child is Node3D and not child is WeaponVisual:copy_geometry(child,body,paths,start)
func _physics_process(dt:float):
	age+=dt
	if age>4. and bodies.all(func(body):return body.linear_velocity.length()<.25 and body.angular_velocity.length()<.5):
		for body in bodies:body.freeze=true
	if age>6.:queue_free()
