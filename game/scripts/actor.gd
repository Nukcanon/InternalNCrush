extends CharacterBody3D
class_name Actor
const Character=preload("res://scripts/character_visual.gd")
const Aim=preload("res://scripts/aim_model.gd")
const Weapon=preload("res://scripts/weapon_visual.gd")
var pid=0
var game:Node
var camera:Camera3D
var body_mesh:Node3D
var head_mesh:Node3D
var limbs:Node3D
var tag:Label3D
var shape:CollisionShape3D
var gun:Node3D
var item_model:Node3D
var view_weapon:WeaponVisual
var world_weapon:WeaponVisual
var render_root:Node3D
var character:CharacterVisual
var protected_visual:MeshInstance3D
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
var input_state={"x":0.0,"z":0.0,"yaw":0.0,"pitch":0.0,"ads":false,"sprint":false,"crouch":false,"fire":false,"alt":false,"use":false,"jump":false,"trigger_seq":0}
var aim_yaw=0.0
var aim_pitch=0.0
var sprint_release=0.0
var last_sprint=false
var target_pos=Vector3.ZERO
var local=false
var bob=0.0
var step_clock=0.0
var grounded_jump=false
var shown_weapon=""
var recoil=0.0
var hit_recoil=0.0
var hit_side=0.0
var old_visual_pos=Vector3.ZERO
var gait=0.
var net_gait=0.
var motion_seed=0.
var previous_yaw=0.
var turn_sway=0.
var shot_serial=0
func _ready():
	motion_seed=fposmod(float(pid)*2.39996,TAU)
	collision_layer=2;collision_mask=1|4|8
	shape=CollisionShape3D.new();var cap=CapsuleShape3D.new();cap.radius=.25;cap.height=1.8;shape.shape=cap;shape.position.y=.9;add_child(shape)
	render_root=Node3D.new();add_child(render_root)
	tag=Label3D.new();tag.font=game.ui.theme.default_font;tag.position.y=2.;tag.font_size=32;tag.outline_size=8;tag.outline_modulate=Color("101f2d");tag.pixel_size=.004;tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(tag)
	camera=Camera3D.new();camera.position.y=1.62;camera.fov=82;camera.far=300;camera.near=.08;add_child(camera)
	gun=Node3D.new();camera.add_child(gun)
	item_model=Node3D.new();gun.add_child(item_model)
	protected_visual=MeshInstance3D.new();var shield=CapsuleMesh.new();shield.radius=.54;shield.height=2.05;protected_visual.mesh=shield;protected_visual.position.y=1.;render_root.add_child(protected_visual)
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.3,.8,1,.25);mat.cull_mode=BaseMaterial3D.CULL_DISABLED;protected_visual.material_override=mat;protected_visual.visible=false;protected_visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func build_gun(wid:String):
	if is_instance_valid(view_weapon):view_weapon.queue_free()
	if is_instance_valid(world_weapon):world_weapon.queue_free()
	var w=Catalog.get_weapon(wid)
	view_weapon=Weapon.new();gun.add_child(view_weapon);view_weapon.build(w);view_weapon.scale=Vector3.ONE*.85
	world_weapon=Weapon.new();(character.socket if is_instance_valid(character) else render_root).add_child(world_weapon);world_weapon.build(w,false);world_weapon.scale=Vector3.ONE*.85
func set_local(on:bool):
	local=on;camera.current=on;render_root.visible=not on;tag.visible=not on;gun.visible=on
func set_team(t:int):
	if not game.players.has(pid):return
	var role=int(game.players[pid].role) if game.options.classes else 0
	if role==shown_role and t==shown_team:return
	shown_role=role;shown_team=t
	body_height=HumanModel.HEIGHTS[role];tag.position.y=body_height+.18
	shape.shape.height=body_height;shape.position.y=body_height*.5
	protected_visual.scale.y=body_height/1.8
	if is_instance_valid(character):character.queue_free()
	character=null
	if game.render_actors:ensure_character()
	shown_weapon=""
