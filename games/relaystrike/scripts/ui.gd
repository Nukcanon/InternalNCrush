extends CanvasLayer
const Reticle=preload("res://scripts/reticle.gd")
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
var role_detail:Label
var team_columns:HBoxContainer
var team_signature=""
var scoreboard:MatchScoreboard
var kill_feed:KillFeed
var damage_indicator:DamageIndicator
func _ready():
	root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	damage_indicator=DamageIndicator.new();damage_indicator.game=game;root.add_child(damage_indicator)
	theme=Theme.new();theme.default_font_size=20
	if ResourceLoader.exists("res://assets/Korean.ttf"):
		var font=FontVariation.new();font.base_font=load("res://assets/Korean.ttf");font.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):650.0};font.variation_embolden=.2;theme.default_font=font
	var style=StyleBoxFlat.new();style.bg_color=Color("122536");style.border_color=Color("2c4554");style.set_border_width_all(1);style.set_corner_radius_all(14);style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=12;style.content_margin_bottom=12
	theme.set_stylebox("panel","PanelContainer",style)
	var btn=style.duplicate();btn.bg_color=Color("26465c");theme.set_stylebox("normal","Button",btn)
	var hov=btn.duplicate();hov.bg_color=Color("376887");theme.set_stylebox("hover","Button",hov)
	var pressed=btn.duplicate();pressed.bg_color=Color("247fba");theme.set_stylebox("pressed","Button",pressed)
	for type in ["OptionButton","LineEdit","SpinBox"]:
		theme.set_stylebox("normal",type,btn);theme.set_stylebox("hover",type,hov);theme.set_stylebox("focus",type,pressed)
	var disabled=btn.duplicate();disabled.bg_color=Color("20313e");theme.set_stylebox("disabled","Button",disabled)
	theme.set_color("font_color","Label",Color("e8f2f3"));theme.set_color("font_color","Button",Color("e8f2f3"));root.theme=theme
	theme.set_color("font_outline_color","Label",Color(0.01,0.025,0.04,.65));theme.set_constant("outline_size","Label",1)
func clear_panel():
	if is_instance_valid(vote_panel):vote_panel.visible=false
	screen="";game.stop_room_search();team_signature=""
	if is_instance_valid(background):background.queue_free();background=null
	if panel:panel.queue_free();panel=null
func make_panel(title:String,width=780):
	clear_panel();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);panel.position=Vector2(-width/2.,-325);panel.custom_minimum_size=Vector2(width,0);root.add_child(panel)
	panel_body=VBoxContainer.new();panel_body.add_theme_constant_override("separation",14);panel.add_child(panel_body)
	var scroll=ScrollContainer.new();panel_scroll=scroll;scroll.custom_minimum_size=Vector2(width-40,560);panel_body.add_child(scroll)
	stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",12);scroll.add_child(stack)
	var eyebrow=Label.new();eyebrow.text="NUKCANON  /  INTERNAL N CRUSH";eyebrow.add_theme_color_override("font_color",Color("5ce1c3"));eyebrow.add_theme_font_size_override("font_size",14);stack.add_child(eyebrow)
	label(title,30)
func pin_actions(node:Control):
	node.get_parent().remove_child(node);panel_body.add_child(node)
	panel_scroll.custom_minimum_size.y=535
func label(text:String,size=20,parent:Node=null) -> Label:
	var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",maxi(17,size));l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;(parent if parent else stack).add_child(l);return l
func button(text:String,callback:Callable,parent:Node=null) -> Button:
	var b=Button.new();b.text=text;b.custom_minimum_size.y=42;b.pressed.connect(func():game.play_sound("ui",Vector3.ZERO,false);callback.call());(parent if parent else stack).add_child(b);return b
func option(title:String,items:Array,selected:int,callback:Callable=Callable(),parent:Node=null) -> OptionButton:
	var row=HBoxContainer.new();(parent if parent else stack).add_child(row);var l=Label.new();l.text=title;l.custom_minimum_size.x=155;row.add_child(l)
	var b=OptionButton.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for s in items:b.add_item(str(s))
	if not items.is_empty():b.select(clampi(selected,0,items.size()-1))
	row.add_child(b)
	if callback.is_valid():b.item_selected.connect(callback)
	return b
