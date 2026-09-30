class_name GraphicsOptions
extends RefCounted

static var detail=1
static var shadows=1
static var antialias=1
static var lighting=1
static var physics_effects=1
static var corpse_quality=1
static var blood_enabled=false
static var fog=false
const PRESETS=[
	{"antialias":0,"shadow_quality":0,"decor_quality":0,"lighting_quality":0,"physics_effects":0,"corpse_quality":0,"fog_enabled":false},
	{"antialias":0,"shadow_quality":0,"decor_quality":1,"lighting_quality":1,"physics_effects":1,"corpse_quality":1,"fog_enabled":true},
	{"antialias":2,"shadow_quality":1,"decor_quality":2,"lighting_quality":2,"physics_effects":2,"corpse_quality":2,"fog_enabled":true}]

static func apply(game:Node,automatic:bool=false):
	var settings=WebGraphics.resolve(game.profile,game.web_graphics.level if is_instance_valid(game.web_graphics) else 1) if OS.has_feature("web") else game.profile
	if not OS.has_feature("web") and game.profile.get("graphics_auto",false):
		settings=game.profile.duplicate()
		var auto_level=game.native_graphics.level if is_instance_valid(game.native_graphics) else 1
		settings.merge(PRESETS[auto_level],true)
	detail=clampi(int(settings.get("decor_quality",1)),0,2)
	lighting=clampi(int(settings.get("lighting_quality",1)),0,2)
	physics_effects=clampi(int(settings.get("physics_effects",1)),0,2)
	corpse_quality=0 if OS.has_feature("web") else clampi(int(settings.get("corpse_quality",1)),0,2)
	shadows=clampi(int(settings.get("shadow_quality",0)),0,2)
	antialias=clampi(int(settings.get("antialias",0)),0,3)
	fog=bool(settings.get("fog_enabled",false))
	if lighting==0:shadows=0
	ToonMaterials.configure(lighting>0)
	RenderingServer.global_shader_parameter_set("material_detail_enabled",detail>0 and lighting>0)
	blood_enabled=bool(game.profile.get("blood_effects",false)) and not OS.has_feature("web")
	if not blood_enabled and is_instance_valid(game.combat_fx) and is_instance_valid(game.combat_fx.blood):
		game.combat_fx.blood.queue_free();game.combat_fx.blood=null
	if DisplayServer.get_name()=="headless":return
	Engine.max_fps=int(game.profile.get("frame_limit",60))
	# GLES directional atlases require a positive size. Disable casting on the
	# lights themselves; keep a tiny valid atlas when shadows are off.
	RenderingServer.directional_shadow_atlas_set_size(([256,2048,4096] if OS.has_feature("web") else [256,4096,4096])[shadows],shadows>0)
	apply_viewport(game.get_viewport());apply_world(game,automatic)
	for viewport in game.find_children("*","SubViewport",true,false):apply_viewport(viewport)

static func apply_viewport(viewport:Viewport):
	viewport.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X][antialias]
	# Pixel error for distance LOD; output resolution and all collision stay intact.
	viewport.mesh_lod_threshold=[2.5,1.5,1.0][detail]
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
		var preset=ui.option("품질 프리셋",["낮음 · 저사양","중간 · 기본","높음 · 세부 표현","사용자 설정","자동 · 성능에 맞춤"],4 if profile.get("graphics_auto",false) else int(profile.get("graphics_quality",1)),func(i):
			profile.graphics_auto=i==4
			if i==4:
				if is_instance_valid(ui.game.native_graphics):ui.game.native_graphics.reset()
				return
			if i==3:return
			profile.graphics_quality=i;profile.merge(PRESETS[i],true)
			for item in controls:
				if item.control is CheckBox:item.control.set_pressed_no_signal(bool(profile[item.key]))
				else:item.control.select(int(profile[item.key])))
		for spec in [["lighting_quality","광원",["고정 카툰 명암","주 광원 1개","주 광원 + 보조 4개"]],["shadow_quality","그림자",["사용 안 함","가까운 고해상도 그림자","넓은 고해상도 그림자"]],["antialias","안티앨리어싱",["사용 안 함","MSAA 2×","MSAA 4×","MSAA 8×"]],["decor_quality","장식 효과",["최소","중간","풍부하게"]],["physics_effects","장식 물리",["최소","기본","풍부하게"]],["corpse_quality","피격·사망 물리",["가벼운 낙하·눕기","관절 시체 · 최대 2명","관절 시체 · 최대 4명"]]]:
			var key:String=spec[0]
			var control=ui.option(spec[1],spec[2],int(profile[key]),func(i):profile[key]=i;profile.graphics_auto=false;profile.graphics_quality=3;preset.select(3))
			controls.append({"key":key,"control":control})
		var fog_control=ui.check("배경 안개",bool(profile.fog_enabled),func(on):profile.fog_enabled=on;profile.graphics_auto=false;profile.graphics_quality=3;preset.select(3))
		controls.append({"key":"fog_enabled","control":fog_control})
		ui.label("시체 물리는 피격 방향과 바닥 충돌을 반영합니다. 작은 통·상자·콘은 모든 품질에서 밀거나 쏴서 움직일 수 있으며, 멀티플레이에서는 방장이 동일하게 판정합니다.",17)
		ui.check("유혈 효과",bool(profile.get("blood_effects",false)),func(on):profile.blood_effects=on)
		ui.check("메뉴 배경 전투 · 다음 메인 화면부터",bool(profile.get("menu_animation",true)),func(on):profile.menu_animation=on)
		ui.option("최대 프레임",["제한 없음","30 FPS","60 FPS","90 FPS","120 FPS","144 FPS"],maxi(0,[0,30,60,90,120,144].find(int(profile.frame_limit))),func(i):profile.frame_limit=[0,30,60,90,120,144][i])
		ui.label("중간 기본값: 기본 재질, 주 광원 1개, 그림자·MSAA 끄기, 제한된 장식 물리. 이동·충돌·총격 판정과 게임 규칙은 품질 설정과 무관합니다. 광원을 끄면 그림자도 꺼집니다.",17)
		ui.label("자동이 기본입니다. 해상도를 유지하며 낮음부터 높음까지 재질·노말맵·조명·그림자·효과를 조절합니다.",17)
	if not OS.has_feature("web"):
		ui.button("기본설정으로 복원",func():
			profile.graphics_auto=true;profile.graphics_quality=1;profile.merge(PRESETS[1],true);profile.frame_limit=60;profile.menu_animation=true
			profile.monitor=DisplayServer.window_get_current_screen();var size=DisplayServer.screen_get_size(int(profile.monitor))
			profile.width=size.x;profile.height=size.y;profile.display_mode=1;profile.window=false
			ui.game.apply_display_settings();apply(ui.game);ui.game.save_profile();ui.settings())
	ui.label("연막의 전술적 범위·밀도·지속 시간과 폭발·회복·스킬 표시는 유지됩니다.",17)
	ui.button("그래픽 설정 적용",func():
		apply(ui.game);ui.game.save_profile()
		var applied=SettingsGuard.snapshot(ui.game.profile)
		for key in ["monitor","display_mode","width","height","window"]:applied.erase(key)
		ui.settings_baseline.merge(applied,true);ui.notice("그래픽 설정을 적용했습니다."))

