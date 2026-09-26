class_name TurretLogic
extends RefCounted
const HALF_ARC=PI*50./180.
const ALERT_DELAY=.10
const PATROL_SPEED=HALF_ARC # 100-degree sweep in two seconds; round trip four.
const TRACK_SPEED=HALF_ARC*2./.45
const FIRE_TOLERANCE=PI/90.
const SCALES=[.5,.65,.82,1.]
const INTERVALS=[.12,.15,.10,.10]
const DAMAGE=[2.8,4.5,3.6,3.8]
const ROCKET_SPEED=30.
static func range_for(game:Node,level:int) -> float:
	return clampf(game.arena.bounds.length(),55.,100.)+float(level-1)*2.
static func origin(d:Dictionary) -> Vector3:return d.pos+Vector3.UP*(1.7*SCALES[clampi(int(d.level)-1,0,3)])
static func remote_damage(base:float,distance:float) -> float:
	return base*lerpf(1.,.10,clampf((distance-12.)/36.,0.,1.))
static func in_arc(d:Dictionary,point:Vector3) -> bool:
	var delta=point-d.pos;delta.y=0
	return delta.length_squared()<.001 or (Basis(Vector3.UP,d.yaw)*Vector3.FORWARD).dot(delta.normalized())>=cos(HALF_ARC)
static func visible_point(game:Node,d:Dictionary,id:int,exclude:Array) -> Vector3:
	var actor=game.actors[id];var from=origin(d)
	# Horizontal acquisition is independent of floor height. Sample exposed body
	# points so a stair lip hiding the chest does not hide the whole character.
	for fraction in [.72,.94,.46]:
		var point=actor.position+Vector3.UP*(actor.eye().y-actor.position.y)*fraction
		var flat=Vector2(point.x-from.x,point.z-from.z)
		if flat.length()>range_for(game,d.level) or not in_arc(d,point):continue
		if not game.in_smoke_line(from,point) and game.clear_line(from,point,exclude+[actor.get_rid()]):return point
	return Vector3.INF
static func upgrade(game:Node,id:int,did:int):
	var p=game.players[id];var d=game.devices[did]
	if Construction.active(game,d):game.feedback(id,"","설치·업그레이드 완료 후 사용할 수 있습니다.");return
	if d.level>=4:game.feedback(id,"","최대 단계 · 기관총 + 미사일");return
	var ready=maxf(float(d.get("upgrade_ready",0)),float(p.skill_ready))
	if game.clock<ready:game.feedback(id,"","업그레이드 준비 중 · %d초"%ceili(ready-game.clock));return
	Construction.advance(game,d)
	var previous_max=float(d.max_hp)
	d.level+=1;d.max_hp=AbilityBalance.turret_hp(d.level);d.build_growth=(d.max_hp-previous_max)*.5;d.hp+=d.build_growth;d.build_progress=0.;d.disabled=game.clock+3.;d.building_started=game.clock;d.building_until=game.clock+3.;d.upgrading=true
	d.upgrade_ready=game.clock+AbilityBalance.COOLDOWNS[3];p.skill_ready=d.upgrade_ready
	game.feedback(id,"heal","포탑 %d단계 · %s"%[d.level,["기관단총","돌격소총","기관총","기관총 + 미사일"][d.level-1]])
	p.placing=""
static func patrol(d:Dictionary,dt:float):
	var current=float(d.get("head_yaw",d.yaw))
	var side=float(d.get("patrol_side",1.))
	var offset=wrapf(current-float(d.yaw),-PI,PI)
	offset=move_toward(offset,HALF_ARC*side,PATROL_SPEED*dt)
	if absf(offset-HALF_ARC*side)<.0001:side=-side
	d.patrol_side=side;d.head_yaw=float(d.yaw)+offset
	d.head_pitch=move_toward(float(d.get("head_pitch",0.)),0.,TRACK_SPEED*dt)
static func track(d:Dictionary,direction:Vector3,dt:float) -> bool:
	var desired=atan2(-direction.x,-direction.z);var pitch=asin(clampf(direction.y,-1.,1.))
	var yaw=float(d.get("head_yaw",d.yaw))
	d.head_yaw=yaw+clampf(wrapf(desired-yaw,-PI,PI),-TRACK_SPEED*dt,TRACK_SPEED*dt)
	d.head_pitch=move_toward(float(d.get("head_pitch",0.)),pitch,TRACK_SPEED*dt)
	return absf(wrapf(desired-float(d.head_yaw),-PI,PI))<=FIRE_TOLERANCE and absf(pitch-float(d.head_pitch))<=FIRE_TOLERANCE
