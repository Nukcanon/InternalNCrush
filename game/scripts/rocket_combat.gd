class_name RocketCombat
extends RefCounted
const SPEED=30.
const GRAVITY=.65
const RADIUS=9.
static func launch(g:Node,id:int,w:Dictionary):
	var p=g.players[id];var a=g.actors[id];var origin=a.muzzle_world()
	var direction=a.direction();var blocked=g.ray(a.eye(),a.desired_muzzle(),[a.get_rid()],1|4|8)
	var rocket={"pos":origin,"origin":origin,"velocity":direction*SPEED,"owner":id,"device":0,"until":g.clock+10.,"launcher":true}
	if not blocked.is_empty():explode(g,rocket,blocked)
	else:g.rockets.append(rocket)
	p.shot_time=g.clock;g.effect.rpc("rocket_launch",origin,origin+direction,id,g.clock,{"weapon":"h4"})
static func tick(g:Node,rocket:Dictionary,dt:float):
	var steps=maxi(1,ceili(dt/.016));var step=dt/steps
	var exclude=[g.actors[rocket.owner].get_rid()] if g.actors.has(rocket.owner) else []
	for i in range(steps):
		var next:Vector3=rocket.pos+rocket.velocity*step-Vector3.UP*GRAVITY*step*step*.5
		var hit=g.ray(rocket.pos,next,exclude)
		Construction.projectile(g,rocket,rocket.pos,hit.get("position",next),60.)
		rocket.velocity.y-=GRAVITY*step
		if not hit.is_empty():rocket.pos=hit.position;rocket.until=0.;explode(g,rocket,hit);return
		rocket.pos=next
static func explode(g:Node,rocket:Dictionary,hit:Dictionary):
	var pos:Vector3=hit.position+hit.normal*.06;var owner=int(rocket.owner)
	g.event_fx.rpc("explosion",hit.position,Vector3.ZERO,owner)
	for id in g.players:
		var p=g.players[id]
		if not p.alive:continue
		var actor=g.actors[id];var point=actor.eye()-Vector3.UP*.3;var distance=point.distance_to(pos)
		var direct=hit.collider==actor
		if not direct and (distance>RADIUS or not g.clear_line(pos,point,[actor.get_rid()])):continue
		var splash=lerpf(45.,15.,clampf(distance/RADIUS,0.,1.))
		var can_push=p.protect<=g.clock and p.get("invulnerable",0)<=g.clock and (id==owner or not g.players.has(owner) or g.enemies(g.players[owner],p) or g.options.friendly)
		g.damage(id,(60. if direct else splash),owner,false,"h4",rocket.origin if direct else pos,hit.position if direct else point)
		if can_push and p.alive:
			var away=Vector3(rocket.velocity.x,0,rocket.velocity.z).normalized() if direct else Vector3(point.x-pos.x,0,point.z-pos.z).normalized()
			if away.length_squared()<.01:away=Vector3.FORWARD
			g.blast_push.rpc(id,away*(8. if direct else lerpf(3.2,.8,distance/RADIUS))+Vector3.UP*(5.5 if direct else 1.6),.65 if direct else .25)
	for did in g.devices.keys():
		if rocket.get("construction_hits",{}).has(did):continue # A pass-through direct hit already dealt this rocket's damage.
		var d=g.devices[did];var point=d.pos+Vector3.UP*.8;var distance=point.distance_to(pos)
		var direct=hit.collider.has_meta("device") and int(hit.collider.get_meta("device"))==int(did)
		var exclude=[g.device_nodes[did].get_rid()] if g.device_nodes.has(did) else []
		if direct or (distance<=RADIUS and g.clear_line(pos,point,exclude)):g.damage_device(did,(60. if direct else lerpf(45.,15.,clampf(distance/RADIUS,0.,1.))),owner)
	for prop in g.arena.props.values():
		var delta=prop.global_position-pos
		if delta.length()<RADIUS and g.clear_line(pos,prop.global_position,[prop.get_rid()]):prop.hit(prop.global_position,delta.normalized(),30.)