func check(title:String,value:bool,callback:Callable) -> CheckBox:
	var b=CheckBox.new();b.text=title;b.button_pressed=value;b.toggled.connect(callback);stack.add_child(b);return b
func edit(title:String,value:String,callback:Callable,secret=false) -> LineEdit:
	var row=HBoxContainer.new();stack.add_child(row);var l=Label.new();l.text=title;l.custom_minimum_size.x=155;row.add_child(l);var e=LineEdit.new();e.text=value;e.secret=secret;e.size_flags_horizontal=Control.SIZE_EXPAND_FILL;e.text_changed.connect(callback);row.add_child(e);return e
func menu():
	if not root or game.demo_mode:return
	game.stop_room_search()
	if hud:hud.queue_free();hud=null
	clear_panel();screen="menu";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	background=Control.new();background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(background)
	if DisplayServer.get_name()!="headless":
		var live=load("res://scripts/menu_demo.gd").new();live.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(live)
	var shade=ColorRect.new();shade.color=Color(.015,.04,.065,.36);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(shade)
	var brand=Label.new();brand.text="NUKCANON  /  TACTICAL LAN FPS";brand.position=Vector2(68,102);brand.add_theme_font_size_override("font_size",19);brand.modulate=Color("7be4cd");background.add_child(brand)
	var title=Label.new();title.text="INTERNAL\nN CRUSH";title.position=Vector2(62,166);title.add_theme_font_size_override("font_size",72);background.add_child(title)
	var intro=Label.new();intro.text="함께 짜는 전술, 맞붙는 화력.\n32인 LAN 전투 · 6개 병과 · 19개 전장";intro.position=Vector2(68,400);intro.add_theme_font_size_override("font_size",22);intro.modulate=Color("d6e5ed");background.add_child(intro)
	version_box=VBoxContainer.new();version_box.position=Vector2(68,545);version_box.custom_minimum_size.x=560;background.add_child(version_box)
	panel=PanelContainer.new();panel.position=Vector2(748,38);panel.custom_minimum_size=Vector2(456,0);root.add_child(panel)
	stack=VBoxContainer.new();stack.add_theme_constant_override("separation",9);panel.add_child(stack)
	var name=label("닉네임",19);name.modulate=Color("a7c5d4")
	var nick=LineEdit.new();nick.text=game.profile.nick;nick.placeholder_text="게임에서 사용할 닉네임";nick.max_length=20;nick.custom_minimum_size.y=47;nick.text_changed.connect(func(t):game.profile.nick=t;game.save_profile());stack.add_child(nick)
	stack.add_child(HSeparator.new());label("플레이",25)
	button("방 만들기",host_settings)
	button("내부망 방 찾기",join_menu)
	if not game.last_server_ip.is_empty():button("최근 서버 재접속",func():game.join_game(game.last_server_ip))
	button("봇 연습",practice_menu)
	stack.add_child(HSeparator.new());label("설정",25)
	button("화면 · 조작 · 소리",settings)
	stack.add_child(HSeparator.new());button("게임 종료",func():game.exit_game())
	notice_label=label("",17);update_version_badge()
func update_version_badge():
	if screen!="menu" or not is_instance_valid(version_box):return
	for child in version_box.get_children():version_box.remove_child(child);child.queue_free()
	var version=label("WINDOWS  /  v"+Rules.VERSION,18,version_box);version.modulate=Color("b2c8d5")
	if game.version_check.state=="newer":
		var warning=label("새 버전 "+game.version_check.latest+"이 있습니다.\n함께 접속할 사람들과 버전을 맞춰 주세요.",18,version_box);warning.modulate=Color("ffd18d")
		button("최신 버전 다운로드",func():OS.shell_open(VersionCheck.PAGE),version_box)
