extends CharacterBody3D
class_name Actor
const Aim=preload("res://scripts/aim_model.gd")
var pid=0
var game:Node
var camera:Camera3D
var body_mesh:Node3D
var head_mesh:Node3D
var limbs:Node3D
var tag:Label3D
var health_tag:Label3D
var shape:CollisionShape3D
var gun:Node3D
var view_space:Node3D
var item_model:Node3D
var gadget_world:GadgetVisual
var bomb_view:Node3D
# The mount pose (and the hand's frame on it) as the current throw began.
var throw_start={}
var view_weapon:GunModel
var world_weapon:GunModel
var render_root:Node3D
var character:HeroCharacter
# First person: the same hero (head hidden) under the camera, hands on view_weapon.
var view_body:HeroCharacter
var view_mount:Node3D
var hit_time=-100.
var held_holder:Node3D
var view_item:Node3D # first-person gadget carried by view_body
var protected_visual:MeshInstance3D
var melee_view:MeleeVisual
var melee_world:MeleeVisual
var melee_role=-1
var item_signature=""
var reload_stage=-1
var body_height=1.8
var shown_role=-1
var shown_team=-1
var spread_angle=.4
var visual_spread=.4
var move_blend=0.
var ads_blend=0.
var aim_progress=0.
var handedness=1
var crouch_blend=0.
var land_kick=0.
var was_grounded=true
var seen_shot=-100.
var net_velocity=Vector3.ZERO
var net_grounded=true
var net_sprint=false
var remote_ads=false
var legs=[]
var arms=[]
var team_material:StandardMaterial3D
var input_state={"x":0.0,"z":0.0,"yaw":0.0,"pitch":0.0,"ads":false,"sprint":false,"crouch":false,"fire":false,"melee":false,"alt":false,"use":false,"jump":false,"trigger_seq":0}
var aim_yaw=0.0
var aim_pitch=0.0
var sprint_release=0.0
const SPRINT_OUT=.15
var load_hold=0. # 0..1 steady loading pose of round-by-round reloads
var pair_swing=0. # 1.4.5: DUET sprint arm swing blend
const PAIR_SWING=.05 # metres each way
const HIP_YAW_GEAR=.13 # held gear (not guns) still turns in a little at the hip
const PAIR_HIP=.54 # DUET: the pair's spacing at the hip (drawn together to PAIR_AIM when aiming); 1.4.5: wider (was .40)
const PAIR_AIM=.36
var sprint_fov=0. # 0..1 blend toward the sprint field of view
var last_sprint=false
var target_pos=Vector3.ZERO
var local=false
var bob=0.0
var step_clock=0.0
var grounded_jump=false
var shown_weapon=""
var weapon_models={}
var recoil=0.0
var hit_recoil=0.0
var hit_side=0.0
var old_visual_pos=Vector3.ZERO
var gait=0.
var net_gait=0.
var net_gait_target=0.
var motion_seed=0.
var previous_yaw=0.
var turn_sway=0.
var shot_serial=0
var fall_peak=0.
var falling=false
## 1.4.6 (the user): falls of a storey (~3 m) are free, two storeys (6 m) cost
## 60, three storeys (9 m) and more kill. Health only (game.damage: armour and
## the heavy's guard never absorb a fall; the medic's invulnerability does).
const FALL_SAFE=3.2
const FALL_LETHAL=9.
static func fall_damage(height:float) -> float:
	if height>=FALL_LETHAL:return 10000.
	return maxf(0.,(height-FALL_SAFE)*60./(6.-FALL_SAFE))
var rotation_target_extra=Vector3.ZERO # hip-only view-model tilt (one-handed pistol cant)
var launcher_tilt=0. # 0..1: launcher tipped forward so the rear end can be loaded
# Third-person loading pose: far enough ahead of the chest that the arms stay outside the torso.
const LOAD_SHIFT=Vector3(-.03,-.24,-.52)
const LOAD_YAW=.22
const LOAD_PITCH=1.0 # muzzle down so the rocket lined up behind the rear end clears the chest
const STEP_HEIGHT=.28
func _ready():
	motion_seed=fposmod(float(pid)*2.39996,TAU)
	collision_layer=2;collision_mask=1|4|8
	shape=CollisionShape3D.new();var cap=CapsuleShape3D.new();cap.radius=.25;cap.height=1.8;shape.shape=cap;shape.position.y=.9;add_child(shape)
	render_root=Node3D.new();add_child(render_root)
	tag=Label3D.new();tag.font=game.ui.theme.default_font;tag.position.y=2.;tag.font_size=32;tag.outline_size=8;tag.outline_modulate=Color("101f2d");tag.pixel_size=.004;tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(tag)
	health_tag=Label3D.new();health_tag.font=game.ui.theme.default_font;health_tag.font_size=30;health_tag.outline_size=8;health_tag.pixel_size=.003;health_tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;health_tag.no_depth_test=true;health_tag.fixed_size=true;health_tag.hide();add_child(health_tag)
	camera=Camera3D.new();camera.position.y=1.62;camera.fov=82;camera.far=300;camera.near=.08;add_child(camera)
	# 1.4.4: the view model (gun, hands, arms, held gear) lives in a view space
	# VIEW_DEPTH times larger and farther: the same size on screen with less
	# perspective stretch (shooters draw it with a narrower field of view).
	view_space=Node3D.new();view_space.name="ViewSpace";view_space.scale=Vector3.ONE*VIEW_DEPTH;camera.add_child(view_space)
	gun=Node3D.new();view_space.add_child(gun)
	item_model=Node3D.new();gun.add_child(item_model)
	protected_visual=MeshInstance3D.new();var shield=CapsuleMesh.new();shield.radius=.54;shield.height=2.05;protected_visual.mesh=shield;protected_visual.position.y=1.;render_root.add_child(protected_visual)
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.3,.8,1,.25);mat.cull_mode=BaseMaterial3D.CULL_DISABLED;protected_visual.material_override=mat;protected_visual.visible=false;protected_visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func build_gun(wid:String):
	if is_instance_valid(view_weapon):view_weapon.hide()
	if is_instance_valid(world_weapon):world_weapon.hide()
	var state=game.players.get(pid,{})
	for key in weapon_models.keys():
		if key not in [state.get("primary",wid),state.get("secondary",wid)]:
			for node in weapon_models[key]:
				if is_instance_valid(node):node.queue_free()
			weapon_models.erase(key)
	if weapon_models.has(wid):
		view_weapon=weapon_models[wid][0];world_weapon=weapon_models[wid][1]
		if is_instance_valid(world_weapon):
			world_weapon.show()
			if is_instance_valid(character):character.hold(world_weapon)
			if is_instance_valid(view_weapon):view_weapon.show()
			return
		weapon_models.erase(wid)
	view_weapon=null;world_weapon=null
	var w=Catalog.get_weapon(wid)
	if local:
		ensure_view_body()
		# Long guns are compact in the view; pistols keep their size next to the big cartoon hand.
		view_weapon=GunModel.new();view_weapon.build(w,false);view_mount.add_child(view_weapon);view_weapon.scale=Vector3.ONE*view_weapon_scale(w)
	world_weapon=GunModel.new();world_weapon.build(w,HeroStyle.outlines_enabled())
	if is_instance_valid(character):character.hold(world_weapon)
	else:render_root.add_child(world_weapon)
	weapon_models[wid]=[view_weapon,world_weapon]
func set_local(on:bool):
	local=on;camera.current=on;render_root.visible=not on;tag.visible=not on;gun.visible=on
func set_team(t:int):
	if not game.players.has(pid):return
	var role=int(game.players[pid].role) if game.options.classes else 0
	if role==shown_role and t==shown_team:return
	for pair in weapon_models.values():
		for node in pair:
			if is_instance_valid(node):node.queue_free()
	weapon_models.clear();view_weapon=null;world_weapon=null
	shown_role=role;shown_team=t
	body_height=HeroCharacter.HEIGHTS[role];tag.position.y=body_height+.18
	shape.shape.height=body_height;shape.position.y=body_height*.5
	protected_visual.scale.y=body_height/1.8
	if is_instance_valid(character):character.queue_free()
	character=null
	if is_instance_valid(view_body):view_body.queue_free()
	view_body=null
	if game.render_actors:ensure_character()
	shown_weapon=""
func ensure_character():
	if is_instance_valid(character):
		if not character.get_meta("pose_only",false):return
		character.queue_free();character=null;shown_weapon=""
	character=HeroCharacter.new();render_root.add_child(character);character.build(shown_role,shown_team,HeroStyle.outlines_enabled())
func ensure_view_body():
	if is_instance_valid(view_body):return
	if not is_instance_valid(view_mount):view_mount=Node3D.new();view_mount.name="ViewMount";gun.add_child(view_mount)
	var _pv=Prof.now();view_body=HeroCharacter.new();view_body.name="ViewBody";camera.add_child(view_body);view_body.build(maxi(0,shown_role),maxi(0,shown_team),false);Prof.add("view_body_build",_pv);_pv=Prof.now()
	view_body.first_person_only();Prof.add("view_body_fp_only",_pv);view_body.frame_override=view_mount;view_body.hand_size=VIEW_HAND/VIEW_BODY_SCALE
	view_body.set_meta("fp_camera",camera);view_body.set_meta("fp_space",view_space)
	for mesh in view_body.meshes():mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func ensure_hit_pose():
	if is_instance_valid(character):return
	# Server-authoritative anatomy: the same hero skeleton and clips, no outlines.
	character=HeroCharacter.new();render_root.add_child(character);character.build(maxi(0,shown_role),maxi(0,shown_team),false);character.set_meta("pose_only",true)
	for mesh in character.meshes():mesh.hide()
	character.drive(1./60.,pose_state(game.players.get(pid,{}),game.clock,-1.,false))

func reset_view(yaw:float):
	camera.top_level=false;camera.transform=Transform3D(Basis.IDENTITY,Vector3(0,eye_height(false),0))
	input_state.yaw=yaw;input_state.pitch=0.;input_state.crouch=false;input_state.sprint=false;input_state.fire=false;input_state.ads=false;input_state.x=0.;input_state.z=0.;input_state.jump=false
	aim_yaw=yaw;aim_pitch=0.;rotation=Vector3(0,yaw,0);last_sprint=false;sprint_release=0.;sprint_fov=0.;old_visual_pos=global_position;spread_angle=.4;visual_spread=.4;seen_shot=-100.;recoil=0.;land_kick=0.
	fall_peak=global_position.y;falling=false
	gait=0.;net_gait=0.;net_gait_target=0.;turn_sway=0.;previous_yaw=yaw;aim_progress=0.;ads_blend=0.
	handedness=int(game.players.get(pid,{}).get("hand",1))
	if local:
		camera.current=true
		if is_instance_valid(game.ui.damage_indicator):game.ui.damage_indicator.clear_hits()
