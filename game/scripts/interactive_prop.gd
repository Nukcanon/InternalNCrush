extends RigidBody3D
class_name InteractiveProp
const M=preload("res://scripts/mesh_factory.gd")
var prop_id=0
var kind="barrel"
var authoritative=false
var home=Transform3D.IDENTITY
var target=Transform3D.IDENTITY
var radius=.55
var received=false
func configure(id:int,type:String,authority:bool):
	prop_id=id;kind=type;authoritative=authority
	collision_layer=8;collision_mask=1|8;freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC;freeze=not authority
	continuous_cd=true;linear_damp=.65;angular_damp=1.3;can_sleep=true
	physics_material_override=PhysicsMaterial.new();physics_material_override.friction=.68;physics_material_override.bounce=.16
	set_meta("prop_id",id)
	var collider=CollisionShape3D.new();add_child(collider)
	match kind:
		"barrel":
			mass=9.;var shape=CylinderShape3D.new();shape.radius=.35;shape.height=.92;collider.shape=shape
			var color=Color("788e8c") if id%2==0 else Color("b78058")
			M.cylinder(self,Vector3.ZERO,.35,.9,color,Vector3.ZERO,-1.,20)
			for y in [-.43,-.24,.24,.43]:M.cylinder(self,Vector3(0,y,0),.363,.035,color.darkened(.27),Vector3.ZERO,-1.,20)
			for y in [-.455,.455]:M.cylinder(self,Vector3(0,y,0),.328,.013,color.lightened(.13),Vector3.ZERO,-1.,20)
			M.cylinder(self,Vector3(.17,.468,.04),.041,.02,Color("454f50"),Vector3.ZERO,-1.,12)
			M.box(self,Vector3(0,.035,-.352),Vector3(.19,.17,.012),Color("d2c8ac"),Vector3.ZERO,.08)
		"crate":
			mass=4.;var shape=BoxShape3D.new();shape.size=Vector3(.69,.53,.58);collider.shape=shape
			M.box(self,Vector3.ZERO,shape.size,Color("af8f62"),Vector3.ZERO,.12)
			for x in [-.25,.25]:
				for z in [-.298,.298]:M.box(self,Vector3(x,0,z),Vector3(.07,.54,.024),Color("d2b37d"))
			for y in [-.20,.20]:
				for z in [-.306,.306]:M.box(self,Vector3(0,y,z),Vector3(.68,.06,.025),Color("81684c"))
		"cone":
			mass=.8;radius=.25;var shape=ConvexPolygonShape3D.new();var points=PackedVector3Array()
			for y in [-.245,.275]:
				for i in range(20):
					var a=i*TAU/20.;var r=.18 if y<0 else .036;points.append(Vector3(cos(a)*r,y,sin(a)*r))
			shape.points=points;collider.shape=shape
			add_box_shape(Vector3(0,-.265,0),Vector3(.46,.044,.46))
			M.box(self,Vector3(0,-.265,0),Vector3(.47,.045,.47),Color("484c47"),Vector3.ZERO,.45)
			M.cylinder(self,Vector3(0,.015,0),.18,.52,Color("d99554"),Vector3.ZERO,.036,20)
			M.cylinder(self,Vector3(0,.015,0),.121,.10,Color("e1d9bb"),Vector3.ZERO,.094,20)
		"canister":
			mass=2.;radius=.35;var shape=BoxShape3D.new();shape.size=Vector3(.30,.46,.18);collider.shape=shape
			M.box(self,Vector3.ZERO,shape.size,Color("919666"),Vector3.ZERO,.6)
			for side in [-1,1]:
				for tilt in [-.55,.55]:M.box(self,Vector3(0,-.01,side*.093),Vector3(.023,.28,.01),Color("737b50"),Vector3(0,0,tilt),.3)
			for x in [-.065,.065]:M.box(self,Vector3(x,.26,0),Vector3(.032,.09,.057),Color("646c47"))
			M.box(self,Vector3(0,.30,0),Vector3(.16,.028,.057),Color("646c47"))
		"tire":
			mass=3.;radius=.34;collider.queue_free()
			for i in range(16):
				var a=i*TAU/16.;add_box_shape(Vector3(sin(a)*.245,cos(a)*.245,0),Vector3(.100,.180,.17),Vector3(0,0,-a))
			var mesh=TorusMesh.new();mesh.inner_radius=.15;mesh.outer_radius=.34;mesh.rings=20;mesh.ring_segments=12
			M.instance(self,mesh,Vector3.ZERO,Color("414845"),Vector3(PI/2,0,0))
			for i in range(16):
				var angle=i*TAU/16.;M.box(self,Vector3(sin(angle)*.323,cos(angle)*.323,0),Vector3(.052,.024,.16),Color("333b3b"),Vector3(0,0,-angle),.45)
		"table":
			mass=12.;radius=.95;collider.queue_free();WorldDressing.furniture(self,6,false)
			for mesh in get_children():
				if mesh is MeshInstance3D:
					var c=CollisionShape3D.new();c.shape=mesh.mesh.create_convex_shape(true,false);c.transform=mesh.transform;add_child(c)
	M.merge_children(self)
func _ready():
	home=global_transform;target=home
	if authoritative:sleeping_state_changed.connect(func():set_physics_process(not sleeping))
func hit(point:Vector3,direction:Vector3,damage:float):
	if not authoritative:return
	sleeping=false
	var impulse=direction.normalized()*clampf(damage*.35,2.,14.)
	apply_impulse(impulse,point-global_position)
func reset_home():
	global_transform=home;target=home;linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO;sleeping=false
func _physics_process(dt:float):
	if authoritative:
		# Do not write cached velocities every frame: that erases queued ray-hit impulses.
		if linear_velocity.length_squared()>64.:linear_velocity=linear_velocity.limit_length(8.)
		if angular_velocity.length_squared()>100.:angular_velocity=angular_velocity.limit_length(10.)
		if global_position.y< -12. or global_position.distance_to(home.origin)>24.:reset_home()
	elif received:
		global_transform=global_transform.interpolate_with(target,1.-exp(-dt*18))
func state() -> Array:
	return [prop_id,global_position,quaternion]
func receive(pos:Vector3,rot:Quaternion):
	if authoritative or not pos.is_finite() or not rot.is_finite():return
	target=Transform3D(Basis(rot.normalized()),pos)
	if not received or global_position.distance_to(pos)>4.:global_transform=target
	received=true

func add_box_shape(pos:Vector3,size:Vector3,rot:Vector3=Vector3.ZERO):
	var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;c.position=pos;c.rotation=rot;add_child(c)
func push_by_character(direction:Vector3,speed:float,dt:float):
	if not authoritative or direction.length_squared()<.01:return
	sleeping=false
	var axis=direction.normalized()
	# Overcome static floor friction on first contact; later impulses only close
	# the speed gap, so held movement never accelerates props without a bound.
	var desired=clampf(speed*.72,.6,3.6)
	var deficit=maxf(0.,desired-linear_velocity.dot(axis))
	apply_central_impulse(axis*mass*minf(deficit,maxf(.4,dt*32.)))