func practice_menu():
	make_panel("봇 연습")
	game.options.bots=maxi(3,int(game.options.bots))
	option("난이도",["하 · 반응과 조준을 완화","중 · 목표와 지원 역할 수행","상 · 빠른 반응, 사격·후퇴 판단 강화"],game.options.get("bot_difficulty",1),func(i):game.options.bot_difficulty=i)
	option("봇 인원",["3명","5명","7명","15명","31명"],maxi(0,[3,5,7,15,31].find(game.options.bots)),func(i):game.options.bots=[3,5,7,15,31][i])
	option("게임 모드",Rules.MODES,game.options.mode,func(i):game.options.mode=i)
	map_selector()
	label("장애물 우회 · 목표 수행 · 회복/수리 · 가젯/스킬 사용\n체력, 탄약, 최근 교전 상황에 따라 행동을 바꿉니다.",16)
	button("연습 시작",func():game.options.max_players=32;game.host_game();game.start_match())
	button("돌아가기",menu)
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
	option("게임 모드",Rules.MODES,game.options.mode,func(i):game.options.mode=i)
	map_selector()
	option("경기 시간",["5분","10분","15분","20분"],[5,10,15,20].find(game.options.minutes),func(i):game.options.minutes=[5,10,15,20][i])
	option("목표 점수",["30","60","100","200"],[30,60,100,200].find(game.options.target),func(i):game.options.target=[30,60,100,200][i])
	stack=groups[1]
	option("최대 인원",["6","8","16","24","32"],[6,8,16,24,32].find(game.options.max_players),func(i):game.options.max_players=[6,8,16,24,32][i])
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
	stack=outer;var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions);button("이 설정으로 방 만들기",func():game.host_game(),actions);button("뒤로",menu,actions);pin_actions(actions);notice_label=label("",14)
func join_menu():
	make_panel("내부망 접속")
	screen="join"
	var ip=edit("서버 IP",game.last_server_ip if not game.last_server_ip.is_empty() else "192.168.0.10",func(_v):pass)
	edit("방 비밀번호",game.options.password,func(t):game.options.password=t,true)
	button("IP로 접속",func():game.join_game(ip.text))
	button("목록 새로고침",func():game.search_rooms())
	room_list=VBoxContainer.new();stack.add_child(room_list)
	label("검색되지 않으면 서버 IP로 접속하세요. UDP 27888·27889 사용.",15)
	notice_label=label("주변 방 자동 검색 중… · 3초마다 갱신",14)
	button("연결 취소",func():game.leave_game("연결을 취소했습니다."))
	button("뒤로",menu)
	game.search_rooms()
func update_rooms():
	if not is_instance_valid(room_list):return
	for n in room_list.get_children():n.queue_free()
	if game.rooms.is_empty():label("검색된 방이 아직 없습니다. 서버 IP로도 접속할 수 있습니다.",15,room_list)
	for ip in game.rooms:
		var d=game.rooms[ip];var b=button(str(d.name)+"  ·  "+str(d.count)+"/"+str(d.max)+"  ·  "+ip,func():game.join_game(ip),room_list)
		b.disabled=str(d.version)!=Rules.VERSION
		if b.disabled:b.text+="  · 버전 다름"
func lobby():
	make_panel("대기실 · "+str(game.options.room),1100);screen="lobby"
	label(Rules.MODES[int(game.options.mode)]+"   ·   "+("스킬 ON" if game.options.skills else "스킬 OFF")+"   ·   최대 "+str(game.options.max_players)+"명",16)
	if game.server:
		var ips=[]
		for ip in IP.get_local_addresses():
			if "." in ip and not ip.begins_with("127."):ips.append(ip)
		label("접속 주소  "+", ".join(ips),15)
	label("대기실: 내 팀 선택 가능 · 방장: 모든 참가자 배치 가능",14)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions)
	button("병과 · 무기 · 가젯",gear,actions);button("팀 편성",teams_menu,actions);button("참가자 관리",members_menu,actions)
	if game.server:button("경기 시작",func():game.start_match(),actions)
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
		else:clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
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
	button("취소",func():
		if game.phase=="lobby":lobby()
		else:teams_menu())
