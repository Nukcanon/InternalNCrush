extends CanvasLayer
const Reticle=preload("res://scripts/reticle.gd")
var map_refresh=Callable()
var reticle:Control
var background:Control
var version_box:VBoxContainer
var vote_panel:PanelContainer
var vote_text:Label
var vote_yes:Button
var vote_no:Button
var member_signature=""
var slots=[]
var slot_panels=[]
var weapon_title:Label
var skill_label:Label
var health_bar:ColorRect
var armor_bar:ColorRect
var gear_detail:Label
var gear_price:Label
var gear_submit:Button
var game:Node
var root:Control
var panel:PanelContainer
var panel_body:VBoxContainer
var panel_scroll:ScrollContainer
var stack:VBoxContainer
var hud:Control
var status:Label
var stats:Label
var health:Label
var ammo:Label
var banner:Label
var crosshair:Label
var info:Label
var score:Label
var score2:Label
var flash_overlay:ColorRect
var roster:Label
var notice_label:Label
var notice_until=0
var hit_until=0
var room_list:VBoxContainer
var gear_primary:OptionButton
var gear_class:OptionButton
var gear_armor:OptionButton
var gear_gadget:OptionButton
var gear_repair:CheckBox
var weapon_ids=[]
var theme:Theme
var perf_clock=0.0
var screen=""
var preview_widget:EquipmentPreview
var preview_kind=0
var preview_secondary=false
var preview_caption:Label
var stat_graph:StatGraph
var role_detail:Label
var role_cards:GridContainer
var gear_cards:GridContainer
var gear_category=0
var gear_tabs:GridContainer
var team_columns:HBoxContainer
var team_signature=""
var scoreboard:MatchScoreboard
var kill_feed:KillFeed
var damage_indicator:DamageIndicator
var interaction_hint:Label
var lan_lobby:LanLobby
var navigation_confirm:ConfirmationDialog
var hud_blue:Label
var hud_orange:Label
var operator_name:Label
var internet_filter=RoomFilters.defaults()
var internet_rooms=[]
const MENU_SCALE=.88
var ACTION_HEIGHT=84 if TouchControls.supported() else 40
func _ready():
	lan_lobby=LanLobby.new(self)
	root=Control.new();root.size=Vector2(1280,720);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	get_viewport().size_changed.connect(scale_interface);scale_interface()
	damage_indicator=DamageIndicator.new();damage_indicator.game=game;root.add_child(damage_indicator)
	theme=Theme.new();theme.default_font_size=28 if TouchControls.supported() else 20
	if ResourceLoader.exists("res://assets/fonts/Rajdhani-SemiBold.ttf"):
		var font=FontVariation.new();font.base_font=load("res://assets/fonts/Rajdhani-SemiBold.ttf");font.fallbacks=[load("res://assets/fonts/DoHyeon-Regular.ttf"),load("res://assets/Korean.ttf")];theme.default_font=font
		for source_font in [font.base_font]+font.fallbacks:
			source_font.multichannel_signed_distance_field=true;source_font.msdf_size=96
	var style=StyleBoxFlat.new();style.bg_color=Color(.055,.09,.13,.86);style.border_color=Color("4c5f72");style.set_border_width_all(1);style.set_corner_radius_all(4);style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=12;style.content_margin_bottom=12
	theme.set_stylebox("panel","PanelContainer",style)
	var btn=style.duplicate();btn.bg_color=Color("253344");btn.border_color=Color("536272");btn.border_width_left=3;theme.set_stylebox("normal","Button",btn)
	btn.content_margin_top=8;btn.content_margin_bottom=8
	var hov=btn.duplicate();hov.bg_color=Color("40566a");hov.border_color=Color("ffcc76");theme.set_stylebox("hover","Button",hov)
	var pressed=btn.duplicate();pressed.bg_color=Color("386479");pressed.border_color=Color("ffc66b");theme.set_stylebox("pressed","Button",pressed)
	for type in ["OptionButton","LineEdit","SpinBox"]:
		theme.set_stylebox("normal",type,btn);theme.set_stylebox("hover",type,hov);theme.set_stylebox("focus",type,pressed)
	var disabled=btn.duplicate();disabled.bg_color=Color("20313e");theme.set_stylebox("disabled","Button",disabled)
	theme.set_color("font_color","Label",Color("e8f2f3"));theme.set_color("font_color","Button",Color("e8f2f3"));root.theme=theme
	theme.set_color("font_outline_color","Label",Color(0.01,0.025,0.04,.65));theme.set_constant("outline_size","Label",1)
func clear_panel(keep_background=false):
	if is_instance_valid(hud):hud.show()
	if is_instance_valid(navigation_confirm):navigation_confirm.queue_free();navigation_confirm=null
	if lan_lobby:lan_lobby.close_dialog()
	if is_instance_valid(vote_panel):vote_panel.visible=false
	screen="";game.stop_room_search();team_signature=""
	if is_instance_valid(background) and not keep_background:background.queue_free();background=null
	if panel:panel.queue_free();panel=null
func make_panel(title:String,width=780):
	if TouchControls.supported():width=maxi(width,1000)
	clear_panel(game.phase=="menu");Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(hud):hud.hide()
	if is_instance_valid(background):
		for child in background.get_children():
			if child is Label or child==version_box:child.hide()
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=Vector2(-width*MENU_SCALE*.5,-280);panel.custom_minimum_size=Vector2(width,0);root.add_child(panel);panel.scale=Vector2.ONE*MENU_SCALE
	panel_body=VBoxContainer.new();panel_body.add_theme_constant_override("separation",14);panel.add_child(panel_body)
	var scroll=ScrollContainer.new();panel_scroll=scroll;scroll.custom_minimum_size=Vector2(width-40,560);panel_body.add_child(scroll)
	stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",12);scroll.add_child(stack)
	var eyebrow=Label.new();eyebrow.text="NUKCANON  /  INTERNAL N CRUSH";eyebrow.add_theme_color_override("font_color",Color("5ce1c3"));eyebrow.add_theme_font_size_override("font_size",14);stack.add_child(eyebrow)
	label(title,32)
func pin_actions(node:Control):
	node.set_meta("pinned_actions",true)
	node.get_parent().remove_child(node);panel_body.add_child(node)
	panel_scroll.custom_minimum_size.y=535
	if node is BoxContainer:
		node.alignment=BoxContainer.ALIGNMENT_END
		for child in node.get_children():
			if child is Button:child.custom_minimum_size=Vector2(160,ACTION_HEIGHT);child.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	elif node is Button:
		node.custom_minimum_size=Vector2(200,ACTION_HEIGHT);node.size_flags_horizontal=Control.SIZE_SHRINK_END
func label(text:String,size=20,parent:Node=null) -> Label:
	var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",maxi(26,size) if TouchControls.supported() else maxi(17,size));l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;(parent if parent else stack).add_child(l);return l
func button(text:String,callback:Callable,parent:Node=null) -> Button:
	var b=Button.new();b.text=text;b.custom_minimum_size.y=ACTION_HEIGHT
	var returning=text in ["메인메뉴","돌아가기"]
	b.pressed.connect(func():
		game.play_sound("ui",Vector3.ZERO,false)
		if returning and screen in ["practice","host","join","internet","internet_create"]:confirm_navigation(callback,text)
		else:callback.call())
	(parent if parent else stack).add_child(b)
	if parent and parent.get_meta("pinned_actions",false):
		b.custom_minimum_size=Vector2(160,ACTION_HEIGHT);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if returning:
		for state in ["normal","hover","pressed"]:
			var style=theme.get_stylebox(state,"Button").duplicate();style.bg_color=Color("593b4b") if state=="normal" else Color("805263");style.border_color=Color("c28c9a");b.add_theme_stylebox_override(state,style)
		if parent==null and is_instance_valid(panel_body) and is_instance_valid(panel_scroll) and screen!="menu":pin_actions(b)
	return b
func confirm_navigation(callback:Callable,destination:String):
	if is_instance_valid(navigation_confirm):return
	navigation_confirm=ConfirmationDialog.new();navigation_confirm.title="화면 이동 확인";navigation_confirm.dialog_text="메인메뉴로 이동할까요?" if destination=="메인메뉴" else "이전 화면으로 돌아갈까요?"
	navigation_confirm.ok_button_text="이동하기";navigation_confirm.cancel_button_text="계속 머물기";root.add_child(navigation_confirm)
	navigation_confirm.confirmed.connect(func():
		var dialog=navigation_confirm;navigation_confirm=null;dialog.queue_free();callback.call())
	navigation_confirm.canceled.connect(func():navigation_confirm.queue_free();navigation_confirm=null)
	navigation_confirm.popup_centered(Vector2i(440,160))
func confirm_practice():
	confirm_navigation(func():clear_panel();PracticeSession.start(game),"연습장")
	if is_instance_valid(navigation_confirm):
		navigation_confirm.title="연습장";navigation_confirm.dialog_text="연습장으로 이동하시겠습니까?";navigation_confirm.ok_button_text="연습장 입장"
