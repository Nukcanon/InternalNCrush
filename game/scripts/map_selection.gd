extends RefCounted
class_name MapSelection
static func build(ui) -> Callable:
	var game=ui.game;var count=ui.option("참가 정원",[],0);var scale=ui.option("전장 규모",[],0);var map=ui.option("전장",[],0)
	count.name="PlayerCapacity";scale.name="MapCapacity";map.name="MapChoice"
	var update_maps=func():
		var sizes=[]
		for capacity in [6,8,12,16,32]:
			if capacity>=int(game.options.max_players) and not Rules.maps_for_size(capacity,int(game.options.mode)).is_empty():sizes.append(capacity)
		var desired=int(game.options.get("map_size",8));scale.clear()
		for capacity in sizes:scale.add_item("%d인용 전장"%capacity,capacity)
		if not desired in sizes:desired=sizes[0]
		scale.select(sizes.find(desired));game.options.map_size=desired;map.clear();map.add_item("%d인용 무작위 맵"%desired,-1)
		var choices=Rules.maps_for_size(desired,int(game.options.mode))
		for index in choices:map.add_item(Rules.MAPS[index],index)
		if not int(game.options.map) in choices:game.options.map=choices[0]
		map.select(0 if game.options.get("map_random",true) else choices.find(int(game.options.map))+1)
	var refresh=func():
		game.options.max_players=clampi(int(game.options.max_players)/2*2,2,12 if int(game.options.mode)==4 else 32);count.clear()
		for capacity in range(2,13 if int(game.options.mode)==4 else 33,2):count.add_item("%d명"%capacity,capacity)
		count.select(int(game.options.max_players)/2-1);update_maps.call()
	count.item_selected.connect(func(i):game.options.max_players=count.get_item_id(i);game.options.bots=mini(int(game.options.bots),int(game.options.max_players)-1);update_maps.call())
	scale.item_selected.connect(func(i):game.options.map_size=scale.get_item_id(i);game.options.map_random=true;update_maps.call())
	map.item_selected.connect(func(i):
		game.options.map_random=i==0
		if i>0:game.options.map=map.get_item_id(i))
	ui.check("무작위 맵 순환",bool(game.options.get("map_rotation",false)),func(value):game.options.map_rotation=value)
	ui.label("정원 이상의 전장만 표시합니다. 무작위 선택 시 같은 규모의 전장이 순환합니다.\n점령·설치/해체는 양 진영을 한 번씩 진행한 뒤 전장을 바꿉니다.",14)
	refresh.call();return refresh
