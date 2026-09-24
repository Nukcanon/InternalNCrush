class_name TouchControls
extends Control
## Multitouch input is separate from mouse emulation: moving, aiming and firing
## can happen simultaneously. Desktop never installs this overlay.
var game:Node
var fingers={}
var positions={}
var input_transform=Transform2D.IDENTITY
var buttons={}
var movement=Vector2.ZERO
var held={}
var stick_center=Vector2(165,500)
var stick_point=Vector2(165,500)
var stick_id=-1
var look_id=-1
var enabled=false
var was_active=false
var last_run_tap=-1000
static func supported() -> bool:
	if "--touch-test" in OS.get_cmdline_user_args():return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("navigator.maxTouchPoints>0 && (matchMedia('(pointer:coarse)').matches || /Android|iPhone|iPad|Mobile/i.test(navigator.userAgent))"))
	return OS.has_feature("mobile")
func _ready():
	enabled=supported();mouse_filter=Control.MOUSE_FILTER_IGNORE;set_process_input(enabled);visible=false
	buttons={
		"fire":Rect2(1100,400,130,130),"reload":Rect2(1000,555,104,82),"ads":Rect2(980,410,96,82),
		"jump":Rect2(1150,565,104,82),"crouch":Rect2(1150,660-10,104,60),
		"sprint":Rect2(75,350,105,78),"slide":Rect2(200,350,105,78),
		"skill":Rect2(395,542,105,76),"gadget":Rect2(514,542,105,76),"use":Rect2(633,542,105,76),"medical":Rect2(752,542,105,76),
		"gear":Rect2(430,452,170,70),"mode":Rect2(620,452,170,70),"menu":Rect2(1130,15,130,65),"score":Rect2(980,15,130,65)}
	for i in range(4):buttons["slot"+str(i)]=Rect2(390+i*126,635,118,70)
func active() -> bool:
	return enabled and is_instance_valid(game.ui) and not is_instance_valid(game.ui.panel) and game.phase in ["combat","buy","round_end","result"] and game.players.has(game.local_id)
func reset():
	if held.get("gadget",false) and game.players.has(game.local_id):game.command("gadget_release",{})
	fingers.clear();positions.clear();held.clear();movement=Vector2.ZERO;stick_id=-1;look_id=-1
func _notification(what):
	# A browser/app switch may omit the last touch-up event. Never retain a
	# virtual trigger or movement stick when the window loses focus.
	if enabled and is_instance_valid(game) and what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:reset()
func _process(_dt):
	visible=active()
	if not visible and was_active:reset()
	was_active=visible
	if visible:
		if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		queue_redraw()
func press(action:String,on:bool):
	if action in ["ads","crouch"]:
		if on:held[action]=not held.get(action,false)
		return
	held[action]=on
	if action=="gadget":game.command("gadget_press" if on else "gadget_release",{});return
	if not on:return
	if action.begins_with("slot"):game.command("slot",{"slot":int(action.trim_prefix("slot"))});return
	match action:
		"fire":
			if is_instance_valid(game.kill_replay) and game.kill_replay.active:game.kill_replay.finish();return
			if not game.players[game.local_id].alive:game.cycle_spectator();return
			game.trigger_seq+=1;game.actors[game.local_id].input_state.trigger_seq=game.trigger_seq
		"reload","skill","slide":game.command(action,{})
		"gear":game.ui.gear()
		"mode":game.command("gadget_mode",{})
		"menu":game.ui.toggle_pause()
		"sprint":
			var stamp=Time.get_ticks_msec()
			if stamp-last_run_tap<300:game.command("slide",{})
			last_run_tap=stamp