static func tick(game:Node,dt:float):
	for did in game.devices.keys():
		if not game.devices.has(did):continue
		var d=game.devices[did];Construction.advance(game,d)
		if game.clock>d.expires:game.remove_device(did);continue
		if d.kind!="turret" or game.clock<d.disabled or game.phase!="combat":continue
		var owner=game.players.get(d.owner,{})
		if owner.is_empty() or owner.protect>game.clock:continue
		var from=origin(d);var target=int(d.get("target",0));var aim=Vector3.INF
		var remote=owner.alive and owner.slot==0 and game.current_weapon(owner).kind=="remote"
		d.remote=remote
		var exclude=[]
		if game.device_nodes.has(did):exclude.append(game.device_nodes[did].get_rid())
		if remote:
			var a=game.actors[d.owner]
			var eye_hit=game.ray(a.eye(),a.eye()+a.direction()*300.,[a.get_rid()])
			aim=eye_hit.get("position",a.eye()+a.direction()*300.);d.target=0;d.lock=game.clock
		else:
			if game.players.has(target) and game.players[target].alive and game.enemies(owner,game.players[target]):aim=visible_point(game,d,target,exclude)
			if not aim.is_finite():target=0;d.target=0
			# Hold a visible target instead of alternating locks between nearby enemies.
			if target==0 and game.clock>=float(d.get("next_scan",0.)):
				d.next_scan=game.clock+.1
				var best=range_for(game,d.level)
				for id in game.players:
					var p=game.players[id]
					if not p.alive or id==d.owner or not game.enemies(owner,p):continue
					var point=visible_point(game,d,id,exclude)
					if not point.is_finite():continue
					var distance=Vector2(point.x-from.x,point.z-from.z).length()
					if distance<best:best=distance;target=id;aim=point
				if target!=0:
					d.target=target;d.lock=game.clock+ALERT_DELAY
					game.event_fx.rpc("turret_detect",from,Vector3.ZERO,int(d.owner))
			if target==0:
				patrol(d,dt)
				d.aim=from+Basis(Vector3.UP,float(d.head_yaw))*Vector3.FORWARD*5.
				continue
		if game.clock<float(d.lock):continue
		var aligned=track(d,(aim-from).normalized(),dt)
		var barrel_direction=Basis(Vector3.UP,float(d.head_yaw))*Basis(Vector3.RIGHT,float(d.head_pitch))*Vector3.FORWARD
		d.aim=from+barrel_direction*maxf(2.,from.distance_to(aim))
		var firing=bool(game.actors[d.owner].input_state.fire) and owner.reload<=0 and game.can_attack(owner) if remote else target!=0
		if not firing or not aligned:continue
		var direction=barrel_direction
		# Shots follow the physical barrel only after acquisition and slew complete.
		var muzzle=from+direction*(.94*SCALES[d.level-1])
		var obstruction=game.ray(from,muzzle,exclude,1|4|8)
		if not obstruction.is_empty():continue
		if game.clock>=d.next_fire:
			d.next_fire=game.clock+INTERVALS[d.level-1]
			var flight=Ballistics.trace(game,muzzle,direction,300. if remote else muzzle.distance_to(aim)+2.,exclude)
			var hit:Dictionary=flight.hit;var end:Vector3=flight.end
			var amount=DAMAGE[d.level-1]
			if remote:amount=remote_damage(amount,muzzle.distance_to(end))
			for passed_id in flight.get("passed",{}):game.damage_device(passed_id,amount,int(d.owner))
			if not hit.is_empty():
				if hit.collider is Actor:game.damage(hit.collider.pid,amount,int(d.owner),false,"turret",muzzle,hit.position)
				elif hit.collider is InteractiveProp:hit.collider.hit(hit.position,direction,amount)
				elif hit.collider.has_meta("device"):game.damage_device(int(hit.collider.get_meta("device")),amount,int(d.owner))
			game.effect.rpc("shot",muzzle,end,0)
		if d.level==4 and game.clock>=float(d.get("rocket_ready",0)):
			d.rocket_ready=game.clock+2.
			game.rockets.append({"pos":muzzle,"velocity":direction*ROCKET_SPEED,"owner":int(d.owner),"device":did,"until":game.clock+10.,"origin":muzzle})
	tick_rockets(game,dt)
static func tick_rockets(game:Node,dt:float):
	for rocket in game.rockets:
		if rocket.get("launcher",false):RocketCombat.tick(game,rocket,dt);continue
		var from:Vector3=rocket.pos;var to=from+rocket.velocity*dt;var exclude=[]
		if game.device_nodes.has(int(rocket.device)):exclude.append(game.device_nodes[int(rocket.device)].get_rid())
		var hit=game.ray(from,to,exclude)
		Construction.projectile(game,rocket,from,hit.get("position",to),30.)
		if not hit.is_empty():
			rocket.pos=hit.position;rocket.until=0.
			for id in game.players:
				if not game.players[id].alive:continue
				var point=game.actors[id].eye()-Vector3.UP*.3;var distance=point.distance_to(hit.position)
				if hit.collider==game.actors[id]:game.damage(id,30.,rocket.owner,false,"turret_missile",rocket.origin,hit.position)
				elif distance<2.4 and game.clear_line(hit.position+hit.normal*.08,point,exclude+[game.actors[id].get_rid()]):game.damage(id,30.*clampf(1.-distance/2.4,.2,1.),rocket.owner,false,"turret_missile",rocket.origin,point)
			for struck in game.devices.keys():
				var device=game.devices[struck];var point=device.pos+Vector3.UP*.6;var distance=point.distance_to(hit.position)
				if distance<2.4 and game.clear_line(hit.position+hit.normal*.08,point,[game.device_nodes[struck].get_rid()] if game.device_nodes.has(struck) else []):game.damage_device(struck,30.*clampf(1.-distance/2.4,.2,1.),int(rocket.owner))
			game.event_fx.rpc("explosion",hit.position,Vector3.ZERO,rocket.owner)
		else:rocket.pos=to
	game.rockets=game.rockets.filter(func(r):return r.until>game.clock)