func settings():
	make_panel("환경 설정",980);screen="settings"
	var outer=stack;var tabs=section_tabs(["화면 · 조준","소리","조작법"]);stack=tabs[0]
	var displays=[]
	for i in range(DisplayServer.get_screen_count()):
		var native=DisplayServer.screen_get_size(i)
		displays.append("모니터 %d · %d × %d · %.0f Hz"%[i+1,native.x,native.y,DisplayServer.screen_get_refresh_rate(i)])
	var monitor=option("출력 모니터",displays,int(game.profile.monitor))
	var mode=option("화면 모드",["창 모드","전체 화면 (테두리 없음)","전체 화면 (독점)"],maxi(0,int(game.profile.display_mode)))
	var resolutions=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1920,1200),Vector2i(2560,1080),Vector2i(2560,1440),Vector2i(2560,1600),Vector2i(3440,1440),Vector2i(3840,1600),Vector2i(3840,2160),Vector2i(5120,1440),Vector2i(5120,2880),Vector2i(7680,2160),Vector2i(7680,4320)]
	for i in range(DisplayServer.get_screen_count()):
		var native=DisplayServer.screen_get_size(i)
		if not native in resolutions:resolutions.append(native)
	var current=game.display_window_size()
	if not current in resolutions:resolutions.append(current)
	var names=[]
	for size in resolutions:names.append("%d × %d"%[size.x,size.y])
	var resolution=option("창 해상도",names,resolutions.find(current))
	var dimensions=HBoxContainer.new();stack.add_child(dimensions)
	var dimension_label=label("직접 입력",18,dimensions);dimension_label.custom_minimum_size.x=125;dimension_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	var width=SpinBox.new();width.min_value=640;width.max_value=32768;width.value=current.x;width.custom_minimum_size.x=190;width.size_flags_vertical=Control.SIZE_SHRINK_CENTER;dimensions.add_child(width)
	var times_label=label("×",18,dimensions);times_label.custom_minimum_size.x=25;times_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	var height=SpinBox.new();height.min_value=360;height.max_value=32768;height.value=current.y;height.custom_minimum_size.x=190;height.size_flags_vertical=Control.SIZE_SHRINK_CENTER;dimensions.add_child(height)
	resolution.item_selected.connect(func(i):width.value=resolutions[i].x;height.value=resolutions[i].y)
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
	label("전체 화면은 선택한 모니터의 원본 해상도를 사용합니다. 창 크기는 해당 화면의 작업 영역 안에 맞춥니다.",17)
	sensitivity_control("마우스 감도",float(game.profile.sensitivity)/.0023,.15,4.,func(v):game.profile.sensitivity=v*.0023;game.save_profile())
	sensitivity_control("정조준 감도 배율",float(game.profile.ads_sensitivity),.2,1.5,func(v):game.profile.ads_sensitivity=v;game.save_profile())
	label("화면과 감도 설정은 다음 실행에도 유지됩니다.",14)
	stack=tabs[1]
	button("피격음 미리 듣기 · 둔탁한 충격",func():game.play_sound("hurt",Vector3.ZERO,false))
	button("방어구 피격음 미리 듣기",func():game.play_sound("armor_hurt",Vector3.ZERO,false))
	sound_slider("전체 음량", "volume")
	label("총소리·발소리·전투 효과는 전체 음량에 함께 적용됩니다.",17)
	sound_slider("명중 알림", "hit_volume")
	sound_slider("메뉴 소리", "ui_volume")
	var samples=HBoxContainer.new();stack.add_child(samples);button("총소리 미리 듣기",func():game.play_sound("gun_a1",Vector3.ZERO,false),samples);button("발소리 미리 듣기",func():game.play_sound("step_stone_0",Vector3.ZERO,false),samples)
	stack=tabs[2]
	var diagram=ControlsDiagram.new();diagram.custom_minimum_size=Vector2(885,415);stack.add_child(diagram)
	label("E 길게: 설치·해체  /  F: 스킬 · 포탑 강화  /  Q: 의료 카빈 회복\nG: 가젯 즉시 사용  /  V: 가젯 종류  /  F6·F7: 강퇴 투표",18)
	stack=outer
	var back=button("돌아가기",func():
		if game.phase=="menu":menu()
		elif game.phase=="lobby":lobby()
		else:clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
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
		else:clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
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
	make_panel("장비 선택",1160);screen="gear";preview_kind=0;preview_secondary=false
	label("크레딧은 구매 시간에 사용 · 전투 중 변경은 다음 라운드 예약" if game.options.mode==4 else "전투 중 선택한 장비는 다음 부활에 적용됩니다.",15)
	var outer=stack;var split=HBoxContainer.new();split.add_theme_constant_override("separation",26);outer.add_child(split)
	var form=VBoxContainer.new();form.custom_minimum_size.x=540;form.size_flags_horizontal=Control.SIZE_EXPAND_FILL;form.add_theme_constant_override("separation",10);split.add_child(form);stack=form
	gear_class=option("병과",["돌격 · 소총","정찰 · 저격 / 지정사수","중화기 · 기관총","공병 · 샷건 / 구조물","통제 · 기관단총","메딕 · 회복 / 지원"],chosen,func(_i):preview_kind=0;refresh_weapons())
	gear_class.disabled=not game.options.classes
	gear_primary=option("주무기",[],0,func(_i):preview_kind=1;preview_secondary=false;refresh_gear_detail())
	gear_armor=option("방어구",["없음","경량 +25"+(" · 300" if game.options.mode==4 else ""),"중량 +50"+(" · 600" if game.options.mode==4 else "")],int(queued.get("armor",int(p.armor_max)/25)),func(_i):refresh_gear_detail())
	gear_gadget=option("가젯 구성",[],0,func(_i):preview_kind=2;refresh_gear_detail())
	gear_repair=check("권총 대신 FIX 수리 도구",queued.get("repair",p.secondary=="repair"),func(_v):preview_kind=1;preview_secondary=true;refresh_gear_detail())
	role_detail=label("",15);role_detail.modulate=Color("8fcbed")
	gear_detail=label("",15);gear_detail.modulate=Color("d2e2ec")
	gear_price=label("",18)
	var right=VBoxContainer.new();right.custom_minimum_size.x=445;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",8);split.add_child(right)
	var tabs=HBoxContainer.new();right.add_child(tabs)
	for i in range(4):
		var choice=i;var tab=button(["캐릭터","주무기","보조","가젯"][i],func():preview_kind=[0,1,1,2][choice];preview_secondary=choice==2;refresh_gear_detail(),tabs);tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	preview_widget=EquipmentPreview.new();right.add_child(preview_widget)
	preview_caption=label("",16,right);label("마우스로 끌어 회전할 수 있습니다.",13,right)
	stack=outer
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);outer.add_child(actions);pin_actions(actions)
	gear_submit=button("선택 적용",func():
		if not weapon_ids.is_empty():game.command("loadout",selected_loadout()),actions)
	button("돌아가기",func():
		if game.phase=="lobby":lobby()
		else:clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED,actions)
	notice_label=label("",14);notice_label.modulate=Color("80cfef")
	refresh_weapons()
	var wanted=queued.get("primary",p.primary)
	if wanted in weapon_ids:gear_primary.select(weapon_ids.find(wanted))
	gear_gadget.select(mini(gear_gadget.item_count-1,int(queued.get("gadget",p.gadget))));refresh_gear_detail()
