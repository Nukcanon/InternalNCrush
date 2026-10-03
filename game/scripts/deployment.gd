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
	var valid=not hit.is_empty() and hit.get("normal",Vector3.ZERO).y>floor_limit(kind) and pos.distance_to(a.position)<8.
	if valid:valid=allowed(game,pos,a.aim_yaw,kind,id)
	return {"pos":pos,"yaw":a.aim_yaw,"valid":valid,"kind":kind}

static func size(kind:String) -> Vector3:
	return Vector3(3.4,1.25,1.) if kind=="cover" else Vector3(.75,1.05,.8)
# 1.4.4: cover may stand on slopes (up to about 40 degrees); turrets need
# near-level ground. Stairs are refused by the corner-height check below.
static func floor_limit(kind:String) -> float:return .75 if kind=="cover" else .88
# Orientation of a build at `pos` facing `yaw`: cover lies on the ground's
# slope (its up along the ground normal); turrets stay level.
static func basis_on_ground(game:Node,pos:Vector3,yaw:float,kind:String) -> Basis:
	var level=Basis(Vector3.UP,yaw)
	if kind!="cover" or not is_instance_valid(game) or not game.has_method("ray"):return level
	var ground=game.ray(pos+Vector3.UP*.5,pos-Vector3.UP*1.,[],1)
	if ground.is_empty():return level
	var n:Vector3=ground.normal.normalized()
	if n.y>.995 or n.y<.5:return level
	var forward:Vector3=level*Vector3.FORWARD
	forward=(forward-n*forward.dot(n)).normalized()
	return Basis(n.cross(-forward).normalized(),n,-forward)
# Only the placer's own body blocks a build next to them: the build box
# must clear the capsule by this much.
const SELF_CLEARANCE=.35
const DEVICE_GAP=.4
## A build's ground footprint (x/z, grown by margin) as a polygon.
static func footprint(pos:Vector3,yaw:float,kind:String,margin:float) -> PackedVector2Array:
	var h=size(kind)*.5+Vector3(margin,0,margin);var out=PackedVector2Array()
	for c in [Vector3(-h.x,0,-h.z),Vector3(h.x,0,-h.z),Vector3(h.x,0,h.z),Vector3(-h.x,0,h.z)]:
		var q=pos+Basis(Vector3.UP,yaw)*c;out.append(Vector2(q.x,q.z))
	return out

# Map layout rules: inside the arena, not in water; 1.4.4: the plant sites are
# kept clear only in bomb mode (a build on the site would block the bomb).
# Elsewhere builds are refused only where they would stand on the player or
# in a wall, so far more of the ground is usable.
static func layout_allows(game:Node,pos:Vector3) -> bool:
	if not pos.is_finite() or not is_instance_valid(game.arena):return false
	if absf(pos.x)>game.arena.bounds.x-2 or absf(pos.z)>game.arena.bounds.y-2 or game.arena.wading(pos):return false
	if int(game.options.mode)==4:
		for site in game.arena.sites:
			if site.distance_to(pos)<5.:return false
	for spawn in game.arena.ffa_spawns:
		if spawn.distance_to(pos)<1.5:return false
	return true

static func allowed(game:Node,pos:Vector3,yaw:float,kind:String,id:int) -> bool:
	if not layout_allows(game,pos):return false
	var query=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=size(kind)-Vector3(.04,.04,.04)
	query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3.UP*(size(kind).y*.5+.04));query.collision_mask=15
	query.exclude=[game.actors[id].get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	# 1.5.4 (the user: a turret and a cover could stand in each other): every build keeps
	# DEVICE_GAP clear of the others' footprints, whatever its collision does while it grows
	# (the placer's own turret is not counted - placing a new one replaces it).
	var mine=footprint(pos,yaw,kind,DEVICE_GAP)
	for d in game.devices.values():
		if kind=="turret" and str(d.kind)=="turret" and int(d.owner)==id:continue
		if absf(float(d.pos.y)-pos.y)>2.:continue
		if not Geometry2D.intersect_polygons(mine,footprint(d.pos,float(d.get("yaw",0.)),str(d.kind),0.)).is_empty():return false
	# The placer's own body (excluded from the query above): no build on top of
	# or overlapping the player.
	var a=game.actors[id]
	var local:Vector3=Basis(Vector3.UP,-yaw)*(a.global_position+Vector3.UP*a.body_height*.5-(pos+Vector3.UP*size(kind).y*.5))
	var half=size(kind)*.5+Vector3(SELF_CLEARANCE,a.body_height*.5,SELF_CLEARANCE)
	if absf(local.x)<half.x and absf(local.z)<half.z and absf(local.y)<half.y+size(kind).y*.5:return false
	# All four supports must touch usable floor at about the same height (no
	# floating edge builds, none straddling steps).
	var heights=[]
	var reach=1.6 if kind=="cover" else .5
	for x in [-.45,.45]:
		for z in [-.45,.45]:
			var point=pos+Basis(Vector3.UP,yaw)*Vector3(x*size(kind).x,reach,z*size(kind).z)
			var ground=game.ray(point,point-Vector3.UP*reach*2.,[],1)
			if ground.is_empty() or ground.normal.y<floor_limit(kind):return false
			heights.append(ground.position.y)
	var lowest=heights.min();var highest=heights.max()
	# Up to the slope limit across the build's own footprint.
	var span=size(kind).x*.9;var slope_limit=span*tan(acos(floor_limit(kind)))+.05
	if highest-lowest>(slope_limit if kind=="cover" else .25):return false
	# Steps: the supports along one edge must not differ from the far edge by a
	# riser while the ground under them is level (a stair, not a slope).
	if kind=="cover" and highest-lowest>.12:
		var mid=pos+Vector3.UP*.5
		var centre=game.ray(mid,mid-Vector3.UP*1.4,[],1)
		if centre.is_empty() or centre.normal.y>.97:return false
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
	if kind=="cover" and owned.size()>=GadgetLoadout.COVER_LIMIT[clampi(int(p.gadget),0,2)]:
		game.feedback(id,"","엄폐물 동시 설치 한도 %d개"%GadgetLoadout.COVER_LIMIT[int(p.gadget)]);return false
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
	game.event_fx.rpc("engineer_deploy",preview.pos,Vector3.ZERO,id) # (1.5.4, the user: machines starting up, from their robot clip)
	game.feedback(id,"","포탑 설치 · 가까이에서 F로 업그레이드" if kind=="turret" else "엄폐물 설치 시작")
	return true

static func nearby_turret(game:Node,id:int) -> int:
	var selected=TurretSelection.target(game,id)
	if selected:return selected
	# Preserve the existing blocked/cooldown state beside an owned turret.
	# It is never outlined and upgrade() rejects it; ready allied targets above
	# still take priority. Never fall back to an unseen upgradeable turret.
	if not game.actors.has(id):return 0
	var a=game.actors[id]
	for did in game.devices:
		var d=game.devices[did]
		if d.kind!="turret" or int(d.owner)!=id or a.position.distance_to(d.pos)>=TurretSelection.RANGE:continue
		var blocked=int(d.level)>=4 or Construction.active(game,d) or TurretSelection.remaining(game,id)>0. or float(d.get("upgrade_ready",0))>game.clock
		if not blocked:continue
		var exclude=[a.get_rid()]
		if game.device_nodes.has(did):exclude.append(game.device_nodes[did].get_rid())
		if game.clear_line(a.eye(),d.pos+Vector3.UP*.6,exclude):return int(did)
	return 0
