class_name GraphicsOptions
extends RefCounted

static var detail=2
static var shadows=2
static var antialias=1
static var blood_enabled=false

static func apply(game:Node):
	detail=clampi(int(game.profile.get("decor_quality",2)),0,2)
	shadows=clampi(int(game.profile.get("shadow_quality",2)),0,2)
	antialias=clampi(int(game.profile.get("antialias",2)),0,3)
	blood_enabled=bool(game.profile.get("blood_effects",false))
	if not blood_enabled and is_instance_valid(game.combat_fx) and is_instance_valid(game.combat_fx.blood):
		game.combat_fx.blood.queue_free();game.combat_fx.blood=null
	if DisplayServer.get_name()=="headless":return
	Engine.max_fps=int(game.profile.get("frame_limit",0))
	RenderingServer.directional_shadow_atlas_set_size([1024,2048,4096][shadows],true)
	apply_viewport(game.get_viewport())
	for viewport in game.find_children("*","SubViewport",true,false):apply_viewport(viewport)

static func apply_viewport(viewport:Viewport):
	viewport.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X][antialias]
	viewport.positional_shadow_atlas_size=[1024,2048,4096][shadows]

static func build(ui:Node):
	ui.label("그래픽 성능",24)
	var profile=ui.game.profile
	ui.check("유혈 효과 · 기본 꺼짐",bool(profile.get("blood_effects",false)),func(on):profile.blood_effects=on;apply(ui.game);ui.game.save_profile())
	var controls=[]
	var preset=ui.option("품질 프리셋",["낮음 · 저사양","중간 · 균형","높음 · 세부 표현","사용자 설정"],int(profile.get("graphics_quality",2)),func(i):
		if i==3:return
		for control in controls:control.select(i)
		profile.graphics_quality=i;profile.antialias=i;profile.shadow_quality=i;profile.decor_quality=i)
	controls.append(ui.option("안티앨리어싱",["사용 안 함","MSAA 2×","MSAA 4×","MSAA 8×"],int(profile.antialias),func(i):profile.antialias=i;profile.graphics_quality=3;preset.select(3)))
	controls.append(ui.option("그림자 선명도",["낮음","중간","높음"],int(profile.shadow_quality),func(i):profile.shadow_quality=i;profile.graphics_quality=3;preset.select(3)))
	controls.append(ui.option("장식 효과",["간소화","균형","풍부하게"],int(profile.decor_quality),func(i):profile.decor_quality=i;profile.graphics_quality=3;preset.select(3)))
	ui.option("최대 프레임",["제한 없음","30 FPS","60 FPS","90 FPS","120 FPS","144 FPS"],maxi(0,[0,30,60,90,120,144].find(int(profile.frame_limit))),func(i):profile.frame_limit=[0,30,60,90,120,144][i])
	ui.label("장식 효과는 탄피·작은 폭발 파편 수와 메뉴 배경의 표시 빈도를 조절합니다.\n연막의 범위·밀도·지속 시간, 폭발·섬광·회복·스킬 표시는 모든 품질에서 유지됩니다.",17)
	ui.button("그래픽 설정 적용",func():apply(ui.game);ui.game.save_profile();ui.notice("그래픽 설정을 적용했습니다."))
	ui.label("더 가볍게 실행하려면 화면 탭에서 게임 해상도도 낮춰 보세요.",17)
	ui.label("멀리 있는 가장자리가 거칠면 모니터 원본 해상도와 MSAA 4× 또는 8×를 사용하세요. 표면 텍스처에는 밉맵과 비등방성 필터가 적용됩니다.",17)