func selected_loadout() -> Dictionary:
	return {"role":gear_class.selected,"primary":weapon_ids[gear_primary.selected],"armor":gear_armor.selected,"gadget":gear_gadget.selected,"repair":gear_repair.button_pressed}
func refresh_weapons():
	gear_primary.clear();weapon_ids=[]
	for id in Catalog.list_for(gear_class.selected,game.options.classes):
		var w=Catalog.get_weapon(id)
		if not game.options.classes and w.kind!="gun":continue
		weapon_ids.append(id);gear_primary.add_item(w.name)
	if is_instance_valid(gear_gadget):
		gear_gadget.clear()
		var items=["기본 가젯"]
		if gear_class.selected==3:items=["경량 엄폐물 · 250 내구도","표준 엄폐물 · 500 내구도","강화 엄폐물 · 800 내구도"]
		elif gear_class.selected==4:items=["연막 2 + 섬광 1","연막 1 + 섬광 2"]
		else:items=[Rules.GADGETS[gear_class.selected]]
		for item in items:gear_gadget.add_item(item)
		gear_repair.visible=gear_class.selected==3
	refresh_gear_detail()
func refresh_gear_detail():
	if not is_instance_valid(gear_detail) or weapon_ids.is_empty():return
	var w=Catalog.get_weapon(weapon_ids[gear_primary.selected]);var role=gear_class.selected
	var mode={"auto":"연발","semi":"단발","burst":"3점사"}.get(w.get("fire_mode","auto"),"")
	var secondary="FIX" if role==3 and gear_repair.button_pressed else Catalog.get_weapon(Rules.SECONDARIES[role]).name
	gear_detail.text="%s  ·  피해 %d%s  ·  탄창 %d  ·  재장전 %.1f초\n2 보조무기: %s\n3 가젯: %s\nF 스킬: %s"%[mode,w.damage," × "+str(int(w.pellets)) if w.pellets>1 else "",w.mag,w.reload,secondary,Rules.GADGET_HELP[role],Rules.SKILL_HELP[role]]
	gear_detail.text+="\n예비탄 %d  ·  분당 %d발  ·  피해 감소 시작 %.0fm"%[w.reserve,60./maxf(.01,float(w.interval)),w.reach]
	role_detail.text="체력 100  ·  기본 방어구 0  ·  걷기 %.1f / 달리기 %.1fm/s\n%s"%[6.66 if int(w.role)==2 else 7.4,10.08 if int(w.role)==2 else 11.2,["소총으로 전선을 유지하고 보호판과 기동 사용","저격총·지정사수소총으로 원거리 지원 및 표식","기관총·거치대 사용. 무거운 주무기는 이동 10% 감소","샷건·엄폐물·포탑. 수리 도구는 권총을 대신함","기관단총과 연막·섬광으로 이동 경로 통제","LINK 지속 회복 / PIPER 전투 회복탄 2초 간격"][role]]
	if w.kind=="heal":gear_detail.text="LINK · 피해 없음 · 회복 24/초 · 거리 10m\n에너지 180 · 회복 중인 아군 중복 회복 제한\n"+Rules.GADGET_HELP[role]+"\n"+Rules.SKILL_HELP[role]
	if not game.options.skills:gear_detail.text+=" (스킬 OFF)"
	if not game.options.classes:gear_detail.text+="\n병과 OFF · 가젯/스킬 없이 공격 무기 사용"
	var p=game.players[game.local_id];var cost=game.loadout_cost(p,selected_loadout())
	gear_price.text="예상 비용 %d / 보유 %d 크레딧"%[cost,p.cash] if game.options.mode==4 else "장비 선택 무료 · 기본 체력 100 / 기본 방어구 없음"
	if is_instance_valid(preview_widget):
		var preview_id=("repair" if role==3 and gear_repair.button_pressed else Rules.SECONDARIES[role]) if preview_kind==1 and preview_secondary else weapon_ids[gear_primary.selected]
		preview_widget.display(preview_kind,role,int(p.team),preview_id,gear_gadget.selected)
		preview_caption.text=[Rules.CLASSES[role]+" · "+CharacterVisual.ROLE_NAMES[role],str(w.name),Rules.GADGETS[role]][preview_kind]
		if preview_kind==1 and preview_secondary:
			var sw=Catalog.get_weapon(preview_id)
			preview_caption.text="FIX · 구조물 수리 · 에너지 100" if sw.kind=="repair" else "%s · 피해 %d · 탄창 %d · 재장전 %.1f초"%[sw.name,sw.damage,sw.mag,sw.reload]
	gear_submit.text="구매하기" if game.phase=="buy" else "장비 적용" if game.phase=="lobby" else "다음 부활에 적용 예약" if game.options.mode!=4 else "다음 라운드 구매 예약"
