extends Node3D
class_name PhysicsRagdoll
var bodies:Array=[]
var age=0.
var model:CharacterVisual
var followers:Array=[]
var launch_origin=Vector3.ZERO
static func launch_velocity(push:Vector3,velocity:Vector3) -> Vector3:
	var forward=Vector3(push.x,0,push.z).normalized()
	if forward.length_squared()<.1:forward=Vector3.FORWARD
	return velocity.limit_length(4.)*.25+forward*4.2+Vector3.UP*(2.5+clampf(push.y,-.4,.6))
const PARTS=[
	["Hips","",.20,.15,0.,12.], ["Hips/Chest","Hips",.34,.18,.10,18.],
	["Hips/Chest/Head","Hips/Chest",.24,.105,.02,5.],
	["Hips/Chest/LeftArm","Hips/Chest",.28,.072,-.14,3.], ["Hips/Chest/LeftArm/Elbow","Hips/Chest/LeftArm",.29,.06,-.14,2.],
	["Hips/Chest/RightArm","Hips/Chest",.28,.072,-.14,3.], ["Hips/Chest/RightArm/Elbow","Hips/Chest/RightArm",.29,.06,-.14,2.],
	["Hips/LeftLeg","Hips",.41,.087,-.205,7.], ["Hips/LeftLeg/Knee","Hips/LeftLeg",.45,.072,-.225,4.],
	["Hips/RightLeg","Hips",.41,.087,-.205,7.], ["Hips/RightLeg/Knee","Hips/RightLeg",.45,.072,-.225,4.]]
func build(source:CharacterVisual,pos:Vector3,push:Vector3,role:int,team:int,facing:float,crouched:bool,velocity:Vector3,impact_point:Vector3=Vector3.INF):
	model=CharacterVisual.new();model.enable_physics=false;add_child(model);model.build(role,team);model.global_position=pos;model.rotation.y=facing
	model.animator.stop()
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
		body.mass=part[5];body.collision_layer=16;body.collision_mask=1|4|8;body.linear_damp=.42;body.angular_damp=2.2;body.continuous_cd=true
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=part[3];capsule.height=maxf(part[2],part[3]*2.01);shape.shape=capsule;body.add_child(shape)
		var physics=PhysicsMaterial.new();physics.friction=.85;physics.bounce=.02;body.physics_material_override=physics
		followers.append({"bone":bone,"offset":body.global_transform.affine_inverse()*bone.global_transform})
		body.linear_velocity=launch_velocity(push,velocity);body.angular_velocity=Vector3(push.z,0,-push.x)*.7
		bodies.append(body);joints[part[0]]={"body":body,"anchor":bone.global_position}
	launch_origin=bodies[0].global_position
	for part in PARTS:
		if part[1]=="":continue
		var hinge=part[0].ends_with("Knee") or part[0].ends_with("Elbow")
		var joint:Joint3D=HingeJoint3D.new() if hinge else ConeTwistJoint3D.new();add_child(joint);joint.global_position=joints[part[0]].anchor
		joint.global_basis=joints[part[0]].body.global_basis*Basis(Vector3.UP,PI/2)
		joint.node_a=joint.get_path_to(joints[part[1]].body);joint.node_b=joint.get_path_to(joints[part[0]].body)
		if hinge:
			joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true);joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-2.25 if part[0].ends_with("Knee") else -.08);joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,.08 if part[0].ends_with("Knee") else 2.35)
		else:
			joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,.50 if part[0].ends_with("Chest") else .60 if part[0].ends_with("Head") else 1.15)
			joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,.42)
	if impact_point.is_finite():
		var closest:RigidBody3D=bodies[0]
		for body in bodies:
			if body.global_position.distance_squared_to(impact_point)<closest.global_position.distance_squared_to(impact_point):closest=body
		closest.set_meta("fatal_impact",true)
		closest.apply_impulse(push.limit_length(1.)*minf(22.,closest.mass*1.8),(impact_point-closest.global_position).limit_length(.2))
	model.sync_deform()
func copy_geometry(node:Node3D,body:RigidBody3D,paths:Dictionary,start:Node3D):
	for child in node.get_children():
		if paths.has(child) and child!=start:continue
		if child is MeshInstance3D:
			var copy=child.duplicate();body.add_child(copy);copy.global_transform=child.global_transform
		elif child is Node3D and not child is WeaponVisual:copy_geometry(child,body,paths,start)
func _physics_process(dt:float):
	age+=dt
	if not bodies.is_empty() and age>.05:
		var delta=bodies[0].global_position-launch_origin;var distance=Vector2(delta.x,delta.z).length()
		# A cosmetic 1–3m launch budget. Damping removes horizontal energy while
		# gravity, world contact and joint rotation continue, including on stairs.
		var drag=smoothstep(1.65,2.65,distance)*28.
		for body in bodies:
			var v=body.linear_velocity;var horizontal=Vector2(v.x,v.z).limit_length(7.)*exp(-drag*dt)
			body.linear_velocity=Vector3(horizontal.x,clampf(v.y,-20.,6.),horizontal.y);body.angular_velocity=body.angular_velocity.limit_length(12.)
	for i in range(followers.size()):followers[i].bone.global_transform=bodies[i].global_transform*followers[i].offset
	if is_instance_valid(model):model.sync_deform()
	if age>4. and bodies.all(func(body):return body.linear_velocity.length()<.25 and body.angular_velocity.length()<.5):
		for body in bodies:body.freeze=true
	if age>6.:queue_free()