func option(title:String,items:Array,selected:int,callback:Callable=Callable(),parent:Node=null) -> OptionButton:
	var row=HBoxContainer.new();(parent if parent else stack).add_child(row);var l=Label.new();l.text=title;l.custom_minimum_size.x=155;row.add_child(l)
	var b=OptionButton.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for s in items:b.add_item(str(s))
	if not items.is_empty():b.select(clampi(selected,0,items.size()-1))
	row.add_child(b)
	if callback.is_valid():b.item_selected.connect(callback)
	return b
func check(title:String,value:bool,callback:Callable) -> CheckBox:
	var b=CheckBox.new();b.text=title;b.button_pressed=value;b.toggled.connect(callback);b.custom_minimum_size.y=40
	# Keep icon/text in the exact same layout for normal, hover and toggled states.
	var style=StyleBoxEmpty.new();style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=6;style.content_margin_bottom=6
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:b.add_theme_stylebox_override(state,style)
	b.add_theme_constant_override("h_separation",14);b.add_theme_constant_override("check_v_offset",0)
	stack.add_child(b);return b
func edit(title:String,value:String,callback:Callable,secret=false) -> LineEdit:
	var row=HBoxContainer.new();stack.add_child(row);var l=Label.new();l.text=title;l.custom_minimum_size.x=155;row.add_child(l);var e=LineEdit.new();e.text=value;e.secret=secret;e.size_flags_horizontal=Control.SIZE_EXPAND_FILL;e.text_changed.connect(callback);row.add_child(e);return e
func menu():
	if not root or game.demo_mode:return
	game.stop_room_search()
	if hud:hud.queue_free();hud=null
	clear_panel(true);screen="menu";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	ensure_menu_background()
	for child in background.get_children():child.show()
	panel=PanelContainer.new();panel.position=Vector2(795,94);panel.custom_minimum_size=Vector2(456,0);root.add_child(panel);panel.scale=Vector2.ONE*MENU_SCALE
	build_main_actions()
func ensure_menu_background():
	if is_instance_valid(background):return
	background=Control.new();background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(background)
	if DisplayServer.get_name()!="headless":
		var live=load("res://scripts/menu_demo.gd").new();live.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(live)
	var shade=ColorRect.new();shade.color=Color(.015,.04,.065,.36);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(shade)
	var brand=Label.new();brand.text="NUKCANON  /  TACTICAL LAN FPS";brand.position=Vector2(68,102);brand.add_theme_font_size_override("font_size",19);brand.modulate=Color("7be4cd");background.add_child(brand)
	var title=Label.new();title.text="INTERNAL\nN CRUSH";title.position=Vector2(62,166);title.add_theme_font_size_override("font_size",64);background.add_child(title)
	var intro=Label.new();intro.text="장비를 고르고, 팀과 전장을 지배하세요.\n6개 병과 · 31개 전장 · 자유 훈련장";intro.position=Vector2(68,400);intro.add_theme_font_size_override("font_size",22);intro.modulate=Color("d6e5ed");background.add_child(intro)
	version_box=VBoxContainer.new();version_box.position=Vector2(68,545);version_box.custom_minimum_size.x=560;background.add_child(version_box)
func build_main_actions():
	if TouchControls.supported():build_touch_main_actions();return
	stack=VBoxContainer.new();stack.add_theme_constant_override("separation",9);panel.add_child(stack)
	var name=label("닉네임",19);name.modulate=Color("a7c5d4")
	var nick=LineEdit.new();nick.text=game.profile.nick;nick.placeholder_text="게임에서 사용할 닉네임";nick.max_length=20;nick.custom_minimum_size.y=47;nick.text_changed.connect(func(t):game.profile.nick=t;game.save_profile());stack.add_child(nick)
	stack.add_child(HSeparator.new());label("플레이",23)
	button("내부망 로비",join_menu)
	button("인터넷 로비",internet_menu)
	stack.add_child(HSeparator.new());label("연습",23)
	var practice_actions=HBoxContainer.new();practice_actions.add_theme_constant_override("separation",10);stack.add_child(practice_actions)
	button("봇 전투",practice_menu,practice_actions).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button("연습장",confirm_practice,practice_actions).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.add_child(HSeparator.new());label("설정",23)
	button("환경 설정",settings)
	stack.add_child(HSeparator.new());button("게임 페이지" if OS.has_feature("web") else "게임 종료",func():
		if OS.has_feature("web"):JavaScriptBridge.eval("window.location.href='https://nukcanon.github.io/nukcanon/internal-n-crush.html'")
		else:game.exit_game())
	notice_label=label("",17);update_version_badge()
func scale_interface():
	if is_instance_valid(role_cards):role_cards.columns=6 if get_viewport().get_visible_rect().size.x>=1100 else 3
	if is_instance_valid(gear_tabs):gear_tabs.columns=5 if get_viewport().get_visible_rect().size.x>=1100 else 3
	# Keep the established 1280x720 UI coordinates while rendering at the selected resolution.
	root.scale=get_viewport().get_visible_rect().size/Vector2(1280,720)
func update_version_badge():
	if screen!="menu" or not is_instance_valid(version_box):return
	for child in version_box.get_children():version_box.remove_child(child);child.queue_free()
	var version=label(("WEB  /  v" if OS.has_feature("web") else "WINDOWS  /  v")+Rules.VERSION,18,version_box);version.modulate=Color("b2c8d5")
	if game.version_check.state=="newer":
		var warning=label("새 버전 "+game.version_check.latest+"이 있습니다.\n함께 접속할 사람들과 버전을 맞춰 주세요.",18,version_box);warning.modulate=Color("ffd18d")
		button("최신 버전 다운로드",func():OS.shell_open(VersionCheck.PAGE),version_box)
func training_menu():
	make_panel("연습",900)
	label("FIELD ACADEMY",30)
	label("4개 높이의 야외 사격장 · 고정/이동 표적 · 회복과 방호 연습
표적은 공격하지 않으며 처치하면 4초 뒤 돌아옵니다. 입구 보급 구역에서 장비를 재충전하세요.",18)
	button("자유 연습장",confirm_practice)
	stack.add_child(HSeparator.new());label("봇 전투",27)
	label("실제 경기 규칙으로 조준, 전술과 목표 수행을 연습합니다.",18)
	button("봇 연습 설정",practice_menu);button("메인메뉴",menu)
func practice_menu():
	make_panel("봇 전투");screen="practice"
	game.options.bots=maxi(3,int(game.options.bots))
	option("난이도",["하 · 반응과 조준을 완화","중 · 목표와 지원 역할 수행","상 · 빠른 반응, 사격·후퇴 판단 강화"],game.options.get("bot_difficulty",1),func(i):game.options.bot_difficulty=i)
	option("봇 인원",["3명","5명","7명","15명","31명"],maxi(0,[3,5,7,15,31].find(game.options.bots)),func(i):game.options.bots=[3,5,7,15,31][i])
	option("게임 모드",Rules.MODES,game.options.mode,func(i):game.options.mode=i;if map_refresh.is_valid():map_refresh.call())
	map_selector()
	label("장애물 우회 · 목표 수행 · 회복/수리 · 가젯/스킬 사용\n체력, 탄약, 최근 교전 상황에 따라 행동을 바꿉니다.",16)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions)
	button("연습 시작",func():Rules.sanitize_room(game.options);game.host_game();game.start_match(),actions)
	button("메인메뉴",menu,actions);pin_actions(actions)
func section_tabs(names:Array) -> Array:
	var tabs=TabContainer.new();tabs.custom_minimum_size.y=340;tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_child(tabs)
	var out=[]
	for name in names:
		var margin=MarginContainer.new();margin.name=name
		for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
		tabs.add_child(margin);var content=VBoxContainer.new();content.add_theme_constant_override("separation",12);margin.add_child(content);out.append(content)
	return out