func toggle_pause():
	if is_instance_valid(panel):clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;return
	make_panel("일시 메뉴 · 경기는 계속 진행됩니다.",680)
	if game.phase=="lobby":button("대기실로 돌아가기",lobby)
	button("게임으로 돌아가기",func():clear_panel();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
	button("병과 · 무기 · 가젯",gear);button("팀 편성",teams_menu);button("참가자 관리",members_menu);button("환경 설정",settings);button("방 나가기",func():game.request_leave())
func hud_label(text:String,pos:Vector2,size:int=20) -> Label:
	var l=Label.new();l.text=text;l.position=pos;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_shadow_color",Color(0,0,0,.8));l.add_theme_constant_override("shadow_offset_x",1);l.add_theme_constant_override("shadow_offset_y",2);hud.add_child(l);return l
func hud_plate(pos:Vector2,size:Vector2) -> Panel:
	var plate=Panel.new();plate.position=pos;plate.size=size;var style=StyleBoxFlat.new();style.bg_color=Color(.035,.075,.1,.86);style.set_corner_radius_all(10);plate.add_theme_stylebox_override("panel",style);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(plate);return plate
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
	stats=hud_label("",Vector2(1062,18),17)
	hud_plate(Vector2(22,595),Vector2(259,98));health=hud_label("",Vector2(40,607),22)
	health_bar=hud_bar(Vector2(40,648),Color("68dcc0"));armor_bar=hud_bar(Vector2(40,665),Color("7aafdc"))
	hud_plate(Vector2(995,577),Vector2(263,116));weapon_title=hud_label("",Vector2(1012,589),16);ammo=hud_label("",Vector2(1012,615),30)
	banner=hud_label("",Vector2(34,96),17)
	info=hud_label("",Vector2(305,686),16)
	skill_label=hud_label("",Vector2(313,590),16)
	slots=[];slot_panels=[]
	for i in range(4):
		var plate=hud_plate(Vector2(305+i*169,622),Vector2(161,54));slot_panels.append(plate)
		var l=hud_label("",Vector2(317+i*169,631),16);slots.append(l)
	crosshair=hud_label("",Vector2(0,0),1)
	reticle=Reticle.new();reticle.game=game;reticle.ui=self;reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(reticle)
	kill_feed=KillFeed.new();hud.add_child(kill_feed)
	scoreboard=MatchScoreboard.new();scoreboard.game=game;hud.add_child(scoreboard);scoreboard.visible=false
	flash_overlay=ColorRect.new();flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);flash_overlay.color=Color(.055,.065,.08,0);flash_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(flash_overlay)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func notice(message:String):
	if message.is_empty():return
	notice_until=Time.get_ticks_msec()+3500
	if is_instance_valid(notice_label):notice_label.text=message
	if game.phase=="menu" and message.contains("버전"):
		var dialog=AcceptDialog.new();dialog.title="게임 버전 확인";dialog.dialog_text=message;dialog.ok_button_text="확인";root.add_child(dialog);dialog.add_button("다운로드",false,"download");dialog.custom_action.connect(func(action):
			if action=="download":OS.shell_open(VersionCheck.PAGE))
		dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(680,210))
	if is_instance_valid(banner):banner.text=message
