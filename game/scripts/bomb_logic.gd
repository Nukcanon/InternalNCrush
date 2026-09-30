extends RefCounted
class_name BombLogic
static func defuse_seconds(p:Dictionary) -> float:
	return 5. if int(p.get("gadget",-1))==9 and GadgetLoadout.has_item(p) else 15.
static func hint(game:Node,id:int,touch:bool=false) -> String:
	if int(game.options.mode)!=4 or not game.players.has(id) or not game.players[id].alive or game.phase not in ["buy","combat"]:return ""
	var key="상호작용 버튼" if touch else "E키"
	var kind=action(game,id)
	if kind=="plant":return key+"를 눌러 폭탄 설치\n3초 동안 누르기"
	if kind=="defuse":return key+"를 눌러 폭탄 해체\n%d초 동안 누르기"%int(defuse_seconds(game.players[id]))
	return "폭탄 보유 중" if int(game.bomb.get("carrier",0))==id and not game.bomb.planted else ""
static func action(game:Node,id:int) -> String:
	if int(game.options.mode)!=4 or game.phase!="combat" or not game.players.has(id) or not game.players[id].alive:return ""
	var p=game.players[id];var pos=game.actors[id].position
	if game.bomb.get("defused",false) or game.bomb.get("exploded",false):return ""
	if game.bomb.planted:
		return "defuse" if p.team!=MatchFlow.attackers(game) and pos.distance_to(game.bomb.position)<1.8 else ""
	if int(game.bomb.get("carrier",0))==id and p.team==MatchFlow.attackers(game):
		for site in game.arena.sites:
			if pos.distance_to(site)<5.:return "plant"
	return ""
static func busy(game:Node,id:int) -> bool:
	return game.actors.has(id) and game.actors[id].input_state.get("use",false) and not action(game,id).is_empty()
static func tap(game:Node,id:int):
	if int(game.options.mode)!=4 or game.phase!="combat" or int(game.bomb.get("carrier",0))!=id or action(game,id)=="plant":return
	var p=game.players[id]
	if not p.alive:return
	if game.clock-float(p.get("bomb_tap_at",-10.))<=.45:
		p.bomb_tap_at=-10.;drop(game,id)
	else:p.bomb_tap_at=game.clock
static func use_label(game:Node,id:int) -> String:
	if int(game.options.mode)==4 and int(game.bomb.get("carrier",0))==id:return "폭탄 설치"
	return "폭탄 해체" if action(game,id)=="defuse" else "상호작용"
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
	game.bomb.resting=false;game.bomb.pickup_after=game.clock+.75
	game.bomb.actor=0;game.bomb.progress=0.
	game.bomb_announcement.rpc("bomb_dropped")
static func pickup(game:Node,id:int) -> bool:
	if game.bomb.planted or not game.bomb.get("dropped",false):return false
	if game.clock<float(game.bomb.get("pickup_after",0.)):return false
	if not game.players[id].alive or int(game.players[id].team)!=MatchFlow.attackers(game):return false
	if game.actors[id].position.distance_to(game.bomb.position)>2.2:return false
	var point:Vector3=game.bomb.position+Vector3.UP*.2
	if not game.clear_line(game.actors[id].eye(),point,[game.actors[id].get_rid()]):return false
	game.bomb.carrier=id;game.bomb.dropped=false;game.bomb.velocity=Vector3.ZERO
	game.feedback(id,"","폭탄 회수 · A 또는 B 구역에서 E를 3초 유지");return true
static func tick(game:Node,dt:float):
	if game.bomb.planted or not game.bomb.get("dropped",false):return
	if game.bomb.get("resting",false):return
	var velocity:Vector3=game.bomb.get("velocity",Vector3.ZERO)
	velocity.y-=18.*dt
	var from:Vector3=game.bomb.position;var to=from+velocity*dt
	var hit=game.ray(from,to,[],1|4|8)
	if not hit.is_empty():
		to=hit.position+hit.normal*.015;velocity=velocity.slide(hit.normal)*.35
		if hit.normal.y>.55:velocity=Vector3.ZERO;game.bomb.resting=true
	game.bomb.position=to;game.bomb.velocity=velocity
static func beep_interval(remaining:float,total:float) -> float:
	var fraction=remaining/maxf(1.,total)
	return 1.2 if fraction>.5 else .75 if fraction>.25 else .4 if fraction>.1 else .16
# 1.4.2: twice the 1.4 reach (the shorter side x 0.8, at most 60 m).
static func radius(game:Node) -> float:
	return 2.*minf(30.,minf(game.arena.bounds.x,game.arena.bounds.y)*2./5.)
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
	# 1.4 cartoon charge: rounded hazard case, three canisters, glowing keypad.
	var body=Node3D.new();body.name="ChargeBody";parent.add_child(body)
	MeshFactory.box(body,Vector3(0,.15,0),Vector3(.6,.26,.42),Color("2e3440"),Vector3.ZERO,.6)
	for x in [-.21,.21]:MeshFactory.box(body,Vector3(x,.16,0),Vector3(.08,.28,.45),Color("f2a33a"),Vector3.ZERO,.5)
	for x in [-.12,0,.12]:MeshFactory.cylinder(body,Vector3(x,.31,.06),.05,.31,Color("d9483b"),Vector3(PI/2,0,0),.045,12)
	MeshFactory.box(body,Vector3(0,.34,-.13),Vector3(.26,.06,.15),Color("1c222c"),Vector3.ZERO,.5)
	MeshFactory.box(body,Vector3(0,.375,-.13),Vector3(.18,.016,.1),Color("7fe0ff"),Vector3.ZERO,.3)
	MeshFactory.merge_children(body)
	for mesh in body.get_children():
		if mesh is MeshInstance3D:mesh.material_override=HeroStyle.toon_material(false,.25)
	var lamp=MeshFactory.sphere(parent,Vector3(.23,.35,-.15),Vector3(.085,.085,.085),Color("ff2920"));lamp.name="Beacon"
	var material=StandardMaterial3D.new();material.albedo_color=Color("ff2920");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.emission_enabled=true;material.emission=Color("ff2920");lamp.material_override=material
