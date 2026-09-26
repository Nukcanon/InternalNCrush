extends Node
class_name KillReplay
const RUNUP_SECONDS=1.75
const BULLET_SECONDS=.55
const FIRST_PERSON_SECONDS=RUNUP_SECONDS+BULLET_SECONDS
const DEATH_SECONDS=.5
const PORTRAIT_SECONDS=2.0
const TOTAL_SECONDS=FIRST_PERSON_SECONDS+DEATH_SECONDS+PORTRAIT_SECONDS
const MAX_FRAMES=90
var game:Node
var history:Array=[]
var sample_clock=0.
var pending={}
var pending_delay=0.
var active=false
var elapsed=0.
var frames:Array=[]
var event={}
var overlay:CanvasLayer
var stage:Node3D
var camera:Camera3D
var models={}
var signatures={}
var first_person_guns={}
var ghost_props={}
var ghost_devices={}
var gun:WeaponVisual
var title:Label
var detail:Label
var nickname:Label
var progress:ProgressBar
var punch_played=false
var fx:CombatFX
var shot_history:Array=[]
var playback_shots:Array=[]
var shot_cursor=0
var kick=0.
var bullet:Node3D
var melee_view:MeleeVisual
var melee_world:MeleeVisual
var bullet_trail:MeshInstance3D
var fatal_frame={}
var fall_started=false
var fatal_sound_played=false
var begin_usec=0
var map_instance=0
var warm_clock=0.
static func bullet_camera_point(start:Vector3,end:Vector3,progress:float) -> Vector3:
	var direction=(end-start).normalized()
	if direction.length_squared()<.1:direction=Vector3.FORWARD
	var distance=start.distance_to(end)
	# Reserve more than a full shoulder width between the lens and the victim.
	var stop=distance-1.35
	var travel=clampf(distance*clampf(progress,0.,1.)-.9,minf(-.9,stop),stop)
	return start+direction*travel+Vector3.UP*.14
func follow_bullet(progress:float):
	# Point-blank shots need space behind the muzzle; hide only the firing turret.
	if event.weapon in ["turret","turret_missile"]:
		for id in ghost_devices:
			if game.devices.has(id) and game.devices[id].owner==event.attacker and game.devices[id].kind=="turret":ghost_devices[id].hide()
	var start:Vector3=event.origin;var end:Vector3=event.hit_point
	var desired=bullet_camera_point(start,end,progress)
	var hit=game.ray(start,desired,[],1|4|8)
	if not hit.is_empty():desired=hit.position+hit.normal*.18
	if desired.distance_to(end)<1.1:desired=bullet_camera_point(start,end,0.)
	camera.position=desired;camera.look_at(end);camera.fov=68.;gun.hide()
func prepare():
	if is_instance_valid(stage):return
	stage=Node3D.new();stage.name="ReplayActors";game.add_child(stage);stage.visible=false;stage.process_mode=Node.PROCESS_MODE_DISABLED
	fx=CombatFX.new();stage.add_child(fx)
	camera=Camera3D.new();camera.fov=82.;camera.near=.04;camera.far=300.;stage.add_child(camera)
	bullet=ReplayProjectile.make(stage)
	var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("ffcc69");material.emission_enabled=true;material.emission=Color("ffba50");material.emission_energy_multiplier=2.
	bullet_trail=MeshInstance3D.new();var mesh=CylinderMesh.new();mesh.top_radius=.012;mesh.bottom_radius=.028;mesh.height=1.;mesh.radial_segments=8;bullet_trail.mesh=mesh;bullet_trail.material_override=material;stage.add_child(bullet_trail)
	bullet.hide();bullet_trail.hide()
	overlay=CanvasLayer.new();overlay.layer=30;add_child(overlay);overlay.hide()
	var top=PanelContainer.new();top.position=Vector2(225,18);top.custom_minimum_size=Vector2(830,0);top.theme=game.ui.theme;overlay.add_child(top)
	var text=VBoxContainer.new();top.add_child(text)
	title=Label.new();title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.modulate=Color("ffc16e");text.add_child(title)
	detail=Label.new();detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.add_theme_font_size_override("font_size",16);text.add_child(detail)
	progress=ProgressBar.new();progress.show_percentage=false;progress.custom_minimum_size.y=4;progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.add_child(progress)
	nickname=Label.new();nickname.position=Vector2(170,530);nickname.size=Vector2(940,100);nickname.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;nickname.add_theme_font_size_override("font_size",38);nickname.add_theme_color_override("font_outline_color",Color("101820"));nickname.add_theme_constant_override("outline_size",10);nickname.theme=game.ui.theme;overlay.add_child(nickname)