func host_settings():
	make_panel("방 만들기",980);screen="host"
	var outer=stack;var groups=section_tabs(["경기","팀 · 참가","병과 · 전투","봇"]);stack=groups[0]
	edit("방 이름",game.options.room,func(t):game.options.room=t.left(40))
	edit("비밀번호 (선택)",str(game.options.get("password","")),func(t):game.options.password=t,true)
	option("게임 모드",Rules.MODES,game.options.mode,func(i):game.options.mode=i;if map_refresh.is_valid():map_refresh.call())
	map_selector()
	option("경기 시간",["5분","10분","15분","20분"],[5,10,15,20].find(game.options.minutes),func(i):game.options.minutes=[5,10,15,20][i])
	option("목표 점수",["30","60","100","200"],[30,60,100,200].find(game.options.target),func(i):game.options.target=[30,60,100,200][i])
	option("진행 경기 수",["무한","2판","4판","6판","10판"],maxi(0,[0,2,4,6,10].find(int(game.options.rounds))),func(i):game.options.rounds=[0,2,4,6,10][i])
	option("설치·해체 준비 시간",["30초","45초","60초"],maxi(0,[30,45,60].find(int(game.options.get("prep_seconds",45)))),func(i):game.options.prep_seconds=[30,45,60][i])
	stack=groups[1]
	label("경기 탭에서 참가 정원을 짝수로 선택합니다. 맵 정원이 참가 정원보다 작을 수 없습니다.",17)
	option("진행 중 참가",["금지","관전만","참가 허용 · 폭탄은 다음 라운드"],game.options.join,func(i):game.options.join=i)
	option("다음 경기 팀",["현재 팀 유지","무작위","기록으로 균형 편성"],game.options.next_teams,func(i):game.options.next_teams=i)
	label("입장할 때 인원에 맞춰 자동 배치합니다.\n대기실에서는 각자 팀을 고르고 방장은 모든 참가자를 이동시킬 수 있습니다.\n경기 중에는 방장만 팀을 변경할 수 있습니다.",16)
	check("제한 부활: 팀 공용 목숨",game.options.shared_lives,func(v):game.options.shared_lives=v)
	option("제한 부활 횟수",["1","3","5","10"],[1,3,5,10].find(game.options.lives),func(i):game.options.lives=[1,3,5,10][i])
	stack=groups[2]
	check("병과 사용",game.options.classes,func(v):game.options.classes=v)
	check("특수 스킬 사용",game.options.skills,func(v):game.options.skills=v)
	label("스킬 OFF여도 회복 무기·수리 도구·가젯은 작동합니다.",14)
	check("무한 공격 탄약 · 재장전은 필요",game.options.infinite,func(v):game.options.infinite=v)
	check("아군 피해",game.options.friendly,func(v):game.options.friendly=v)
	check("체력 자동 회복",game.options.autoheal,func(v):game.options.autoheal=v)
	label("마지막 사격·피격 10초 후 초당 1 HP 회복. 부활 횟수와 별개입니다.",17)
	stack=groups[3]
	option("봇 인원",["없음","3명","5명","7명","15명","31명"],maxi(0,[0,3,5,7,15,31].find(game.options.bots)),func(i):game.options.bots=[0,3,5,7,15,31][i])
	option("봇 난이도",["하 · 느린 반응","중 · 균형","상 · 빠른 판단"],game.options.get("bot_difficulty",1),func(i):game.options.bot_difficulty=i)
	label("봇도 참가 인원에 포함됩니다.\n선택 인원이 방 정원을 넘으면 정원까지 추가합니다.",16)
	stack=outer;var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions);button("이 설정으로 방 만들기",func():game.host_game(),actions);button("돌아가기",join_menu,actions);pin_actions(actions);notice_label=label("",14)
func join_menu():
	if OS.has_feature("web"):internet_menu("lan")
	else:lan_lobby.show()
func update_rooms():
	lan_lobby.update_rooms()
func lobby():
	make_panel("대기실 · "+str(game.options.room),1100);screen="lobby"
	label(Rules.MODES[int(game.options.mode)]+"   ·   "+("스킬 ON" if game.options.skills else "스킬 OFF")+"   ·   최대 "+str(game.options.max_players)+"명",16)
	if game.server and not OS.has_feature("web"):
		var ips=[]
		for ip in IP.get_local_addresses():
			if "." in ip and not ip.begins_with("127."):ips.append(ip)
		label("접속 주소  "+", ".join(ips),15)
	label("대기실: 내 팀 선택 가능 · 방장: 모든 참가자 배치 가능",14)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions)
	button("병과 · 무기 · 가젯",gear,actions);button("팀 편성",teams_menu,actions);button("참가자 관리",members_menu,actions)
	actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions);pin_actions(actions)
	if game.server or int(game.options.get("room_owner",0))==game.local_id:button("경기 시작",func():game.command("start",{}),actions)
	else:label("방장이 경기를 시작하면 참여합니다.",15)
	button("방 나가기",func():game.request_leave(),actions);notice_label=label("",14)
	team_columns=HBoxContainer.new();team_columns.add_theme_constant_override("separation",18);stack.add_child(team_columns);refresh_teams()
func teams_menu():
	make_panel("팀 편성",1100);screen="teams"
	label("방장만 경기 중 팀을 변경할 수 있습니다. 변경된 참가자는 부활 후 합류하며 설치/해체 모드는 다음 라운드에 합류합니다.",15)
	if game.server:option("다음 경기 편성",["현재 팀 유지","무작위","기록으로 균형 편성"],game.options.next_teams,func(i):game.command("team_policy",{"next_teams":i}))
	team_columns=HBoxContainer.new();team_columns.add_theme_constant_override("separation",18);stack.add_child(team_columns);refresh_teams()
	button("돌아가기",func():
		if game.phase=="lobby":lobby()
		else:clear_panel();game.capture_pointer())
	notice_label=label("",14)
func refresh_teams():
	if not is_instance_valid(team_columns):return
	var signature=str(game.players.keys())+str(game.options.mode)
	for p in game.players.values():signature+=str([p.id,p.team,p.role,p.nick])
	if signature==team_signature:return
	team_signature=signature
	for node in team_columns.get_children():team_columns.remove_child(node);node.queue_free()
	for side in range(2):
		var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;team_columns.add_child(box)
		var head=label(("◆ BLUE" if side==0 else "● ORANGE")+"   "+str(game.team_count(side))+"명",23,box);head.modulate=Color("63c5ff") if side==0 else Color("ffa35f")
		for p in game.players.values():
			if p.team!=side:continue
			var row=HBoxContainer.new();box.add_child(row)
			var name=label(p.nick+("  · 나" if p.id==game.local_id else "")+"  /  "+Rules.CLASSES[p.role],15,row);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			var allowed=game.server or (game.phase=="lobby" and p.id==game.local_id)
			if allowed and game.options.mode!=1:
				var pid=int(p.id);var target=1-side
				var full=game.team_count(target)>=16
				var move=button("교환…" if full and game.server else "→ "+("BLUE" if target==0 else "ORANGE"),func():
					if full and game.server:team_swap_menu(pid)
					else:game.command("team",{"player_id":pid,"team":target}),row)
				move.custom_minimum_size.y=28;move.add_theme_font_size_override("font_size",13)
		if game.phase=="lobby" and game.players.has(game.local_id) and game.players[game.local_id].team!=side and game.options.mode!=1:
			var selected=side;button("이 팀으로 참가",func():game.command("team",{"team":selected}),box)
func team_swap_menu(first:int):
	if not game.server or not game.players.has(first):return
	make_panel("참가자 팀 교환",780)
	label(game.players[first].nick+"와 팀을 바꿀 상대를 선택하세요. 양 팀의 인원수는 유지됩니다.",18)
	var ids=[];var names=[]
	for p in game.players.values():
		if p.team!=game.players[first].team:ids.append(int(p.id));names.append(p.nick+" / "+Rules.CLASSES[p.role])
	var choice=option("상대 팀 참가자",names,0)
	button("팀 교환 적용",func():
		if not ids.is_empty():game.command("team_swap",{"first":first,"second":ids[choice.selected]})
		if game.phase=="lobby":lobby()
		else:teams_menu())
	button("돌아가기",func():
		if game.phase=="lobby":lobby()
		else:teams_menu())