func eye_height(crouched:bool) -> float:return (1.30 if crouched else 1.62)*body_height/1.8
func head_threshold() -> float:return (1.14 if input_state.crouch else 1.46)*body_height/1.8
func eye() -> Vector3:return global_position+Vector3.UP*eye_height(bool(input_state.crouch))
func direction() -> Vector3:return Basis(Vector3.UP,aim_yaw)*Basis(Vector3.RIGHT,aim_pitch)*Vector3.FORWARD
func desired_muzzle() -> Vector3:
	# Use the authoritative ADS transition, not the cosmetic view-model transform.
	var blend=clampf(aim_progress,0.,1.)
	var offset=Vector3(lerpf(.20,.025,blend)*handedness,lerpf(-.46,-.045,blend)*body_height/1.8,0.)
	return eye()+Basis(Vector3.UP,aim_yaw)*offset+direction()*lerpf(.55,.48,blend)
func muzzle_world() -> Vector3:
	var desired=desired_muzzle()
	var hit=game.ray(eye(),desired,[get_rid()],1|4|8)
	return hit.position+hit.normal*.03 if not hit.is_empty() else desired
func visual_muzzle() -> Vector3:
	if local and is_instance_valid(view_weapon) and view_weapon.visible:return view_weapon.muzzle.global_position
	if not local and is_instance_valid(world_weapon) and world_weapon.visible:return world_weapon.muzzle.global_position
	return muzzle_world()
func react_hit(push:Vector3):
	hit_recoil=1.;hit_side=clampf(global_basis.x.dot(push),-1,1);hit_time=game.clock
func simulate(dt:float,now:float,can_move:bool):
	aim_yaw=float(input_state.yaw);aim_pitch=clampf(float(input_state.pitch),-1.45,1.45);rotation.y=aim_yaw
	var sliding=game.players.get(pid,{}).get("slide_until",0)>now
	var crouch=bool(input_state.crouch) or sliding
	if not crouch and shape.shape.height<body_height-.01:
		var q=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP*(body_height+.05),1|4|8);q.exclude=[get_rid()]
		crouch=not get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	input_state.crouch=crouch
	shape.shape.height=(1.45/1.8*body_height) if crouch else body_height;shape.position.y=shape.shape.height*.5

	var cooking=game.players.get(pid,{}).get("cooking",0)>0
	var sprint=not cooking and not MeleeCombat.active(game.players.get(pid,{}),now) and bool(input_state.sprint) and not crouch and not input_state.ads and not input_state.fire
	# 1.4.2: firing out of a sprint waited half a second (and the sprint FOV
	# snapped back like a zoom): the gun now comes up in SPRINT_OUT seconds.
	if last_sprint and not sprint:sprint_release=now+SPRINT_OUT
	last_sprint=sprint
	var speed=Rules.RUN_SPEED if sprint else Rules.CROUCH_SPEED if crouch else Rules.WALK_SPEED
	if game.arena and game.arena.wading(global_position):speed*=.72
	if game.players.has(pid):
		var p=game.players[pid]
		var weapon=game.current_weapon(p)
		speed*=[1.,.94,.88][clampi(int(p.armor_max)/25,0,2)]
		if p.get("placing","")=="cover":speed*=[.9,.72,.55][clampi(int(p.gadget),0,2)]
		if input_state.ads and p.slot<2:speed=minf(speed,float(weapon.get("ads_speed",4.4))*.5)
		elif p.slot<2:speed*=float(weapon.get("move_speed_scale",1.))
		if p.get("slow",0)>now:speed*=.35
		if p.get("shield",0)>now:speed*=.6
		if p.get("dash",0)>now:speed*=2.1
		elif p.get("dash_recovery",0)>now:speed*=1.65
		if Catalog.get_weapon(p.primary).role==2:speed*=.9
	var wish=Vector3(float(input_state.x),0,float(input_state.z)).limit_length(1)
	wish=Basis(Vector3.UP,aim_yaw)*wish
	var target_velocity=wish*speed if can_move else Vector3.ZERO
	if sliding and can_move:
		var p=game.players[pid];var age=now-float(p.slide_started);target_velocity=p.slide_direction*maxf(2.4,Rules.SLIDE_SPEED-age*Rules.SLIDE_DECAY)
		if not is_on_floor():p.slide_until=now
	var acceleration=40. if sliding else 22. if wish.length_squared()>.01 else 28.
	if not is_on_floor():acceleration=16.
	if game.players.get(pid,{}).get("blast_until",0)>now:acceleration=1.5
	var planar=Vector2(velocity.x,velocity.z).move_toward(Vector2(target_velocity.x,target_velocity.z),acceleration*dt)
	velocity.x=planar.x;velocity.z=planar.y
	if not can_move:velocity.x=0.;velocity.z=0.
	if not is_on_floor():velocity.y-=22*dt
	elif input_state.jump and not grounded_jump and can_move:velocity.y=6
	grounded_jump=bool(input_state.jump)
	was_grounded=is_on_floor()
	var before=global_position
	if can_move and game.players.get(pid,{}).get("blast_until",0)<=now:
		if not try_mantle():try_low_step(dt)
	move_and_slide()
	# Collision recovery can nudge a stationary spawn sideways. That is not a
	# walking step, especially while movement is disabled during round setup.
	if is_on_floor() and can_move and Vector2(velocity.x,velocity.z).length_squared()>.0025:
		gait+=Vector2(global_position.x-before.x,global_position.z-before.z).length()/(2.*Rules.step_length(sprint,crouch))
	if not is_on_floor():
		if not falling:fall_peak=before.y;falling=true
		fall_peak=maxf(fall_peak,global_position.y)
	if not was_grounded and is_on_floor():
		land_kick=clampf((fall_peak-global_position.y)*.008,.035,.14)
		if game.server and game.phase=="combat" and falling and not game.arena.wading(global_position):
			var amount=fall_damage(fall_peak-global_position.y)
			if amount>0.:game.damage(pid,amount,pid,false,"fall")
		falling=false
	if game.server and can_move:
		var pushed={}
		for i in range(get_slide_collision_count()):
			var collision=get_slide_collision(i);var body=collision.get_collider()
			if body is InteractiveProp and body.mass<=15. and not pushed.has(body.get_instance_id()):
				var push=-collision.get_normal();push.y=0.
				if push.length_squared()<.1 or target_velocity.dot(push)<=0.:continue
				pushed[body.get_instance_id()]=true
				body.push_by_character(push,target_velocity.length(),dt);velocity.x*=.82;velocity.z*=.82
	update_spread(dt,now)
	if game.server and game.phase=="combat" and is_instance_valid(game.arena) and game.arena.fatal_water(global_position):
		game.damage(pid,10000.,pid,false,"water")
	var bound=game.arena.bounds if is_instance_valid(game.arena) else Vector2(100,90)
	if is_instance_valid(game.arena) and game.arena.get_meta("water_kind","")=="sea":bound+=Vector2.ONE*7.
	global_position.x=clampf(global_position.x,-bound.x+2,bound.x-2);global_position.z=clampf(global_position.z,-bound.y+2,bound.y-2)
	if global_position.y< (-12. if game.arena and game.arena.vertical_map else -4.):
		# Irregular maps have genuine voids. Raising Y at the same X/Z would
		# repeatedly drop the actor into the same hole instead of recovering.
		var safe=Vector3(global_position.x,.2,global_position.z)
		if game.arena and game.arena.has_meta("district"):
			var nav=game.bot_navigation;var cell=nav.nearest(safe)
			if not nav.grid.is_point_solid(cell):safe=nav.point(cell)+Vector3.UP*.2
			else:
				var distance=INF
				var fallen_position=safe
				for spawn in game.arena.ffa_spawns:
					if spawn.distance_squared_to(fallen_position)<distance:distance=spawn.distance_squared_to(fallen_position);safe=spawn+Vector3.UP*.1
		global_position=safe;velocity=Vector3.ZERO
func try_mantle() -> bool:
	if not input_state.jump or float(input_state.z)>-.5 or velocity.y< -3. or input_state.crouch:return false
	var forward=Basis(Vector3.UP,aim_yaw)*Vector3.FORWARD
	var motion=forward*(float(shape.shape.radius)+.38)
	var obstacle=KinematicCollision3D.new()
	if not test_move(global_transform,motion,obstacle) or obstacle.get_collider() is RigidBody3D or absf(obstacle.get_normal().y)>.3:return false
	var lift=1.35 if is_on_floor() else .8
	if test_move(global_transform,Vector3.UP*lift):return false
	var raised=global_transform;raised.origin.y+=lift
	if test_move(raised,motion):return false
	raised.origin+=motion
	var landing=KinematicCollision3D.new()
	if not test_move(raised,Vector3.DOWN*lift,landing) or landing.get_normal().y<cos(floor_max_angle) or landing.get_collider() is RigidBody3D:return false
	var rise=lift+landing.get_travel().y
	if rise<.1 or rise>lift:return false
	global_position=raised.origin+landing.get_travel()+Vector3.UP*.006
	velocity.y=0.;land_kick=.08;return true
func try_low_step(dt:float) -> bool:
	# Only a grounded walk may step: never climb in mid-air or cancel a jump.
	if not is_on_floor() or velocity.y>0. or input_state.jump:return false
	var motion=Vector3(velocity.x,0,velocity.z)*dt
	if motion.length_squared()<.000001:return false
	var obstacle=KinematicCollision3D.new()
	if not test_move(global_transform,motion,obstacle):return false
	if obstacle.get_collider() is RigidBody3D:return false # Push small props instead.
	if obstacle.get_normal().y>=cos(floor_max_angle):return false
	# Clear the tread by a small collision margin; keep the actual step limit below.
	var clearance=STEP_HEIGHT+.01
	if test_move(global_transform,Vector3.UP*clearance):return false
	var raised=global_transform;raised.origin.y+=clearance
	# A capsule touching the riser is still outside its top surface. Probe one
	# foot radius ahead so the downward sweep finds the tread, not the corner.
	var step_motion=motion.normalized()*maxf(motion.length(),float(shape.shape.radius)+.03)
	if test_move(raised,step_motion):return false
	raised.origin+=step_motion
	var landing=KinematicCollision3D.new()
	if not test_move(raised,Vector3.DOWN*(clearance+.02),landing):return false
	if landing.get_collider() is RigidBody3D or landing.get_normal().y<cos(floor_max_angle):return false
	var rise=clearance+landing.get_travel().y
	if rise<=.005 or rise>STEP_HEIGHT+safe_margin*2.:return false
	global_position.y+=rise+.002
	return true
