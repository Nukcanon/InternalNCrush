class_name WebGraphics
extends Node
## Render-only policy. Never changes geometry, game rules, bot count or replay.
const WINDOW_SECONDS=3.
const AUTO_MIN_SCALE=.85
const PRESETS=[
	{"lighting_quality":0,"shadow_quality":0,"antialias":0,"decor_quality":0,"fog_enabled":false},
	{"lighting_quality":0,"shadow_quality":0,"antialias":0,"decor_quality":1,"fog_enabled":false},
	{"lighting_quality":1,"shadow_quality":0,"antialias":1,"decor_quality":2,"fog_enabled":false}]
const NAMES=["낮음","중간","높음"]
signal changed(description:String)
var game:Node
var level=1
var scale_3d=1.
var slow_windows=0
var fast_windows=0
var hold_windows=0
var elapsed=0.
var frames=0
var warmup=8.
var context=""

static func quality(profile:Dictionary) -> int:return clampi(int(profile.get("web_quality",-1)),-1,3)
static func resolve(profile:Dictionary,auto_level:int=1) -> Dictionary:
	var mode=quality(profile)
	var settings=PRESETS[clampi(auto_level if mode<0 else 1 if mode==3 else mode,0,2)].duplicate()
	if mode==3:settings.merge(profile.get("web_options",{}),true)
	settings.lighting_quality=clampi(int(settings.lighting_quality),0,1)
	settings.shadow_quality=clampi(int(settings.shadow_quality),0,1)
	settings.antialias=clampi(int(settings.antialias),0,2)
	settings.decor_quality=clampi(int(settings.decor_quality),0,2)
	# Automatic adjustments must not allocate MSAA/shadow buffers or switch lighting
	# while the player is fighting. Manual high/custom still enables those features.
	if mode<0:settings.lighting_quality=0;settings.shadow_quality=0;settings.antialias=0
	settings.physics_effects=0
	return settings
static func render_scale(profile:Dictionary,auto_scale:float=1.) -> float:
	return clampf(auto_scale,AUTO_MIN_SCALE,1.) if quality(profile)<0 else clampf(float(profile.get("web_render_scale",1.)),.7,1.)
func reset_samples():
	elapsed=0.;frames=0;warmup=8.;slow_windows=0;fast_windows=0;hold_windows=0
func reset_auto():
	level=1;scale_3d=1.;reset_samples()
func describe() -> String:
	var mode=quality(game.profile)
	var name="자동 · "+NAMES[level] if mode<0 else NAMES[mode] if mode<3 else "사용자 설정"
	return "%s · 3D 선명도 %d%%"%[name,roundi(render_scale(game.profile,scale_3d)*100.)]
func observe(fps:float,target:float) -> bool:
	if not is_finite(fps) or fps<=0. or target<=0.:return false
	if hold_windows>0:
		hold_windows-=1;slow_windows=0;fast_windows=0;return false
	slow_windows=slow_windows+1 if fps<target*.82 else 0
	fast_windows=fast_windows+1 if fps>=target*.97 else 0
	var before=Vector2(level,scale_3d)
	if slow_windows>=2:
		# Remove effects before touching resolution. Never degrade the base mesh.
		if level>0:level-=1
		elif scale_3d>AUTO_MIN_SCALE:scale_3d=AUTO_MIN_SCALE
	elif fast_windows>=5:
		# Recover sharpness before adding optional effects.
		if scale_3d<1.:scale_3d=1.
		elif level<2:level+=1
	if before==Vector2(level,scale_3d):return false
	hold_windows=6;slow_windows=0;fast_windows=0;return true
func _process(dt:float):
	if not is_instance_valid(game) or quality(game.profile)>=0:return
	var next_context=str([game.options.map,game.phase])
	if context!=next_context:context=next_context;reset_samples()
	# Loading, menus, replay and a background tab are not valid combat samples.
	if game.phase!="combat" or not is_instance_valid(game.ui) or is_instance_valid(game.ui.panel) or not get_window().has_focus() or (is_instance_valid(game.kill_replay) and game.kill_replay.active):
		elapsed=0.;frames=0;warmup=maxf(warmup,2.);return
	if not is_finite(dt) or dt<=0.:return
	if dt>1.:elapsed=0.;frames=0;warmup=maxf(warmup,2.);return
	if warmup>0.:warmup-=dt;return
	elapsed+=dt;frames+=1
	if elapsed<WINDOW_SECONDS:return
	var fps=frames/elapsed;elapsed=0.;frames=0
	var cap=int(game.profile.get("frame_limit",60));var target=float(mini(cap,60) if cap>0 else 60)
	if observe(fps,target):
		GraphicsOptions.apply(game);game.apply_display_settings();changed.emit(describe())
