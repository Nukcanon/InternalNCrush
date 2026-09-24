extends RefCounted
class_name MatchFlow
static func attackers(game) -> int:return maxi(0,game.round_no-1)%2
static func rotate(game):
	if not (game.options.get("map_random",false) or game.options.get("map_rotation",false)):return
	game.options.map=Rules.random_map(game.options,int(game.options.map));game.build_world()
	for id in game.players:
		if id<0:
			var bot=BotAgent.new();bot.setup(game,id);game.bot_agents[id]=bot
	game.zone_owner=[-1,-1,-1];game.zone_capture=[0.,0.,0.]
static func preparation(game,id:int):
	if int(game.options.mode)!=4 or game.phase!="buy" or not game.arena.has_meta("staging_z"):return
	var a=game.actors[id];var boundary=float(game.arena.get_meta("staging_z"));var before=a.position
	if int(game.players[id].team)==attackers(game):
		a.position.z=maxf(a.position.z,boundary+1.2);a.position.x=clampf(a.position.x,-8.5,8.5)
	else:a.position.z=minf(a.position.z,boundary-5.)
	if before!=a.position:a.velocity=Vector3.ZERO
static func update_gate(game):
	if not is_instance_valid(game.arena) or not game.arena.has_meta("staging_z"):return
	var gate=game.arena.get_node_or_null("PreparationGate")
	if game.phase!="buy":
		if is_instance_valid(gate):game.arena.remove_child(gate);gate.queue_free()
		return
	if is_instance_valid(gate):return
	gate=StaticBody3D.new();gate.name="PreparationGate";gate.collision_layer=1;game.arena.add_child(gate);gate.position=Vector3(0,4.,float(game.arena.get_meta("staging_z"))-.8)
	var size=Vector3(game.arena.bounds.x*2.,8.,.35);var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size;shape.shape=box;gate.add_child(shape)
	MeshFactory.box(gate,Vector3.ZERO,size,Color("385564"));game.arena.text3d("PREPARATION / 출입 통제",Vector3(0,3.,1.),Color("82dfca"),35,gate)
static func at_limit(game) -> bool:return int(game.options.rounds)>0 and game.completed_games>=int(game.options.rounds)
static func return_to_lobby(game):
	game.phase="lobby";game.announce("설정한 경기 수를 완료했습니다.");game.ui.lobby();game.broadcast_state(true)