func settings():
	make_panel("환경 설정",980);screen="settings"
	var outer=stack;var tabs=section_tabs(["화면 · 조준","그래픽","HUD","소리","조작법"]);stack=tabs[0]
	var displays=[]
	for i in range(DisplayServer.get_screen_count()):
		var native=DisplayServer.screen_get_size(i)
		displays.append("모니터 %d · %d × %d · %.0f Hz"%[i+1,native.x,native.y,DisplayServer.screen_get_refresh_rate(i)])
	var monitor=option("출력 모니터",displays,int(game.profile.monitor))
	var mode=option("화면 모드",["창 모드","전체 화면 · 빠른 앱 전환","전체 화면 · 게임 전용"],maxi(0,int(game.profile.display_mode)));mode.name="DisplayMode"
	if OS.has_feature("web"):
		monitor.disabled=true;mode.disabled=true
		label("브라우저 창 크기에 맞춰 표시됩니다. 전체 화면은 플레이 페이지의 전체 화면 버튼으로 전환하세요.",17)
	var mode_help=label("",17)
	var resolutions=[]
	var current=game.display_window_size()
	var resolution=option("게임 해상도",[],0);resolution.name="ResolutionChoices"
	var dimensions=HBoxContainer.new();dimensions.name="CustomResolution";stack.add_child(dimensions)
	var dimension_label=label("직접 입력",18,dimensions);dimension_label.custom_minimum_size.x=125;dimension_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	var width=SpinBox.new();width.min_value=640;width.max_value=32768;width.value=current.x;width.custom_minimum_size.x=190;dimensions.add_child(width)
	var times_label=label("×",18,dimensions);times_label.custom_minimum_size.x=25;times_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	var height=SpinBox.new();height.min_value=360;height.max_value=32768;height.value=current.y;height.custom_minimum_size.x=190;dimensions.add_child(height)
	var update_visibility=func():
		resolution.disabled=false;dimensions.visible=resolution.selected==resolutions.size()
		mode_help.text=["크기를 조절할 수 있는 창으로 플레이합니다.","테두리 없는 창을 화면 가득 표시합니다. 다른 앱으로 전환하기 편합니다.","독점 전체 화면입니다. 게임에 집중하는 모드이며 앱 전환 때 잠깐 깜빡일 수 있습니다."][mode.selected]
	var update_choices=func():
		var native=DisplayServer.screen_get_size(monitor.selected)
		if native.x<640 or native.y<360:native=Vector2i(1280,720)
		resolutions.assign(DisplayOptions.resolutions_for(native));resolution.clear()
		width.max_value=native.x;height.max_value=native.y
		for size in resolutions:resolution.add_item("%d × %d%s"%[size.x,size.y," · 모니터 원본" if size==native else ""])
		resolution.add_item("직접 입력")
		var size=Vector2i(int(width.value),int(height.value));var found=resolutions.find(size)
		resolution.select(found if found>=0 else resolutions.size());update_visibility.call()
	resolution.item_selected.connect(func(i):
		if i<resolutions.size():width.value=resolutions[i].x;height.value=resolutions[i].y
		update_visibility.call())
	monitor.item_selected.connect(func(_i):update_choices.call());mode.item_selected.connect(func(_i):update_visibility.call());update_choices.call()
	button("화면 설정 적용",func():
		var previous=game.profile.duplicate(true)
		game.profile.monitor=monitor.selected;game.profile.display_mode=mode.selected;game.profile.width=int(width.value);game.profile.height=int(height.value)
		game.apply_display_settings()
		var confirm=ConfirmationDialog.new();confirm.title="화면 설정 유지";confirm.ok_button_text="유지";confirm.cancel_button_text="되돌리기";root.add_child(confirm)
		var seconds=[15];var settled=[false];var timer=Timer.new();timer.wait_time=1.;confirm.add_child(timer)
		var rollback=func():
			if settled[0]:return
			settled[0]=true;game.profile.merge(previous,true);game.apply_display_settings();confirm.queue_free();settings()
		confirm.confirmed.connect(func():settled[0]=true;game.save_profile();confirm.queue_free();settings())
		confirm.canceled.connect(rollback)
		timer.timeout.connect(func():
			seconds[0]-=1;confirm.dialog_text="이 화면을 유지할까요? %d초 후 이전 설정으로 돌아갑니다."%seconds[0]
			if seconds[0]<=0:rollback.call())
		confirm.dialog_text="이 화면을 유지할까요? 15초 후 이전 설정으로 돌아갑니다.";confirm.popup_centered(Vector2i(660,170));timer.start())
	label("전체 화면에서도 게임 해상도를 낮출 수 있습니다. 낮을수록 화면은 덜 선명하지만 그래픽 부하가 줄어듭니다.",17)
	sensitivity_control("마우스 감도",float(game.profile.sensitivity)/.0023,.15,4.,func(v):game.profile.sensitivity=v*.0023;game.save_profile())
	sensitivity_control("정조준 감도 배율",float(game.profile.ads_sensitivity),.2,1.5,func(v):game.profile.ads_sensitivity=v;game.save_profile())
	label("화면과 감도 설정은 다음 실행에도 유지됩니다.",14)
	stack=tabs[1]
	GraphicsOptions.build(self)
	stack=tabs[2]
	var preview=HudPreview.new();preview.game=game;stack.add_child(preview)
	sensitivity_control("HUD 크기",float(game.profile.hud_scale),.65,1.1,func(v):game.profile.hud_scale=v;HudLayout.apply(self);preview.queue_redraw();game.save_profile())
	sensitivity_control("HUD 배경 농도",float(game.profile.hud_opacity),.1,.8,func(v):game.profile.hud_opacity=v;HudLayout.apply(self);preview.queue_redraw();game.save_profile())
	label("기본 크기 80% · 배경 농도 38%. 낮은 농도일수록 뒤의 전장이 더 잘 보입니다. 조준점과 피격 판정에는 영향을 주지 않습니다.",17)
	stack=tabs[3]
	button("피격음 미리 듣기 · 둔탁한 충격",func():game.play_sound("hurt",Vector3.ZERO,false))
	button("방어구 피격음 미리 듣기",func():game.play_sound("armor_hurt",Vector3.ZERO,false))
	sound_slider("전체 음량", "volume")
	label("총소리·발소리·전투 효과는 전체 음량에 함께 적용됩니다.",17)
	sound_slider("명중 알림", "hit_volume")
	sound_slider("메뉴 소리", "ui_volume")
	var samples=HBoxContainer.new();stack.add_child(samples);button("총소리 미리 듣기",func():game.play_sound("gun_a1",Vector3.ZERO,false),samples);button("발소리 미리 듣기",func():game.play_sound("step_stone_0",Vector3.ZERO,false),samples)
	stack=tabs[4]
	var diagram=ControlsDiagram.new();diagram.custom_minimum_size=Vector2(885,415);stack.add_child(diagram)
	label("E: 문 열기·닫기  /  E 길게: 설치·해체  /  F: 스킬 · 포탑 강화  /  Q: 의료 카빈 회복\nG: 가젯 · 수류탄은 누른 뒤 놓아 투척  /  V: 가젯 종류  /  F6·F7: 강퇴 투표",18)
	stack=outer
	var back=button("메인메뉴" if game.phase=="menu" else "돌아가기",func():
		if game.phase=="menu":menu()
		elif game.phase=="lobby":lobby()
		else:clear_panel();game.capture_pointer())
	pin_actions(back)
func sound_slider(title:String,key:String):
	var row=HBoxContainer.new();stack.add_child(row);var text=label(title,20,row);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var amount=label("%d%%"%roundi(float(game.profile[key])*100),18,row);amount.autowrap_mode=TextServer.AUTOWRAP_OFF;amount.custom_minimum_size.x=72;amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var slider=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.01;slider.value=game.profile[key];slider.custom_minimum_size.y=28;stack.add_child(slider)
	slider.value_changed.connect(func(v):game.profile[key]=v;amount.text="%d%%"%roundi(v*100);game.save_profile())
func members_menu():
	make_panel("참가자 관리",1020);screen="members";member_signature=""
	label("방장은 바로 강퇴할 수 있습니다. 투표는 대상 외 참가자의 60% 이상(최소 2명)이 찬성하면 통과됩니다.",18)
	room_list=VBoxContainer.new();stack.add_child(room_list);refresh_members()
	button("돌아가기",func():
		if game.phase=="lobby":lobby()
		else:clear_panel();game.capture_pointer())
	notice_label=label("",17)
func refresh_members():
	if screen!="members" or not is_instance_valid(room_list):return
	var signature=str(game.players.keys())
	if signature==member_signature:return
	member_signature=signature
	for node in room_list.get_children():room_list.remove_child(node);node.queue_free()
	for p in game.players.values():
		var row=HBoxContainer.new();room_list.add_child(row);var pid=int(p.id)
		var name=label(p.nick+(" · 방장" if pid==1 else " · 나" if pid==game.local_id else ""),20,row);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.modulate=Color("78caff") if p.team==0 else Color("ffb376")
		if pid!=1 and pid!=game.local_id:
			if game.server:button("강퇴",func():game.command("kick",{"target":pid}),row)
			if pid>0:button("강퇴 투표",func():game.command("vote_kick",{"target":pid}),row)
func refresh_vote():
	if game.vote.is_empty():
		if is_instance_valid(vote_panel):vote_panel.visible=false
		return
	if not is_instance_valid(vote_panel):
		vote_panel=PanelContainer.new();vote_panel.position=Vector2(353,75);vote_panel.custom_minimum_size=Vector2(575,0);vote_panel.z_index=100;root.add_child(vote_panel)
		var column=VBoxContainer.new();vote_panel.add_child(column);vote_text=label("",18,column)
		var row=HBoxContainer.new();column.add_child(row)
		vote_yes=button("F6  찬성",func():game.command("vote",{"yes":true}),row);vote_no=button("F7  반대",func():game.command("vote",{"yes":false}),row)
	vote_panel.visible=true
	var v=game.vote;var total=0
	for result in v.get("votes",{}).values():
		if result:total+=1
	vote_text.text="%s 강퇴 투표  ·  찬성 %d / %d  ·  %d초"%[v.get("name",""),total,v.get("needed",2),maxi(0,int(v.get("until",0)-game.clock))]
	var allowed=game.local_id in v.get("eligible",[]) and not v.get("votes",{}).has(game.local_id)
	vote_yes.disabled=not allowed;vote_no.disabled=not allowed