static func apply_settings(game:Node):
	GraphicsOptions.apply(game);game.apply_display_settings();game.save_profile()
	if is_instance_valid(game.web_graphics):
		game.web_graphics.reset_samples();game.web_graphics.changed.emit(game.web_graphics.describe())
static func build(ui:Node):
	var profile=ui.game.profile
	var controls=[]
	var refresh_controls=func():
		var settings=resolve(profile,ui.game.web_graphics.level if is_instance_valid(ui.game.web_graphics) else 1)
		for item in controls:
			if item.key=="web_render_scale":item.control.select(maxi(0,[1.,.85,.7].find(render_scale(profile,ui.game.web_graphics.scale_3d if is_instance_valid(ui.game.web_graphics) else 1.))))
			elif item.control is CheckBox:item.control.set_pressed_no_signal(bool(settings[item.key]))
			else:item.control.select(int(settings[item.key]))
			if item.key=="shadow_quality":item.control.disabled=int(settings.lighting_quality)==0
	var status=ui.label(ui.game.web_graphics.describe() if is_instance_valid(ui.game.web_graphics) else "자동 · 중간",18)
	if is_instance_valid(ui.game.web_graphics):ui.game.web_graphics.changed.connect(status.set_text)
	var preset=ui.option("품질 프리셋",["자동 · 기본","낮음 · 저사양","중간 · 균형","높음 · 선명하게","사용자 설정"],quality(profile)+1,func(i):
		profile.web_quality=i-1
		if i>0 and i<4:
			profile.web_options=PRESETS[i-1].duplicate();profile.web_render_scale=.85 if i==1 else 1.
		elif i==0 and is_instance_valid(ui.game.web_graphics):ui.game.web_graphics.reset_auto()
		elif i==4:
			profile.web_options={}
			for item in controls:
				if item.key=="web_render_scale":profile.web_render_scale=[1.,.85,.7][item.control.selected]
				else:profile.web_options[item.key]=item.control.button_pressed if item.control is CheckBox else item.control.selected
		refresh_controls.call();apply_settings(ui.game))
	var make_custom=func():
		if quality(profile)!=3:
			profile.web_options=resolve(profile,ui.game.web_graphics.level if is_instance_valid(ui.game.web_graphics) else 1)
			profile.web_render_scale=render_scale(profile,ui.game.web_graphics.scale_3d if is_instance_valid(ui.game.web_graphics) else 1.)
		profile.web_quality=3;preset.select(4)
	var initial=resolve(profile,ui.game.web_graphics.level if is_instance_valid(ui.game.web_graphics) else 1)
	for spec in [["lighting_quality","광원",["고정 카툰 명암","주 광원 1개"]],["shadow_quality","그림자",["사용 안 함","1024 · 가까운 그림자"]],["antialias","안티앨리어싱",["사용 안 함","MSAA 2×","MSAA 4×"]],["decor_quality","장식 효과",["최소","중간","풍부하게"]]]:
		var key:String=spec[0]
		var control=ui.option(spec[1],spec[2],int(initial[key]),func(i):make_custom.call();profile.web_options[key]=i;refresh_controls.call();apply_settings(ui.game))
		controls.append({"key":key,"control":control})
	var fog_control=ui.check("배경 안개",bool(initial.fog_enabled),func(on):make_custom.call();profile.web_options.fog_enabled=on;refresh_controls.call();apply_settings(ui.game))
	controls.append({"key":"fog_enabled","control":fog_control})
	var resolution=ui.option("3D 선명도",["100% · 원본","85% · 균형","70% · 직접 선택"],maxi(0,[1.,.85,.7].find(render_scale(profile,ui.game.web_graphics.scale_3d if is_instance_valid(ui.game.web_graphics) else 1.))),func(i):make_custom.call();profile.web_render_scale=[1.,.85,.7][i];apply_settings(ui.game))
	controls.append({"key":"web_render_scale","control":resolution})
	refresh_controls.call()
	ui.option("최대 프레임",["제한 없음","30 FPS","60 FPS","90 FPS","120 FPS"],maxi(0,[0,30,60,90,120].find(int(profile.frame_limit))),func(i):profile.frame_limit=[0,30,60,90,120][i];apply_settings(ui.game))
	ui.label("자동은 전투 중 성능을 확인해 효과를 먼저 조절합니다. 선명도는 85% 아래로 내리지 않으며, 여유가 생기면 복원합니다. 항목을 직접 바꾸면 사용자 설정으로 전환합니다. 광원을 끄면 그림자도 꺼집니다.",17)
	ui.label("모든 품질에서 가까운 캐릭터·무기·지형의 기본 형태와 카툰 색상을 유지합니다. 연습장·봇·킬 리플레이·5개 모드와 연막의 전술적 효과는 동일합니다.",17)
	ui.button("기본설정으로 복원",func():profile.web_render_scale=1.;profile.web_options={};profile.frame_limit=60;preset.select(0);preset.item_selected.emit(0))

