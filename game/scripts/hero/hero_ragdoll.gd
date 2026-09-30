extends Node3D
class_name HeroRagdoll
## Native corpse: a HeroCharacter copy whose major bones are carried by jointed
## rigid bodies. Shapes come from the measured hit volumes (hitboxes.json), so
## the falling body matches the visible mesh. Cosmetic only: bodies collide with
## static world geometry (layer 1) and never with players or props.
# [bone, parent body bone, joint kind, mass]
const PARTS=[
	["Body","","",12.],["Chest","Body","cone",14.],["Head","Chest","cone",5.],
	["UpperArm.L","Chest","cone",2.5],["LowerArm.L","UpperArm.L","hinge",1.8],
	["UpperArm.R","Chest","cone",2.5],["LowerArm.R","UpperArm.R","hinge",1.8],
	["UpperLeg.L","Body","cone",7.],["LowerLeg.L","UpperLeg.L","knee",4.],
	["UpperLeg.R","Body","cone",7.],["LowerLeg.R","UpperLeg.R","knee",4.]]
# Bones parented to Root (IK helpers) that must ride along with a limb.
const CARRIED={"Foot.L":"LowerLeg.L","Foot.R":"LowerLeg.R","PT.L":"LowerLeg.L","PT.R":"LowerLeg.R"}
var hero:HeroCharacter
var bodies=[]
var offsets=[]
var indices=[]
var carried=[]
var age=0.
var settled=false
var still=0.
static func launch_velocity(push:Vector3,velocity:Vector3) -> Vector3:
	var forward=Vector3(push.x,0,push.z).normalized()
	if forward.length_squared()<.1:forward=Vector3.FORWARD
	return velocity.limit_length(4.)*.25+forward*3.6+Vector3.UP*(2.2+clampf(push.y,-.4,.6))