func sensitivity_control(title:String,value:float,low:float,high:float,callback:Callable):
	var row=HBoxContainer.new();stack.add_child(row)
	var l=Label.new();l.text=title;l.custom_minimum_size.x=155;row.add_child(l)
	var slider=HSlider.new();slider.min_value=low;slider.max_value=high;slider.step=.05;slider.value=value;slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
	var number=SpinBox.new();number.min_value=low;number.max_value=high;number.step=.05;number.value=value;number.custom_minimum_size.x=125;row.add_child(number)
	slider.value_changed.connect(func(v):number.set_value_no_signal(v);callback.call(v))
	number.value_changed.connect(func(v):slider.set_value_no_signal(v);callback.call(v))
func gear():
	if not game.players.has(game.local_id):return
	var p=game.players[game.local_id];var queued=p.get("pending_loadout",{});var chosen=queued.get("role",p.role)
	make_panel("오퍼레이터 · 장비",1160);screen="gear";preview_kind=0;preview_secondary=false;gear_category=0
	# Hidden selectors preserve one canonical loadout state for networking and menus.
	gear_class=option("병과",Rules.CLASSES,chosen);gear_class.get_parent().hide()
	gear_class.disabled=not game.options.classes
	gear_primary=option("주무기",[],0);gear_primary.get_parent().hide()
	gear_armor=option("방어구",["없음","경량 +25","중량 +50"],int(queued.get("armor",int(p.armor_max)/25)));gear_armor.get_parent().hide()
	gear_gadget=option("가젯",[],0);gear_gadget.get_parent().hide()
	gear_repair=check("FIX",queued.get("repair",p.secondary=="repair"),func(_v):refresh_gear_detail());gear_repair.hide()
	role_cards=GridContainer.new();role_cards.columns=6 if get_viewport().get_visible_rect().size.x>=1100 else 3;role_cards.add_theme_constant_override("h_separation",8);role_cards.add_theme_constant_override("v_separation",8);stack.add_child(role_cards)
	var outer=stack;var split=HBoxContainer.new();split.add_theme_constant_override("separation",20);outer.add_child(split)
	var form=VBoxContainer.new();form.custom_minimum_size.x=625;split.add_child(form)
	var tabs=GridContainer.new();gear_tabs=tabs;tabs.columns=5 if get_viewport().get_visible_rect().size.x>=1100 else 3;tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;form.add_child(tabs)
	for i in range(5):
		var category=i;var tab=button(["주무기","보조","가젯","방어구","스킬"][i],func():gear_category=category;preview_secondary=category==1;preview_kind=[1,1,2,3,4][category];refresh_gear_detail();refresh_gear_cards(),tabs);tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(625,260);form.add_child(scroll)
	gear_cards=GridContainer.new();gear_cards.columns=3;gear_cards.add_theme_constant_override("h_separation",8);gear_cards.add_theme_constant_override("v_separation",8);scroll.add_child(gear_cards)
	role_detail=label("",17,form);role_detail.modulate=Color("8fcbed")
	var right=VBoxContainer.new();right.custom_minimum_size.x=440;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(right)
	preview_widget=EquipmentPreview.new();right.add_child(preview_widget);preview_widget.custom_minimum_size=Vector2(440,clampf(get_viewport().get_visible_rect().size.y*.32,220.,380.));preview_widget.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	preview_caption=label("",21,right)
	stat_graph=StatGraph.new();right.add_child(stat_graph)
	gear_detail=label("",15,right);gear_detail.add_theme_font_size_override("font_size",14);gear_detail.modulate=Color("d2e2ec")
	stack=outer
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);outer.add_child(actions);pin_actions(actions)
	gear_submit=button("선택 적용",func():
		if not weapon_ids.is_empty():game.command("loadout",selected_loadout()),actions)
	if game.phase=="combat" and int(game.options.mode) in [0,1,3] and not game.options.get("practice",false):
		button("사망 후 즉시 적용 · −25점",func():
			var selection=selected_loadout();selection.immediate=true;game.command("loadout",selection),actions)
	button("돌아가기",exit_gear,actions)
	gear_price=label("",17,actions);gear_price.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	notice_label=label("",14);notice_label.modulate=Color("80cfef")
	refresh_weapons()
	var wanted=queued.get("primary",p.primary)
	if wanted in weapon_ids:gear_primary.select(weapon_ids.find(wanted))
	gear_gadget.select(maxi(0,gear_gadget.get_item_index(int(queued.get("gadget",p.gadget)))));refresh_gear_detail();refresh_gear_cards()
func exit_gear():
	if game.phase=="lobby":lobby()
	else:clear_panel();game.capture_pointer()
func image_card(parent:Node,key:String,caption:String,selected:bool,callback:Callable,width=199,height=116) -> Button:
	var card=Button.new();card.custom_minimum_size=Vector2(width,height);card.toggle_mode=true;card.button_pressed=selected;parent.add_child(card);card.pressed.connect(callback)
	var content=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=6;content.offset_right=-6;content.offset_top=4;content.offset_bottom=-4;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(content)
	var picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.size_flags_vertical=Control.SIZE_EXPAND_FILL;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(picture)
	var path="res://assets/thumbnails/"+key+".png"
	if ResourceLoader.exists(path):picture.texture=load(path)
	var text=Label.new();text.text=caption;text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.add_theme_font_size_override("font_size",16);text.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(text)
	return card
func refresh_gear_cards():
	if not is_instance_valid(gear_cards):return
	for child in role_cards.get_children():role_cards.remove_child(child);child.queue_free()
	for role in range(6):
		var selected_role=role
		var card=image_card(role_cards,"role"+str(role),Rules.CLASSES[role]+" · "+HumanModel.IDENTITIES[role],gear_class.selected==role,func():gear_class.select(selected_role);preview_kind=0;refresh_weapons();refresh_gear_cards(),174,84)
		card.disabled=not game.options.classes;card.tooltip_text="%d cm · %s"%[roundi(HumanModel.HEIGHTS[role]*100),Rules.GADGET_HELP[role]]
	for child in gear_cards.get_children():gear_cards.remove_child(child);child.queue_free()
	var role=gear_class.selected
	match gear_category:
		0:
			for i in range(weapon_ids.size()):
				var index=i;var w=Catalog.get_weapon(weapon_ids[i])
				image_card(gear_cards,weapon_ids[i],w.name,gear_primary.selected==i,func():gear_primary.select(index);preview_kind=1;preview_secondary=false;refresh_gear_detail();refresh_gear_cards())
		1:
			for id in ([Rules.SECONDARIES[role],"repair"] if role==3 else [Rules.SECONDARIES[role]]):
				var wid=id;image_card(gear_cards,id,Catalog.get_weapon(id).name,gear_repair.button_pressed if id=="repair" else not gear_repair.button_pressed,func():gear_repair.button_pressed=wid=="repair";preview_kind=1;preview_secondary=true;refresh_gear_detail();refresh_gear_cards())
		2:
			for i in range(gear_gadget.item_count):
				var index=i;image_card(gear_cards,"gadget"+str(role)+"_"+str(gear_gadget.get_item_id(i)),gear_gadget.get_item_text(i).split(" · ")[0],gear_gadget.selected==i,func():gear_gadget.select(index);preview_kind=2;refresh_gear_detail();refresh_gear_cards())
		3:
			for i in range(3):
				var index=i;image_card(gear_cards,"armor"+str(i),["기본 복장","경량 방어구","중량 방어구"][i],gear_armor.selected==i,func():gear_armor.select(index);preview_kind=3;refresh_gear_detail();refresh_gear_cards())
		4:image_card(gear_cards,"skill"+str(role),Rules.SKILLS[role],true,func():preview_kind=4;refresh_gear_detail())
func selected_loadout() -> Dictionary:
	return {"role":gear_class.selected,"primary":weapon_ids[gear_primary.selected],"armor":gear_armor.selected,"gadget":gear_gadget.get_selected_id(),"repair":gear_repair.button_pressed}
func refresh_weapons():
	if gear_class.selected!=3:gear_repair.button_pressed=false
	gear_primary.clear();weapon_ids=[]
	for id in Catalog.list_for(gear_class.selected,game.options.classes):
		var w=Catalog.get_weapon(id)
		if not game.options.classes and w.kind!="gun":continue
		weapon_ids.append(id);gear_primary.add_item(w.name)
	if is_instance_valid(gear_gadget):
		gear_gadget.clear()
		var items=["기본 가젯"]
		if gear_class.selected==3:items=["경량 엄폐물 · 180 내구도","표준 엄폐물 · 300 내구도","강화 엄폐물 · 420 내구도"]
		elif gear_class.selected==0:items=["보호판", "파편 수류탄"]
		elif gear_class.selected==4:items=["연막 2 + 섬광 1","연막 1 + 섬광 2"]
		else:items=[Rules.GADGETS[gear_class.selected]]
		for item in items:gear_gadget.add_item(item)
		if int(game.options.mode)==4:gear_gadget.add_item("해체 키트 · 400 크레딧",9)
		gear_repair.hide()
	refresh_gear_detail()
