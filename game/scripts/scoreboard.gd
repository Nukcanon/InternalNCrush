extends PanelContainer
class_name MatchScoreboard
var game:Node
var columns:HBoxContainer
var timer=0.
func _ready():
	position=Vector2(65,108);custom_minimum_size=Vector2(1150,520);mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new();style.bg_color=Color("101e2c");style.set_corner_radius_all(16);style.set_content_margin_all(20);style.border_color=Color("344d62");style.set_border_width_all(1);add_theme_stylebox_override("panel",style)
	var main=VBoxContainer.new();add_child(main);var title=Label.new();title.text="경기 기록   /   TAB";title.add_theme_font_size_override("font_size",24);main.add_child(title)
	columns=HBoxContainer.new();columns.add_theme_constant_override("separation",18);main.add_child(columns)
func refresh_scores(dt=.016):
	timer-=dt
	if timer>0:return
	timer=.3
	for c in columns.get_children():columns.remove_child(c);c.queue_free()
	var players=game.players.values();players.sort_custom(func(a,b):return a.kills>b.kills if a.kills!=b.kills else a.deaths<b.deaths)
	for side in range(2):
		var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",2);columns.add_child(box)
		var ffa=int(game.options.mode)==1;var color=Color("5bbfff") if side==0 else Color("ff9a54")
		var title=Label.new();title.text=("개인전 순위  1–16" if side==0 else "개인전 순위  17–32") if ffa else ("◆ BLUE" if side==0 else "● ORANGE")+"   ·   "+str(game.scores[side])+"점";title.add_theme_color_override("font_color",Color("dbe8f2") if ffa else color);title.add_theme_font_size_override("font_size",20);box.add_child(title)
		row(box,["플레이어","병과","K","D","A","목표"],false,true)
		var count=0
		for i in range(players.size()):
			var p=players[i]
			if (ffa and i/16!=side) or (not ffa and p.team!=side):continue
			row(box,[(str(i+1)+". " if ffa else "")+p.nick+ ("  · 나" if p.id==game.local_id else ""),Rules.CLASSES[p.role] if game.options.classes else "—",str(p.kills),str(p.deaths),str(p.assists),str(p.objective)],p.id==game.local_id,false,not p.alive);count+=1
		if count==0:var empty=Label.new();empty.text="참가자 없음";empty.modulate=Color("8497aa");box.add_child(empty)
func row(parent:Node,values:Array,highlight:bool,header=false,inactive=false):
	var panel=PanelContainer.new();var style=StyleBoxFlat.new();style.bg_color=Color("244863") if highlight else Color("223447") if header else Color("18293a");style.set_corner_radius_all(5);style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=2;style.content_margin_bottom=2;panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",8);panel.add_child(line)
	for i in range(values.size()):
		var l=Label.new();l.text=values[i];l.add_theme_font_size_override("font_size",16);l.modulate=Color("cad9e5") if inactive else Color.WHITE;l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		if i==0:l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.custom_minimum_size.x=140
		else:l.custom_minimum_size.x=48 if i==1 else 33;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		line.add_child(l)
		if i==0 and inactive:
			var dead=Label.new();dead.text="Dead";dead.add_theme_font_size_override("font_size",14);dead.modulate=Color("b5c2cf");line.add_child(dead)
