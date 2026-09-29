class_name RoomFilters
extends RefCounted
static func defaults() -> Dictionary:return {"name":"","mode":-1,"players":0,"ping":0,"sort":0}
static func select(rooms:Array,filter:Dictionary) -> Array:
	var selected=[];var ranges=[[0,32],[0,0],[1,4],[5,8],[9,16],[17,32]]
	var span=ranges[clampi(int(filter.players),0,5)]
	for room in rooms:
		if not str(filter.name).strip_edges().is_empty() and not str(room.name).to_lower().contains(str(filter.name).strip_edges().to_lower()):continue
		if int(filter.mode)>=0 and int(room.mode)!=int(filter.mode):continue
		if int(room.players)<span[0] or int(room.players)>span[1]:continue
		if int(filter.ping)>0 and (int(room.get("ping",-1))<0 or int(room.ping)>int(filter.ping)):continue
		selected.append(room)
	selected.sort_custom(func(a,b):
		var primary=0
		match int(filter.sort):
			1:primary=(99999 if int(a.get("ping",-1))<0 else int(a.ping))-(99999 if int(b.get("ping",-1))<0 else int(b.ping))
			2:primary=int(b.players)-int(a.players)
			3:primary=int(a.players)-int(b.players)
		if primary==0:return str(a.name).naturalnocasecmp_to(str(b.name))<0
		return primary<0)
	return selected
# Row 1: name search (widest) with an explicit search button; callers may pass
# their own toolbar row to share it. Row 2: four equal-width filters. The name
# filter applies on the button or Enter, not on every key.
static func build(ui:Node,parent:Node,filter:Dictionary,changed:Callable,search:Callable=Callable(),first:HBoxContainer=null) -> Dictionary:
	if first==null:first=HBoxContainer.new();first.add_theme_constant_override("separation",10);parent.add_child(first)
	var name=LineEdit.new();name.name="RoomSearch";name.placeholder_text="방 이름 검색";name.text=str(filter.name);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.custom_minimum_size.y=ui.ACTION_HEIGHT;first.add_child(name)
	var submit=func():
		filter.name=name.text.strip_edges()
		if search.is_valid():search.call()
		else:changed.call()
	var button=tool_button(ui,first,"검색하기",submit,true);button.name="RoomSearchButton"
	name.text_submitted.connect(func(_value):submit.call())
	var second=HBoxContainer.new();second.name="RoomFilterRow";second.add_theme_constant_override("separation",10);parent.add_child(second)
	var mode=choice(second,["모든 게임 모드"]+Rules.MODES,int(filter.mode)+1,func(value):filter.mode=value-1;changed.call())
	mode.name="ModeFilter"
	choice(second,["인원 전체","빈 방","1–4명","5–8명","9–16명","17–32명"],int(filter.players),func(value):filter.players=value;changed.call()).name="PlayerFilter"
	choice(second,["핑 제한 없음","50 ms 이하","100 ms 이하","150 ms 이하","250 ms 이하"],maxi(0,[0,50,100,150,250].find(int(filter.ping))),func(value):filter.ping=[0,50,100,150,250][value];changed.call()).name="PingFilter"
	choice(second,["방 이름순","낮은 핑순","많은 인원순","적은 인원순"],int(filter.sort),func(value):filter.sort=value;changed.call()).name="SortFilter"
	return {"toolbar":first,"filters":second,"search":name}
# Buttons stacked in one right-hand column share the widest text width so their
# edges line up (online lobby: connect / search / refresh).
static func match_widths(buttons:Array):
	var widest=0.
	for b in buttons:widest=maxf(widest,b.get_combined_minimum_size().x)
	for b in buttons:b.custom_minimum_size.x=widest
# Toolbar buttons are as wide as their text; primary actions use the yellow accent.
static func tool_button(ui:Node,parent:Node,text:String,callback:Callable,accent:bool=false) -> Button:
	var b=ui.button(text,callback,parent);b.clip_text=false;b.custom_minimum_size.x=0;b.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	b.set_meta("auto_text_fit",true) # keep full text; never shrink to fit
	if accent:ui.lan_lobby.accent(b)
	return b
static func choice(parent:Node,items:Array,selected:int,callback:Callable) -> OptionButton:
	var option=OptionButton.new();option.fit_to_longest_item=false;option.clip_text=true
	option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option.size_flags_stretch_ratio=1.;option.custom_minimum_size=Vector2(1,48 if not TouchControls.supported() else 64)
	for item in items:option.add_item(str(item))
	option.select(clampi(selected,0,items.size()-1));option.item_selected.connect(callback);parent.add_child(option)
	return option
# Alternating list rows make adjacent rooms easy to tell apart.
static func row_style(index:int) -> StyleBoxFlat:
	var style=UiSkin.card(index)
	style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8
	return style
