extends Node
class_name KillReplay
const FIRST_PERSON_SECONDS=2.5
const PORTRAIT_SECONDS=1.0
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
var viewport:SubViewport
var stage:Node3D
var replay_arena:Arena
var camera:Camera3D
var models={}
var gun:WeaponVisual
var title:Label
var progress:ProgressBar
var punch_played=false
var fx:CombatFX
var last_shots={}
var shot_history:Array=[]
var playback_shots:Array=[]
var shot_cursor=0
var kick=0.
func capture(dt:float):
	if game.phase!="combat" or game.demo_mode or game.dedicated:return
	sample_clock+=dt
	if sample_clock<.05:return
	sample_clock=0.
	var actors={}
	for id in game.players:
		if not game.actors.has(id):continue
		var p=game.players[id];var a=game.actors[id]
		actors[id]={"pos":a.position,"yaw":a.aim_yaw,"pitch":a.aim_pitch,"role":a.shown_role if a.shown_role>=0 else p.role,"team":p.team,"weapon":p.primary if p.slot==0 else p.secondary,"alive":p.alive,"grounded":a.is_on_floor() if game.server or a.local else a.net_grounded,"shot":p.get("shot_time",-100.),"crouch":a.input_state.crouch,"sprint":a.last_sprint if game.server or a.local else a.net_sprint,"velocity":a.velocity if game.server or a.local else a.net_velocity,"gait":a.gait if game.server or a.local else a.net_gait}
	history.append({"time":Time.get_ticks_msec()/1000.,"actors":actors,"devices":game.devices.duplicate(true),"props":game.arena.prop_states() if game.arena else []})
	while history.size()>MAX_FRAMES:history.pop_front()
func request(kill:Dictionary):
	if int(kill.victim)!=game.local_id or int(kill.attacker)==game.local_id or int(kill.attacker)==0:return
	if history.size()<2:return
	pending=kill.duplicate(true);pending_delay=.12
func _process(dt):
	if not pending.is_empty():
		pending_delay-=dt
		if pending_delay<=0:
			var kill=pending;pending={};begin(kill)
	if not active:return
	elapsed+=dt
	if game.phase not in ["combat","round_end","result"] or not game.players.has(game.local_id) or (elapsed>.3 and game.players[game.local_id].alive):finish();return
	if elapsed>=FIRST_PERSON_SECONDS+PORTRAIT_SECONDS:finish();return
	var last=frames.back().time
	var time=lerpf(maxf(frames[0].time,last-FIRST_PERSON_SECONDS),last,minf(1.,elapsed/FIRST_PERSON_SECONDS))
	var left=frames[0];var right=frames.back()
	for i in range(frames.size()-1):
		if frames[i].time<=time and frames[i+1].time>=time:left=frames[i];right=frames[i+1];break
	var blend=clampf((time-left.time)/maxf(.001,right.time-left.time),0,1)
	replay_arena.receive_props(left.get("props",[]))
	for id in models:
		if not left.actors.has(id):models[id].visible=false;continue
		var a=left.actors[id];var b=right.actors.get(id,a);var node=models[id]
		node.position=a.pos.lerp(b.pos,blend);node.rotation.y=lerp_angle(a.yaw,b.yaw,blend);node.visible=a.alive
		var visual=node.get_node("Body")
		visual.update_pose(dt,a.velocity,a.sprint,a.crouch,a.grounded,a.pitch,-1,0,a.gait,0)
	var killer=int(event.attacker)
	if not left.actors.has(killer) or not models.has(killer):finish();return
	while shot_cursor<playback_shots.size() and playback_shots[shot_cursor].time<=time:
		var shot=playback_shots[shot_cursor];shot_cursor+=1
		var start=shot.from
		if int(shot.owner)==killer:start+=(shot.to-start).normalized()*.75;kick=1.
		fx.beam(start,shot.to,false)
	kick=move_toward(kick,0,dt*5.5)
	var state=left.actors[killer];var attacker=models[killer]
	if elapsed<FIRST_PERSON_SECONDS:
		attacker.visible=false;gun.visible=true
		camera.position=attacker.position+Vector3.UP*(1.30 if state.crouch else 1.62)*HumanModel.HEIGHTS[int(state.role)]/1.8
		camera.rotation=Vector3(lerpf(state.pitch,right.actors.get(killer,state).pitch,blend),attacker.rotation.y,0)
		if event.weapon=="turret":
			camera.position=event.get("origin",camera.position)+Vector3.UP*.1
			camera.look_at(event.get("victim_pos",camera.position+Vector3.FORWARD)+Vector3.UP*1.2);gun.visible=false
		gun.rotation.x=kick*.24;gun.position.z=-.46+kick*.11;gun.animate_reload(-1.,kick,0. if kick>.75 else 10.)
	else:
		if not punch_played:
			punch_played=true;title.text="킬 리플레이 · 처치한 플레이어 · "+str(event.attacker_name);game.play_sound("kill_sting",Vector3.ZERO,false)
		attacker.visible=true;gun.visible=false
		var t=clampf((elapsed-FIRST_PERSON_SECONDS)/PORTRAIT_SECONDS,0,1)
		var focus=attacker.position+Vector3.UP*1.40*HumanModel.HEIGHTS[int(state.role)]/1.8
		var facing=Basis(Vector3.UP,attacker.rotation.y)
		var desired=focus+facing*Vector3(.55,.22,-lerpf(3.2,1.35,1.-pow(1.-t,3)))
		var hit=stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(focus,desired,1))
		camera.position=hit.position+hit.normal*.15 if not hit.is_empty() else desired
		camera.look_at(focus);camera.rotation.z=sin(t*PI)*-.035
		camera.fov=lerpf(68.,55.,1.-pow(1.-t,3))
	progress.value=elapsed/(FIRST_PERSON_SECONDS+PORTRAIT_SECONDS)*100
