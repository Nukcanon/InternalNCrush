class_name TurretLogic
extends RefCounted
const HALF_ARC=PI/6.
const SCALES=[.5,.65,.82,1.]
const INTERVALS=[.12,.15,.10,.10]
const DAMAGE=[2.8,4.5,3.6,3.8]
static func range_for(game:Node,level:int) -> float:
	return clampf(game.arena.bounds.length(),55.,100.)+float(level-1)*2.
static func origin(d:Dictionary) -> Vector3:return d.pos+Vector3.UP*(1.7*SCALES[clampi(int(d.level)-1,0,3)])
static func remote_damage(base:float,distance:float) -> float:
	return base*lerpf(1.,.10,clampf((distance-12.)/36.,0.,1.))
static func in_arc(d:Dictionary,point:Vector3) -> bool:
	var delta=point-d.pos;delta.y=0
	return delta.length_squared()<.001 or (Basis(Vector3.UP,d.yaw)*Vector3.FORWARD).dot(delta.normalized())>=cos(HALF_ARC)
static func upgrade(game:Node,id:int,did:int):
	var p=game.players[id];var d=game.devices[did]
	if d.level>=4:game.feedback(id,"","최대 단계 · 기관총 + 미사일");return
	if game.clock<float(d.get("upgrade_ready",0)):game.feedback(id,"","업그레이드 준비 중 · %d초"%ceili(d.upgrade_ready-game.clock));return
	d.level+=1;d.max_hp=AbilityBalance.turret_hp(d.level);d.hp=minf(d.max_hp,d.hp+45.);d.disabled=game.clock+1.5;d.upgrade_ready=game.clock+18.
	game.feedback(id,"heal","포탑 %d단계 · %s"%[d.level,["기관단총","돌격소총","기관총","기관총 + 미사일"][d.level-1]])
	p.placing=""
static func tick(game:Node,dt:float):
	for did in game.devices.keys():
		var d=game.devices[did]
		if game.clock>d.expires:game.remove_device(did);continue
		if d.kind!="turret" or game.clock<d.disabled or game.phase!="combat":continue
		var owner=game.players.get(d.owner,{})
		if owner.is_empty() or owner.protect>game.clock:continue
		var from=origin(d);var target=0;var aim=from+Basis(Vector3.UP,d.yaw)*Vector3.FORWARD*range_for(game,d.level)
		var remote=owner.alive and owner.slot==0 and game.current_weapon(owner).kind=="remote"
		d.remote=remote
		var exclude=[]
		if game.device_nodes.has(did):exclude.append(game.device_nodes[did].get_rid())
		if remote:
			var a=game.actors[d.owner]
			var eye_hit=game.ray(a.eye(),a.eye()+a.direction()*300.,[a.get_rid()])
			aim=eye_hit.get("position",a.eye()+a.direction()*300.)
			d.lock=game.clock
		else:
			# Target search at 10 Hz, while rotation/fire and projectiles remain fixed-tick.
			if game.clock>=float(d.get("next_scan",0)):
				d.next_scan=game.clock+.1
				var best=range_for(game,d.level)
				for id in game.players:
					var p=game.players[id]
					if not p.alive or id==d.owner or not game.enemies(owner,p):continue
					var point=game.actors[id].eye()-Vector3.UP*.3
					var distance=from.distance_to(point)
					if distance<best and in_arc(d,point) and not game.in_smoke_line(from,point) and game.clear_line(from,point,exclude+[game.actors[id].get_rid()]):best=distance;target=id
				if target!=int(d.target):d.target=target;d.lock=game.clock+.18
			target=int(d.target)
			if not game.players.has(target) or not game.players[target].alive:target=0;d.target=0
			if target:aim=game.actors[target].eye()-Vector3.UP*.3
		d.aim=aim
		var firing=bool(game.actors[d.owner].input_state.fire) and owner.reload<=0 and game.can_attack(owner) if remote else target!=0
		if not firing or game.clock<d.lock:continue
		var direction=(aim-from).normalized()
		# Muzzle follows the target without recoil; obstruction still wins over targeting.
		var muzzle=from+direction*(.94*SCALES[d.level-1])
		var obstruction=game.ray(from,muzzle,exclude,1|4|8)
		if not obstruction.is_empty():continue
		if game.clock>=d.next_fire:
			d.next_fire=game.clock+INTERVALS[d.level-1]
			var hit=game.ray(muzzle,muzzle+direction*(300. if remote else range_for(game,d.level)),exclude)
			var end:Vector3=hit.get("position",aim)
			var amount=DAMAGE[d.level-1]
			if remote:amount=remote_damage(amount,muzzle.distance_to(end))
			if not hit.is_empty():
				if hit.collider is Actor:game.damage(hit.collider.pid,amount,int(d.owner),false,"turret",muzzle,hit.position)
				elif hit.collider is InteractiveProp:hit.collider.hit(hit.position,direction,amount)
				elif hit.collider.has_meta("device"):game.damage_device(int(hit.collider.get_meta("device")),amount,int(d.owner))
			game.effect.rpc("shot",muzzle,end,0)
		if d.level==4 and game.clock>=float(d.get("rocket_ready",0)):
			d.rocket_ready=game.clock+2.
			game.rockets.append({"pos":muzzle,"velocity":direction*18.,"owner":int(d.owner),"device":did,"until":game.clock+10.,"origin":muzzle})
	tick_rockets(game,dt)
static func tick_rockets(game:Node,dt:float):
	for rocket in game.rockets:
		var from:Vector3=rocket.pos;var to=from+rocket.velocity*dt;var exclude=[]
		if game.device_nodes.has(int(rocket.device)):exclude.append(game.device_nodes[int(rocket.device)].get_rid())
		var hit=game.ray(from,to,exclude)
		if not hit.is_empty():
			rocket.pos=hit.position;rocket.until=0.
			for id in game.players:
				if not game.players[id].alive:continue
				var point=game.actors[id].eye()-Vector3.UP*.3;var distance=point.distance_to(hit.position)
				if hit.collider==game.actors[id]:game.damage(id,30.,rocket.owner,false,"turret_missile",rocket.origin,hit.position)
				elif distance<2.4 and game.clear_line(hit.position+hit.normal*.08,point,exclude+[game.actors[id].get_rid()]):game.damage(id,30.*clampf(1.-distance/2.4,.2,1.),rocket.owner,false,"turret_missile",rocket.origin,point)
			game.event_fx.rpc("explosion",hit.position,Vector3.ZERO,rocket.owner)
		else:rocket.pos=to
	game.rockets=game.rockets.filter(func(r):return r.until>game.clock)