static func apply_world(root:Node,automatic:bool=false):
	if not automatic:WebMaterials.apply(root)
	# SceneTree groups automatically remove freed nodes. Automatic changes visit
	# only registered quality targets, not every node/mesh in the entire match.
	if not automatic:
		for mesh in root.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override is ShaderMaterial and "district_surface" in mesh.material_override.shader.code:
				mesh.material_override.shader=WorldSurface.material("wall",0).shader
			if mesh.has_meta("district_detail") or (mesh.material_override is ShaderMaterial and "district_surface" in mesh.material_override.shader.code):mesh.add_to_group("quality_mesh")
		for light in root.find_children("*","Light3D",true,false):light.add_to_group("quality_light")
		for world in root.find_children("*","WorldEnvironment",true,false):world.add_to_group("quality_environment")
	# Native retains the original material response; only expensive micro-detail is optional.
	if not RenderStyle.web() and not automatic:
		for mesh in root.find_children("*","MeshInstance3D",true,false):
			var materials=[mesh.material_override] if mesh.material_override else []
			if mesh.mesh and not mesh.material_override:
				for i in range(mesh.mesh.get_surface_count()):materials.append(mesh.get_active_material(i))
			for material in materials:
				if material is ShaderMaterial and "rich_detail" in material.shader.code:material.set_shader_parameter("rich_detail",detail==2)
				if material is ShaderMaterial and "texture_detail" in material.shader.code:material.set_shader_parameter("texture_detail",detail>0)
	for mesh in root.get_tree().get_nodes_in_group("quality_mesh"):
		if mesh.material_override is ShaderMaterial and "district_surface" in mesh.material_override.shader.code:
			mesh.material_override.set_shader_parameter("dynamic_lighting",lighting>0)
			# Relief maps cost one sample: always on natively, Web minimum drops them.
			mesh.material_override.set_shader_parameter("texture_detail",relief())
		if mesh.has_meta("district_detail"):
			mesh.visible=true;mesh.visibility_range_end=([28.,65.,100.] if RenderStyle.web() else [28.,65.,100.])[detail];mesh.visibility_range_end_margin=5.
	var points=0;var pooled=true
	for light in root.get_tree().get_nodes_in_group("quality_light"):
		if light.has_meta("pooled_practical"):continue
		if not light.has_meta("quality_shadow"):light.set_meta("quality_shadow",light.shadow_enabled)
		if light is OmniLight3D or light is SpotLight3D:
			light.visible=lighting==2 and points<4 and not pooled;light.shadow_enabled=false;points+=1
		elif light is DirectionalLight3D:
			# A map's indoor flag must not permanently disable the user's sun
			# shadows: rebuilt districts may contain both courtyards and rooms.
			light.visible=lighting>0;light.shadow_enabled=lighting>0 and shadows>0 and (light.name=="Sun" or bool(light.get_meta("quality_shadow")))
			light.directional_shadow_max_distance=25. if shadows==1 else 55.
			light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.shadow_bias=.25;light.shadow_normal_bias=1.2;light.shadow_blur=2.
			light.directional_shadow_blend_splits=true
			if not light.has_meta("unshadowed_energy"):light.set_meta("unshadowed_energy",light.light_energy)
			var base=float(light.get_meta("unshadowed_energy"))
			# Compatibility shadows use a different lighting pass. Keep sunlit
			# plaster below clipping instead of washing out its texture relief.
			light.light_energy=base*(.72 if light.shadow_enabled and base>.8 else 1.)
	for world in root.get_tree().get_nodes_in_group("quality_environment"):
		if world.environment:
			world.environment.tonemap_exposure=1.0
			if not world.has_meta("quality_fog"):world.set_meta("quality_fog",world.environment.fog_enabled)
			world.environment.fog_enabled=fog and bool(world.get_meta("quality_fog"))
			if RenderStyle.web():world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
			world.environment.ambient_light_energy=maxf(world.environment.ambient_light_energy,.65 if RenderStyle.web() else .55)

static func relief() -> bool:return detail>0 or not OS.has_feature("web")
static func physical_pose_limit() -> int:return 1 if physics_effects==2 and not OS.has_feature("web") else 0