func ensure_character():
	if is_instance_valid(character):
		if not character.get_meta("pose_only",false):return
		character.queue_free();character=null;shown_weapon=""
	character=Character.new();render_root.add_child(character);character.build(shown_role,shown_team);character.motion_seed=motion_seed
func ensure_hit_pose():
	if is_instance_valid(character):return
	character=Character.new();render_root.add_child(character);character.build_pose_only(maxi(0,shown_role),maxi(0,shown_team));character.set_meta("pose_only",true);character.motion_seed=motion_seed
	character.update_pose(1./60.,velocity,last_sprint,bool(input_state.crouch),is_on_floor(),aim_pitch,-1.,0.,gait)

func reset_view(yaw:float):
	camera.top_level=false;camera.transform=Transform3D(Basis.IDENTITY,Vector3(0,eye_height(false),0))
	input_state.yaw=yaw;input_state.pitch=0.;input_state.crouch=false;input_state.sprint=false;input_state.fire=false;input_state.ads=false;input_state.x=0.;input_state.z=0.;input_state.jump=false
	aim_yaw=yaw;aim_pitch=0.;rotation=Vector3(0,yaw,0);last_sprint=false;sprint_release=0.;old_visual_pos=global_position;spread_angle=.4;visual_spread=.4;seen_shot=-100.;recoil=0.;land_kick=0.
	gait=0.;net_gait=0.;turn_sway=0.;previous_yaw=yaw;aim_progress=0.;ads_blend=0.
	handedness=int(game.players.get(pid,{}).get("hand",1))
	if local:
		camera.current=true
		if is_instance_valid(game.ui.damage_indicator):game.ui.damage_indicator.clear_hits()
func eye_height(crouched:bool) -> float:return (1.30 if crouched else 1.62)*body_height/1.8
func head_threshold() -> float:return (1.14 if input_state.crouch else 1.46)*body_height/1.8
func eye() -> Vector3:return global_position+Vector3.UP*eye_height(bool(input_state.crouch))
func direction() -> Vector3:return Basis(Vector3.UP,aim_yaw)*Basis(Vector3.RIGHT,aim_pitch)*Vector3.FORWARD
func desired_muzzle() -> Vector3:return eye()+Basis(Vector3.UP,aim_yaw)*Vector3(.2*handedness,-.23,0)+direction()*.55
func muzzle_world() -> Vector3:
	var desired=desired_muzzle()
	var hit=game.ray(eye(),desired,[get_rid()],1|4|8)
	return hit.position+hit.normal*.03 if not hit.is_empty() else desired
func visual_muzzle() -> Vector3:
	if local and is_instance_valid(view_weapon) and view_weapon.visible:return view_weapon.muzzle.global_position
	if not local and is_instance_valid(world_weapon) and world_weapon.visible:return world_weapon.muzzle.global_position
	return muzzle_world()