func _input(event):
	if not active():return
	var inverse=get_global_transform_with_canvas().affine_inverse()
	if event is InputEventScreenTouch:
		var p=inverse*event.position
		if event.pressed:
			positions[event.index]=p;input_transform=inverse
			for action in buttons:
				if buttons[action].has_point(p):fingers[event.index]=action;press(action,true);get_viewport().set_input_as_handled();return
			if p.x<380 and p.y>180 and stick_id<0:
				stick_id=event.index;stick_center=Vector2(clampf(p.x,95,290),clampf(p.y,220,590));stick_point=p;movement=(p-stick_center).limit_length(90)/90.
			elif look_id<0:look_id=event.index
		else:
			positions.erase(event.index)
			if fingers.has(event.index):
				var action=fingers[event.index];fingers.erase(event.index)
				if action not in fingers.values():press(action,false)
			if event.index==stick_id:stick_id=-1;movement=Vector2.ZERO
			if event.index==look_id:look_id=-1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var point=inverse*event.position
		# Web multitouch relative vectors may refer to another finger (Godot #94346).
		# Track each contact independently; rebase after orientation/layout changes.
		var delta=point-positions.get(event.index,point)
		positions[event.index]=point
		if inverse!=input_transform:
			input_transform=inverse;positions.clear();positions[event.index]=point;delta=Vector2.ZERO
		if not delta.is_finite() or delta.length()>240.:delta=Vector2.ZERO
		if event.index==stick_id:
			stick_point=inverse*event.position;movement=(stick_point-stick_center).limit_length(90)/90.
		elif event.index==look_id or fingers.get(event.index,"")=="fire":
			var actor=game.actors.get(game.local_id)
			if actor:
				var sensitivity=float(game.profile.get("touch_sensitivity",.0028))*(.65 if held.get("ads",false) else 1.)
				if game.players[game.local_id].alive:actor.input_state.yaw-=delta.x*sensitivity;actor.input_state.pitch=clampf(actor.input_state.pitch-delta.y*sensitivity,-1.45,1.45)
				else:game.spectator_yaw-=delta.x*sensitivity;game.spectator_pitch=clampf(game.spectator_pitch-delta.y*sensitivity,-1.2,1.2)
		get_viewport().set_input_as_handled()
func apply_input(actor:Actor,on:bool):
	actor.input_state.x=movement.x if on else 0.;actor.input_state.z=movement.y if on else 0.
	for key in ["crouch","jump","use","ads","fire"]:actor.input_state[key]=on and held.get(key,false)
	actor.input_state.sprint=on and (held.get("sprint",false) or movement.length()>.94)
	actor.input_state.alt=on and held.get("medical",false)
func _draw():
	if not visible:return
	var font=game.ui.theme.default_font
	var labels={"fire":"발사","reload":"재장전","ads":"조준","jump":"점프","crouch":"앉기","sprint":"달리기","slide":"슬라이딩","skill":"스킬","gadget":"가젯","use":"상호작용","medical":"보조 발사","gear":"병과 / 장비","mode":"설치 모드","menu":"메뉴","score":"기록"}
	var p=game.players.get(game.local_id,{})
	labels.use=BombLogic.use_label(game,game.local_id)
	for action in buttons:
		var rect:Rect2=buttons[action];var color=Color(.04,.075,.10,.40) if not held.get(action,false) else Color(.18,.48,.54,.75)
		if action=="fire":draw_circle(rect.get_center(),rect.size.x*.5,color);draw_arc(rect.get_center(),rect.size.x*.5,0,TAU,48,Color(.86,.96,1,.6),2.,true)
		else:draw_style_box(plate(color),rect)
		var title=labels.get(action,"");var font_size=26
		if action.begins_with("slot"):
			var index=int(action.trim_prefix("slot"));var id=p.get("primary","") if index==0 else p.get("secondary","") if index==1 else ""
			title=game.ui.slots[index].text if index<game.ui.slots.size() else "장비"
			font_size=clampi(int((rect.size.x-10)/maxf(1.,font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x)*26),17,26)
			if int(p.get("slot",0))==index:draw_rect(rect,Color("65dfc1"),false,3.)
		if action=="skill":
			var state=AbilityBalance.skill_state(game,game.local_id);var remain=state.remaining
			title="%d초"%ceili(remain) if remain>0 else state.label;font_size=22
			var fraction=1.-clampf(remain/state.duration,0.,1.) if state.enabled else 0.
			draw_line(rect.position+Vector2(8,rect.size.y-5),rect.position+Vector2(8+(rect.size.x-16)*fraction,rect.size.y-5),Color("6cdfc3"),3.)
		if action=="gadget":title="가젯 ×"+str(p.get("gadget_count",0));font_size=22
		if action=="fire" and not p.get("alive",false):title="다음 관전";font_size=22
		if action=="fire" and is_instance_valid(game.kill_replay) and game.kill_replay.active:title="건너뛰기";font_size=22
		draw_string(font,rect.position+Vector2(5,rect.size.y*.5+9),title,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-10,font_size,Color("eefaff"))
	var center=stick_center if stick_id>=0 else Vector2(165,530)
	draw_circle(center,90,Color(.06,.11,.15,.27));draw_arc(center,90,0,TAU,48,Color(.8,.94,1,.5),2.,true)
	draw_circle(center+movement*64,35,Color(.7,.9,.96,.55))
	if stick_id<0:draw_string(font,center+Vector2(-50,117),"이동 / 달리기",HORIZONTAL_ALIGNMENT_CENTER,100,22,Color("d2e6e8"))
func plate(color:Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=Color(.8,.92,1,.5);style.set_border_width_all(1);style.set_corner_radius_all(14);return style