func warm_one():
	# Spread preparation across frames while alive. begin() never builds a map or a rig.
	if active or not is_instance_valid(game.arena):return
	prepare()
	for id in models.keys():
		if not game.players.has(id) and not history.any(func(frame):return frame.actors.has(id)):
			models[id].queue_free();models.erase(id);signatures.erase(id);return
	for id in ghost_devices.keys():
		if not game.devices.has(id) and not history.any(func(frame):return frame.get("devices",{}).has(id)):
			ghost_devices[id].queue_free();ghost_devices.erase(id);return
	for id in game.players:
		var p=game.players[id];var role=int(p.role) if game.options.classes else 0;var wid=p.primary if p.slot==0 else p.secondary
		var signature=str([role,p.team,wid])
		if signatures.get(id,"")!=signature:
			var node=models.get(id)
			if not is_instance_valid(node) or node.get_meta("body_signature","")!=str([role,p.team]):
				if is_instance_valid(node):node.queue_free()
				node=Node3D.new();stage.add_child(node);models[id]=node
				var body=CharacterVisual.new();body.enable_physics=false;body.name="Body";node.add_child(body);body.build(role,int(p.team))
				node.set_meta("body_signature",str([role,p.team]))
			var body=node.get_node("Body")
			for old in body.socket.get_children():old.free()
			var weapon=WeaponVisual.new();body.socket.add_child(weapon);weapon.build(Catalog.get_weapon(wid),false);weapon.scale=Vector3.ONE*.8
			signatures[id]=signature
			return
		if not first_person_guns.has(wid):
			var weapon=WeaponVisual.new();camera.add_child(weapon);weapon.build(Catalog.get_weapon(wid));weapon.hide();first_person_guns[wid]=weapon;return
	for id in game.arena.props:
		if not ghost_props.has(id):
			var prop=game.arena.props[id];var node=Node3D.new();stage.add_child(node);ghost_props[id]=node
			for child in prop.get_children():
				if child is MeshInstance3D:
					var copy=child.duplicate();node.add_child(copy);copy.show()
			return
	for id in game.device_nodes:
		if not ghost_devices.has(id) and game.devices.has(id):
			var d=game.devices[id];var node=Node3D.new();stage.add_child(node);ghost_devices[id]=node;CombatFX.device(node,d.kind,int(d.team));return
func capture(dt:float):
	if game.phase!="combat" or game.demo_mode or game.dedicated:return
	sample_clock+=dt
	if sample_clock<.05:return
	sample_clock=0.
	var actors={}
	for id in game.players:
		if not game.actors.has(id):continue
		var p=game.players[id];var a=game.actors[id]
		actors[id]={"pos":a.position,"yaw":a.aim_yaw,"pitch":a.aim_pitch,"slot":p.slot,"melee_age":game.clock-float(p.get("melee_started",-100.)),"role":a.shown_role if a.shown_role>=0 else p.role,"team":p.team,"weapon":p.primary if p.slot==0 else p.secondary,"hand":p.get("hand",1),"alive":p.alive,"grounded":a.is_on_floor() if game.server or a.local else a.net_grounded,"crouch":a.input_state.crouch,"sprint":a.last_sprint if game.server or a.local else a.net_sprint,"velocity":a.velocity if game.server or a.local else a.net_velocity,"gait":a.gait if game.server or a.local else a.net_gait}
	history.append({"time":Time.get_ticks_msec()/1000.,"actors":actors,"devices":game.devices.duplicate(true),"props":game.arena.prop_states() if game.arena else []})
	while history.size()>MAX_FRAMES:history.pop_front()
func request(kill:Dictionary):
	if int(kill.victim)!=game.local_id or int(kill.attacker)==game.local_id or int(kill.attacker)==0:return
	if history.size()<2:return
	pending=kill.duplicate();pending_delay=.04
