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
static func build(ui:Node,parent:Node,filter:Dictionary,changed:Callable):
	var first=HBoxContainer.new();first.add_theme_constant_override("separation",10);parent.add_child(first)
	var name=LineEdit.new();name.placeholder_text="방 이름 검색";name.text=str(filter.name);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;first.add_child(name)
	name.text_changed.connect(func(value):filter.name=value;changed.call())
	var mode=OptionButton.new();first.add_child(mode);mode.add_item("모든 게임 모드")
	for item in Rules.MODES:mode.add_item(item)
	mode.select(int(filter.mode)+1);mode.item_selected.connect(func(value):filter.mode=value-1;changed.call())
	var players=OptionButton.new();first.add_child(players)
	for item in ["인원 전체","빈 방","1–4명","5–8명","9–16명","17–32명"]:players.add_item(item)
	players.select(int(filter.players));players.item_selected.connect(func(value):filter.players=value;changed.call())
	var second=HBoxContainer.new();second.add_theme_constant_override("separation",10);parent.add_child(second)
	var ping=OptionButton.new();second.add_child(ping)
	for item in ["핑 제한 없음","50 ms 이하","100 ms 이하","150 ms 이하","250 ms 이하"]:ping.add_item(item)
	ping.select(maxi(0,[0,50,100,150,250].find(int(filter.ping))));ping.item_selected.connect(func(value):filter.ping=[0,50,100,150,250][value];changed.call())
	var sort=OptionButton.new();second.add_child(sort)
	for item in ["방 이름순","낮은 핑순","많은 인원순","적은 인원순"]:sort.add_item(item)
	sort.select(int(filter.sort));sort.item_selected.connect(func(value):filter.sort=value;changed.call())
	var note=ui.label("핑 미측정 방은 핑 제한 검색에서 제외됩니다.",16,second);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