func update_spread(dt:float,now:float):
	if not game.players.has(pid):return
	var p=game.players[pid];var w=game.current_weapon(p)
	aim_progress=move_toward(aim_progress,1. if input_state.ads and p.slot<2 and p.reload<=now else 0.,dt/maxf(.08,float(w.get("ads_ms",250))*.001*(1.+float(p.armor_max)/250.)))
	var target=Aim.spread(w,Vector2(velocity.x,velocity.z).length(),bool(input_state.ads),bool(input_state.crouch),last_sprint,is_on_floor(),float(p.get("bloom",0)),GadgetLoadout.mounted(p,bool(input_state.crouch)),velocity.y,aim_progress)
	if p.get("slide_until",0)>now:target+=2.3
	spread_angle=lerpf(spread_angle,target,1.-exp(-dt*(18 if target>spread_angle else 13.)))
func update_melee(p:Dictionary,now:float):
	var shown=MeleeCombat.shown(p,now)
	if shown and (not is_instance_valid(melee_world) or melee_role!=int(p.role)):
		if is_instance_valid(melee_world):melee_world.queue_free()
		if is_instance_valid(melee_view):melee_view.queue_free()
		melee_role=int(p.role)
		melee_world=MeleeVisual.new();character.hand_attachment("R").add_child(melee_world);melee_world.build(MeleeCombat.wrench(p),melee_role,false)
		if local:
			# 1.4.4: the first-person tool rides the view body's hand bone; the
			# arm is swung instead (MeleeVisual.swing_wrist, update_view_body).
			ensure_view_body()
			melee_view=MeleeVisual.new();view_body.hand_attachment("R").add_child(melee_view);melee_view.build(MeleeCombat.wrench(p),melee_role,true)
	if is_instance_valid(melee_world):melee_world.visible=shown;melee_world.pose(-1.)
	if is_instance_valid(melee_view):melee_view.visible=shown
# Animation state for HeroCharacter.drive(), shared by render and server poses.
func pose_state(p:Dictionary,now:float,progress:float,item_visible:bool) -> Dictionary:
	var networked=not local and not game.server
	var w:Dictionary=game.current_weapon(p) if not p.is_empty() else {}
	var s={"velocity":net_velocity if networked else velocity,"grounded":net_grounded if networked else is_on_floor(),"crouch":bool(input_state.crouch),
		"sprint":net_sprint if networked else last_sprint,"pitch":aim_pitch,"reload":progress,"reload_time":float(w.get("reload",2.)),
		"shot":now-float(p.get("shot_time",-100.)),"hit":clampf(1.-(now-hit_time)/.3,0.,1.),"melee":now-float(p.get("melee_started",-100.))}
	if p.is_empty():return s
	# Reload hand work needs the chambered-round rule and the tube count.
	s.reload_tactical=bool(p.get("reload_tactical",false));s.rounds=int(p.get("mag",{}).get(p.primary if p.slot==0 else p.secondary,0))
	if p.get("slide_until",0)>now:s.slide=clampf((now-float(p.slide_started))/Rules.SLIDE_DURATION,0.,1.)
	if p.get("cooking",0)>0 or float(p.get("throw_until",-100.))>now:
		s.throw=clampf((now-float(p.get("grenade_started",now)))/maxf(.2,float(p.get("throw_until",now+.3))-float(p.get("grenade_started",now))),0.,1.)
	var hold="none"
	if BombHandling.active(self):s.plant=true
	elif MeleeCombat.shown(p,now):hold="none"
	elif item_visible:hold="item"
	elif p.slot<2 and (p.slot!=0 or p.get("owned_primary",true)) and p.get("cooking",0)==0 and p.get("throw_until",0)<=now and p.get("placing","")=="":
		hold=GunLooks.hold_kind(w)
		if hold=="shoulder":hold="rifle"
	s.hold=hold;s.hands=0. if hold=="none" else 1.
	if hold=="item" and is_instance_valid(held_holder):s.two_hands=bool(held_holder.get_meta("two_handed",false))
	# 1.4.2: pistols and pistol-grip tools are held in both hands.
	if hold=="pistol":s.two_hands=true
	return s
# Legacy gadget meshes are carried through grip markers until the gear pass.
func holder_for(item:Node3D,right:Vector3,left:Vector3,two_handed:bool,grip:Dictionary={}) -> Node3D:
	var holder=Node3D.new();holder.name="HeldItem";holder.add_child(item)
	for marker in [["RightGrip",right],["LeftGrip",left]]:
		var m=Marker3D.new();m.name=marker[0];m.position=marker[1];holder.add_child(m)
	holder.set_meta("two_handed",two_handed)
	# Sockets are the points the palms wrap: cupped when one-handed, a fist on
	# each side when two-handed. Gear may name its own grip styles and shapes.
	var styles={"R":"pistol" if two_handed else "hold","L":"pistol"};var shapes={}
	for side in grip:
		styles[side]=str(grip[side].get("style",styles.get(side,"pistol")))
		if grip[side].has("shape"):shapes[side]=grip[side].shape
	holder.set_meta("grip_styles",styles);holder.set_meta("grip_shapes",shapes)
	if item is GadgetVisual and item.field_id!="":holder.set_meta("grip_field_id",item.field_id)
	return holder
# Named descendants looked up once per item (the view model asks every frame).
func cached_child(node:Node,child:String) -> Node:
	var key="child_"+child
	if node.has_meta(key):
		var found=node.get_meta(key)
		if found is Node and is_instance_valid(found):return found
		if found is bool:return null
	var hit=node.find_child(child,true,false)
	node.set_meta(key,hit if hit else false)
	return hit
const HEADLESS_POSE_INTERVAL=2
const HELD_OFFSET=Vector3(0,-.05,.02)
var pose_dt=0.
var pose_frame=0
# Full-rate / half-rate pose distances per decoration tier (low, medium, high).
const POSE_NEAR=[10.,18.,28.]
const POSE_MID=[24.,40.,60.]
func pose_interval() -> int:
	if local:return 1
	var view:=get_viewport().get_camera_3d() if is_inside_tree() else null
	if view==null:return 1
	var at=global_position+Vector3.UP
	var distance=view.global_position.distance_to(at)
	if not view.is_position_in_frustum(at) and distance>2.5:return 4
	var tier=clampi(GraphicsOptions.detail,0,2)
	return 1 if distance<POSE_NEAR[tier] else 2 if distance<POSE_MID[tier] else 3
func headless_pose(p:Dictionary):
	# The same hero skeleton drives authoritative hit volumes (meshes hidden).
	set_team(int(p.team))
	if not local and not game.server:global_position=target_pos;rotation.y=aim_yaw
	shape.shape.height=(1.45/1.8*body_height) if input_state.crouch else body_height;shape.position.y=shape.shape.height*.5
	camera.position=Vector3(0,eye_height(bool(input_state.crouch)),0)
	# Receiving headless peers only need capsules/cameras. Server-only anatomy
	# avoids 32 clients redundantly animating 32 complete authoritative rigs each.
	if not game.server:return
	ensure_hit_pose();character.scale.x=float(p.get("hand",1));character.pose_fingers=false
	var w=game.current_weapon(p);var progress=MagazineReload.progress(game,p,w)
	var held=character.held
	if not held is GunModel or held.spec.get("name","")!=w.get("name",""):
		if is_instance_valid(held):held.queue_free()
		var gun_model=GunModel.new();gun_model.build(w,false);character.hold(gun_model)
		for mesh in gun_model.find_children("*","MeshInstance3D",true,false):mesh.hide()
	# Hit rigs re-pose every other tick (staggered); the volumes still move with
	# the actor every tick. Keeps a 32-player dedicated server within its budget.
	pose_dt+=1./60.;pose_frame+=1
	if (pose_frame+absi(pid))%HEADLESS_POSE_INTERVAL==0 or character.held!=held:
		character.drive(pose_dt,pose_state(p,game.clock,progress,false));pose_dt=0.
