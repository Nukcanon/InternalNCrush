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
var item_model:Node3D
var gadget_world:GadgetVisual
var bomb_view:Node3D
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
	gun=Node3D.new();camera.add_child(gun)
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
		view_weapon=GunModel.new();view_weapon.build(w,false);view_mount.add_child(view_weapon);view_weapon.scale=Vector3.ONE*(1. if GunLooks.hold_kind(w)=="pistol" else .9)
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
	view_body=HeroCharacter.new();view_body.name="ViewBody";camera.add_child(view_body);view_body.build(maxi(0,shown_role),maxi(0,shown_team),false)
	view_body.first_person_only();view_body.frame_override=view_mount;view_body.hand_size=VIEW_HAND/VIEW_BODY_SCALE
	view_body.set_meta("fp_camera",camera)
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
			var amount=maxf(0.,(fall_peak-global_position.y-9.)*(40./3.6))
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
			melee_view=MeleeVisual.new();gun.add_child(melee_view);melee_view.build(MeleeCombat.wrench(p),melee_role,true)
	if is_instance_valid(melee_world):melee_world.visible=shown;melee_world.pose(-1.)
	if is_instance_valid(melee_view):melee_view.visible=shown;melee_view.pose(now-float(p.get("melee_started",-100.)))
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
		if signature!=item_signature:
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
	var hip_base=Vector3(.19,-.265,-.46)
	if dual:hip_base=Vector3(0,-.235,-.46)
	elif kind=="pistol":hip_base=Vector3(.15,-.235,-.44)
	# Hand-held launchers (QUAD) sit lower and further right: the tube cluster
	# is wide and would cover the middle of the screen.
	elif rocket and not shoulder:hip_base=Vector3(.34,-.36,-.42)
	var ads_base=(Vector3(.25,-.21,-.50) if shoulder else Vector3(.29,-.27,-.50)) if rocket else hip_base+Vector3(0,.07,-.03) if dual else Vector3.ZERO
	var base=hip_base.lerp(ads_base,ads_blend)
	# Rear loading: the gun node moves to where the launcher's rear opening is
	# shown (low, just right of centre); the launcher itself tips forward below.
	var load_tip=smoothstep(0.,1.,launcher_tilt) if rocket else 0.
	base=base.lerp(Vector3(.10,-.20,-.50),load_tip)
	if kind=="pistol" and not dual:rotation_target_extra=Vector3(0,-.03,.10)
	else:rotation_target_extra=Vector3.ZERO
	base+=Vector3(-.025,.095,-.025)*crouch_blend*(1.-ads_blend)
	var motion=move_blend*(1.-ads_blend*.93)*(1.-crouch_blend*.35)
	base.y+=sin(now*1.9)*.002*(1.-move_blend)*(1.-ads_blend)
	base+=Vector3(cos(bob)*.022,cos(bob*2)*.017,0)*motion
	var rotation_target=Vector3(recoil*lerpf(.34,.12,ads_blend),-.09 if sprint else -turn_sway*.012,-.05*motion*sin(bob)+sin(shot_serial*2.3)*recoil*.025)+rotation_target_extra*(1.-ads_blend)
	if sprint:base+=Vector3(.075,-.055,.055);rotation_target+=Vector3(-.2,.3,.23)
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
			base+=Vector3(-.07,.05,.04)*hold;rotation_target+=Vector3(.18,.85,.1)*hold
		else:base+=Vector3(.02,.06,.10)*hold;rotation_target+=Vector3(.12,-.2,-.28)*hold
		if reload_style=="break":rotation_target.x-=.32*hold # muzzle down, breech up toward the eye
	elif reloading:
		# Brought up and in so the support hand working the magazine stays in view.
		base+=Vector3(.02,.07,.14)*sin(progress*PI);rotation_target+=Vector3(.10,-.15,-.31)*sin(progress*PI)
	if p.get("cooking",0)>0:base+=Vector3(-.08,.07,.05);rotation_target+=Vector3(.25,.15,-.22)
	if float(p.get("throw_until",-100.))>now:
		var throw_phase=1.-(float(p.throw_until)-now)/.28
		base.z-=sin(throw_phase*PI)*.48;rotation_target.x-=sin(throw_phase*PI)*.9
		item_model.visible=false
	var swap=clampf((float(p.get("switch_until",0))-now)/.32,0,1);base.y-=swap*.32;rotation_target.z-=swap*.3
	base.x-=turn_sway*.004*(1.-ads_blend*.85)
	base.z+=recoil*(.105 if w.slot==1 else .155)*lerpf(1.,.38,ads_blend);base.y+=recoil*.025*(1.-ads_blend);base.y-=land_kick*.6
	base.x*=handedness;rotation_target.y*=handedness;rotation_target.z*=handedness
	gun.position=gun.position.lerp(base,1.-exp(-dt*20));gun.rotation=gun.rotation.lerp(rotation_target,1.-exp(-dt*22))
	var cooking=p.get("cooking",0)>0
	var throwing=p.get("throw_until",0)>now
	for carried in [view_item,gadget_world]:
		if is_instance_valid(carried):
			var payload=cached_child(carried,"Payload")
			if payload:payload.visible=not throwing
	item_model.visible=GadgetLoadout.held_visible(p,now) and (p.slot>=2 or cooking or throwing or p.get("placing","")!="") and not MeleeCombat.shown(p,now)
	if is_instance_valid(view_weapon):
		view_weapon.visible=p.slot<2 and (p.slot!=0 or p.get("owned_primary",true)) and not scoped and not semi_scoped and not cooking and not throwing and p.get("placing","")=="" and not MeleeCombat.shown(p,now)
		view_weapon.fire_side=int(p.mag.get(wid,0))%2;view_weapon.animate_reload(progress,recoil,age);view_weapon.set_rounds(int(p.mag.get(wid,0)),progress)
		# Hip: the right handle sits at the anchor (a pair is centred on it).
		# Aim: the rear sight sits a little below the camera axis, close enough
		# that only the gun from the sight forward is in view; a pair only
		# rises slightly toward the centre.
		var s=view_weapon.base.scale*view_weapon.scale.x
		var grip:Vector3=view_weapon.right_grip.position*s
		var sight:Vector3=view_weapon.aim_point.position*s
		# DUET: the pair is held wide at the hip and drawn a little together when aiming.
		var pair=lerpf(.40,.32,ads_blend)
		if dual:view_weapon.set_pair_spacing(pair/view_weapon.base.scale.x)
		var hip=-grip+(Vector3(pair*.5*view_weapon.scale.x,0,0) if dual else Vector3.ZERO)
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
# 1.4.2: the shoulders slide to meet each view-model forearm (HeroIK.fp_forearm),
# so long arms are no longer needed for reach; a modest scale keeps the
# forearms from filling the lower screen.
const VIEW_BODY_SCALE=1.3
const VIEW_HAND=1.15
const VIEW_BODY_OFFSET=Vector3(0,-.03,.10)
func update_view_body(dt:float,p:Dictionary,now:float,progress:float):
	if not is_instance_valid(view_body):return
	var item_up=is_instance_valid(view_item) and item_model.visible
	if is_instance_valid(view_item):view_item.visible=item_up
	var bomb_up=is_instance_valid(bomb_view) and bomb_view.visible
	var melee_up=is_instance_valid(melee_view) and melee_view.visible and not bomb_up
	var weapon_up=is_instance_valid(view_weapon) and view_weapon.visible
	view_body.visible=weapon_up or item_up or melee_up or bomb_up
	if not view_body.visible:return
	var carried:Node3D=bomb_view if bomb_up else melee_view if melee_up else view_item if item_up else view_weapon
	if view_body.held!=carried:
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
	view_body.global_basis=yaw*Basis.from_scale(Vector3(float(handedness),1.,1.)*VIEW_BODY_SCALE)
	# Only forearms and hands are drawn, so the (invisible) shoulders may sit ahead
	# of the eye: short cartoon arms then reach both grips of long rifles.
	view_body.global_position=camera.global_position-yaw*view_head_offset+yaw*VIEW_BODY_OFFSET
	var state=pose_state(p,now,progress,false);state.velocity=Vector3.ZERO;state.hold=GunLooks.hold_kind(game.current_weapon(p))
	if state.hold=="shoulder":state.hold="rifle"
	if item_up:state.hold="item";state.two_hands=bool(view_item.get_meta("two_handed",false))
	elif state.hold=="pistol":state.two_hands=true
	if melee_up:state.hold="item";state.two_hands=false;state.erase("melee")
	if bomb_up:state.hold="item";state.two_hands=true;state.point=true;state.erase("plant")
	state.hands=1.;state.sprint=false
	var _pt=Prof.now();view_body.drive(dt,state);Prof.add("actor_fp_drive",_pt)
	view_head_offset=yaw.inverse()*(view_body.head_position()-view_body.global_position)
func show_shot(at:float) -> bool:
	if at<=seen_shot:return false
	seen_shot=at;shot_serial+=1;recoil=minf(1.8,recoil*.35+float(game.current_weapon(game.players[pid]).get("recoil_kick",1.)))
	if GadgetLoadout.mounted(game.players[pid],bool(input_state.crouch)):recoil*=.4
	if not game.current_weapon(game.players[pid]).get("rocket",false) and local and is_instance_valid(view_weapon) and is_instance_valid(game.combat_fx) and game.players.has(pid) and game.players[pid].slot<2:
		var source=gun.to_global(Vector3(.09,.01,-.16))
		game.combat_fx.eject_case(source,camera.global_basis.x,camera.global_basis.y,global_position.y,shot_serial+pid)
	return true
