extends Node3D
class_name BurstVisual
static var texture:Texture2D
static var debris_count=0
static var quad_mesh:QuadMesh
static var debris_shapes={}
var puffs:Array=[]
var age=0.
var blast_scale=1.
var bomb=false
var pooled=false
var active=false
var debris:Array=[]
## 1.4.6: the shader warm-up burst (CombatFx.warm_effects) is drawn but never
## seen - the user saw it as a puff of smoke and flying bits on entering a map.
var ghost=false
func retire():
	active=false;hide();set_process(false)
	for body in debris:
		if is_instance_valid(body):body.queue_free()
	debris.clear()
func build(fire:bool):
	age=0.;active=true;show();set_process(true)
	if texture==null:texture=load("res://assets/textures/smoke_particle_v103.png")
	if quad_mesh==null:quad_mesh=QuadMesh.new();quad_mesh.size=Vector2.ONE
	var rng=RandomNumberGenerator.new();rng.randomize()
	for i in range(24):
		var flame=fire and i<7;var dust=i>=18;var angle=i*2.39996
		var mesh:MeshInstance3D;var mat:StandardMaterial3D
		if i<puffs.size():mesh=puffs[i].node;mat=puffs[i].material
		else:
			mesh=MeshInstance3D.new();mesh.mesh=quad_mesh;add_child(mesh);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mat=StandardMaterial3D.new();mat.albedo_texture=texture;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.billboard_keep_scale=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.hide();mesh.position=Vector3.ZERO;mesh.scale=Vector3.ONE
		mat.albedo_color=Color(1.,.46,.085,.95) if flame else Color(.24,.27,.29,.64) if not dust else Color(.55,.48,.36,.34)
		mat.emission_enabled=flame
		if flame:mat.emission_enabled=true;mat.emission=Color(1.,.30,.035);mat.emission_energy_multiplier=1.6;mat.emission_texture=texture
		mesh.material_override=mat
		var direction=Vector3(cos(angle),rng.randf_range(.4,1.4),sin(angle)).normalized()
		var puff={"node":mesh,"material":mat,"delay":float(i%6)*.012,"life":(.85 if flame else 2.4 if dust else 7.) if bomb else (.44 if flame else 1.2 if dust else 2.8),"velocity":direction*(2.3 if dust else 1.05),"size":rng.randf_range(1.8,2.9) if not dust else 2.3,"alpha":mat.albedo_color.a,"flame":flame,"dust":dust}
		if i<puffs.size():puffs[i]=puff
		else:puffs.append(puff)
	# Fire/smoke puffs above remain identical at every quality; only tiny debris scales.
	if GraphicsOptions.physics_effects<2 or OS.has_feature("web"):return
	# (the warm-up burst draws one debris piece too, shrunk out of sight, so its
	# material is ready before the first real explosion)
	for i in range(1 if ghost else [4,8,12][GraphicsOptions.detail]):
		if debris_count>=[12,36,72][GraphicsOptions.detail]:break
		var body=RigidBody3D.new();add_child(body);body.position=Vector3.UP*.3;body.mass=.04;body.collision_layer=0;body.collision_mask=1;body.continuous_cd=true;body.linear_damp=.25
		var size=[Vector3(.05,.045,.065),Vector3(.075,.045,.10),Vector3(.105,.045,.135)][i%3];MeshFactory.box(body,Vector3.ZERO,size,Color("686e70"))
		if not debris_shapes.has(i%3):var box=BoxShape3D.new();box.size=size;debris_shapes[i%3]=box
		var collision=CollisionShape3D.new();collision.shape=debris_shapes[i%3];body.add_child(collision);debris.append(body)
		if ghost:
			for m in body.get_children():
				if m is MeshInstance3D:m.scale=Vector3.ONE*.001
		body.linear_velocity=Vector3(rng.randf_range(-4.5,4.5),rng.randf_range(2.,5.5),rng.randf_range(-4.5,4.5));body.angular_velocity=Vector3(6,9,4)
		debris_count+=1;body.tree_exited.connect(func():debris_count=maxi(0,debris_count-1))
func _process(dt:float):
	age+=dt
	for puff in puffs:
		var t=(age-puff.delay)/puff.life;puff.node.visible=t>=0. and t<1.
		if not puff.node.visible:continue
		var expansion=1.-pow(1.-t,3.)
		puff.node.position=blast_scale*puff.velocity*expansion*(1.1 if puff.flame else 2.2)+Vector3.UP*(.25 if puff.dust else .35+t*.7)
		puff.node.scale=Vector3.ONE*(.35+expansion*puff.size)*blast_scale
		puff.material.albedo_color.a=puff.alpha*(1.-smoothstep(.12 if puff.flame else .35,1.,t))*smoothstep(0.,.07,t)*(.003 if ghost else 1.)
		if puff.flame:puff.material.emission_energy_multiplier=1.6*(1.-t)*(.003 if ghost else 1.)
	if age>(7.2 if bomb else 3.):
		if pooled:retire()
		else:queue_free()