func build(source:HeroCharacter,pos:Vector3,push:Vector3,role:int,team:int,facing:float,_crouched:bool,velocity:Vector3,impact:Vector3=Vector3.INF):
	hero=HeroCharacter.new();add_child(hero);hero.build(role,team,HeroStyle.outlines_enabled());hero.tree.active=false
	hero.global_position=pos;hero.rotation.y=facing
	if is_instance_valid(source):
		hero.scale=source.scale;hero.dress_like(source)
		for i in range(source.skeleton.get_bone_count()):hero.skeleton.set_bone_pose(i,source.skeleton.get_bone_pose(i))
	# The struck part is chosen in the living pose, then the corpse is laid flat
	# along the bullet travel (the existing exaggerated launch).
	var impact_bone=""
	if impact.is_finite():
		var best=INF
		for part in PARTS:
			var d=hero.bone_world(hero.skeleton.find_bone(part[0])).origin.distance_squared_to(impact)
			if d<best:best=d;impact_bone=part[0]
	var flight=Vector3(push.x,0,push.z).normalized()
	if flight.length_squared()<.1:flight=Vector3.FORWARD
	var y_axis=flight;var z_axis=Vector3.DOWN;var x_axis=y_axis.cross(z_axis).normalized()
	hero.global_transform=Transform3D(Basis(x_axis,y_axis,z_axis).scaled(hero.scale),pos+Vector3.UP*.16)
	HeroHitbox.load_volumes()
	var shapes={}
	for v in HeroHitbox.volumes.get(HeroCharacter.OUTFITS[hero.role],[]):
		if not v.has("part"):shapes[v.bone]=v
	var by_bone={}
	var model_scale=hero.model.scale.x*hero.scale.x
	for part in PARTS:
		var index=hero.skeleton.find_bone(part[0])
		var bone_world=hero.bone_world(index)
		var body=RigidBody3D.new();body.name="Rag_"+part[0];add_child(body)
		body.collision_layer=16;body.collision_mask=1;body.mass=part[3];body.linear_damp=.4;body.angular_damp=2.;body.continuous_cd=true
		body.contact_monitor=true;body.max_contacts_reported=2
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();body.add_child(shape)
		var v:Dictionary=shapes.get(part[0] if part[0]!="Body" else "Hips",{})
		var a=Vector3.ZERO;var b=Vector3(0,.2,0);var r=.1
		if v.get("type","")=="capsule":a=HeroHitbox.v3(v.a);b=HeroHitbox.v3(v.b);r=float(v.r)
		elif v.get("type","")=="ellipsoid":
			var c=HeroHitbox.v3(v.c);var e=HeroHitbox.v3(v.e);r=minf(e.x,e.z);a=c-Vector3(0,e.y-r,0);b=c+Vector3(0,e.y-r,0)
		var frame=bone_world if part[0]!="Body" else hero.bone_world(hero.skeleton.find_bone("Hips"))
		var mid=frame*((a+b)*.5)
		var axis=(frame.basis*(b-a))
		capsule.radius=maxf(.03,r*model_scale);capsule.height=maxf(capsule.radius*2.05,axis.length()+capsule.radius*2.)
		shape.shape=capsule
		var up=axis.normalized() if axis.length()>.001 else Vector3.UP
		var side=up.cross(Vector3.FORWARD);if side.length()<.1:side=up.cross(Vector3.RIGHT)
		side=side.normalized()
		body.global_transform=Transform3D(Basis(side,up,side.cross(up)).orthonormalized(),mid)
		var physics=PhysicsMaterial.new();physics.friction=.85;physics.bounce=.02;body.physics_material_override=physics
		bodies.append(body);indices.append(index);offsets.append(body.global_transform.affine_inverse()*bone_world)
		by_bone[part[0]]=body
		body.linear_velocity=launch_velocity(push,velocity);body.angular_velocity=Vector3(push.z,0,-push.x)*.15
	for body in bodies:
		for other in bodies:
			if body!=other:body.add_collision_exception_with(other)
	for part in PARTS:
		if part[1]=="":continue
		var child:RigidBody3D=by_bone[part[0]];var parent:RigidBody3D=by_bone[part[1]]
		var anchor=hero.bone_world(hero.skeleton.find_bone(part[0])).origin
		var joint:Joint3D
		if part[2]=="cone":
			joint=ConeTwistJoint3D.new();joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,.55 if part[0]=="Chest" else .7 if part[0]=="Head" else 1.2);joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,.4)
		else:
			joint=HingeJoint3D.new();joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-2.3 if part[2]=="knee" else -.05);joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,.05 if part[2]=="knee" else 2.3)
		add_child(joint);joint.global_position=anchor
		# Hinge axis: the character's sideways axis.
		joint.global_basis=Basis(Vector3.UP,facing)*Basis(Vector3.UP,PI*.5)
		joint.node_a=joint.get_path_to(parent);joint.node_b=joint.get_path_to(child)
	for name in CARRIED:
		var bone=hero.skeleton.find_bone(name);var anchor=hero.skeleton.find_bone(CARRIED[name])
		if bone>=0 and anchor>=0:carried.append([bone,anchor,hero.bone_world(anchor).affine_inverse()*hero.bone_world(bone)])
	if impact_bone!="":
		var closest:RigidBody3D=by_bone[impact_bone]
		closest.set_meta("fatal_impact",true);closest.set_meta("fatal_impact_part",str(closest.name).trim_prefix("Rag_"))
		closest.apply_impulse(push.limit_length(1.)*minf(20.,closest.mass*1.6),(impact-closest.global_position).limit_length(.2))
	write_pose()
# Pelvis-to-chest direction of the corpse (flat when lying).
func torso_axis() -> Vector3:
	return (hero.bone_world(hero.skeleton.find_bone("Chest")).origin-hero.bone_world(hero.skeleton.find_bone("Hips")).origin).normalized()
func write_pose():
	var inv=hero.skeleton.global_transform.affine_inverse()
	for i in range(bodies.size()):
		hero.skeleton.set_bone_global_pose(indices[i],inv*(bodies[i].global_transform*offsets[i]))
	for c in carried:
		hero.skeleton.set_bone_global_pose(c[0],inv*(hero.bone_world(c[1])*c[2]))
func _physics_process(dt:float):
	age+=dt
	if age>7.:queue_free();return
	if settled:return
	for body in bodies:
		var v=body.linear_velocity;body.linear_velocity=Vector3(v.x,clampf(v.y,-20.,6.),v.z).limit_length(9.);body.angular_velocity=body.angular_velocity.limit_length(12.)
	write_pose()
	var moving=bodies.any(func(b):return b.linear_velocity.length()>.12 or b.angular_velocity.length()>.3)
	still=0. if moving else still+dt
	if age>1.2 and (still>.5 or age>3.):
		for body in bodies:body.freeze=true
		settled=true
