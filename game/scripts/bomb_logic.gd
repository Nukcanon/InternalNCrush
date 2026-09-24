class_name BombLogic
extends RefCounted
static func assign(game:Node):
	var candidates=[]
	for id in game.players:
		if game.players[id].alive and int(game.players[id].team)==MatchFlow.attackers(game):candidates.append(id)
	game.bomb.carrier=candidates.pick_random() if not candidates.is_empty() else 0
	game.bomb.dropped=false;game.bomb.exploded=false;game.bomb.defused=false;game.bomb.velocity=Vector3.ZERO
	if game.bomb.carrier:game.feedback(game.bomb.carrier,"","폭탄 운반자 · A 또는 B 구역에서 E를 3초 유지")
static func drop(game:Node,id:int):
	if int(game.options.mode)!=4 or game.bomb.planted or int(game.bomb.get("carrier",0))!=id:return
	game.bomb.carrier=0;game.bomb.dropped=true
	game.bomb.position=game.actors[id].position+Vector3.UP*.45
	game.bomb.velocity=game.actors[id].velocity*.35+Vector3.UP
	game.bomb.actor=0;game.bomb.progress=0.
	game.bomb_announcement.rpc("bomb_dropped")
static func pickup(game:Node,id:int) -> bool:
	if game.bomb.planted or not game.bomb.get("dropped",false):return false
	if not game.players[id].alive or int(game.players[id].team)!=MatchFlow.attackers(game):return false
	if game.actors[id].position.distance_to(game.bomb.position)>2.2:return false
	var point:Vector3=game.bomb.position+Vector3.UP*.2
	if not game.clear_line(game.actors[id].eye(),point,[game.actors[id].get_rid()]):return false
	game.bomb.carrier=id;game.bomb.dropped=false;game.bomb.velocity=Vector3.ZERO
	game.feedback(id,"","폭탄 회수 · A 또는 B 구역에서 E를 3초 유지");return true
static func tick(game:Node,dt:float):
	if game.bomb.planted or not game.bomb.get("dropped",false):return
	var velocity:Vector3=game.bomb.get("velocity",Vector3.ZERO)
	velocity.y-=18.*dt
	var from:Vector3=game.bomb.position;var to=from+velocity*dt
	var hit=game.ray(from,to,[],1|4|8)
	if not hit.is_empty():to=hit.position+hit.normal*.12;velocity=Vector3.ZERO
	game.bomb.position=to;game.bomb.velocity=velocity
static func beep_interval(remaining:float,total:float) -> float:
	var fraction=remaining/maxf(1.,total)
	return 1.2 if fraction>.5 else .75 if fraction>.25 else .4 if fraction>.1 else .16
static func radius(game:Node) -> float:
	return minf(30.,minf(game.arena.bounds.x,game.arena.bounds.y)*2./5.)
static func detonate(game:Node):
	if game.bomb.get("exploded",false):return
	game.bomb.exploded=true
	var reach=radius(game);var origin:Vector3=game.bomb.position
	for id in game.players:
		if not game.players[id].alive:continue
		var point=game.actors[id].eye()-Vector3.UP*.4;var distance=point.distance_to(origin)
		if distance<reach:game.damage(id,600.*sqrt(1.-distance/reach),0,false,"bomb",origin,point)
	for id in game.devices.keys():
		if game.devices[id].pos.distance_to(origin)<reach:game.damage_device(id,1000.,0)
	for prop in game.arena.props.values():
		var offset=prop.global_position-origin
		if offset.length()<reach:prop.hit(prop.global_position,(offset+Vector3.UP*3.).normalized(),300.)
	game.event_fx.rpc("bomb_explosion",origin,Vector3(reach,0,0),0)
	game.finish_round(MatchFlow.attackers(game),"폭탄 폭발")
static func model(parent:Node3D):
	MeshFactory.box(parent,Vector3(0,.16,0),Vector3(.60,.26,.42),Color("343e44"))
	for x in [-.21,.21]:MeshFactory.box(parent,Vector3(x,.17,0),Vector3(.07,.28,.45),Color("aa8953"))
	for x in [-.12,0,.12]:MeshFactory.cylinder(parent,Vector3(x,.31,.06),.048,.31,Color("797564"),Vector3(PI/2,0,0),-1.,10)
	MeshFactory.box(parent,Vector3(0,.34,-.13),Vector3(.26,.055,.15),Color("182831"))
	MeshFactory.box(parent,Vector3(0,.374,-.13),Vector3(.18,.015,.10),Color("e95145"))
	var lamp=MeshFactory.sphere(parent,Vector3(.23,.35,-.15),Vector3(.085,.085,.085),Color("ff2920"));lamp.name="Beacon"
	var material=StandardMaterial3D.new();material.albedo_color=Color("ff2920");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.emission_enabled=true;material.emission=Color("ff2920");lamp.material_override=material
