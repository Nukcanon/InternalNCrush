extends RefCounted
class_name MatchFlow
static func attackers(game) -> int:
	if game.round_no>int(game.options.rounds):return int(game.overtime_attacker)
	return 0 if game.round_no<=int(game.options.rounds)/2 else 1
static func rotate(game):
	if not (game.options.get("map_random",false) or game.options.get("map_rotation",false)):return
	game.options.map=Rules.random_map(game.options,int(game.options.map));game.build_world()
	for id in game.players:
		if id<0:
			var bot=BotAgent.new();bot.setup(game,id);game.bot_agents[id]=bot
	game.zone_owner=[-1,-1,-1];game.zone_capture=[0.,0.,0.];game.zone_counts=[[0,0],[0,0],[0,0]]
static func spawn_rect(game:Node,team:int) -> Rect2:
	var side=0 if team==attackers(game) else 1
	var spec=DefusalLayout.spec(int(game.options.map))
	var half=Vector2(9.2,6.2) if side==0 else Vector2(4.2,4.2)
	var center:Vector2=spec.points[side]
	if is_instance_valid(game.arena) and game.arena.has_meta("district"):
		center=game.arena.get_meta("district_spawns")[side]
	return Rect2(center-half,half*2.)
static func protected_spawn(game:Node,id:int) -> bool:
	if int(game.options.mode)!=4 or not DefusalLayout.enabled(int(game.options.map)) or not game.actors.has(id):return false
	var pos:Vector3=game.actors[id].position
	return spawn_rect(game,int(game.players[id].team)).has_point(Vector2(pos.x,pos.z))
static func preparation(game,id:int):
	var actor=game.actors[id];actor.collision_mask=1|4|8
	if int(game.options.mode)!=4 or not DefusalLayout.enabled(int(game.options.map)):return
	var team=int(game.players[id].team);var enemy_rect=spawn_rect(game,1-team).grow(1.2)
	actor.collision_mask|=16 if team==1 else 32
	var point=Vector2(actor.position.x,actor.position.z);var previous=point
	if game.phase=="buy" and team==attackers(game):
		actor.collision_mask|=16 if team==0 else 32
		var own=spawn_rect(game,team).grow(-1.2)
		point=point.clamp(own.position,own.end)
	if enemy_rect.has_point(point):
		var distances=[point.x-enemy_rect.position.x,enemy_rect.end.x-point.x,point.y-enemy_rect.position.y,enemy_rect.end.y-point.y]
		match distances.find(distances.min()):
			0:point.x=enemy_rect.position.x-.01
			1:point.x=enemy_rect.end.x+.01
			2:point.y=enemy_rect.position.y-.01
			3:point.y=enemy_rect.end.y+.01
	if point!=previous:actor.position.x=point.x;actor.position.z=point.y;actor.velocity=Vector3.ZERO
static func update_gate(game):
	if not is_instance_valid(game.arena) or int(game.options.mode)!=4 or not DefusalLayout.enabled(int(game.options.map)):return
	var gate=game.arena.get_node_or_null("PreparationGate")
	var viewer=int(game.players.get(game.local_id,{}).get("team",attackers(game)))
	var signature=str([game.phase,game.round_no,viewer])
	if is_instance_valid(gate) and gate.get_meta("signature","")==signature:return
	if is_instance_valid(gate):game.arena.remove_child(gate);gate.queue_free()
	gate=Node3D.new();gate.name="PreparationGate";gate.set_meta("signature",signature);game.arena.add_child(gate)
	for team in [0,1]:
		var rect=spawn_rect(game,team);var center=rect.get_center();var half=rect.size*.5
		var body=StaticBody3D.new();body.name="Team%d"%team;body.collision_layer=16 if team==0 else 32;body.collision_mask=0;gate.add_child(body)
		var unlocked=team!=attackers(game) or game.phase!="buy"
		var color=Color(.15,.85,.43,.18) if unlocked and team==viewer else Color(.95,.18,.12,.22)
		for index in range(4):
			var along_x=index<2;var sign_axis=-1. if index%2==0 else 1.
			var size=Vector3(rect.size.x+1.6,12.,1.6) if along_x else Vector3(1.6,12.,rect.size.y)
			var pos=Vector3(center.x,6.,center.y)+Vector3(0,0,sign_axis*half.y) if along_x else Vector3(center.x+sign_axis*half.x,6.,center.y)
			var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size;collision.shape=box;collision.position=pos;body.add_child(collision)
			var visual=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(size.x if along_x else size.z,12.);plane.orientation=PlaneMesh.FACE_Z;visual.mesh=plane
			var material=StandardMaterial3D.new();material.albedo_color=color;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED
			visual.material_override=material;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;visual.position=pos
			if not along_x:visual.rotation.y=PI/2.
			body.add_child(visual)
	for id in game.players:
		if game.actors.has(id):preparation(game,id)
static func at_limit(game) -> bool:return int(game.options.mode)==4 and game.round_no>=int(game.options.rounds) and game.scores[0]!=game.scores[1]
static func return_to_lobby(game):
	RoundCleanup.clear(game)
	game.phase="lobby";game.announce("설정한 경기 수를 완료했습니다.");game.ui.lobby();game.broadcast_state(true)