func visual(dt:float,p:Dictionary,now:float):
	visible=p.alive and not (is_instance_valid(game.kill_replay) and game.kill_replay.active);set_team(int(p.team));ensure_character()
	if not p.alive:tag.hide();health_tag.hide();return
	handedness=int(p.get("hand",1));character.scale.x=float(handedness);gun.scale.x=float(handedness)
	protected_visual.visible=p.alive and maxf(float(p.get("protect",0)),float(p.get("invulnerable",0)))>now
	protected_visual.material_override.albedo_color=Color(.20,.66,1,.24+sin(now*9)*.045) if p.team==0 else Color(1,.60,.17,.24+sin(now*9)*.045)
	var item_shown=GadgetLoadout.held_visible(p,now) and (p.slot in [2,3] or p.get("cooking",0)>0 or p.get("throw_until",0)>now or p.get("placing","")!="") and not MeleeCombat.shown(p,now)
	if item_shown:
		var signature=str([p.role,p.gadget,p.slot,p.get("placing","")])
		# (the view item lives in the view body's hand once held; a rebuilt view
		# body (team/role change) takes it with it, so it is made again)
		if signature!=item_signature or not is_instance_valid(view_item):
			item_signature=signature
			for child in item_model.get_children():item_model.remove_child(child);child.queue_free()
			var first=GadgetVisual.new();first.build(int(p.role),int(p.gadget),true,p.get("placing","")=="turret");item_model.scale=Vector3.ONE;item_model.position=Vector3.ZERO
			if is_instance_valid(view_item):view_item.queue_free()
			view_item=holder_for(first,first.right_socket,first.left_socket,first.two_handed,first.grip);view_item.position=Vector3(-.04,.04+first.view_lift*.75,.10);item_model.add_child(view_item)
			if is_instance_valid(held_holder):held_holder.queue_free()
			gadget_world=GadgetVisual.new();gadget_world.build(int(p.role),int(p.gadget),false,p.get("placing","")=="turret")
			held_holder=holder_for(gadget_world,gadget_world.right_socket,gadget_world.left_socket,gadget_world.two_handed,gadget_world.grip)
			# The hero's item frame already sits ahead of the chest; a further 28 cm put
			# grenades and kits beyond arm's reach (hands stopped short of them).
			held_holder.position=HELD_OFFSET
	var wid=(p.primary if p.slot==0 else p.secondary) if p.slot<2 or shown_weapon.is_empty() else shown_weapon
	if shown_weapon!=wid:shown_weapon=wid;build_gun(wid)
	var w=Catalog.get_weapon(wid);var age=now-float(p.get("shot_time",-100.))
	if float(p.get("shot_time",-100.))>seen_shot:show_shot(float(p.shot_time))
	recoil=move_toward(recoil,0,dt*5.5);hit_recoil=move_toward(hit_recoil,0,dt*4);land_kick=lerpf(land_kick,0,1.-exp(-dt*12))
	var speed=Vector2(velocity.x,velocity.z).length() if local or game.server else Vector2(net_velocity.x,net_velocity.z).length()
	var grounded=is_on_floor() if local or game.server else net_grounded
	var sprint=last_sprint if local or game.server else net_sprint
	var progress=MagazineReload.progress(game,p,w)
	move_blend=lerpf(move_blend,minf(1,speed/Rules.WALK_SPEED),1.-exp(-dt*9))
	if not local and not game.server and grounded:
		var advance=dt*speed/(2.*Rules.step_length(sprint,bool(input_state.crouch)))
		net_gait+=advance;net_gait_target+=advance
		net_gait+=wrapf(net_gait_target-net_gait,-.5,.5)*(1.-exp(-dt*3.))
	var phase=gait if local or game.server else net_gait
	bob=phase*TAU
	var yaw_delta=wrapf(aim_yaw-previous_yaw,-PI,PI);previous_yaw=aim_yaw;turn_sway=lerpf(turn_sway,clampf(yaw_delta/maxf(dt,.001),-4,4),1.-exp(-dt*10))
	character.set_armor(clampi(int(p.armor_max)/25,0,2))
	var state=pose_state(p,now,progress,item_shown)
	if state.hold=="item" and is_instance_valid(held_holder):character.hold(held_holder)
	elif is_instance_valid(world_weapon):character.hold(world_weapon)
	if is_instance_valid(world_weapon):
		# Two-handed tools held like items (the TETHER pad) are still this weapon.
		world_weapon.visible=state.hold in ["rifle","pistol"] or (state.hold=="item" and character.held==world_weapon)
		world_weapon.fire_side=int(p.mag.get(wid,0))%2;world_weapon.animate_reload(progress,recoil,age);world_weapon.set_rounds(int(p.mag.get(wid,0)),progress)
		# Launchers tip forward while a rocket goes into the rear end, and stay
		# down between the rockets of a tube-by-tube reload.
		var loading=world_weapon.launcher and progress>=0.
		var more=loading and bool(w.get("single_load",false)) and int(p.mag.get(wid,0))+1<int(w.get("mag",1))
		launcher_tilt=move_toward(launcher_tilt,1. if loading and (progress<.86 or more) else 0.,dt*4.5)
		var tip=smoothstep(0.,1.,launcher_tilt)
		# The launcher comes down in front of the chest, muzzle low and turned a
		# little across the body, so the rear opening faces the support hand.
		world_weapon.position=Vector3(0,0,recoil*.045)+LOAD_SHIFT*tip;world_weapon.rotation=Vector3(recoil*.10-LOAD_PITCH*tip,LOAD_YAW*tip,0)
	if is_instance_valid(held_holder):held_holder.visible=state.hold=="item"
	# Pose LOD: far or off-screen heroes re-pose every 2-4 drawn frames (the
	# collected time keeps their animation speed); staggered by id so the work
	# spreads over frames. Near, on-screen and local heroes pose every frame.
	pose_dt+=dt;pose_frame+=1
	var interval=pose_interval()
	if interval<=1 or (pose_frame+absi(pid))%interval==0:
		var _tp=Prof.now();character.drive(pose_dt,state);Prof.add("actor_tp_drive",_tp);pose_dt=0.
	update_melee(p,now)
	if BombHandling.active(self):
		if is_instance_valid(world_weapon):world_weapon.hide()
		if is_instance_valid(gadget_world):gadget_world.hide()
		if is_instance_valid(melee_world):melee_world.hide()
	if is_instance_valid(world_weapon) and MeleeCombat.shown(p,now):world_weapon.hide()
	# 1.4.2: weapons not in hand and the kit show on the body (rebuilt only when
	# the loadout changes; drawing a weapon only toggles its stowed copy).
	CarriedGear.apply(character,CarriedGear.spec_for(p,shown_weapon if is_instance_valid(world_weapon) and world_weapon.visible else "",item_shown))
	if not local:
		TargetReveal.apply(self,p)
		MedicSelection.apply(self)
		if not game.server:global_position=global_position.lerp(target_pos,minf(1,dt*14));rotation.y=lerp_angle(rotation.y,aim_yaw,minf(1,dt*15))
		shape.shape.height=(1.45/1.8*body_height) if input_state.crouch else body_height;shape.position.y=shape.shape.height*.5
		var viewer=game.players.get(game.local_id,{})
		var allied=not viewer.is_empty() and not game.enemies(viewer,p)
		tag.visible=allied
		health_tag.visible=allied and int(viewer.get("role",-1))==5
		AllyHealthLabels.layout(self);health_tag.text="%d HP"%ceili(p.hp);health_tag.modulate=Color("ff3434").lerp(Color("68ef9c"),clampf(float(p.hp)/Rules.max_hp(p),0.,1.))
		tag.modulate=Color("6ccaff") if p.team==0 else Color("ff9b55");tag.text=("◆ " if p.team==0 else "● ")+p.nick
		return
	var reloading=p.reload>now
	var ads=input_state.ads and p.slot<2 and not reloading and not MeleeCombat.shown(p,now)
	ads_blend=move_toward(ads_blend,1. if ads else 0.,dt/maxf(.08,float(w.get("ads_ms",250))*.001*(1.+float(p.armor_max)/250.)));crouch_blend=lerpf(crouch_blend,1. if input_state.crouch else 0.,1.-exp(-dt*14))
	var scoped=ads and SniperScope.overlay(w) and ads_blend>.9
	# ATLAS (semi_scope): a magnified look without optics; the gun leaves the view.
	var semi_scoped=ads and bool(w.get("semi_scope",false)) and ads_blend>.9
	camera.position.x=0.;camera.position.z=0.;camera.rotation=Vector3(aim_pitch,0,0);camera.position.y=lerpf(eye_height(false),eye_height(true),crouch_blend)-land_kick
	sprint_fov=move_toward(sprint_fov,1. if sprint else 0.,dt/.22)
	camera.fov=lerpf(lerpf(82.,88.,smoothstep(0.,1.,sprint_fov)),SniperScope.fov(game.profile,w),ads_blend)
	# View-model anchor: the right handle sits at this point in camera space at
	# the hip. Aiming brings the rear sight (GunModel.aim_point) to the camera
	# axis instead, so the anchor moves to the eye.
	var kind=GunLooks.hold_kind(w);var dual=bool(w.get("dual",false))
	var rocket=bool(w.get("rocket",false));var shoulder=bool(GunLooks.look(w).get("shoulder",false))
	# 1.4.2: a little further out and lower than before, so the stock leaves the
	# view at the lower right and the gripping hand shows (first-person arms lay
	# their forearms out from the grips, HeroIK.fp_forearm).
	# 1.4.4: at the hip every weapon stays in the bottom third of the screen
	# (the user's rule); aiming brings it up to the sight line.
	var cooking=p.get("cooking",0)>0
	var throwing=float(p.get("throw_until",-100.))>now
	var gadget_up=GadgetLoadout.held_visible(p,now) and (p.slot>=2 or cooking or throwing or p.get("placing","")!="") and not MeleeCombat.shown(p,now)
	# Throwables (grenades, smoke, flash) are held up where they are seen: the
	# lower right of the view with the hand under them, not down at the gun's
	# hip height (the grenade was at the bottom edge, behind the HUD).
	var throwable=gadget_up and (cooking or throwing or p.slot==2) and GrenadeLogic.equipped(p)
	var hip_base:Vector3=THROW_HOLD if throwable else hip_base_for(w,gadget_up)
	var ads_base=(Vector3(.25,-.21,-.50) if shoulder else Vector3(.29,-.27,-.50)) if rocket else hip_base+Vector3(0,.07,-.03) if dual else Vector3.ZERO
	var base=hip_base.lerp(ads_base,ads_blend)
	# Rear loading: the gun node moves to where the launcher's rear opening is
	# shown (low, just right of centre); the launcher itself tips forward below.
	var load_tip=smoothstep(0.,1.,launcher_tilt) if rocket else 0.
	base=base.lerp(Vector3(.13,-.25,-.64),load_tip)
	if kind=="pistol" and not dual:rotation_target_extra=Vector3(0,0,.10) # roll only: the barrel stays on the aim line
	else:rotation_target_extra=Vector3.ZERO
	base+=Vector3(-.025,.095,-.025)*crouch_blend*(1.-ads_blend)
	var motion=move_blend*(1.-ads_blend*.93)*(1.-crouch_blend*.35)
	base.y+=sin(now*1.9)*.002*(1.-move_blend)*(1.-ads_blend)
	base+=Vector3(cos(bob)*.022,cos(bob*2)*.017,0)*motion
	# 1.4.5: in aim the kick pitches the gun much less (at .12 rad per unit the
	# top of the gun rose over the sight and hid the target) and instead drives
	# it back and a little down, so the sight line stays clear while firing.
	var rotation_target=Vector3(recoil*lerpf(.34,ADS_KICK_PITCH,ads_blend),-.09 if sprint else -turn_sway*.012,-.05*motion*sin(bob)+sin(shot_serial*2.3)*recoil*.025)+rotation_target_extra*(1.-ads_blend)
	base+=Vector3(0,-ADS_KICK_DROP,ADS_KICK_BACK)*recoil*ads_blend
	# 1.4.5: every gun keeps its barrel parallel to the aim line at the hip (the
	# 1.4.4 turned-in, dipped hip angle made the muzzle visibly point below and
	# left of the crosshair); only held gear still turns in a little.
	rotation_target.y+=(HIP_YAW_GEAR if gadget_up else 0.)*(1.-ads_blend)
	# Round 3 (the user): the rear of the gun goes out to the side and down,
	# the muzzle still on the crosshair: the barrel line crosses the aim line
	# HIP_CONVERGE ahead (any line through the aim line projects through the
	# screen centre), so the stock no longer runs straight back at the eye and
	# the firing hand sits naturally. Beam weapons stay parallel (their beam
	# leaves the muzzle for the far aim point).
	if not gadget_up and not throwable and not bool(w.get("laser",false)):
		var converge=hip_converge(hip_base,converge_distance(w))*(1.-ads_blend)
		rotation_target.y+=converge.x;rotation_target.x+=converge.y
	# 1.4.5 DUET: no sprint tilt; the two pistols swing like running arms instead
	# (one forward and up while the other goes back and down, 5 cm each way).
	pair_swing=lerpf(pair_swing,1. if sprint and dual else 0.,1.-exp(-dt*8.))
	if is_instance_valid(view_weapon) and view_weapon.dual_guns.size()>1 and (pair_swing>.001 or view_weapon.pair_swing_amount!=0.):view_weapon.set_pair_swing(sin(bob)*PAIR_SWING*pair_swing*(1.-ads_blend))
	# (nor for held gear: a cover plate or kit drawn while sprinting sat skewed)
	if sprint and not dual and not gadget_up:base+=Vector3(.075,-.055,.055);rotation_target+=Vector3(-.2,.3,.23)
	var reload_style=str(w.get("reload_style",""))
	# Round-by-round loads (shells, break-action, revolvers) hold one steady
	# loading pose across their cycles instead of bobbing with each round.
	load_hold=move_toward(load_hold,1. if reloading and reload_style in ["shell","break","revolver"] else 0.,dt*5.)
	if rocket:pass # launchers take their loading pose below (view weapon transform)
	elif reload_style=="dual":pass # the pistols leave the view in turn (GunModel.animate_pair)
	elif load_hold>0.:
		var hold=smoothstep(0.,1.,load_hold)
		if reload_style=="revolver":
			# Turned muzzle-left so the loading gate on its left side faces the eye.
			# 1.4.4: pulled in toward the eye while loading (the hands over-bent
			# and the support hand reached out too far at the hip distance).
			# Round 3: raised like the magazine reloads so the cylinder and both
			# hands are in the frame.
			base+=Vector3(-.07,.16,.16)*hold;rotation_target+=Vector3(.15,.70,.25)*hold # round 8: turned less, rolled more (the straighter forearm crossed the view when the gun was turned 49 deg)
		else:base+=Vector3(-.06,.14,.14)*hold;rotation_target+=Vector3(.12,-.2,-.28)*hold
		# Break action: brought to the lower centre, muzzle down, so the open
		# breech and the loading hand are in the middle of the view.
		if reload_style=="break":base+=Vector3(-.06,.03,0.)*hold;rotation_target.x-=.12*hold
	elif reloading:
		# Brought up and in so the support hand working the magazine stays in view.
		# 1.4.4: pulled in toward the eye (z +.22) so neither hand reaches far.
		# Round 3: raised further (y +.24) and a little toward the centre, so the
		# magazine well and the hand on it are in the frame (nearer the eye, the
		# same height sat below the bottom edge).
		# Round 8 pistols: lifted less far in (the straight-wristed forearm behind
		# a hand 30 cm from the eye filled the lower right of the view).
		if reload_style=="pistol":base+=Vector3(-.02,.20,.08)*sin(progress*PI);rotation_target+=Vector3(.10,-.05,-.20)*sin(progress*PI)
		else:base+=Vector3(-.05,.24,.22)*sin(progress*PI);rotation_target+=Vector3(.10,-.15,-.31)*sin(progress*PI)
		# 1.4.4 pistols: while the slide is racked the gun moves right, down and
		# turns its left side up, so the slide and the hand on it are both seen
		# instead of the hand covering the gun.
		if reload_style=="pistol":
			var rack=smoothstep(.78,.85,progress)*(1.-smoothstep(.96,1.,progress))
			base+=Vector3(.10,-.05,-.06)*rack;rotation_target+=Vector3(-.15,-.25,.55)*rack
	# Cooking (pin pulled): the grenade comes up and in a little, ready to go.
	# (1.4.5: in to the middle for the pin, then drawn back low - Actor.cook_pose)
	if cooking and throwable:
		var cook=cook_pose(now-float(p.get("grenade_started",now)));base+=cook[0];rotation_target+=cook[1]
	var throw_phase=-1.
	if not throwing:throw_start={}
	else:
		# 1.4.4 throw: from wherever the grenade was held the mount (grenade and
		# the hand on it) is drawn back and up beside the head, whipped forward
		# past the eye and followed through down and across (Actor.throw_path);
		# the grenade leaves the hand at THROW_RELEASE. The pose at the start of
		# the throw is remembered so the draw-back starts from the hold.
		throw_phase=1.-(float(p.throw_until)-now)/THROW_TIME
		if throw_start.is_empty() or float(throw_start.get("until",0.))!=float(p.throw_until):
			throw_start={"until":float(p.throw_until),"position":Vector3(gun.position.x*handedness,gun.position.y,gun.position.z),"rotation":Vector3(gun.rotation.x,gun.rotation.y*handedness,gun.rotation.z*handedness),"frame":gun.global_transform}
		var path=throw_path(throw_phase,[throw_start.position,throw_start.rotation])
		base=path[0];rotation_target=path[1]
	var swap=clampf((float(p.get("switch_until",0))-now)/.32,0,1);base.y-=swap*.32;rotation_target.z-=swap*.3
	base.x-=turn_sway*.004*(1.-ads_blend*.85)
	base.z+=recoil*(.105 if w.slot==1 else .155)*lerpf(1.,.38,ads_blend);base.y+=recoil*.025*(1.-ads_blend);base.y-=land_kick*.6
	base.x*=handedness;rotation_target.y*=handedness;rotation_target.z*=handedness
	if throwing:gun.position=base;gun.rotation=rotation_target # the throw path is its own motion (no smoothing lag)
	else:gun.position=gun.position.lerp(base,1.-exp(-dt*20));gun.rotation=gun.rotation.lerp(rotation_target,1.-exp(-dt*22))
	# The thrown item stays in the hand until the release point of the throw
	# (the world projectile is hidden from its thrower until then,
	# CombatFx.sync_grenades); third person hides it for the whole throw.
	for carried in [view_item,gadget_world]:
		if is_instance_valid(carried):
			var payload=cached_child(carried,"Payload")
			if payload:payload.visible=not throwing or (carried==view_item and throw_phase<THROW_RELEASE)
	item_model.visible=GadgetLoadout.held_visible(p,now) and (p.slot>=2 or cooking or throwing or p.get("placing","")!="") and not MeleeCombat.shown(p,now)
	if is_instance_valid(view_weapon):
		view_weapon.visible=p.slot<2 and (p.slot!=0 or p.get("owned_primary",true)) and not scoped and not semi_scoped and not cooking and not throwing and p.get("placing","")=="" and not MeleeCombat.shown(p,now)
		view_weapon.fire_side=int(p.mag.get(wid,0))%2;view_weapon.animate_reload(progress,recoil,age);view_weapon.set_rounds(int(p.mag.get(wid,0)),progress)
		# Hip: the right handle sits at the anchor (a pair is centred on it).
		# Aim: the rear sight sits a little below the camera axis, close enough
		# that only the gun from the sight forward is in view; a pair only
		# rises slightly toward the centre.
		var s=view_weapon.base.scale*view_weapon.scale.x
		var sight:Vector3=view_weapon.aim_point.position*s
		# DUET: the pair is held wide at the hip and drawn a little together when aiming.
		# 1.4.4: near the baked spacing (GunModel.PAIR_SPACING) so the left hand
		# keeps its grip field on the second pistol.
		# Round 3: held wider apart (40 cm) at the hip; GripField maps the left
		# hand's contact back to the baked spacing, so any width keeps its grip.
		var pair=lerpf(PAIR_HIP,PAIR_AIM,ads_blend)
		if dual:view_weapon.set_pair_spacing(pair/view_weapon.base.scale.x)
		var hip=hip_weapon_offset(view_weapon,pair)
		var aimed=hip if dual else Vector3(0,-.04 if kind=="rifle" else -.045,-(.27 if kind=="rifle" else .34))-sight
		if shoulder:
			# Shoulder launchers: the tube rests over the right shoulder, rear end just ahead of the eye.
			hip=Vector3(.06,-.02,.30);aimed=hip
		view_weapon.position=hip.lerp(aimed,ads_blend)
		view_weapon.basis=Basis.from_scale(view_weapon.scale)
		if load_tip>0.:
			# Rear loading pose: the tube points forward, down and to the right, its
			# open rear end at the gun node's origin facing the eye.
			var axis=Vector3(.46,-.36,-.81).normalized()
			var turn=Basis.looking_at(axis,Vector3.UP)
			var rear_local=Vector3(0,view_weapon.muzzle.position.y,float(view_weapon.base.get_meta("rear",0.)))*view_weapon.base.scale
			var loading=Transform3D(turn*Basis.from_scale(view_weapon.scale),-(turn*(rear_local*view_weapon.scale)))
			view_weapon.transform=view_weapon.transform.interpolate_with(loading,load_tip)
		var gauge=cached_child(view_weapon,"HeatGauge")
		if gauge:gauge.update_heat(float(p.get("laser_heat",0)),float(p.get("laser_lock",0))>now)
	update_view_body(dt,p,now,progress)
	BombHandling.view(self,p,now)
	var envelope=Aim.reticle_angle(w,p,spread_angle,aim_progress,bool(input_state.crouch))
	visual_spread=lerpf(visual_spread,envelope,1.-exp(-dt*(35. if envelope>visual_spread else 22.)))

