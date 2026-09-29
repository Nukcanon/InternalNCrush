extends SceneTree
# 1.3.5: people replace bots on join, one public room list with search button,
# equal filters, quick-join mode dialog, alternating rows and cached held items.
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func settle():
	for i in range(6):await process_frame
func key(code:int) -> InputEventKey:
	var event=InputEventKey.new();event.keycode=code;event.pressed=true;return event
func room(g:Node,max_players:int) -> Node:
	g.server=true;g.local_id=1;g.phase="lobby";g.options=Rules.default_options();g.options.map_random=false;g.options.max_players=max_players;g.options.mode=0
	g.players.clear();g.actors.clear();g.bot_agents.clear()
	return g
func clear(g:Node):
	for id in g.players.keys():TeamBalance.remove_auto(g,int(id))
	g.options.manual_roster=false
func run():
	Catalog.load_all()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	await settle()
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false
	room(g,8)
	# Host alone: a balance bot holds the other side and yields to the next person.
	g.add_player(1,"Host","host_v135",0);TeamBalance.reconcile(g)
	expect(TeamBalance.auto_ids(g).size()==1 and g.players[TeamBalance.auto_ids(g)[0]].team==1,"balance bot fills ORANGE for a lone BLUE host")
	var team=TeamBalance.admit(g)
	expect(team==1 and TeamBalance.auto_ids(g).is_empty(),"arriving person takes the balance bot seat")
	g.add_player(2,"Guest","guest_v135",team);TeamBalance.reconcile(g)
	expect(g.players[2].team==1 and g.players.size()==2,"guest joins ORANGE and no extra bot is created")
	# Full room of host-added bots: a person still gets in by replacing one.
	clear(g);g.add_player(1,"Host","host_v135",0)
	for i in range(7):RosterControls.add_bot(g,1,[1,0][i%2])
	expect(g.players.size()==8,"host filled the room with bots")
	team=TeamBalance.admit(g)
	expect(team in [0,1] and g.players.size()==7,"full bot room frees one bot seat for a person")
	g.add_player(3,"Late","late_v135",team)
	expect(g.players.size()==8 and g.players[3].team==team,"person takes the freed seat on that bot's team")
	var blue=0;var orange=0
	for p in g.players.values():
		if int(p.team)==0:blue+=1
		else:orange+=1
	expect(blue==4 and orange==4,"teams remain 4:4 after replacement")
	expect(TeamBalance.humans(g)==2,"room lists count people only")
	# Mid-match departure: the replacement bot yields to the next person.
	clear(g);g.options.mode=4;g.phase="combat"
	g.add_player(1,"Host","host_v135",0);g.add_player(2,"B","b_v135",0);g.add_player(6,"D","d_v135",1);g.add_player(4,"C","c_v135",1)
	var departed=g.players[4].duplicate(true);g.players.erase(4);g.actors[4].queue_free();g.actors.erase(4)
	TeamBalance.replace_departed(g,departed,Vector3.ZERO)
	expect(TeamBalance.replacement_ids(g).size()==1,"departure leaves a hard replacement bot")
	team=TeamBalance.admit(g)
	expect(team==1 and TeamBalance.replacement_ids(g).is_empty(),"new person replaces the departure bot on its team")
	# Only people: full means full.
	clear(g);g.options.mode=0;g.phase="lobby";g.options.max_players=2
	g.add_player(1,"Host","host_v135",0);g.add_player(5,"P","p_v135",1)
	expect(TeamBalance.admit(g)==-1,"room of people rejects further joins")
	# Online lobby layout.
	var ui=g.ui;g.phase="menu";g.players.clear()
	g.internet.token="test-token";g.internet.endpoint=""
	ui.internet_menu(false);await settle()
	var texts=ui.panel.find_children("*","Button",true,false).map(func(b):return b.text)
	expect(not texts.any(func(t):return "같은 네트워크" in t),"no same-network room button")
	expect(ui.panel.find_children("*","Label",true,false).all(func(l):return not "핑 미측정" in l.text),"ping note removed")
	expect(ui.panel.find_child("RoomSearchButton",true,false)!=null and ui.panel.find_child("RoomSearch",true,false).get_parent()==ui.panel.find_child("RoomSearchButton",true,false).get_parent(),"search button beside room name search")
	var filters=ui.panel.find_child("RoomFilterRow",true,false)
	var options=filters.get_children().filter(func(c):return c is OptionButton)
	var widths=options.map(func(c):return roundi(c.size.x))
	expect(options.size()==4 and widths.max()-widths.min()<=1,"mode, players, ping and sort share one row with equal widths %s"%str(widths))
	var refresh:Button=filters.get_child(filters.get_child_count()-1)
	expect(refresh.text=="새로고침" and refresh.get_theme_stylebox("normal").bg_color==UiSkin.PRIMARY,"yellow refresh button sits after the sort filter")
	var server_row=ui.panel.find_child("ServerRow",true,false)
	expect(server_row.get_child(0).text=="서버" and server_row.get_child(1) is LineEdit and server_row.get_child(2).text=="서버 연결" and server_row.get_child(2).get_theme_stylebox("normal").bg_color==UiSkin.PRIMARY,"server label, address and yellow connect button share one row")
	expect(not texts.has("목록 새로고침"),"full-width refresh button removed")
	var column=[server_row.get_child(2),ui.panel.find_child("RoomSearchButton",true,false),refresh]
	expect(column.all(func(b):return absf(b.size.x-column[0].size.x)<1. and absf(b.get_global_rect().end.x-column[0].get_global_rect().end.x)<1.),"connect, search and refresh buttons share one width and right edge")
	expect(ui.panel.find_children("*","OptionButton",true,false).size()==4,"quick-join mode selector removed from the lobby")
	ui.internet_rooms=[]
	for i in range(4):ui.internet_rooms.append({"id":"r%d"%i,"name":"방 %d"%i,"mode":0,"map":13,"players":1,"capacity":8,"phase":"lobby","ping":30})
	ui.render_internet_rooms();await settle()
	var cards=ui.room_list.get_children().filter(func(c):return c is PanelContainer)
	expect(cards.size()==4 and cards[0].get_theme_stylebox("panel").bg_color!=cards[1].get_theme_stylebox("panel").bg_color and cards[0].get_theme_stylebox("panel").bg_color==cards[2].get_theme_stylebox("panel").bg_color,"room rows alternate colors")
	var join:Button=cards[0].find_children("*","Button",true,false)[0]
	expect(join.size.x>=120 and join.get_global_rect().end.x<=cards[0].get_global_rect().end.x+.5,"join button keeps its width inside the row")
	# Quick join dialog: Escape returns, Enter joins.
	ui.panel.find_child("QuickJoin",true,false).pressed.emit();await settle()
	expect(is_instance_valid(ui.quick_join) and ui.quick_join.find_child("QuickJoinSubmit",true,false)!=null and ui.quick_join.find_child("QuickJoinBack",true,false)!=null,"quick join opens a mode dialog with join/back")
	expect(ui.quick_join.find_children("Mode*","Button",true,false).size()==Rules.MODES.size()+1,"dialog lists all modes plus any mode")
	ui.quick_join.find_child("Mode3",true,false).button_pressed=true
	expect(ui.quick_join_mode==2,"choosing a mode records it")
	expect(ui.menu_key(key(KEY_ESCAPE)) and not is_instance_valid(ui.quick_join) and ui.screen=="internet","Escape closes the dialog and stays in the lobby")
	ui.panel.find_child("QuickJoin",true,false).pressed.emit();await settle()
	expect(ui.menu_key(key(KEY_ENTER)) and not is_instance_valid(ui.quick_join),"Enter submits the dialog")
	await settle()
	ui.panel.find_child("RoomSearch",true,false).grab_focus()
	expect(not ui.menu_key(key(KEY_ENTER)),"Enter in the search box is left to the search field")
	g.internet.token=""
	# LAN lobby rows alternate and filters share one row.
	ui.join_menu();g.stop_room_search()
	for i in range(3):g.rooms["10.0.0.%d"%i]={"name":"LAN %d"%i,"count":1,"bots":3,"max":8,"mode":"팀 데스매치","version":Rules.VERSION}
	ui.update_rooms();await settle()
	var lan_cards=ui.room_list.get_children().filter(func(c):return c is PanelContainer)
	expect(lan_cards.size()==3 and lan_cards[0].get_theme_stylebox("panel").bg_color!=lan_cards[1].get_theme_stylebox("panel").bg_color,"LAN rows alternate colors")
	expect(ui.panel.find_child("RoomFilterRow",true,false).get_child_count()==4,"LAN filters share one row")
	var toolbar=ui.panel.find_child("LanToolbar",true,false)
	var order=toolbar.get_children().map(func(c):return c.text if c is Button else str(c.name))
	expect(order==["IP로 접속","새로고침","RoomSearch","검색하기"],"LAN toolbar: IP, refresh, search field, search button in one row %s"%str(order))
	expect(toolbar.get_node("RoomSearch").size.x>toolbar.get_child(0).size.x*2,"room search is the widest toolbar control")
	expect(not ui.panel.find_children("*","Button",true,false).any(func(b):return b.text=="웹 호환 로비"),"web-compatible lobby button removed")
	expect(lan_cards[0].find_children("*","Button",true,false)[0].text=="참가","bot-filled LAN room remains joinable")
	g.rooms.clear();ui.menu()
	# Waiting room: roster directly under the tool buttons; equal move-button text.
	room(g,8);g.add_player(1,"Host","host_v135",0);TeamBalance.reconcile(g)
	ui.lobby();await settle()
	var tools=ui.team_columns.get_parent().get_child(ui.team_columns.get_index()-1)
	expect(tools is HBoxContainer and tools.get_children().any(func(b):return b is Button and b.text=="팀 편성"),"team roster follows the tool buttons with no gap row")
	var moves=ui.team_columns.find_children("*","Button",true,false).filter(func(b):return b.text in ["→ ORANGE","← BLUE"])
	expect(moves.size()==2 and moves[0].get_theme_font_size("font_size")==moves[1].get_theme_font_size("font_size") and moves[0].get_theme_font_size("font_size")==14,"BLUE and ORANGE move buttons use the same text size")
	g.players.clear();g.phase="menu";ui.menu()
	# Held items are built once and then reused.
	var holder=Node3D.new();root.add_child(holder)
	var first=GadgetVisual.new();holder.add_child(first);first.build(3,0,false,false)
	var start=Time.get_ticks_usec();var second=GadgetVisual.new();holder.add_child(second);second.build(3,0,false,false)
	expect((Time.get_ticks_usec()-start)/1000.<10. and second.get_child_count()==first.get_child_count() and second.right_socket==first.right_socket and second.two_handed,"repeated gadget selection reuses the finished assembly")
	holder.free()
	print("LOBBY_V135 ",checks," checks / ",failures," failures")
	g.queue_free();await process_frame;quit(1 if failures else 0)
