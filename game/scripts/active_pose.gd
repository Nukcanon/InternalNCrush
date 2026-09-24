extends Node3D
class_name ActivePose
# A bounded physical follower of the locomotion/IK pose. Gameplay collision stays
# server-authoritative; presentation bodies cannot push players or change aim.
var character:CharacterVisual
var bodies:Array=[]
var targets:Array=[]
var paused=false
static var active_count=0
const LIMIT=8
func build(source:CharacterVisual):
	character=source;top_level=true;active_count+=1
	for part in PhysicsRagdoll.PARTS:
		var bone:Node3D=character.rig.get_node(part[0]);var body=RigidBody3D.new();add_child(body)
		body.mass=part[5];body.gravity_scale=0.;body.linear_damp=2.;body.angular_damp=4.;body.collision_layer=0;body.collision_mask=0
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=part[3]*.8;capsule.height=maxf(part[2],capsule.radius*2.01);shape.shape=capsule;body.add_child(shape)
		var transform=bone.global_transform;transform.basis=transform.basis.orthonormalized()
		if transform.basis.determinant()<0:transform.basis.x=-transform.basis.x
		body.global_transform=transform;targets.append(transform);bodies.append(body)
	for i in range(1,bodies.size()):
		var parent=0
		for j in range(i):
			if PhysicsRagdoll.PARTS[j][0]==PhysicsRagdoll.PARTS[i][1]:parent=j;break
		var joint=ConeTwistJoint3D.new();add_child(joint);joint.global_position=bodies[i].global_position
		joint.node_a=joint.get_path_to(bodies[parent]);joint.node_b=joint.get_path_to(bodies[i])
		joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,PI*.85);joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,PI*.8)
func _exit_tree():active_count=maxi(0,active_count-1)
func _physics_process(_dt:float):
	if not is_instance_valid(character):queue_free();return
	for i in range(bodies.size()):
		var body:RigidBody3D=bodies[i];var target:Transform3D=targets[i]
		body.freeze=paused
		if paused:continue
		var error=target.origin-body.global_position
		if error.length()>1.2:body.global_transform=target;body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO;continue
		body.apply_central_force((error*210.-body.linear_velocity*27.).limit_length(400.)*body.mass)
		var q=(target.basis.get_rotation_quaternion()*body.global_basis.get_rotation_quaternion().inverse()).normalized()
		if q.w<0.:q=-q
		var angle=q.get_angle();var axis=q.get_axis().normalized() if angle>.0001 else Vector3.ZERO
		body.apply_torque((axis*angle*75.-body.angular_velocity*11.).limit_length(160.)*body.mass*.12)
func apply():
	for i in range(bodies.size()):
		var bone:Node3D=character.rig.get_node(PhysicsRagdoll.PARTS[i][0]);var target=bone.global_transform
		target.basis=target.basis.orthonormalized()
		if target.basis.determinant()<0:target.basis.x=-target.basis.x
		targets[i]=target
	# Feet are solved against the ground: physical sway must not perturb leg IK.
	# Capture all unmodified targets first, then apply parent-to-child deviations.
	for i in range(bodies.size()):
		if "Leg" in str(PhysicsRagdoll.PARTS[i][0]):continue
		var bone:Node3D=character.rig.get_node(PhysicsRagdoll.PARTS[i][0]);var target:Transform3D=targets[i]
		var q=(target.basis.get_rotation_quaternion().inverse()*bodies[i].global_basis.orthonormalized().get_rotation_quaternion()).normalized()
		if q.w<0.:q=-q
		var angle=minf(q.get_angle(),.25);var axis=q.get_axis().normalized() if angle>.0001 else Vector3.ZERO
		if angle>.0001 and axis.length_squared()>.5:bone.rotate_object_local(axis,angle*(.20 if i>2 else .30))
		if i==1:bone.position+=bone.global_basis.inverse()*(bodies[i].global_position-target.origin).limit_length(.05)*.28
func impulse(direction:Vector3,point:Vector3):
	var closest=0;var distance=INF
	for i in range(bodies.size()):
		var d=bodies[i].global_position.distance_squared_to(point)
		if d<distance:distance=d;closest=i
	bodies[closest].apply_central_impulse(direction.limit_length(1.)*bodies[closest].mass*.7)
	bodies[closest].apply_torque_impulse(Vector3(direction.z,0,-direction.x)*.45)
