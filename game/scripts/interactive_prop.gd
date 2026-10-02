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
# Junk tyres lie flat (centre this high, half the tyre's width) about half the time.
const TYRE_FLAT=.1
static func tyre_lying(map_index:int,id:int) -> bool:return (id*7+map_index*3)%5<2 or (id+map_index)%7==0
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
		"crate":
			mass=4.;var shape=BoxShape3D.new();shape.size=Vector3(.69,.53,.58);collider.shape=shape
		"cone":
			mass=.8;radius=.25;var shape=ConvexPolygonShape3D.new();var points=PackedVector3Array()
			for y in [-.245,.275]:
				for i in range(20):
					var a=i*TAU/20.;var r=.18 if y<0 else .036;points.append(Vector3(cos(a)*r,y,sin(a)*r))
			shape.points=points;collider.shape=shape
			add_box_shape(Vector3(0,-.265,0),Vector3(.46,.044,.46))
		"canister":
			mass=2.;radius=.35;var shape=BoxShape3D.new();shape.size=Vector3(.30,.46,.18);collider.shape=shape
		"tire":
			mass=3.;radius=.34;collider.queue_free()
			for i in range(16):
				var a=i*TAU/16.;add_box_shape(Vector3(sin(a)*.245,cos(a)*.245,0),Vector3(.100,.180,.17),Vector3(0,0,-a))
			# (1.4.5: drawn by cartoon_visual - a 12-sided low tyre, no tread blocks)
		"table":
			mass=12.;radius=.95;collider.queue_free();WorldDressing.furniture(self,6,false)
			for mesh in get_children():
				if mesh is MeshInstance3D:
					var c=CollisionShape3D.new();c.shape=mesh.mesh.create_convex_shape(true,false);c.transform=mesh.transform;add_child(c)
	M.merge_children(self)
	cartoon_visual()
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
		# 1.4.6: knocked into deep water - it floats back to where it stood
		elif global_position.y< -1. and get_parent().has_method("deep_water") and get_parent().deep_water(global_position):reset_home()
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
# 1.4 cartoon visuals (collision above is unchanged): Toon Shooter pieces
# (assets/props) and a painted steel drum, drawn with the world material.
func cartoon_visual():
	var material=WorldSurface.material("detail",0,true)
	var add=func(mesh:Mesh,offset:Vector3,scale:Vector3):
		var visual=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=material;visual.position=offset;visual.scale=scale;add_child(visual)
	match kind:
		"barrel":
			# 1.4.5 remodel: a real 200 l steel drum (PropModels.drum)
			var kit=DistrictFacade.Kit.new();PropModels.loose_drum(kit,prop_id)
			add.call(kit.detail.commit(),Vector3.ZERO,Vector3.ONE)
		"tire":
			var kit=DistrictFacade.Kit.new();PropModels.tyre(kit)
			add.call(kit.detail.commit(),Vector3.ZERO,Vector3.ONE)
		"crate":add.call(DistrictProps.baked("crate"),Vector3(0,-.265,0),Vector3(.69,.53,.58)/.9)
		"cone":add.call(DistrictProps.baked("trafficcone"),Vector3(0,-.287,0),Vector3.ONE*.77)
		"canister":add.call(DistrictProps.baked("gascan"),Vector3(0,-.23,0),Vector3(.88,1.02,1.2))