func _process(dt):
	warm_clock-=dt
	if game.phase in ["combat","lobby"] and not game.demo_mode and warm_clock<=0.:
		warm_one();warm_clock=.05 if OS.has_feature("web") else .025
	if not pending.is_empty():
		pending_delay-=dt
		if pending_delay<=0:
			var kill=pending;pending={};begin(kill)
	if not active:return
	overlay.scale=game.get_viewport().get_visible_rect().size/Vector2(1280,720)
	elapsed+=dt
	if game.phase not in ["combat","round_end","result"] or not game.players.has(game.local_id) or (elapsed>.3 and game.players[game.local_id].alive):finish();return
	if elapsed>=TOTAL_SECONDS:finish();return
	hide_live(true)
	var last=float(fatal_frame.time)
	var time=lerpf(maxf(float(frames[0].time),last-RUNUP_SECONDS),last,minf(1.,elapsed/RUNUP_SECONDS))
	var left=frames[0];var right=fatal_frame
	for i in range(frames.size()-1):
		if frames[i].time<=time and frames[i+1].time>=time:left=frames[i];right=frames[i+1];break
	if elapsed>=RUNUP_SECONDS:left=fatal_frame;right=fatal_frame
	var blend=clampf((time-left.time)/maxf(.001,right.time-left.time),0,1)
	for id in ghost_props:ghost_props[id].hide()
	for state in left.get("props",[]):
		if ghost_props.has(int(state[0])):
			var node=ghost_props[int(state[0])];node.position=state[1];node.quaternion=state[2];node.show()
	for id in ghost_devices:
		var node=ghost_devices[id];node.visible=left.get("devices",{}).has(id)
		if node.visible:
			node.position=left.devices[id].pos;node.rotation.y=left.devices[id].yaw
			node.scale=Vector3.ONE*(TurretLogic.SCALES[int(left.devices[id].level)-1] if left.devices[id].kind=="turret" else 1.)
	for id in models:
		if not left.actors.has(id):models[id].hide();continue
		var a=left.actors[id];var b=right.actors.get(id,a);var node=models[id]
		node.position=a.pos.lerp(b.pos,blend);node.rotation.y=lerp_angle(a.yaw,b.yaw,blend);node.visible=a.alive or id==int(event.victim)
		if id==int(event.victim) and elapsed>RUNUP_SECONDS-.15:node.position=node.position.lerp(event.get("victim_pos",node.position),clampf((elapsed-RUNUP_SECONDS+.15)/.15,0,1))
		var visual=node.get_node("Body");visual.scale.x=float(a.get("hand",1))
		if id==int(event.victim) and elapsed>=FIRST_PERSON_SECONDS:
			if not fall_started:
				var direction=(Vector3(event.hit_point)-Vector3(event.origin)).normalized()
				fx.ragdoll(visual,node.global_position,direction,int(a.role),int(a.team),node.rotation.y,bool(a.crouch),a.velocity,event.hit_point)
				fall_started=true;game.play_sound("hurt",Vector3.ZERO,false)
			node.hide()
		else:visual.update_pose(dt,a.velocity if elapsed<RUNUP_SECONDS else Vector3.ZERO,a.sprint and elapsed<RUNUP_SECONDS,a.crouch,a.grounded,a.pitch,-1,0,a.gait,0)
	var killer=int(event.attacker);var state=left.actors.get(killer,{})
	if state.is_empty() or not models.has(killer):finish();return
	var attacker=models[killer]
	while shot_cursor<playback_shots.size() and playback_shots[shot_cursor].time<=time and elapsed<RUNUP_SECONDS:
		var shot=playback_shots[shot_cursor];shot_cursor+=1;fx.beam(shot.from,shot.to,false)
		if int(shot.owner)==killer:kick=1.
	kick=move_toward(kick,0,dt*5.5)
	if elapsed<FIRST_PERSON_SECONDS+DEATH_SECONDS:
		attacker.hide();camera.fov=82.;gun.visible=event.weapon not in ["turret","turret_missile","knife","wrench"]
		camera.position=attacker.position+Vector3.UP*(1.30 if state.crouch else 1.62)*HumanModel.HEIGHTS[int(state.role)]/1.8
		camera.rotation=Vector3(lerpf(state.pitch,right.actors.get(killer,state).pitch,blend),attacker.rotation.y,0)
		if event.weapon in ["turret","turret_missile"]:
			camera.position=event.origin+(event.hit_point-event.origin).normalized()*.25+Vector3.UP*.10;camera.look_at(event.hit_point);gun.hide()
		gun.scale.x=float(state.get("hand",1));gun.rotation=Vector3(kick*.24,0,0);gun.position=Vector3(.255*float(state.get("hand",1)),-.255,-.46+kick*.11);gun.animate_reload(-1.,kick,0. if kick>.75 else 10.)
		if elapsed>=RUNUP_SECONDS and event.weapon not in ["knife","wrench"]:
			camera.look_at(event.hit_point);camera.fov=70.
			if elapsed<FIRST_PERSON_SECONDS:
				if not fatal_sound_played:fatal_sound_played=true;game.play_sound("gun_"+str(event.weapon) if Catalog.weapons.has(event.weapon) else "gun_h1",Vector3.ZERO,false)
				title.text="킬 리플레이 · 마지막 탄환 · 슬로 모션"
				var t=clampf((elapsed-RUNUP_SECONDS)/BULLET_SECONDS,0,1);var start:Vector3=event.origin;var end:Vector3=event.hit_point;var direction=(end-start).normalized()
				bullet.show();bullet_trail.show();bullet.position=Ballistics.between(start,end,smoothstep(0.,1.,t)) if Catalog.weapons.has(event.weapon) or event.weapon=="turret" else start.lerp(end,smoothstep(0.,1.,t))
				follow_bullet(smoothstep(0.,1.,t))
				bullet.quaternion=Quaternion(Vector3.UP,direction)
				var length=minf(1.4,start.distance_to(bullet.position));bullet_trail.position=bullet.position-direction*(.023+length*.5);bullet_trail.scale.y=maxf(.001,length);bullet_trail.quaternion=Quaternion(Vector3.UP,direction)
			else:
				bullet.hide();bullet_trail.hide();title.text="킬 리플레이 · 사망 순간"
				follow_bullet(1.)
	else:
		if not punch_played:punch_played=true;title.text="킬 리플레이 · 처치한 플레이어";nickname.text=str(event.attacker_name);nickname.show();game.play_sound("kill_sting",Vector3.ZERO,false)
		attacker.show();gun.hide()
		var t=clampf((elapsed-FIRST_PERSON_SECONDS-DEATH_SECONDS)/PORTRAIT_SECONDS,0,1)
		var focus=attacker.position+Vector3.UP*1.43*HumanModel.HEIGHTS[int(state.role)]/1.8
		var desired=focus+Basis(Vector3.UP,attacker.rotation.y)*Vector3(.45,.16,-lerpf(3.2,1.35,1.-pow(1.-t,3)))
		var hit=game.ray(focus,desired,[],1);camera.position=hit.position+hit.normal*.15 if not hit.is_empty() else desired
		camera.look_at(focus);camera.rotation.z=sin(t*PI)*-.035;camera.fov=lerpf(68.,55.,1.-pow(1.-t,3))
	if event.weapon in ["knife","wrench"] and is_instance_valid(melee_view):
		var age=elapsed-RUNUP_SECONDS+.20
		var showing=int(state.get("slot",0))==MeleeCombat.SLOT or elapsed>=RUNUP_SECONDS-.20 or float(state.get("melee_age",100.))<MeleeCombat.DURATION
		melee_view.visible=showing and elapsed<FIRST_PERSON_SECONDS;melee_world.visible=elapsed>=FIRST_PERSON_SECONDS+DEATH_SECONDS
		gun.visible=not showing and elapsed<FIRST_PERSON_SECONDS
		melee_view.pose(age);melee_view.position=Vector3(.255*float(state.get("hand",1)),-.255,-.46);melee_view.scale.x=float(state.get("hand",1))
		melee_world.pose(-1.)
		var body=models[killer].get_node("Body")
		body.solve_arm(body.right_arm,body.right_elbow,body.chest.to_local(melee_world.palm.global_position),Vector3(.75,-.8,.25),dt,1.)
		body.left_arm.rotation=Vector3(.15,.05,.12);body.left_elbow.rotation=Vector3(.35,0,0);body.sync_deform()
		if elapsed>=RUNUP_SECONDS and elapsed<FIRST_PERSON_SECONDS:
			title.text="킬 리플레이 · 근접 공격"
			if not fatal_sound_played:fatal_sound_played=true;game.play_sound("melee_swing",Vector3.ZERO,false)
		for child in models[killer].get_node("Body").socket.get_children():
			if child is WeaponVisual:child.hide()
	progress.value=elapsed/TOTAL_SECONDS*100
