class_name AnimatedDeath
extends Node3D
## A complete death pose without rigid bodies, joints, or per-frame floor rays.
var model:CharacterVisual
var age=0.
func build(source:CharacterVisual,pos:Vector3,push:Vector3,role:int,team:int,facing:float,_crouched:bool,_velocity:Vector3,_point:Vector3=Vector3.INF):
	position=pos;rotation.y=facing
	model=CharacterVisual.new();model.enable_physics=false;add_child(model);model.build(role,team)
	if is_instance_valid(source):model.scale=source.scale
	var direction=Basis(Vector3.UP,-facing)*push
	var clip="fall_back" if direction.z>=0. else "fall_front"
	if absf(direction.x)>absf(direction.z):clip="fall_right" if direction.x>0. else "fall_left"
	model.animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	model.animator.play(clip);model.animator.advance(0.);model.sync_deform()
func _process(dt:float):
	age+=dt
	if age<1.:model.animator.advance(dt);model.sync_deform()
	if age>4.5:
		scale=Vector3.ONE*maxf(.01,1.-(age-4.5)*2.)
	if age>=5.:queue_free()