func refresh_gear_detail():
	if not is_instance_valid(gear_detail) or weapon_ids.is_empty():return
	var role=gear_class.selected;var p=game.players[game.local_id]
	var preview_id=("repair" if role==3 and gear_repair.button_pressed else Rules.SECONDARIES[role]) if preview_kind==1 and preview_secondary else weapon_ids[gear_primary.selected]
	var w=Catalog.get_weapon(preview_id)
	var mode={"auto":"연발","semi":"단발","burst":"3점사"}.get(w.get("fire_mode","auto"),"")
	preview_caption.text=w.name+" · "+str(w.get("category",mode))
	gear_detail.text="피해 %d%s    /    %s · 분당 %d발\n탄창 %d · 예비탄 %d    /    재장전 %.1f초\n안정성 %d / 100    /    조준 속도 %d ms\n무게 %.2f kg    /    휴대성 %d / 100\n기본 퍼짐 %.2f°    /    조준 시 %.2f°\n피해 감소 시작 %.0f m"%[w.damage," × "+str(int(w.pellets)) if w.pellets>1 else "",mode,60./maxf(.01,float(w.interval)),w.mag,w.reserve,w.reload,w.get("stability",0),w.get("ads_ms",250),w.get("weight_kg",0),w.get("portability",0),w.spread,w.get("ads_spread",0),w.reach]
	gear_detail.tooltip_text="안정성↑: 연속 사격 퍼짐 감소 · 조준 시간↓: 더 빠른 조준\n무게↑ / 휴대성↓: 이동 중 퍼짐 증가 · 퍼짐은 반각 기준"
	gear_detail.text="머리 ×%.2f · 몸통 ×1 · 다리 ×%.2f\n조준 이동 %.2f m/s · 비조준 %.1f° / 조준 %.1f°"%[w.zone_multipliers.head,w.zone_multipliers.legs,float(w.get("ads_speed",4.4))*.5,w.spread,w.ads_spread]
	if w.kind=="heal":gear_detail.text="LINK · 피해 없음 · 회복 24/초\n유효 거리 10 m · 에너지 180\n아군을 향해 발사하면 지속 회복합니다.\n같은 아군에게 여러 LINK 효과는 중첩되지 않습니다."
	if w.kind=="remote":gear_detail.text="TETHER · 원격 포탑 조종\n클릭: 자동 각도·사거리 제한 없이 사격\n12m 이후 탄환 피해 감소 · 48m에서 10%\n4단계 미사일은 2초 간격 · 거리 감쇠 없음"
	if w.kind=="repair":gear_detail.text="FIX · 구조물 수리 · 에너지 100\n아군 엄폐물과 포탑을 향해 발사하세요.\n권총 자리를 사용합니다."
	if preview_kind==0:
		preview_caption.text=HumanModel.IDENTITIES[role]+" · "+Rules.CLASSES[role]+" · %d cm"%roundi(HumanModel.HEIGHTS[role]*100)
		gear_detail.text=["소총으로 전선을 유지하는 돌격수.","스코프 사격과 표식으로 시야를 확보하는 정찰수.","기관총과 방호로 거점을 지키는 중화기병.","샷건과 엄폐물, 자동 포탑을 운용하는 공병.","기관단총과 연막·섬광으로 경로를 통제하는 지원병.","회복 도구와 의료 카빈으로 팀을 지원하는 메딕."][role]+"\n\n"+Rules.GADGET_HELP[role]+"\n"+Rules.SKILL_HELP[role]
	elif preview_kind==2:
		preview_caption.text=gear_gadget.get_item_text(gear_gadget.selected);gear_detail.text=Rules.GADGET_HELP[role]+"\n\n3 가젯 선택 · 클릭 사용 · G 즉시 사용"
		if role==0 and gear_gadget.selected==1:gear_detail.text="G 또는 3번 선택 후 클릭을 누르면 안전핀 해제.\n놓으면 투척 · 3초 후 폭발 · 계속 들면 자신도 피해.\n벽 뒤에는 폭발 피해가 전달되지 않습니다."
		if role==3 and gear_gadget.get_selected_id()!=9:gear_detail.text+="\n내구도 %d · 조준한 방향에 배치"%AbilityBalance.COVER_HP[gear_gadget.selected]
		if gear_gadget.get_selected_id()==9:gear_detail.text="해체 시간 30초 → 10초\n400 크레딧 · 기존 병과 가젯 대신 장착\n장치 앞에서 E를 계속 누르면 자동 사용합니다."
	elif preview_kind==3:
		preview_caption.text=["기본 복장","경량 방어구 · +25","중량 방어구 · +50"][gear_armor.selected];gear_detail.text="방어구는 체력보다 먼저 피해를 흡수합니다.\n기본 체력 100 · 기본 방어구 0\n"+("비용 %d 크레딧"%[0,300,600][gear_armor.selected] if game.options.mode==4 else "장비 선택은 무료입니다.")
	elif preview_kind==4:
		preview_caption.text=Rules.SKILLS[role];gear_detail.text=Rules.SKILL_HELP[role]+"\n\nF 사용 · 충전 완료 후 사용 가능"
	if not game.options.skills and preview_kind==4:gear_detail.text+="\n현재 방에서는 스킬이 꺼져 있습니다."
	stat_graph.configure(preview_kind,w,role,gear_armor.selected if preview_kind==3 else gear_gadget.get_selected_id())
	var primary=Catalog.get_weapon(weapon_ids[gear_primary.selected])
	role_detail.text="%s  /  %s\n%s"%[Rules.CLASSES[role],primary.name,"선택한 장비는 다음 부활에 적용" if game.phase=="combat" and not game.options.get("practice",false) else "카드를 선택하고 장비 적용을 누르세요."]
	var cost=game.loadout_cost(p,selected_loadout())
	gear_price.text="비용 %d / 보유 %d"%[cost,p.cash] if game.options.mode==4 else "장비 선택 무료"
	if is_instance_valid(preview_widget):preview_widget.display(preview_kind,role,int(p.team),preview_id,gear_armor.selected if preview_kind==3 else gear_gadget.get_selected_id())
	gear_submit.text="구매하기" if game.phase=="buy" else "장비 적용" if game.phase=="lobby" or game.options.get("practice",false) else "다음 부활에 적용 예약" if game.options.mode!=4 else "다음 라운드 구매 예약"
func toggle_pause():
	if is_instance_valid(panel):clear_panel();game.capture_pointer();return
	make_panel("일시 메뉴 · 경기는 계속 진행됩니다.",680)
	if game.phase=="lobby":button("돌아가기",lobby)
	else:button("돌아가기",func():clear_panel();game.capture_pointer())
	button("병과 · 무기 · 가젯",gear);button("팀 편성",teams_menu);button("참가자 관리",members_menu);button("환경 설정",settings);button("방 나가기",func():game.request_leave())
func hud_label(text:String,pos:Vector2,size:int=20) -> Label:
	var l=Label.new();l.text=text;l.position=pos;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_shadow_color",Color(0,0,0,.8));l.add_theme_constant_override("shadow_offset_x",1);l.add_theme_constant_override("shadow_offset_y",2);hud.add_child(l);return l
func hud_plate(pos:Vector2,size:Vector2) -> Panel:
	var plate=Panel.new();plate.set_meta("hud_plate",true);plate.position=pos;plate.size=size;var style=StyleBoxFlat.new();style.bg_color=Color(.035,.075,.1,.38);style.set_corner_radius_all(4);style.border_color=Color(.75,.84,.9,.24);style.border_width_bottom=1;plate.add_theme_stylebox_override("panel",style);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(plate);return plate
func hud_bar(pos:Vector2,color:Color) -> ColorRect:
	var bg=ColorRect.new();bg.color=Color("344752");bg.position=pos;bg.size=Vector2(220,5);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(bg)
	var bar=ColorRect.new();bar.color=color;bar.position=pos;bar.size=Vector2(220,5);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(bar);return bar
