class_name LanLobby
extends RefCounted

var ui:Node
var room_scroll:ScrollContainer
var actions:HBoxContainer
var create_button:Button
var ip_button:Button
var refresh_button:Button
var cancel_button:Button
var dialog:Control
var address:LineEdit
var password:LineEdit
var connect_button:Button
var dialog_notice:Label
var last_address=""

func _init(owner_ui:Node):
	ui=owner_ui

func show():
	ui.make_panel("내부망 로비",1100);ui.screen="join"
	# Only the room list scrolls; the title, connection status and actions stay visible.
	ui.stack.reparent(ui.panel_body);ui.panel_body.move_child(ui.stack,0)
	ui.panel_scroll.queue_free();ui.panel_scroll=null
	ui.panel.position.y=63;ui.panel.custom_minimum_size.y=632
	ui.stack.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ui.stack.add_theme_constant_override("separation",8)
	var hint=ui.label("같은 네트워크의 방에 참가하거나 새로운 방을 만드세요.",18)
	hint.modulate=Color("a7bacb")
	var tools=HBoxContainer.new();tools.add_theme_constant_override("separation",10);ui.stack.add_child(tools)
	ip_button=ui.button("IP로 접속",func():show_direct(),tools)
	refresh_button=ui.button("목록 새로고침",func():ui.game.search_rooms();ui.notice("방 목록을 새로 검색합니다."),tools)
	var heading=HBoxContainer.new();ui.stack.add_child(heading)
	column(heading,"방 이름 / 게임 모드",0,true)
	column(heading,"인원",85)
	column(heading,"접속 주소",190)
	column(heading,"참가",112)
	room_scroll=ScrollContainer.new();room_scroll.name="RoomsScroll"
	room_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	room_scroll.custom_minimum_size.y=280;room_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ui.stack.add_child(room_scroll)
	ui.room_list=VBoxContainer.new();ui.room_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ui.room_list.add_theme_constant_override("separation",8);room_scroll.add_child(ui.room_list)
	ui.notice_label=ui.label("자동 검색 중 · 3초마다 갱신됩니다.",17)
	ui.notice_label.custom_minimum_size.y=26
	actions=HBoxContainer.new();actions.name="LobbyActions";actions.add_theme_constant_override("separation",10);ui.panel_body.add_child(actions)
	create_button=ui.button("방 만들기",ui.host_settings,actions);accent(create_button)
	cancel_button=ui.button("연결 취소",cancel_connection,actions)
	cancel_button.tooltip_text="서버에 접속하는 동안 연결 시도를 중단합니다."
	ui.button("메인메뉴",back_to_menu,actions)
	for child in actions.get_children():child.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	refresh_connection();ui.game.search_rooms()

func column(parent:Node,text:String,width:float,expand=false) -> Label:
	var item=ui.label(text,17,parent);item.autowrap_mode=TextServer.AUTOWRAP_OFF
	item.custom_minimum_size.x=width;item.modulate=Color("9ab0c4")
	if expand:item.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return item

func accent(target:Button):
	for state in ["normal","hover","pressed"]:
		var style=ui.theme.get_stylebox(state,"Button").duplicate()
		style.bg_color=Color("dc9c43") if state=="normal" else Color("f5bd64") if state=="hover" else Color("bd7d2d")
		style.border_color=Color("ffcd7a");target.add_theme_stylebox_override(state,style)
		target.add_theme_color_override("font_color" if state=="normal" else "font_"+state+"_color",Color("182330"))

func update_rooms():
	if ui.screen!="join" or not is_instance_valid(ui.room_list):return
	var scroll_position=room_scroll.scroll_vertical
	for item in ui.room_list.get_children():ui.room_list.remove_child(item);item.queue_free()
	if ui.game.rooms.is_empty():
		var empty=VBoxContainer.new();empty.custom_minimum_size.y=225;empty.alignment=BoxContainer.ALIGNMENT_CENTER;ui.room_list.add_child(empty)
		var title=ui.label("열린 방을 찾고 있습니다",24,empty);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var help=ui.label("방을 만들거나 IP로 직접 접속할 수 있습니다.",18,empty);help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;help.modulate=Color("9ab0c4")
	var ips=ui.game.rooms.keys();ips.sort()
	for ip in ips:
		var data:Dictionary=ui.game.rooms[ip]
		var card=PanelContainer.new();ui.room_list.add_child(card)
		var style=StyleBoxFlat.new();style.bg_color=Color("172535");style.set_corner_radius_all(3)
		style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8;card.add_theme_stylebox_override("panel",style)
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
		var names=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(names)
		var title=ui.label(str(data.get("name","이름 없는 방")).left(40),20,names)
		title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var locked=bool(data.get("locked",false))
		var mode=ui.label(str(data.get("mode",""))+("  ·  비밀번호 필요" if locked else "  ·  공개 방"),17,names);mode.modulate=Color("9ab0c4")
		column(row,"%d / %d"%[int(data.get("count",0)),int(data.get("max",0))],73)
		column(row,str(ip),178)
		var incompatible=str(data.get("version",""))!=Rules.VERSION
		var full=int(data.get("count",0))>=int(data.get("max",0))
		var join=ui.button("버전 다름" if incompatible else "정원 초과" if full else "참가",func():
			if locked:show_direct(ip,str(data.get("name","")))
			else:ui.game.options.password="";ui.game.join_game(ip);refresh_connection(),row)
		join.custom_minimum_size.x=112;join.disabled=incompatible or full or ui.game.connection_busy
		if incompatible:join.tooltip_text="방 버전: "+str(data.get("version",""))+" / 내 버전: "+Rules.VERSION
	room_scroll.set_deferred("scroll_vertical",scroll_position)