# First-person arms: the hero (head hidden) stands where the camera is and
# reaches both hands onto the view weapon.
var view_head_offset=Vector3(0,1.62,0)
# First-person arms: a larger view body gives long arms whose shoulders stay
# below the bottom of the screen (the arm mesh's cut end never shows); the
# hands are scaled back at the wrists to their usual first-person size.
# 1.4.4: a view model, not the third-person body. As in shooters' first-person
# arm rigs the arms are longer than a person's (the rig's 0.39 m arm scaled
# 2x) so both hands reach a long gun, fixed shoulders sit well below the view
# (never seen), and each forearm rises into the frame from the lower corner on
# its own side (FP_FOREARM: wrist -> elbow direction); the elbows and upper
# arms stay below the frame. Hands keep their first-person size (VIEW_HAND).
const VIEW_BODY_SCALE=HeroCharacter.FP_BODY_SCALE
const VIEW_HAND=HeroCharacter.FP_HAND
const VIEW_DEPTH=1.4
const VIEW_BODY_OFFSET=Vector3(0,-.03,.10)
# Camera space, right-handed (x mirrors for a left-handed player).
const FP_SHOULDER={
	"rifle":{"R":Vector3(.45,-.52,.50),"L":Vector3(-.45,-.82,-.30)},
	# Round 4, pistols: the shoulder sits further back (and less far below) so
	# the arm extends toward the pistol with the forearm near the barrel line;
	# from the rifle anchor the forearm had to rise steeply to the grip and the
	# wrist bent past its limit.
	"pistol":{"R":Vector3(.45,-.45,.55),"L":Vector3(-.45,-.45,.55)},
	"item":{"R":Vector3(.42,-.62,.35),"L":Vector3(-.30,-.78,.06)}}
