extends PanelContainer
class_name MatchScoreboard
var game:Node
var columns:BoxContainer
var timer=0.
var last_signature=""
var lineup:WinnerLineup
var body:VBoxContainer
var map_card:MapPlanView
var layout:BoxContainer
var records_scroll:ScrollContainer
var pinned=false
var close_button:Button
func editable() -> bool:return BotSettings.allowed(game,game.local_id)
func shown() -> bool:return pinned or game.phase=="result" or (not editable() and (Input.is_action_pressed("score") or (is_instance_valid(game.touch) and game.touch.held.get("score",false))))
func toggle():
	pinned=not pinned
	visible=shown()
	if pinned:
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if is_instance_valid(game.touch):game.touch.reset()
		refresh_scores(1.)
	else:game.capture_pointer(true)
func close():
	pinned=false;visible=false
	game.capture_pointer(true)
func _input(event):
	if is_instance_valid(game.ui.panel) or is_instance_valid(game.ui.map_viewer):return
	if event.is_action("score"):
		if event.is_echo():get_viewport().set_input_as_handled();return
		if editable():
			if event.is_pressed():toggle()
		elif event.is_pressed():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		else:game.capture_pointer(true)
		get_viewport().set_input_as_handled();return
	if pinned and TouchControls.supported() and event is InputEventScreenTouch and event.pressed:
		for control in find_children("*","OptionButton",true,false):
			if control.get_popup().visible:return
		var point=get_global_transform_with_canvas().affine_inverse()*event.position
		if not Rect2(Vector2.ZERO,size).has_point(point):close();get_viewport().set_input_as_handled()
func _ready():
	position=Vector2(30,76);custom_minimum_size=Vector2(1220,590);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=80
	var style=StyleBoxFlat.new();style.bg_color=Color("101e2c");style.set_corner_radius_all(16);style.set_content_margin_all(20);style.border_color=Color("344d62");style.set_border_width_all(1);add_theme_stylebox_override("panel",style)
	var main=VBoxContainer.new();add_child(main)
	var heading=HBoxContainer.new();main.add_child(heading)
	var caption=Label.new();caption.text="경기 기록 · 팀 편성";caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(caption)
	close_button=Button.new();close_button.text="×";close_button.tooltip_text="닫기 (Tab)";close_button.custom_minimum_size=Vector2(48,40);close_button.pressed.connect(close);heading.add_child(close_button)
	lineup=WinnerLineup.new();lineup.game=game;main.add_child(lineup)
	layout=BoxContainer.new();layout.vertical=false;layout.add_theme_constant_override("separation",18);main.add_child(layout)
	var scroll=ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.custom_minimum_size=Vector2(520,280 if layout.vertical else 420);layout.add_child(scroll)
	records_scroll=scroll
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body);var title=Label.new();title.text="기록 · 처치 100 · 도움 75 · 치료 1HP당 0.6 · 설치 80 · 목표 50 · 사망 −25";title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.add_theme_font_size_override("font_size",16);body.add_child(title)
	columns=VBoxContainer.new();columns.add_theme_constant_override("separation",18);body.add_child(columns)

func refresh_scores(dt=.016):

	lineup.refresh();position.y=15 if game.phase=="result" else 76
	custom_minimum_size.y=650 if game.phase=="result" else 590
	close_button.visible=game.phase!="result"
	records_scroll.custom_minimum_size.y=260 if game.phase=="result" else 280 if layout.vertical else 420
	size.y=custom_minimum_size.y
	timer-=dt
	if timer>0:return
	timer=.3
	var state=[game.options.mode,game.scores,game.phase]
	for p in game.players.values():state.append([p.id,p.nick,p.team,p.role,p.get("bot_role",p.role),p.get("bot_difficulty",2),p.alive,p.kills,p.deaths,p.assists,p.healed,p.get("builds",0),p.get("objective",0)])
	var signature=str(state)
	if signature==last_signature:return
	for control in find_children("*","OptionButton",true,false):
		if control.get_popup().visible:return
	last_signature=signature
	for c in columns.get_children():columns.remove_child(c);c.queue_free()
	RosterControls.populate(game,columns,true)
func row(parent:Node,values:Array,highlight:bool,header=false,inactive=false):
	var panel=PanelContainer.new();var style=StyleBoxFlat.new();style.bg_color=Color("244863") if highlight else Color("223447") if header else Color("18293a");style.set_corner_radius_all(5);style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=2;style.content_margin_bottom=2;panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",4);panel.add_child(line)
	for i in range(values.size()):
		var l=Label.new();l.text=values[i];l.add_theme_font_size_override("font_size",14);l.modulate=Color("cad9e5") if inactive else Color.WHITE;l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		if i==0:l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.custom_minimum_size.x=110
		else:l.custom_minimum_size.x=48 if i==1 else 40 if i>=4 else 24;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		line.add_child(l)
		if i==0 and inactive:
			var dead=Label.new();dead.text="Dead";dead.add_theme_font_size_override("font_size",14);dead.modulate=Color("b5c2cf");line.add_child(dead)