func react_hit(push:Vector3):
	hit_recoil=1.;hit_side=clampf(global_basis.x.dot(push),-1,1)
	if is_instance_valid(character):character.react(hit_side)
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
	var sprint=not cooking and bool(input_state.sprint) and not crouch and not input_state.ads and not input_state.fire
	if last_sprint and not sprint:sprint_release=now+.5
	last_sprint=sprint
	var speed=Rules.RUN_SPEED if sprint else Rules.CROUCH_SPEED if crouch else Rules.WALK_SPEED
	if game.arena and game.arena.wading(global_position):speed*=.72
	if game.players.has(pid):
		var p=game.players[pid]
		var weapon=game.current_weapon(p)
		if input_state.ads and p.slot<2:speed=minf(speed,float(weapon.get("ads_speed",4.4))*.5)
		elif p.slot<2:speed*=float(weapon.get("move_speed_scale",1.))
		if p.get("slow",0)>now:speed*=.6
		if p.get("shield",0)>now:speed*=.6
		if p.get("dash",0)>now:speed*=2
		if Catalog.get_weapon(p.primary).role==2:speed*=.9
	var wish=Vector3(float(input_state.x),0,float(input_state.z)).limit_length(1)
	wish=Basis(Vector3.UP,aim_yaw)*wish
	var target_velocity=wish*speed if can_move else Vector3.ZERO
	if sliding and can_move:
		var p=game.players[pid];var age=now-float(p.slide_started);target_velocity=p.slide_direction*maxf(2.4,6.8-age*5.)
		if not is_on_floor():p.slide_until=now
	var acceleration=40. if sliding else 22. if wish.length_squared()>.01 else 28.
	if not is_on_floor():acceleration=16.
	var planar=Vector2(velocity.x,velocity.z).move_toward(Vector2(target_velocity.x,target_velocity.z),acceleration*dt)
	velocity.x=planar.x;velocity.z=planar.y
	if not can_move:velocity.x=0.;velocity.z=0.
	if not is_on_floor():velocity.y-=22*dt
	elif input_state.jump and not grounded_jump and can_move:velocity.y=6
	grounded_jump=bool(input_state.jump)
	was_grounded=is_on_floor()
	var before=global_position
	move_and_slide()
	# Collision recovery can nudge a stationary spawn sideways. That is not a
	# walking step, especially while movement is disabled during round setup.
	if is_on_floor() and can_move and Vector2(velocity.x,velocity.z).length_squared()>.0025:
		gait+=Vector2(global_position.x-before.x,global_position.z-before.z).length()/(2.*Rules.step_length(sprint,crouch))
	if not was_grounded and is_on_floor():land_kick=.055
	update_spread(dt,now)
	var bound=game.arena.bounds if is_instance_valid(game.arena) else Vector2(100,90)
	global_position.x=clampf(global_position.x,-bound.x+2,bound.x-2);global_position.z=clampf(global_position.z,-bound.y+2,bound.y-2)
	if global_position.y< (-12. if game.arena and game.arena.vertical_map else -4.):global_position.y=.2;velocity.y=0
func update_spread(dt:float,now:float):
	if not game.players.has(pid):return
	var p=game.players[pid];var w=game.current_weapon(p)
	aim_progress=move_toward(aim_progress,1. if input_state.ads and p.slot<2 and p.reload<=now else 0.,dt/maxf(.08,float(w.get("ads_ms",250))*.001))
	var target=Aim.spread(w,Vector2(velocity.x,velocity.z).length(),bool(input_state.ads),bool(input_state.crouch),last_sprint,is_on_floor(),float(p.get("bloom",0)),p.get("mounted",0)>now,velocity.y,aim_progress)
	if p.get("slide_until",0)>now:target+=2.3
	spread_angle=lerpf(spread_angle,target,1.-exp(-dt*(18 if target>spread_angle else 13.)))
func headless_pose(p:Dictionary):
	# The same small joint hierarchy drives authoritative hit volumes without meshes.
	set_team(int(p.team))
	if not local and not game.server:global_position=target_pos;rotation.y=aim_yaw
	shape.shape.height=(1.45/1.8*body_height) if input_state.crouch else body_height;shape.position.y=shape.shape.height*.5
	camera.position=Vector3(0,eye_height(bool(input_state.crouch)),0)
	# Receiving headless peers only need capsules/cameras. Server-only anatomy
	# avoids 32 clients redundantly animating 32 complete authoritative rigs each.
	if not game.server:return
	ensure_hit_pose();character.scale.x=float(p.get("hand",1))
	var w=game.current_weapon(p);var progress=clampf((game.clock-float(p.get("reload_started",0)))/maxf(.01,float(w.reload)),0.,1.) if p.reload>game.clock else -1.
	var weapon=character.socket.get_child(0) if character.socket.get_child_count()>0 else null
	if not is_instance_valid(weapon) or weapon.spec.name!=w.name:
		if is_instance_valid(weapon):character.socket.remove_child(weapon);weapon.free()
		weapon=Weapon.new();character.socket.add_child(weapon);weapon.scale=Vector3.ONE*.85;weapon.build_pose(w)
	weapon.animate_reload(progress,0.,game.clock-float(p.get("shot_time",-100.)))
	character.update_pose(1./60.,velocity,last_sprint,bool(input_state.crouch),is_on_floor(),aim_pitch,progress,0.,gait)
	if p.get("slide_until",0)>game.clock:character.slide_pose(clampf((game.clock-float(p.slide_started))/.72,0.,1.))
	character.throw_pose(float(p.get("grenade_started",-100.)),p.get("cooking",0)>0,float(p.get("throw_until",-100.)),game.clock)