# 1.4.4 round 3: the support forearm leaves the handguard down and out to the
# left, so the arm opens away from the gun instead of lying along it (the
# support shoulder also sits further forward, so that arm is bent rather than
# straight along the shoulder-hand line); the hand itself stays on its grip.
# Round 7: the firing forearm runs straight back from the grip (the wrist
# nearly straight, as the user drew it), not up from the lower right.
const FP_FOREARM={"R":Vector3(.14,-.26,.95),"L":Vector3(-.85,-.30,.45)}
# Round 4, pistols (one in each hand for DUET): the forearm runs nearly along
# the barrel, as a pistol is held — the steeper rifle lines asked the wrist
# for a 75-100 degree bend, past its limit, so the hand turned off its grip
# (knuckles up at the trigger, the index and middle fingers in the guard).
const FP_FOREARM_PISTOL={"R":Vector3(.12,-.22,.97),"L":Vector3(-.12,-.22,.97)}
# Two-handed items (kits, plates) in front of the chest.
const FP_FOREARM_ITEM={"R":Vector3(.25,-.45,.86),"L":Vector3(-.35,-.50,.78)}
const FREE_ARM_OUT=Vector3(-1.,-.22,.12) # wrist -> elbow of the free arm with a throwable (camera space)
const FREE_SHOULDER_OUT=Vector3(-.08,.06,.26) # its (hidden) shoulder: a little out and well back (the upper arm stays out of view)
const FREE_ELBOW_W=14. # and the elbow pulled firmly to that line (HeroIK solve_arm)
const FREE_ARM_PIN=Vector3(-.40,-.88,.26) # pulling the pin: the forearm runs down out of the view
const FREE_SHOULDER_PIN=Vector3(-.04,-.10,.12)
# Raised fist (melee, throws): the forearm comes up nearly vertically.
const FP_FOREARM_STEEP={"R":Vector3(.30,-.88,.36),"L":Vector3(-.30,-.88,.36)}
# Melee: a shallow forearm from the lower right, fist ahead, blade up.
const FP_FOREARM_MELEE={"R":Vector3(.35,-.35,.87),"L":Vector3(-.35,-.35,.87)}
# Round 8: a gun hand's forearm continues the hand instead of running along a
# fixed line; the (hidden) shoulder is placed behind and below the elbow in
# this direction (elbow -> shoulder, camera space) so the elbow is reachable.
const FP_UPPER={"R":Vector3(.05,-.55,.83),"L":Vector3(-.05,-.55,.83)}
const FOLLOW_LOAD_BEND=.5 # share of the wrist bend allowed back while a gun is held sideways to load
# Round 9: the forearm is not the straight continuation of the hand but tilts
# FOLLOW_BEND below it (the elbow lower, as the user drew it), and keeps at
# least FOLLOW_DROP of slope below the horizon (a raked grip would otherwise
# send it up through the stock).
const FOLLOW_BEND=.45
const FOLLOW_DROP=.20
const FOLLOW_BEND_DUAL=.22
const FOLLOW_DROP_DUAL=.08
const FP_UPPER_DUAL_X=.35 # DUET: shoulders further out, the arms open to both sides
const STOCK_BEND=.25 # straight stocks (shotguns, FOLD): forearm bend below its line
const STOCK_DROP=0. # ...least slope down from the wrist to the elbow
const STOCK_ELBOW_OUT=.45 # ...and the elbow out to the side
const STOCK_HIP=Vector3(.14,-.40,-.56) # their hip anchor (before the side shift below)
const STOCK_CONVERGE=1.2 # ...crossing the aim line nearer: the gun lies across the view, its side seen
# Aimed recoil: pitch (rad per recoil unit), drop and push-back (m per unit).
const ADS_KICK_PITCH=.035
const ADS_KICK_DROP=.006
const ADS_KICK_BACK=.025
static func fp_forearms(hand:float,steep:bool=false,melee:bool=false,hold:String="rifle") -> Dictionary:
	var f:Dictionary=FP_FOREARM_MELEE if melee else FP_FOREARM_STEEP if steep else FP_FOREARM_PISTOL if hold=="pistol" else FP_FOREARM_ITEM if hold=="item" else FP_FOREARM
	return {"R":Vector3(f.R.x*hand,f.R.y,f.R.z),"L":Vector3(f.L.x*hand,f.L.y,f.L.z)}
# Throwables at rest (view space, right-handed): held at the lower right where
# the grenade and the hand under it are seen.
const THROW_HOLD=Vector3(.21,-.25,-.46)
const THROW_TIME=.28 # GrenadeLogic.release: throw_until = clock + .28
const THROW_RELEASE=.55 # phase at which the grenade leaves the hand
# Overhand throw (view space, right-handed) as other shooters animate it: from
# the hold the arm draws back and up so the hand is cocked beside the head
# (grenade behind the hand, fist pointing up), then whips forward past the
# eye, the grenade leaving at THROW_RELEASE, and follows through down and
# across the body before coming back to the hold. Keys are [phase, mount
# position, mount euler]; the first and last are the pose the throw started
# from, so there is no jump at either end.
# (Round 4: the hand turns down much less after the release; the wrist stayed
# bent far below the forearm through the follow-through.)
const THROW_KEYS=[[.0,Vector3.ZERO,Vector3.ZERO],[.26,Vector3(.34,.02,-.36),Vector3(1.05,-.30,-.40)],[.55,Vector3(.06,-.05,-.60),Vector3(-.20,.05,.05)],[.76,Vector3(-.02,-.30,-.50),Vector3(-.50,.20,.25)],[1.,Vector3.ZERO,Vector3.ZERO]]
static func throw_path(phase:float,start:Array=[THROW_HOLD,Vector3.ZERO]) -> Array:
	var keys=[]
	for k in THROW_KEYS:keys.append([float(k[0]),Vector3(start[0]) if Vector3(k[1])==Vector3.ZERO else Vector3(k[1]),Vector3(start[1]) if Vector3(k[2])==Vector3.ZERO else Vector3(k[2])])
	phase=clampf(phase,0.,1.)
	var i=0
	while i<keys.size()-2 and phase>=float(keys[i+1][0]):i+=1
	var a=keys[maxi(0,i-1)];var b=keys[i];var c=keys[i+1];var d=keys[mini(keys.size()-1,i+2)]
	var t=(phase-float(b[0]))/maxf(.0001,float(c[0])-float(b[0]))
	# A Catmull-Rom spline through the keys: one continuous sweep, no pauses.
	var tb=float(b[0]);var tc=float(c[0])-tb;var ta=float(a[0])-tb;var td=float(d[0])-tb # key times relative to b
	var pos:Vector3=Vector3(b[1]).cubic_interpolate_in_time(Vector3(c[1]),Vector3(a[1]),Vector3(d[1]),t,tc,ta,td)
	var rot:Vector3=Vector3(b[2]).cubic_interpolate_in_time(Vector3(c[2]),Vector3(a[2]),Vector3(d[2]),t,tc,ta,td)
	return [pos,rot]
# Wrist -> elbow direction of the throwing arm through the throw (camera
# space, right-handed): the forearm stands up under the cocked hand, lies back
# toward the body as the arm extends, and rises to the right (elbow up and
# out) in the follow-through across the body.
const THROW_FOREARM=[[.0,Vector3(.35,-.55,.75)],[.26,Vector3(.40,-.88,.25)],[.55,Vector3(.45,-.75,.48)],[.76,Vector3(.60,-.55,.58)],[1.,Vector3(.35,-.55,.75)]]
static func throw_forearm(phase:float) -> Vector3:
	phase=clampf(phase,0.,1.)
	for i in range(THROW_FOREARM.size()-1):
		if phase<=float(THROW_FOREARM[i+1][0]):
			var t=smoothstep(float(THROW_FOREARM[i][0]),float(THROW_FOREARM[i+1][0]),phase)
			return Vector3(THROW_FOREARM[i][1]).normalized().slerp(Vector3(THROW_FOREARM[i+1][1]).normalized(),t)
	return Vector3(THROW_FOREARM[-1][1]).normalized()
# 1.4.5 throw (the user's reference video): the pin comes out first - the two
# hands meet low in the middle and the free hand pulls the ring - then the free
# arm reaches out ahead, open, to aim while the throwing hand drops back and
# low; the release (THROW_KEYS) comes overhand from there while the free arm
# sweeps down out of view. Times in seconds of cooking; mount offsets from
# THROW_HOLD (view space, right-handed).
const PIN_REACH=.16
const PIN_PULL=.36
const COCK_TIME=.60
const PIN_OFFSET=Vector3(-.12,.08,-.02)
const PIN_ROT=Vector3(.15,.40,-.05)
const COCK_OFFSET=Vector3(.13,-.12,.17)
const COCK_ROT=Vector3(.45,-.20,-.35)
static func cook_pose(age:float) -> Array:
	var meet=smoothstep(0.,PIN_REACH,age)*(1.-smoothstep(PIN_PULL,COCK_TIME,age))
	var cock=smoothstep(PIN_PULL,COCK_TIME,age)
	return [PIN_OFFSET*meet+COCK_OFFSET*cock,PIN_ROT*meet+COCK_ROT*cock]