func show_hud():
	if game.demo_mode:return
	clear_panel()
	if hud:hud.queue_free()
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
	hud_plate(Vector2(406,15),Vector2(468,49))
	status=hud_label("",Vector2(422,24),21);status.custom_minimum_size.x=436;status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud_blue=hud_label("",Vector2(422,24),21);hud_blue.modulate=Color("69bdff")
	hud_orange=hud_label("",Vector2(752,24),21);hud_orange.modulate=Color("ffb16b")
	stats=hud_label("",Vector2(1062,18),17)
	hud_plate(Vector2(22,595),Vector2(259,98));health=hud_label("",Vector2(40,607),22)
	health_bar=hud_bar(Vector2(40,648),Color("68dcc0"));armor_bar=hud_bar(Vector2(40,665),Color("7aafdc"))
	hud_plate(Vector2(995,577),Vector2(263,116));weapon_title=hud_label("",Vector2(1012,589),16);ammo=hud_label("",Vector2(1012,615),30)
	health.size=Vector2(224,32);health.position.y=607;health.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	health.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	operator_name=hud_label("",Vector2(40,573),17);operator_name.size=Vector2(224,24);operator_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	weapon_title.size=Vector2(228,25);weapon_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;weapon_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	ammo.size=Vector2(228,49);ammo.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	ammo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var pips=AmmoPips.new();pips.game=game;pips.position=Vector2(1012,621);hud.add_child(pips)
	interaction_hint=hud_label("",Vector2(440,449),18);interaction_hint.size=Vector2(400,36);interaction_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	banner=hud_label("",Vector2(34,96),17)
	info=hud_label("",Vector2(305,686),16)
	skill_label=hud_label("",Vector2(313,590),16)
	slots=[];slot_panels=[]
	for i in range(4):
		var plate=hud_plate(Vector2(305+i*132,622),Vector2(125,54));slot_panels.append(plate)
		var l=hud_label("",Vector2(346+i*132,632),12);l.size=Vector2(76,30);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;slots.append(l)
	skill_label.hide();info.hide()
	var symbols=HudSymbols.new();symbols.game=game;symbols.ui=self;symbols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.add_child(symbols)
	crosshair=hud_label("",Vector2(0,0),1)
	reticle=Reticle.new();reticle.game=game;reticle.ui=self;reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(reticle)
	kill_feed=KillFeed.new();hud.add_child(kill_feed)
	scoreboard=MatchScoreboard.new();scoreboard.game=game;hud.add_child(scoreboard);scoreboard.visible=false
	flash_overlay=ColorRect.new();flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash_overlay.color=Color(.055,.065,.08,0);flash_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(flash_overlay)
	HudLayout.attach(self)
	if is_instance_valid(game.touch):
		root.move_child(game.touch,-1)
	game.capture_pointer()
func notice(message:String):
	if message.is_empty():return
	if lan_lobby:lan_lobby.notice(message)
	notice_until=Time.get_ticks_msec()+3500
	if is_instance_valid(notice_label):notice_label.text=message
	if game.phase=="menu" and message.contains("버전"):
		var dialog=AcceptDialog.new();dialog.title="게임 버전 확인";dialog.dialog_text=message;dialog.ok_button_text="확인";root.add_child(dialog);dialog.add_button("다운로드",false,"download");dialog.custom_action.connect(func(action):
			if action=="download":OS.shell_open(VersionCheck.PAGE))
		dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(680,210))
	if is_instance_valid(banner):banner.text=message
func refresh():
	if lan_lobby:lan_lobby.refresh_connection()
	refresh_vote();refresh_members()
	if screen in ["lobby","teams"]:refresh_teams()
	if not is_instance_valid(hud) or not game.players.has(game.local_id):return
	var p=game.players[game.local_id];var a=game.actors[game.local_id];var wid=p.primary if p.slot==0 else p.secondary;var w=Catalog.get_weapon(wid)
	var door=InteractiveDoor.target(game,game.local_id) if p.alive else null
	interaction_hint.text="[ E ]  문 닫기" if door and door.opened else "[ E ]  문 열기" if door else ""
	interaction_hint.visible=door!=null
	if p.role==3:
		var turret=Deployment.nearby_turret(game,game.local_id)
		if turret:
			var d=game.devices[turret];interaction_hint.visible=true
			interaction_hint.text="[ F ] 포탑 업그레이드 %d → %d"%[d.level,d.level+1] if d.level<4 else "포탑 최대 단계"
	if p.get("placing","")!="":interaction_hint.text="클릭 설치 · 같은 설치 키로 취소 · 빨강: 설치 불가";interaction_hint.visible=true
	if p.get("invul_select",0)>game.clock:interaction_hint.text="아군 조준 후 클릭: 무적 · F 두 번: 자신";interaction_hint.visible=true
	if p.get("mark",0)>game.clock:interaction_hint.text="위치 노출 · %.1f초"%(p.mark-game.clock);interaction_hint.visible=true
	if p.get("invulnerable",0)>game.clock:interaction_hint.text="무적 보호 · %.1f초"%(p.invulnerable-game.clock);interaction_hint.visible=true
	kill_feed.refresh(game.kill_events,game.local_id,Time.get_ticks_msec())
	stats.text="%d FPS  ·  %s"%[Engine.get_frames_per_second(),"HOST" if game.server else str(game.ping_ms)+" ms"]
	var secs=maxi(0,int(game.remaining));status.text="%02d:%02d"%[secs/60,secs%60]
	hud_blue.text="BLUE %d"%game.scores[0];hud_orange.text="%d ORANGE"%game.scores[1]
	hud_blue.visible=not game.options.get("practice",false);hud_orange.visible=hud_blue.visible
	if game.options.get("practice",false):status.text="FIELD ACADEMY  ·  자유 연습"
	health.text=("◆ BLUE  " if p.team==0 else "● ORANGE  ")+"%d HP"%p.hp if p.alive else "Dead · 관전" if game.options.mode==4 or p.spectator else "Dead · 부활 %.0f초"%maxf(0,p.respawn-game.clock)
	operator_name.text=HumanModel.IDENTITIES[int(p.role)]+"  ·  "+Rules.CLASSES[int(p.role)]
	health_bar.size.x=220*clampf(p.hp/100.,0,1);armor_bar.size.x=220*clampf(p.armor/50.,0,1)
	var fire_mode={"auto":"AUTO","semi":"SEMI","burst":"BURST"}.get(w.get("fire_mode","auto"),"")
	weapon_title.text=w.name+"   /   "+fire_mode
	ammo.text=str(int(p.mag.get(wid,0)))+" / "+("∞" if game.options.infinite else str(int(p.reserve.get(wid,0))))
	if w.kind=="heal":ammo.text="%d / 180"%p.energy;weapon_title.text="LINK  /  회복 에너지"
	if w.kind=="repair":ammo.text="%d / 100"%p.repair_energy;weapon_title.text="FIX  /  수리 에너지"
	if p.slot>=2:weapon_title.text=Rules.GADGETS[p.role] if p.role!=4 else "섬광탄" if p.slot==3 else "연막탄";ammo.text="클릭하여 사용"
	if p.reload>game.clock:ammo.text="재장전 %.1f"%(p.reload-game.clock)
	health.add_theme_color_override("font_color",Color("6bc7ff") if p.team==0 else Color("ffa35f"))
	var skill="준비" if p.skill_ready<=game.clock else "%.0f초"%ceil(p.skill_ready-game.clock)
	if GrenadeLogic.equipped(p) and p.slot==2:weapon_title.text="파편 수류탄";ammo.text="누르고 준비 · 놓아 투척"
	if p.get("cooking",0)>0:weapon_title.text="수류탄 안전핀 해제";ammo.text="%.1f초 · 놓아 투척"%maxf(0.,3.-game.clock+float(p.grenade_started))
	ammo.add_theme_font_size_override("font_size",16 if p.slot>=2 or p.get("cooking",0)>0 else 26 if p.reload>game.clock else 30)
	ammo.visible=p.slot>=2 or p.get("cooking",0)>0 or p.reload>game.clock
	skill_label.text="F  "+Rules.SKILLS[p.role]+"  ·  "+skill if game.options.skills and game.options.classes else "특수 스킬 OFF"
	if p.primary=="m2":skill_label.text+="     Q 회복 %d  ·  2초 간격"%p.heal_mag
	if p.get("mounted",0)>game.clock:skill_label.text+="     거치대 %.0f초"%(p.mounted-game.clock)
	if p.shield>game.clock:skill_label.text+="     방호 활성"
	var labels=["1  "+Catalog.get_weapon(p.primary).name,"2  "+Catalog.get_weapon(p.secondary).name,"3  "+("해체 키트" if p.gadget==9 else "파편 수류탄" if GrenadeLogic.equipped(p) else Rules.GADGETS[p.role] if p.role!=4 else "연막탄")+" ×"+str(p.gadget_count if p.role!=4 else p.smoke),"4  "+("섬광탄 ×"+str(p.flash_count) if p.role==4 else "—")]
	for i in range(4):
		slots[i].text=labels[i].substr(3);slots[i].modulate=Color("6eebc7") if p.slot==i else Color("b6cbd4")
		slot_panels[i].self_modulate=Color("75cebb") if p.slot==i else Color.WHITE
		if i>=2 and not game.options.classes:slots[i].text=str(i+1)+"  사용 안 함"
	info.text="B 병과/장비   ·   E 상호작용   ·   TAB 기록   ·   ESC 설정"
	if game.options.mode==4:info.text+="   ·   %d 크레딧"%p.cash
	if not p.get("pending_loadout",{}).is_empty():info.text+="   ·   다음 부활 장비 예약됨"
	if not p.alive:info.text="마우스: 관전 시점   ·   클릭: 관전 대상 변경   ·   B 다음 병과/장비"
	reticle.queue_redraw()
	flash_overlay.color.a=clampf((p.flash-game.clock)/2.5,0,.96)
	if p.alive and p.protect>game.clock:banner.text="부활 보호 %.1f초 · 공격 대기"%(p.protect-game.clock)
	elif p.flash>game.clock:banner.text="섬광 · 시야 회복 중"
	elif game.phase=="buy":banner.text="준비 %.0f초 · B 병과/장비 · 공격팀 대기 / 수비팀 배치"%game.remaining
	elif game.bomb.planted:banner.text="폭탄 폭발까지 %.1f초 · 해체 E 유지"%maxf(0.,game.bomb.time)
	elif game.bomb.actor==game.local_id:banner.text="상호작용 %.1f초"%game.bomb.progress
	elif int(game.options.mode)==4 and int(game.bomb.get("carrier",0))==game.local_id:banner.text="폭탄 운반 중 · A 또는 B에서 E 유지"
	elif int(game.options.mode)==4 and game.bomb.get("dropped",false) and p.team==MatchFlow.attackers(game):banner.text="폭탄을 회수하세요 · 가까이에서 E"
	elif game.options.get("practice",false):banner.text=("병과/장비 버튼" if TouchControls.supported() else "B 병과/장비")+" · 입구 보급 구역에서 탄약·가젯·스킬 재충전"
	elif Time.get_ticks_msec()>notice_until:banner.text=""
	scoreboard.visible=Input.is_action_pressed("score") or game.phase=="result" or (is_instance_valid(game.touch) and game.touch.held.get("score",false))
	if scoreboard.visible:scoreboard.refresh_scores()

