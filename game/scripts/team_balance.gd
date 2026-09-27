extends RefCounted
class_name TeamBalance
static func host(g:Node,id:int) -> bool:
	return id==1 or id==int(g.options.get("room_owner",0)) or (is_instance_valid(g.public_room) and g.public_room.enabled and g.public_room.can_start(id))
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
	var need=(counts[0]+counts[1])%2==1 and counts[0]+counts[1]<int(g.options.max_players)
	var target=0 if counts[0]<counts[1] else 1
	if not need:
		for id in autos:remove_auto(g,id)
		return
	var id=int(autos.pop_front()) if not autos.is_empty() else -1000
	for extra in autos:remove_auto(g,extra)
	if not g.players.has(id):
		while g.players.has(id):id-=1
		g.add_player(id,"BOT 균형","auto_balance_%d"%id);g.players[id].auto_balance=true
	g.players[id].team=target;g.bot_agents[id].difficulty=2;g.actors[id].set_team(target)
	if g.phase=="lobby":g.spawn(id)
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