# Free (left) hand keys, view space right-handed: [wrist, finger direction,
# thumb direction, curl].
const FREE_IDLE=[Vector3(-.20,-.32,-.50),Vector3(.30,.10,-1.),Vector3(-.05,1.,.15),"flat"]
const FREE_AIM=[Vector3(-.15,-.13,-.60),Vector3(.12,1.,-.30),Vector3(1.,-.05,.1),"flat"]
const FREE_DOWN=[Vector3(-.30,-.58,-.36),Vector3(.15,-.35,-1.),Vector3(0.,1.,0.),"rest"]
const PIN_FINGERS=Vector3(.6,.45,-.65)
const PIN_THUMB=Vector3(0.,1.,.2)
const PIN_DRAW=Vector3(-.12,-.07,.03)
static func free_frame(fingers:Vector3,thumb:Vector3) -> Basis:
	# left hand: x is the thumb side, y the fingers, the palm faces -z
	var y=fingers.normalized();var x=(thumb-y*y.dot(thumb)).normalized()
	return Basis(x,y,x.cross(y))
static func free_key(k:Array) -> Transform3D:return Transform3D(free_frame(k[1],k[2]),k[0])
static func blend_key(a:Transform3D,b:Transform3D,t:float) -> Transform3D:
	return Transform3D(Basis(a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(),t)),a.origin.lerp(b.origin,t))
var held_ring:MeshInstance3D
func update_throw_hands(p:Dictionary,now:float,active:bool):
	if not active:
		view_body.free_hand={}
		if is_instance_valid(held_ring):held_ring.visible=false
		return
	var cooking=p.get("cooking",0)>0;var throwing=float(p.get("throw_until",-100.))>now
	var age=now-float(p.get("grenade_started",now)) if cooking else -1.
	var payload=cached_child(view_item,"Payload") if is_instance_valid(view_item) else null
	var ring:MeshInstance3D=payload.get_node_or_null("Grenade/PullRing") if payload else null
	var mirror=Basis.from_scale(Vector3(-1,1,1)) if handedness<0 else Basis.IDENTITY
	var to_world=func(local:Transform3D) -> Transform3D:
		var m=Transform3D(mirror*local.basis,Vector3(local.origin.x*handedness,local.origin.y,local.origin.z))
		var at=view_space.global_transform*m;return Transform3D(at.basis.orthonormalized(),at.origin)
	var idle=free_key(FREE_IDLE);var aim=free_key(FREE_AIM);var down=free_key(FREE_DOWN)
	var key:Transform3D=idle;var curl="flat";var in_hand=false
	if cooking and is_instance_valid(ring):
		# the pinch meets the ring where it is now (the grenade is moving in)
		var ring_local:Vector3=view_space.global_transform.affine_inverse()*(ring.global_transform*ring.get_aabb().get_center())
		ring_local.x*=handedness
		var pin_basis=free_frame(PIN_FINGERS,PIN_THUMB)
		var pin=Transform3D(pin_basis,ring_local-pin_basis.y*PINCH_REACH)
		if age<PIN_REACH:key=blend_key(idle,pin,smoothstep(0.,PIN_REACH,age));curl="flat" if age<PIN_REACH*.6 else "pinch"
		elif age<PIN_PULL:
			var pulled=pin.translated(PIN_DRAW*smoothstep(PIN_REACH,PIN_PULL,age))
			key=pulled;curl="pinch";in_hand=true
		else:
			key=blend_key(Transform3D(pin.basis,pin.origin+PIN_DRAW),aim,smoothstep(PIN_PULL,COCK_TIME,age));curl="pinch" if age<PIN_PULL+.08 else "flat";in_hand=age<PIN_PULL+.12
	elif throwing:
		var phase=1.-(float(p.throw_until)-now)/THROW_TIME
		key=blend_key(aim,down,smoothstep(.05,.55,phase)) if phase<.6 else blend_key(down,idle,smoothstep(.6,1.,phase))
		curl="flat" if phase<.3 else "rest"
	view_body.free_hand={"L":to_world.call(key),"curl_L":curl}
	if is_instance_valid(ring):ring.visible=not cooking and not throwing or (cooking and age<PIN_REACH)
	if in_hand:
		if not is_instance_valid(held_ring) and is_instance_valid(ring):
			held_ring=MeshInstance3D.new();held_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(held_ring)
	if is_instance_valid(held_ring):
		held_ring.visible=in_hand
		if is_instance_valid(ring) and in_hand:
			# (the thrown kind's own ring: the frag's and the smoke / flash one differ)
			if held_ring.mesh!=ring.mesh:held_ring.mesh=ring.mesh;held_ring.material_override=ring.get_surface_override_material(0)
			held_ring.set_meta("size",absf(ring.global_basis.get_scale().x));held_ring.set_meta("centre",ring.get_aabb().get_center())
# View-space length from the free hand's wrist to its pinch (thumb and index tips).
const PINCH_REACH=.085
# The pulled ring hangs from the free hand's pinch (after the hand is solved).
func place_held_ring():
	if not is_instance_valid(held_ring) or not held_ring.visible:return
	var thumb:Array=HeroIK.finger_chains(view_body,"L").Thumb;var index:Array=HeroIK.finger_chains(view_body,"L").Index
	var a=view_body.bone_world(thumb[thumb.size()-1]).origin;var b=view_body.bone_world(index[index.size()-1]).origin
	var wrist=view_body.bone_world(view_body.bone["Wrist.L"])
	var basis=Basis(wrist.basis.get_rotation_quaternion()).scaled(Vector3.ONE*float(held_ring.get_meta("size",1.)))
	held_ring.global_transform=Transform3D(basis,(a+b)*.5-basis*Vector3(held_ring.get_meta("centre",Vector3.ZERO)))
static func fp_shoulders(hold:String,hand:float) -> Dictionary:
	var set:Dictionary=FP_SHOULDER.get(hold,FP_SHOULDER.pistol)
	return {"R":Vector3(set.R.x*hand,set.R.y,set.R.z),"L":Vector3(set.L.x*hand,set.L.y,set.L.z)}
# Short guns (pistols, shotguns, the break-action FOLD) sit higher than the
# rifles: their tops were down at the bottom edge (round 3).
static func short_gun_kind(w:Dictionary) -> bool:
	return GunLooks.hold_kind(w)=="pistol" or str(GunLooks.look(w).get("base","")) in ["Shotgun","ShortCannon"]
# Hip anchor of the view weapon's right handle (view space, right-handed).
# 1.4.4: at the hip every weapon stays in the bottom third of the screen (the
# user's rule); aiming brings it up to the sight line. Shared with the kill
# replay (1.4.5), whose first-person view is built the same way as live play.
const GADGET_OUT=Vector3(.0,.015,-.05)
static func hip_base_for(w:Dictionary,gadget_up:bool=false) -> Vector3:
	var kind=GunLooks.hold_kind(w);var dual=bool(w.get("dual",false))
	var rocket=bool(w.get("rocket",false));var shoulder=bool(GunLooks.look(w).get("shoulder",false))
	var hip_base=Vector3(.235,-.44,-.56)
	if dual:hip_base=Vector3(0,-.36,-.50)
	elif kind=="pistol":hip_base=Vector3(.15,-.33,-.50)
	# Hand-held launchers (QUAD) sit lower and further right: the tube cluster
	# is wide and would cover the middle of the screen.
	elif rocket and not shoulder:hip_base=Vector3(.34,-.42,-.46)
	# 1.4.5 straight stocks (shotguns, FOLD), as other shooters hold them: the
	# rear of the gun near the bottom centre, the gun rising across to the
	# crosshair, the firing arm reaching in from the side.
	elif GunModel.straight_look(GunLooks.look(w)):hip_base=STOCK_HIP
	elif short_gun_kind(w):hip_base.y=-.37
	# Guns (not gadgets, not the centred pair) sit further to the shooting side
	# (the user's 1.4.4 round-3 request) so the middle of the screen is clear.
	if not gadget_up and not dual:hip_base.x+=.06
	# 1.4.6 (the user): held gadgets a little further out from the body
	if gadget_up:hip_base+=GADGET_OUT
	return hip_base
# Hip turn (yaw in toward the centre, pitch up) that makes the barrel line
# cross the aim line HIP_CONVERGE ahead (view-space units; the bore runs about
# HIP_BORE above the right handle).
const HIP_CONVERGE=4.
const HIP_BORE=.08
static func converge_distance(w:Dictionary) -> float:
	return STOCK_CONVERGE if GunModel.straight_look(GunLooks.look(w)) else HIP_CONVERGE
static func hip_converge(hip:Vector3,distance:float=HIP_CONVERGE) -> Vector2:
	return Vector2(atan2(hip.x,distance),atan2(-(hip.y+HIP_BORE),distance))
# View-weapon scale: long guns are compact in the view, pistols keep their
# size next to the big cartoon hand.
static func view_weapon_scale(w:Dictionary) -> float:return 1.18 if GunLooks.hold_kind(w)=="pistol" else .9
# The weapon's offset inside its mount so the right handle (a pair: its
# centre) sits at the mount origin at the hip.
static func hip_weapon_offset(model:GunModel,pair:float) -> Vector3:
	var s=model.base.scale*model.scale.x
	var grip:Vector3=model.right_grip.position*s
	return -grip+(Vector3(pair*.5*model.scale.x,0,0) if model.dual_guns.size()>1 else Vector3.ZERO)