func map_selector():
	map_refresh=MapSelection.build(self)

func internet_menu(scope:String="internet"):
	game.internet.scope=scope
	make_panel("내부망 로비" if scope=="lan" else "인터넷 로비",980);screen="internet"
	var service=game.internet
	if scope=="lan":label("웹 호환 내부망 방입니다. 참가자 모두 같은 로비 주소를 사용하세요. 브라우저는 UDP 자동 검색을 지원하지 않습니다.",17)
	var footer=HBoxContainer.new();footer.add_theme_constant_override("separation",12);stack.add_child(footer);pin_actions(footer)
	var address=edit("로비 서버",str(game.profile.get("lobby_url","")),func(_v):pass)
	address.placeholder_text="https://play.example.com"
	button("서버 연결",func():
		notice("로비 서버에 연결 중…")
		var result=await service.connect_service(address.text)
		if screen!="internet":return
		if result.has("error"):notice(result.error)
		else:internet_menu(scope),footer)
	if service.token.is_empty():
		label("운영 중인 로비 서버 주소를 입력하세요.\n서버 운영자는 저장소의 Docker/NAS 구성을 사용할 수 있습니다.",17)
	else:
		RoomFilters.build(self,stack,internet_filter,render_internet_rooms)
		var selected_mode=[-1]
		option("빠른 참가 모드",["모든 모드"]+Rules.MODES,0,func(i):selected_mode[0]=i-1)
		var actions=footer
		button("빠른 참가",func():
			notice("참가 가능한 경기를 찾는 중…")
			var result=await service.matchmake(selected_mode[0])
			if result.has("error"):notice(result.error)
			elif result.get("pending",false):wait_internet_room(result.room.id),actions)
		button("공개 방 만들기",internet_create,actions)
		button("목록 새로고침",refresh_internet_rooms)
		label("예상 핑은 로비까지의 왕복 시간과 방장 응답 시간을 합친 값입니다. 게임에서는 직접 연결 핑을 표시합니다.",16)
		room_list=VBoxContainer.new();stack.add_child(room_list)
		refresh_internet_rooms()
	notice_label=label("",17)
	# Connected rooms need start/create/back; reconnect lives above the list.
	if not service.token.is_empty():
		var connect=footer.get_child(0);connect.reparent(stack);stack.move_child(connect,3)
	button("메인메뉴",menu,footer)
func refresh_internet_rooms():
	if screen!="internet" or game.internet.token.is_empty():return
	var result=await game.internet.request("/v1/rooms?scope="+game.internet.scope)
	if screen!="internet" or not is_instance_valid(room_list):return
	if result.has("error"):notice(result.error);return
	internet_rooms=result.get("rooms",[])
	for room in internet_rooms:room.ping=-1 if room.get("host_rtt")==null else int(room.host_rtt)+game.internet.list_latency
	render_internet_rooms()
func render_internet_rooms():
	if screen!="internet" or not is_instance_valid(room_list):return
	for child in room_list.get_children():room_list.remove_child(child);child.queue_free()
	var selected=RoomFilters.select(internet_rooms,internet_filter)
	for room in selected:
		var row=HBoxContainer.new();room_list.add_child(row)
		var description=label("%s · %s · %d/%d\n%s · %s"%[room.name,Rules.MODES[int(room.mode)],room.players,room.capacity,Rules.MAPS[int(room.map)],"예상 %d ms"%int(room.ping) if int(room.ping)>=0 else "핑 측정 중"],17,row);description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var room_id=str(room.id)
		var join=button("준비 중" if room.phase=="starting" else "참가",func():
			game.options.password=""
			if room.get("locked",false):internet_password(room_id)
			else:wait_internet_room(room_id),row);join.disabled=room.phase=="starting" or int(room.players)>=int(room.capacity)
	if selected.is_empty():label("검색 조건에 맞는 방이 없습니다. 방을 만들거나 검색 조건을 바꿔 보세요.",17,room_list)
func internet_password(room_id:String):
	var dialog=ConfirmationDialog.new();dialog.title="방 비밀번호";dialog.ok_button_text="접속";dialog.cancel_button_text="돌아가기";root.add_child(dialog)
	var password=LineEdit.new();password.secret=true;password.placeholder_text="방 비밀번호";password.custom_minimum_size=Vector2(350,45);dialog.add_child(password)
	dialog.confirmed.connect(func():game.options.password=password.text;dialog.queue_free();wait_internet_room(room_id))
	dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(420,150));password.grab_focus()
func internet_create():
	make_panel("공개 방 만들기",880);screen="internet_create"
	var title=edit("방 이름",str(game.profile.nick)+"의 경기",func(_v):pass)
	edit("방 비밀번호 · 선택",str(game.options.get("password","")),func(value):game.options.password=value,true)
	option("게임 모드",Rules.MODES,game.options.mode,func(i):game.options.mode=i;if map_refresh.is_valid():map_refresh.call())
	map_selector()
	option("진행 경기 수",["무한","2판","4판","6판","10판"],maxi(0,[0,2,4,6,10].find(int(game.options.rounds))),func(i):game.options.rounds=[0,2,4,6,10][i])
	option("설치·해체 준비 시간",["30초","45초","60초"],maxi(0,[30,45,60].find(int(game.options.get("prep_seconds",45)))),func(i):game.options.prep_seconds=[30,45,60][i])
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions);pin_actions(actions)
	button("방 만들고 참가",func():
		Rules.sanitize_room(game.options)
		var result=await game.internet.request("/v1/rooms",{"name":title.text.left(40),"mode":int(game.options.mode),"map":int(game.options.map),"capacity":int(game.options.max_players),"map_random":bool(game.options.map_random),"map_rotation":bool(game.options.map_rotation),"rounds":int(game.options.rounds),"prep_seconds":int(game.options.prep_seconds),"scope":game.internet.scope,"locked":not str(game.options.password).is_empty()})
		if result.has("error"):notice(result.error)
		else:wait_internet_room(result.id),actions)
	notice_label=label("방장이 대기실에서 경기를 시작합니다.",17)
	button("돌아가기",func():internet_menu(game.internet.scope),actions)
func wait_internet_room(room_id:String):
	for i in range(30):
		if screen not in ["internet","internet_create"] or game.phase!="menu":return
		var result=await game.internet.join(room_id)
		if result.has("ticket"):return
		var message=str(result.get("error","연결 대기 중"));notice(message)
		if not message.contains("준비 중"):return
		await get_tree().create_timer(2.).timeout

func build_touch_main_actions():
	panel.position=Vector2(145,64);panel.custom_minimum_size=Vector2(1120,0)
	for child in background.get_children():
		if child is Label or child==version_box:child.hide()
	stack=VBoxContainer.new();stack.add_theme_constant_override("separation",14);panel.add_child(stack)
	label("INTERNAL N CRUSH",38)
	var nick=LineEdit.new();nick.text=game.profile.nick;nick.placeholder_text="닉네임";nick.max_length=20;nick.custom_minimum_size.y=64;nick.text_changed.connect(func(t):game.profile.nick=t;game.save_profile());stack.add_child(nick)
	for items in [[["내부망 로비",join_menu],["인터넷 로비",internet_menu]],[["봇 전투",practice_menu],["연습장",confirm_practice]],[["환경 설정",settings],["게임 페이지",func():OS.shell_open("https://nukcanon.github.io/nukcanon/internal-n-crush.html")]]]:
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);stack.add_child(row)
		for item in items:button(item[0],item[1],row).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label("왼손 이동 · 오른손 화면 조준 · 이동 스틱 끝까지 밀면 달리기",25)
