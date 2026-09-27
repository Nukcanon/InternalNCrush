extends RefCounted
class_name TeamBalance
static func host(g:Node,id:int) -> bool:
	if is_instance_valid(g.public_room) and g.public_room.enabled:return g.public_room.can_start(id)
	return id==1 or (id>0 and id==int(g.options.get("room_owner",0)))
static func allowed(g:Node,requester:int,target:int) -> bool:
	return requester==target or (target<0 and host(g,requester))
static func auto_ids(g:Node) -> Array:
	return g.players.keys().filter(func(id):return g.players[id].get("auto_balance",false))
static func remove_auto(g:Node,id:int):
	for did in g.devices.keys():
		if int(g.devices[did].owner)==id:g.remove_device(did)
	g.bot_agents.erase(id);g.players.erase(id)
	if g.actors.has(id):g.actors[id].queue_free();g.actors.erase(id)
static func reconcile(g:Node):
	if not g.server or g.demo_mode or int(g.options.mode)==1 or g.options.get("practice",false):return
	var autos=auto_ids(g);var counts=[0,0]
	for p in g.players.values():
		if not p.get("auto_balance",false):counts[int(p.team)]+=1
	var need=mini(absi(counts[0]-counts[1]),int(g.options.max_players)-counts[0]-counts[1])
	var target=0 if counts[0]<counts[1] else 1
	while autos.size()>need:remove_auto(g,int(autos.pop_back()))
	for index in range(need):
		var fresh=index>=autos.size();var id=int(autos[index]) if not fresh else -1000
		if fresh:
			while g.players.has(id):id-=1
			g.add_player(id,"BOT 균형","auto_balance_%d"%id);g.players[id].auto_balance=true
		g.players[id].team=target;g.bot_agents[id].difficulty=2;g.actors[id].set_team(target)
		if fresh and (g.phase in ["lobby","buy"] or (g.phase=="combat" and int(g.options.mode) in [0,1,3])):g.spawn(id)
static func can_move(g:Node,requester:int,target:int,team:int) -> bool:
	if not g.players.has(target) or team not in [0,1] or int(g.options.mode)==1 or not allowed(g,requester,target):return false
	if int(g.players[target].team)==team:return true
	var counts=[0,0]
	for p in g.players.values():
		if not p.get("auto_balance",false):counts[int(p.team)]+=1
	if g.players[target].get("auto_balance",false):return false
	counts[int(g.players[target].team)]-=1;counts[team]+=1
	return abs(counts[0]-counts[1])<=1 and maxi(counts[0],counts[1])<=int(g.options.max_players)/2
static func move(g:Node,requester:int,target:int,team:int) -> bool:
	if not can_move(g,requester,target,team):return false
	if int(g.players[target].team)==team:return true
	g.players[target].team=team;g.finish_team_change(target);reconcile(g);g.enforce_medics();g.broadcast_state(true);return true
