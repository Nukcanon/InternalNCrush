class_name HeroDeath
extends CharacterBody3D
## Lightweight (web) corpse: one swept sphere and the outfit's own death clip,
## launched along the killing shot like the native ragdoll.
var hero:HeroCharacter
var age=0.
var settled=false
func build(source:HeroCharacter,pos:Vector3,push:Vector3,role:int,team:int,facing:float,_crouched:bool,previous_velocity:Vector3,_point:Vector3=Vector3.INF):
	position=pos;rotation.y=facing;collision_layer=0;collision_mask=1;floor_snap_length=.2
	var shape=CollisionShape3D.new();var sphere=SphereShape3D.new();sphere.radius=.18;shape.shape=sphere;shape.position.y=.18;add_child(shape)
	var horizontal=Vector3(push.x,0,push.z).normalized()
	velocity=horizontal*3.4+previous_velocity.limit_length(4.)*.2+Vector3.UP*1.6
	hero=HeroCharacter.new();add_child(hero);hero.build(role,team,false)
	if is_instance_valid(source):hero.scale=source.scale;hero.dress_like(source)
	# The death clip falls backward: turn the back (+Z) along the shot.
	var local=Basis(Vector3.UP,-facing)*push
	if Vector2(local.x,local.z).length()>.01:hero.rotation.y=atan2(local.x,local.z)
	hero.play("Death" if hero.player.has_animation("Death") else "Death01")
	hero.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
func torso_axis() -> Vector3:
	return (hero.bone_world(hero.skeleton.find_bone("Chest")).origin-hero.bone_world(hero.skeleton.find_bone("Hips")).origin).normalized()
func _physics_process(dt:float):
	if settled:return
	velocity.y-=18.*dt
	var drag=7. if is_on_floor() else .8
	velocity.x=move_toward(velocity.x,0.,drag*dt);velocity.z=move_toward(velocity.z,0.,drag*dt)
	move_and_slide()
	if age>1.2 and is_on_floor() and velocity.length_squared()<.01:settled=true;set_physics_process(false)
func _process(dt:float):
	age+=dt
	if age>4.5:hero.scale=Vector3.ONE*maxf(.01,1.-(age-4.5)*2.)
	if age>=5.:queue_free()
