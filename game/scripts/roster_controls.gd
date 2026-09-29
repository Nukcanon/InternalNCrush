class_name RosterControls
extends RefCounted
static func row_panel(parent:Node,index:int) -> PanelContainer:
	var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style=UiSkin.card(index,6)
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel);return panel
static func small_button(parent:Node,text:String,callback:Callable) -> Button:
	var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,64 if TouchControls.supported() else 30);b.add_theme_font_size_override("font_size",22 if TouchControls.supported() else 14);b.pressed.connect(callback);parent.add_child(b);return b
static func add_bot(g:Node,requester:int,team:int):
	if not g.server or not TeamBalance.host(g,requester) or team not in [0,1]:return
	if g.players.size()>=int(g.options.max_players) or (int(g.options.mode)!=1 and g.team_count(team)>=int(g.options.max_players)/2):g.feedback(requester,"","참가 정원이 가득 찼습니다.",true);return
	g.options.manual_roster=true
	var id=-1
	while g.players.has(id):id-=1
	g.add_player(id,"BOT %02d"%absi(id),"manual_bot_%d"%absi(id));var p=g.players[id];p.team=team;p.auto_balance=false;p.bot_difficulty=2;g.bot_agents[id].difficulty=2;g.actors[id].set_team(team)
	if g.phase in ["lobby","buy"] or (g.phase=="combat" and int(g.options.mode) in [0,1,3]):g.spawn(id)
	g.broadcast_state(true)
static func remove_bot(g:Node,requester:int,target:int):
	if not g.server or not TeamBalance.host(g,requester) or target>=0 or not g.players.has(target):return
	g.options.manual_roster=true;TeamBalance.remove_auto(g,target);g.broadcast_state(true)
static func populate(g:Node,parent:Node,results:bool):
	var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",6);parent.add_child(grid)
	var teams=[[],[]];var players=g.players.values();players.sort_custom(func(a,b):return Rules.score(a)>Rules.score(b) if results else int(a.id)>int(b.id))
	for p in players:
		var side=int(p.team) if int(g.options.mode)!=1 else (0 if teams[0].size()<16 else 1)
		if side in [0,1]:teams[side].append(p)
	for side in range(2):
		var h=HBoxContainer.new();grid.add_child(h);var title=Label.new();title.text=("BLUE" if side==0 else "ORANGE")+" · %d명"%teams[side].size();title.add_theme_color_override("font_color",Color("2f7fd8") if side==0 else Color("e0741a"));title.add_theme_font_size_override("font_size",20);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;h.add_child(title)
		if results:title.text+=" · %d%s"%[g.scores[side],"승" if int(g.options.mode)==4 else "점"]
		if TeamBalance.host(g,g.local_id):
			var team=side;var add=small_button(h,"+ 봇",func():g.command("bot_add",{"team":team}));add.disabled=g.players.size()>=int(g.options.max_players) or (int(g.options.mode)!=1 and g.team_count(side)>=int(g.options.max_players)/2)
	for index in range(maxi(teams[0].size(),teams[1].size())):
		for side in range(2):
			var panel=row_panel(grid,index);var cell=HBoxContainer.new();cell.custom_minimum_size=Vector2(380,64);cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(cell)
			if index>=teams[side].size():continue
			var p=teams[side][index];var pid=int(p.id);var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_child(left)
			var title=preload("res://scripts/scrolling_name.gd").new();title.display_text=str(p.nick)+(" · 나" if pid==g.local_id else "")+" · "+Rules.CLASSES[p.role]+(" · %d/%d · %d점"%[p.kills,p.deaths,Rules.score(p)] if results else "");title.font_size=15;title.custom_minimum_size=Vector2(190,30);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.add_child(title)
			if pid<0 and BotSettings.allowed(g,g.local_id):
				var actions=HBoxContainer.new();left.add_child(actions);BotSettings.controls(g,actions,p)
				for control in actions.get_children():control.custom_minimum_size=Vector2(104 if control.name=="BotRole" else 78,30);control.add_theme_font_size_override("font_size",14)
				small_button(actions,"제거",func():g.command("bot_remove",{"target":pid}))
			if results:
				var detail=small_button(cell,"기록",func():
					var d=AcceptDialog.new();d.title=str(p.nick)+" · 상세 기록";d.dialog_text="처치 %d / 사망 %d\n도움점 %d · 치료점 %d\n설치점 %d · 목표점 %d"%[p.kills,p.deaths,Rules.score_parts(p).assists,Rules.score_parts(p).healing,Rules.score_parts(p).builds,Rules.score_parts(p).objectives];g.ui.root.add_child(d);d.confirmed.connect(d.queue_free);d.canceled.connect(d.queue_free);DialogStyle.apply(d,g.ui.theme);DialogStyle.popup(d))
				detail.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			if int(g.options.mode)!=1 and TeamBalance.allowed(g,g.local_id,pid):
				var target=1-side;var full=g.team_count(target)>=int(g.options.max_players)/2
				var move=small_button(cell,"교환" if full and TeamBalance.host(g,g.local_id) else "→ ORANGE" if target==1 else "← BLUE",func():
					if full and TeamBalance.host(g,g.local_id):g.ui.team_swap_menu(pid)
					else:g.command("team",{"player_id":pid,"team":target}))
				move.tooltip_text="ORANGE로 이동" if target==1 else "BLUE로 이동";move.custom_minimum_size.x=112;move.size_flags_vertical=Control.SIZE_EXPAND_FILL;move.disabled=not TeamBalance.can_move(g,g.local_id,pid,target) and not (full and TeamBalance.host(g,g.local_id))
				if not (full and TeamBalance.host(g,g.local_id)):UiSkin.paint(move,"orange" if target==1 else "blue")
				# Narrow margins let "→ ORANGE" keep the same 14 px text as "← BLUE".
				compact(g,move)
static func compact(g:Node,b:Button):
	for state in ["normal","hover","pressed","disabled"]:
		var style=b.get_theme_stylebox(state).duplicate();style.content_margin_left=6;style.content_margin_right=6;b.add_theme_stylebox_override(state,style)