func begin(kill:Dictionary):
	var started=Time.get_ticks_usec()
	finish();event=kill.duplicate();frames=history.duplicate()
	var killer=int(kill.attacker);var victim=int(kill.victim)
	if frames.is_empty() or not models.has(killer) or not is_instance_valid(stage):return
	fatal_frame=frames.back()
	# Use the last living pose, so the actual victim remains visible through the impact.
	for i in range(frames.size()-1,-1,-1):
		if frames[i].actors.has(victim) and frames[i].actors[victim].alive:fatal_frame=frames[i];break
	if not fatal_frame.actors.has(killer):return
	var weapon=fatal_frame.actors[killer].weapon
	if not first_person_guns.has(weapon):return
	gun=first_person_guns[weapon]
	if kill.weapon in ["knife","wrench"]:
		var role=int(fatal_frame.actors[killer].role)
		melee_view=MeleeVisual.new();camera.add_child(melee_view);melee_view.build(kill.weapon=="wrench",role,true)
		melee_world=MeleeVisual.new();models[killer].get_node("Body").socket.add_child(melee_world);melee_world.build(kill.weapon=="wrench",role,false)
	event.hit_point=event.get("hit_point",event.get("victim_pos",Vector3.ZERO)+Vector3.UP*1.2)
	active=true;elapsed=0.;punch_played=false;fall_started=false;fatal_sound_played=false;kick=0.;shot_cursor=0
	var beginning=maxf(float(frames[0].time),float(fatal_frame.time)-RUNUP_SECONDS)
	playback_shots=shot_history.filter(func(shot):return shot.time>=beginning and shot.time<fatal_frame.time-.035)
	stage.process_mode=Node.PROCESS_MODE_INHERIT;stage.show();overlay.show();camera.current=true;bullet.hide();bullet_trail.hide();nickname.hide();hide_live(true)
	title.text="킬 리플레이 · 공격자 1인칭"
	var weapon_name="칼" if kill.weapon=="knife" else "렌치" if kill.weapon=="wrench" else Catalog.get_weapon(kill.weapon).name if Catalog.weapons.has(kill.weapon) else "자동 포탑"
	detail.text="%s  ·  %s%s  ·  기록 기반 재구성  ·  SPACE 건너뛰기"%[kill.attacker_name,weapon_name," / 정밀 명중" if kill.get("critical",false) else ""]
	begin_usec=Time.get_ticks_usec()-started