# The arm-follow settings of a gun hold (meta "fp_follow", HeroIK.solve_arm):
# the firing forearm continues the hand with the hidden shoulder following.
static func fp_follow_for(hold:String,paired:bool,hand:float,weight:float=1.,model:GunModel=null) -> Dictionary:
	var follow={}
	if hold=="item":return follow
	# DUET: the arms open out to both sides with the wrists bent less.
	var bend=FOLLOW_BEND_DUAL if paired else FOLLOW_BEND;var drop=FOLLOW_DROP_DUAL if paired else FOLLOW_DROP;var out=FP_UPPER_DUAL_X if paired else 0.
	follow.R={"upper":Vector3((FP_UPPER.R.x+out)*hand,FP_UPPER.R.y,FP_UPPER.R.z),"weight":weight,"bend":bend,"drop":drop}
	# 1.4.5: a straight stock (shotguns, FOLD) is held round its wrist; the
	# forearm runs back along the stock instead of continuing the hand.
	# (the hand closes round the wrist knuckles-down, so the forearm comes in
	# level from the side - elbow out, as a shotgun is held - not from below:
	# no least slope, little extra bend)
	if is_instance_valid(model) and model.straight_wrist():
		follow.R.line=-model.right_grip.global_basis.y.normalized();follow.R.bend=STOCK_BEND;follow.R.drop=STOCK_DROP
		follow.R.upper=Vector3((FP_UPPER.R.x+STOCK_ELBOW_OUT)*hand,FP_UPPER.R.y,FP_UPPER.R.z)
	if paired:follow.L={"upper":Vector3((FP_UPPER.L.x-out)*hand,FP_UPPER.L.y,FP_UPPER.L.z),"weight":weight,"bend":bend,"drop":drop}
	return follow
func update_view_body(dt:float,p:Dictionary,now:float,progress:float):
	if not is_instance_valid(view_body):return
	var item_up=is_instance_valid(view_item) and item_model.visible
	if is_instance_valid(view_item):view_item.visible=item_up
	var bomb_up=is_instance_valid(bomb_view) and bomb_view.visible
	var melee_up=is_instance_valid(melee_view) and melee_view.visible and not bomb_up
	var weapon_up=is_instance_valid(view_weapon) and view_weapon.visible
	view_body.visible=weapon_up or item_up or melee_up or bomb_up
	if not view_body.visible:return
	var throwing=float(p.get("throw_until",-100.))>now
	var carried:Node3D=bomb_view if bomb_up else null if melee_up or (item_up and throwing) else view_item if item_up else view_weapon
	# 1.4.4 melee: the tool rides the hand; the arm is swung to a wrist point.
	if melee_up:
		var wrist:Vector3=MeleeVisual.swing_wrist(now-float(p.get("melee_started",-100.)))
		# The fist continues the forearm, which comes in from the lower right at
		# a shallow angle (FP_FOREARM_MELEE); the blade leaves the fist on the
		# thumb side, pointing UP and a little forward (a hammer grip with the
		# blade up, as in most shooters' knife poses).
		var dir:Vector3=-Vector3(FP_FOREARM_MELEE.R).normalized()
		# Left-handed: the frame is mirrored like a gun's handles (a reflected basis).
		# 1.4.5: the wrench is carried with its head tilted further forward.
		var thumb:Vector3=(Vector3(0,.70,-.71) if melee_view.tool else Vector3(0,.9,-.44)).normalized()
		var x:Vector3=-(thumb-dir*dir.dot(thumb)).normalized()
		var basis=Basis(x,dir,x.cross(dir).normalized())
		if handedness<0:basis=Basis.from_scale(Vector3(-1,1,1))*basis;wrist.x=-wrist.x
		var at:Transform3D=view_space.global_transform*Transform3D(basis,wrist)
		var age=now-float(p.get("melee_started",-100.))
		var swinging=age>=0. and age<MeleeCombat.DURATION
		view_body.wrist_override={"R":Transform3D(at.basis.orthonormalized(),at.origin),"capture_R":not swinging,"rigid_R":swinging,"tool_R":melee_view.handle_shape()}
		if is_instance_valid(view_body.held):view_body.hold(null)
	elif item_up and throwing:
		# 1.4.4 throw: the hand keeps its hold on the grenade (its wrist frame in
		# mount space, taken as the throw begins) and rides the mount along the
		# throw path (Actor.throw_path), so grenade, hand and forearm swing as
		# one; after the release the fingers open, closing again at the end.
		var phase=1.-(float(p.throw_until)-now)/THROW_TIME
		# (the hand is still in last frame's hold when the throw begins: its frame
		# is taken relative to the mount's pose at that moment, not the path's)
		if not throw_start.has("wrist"):throw_start.wrist=Transform3D(throw_start.frame).affine_inverse()*view_body.bone_world(view_body.bone["Wrist.R"])
		var at:Transform3D=gun.global_transform*Transform3D(throw_start.wrist)
		var open=smoothstep(THROW_RELEASE,THROW_RELEASE+.12,phase)*(1.-smoothstep(.86,1.,phase))
		# Round 5: the wrist stays as it was at the hold (rigid to the forearm, as
		# in the melee swing) so the hand turns with the arm instead of bending
		# at the wrist through the swing; the grenade is re-seated on the hand
		# after the arm is solved (below), so it never parts from the palm.
		var first=not throw_start.has("rigid")
		view_body.wrist_override={"R":Transform3D(at.basis.orthonormalized(),at.origin),"curl_R":"hold","open_R":open,"capture_R":first,"rigid_R":not first}
		throw_start.rigid=true
	else:view_body.wrist_override={}
	if carried!=null and view_body.held!=carried:
		if carried==bomb_view:view_body.hold(carried,false)
		else:
			# The view body's weapon frame follows the view mount (gun space), so
			# the item keeps its gun-space transform; the frame itself may still
			# be stale on a freshly built body.
			var local=gun.global_transform.affine_inverse()*carried.global_transform
			view_body.hold(carried);carried.transform=local
	var yaw=Basis(Vector3.UP,aim_yaw)
	# View-model convention: a slightly larger body and a compact gun keep both
	# hands on long rifles with the short cartoon arms.
	view_body.global_basis=yaw*Basis.from_scale(Vector3(float(handedness),1.,1.)*VIEW_BODY_SCALE*VIEW_DEPTH)
	# Only forearms and hands are drawn, so the (invisible) shoulders may sit ahead
	# of the eye: short cartoon arms then reach both grips of long rifles.
	view_body.global_position=camera.global_position-yaw*view_head_offset+yaw*VIEW_BODY_OFFSET
	var state=pose_state(p,now,progress,false);state.velocity=Vector3.ZERO;state.hold=GunLooks.hold_kind(game.current_weapon(p))
	if state.hold=="shoulder":state.hold="rifle"
	if item_up:state.hold="item";state.two_hands=bool(view_item.get_meta("two_handed",false))
	# 1.4.4: first-person pistols are held in one hand (third person keeps
	# both); DUET has a pistol in each hand.
	elif state.hold=="pistol":state.two_hands=bool(game.current_weapon(p).get("dual",false))
	if melee_up:state.hold="item";state.two_hands=false;state.erase("melee")
	if bomb_up:state.hold="item";state.two_hands=true;state.point=true;state.erase("plant")
	state.hands=1.;state.sprint=false
	view_body.set_meta("fp_shoulders",fp_shoulders(str(state.hold),float(handedness)))
	# Melee: the arm comes in low from the side; throws: the forearm follows the swing.
	var lines:Dictionary=fp_forearms(float(handedness),false,melee_up,str(state.hold))
	if throwing:
		var line:Vector3=throw_forearm(1.-(float(p.throw_until)-now)/THROW_TIME)
		lines.R=Vector3(line.x*handedness,line.y,line.z)
	# 1.4.6 (the user): holding a throwable, the free arm is spread further out
	# to the side - the hand stays where it is, the elbow goes out.
	if item_up and not melee_up and not bomb_up and GrenadeLogic.equipped(p):
		# (while the pin is pulled the elbow drops instead: the upper arm stays
		# below the view, never half in it)
		var pin=p.get("cooking",0)>0
		var line:Vector3=FREE_ARM_PIN if pin else FREE_ARM_OUT;var out:Vector3=FREE_SHOULDER_PIN if pin else FREE_SHOULDER_OUT
		lines.L=Vector3(line.x*handedness,line.y,line.z)
		var shoulders:Dictionary=Dictionary(view_body.get_meta("fp_shoulders",{})).duplicate()
		if shoulders.has("L"):shoulders.L=Vector3(shoulders.L)+Vector3(out.x*handedness,out.y,out.z);view_body.set_meta("fp_shoulders",shoulders)
	view_body.set_meta("fp_elbow_w",{"L":FREE_ELBOW_W} if item_up and not melee_up and not bomb_up and GrenadeLogic.equipped(p) else {})
	view_body.set_meta("fp_forearm",lines)
	# Round 8: a gun hand's forearm continues the hand (wrist straight); the
	# hidden shoulder follows (HeroIK solve_arm, meta "fp_follow").
	var follow={}
	if weapon_up and not throwing and not melee_up and not bomb_up and not item_up:
		# A gun turned sideways to load (revolver gate, shells, break action) keeps a
		# bent wrist: fully straight, the forearm would cross the view from the side.
		var w=1.-FOLLOW_LOAD_BEND*smoothstep(0.,1.,load_hold)
		follow=fp_follow_for(str(state.hold),state.hold=="pistol" and state.two_hands,float(handedness),w,view_weapon)
	view_body.set_meta("fp_follow",follow)
	update_throw_hands(p,now,item_up and not melee_up and not bomb_up and GrenadeLogic.equipped(p) and (p.get("cooking",0)>0 or throwing or p.slot==2))
	var _pt=Prof.now();view_body.drive(dt,state);Prof.add("actor_fp_drive",_pt)
	place_held_ring()
	if throwing and item_up and throw_start.has("wrist"):
		# The grenade follows the solved hand: the mount (and the weapon frame the
		# item hangs from) is placed from the wrist by the frame taken at the hold.
		var hand:Transform3D=view_body.bone_world(view_body.bone["Wrist.R"])
		gun.global_transform=hand*Transform3D(throw_start.wrist).affine_inverse()
		if is_instance_valid(view_mount):view_body.weapon_frame.global_transform=view_mount.global_transform
	view_head_offset=yaw.inverse()*(view_body.head_position()-view_body.global_position)
func show_shot(at:float) -> bool:
	if at<=seen_shot:return false
	seen_shot=at;shot_serial+=1;recoil=minf(1.8,recoil*.35+float(game.current_weapon(game.players[pid]).get("recoil_kick",1.)))
	if GadgetLoadout.mounted(game.players[pid],bool(input_state.crouch)):recoil*=.4
	if not game.current_weapon(game.players[pid]).get("rocket",false) and local and is_instance_valid(view_weapon) and is_instance_valid(game.combat_fx) and game.players.has(pid) and game.players[pid].slot<2:
		var source=gun.to_global(Vector3(.09,.01,-.16))
		game.combat_fx.eject_case(source,camera.global_basis.x,camera.global_basis.y,global_position.y,shot_serial+pid)
	return true