func begin(kill:Dictionary):
	finish();event=kill;frames=history.duplicate(true)
	if frames.is_empty() or not frames.back().actors.has(int(kill.attacker)):return
	active=true;elapsed=0.;punch_played=false;last_shots.clear();kick=0.;shot_cursor=0
	var beginning=maxf(frames[0].time,frames.back().time-FIRST_PERSON_SECONDS)
	playback_shots=shot_history.filter(func(shot):return shot.time>=beginning and shot.time<=frames.back().time).duplicate(true)
	overlay=CanvasLayer.new();overlay.layer=30;add_child(overlay)
	var container=SubViewportContainer.new();container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(container)
	viewport=SubViewport.new();viewport.size=Vector2i(1280,720);viewport.own_world_3d=true;viewport.gui_disable_input=true;viewport.audio_listener_enable_3d=false;container.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var arena=Arena.new();stage.add_child(arena);arena.build(int(game.options.map));replay_arena=arena
	fx=CombatFX.new();stage.add_child(fx)
	for device in frames.back().get("devices",{}).values():
		var node=Node3D.new();stage.add_child(node);node.position=device.pos;node.rotation.y=device.yaw;CombatFX.device(node,device.kind,int(device.team))
	for id in frames.back().actors:
		var state=frames.back().actors[id];var node=Node3D.new();stage.add_child(node);models[id]=node
		var body=CharacterVisual.new();body.name="Body";node.add_child(body);body.build(int(state.role),int(state.team))
		var weapon=WeaponVisual.new();body.socket.add_child(weapon);weapon.build(Catalog.get_weapon(state.weapon),false);weapon.scale=Vector3.ONE*.8
	camera=Camera3D.new();camera.fov=82.;camera.near=.06;camera.far=250.;stage.add_child(camera);camera.current=true
	gun=WeaponVisual.new();camera.add_child(gun);gun.build(Catalog.get_weapon(kill.weapon) if Catalog.weapons.has(kill.weapon) else Catalog.get_weapon("a1"));gun.position=Vector3(.255,-.255,-.46)
	var top=PanelContainer.new();top.position=Vector2(250,18);top.custom_minimum_size=Vector2(780,0);top.theme=game.ui.theme;overlay.add_child(top)
	var text=VBoxContainer.new();top.add_child(text)
	title=Label.new();title.text="킬 리플레이 · "+("포탑 시점" if kill.weapon=="turret" else "공격자 1인칭");title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.modulate=Color("ffc16e");text.add_child(title)
	var detail=Label.new();detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.add_theme_font_size_override("font_size",17)
	var weapon_name=Catalog.get_weapon(kill.weapon).name if Catalog.weapons.has(kill.weapon) else "자동 포탑"
	detail.text="%s  ·  %s%s  ·  기록 기반 재구성  ·  SPACE 건너뛰기"%[kill.attacker_name,weapon_name," / 정밀 명중" if kill.get("critical",false) else ""];text.add_child(detail)
	progress=ProgressBar.new();progress.show_percentage=false;progress.custom_minimum_size.y=4;progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.add_child(progress)
func finish():
	active=false;models.clear();frames.clear()
	if is_instance_valid(overlay):overlay.queue_free()
	overlay=null
func reset():
	pending={};history.clear();shot_history.clear();finish()

func record_shot(from:Vector3,to:Vector3,owner:int):
	var now=Time.get_ticks_msec()/1000.
	shot_history.append({"time":now,"from":from,"to":to,"owner":owner})
	while shot_history.size()>512 or (not shot_history.is_empty() and now-shot_history[0].time>4.5):shot_history.pop_front()