func hide_live(hidden:bool):
	if is_instance_valid(game.combat_fx):game.combat_fx.visible=not hidden
	if is_instance_valid(game.ui.hud):game.ui.hud.visible=not hidden
	if is_instance_valid(game.ui.damage_indicator):game.ui.damage_indicator.visible=not hidden
	for a in game.actors.values():a.visible=not hidden and game.players.get(a.pid,{}).get("alive",false)
	if is_instance_valid(game.arena):
		for p in game.arena.props.values():p.visible=not hidden
		for child in game.arena.get_children():
			if child is WebPropBatch:child.visible=not hidden
	for node in game.device_nodes.values():node.visible=not hidden
	for node in game.drop_nodes.values():node.visible=not hidden
func finish():
	if is_instance_valid(melee_view):melee_view.hide();melee_view.queue_free();melee_view=null
	if is_instance_valid(melee_world):melee_world.hide();melee_world.queue_free();melee_world=null
	var was_active=active;active=false;frames.clear()
	if is_instance_valid(stage):stage.hide();stage.process_mode=Node.PROCESS_MODE_DISABLED;camera.current=false;fx.clear()
	if is_instance_valid(overlay):overlay.hide()
	for weapon in first_person_guns.values():weapon.hide()
	for model in models.values():
		for child in model.get_node("Body").socket.get_children():
			if child is WeaponVisual:child.show()
	if was_active:hide_live(false);game.update_spectator()
func reset():
	pending={};history.clear();shot_history.clear();finish()
	if is_instance_valid(stage):stage.queue_free()
	if is_instance_valid(overlay):overlay.queue_free()
	stage=null;overlay=null;models.clear();signatures.clear();first_person_guns.clear();ghost_props.clear();ghost_devices.clear()
func record_shot(from:Vector3,to:Vector3,owner:int):
	var now=Time.get_ticks_msec()/1000.
	shot_history.append({"time":now,"from":from,"to":to,"owner":owner})
	while shot_history.size()>512 or (not shot_history.is_empty() and now-shot_history[0].time>4.5):shot_history.pop_front()
