class_name Deployment
extends RefCounted

static func candidate(game:Node,id:int,kind:String) -> Dictionary:
	var a=game.actors[id]
	var hit=game.ray(a.eye(),a.eye()+a.direction()*8.,[a.get_rid()],1|4|8)
	if hit.is_empty():
		var forward=a.direction();forward.y=0;forward=forward.normalized()
		var point=a.position+forward*4.
		hit=game.ray(point+Vector3.UP*2.,point-Vector3.UP*4.,[a.get_rid()],1|4|8)
	var pos:Vector3=hit.get("position",a.position+a.direction()*4.)
	var valid=not hit.is_empty() and hit.get("normal",Vector3.ZERO).y>.88 and pos.distance_to(a.position)<8.
	if valid:valid=allowed(game,pos,a.aim_yaw,kind,id)
	return {"pos":pos,"yaw":a.aim_yaw,"valid":valid,"kind":kind}

static func size(kind:String) -> Vector3:
	return Vector3(3.4,1.25,1.) if kind=="cover" else Vector3(.75,1.05,.8)

static func allowed(game:Node,pos:Vector3,yaw:float,kind:String,id:int) -> bool:
	if not pos.is_finite() or not is_instance_valid(game.arena):return false
	if absf(pos.x)>game.arena.bounds.x-2 or absf(pos.z)>game.arena.bounds.y-2 or game.arena.wading(pos):return false
	for site in game.arena.sites:
		if site.distance_to(pos)<5.:return false
	for spawn in game.arena.ffa_spawns:
		if spawn.distance_to(pos)<2.:return false
	var query=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=size(kind)-Vector3(.04,.04,.04)
	query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3.UP*(size(kind).y*.5+.04));query.collision_mask=15
	query.exclude=[game.actors[id].get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	# All four supports must touch the same usable floor; no floating edge builds.
	for x in [-.45,.45]:
		for z in [-.45,.45]:
			var point=pos+Basis(Vector3.UP,yaw)*Vector3(x*size(kind).x,.2,z*size(kind).z)
			var ground=game.ray(point,point-Vector3.UP*.4,[],1)
			if ground.is_empty() or ground.normal.y<.88:return false
	return true

static func begin(game:Node,id:int,kind:String):
	var p=game.players[id]
	p.placing="" if p.get("placing","")==kind else kind
	p.fire_prev=true;p.trigger_seen=int(game.actors[id].input_state.get("trigger_seq",0));p.burst_left=0;p.trigger_until=0.
	if id<0 and p.placing!="":confirm(game,id)
	game.feedback(id,"","설치 위치 선택 · 클릭 확정 · 같은 키로 취소" if p.placing!="" else "설치 취소")

static func confirm(game:Node,id:int) -> bool:
	var p=game.players[id];var kind=str(p.get("placing",""))
	if kind not in ["turret","cover"] or p.role!=3 or not game.can_attack(p) or game.phase!="combat":return false
	if kind=="turret" and (not game.options.skills or p.skill_ready>game.clock):return false
	if kind=="cover" and (p.gadget_count<=0 or p.gadget_ready>game.clock):return false
	var preview=candidate(game,id,kind)
	if not preview.valid:game.feedback(id,"","빨간 위치에는 설치할 수 없습니다.");return false
	var owned=[]
	for did in game.devices:
		if game.devices[did].owner==id and game.devices[did].kind==kind:owned.append(did)
	if kind=="cover" and owned.size()>=2:game.feedback(id,"","엄폐물은 두 개까지 설치할 수 있습니다.");return false
	if kind=="turret":
		for did in owned:
			game.event_fx.rpc("turret_break",game.devices[did].pos+Vector3.UP*.85,Vector3.ZERO,id)
			game.remove_device(did)
	var did=game.add_device(kind,preview.pos,id,AbilityBalance.turret_hp(1) if kind=="turret" else AbilityBalance.COVER_HP[int(p.gadget)])
	var build_seconds=5. if kind=="turret" else [2.,3.5,5.][clampi(int(p.gadget),0,2)]
	game.devices[did].disabled=game.clock+build_seconds
	game.devices[did].building_started=game.clock;game.devices[did].building_until=game.clock+build_seconds
	game.devices[did].build_growth=game.devices[did].max_hp*.5;game.devices[did].build_progress=0.;game.devices[did].hp=game.devices[did].max_hp*.5
	if kind=="turret":p.skill_ready=game.clock+AbilityBalance.COOLDOWNS[3]
	else:p.gadget_count-=1;p.gadget_ready=game.clock+.8
	p.placing="";p.fire_ready=game.clock+.35;p.builds=int(p.get("builds",0))+1
	game.event_fx.rpc("deploy",preview.pos,Vector3.ZERO,id)
	game.feedback(id,"","포탑 설치 · 가까이에서 F로 업그레이드" if kind=="turret" else "엄폐물 설치 완료")
	return true

static func nearby_turret(game:Node,id:int) -> int:
	return TurretSelection.target(game,id)
