class_name AnimatedDeath
extends CharacterBody3D
## One swept collision body and a baked pose, instead of eleven jointed bodies.
var model:CharacterVisual
var age=0.
var settled=false
func build(source:CharacterVisual,pos:Vector3,push:Vector3,role:int,team:int,facing:float,_crouched:bool,previous_velocity:Vector3,_point:Vector3=Vector3.INF):
	position=pos;rotation.y=facing;collision_layer=0;collision_mask=1;floor_snap_length=.2
	var shape=CollisionShape3D.new();var sphere=SphereShape3D.new();sphere.radius=.18;shape.shape=sphere;shape.position.y=.18;add_child(shape)
	var horizontal=Vector3(push.x,0,push.z).normalized()
	velocity=horizontal*2.0+previous_velocity.limit_length(4.)*.2+Vector3.UP*.7
	model=CharacterVisual.new();model.enable_physics=false;add_child(model);model.build(role,team)
	if is_instance_valid(source):model.scale=source.scale
	var direction=Basis(Vector3.UP,-facing)*push
	var clip="fall_back" if direction.z>=0. else "fall_front"
	if absf(direction.x)>absf(direction.z):clip="fall_right" if direction.x>0. else "fall_left"
	model.animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	model.animator.play(clip);model.animator.advance(0.);model.sync_deform()
func _physics_process(dt:float):
	if settled:return
	velocity.y-=18.*dt
	var drag=7. if is_on_floor() else .8
	velocity.x=move_toward(velocity.x,0.,drag*dt);velocity.z=move_toward(velocity.z,0.,drag*dt)
	move_and_slide()
	if age>1.2 and is_on_floor() and velocity.length_squared()<.01:settled=true;set_physics_process(false)
func _process(dt:float):
	age+=dt
	if age<1.1:model.animator.advance(dt)
	if age>=.9:
		# Relax into a spread, flat resting pose instead of a permanently bent squat.
		model.left_arm.rotation=Vector3(0,0,-.9);model.right_arm.rotation=Vector3(0,0,.9)
		model.left_elbow.rotation=Vector3(.08,0,0);model.right_elbow.rotation=Vector3(.08,0,0)
		for side in [-1,1]:
			var leg=model.hips.get_node("LeftLeg" if side<0 else "RightLeg")
			leg.rotation=Vector3(.03,0,side*.20);leg.get_node("Knee").rotation=Vector3(-.08,0,0)
		model.chest.rotation=Vector3.ZERO
	model.sync_deform()
	if age>4.5:model.scale=Vector3.ONE*maxf(.01,1.-(age-4.5)*2.)
	if age>=5.:queue_free()