func show_direct(ip="",room_name=""):
	if ui.game.connection_busy:return
	close_dialog()
	dialog=Control.new();dialog.name="DirectConnect";dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dialog.z_index=100;ui.root.add_child(dialog)
	var dim=ColorRect.new();dim.color=Color(0.01,.02,.04,.8);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dialog.add_child(dim)
	var box=PanelContainer.new();box.set_anchors_and_offsets_preset(Control.PRESET_CENTER);box.position=Vector2(-320,-220);box.custom_minimum_size=Vector2(640,0);dialog.add_child(box)
	var content=VBoxContainer.new();content.add_theme_constant_override("separation",16);box.add_child(content)
	ui.label("IP로 접속" if room_name.is_empty() else "비밀번호가 있는 방",30,content)
	var hint=ui.label("접속할 서버의 IP와 방 비밀번호를 입력하세요." if room_name.is_empty() else room_name.left(40),18,content);hint.modulate=Color("a7bacb")
	address=field(content,"서버 IP",false);address.name="ServerIP";address.placeholder_text="예: 192.168.0.10";address.max_length=45
	address.text=ip if not ip.is_empty() else last_address if not last_address.is_empty() else ui.game.last_server_ip if ui.game.last_server_ip.is_valid_ip_address() else ""
	password=field(content,"방 비밀번호 · 선택",true);password.name="RoomPassword";password.placeholder_text="비밀번호가 없는 방은 비워 두세요";password.max_length=64
	dialog_notice=ui.label("",17,content);dialog_notice.custom_minimum_size.y=46
	var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",12);content.add_child(buttons)
	connect_button=ui.button("접속",submit_direct,buttons);connect_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;accent(connect_button)
	var back=ui.button("돌아가기",back_from_direct,buttons);back.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	address.text_submitted.connect(func(_text):submit_direct());password.text_submitted.connect(func(_text):submit_direct())
	if not room_name.is_empty():password.grab_focus()
	else:address.grab_focus()

func field(parent:Node,title:String,secret:bool) -> LineEdit:
	var column_box=VBoxContainer.new();column_box.add_theme_constant_override("separation",6);parent.add_child(column_box)
	ui.label(title,18,column_box)
	var input=LineEdit.new();input.custom_minimum_size.y=48;input.secret=secret;column_box.add_child(input);return input

func submit_direct():
	if ui.game.connection_busy:return
	var ip=address.text.strip_edges()
	if not ip.is_valid_ip_address():dialog_notice.text="올바른 서버 IP를 입력하세요. 예: 192.168.0.10";address.grab_focus();return
	last_address=ip;ui.game.options.password=password.text
	ui.game.join_game(ip);refresh_connection()

func close_dialog():
	if is_instance_valid(dialog):dialog.hide();dialog.queue_free()
	dialog=null;address=null;password=null;dialog_notice=null;connect_button=null

func back_from_direct():
	if is_instance_valid(address):last_address=address.text
	if ui.game.connection_busy:cancel_connection()
	else:close_dialog()

func cancel_connection():
	if ui.game.connection_busy:ui.game.leave_game("연결을 취소했습니다. 다른 방에 참가할 수 있습니다.")

func back_to_menu():
	if ui.game.connection_busy:ui.game.leave_game()
	ui.menu()

func refresh_connection():
	if ui.screen!="join":return
	var busy=ui.game.connection_busy
	for target in [create_button,ip_button,refresh_button]:
		if is_instance_valid(target):target.disabled=busy
	if is_instance_valid(cancel_button):cancel_button.disabled=not busy
	if is_instance_valid(connect_button):
		connect_button.disabled=busy;connect_button.text="접속 중…" if busy else "접속"
		address.editable=not busy;password.editable=not busy

func notice(message:String):
	if is_instance_valid(dialog_notice):dialog_notice.text=message