func refresh():
	refresh_vote();refresh_members()
	if screen in ["lobby","teams"]:refresh_teams()
	if not is_instance_valid(hud) or not game.players.has(game.local_id):return
	var p=game.players[game.local_id];var a=game.actors[game.local_id];var wid=p.primary if p.slot==0 else p.secondary;var w=Catalog.get_weapon(wid)
	kill_feed.refresh(game.kill_events,game.local_id,Time.get_ticks_msec())
	stats.text="%d FPS  ·  %s"%[Engine.get_frames_per_second(),"HOST" if game.server else str(game.ping_ms)+" ms"]
	var secs=maxi(0,int(game.remaining));status.text="BLUE %d    %02d:%02d    %d ORANGE"%[game.scores[0],secs/60,secs%60,game.scores[1]]
	health.text=("◆ BLUE  " if p.team==0 else "● ORANGE  ")+"%d HP"%p.hp if p.alive else "Dead · 관전" if game.options.mode==4 or p.spectator else "Dead · 부활 %.0f초"%maxf(0,p.respawn-game.clock)
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
	skill_label.text="F  "+Rules.SKILLS[p.role]+"  ·  "+skill if game.options.skills and game.options.classes else "특수 스킬 OFF"
	if p.primary=="m2":skill_label.text+="     Q 회복 %d  ·  2초 간격"%p.heal_mag
	if p.get("mounted",0)>game.clock:skill_label.text+="     거치대 %.0f초"%(p.mounted-game.clock)
	if p.shield>game.clock:skill_label.text+="     방호 활성"
	var labels=["1  "+Catalog.get_weapon(p.primary).name,"2  "+Catalog.get_weapon(p.secondary).name,"3  "+(Rules.GADGETS[p.role] if p.role!=4 else "연막탄")+" ×"+str(p.gadget_count if p.role!=4 else p.smoke),"4  "+("섬광탄 ×"+str(p.flash_count) if p.role==4 else "—")]
	for i in range(4):
		slots[i].text=labels[i];slots[i].modulate=Color("6eebc7") if p.slot==i else Color("b6cbd4")
		slot_panels[i].self_modulate=Color("75cebb") if p.slot==i else Color.WHITE
		if i>=2 and not game.options.classes:slots[i].text=str(i+1)+"  사용 안 함"
	info.text="B 장비 선택   ·   E 상호작용   ·   TAB 기록   ·   ESC 설정"
	if game.options.mode==4:info.text+="   ·   %d 크레딧"%p.cash
	if not p.get("pending_loadout",{}).is_empty():info.text+="   ·   다음 부활 장비 예약됨"
	if not p.alive:info.text="마우스: 관전 시점   ·   클릭: 관전 대상 변경   ·   B 다음 장비 선택"
	reticle.queue_redraw()
	flash_overlay.color.a=clampf((p.flash-game.clock)/2.5,0,.96)
	if p.alive and p.protect>game.clock:banner.text="부활 보호 %.1f초 · 공격 대기"%(p.protect-game.clock)
	elif p.flash>game.clock:banner.text="섬광 · 시야 회복 중"
	elif game.phase=="buy":banner.text="구매 시간 · B로 무기·방어구·가젯 구매"
	elif game.bomb.planted:banner.text="장치 작동까지 %.1f초 · 해체 E 유지"%game.bomb.time
	elif game.bomb.actor==game.local_id:banner.text="상호작용 %.1f초"%game.bomb.progress
	elif Time.get_ticks_msec()>notice_until:banner.text=""
	scoreboard.visible=Input.is_action_pressed("score") or game.phase=="result"
	if scoreboard.visible:scoreboard.refresh_scores()

func map_selector():
	var counts=[6,8,16,32];var selected=Rules.MAP_PLAYERS[clampi(int(game.options.map),0,Rules.MAPS.size()-1)]
	label("맵 권장 인원",18)
	var size_choice=OptionButton.new();size_choice.custom_minimum_size.y=40;stack.add_child(size_choice)
	for count in counts:size_choice.add_item("%d인용 · %d개 맵"%[count,Rules.maps_for_size(count).size()])
	size_choice.select(counts.find(selected))
	var map_choice=OptionButton.new();map_choice.custom_minimum_size.y=42;stack.add_child(map_choice)
	var populate=func(count):
		map_choice.clear()
		for index in Rules.maps_for_size(count):map_choice.add_item(Rules.MAPS[index],index)
		for i in range(map_choice.item_count):
			if map_choice.get_item_id(i)==int(game.options.map):map_choice.select(i)
	populate.call(selected)
	size_choice.item_selected.connect(func(i):game.options.map=Rules.maps_for_size(counts[i])[0];populate.call(counts[i]))
	map_choice.item_selected.connect(func(i):game.options.map=map_choice.get_item_id(i))
	label("권장 인원에 맞춘 전장 크기입니다. 참가 인원은 별도로 설정합니다.",15)