func visual(dt:float,p:Dictionary,now:float):
	visible=p.alive and not (is_instance_valid(game.kill_replay) and game.kill_replay.active);set_team(int(p.team));ensure_character()
	handedness=int(p.get("hand",1));character.scale.x=float(handedness);gun.scale.x=float(handedness)
	protected_visual.visible=p.alive and float(p.get("protect",0))>now
	protected_visual.material_override.albedo_color=Color(.20,.66,1,.24+sin(now*9)*.045) if p.team==0 else Color(1,.60,.17,.24+sin(now*9)*.045)
	if p.slot>=2 or p.get("cooking",0)>0:
		var signature=str([p.role,p.gadget,p.slot])
		if signature!=item_signature:
			item_signature=signature
			for child in item_model.get_children():item_model.remove_child(child);child.queue_free()
			EquipmentPreview.gadget_model(item_model,int(p.role),int(p.gadget));item_model.scale=Vector3.ONE*.45;item_model.position=Vector3(0,-.15,-.18)
	var wid=p.primary if p.slot==0 else p.secondary
	if shown_weapon!=wid:shown_weapon=wid;build_gun(wid)
	var w=Catalog.get_weapon(wid);var age=now-float(p.get("shot_time",-100.))
	if float(p.get("shot_time",-100.))>seen_shot:show_shot(float(p.shot_time))
	recoil=move_toward(recoil,0,dt*5.5);hit_recoil=move_toward(hit_recoil,0,dt*4);land_kick=lerpf(land_kick,0,1.-exp(-dt*12))
	var speed=Vector2(velocity.x,velocity.z).length() if local or game.server else Vector2(net_velocity.x,net_velocity.z).length()
	var moving_velocity=velocity if local or game.server else net_velocity
	var grounded=is_on_floor() if local or game.server else net_grounded
	var sprint=last_sprint if local or game.server else net_sprint
	var progress=clampf((now-float(p.get("reload_started",0)))/maxf(.01,float(w.reload)),0,1) if p.reload>now else -1.
	move_blend=lerpf(move_blend,minf(1,speed/Rules.WALK_SPEED),1.-exp(-dt*9))
	if not local and not game.server and grounded:net_gait+=dt*speed/(2.*Rules.step_length(sprint,bool(input_state.crouch)))
	var phase=gait if local or game.server else net_gait
	bob=phase*TAU
	var yaw_delta=wrapf(aim_yaw-previous_yaw,-PI,PI);previous_yaw=aim_yaw;turn_sway=lerpf(turn_sway,clampf(yaw_delta/maxf(dt,.001),-4,4),1.-exp(-dt*10))
	character.update_pose(dt,moving_velocity,sprint,bool(input_state.crouch),grounded,aim_pitch,progress,recoil,phase,turn_sway)
	if p.get("slide_until",0)>now:character.slide_pose(clampf((now-float(p.slide_started))/.72,0.,1.))
	character.throw_pose(float(p.get("grenade_started",-100.)),p.get("cooking",0)>0,float(p.get("throw_until",-100.)),now)
	if is_instance_valid(world_weapon):
		world_weapon.visible=p.slot<2 and p.get("cooking",0)==0;world_weapon.animate_reload(progress,recoil,age)
		world_weapon.position=Vector3(0,0,recoil*.055);world_weapon.rotation=Vector3(recoil*.12,0,sin(shot_serial*2.3)*recoil*.025)
	if not local:
		if not game.server:global_position=global_position.lerp(target_pos,minf(1,dt*14));rotation.y=lerp_angle(rotation.y,aim_yaw,minf(1,dt*15))
		shape.shape.height=(1.45/1.8*body_height) if input_state.crouch else body_height;shape.position.y=shape.shape.height*.5
		tag.visible=game.players.has(game.local_id) and (p.team==game.players[game.local_id].team or p.mark>now)
		tag.modulate=Color("ffae65") if p.mark>now else Color("6ccaff") if p.team==0 else Color("ff9b55");tag.text=("◆ " if p.team==0 else "● ")+p.nick
		return
	var reloading=p.reload>now
	var stage=0 if progress<.3 else 1 if progress<.76 else 2
	if reloading and stage!=reload_stage:
		reload_stage=stage
		if stage>0:game.play_sound("magazine" if stage==1 else "bolt",Vector3.ZERO,false)
	elif not reloading:reload_stage=-1
	var ads=input_state.ads and p.slot<2 and not reloading
	ads_blend=move_toward(ads_blend,1. if ads else 0.,dt/maxf(.08,float(w.get("ads_ms",250))*.001));crouch_blend=lerpf(crouch_blend,1. if input_state.crouch else 0.,1.-exp(-dt*14))
	var scoped=ads and float(w.zoom)<=38 and ads_blend>.9
	camera.position.x=0.;camera.position.z=0.;camera.rotation=Vector3(aim_pitch,0,0);camera.position.y=lerpf(eye_height(false),eye_height(true),crouch_blend)-land_kick
	camera.fov=lerpf(88. if sprint else 82.,float(w.zoom),ads_blend)
	var base=Vector3(.255,-.255,-.46).lerp(Vector3(0,-.14,-.5),ads_blend)
	var motion=move_blend*(1.-ads_blend*.93)
	base.y+=sin(now*1.9)*.002*(1.-move_blend)*(1.-ads_blend)
	base+=Vector3(cos(bob)*.022,cos(bob*2)*.017,0)*motion
	var rotation_target=Vector3(recoil*lerpf(.34,.12,ads_blend),-.09 if sprint else -turn_sway*.012,-.05*motion*sin(bob)+sin(shot_serial*2.3)*recoil*.025)
	if sprint:base+=Vector3(.075,-.055,.055);rotation_target+=Vector3(-.2,.3,.23)
	if reloading:
		base+=Vector3(.035,.015,.085)*sin(progress*PI);rotation_target+=Vector3(.10,-.15,-.31)*sin(progress*PI)
	if p.get("cooking",0)>0:base+=Vector3(-.08,.07,.05);rotation_target+=Vector3(.25,.15,-.22)
	if float(p.get("throw_until",-100.))>now:base.z-=sin((.45-float(p.throw_until)+now)/.45*PI)*.32
	var swap=clampf((float(p.get("switch_until",0))-now)/.32,0,1);base.y-=swap*.32;rotation_target.z-=swap*.3
	base.x-=turn_sway*.004*(1.-ads_blend*.85)
	base.z+=recoil*(.105 if w.slot==1 else .155)*lerpf(1.,.38,ads_blend);base.y+=recoil*.025*(1.-ads_blend);base.y-=land_kick*.6
	base.x*=handedness;rotation_target.y*=handedness;rotation_target.z*=handedness
	gun.position=gun.position.lerp(base,1.-exp(-dt*20));gun.rotation=gun.rotation.lerp(rotation_target,1.-exp(-dt*22))
	var cooking=p.get("cooking",0)>0
	view_weapon.visible=p.slot<2 and not scoped and not cooking;item_model.visible=p.slot>=2 or cooking;view_weapon.animate_reload(progress,recoil,age)
	var envelope=Aim.reticle_angle(w,p,spread_angle,aim_progress,bool(input_state.crouch))
	visual_spread=lerpf(visual_spread,envelope,1.-exp(-dt*(35. if envelope>visual_spread else 22.)))

func show_shot(at:float) -> bool:
	if at<=seen_shot:return false
	seen_shot=at;shot_serial+=1;recoil=minf(1.8,recoil*.35+float(game.current_weapon(game.players[pid]).get("recoil_kick",1.)))
	if local and is_instance_valid(view_weapon) and is_instance_valid(game.combat_fx) and game.players.has(pid) and game.players[pid].slot<2:
		var source=gun.to_global(Vector3(.09,.01,-.16))
		game.combat_fx.eject_case(source,camera.global_basis.x,camera.global_basis.y,global_position.y,shot_serial+pid)
	return true
