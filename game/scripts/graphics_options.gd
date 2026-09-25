class_name GraphicsOptions
extends RefCounted

static var detail=1
static var shadows=0
static var antialias=0
static var lighting=1
static var physics_effects=1
static var blood_enabled=false
static var fog=false
const PRESETS=[
	{"antialias":0,"shadow_quality":0,"decor_quality":0,"lighting_quality":0,"physics_effects":0,"fog_enabled":false},
	{"antialias":0,"shadow_quality":0,"decor_quality":1,"lighting_quality":1,"physics_effects":1,"fog_enabled":false},
	{"antialias":2,"shadow_quality":1,"decor_quality":2,"lighting_quality":2,"physics_effects":2,"fog_enabled":true}]

static func apply(game:Node):
	var settings=WebGraphics.resolve(game.profile,game.web_graphics.level if is_instance_valid(game.web_graphics) else 1) if OS.has_feature("web") else game.profile
	detail=clampi(int(settings.get("decor_quality",1)),0,2)
	lighting=clampi(int(settings.get("lighting_quality",1)),0,2)
	physics_effects=clampi(int(settings.get("physics_effects",1)),0,2)
	shadows=clampi(int(settings.get("shadow_quality",0)),0,2)
	antialias=clampi(int(settings.get("antialias",0)),0,3)
	fog=bool(settings.get("fog_enabled",false))
	if lighting==0:shadows=0
	ToonMaterials.configure(lighting>0)
	blood_enabled=bool(game.profile.get("blood_effects",false)) and not OS.has_feature("web")
	if not blood_enabled and is_instance_valid(game.combat_fx) and is_instance_valid(game.combat_fx.blood):
		game.combat_fx.blood.queue_free();game.combat_fx.blood=null
	if DisplayServer.get_name()=="headless":return
	Engine.max_fps=int(game.profile.get("frame_limit",60))
	# GLES directional atlases require a positive size. Disable casting on the
	# lights themselves; keep a tiny valid atlas when shadows are off.
	RenderingServer.directional_shadow_atlas_set_size([256,1024,2048][shadows],true)
	apply_viewport(game.get_viewport());apply_world(game)
	for viewport in game.find_children("*","SubViewport",true,false):apply_viewport(viewport)

static func apply_viewport(viewport:Viewport):
	viewport.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X][antialias]
	# Point lights never cast shadows; do not allocate an unused local atlas.
	viewport.positional_shadow_atlas_size=0

static func build(ui:Node):
	ui.label("그래픽 성능",24)
	ui.label("렌더러: "+RenderingServer.get_video_adapter_name()+" · "+RenderingServer.get_video_adapter_api_version(),14)
	var profile=ui.game.profile
	if OS.has_feature("web"):
		WebGraphics.build(ui);return
	else:
		var controls=[]
		var preset=ui.option("품질 프리셋",["낮음 · 저사양","중간 · 기본","높음 · 세부 표현","사용자 설정"],int(profile.get("graphics_quality",1)),func(i):
			if i==3:return
			profile.graphics_quality=i;profile.merge(PRESETS[i],true)
			for item in controls:
				if item.control is CheckBox:item.control.set_pressed_no_signal(bool(profile[item.key]))
				else:item.control.select(int(profile[item.key])))
		for spec in [["lighting_quality","광원",["고정 카툰 명암","주 광원 1개","주 광원 + 보조 4개"]],["shadow_quality","그림자",["사용 안 함","1024 · 가까운 그림자","2048 · 먼 그림자"]],["antialias","안티앨리어싱",["사용 안 함","MSAA 2×","MSAA 4×","MSAA 8×"]],["decor_quality","장식 효과",["최소","중간","풍부하게"]],["physics_effects","장식 물리",["최소","기본","관절 효과 · 최대 2개"]]]:
			var key:String=spec[0]
			var control=ui.option(spec[1],spec[2],int(profile[key]),func(i):profile[key]=i;profile.graphics_quality=3;preset.select(3))
			controls.append({"key":key,"control":control})
		var fog_control=ui.check("배경 안개",bool(profile.fog_enabled),func(on):profile.fog_enabled=on;profile.graphics_quality=3;preset.select(3))
		controls.append({"key":"fog_enabled","control":fog_control})
		ui.check("유혈 효과",bool(profile.get("blood_effects",false)),func(on):profile.blood_effects=on)
		ui.check("메뉴 배경 전투 · 다음 메인 화면부터",bool(profile.get("menu_animation",false)),func(on):profile.menu_animation=on)
		ui.option("최대 프레임",["제한 없음","30 FPS","60 FPS","90 FPS","120 FPS","144 FPS"],maxi(0,[0,30,60,90,120,144].find(int(profile.frame_limit))),func(i):profile.frame_limit=[0,30,60,90,120,144][i])
		ui.label("중간 기본값: 주 광원 1개, 그림자 끄기, 기본 물리. 이동·충돌·총격 판정과 게임 규칙은 품질 설정과 무관합니다. 광원을 끄면 그림자도 꺼집니다.",17)
	ui.label("연막의 전술적 범위·밀도·지속 시간과 폭발·회복·스킬 표시는 유지됩니다.",17)
	ui.button("그래픽 설정 적용",func():apply(ui.game);ui.game.save_profile();ui.notice("그래픽 설정을 적용했습니다."))

static func apply_world(root:Node):
	WebMaterials.apply(root)
	var points=0
	for light in root.find_children("*","Light3D",true,false):
		if not light.has_meta("quality_shadow"):light.set_meta("quality_shadow",light.shadow_enabled)
		if light is OmniLight3D or light is SpotLight3D:
			light.visible=lighting==2 and points<4;light.shadow_enabled=false;points+=1
		elif light is DirectionalLight3D:
			light.visible=lighting>0;light.shadow_enabled=lighting>0 and shadows>0 and bool(light.get_meta("quality_shadow"))
			light.directional_shadow_max_distance=35. if shadows==1 else 65.
			light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	for world in root.find_children("*","WorldEnvironment",true,false):
		if world.environment:
			if not world.has_meta("quality_fog"):world.set_meta("quality_fog",world.environment.fog_enabled)
			world.environment.fog_enabled=fog and bool(world.get_meta("quality_fog"))
			world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
			world.environment.ambient_light_energy=.5

static func physical_pose_limit() -> int:return 1 if physics_effects==2 and not OS.has_feature("web") else 0
