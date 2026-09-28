class_name LaserCombat
extends RefCounted
const HEAT_SECONDS=3.2
const LOCK_SECONDS=2.
const COOL_SECONDS=1.8
const BATTERY_SECONDS=5.
static func dps(heat:float) -> float:return lerpf(60.,120.,clampf(heat/.98,0.,1.))
static func tick(g:Node,id:int,dt:float):
	var p=g.players[id];var a=g.actors[id];var w=g.current_weapon(p)
	var heat=float(p.get("laser_heat",0.))
	if not w.get("laser",false) and heat<=0.:p.laser_firing=false;p.laser_dt=0.;return
	p.laser_dt=float(p.get("laser_dt",0.))+dt
	if float(p.laser_dt)<.05:return
	dt=minf(float(p.laser_dt),.15);p.laser_dt=0.
	var locked=float(p.get("laser_lock",0.))>g.clock
	p.laser_firing=false
	if locked:p.laser_heat=clampf((float(p.laser_lock)-g.clock)/LOCK_SECONDS,0.,1.);return
	var active=w.get("laser",false) and p.slot<2 and WeaponRules.allows_slot(g.options,int(p.slot)) and a.input_state.fire and g.can_attack(p) and p.reload<=0 and p.switch_until<=g.clock and not MeleeCombat.active(p,g.clock) and not a.last_sprint and g.clock>=a.sprint_release and p.get("cooking",0)<=0 and p.get("placing","")==""
	var wid=p.primary if p.slot==0 else p.secondary
	if not active or float(p.mag.get(wid,0))<=0:
		p.laser_heat=maxf(0.,heat-dt/COOL_SECONDS)
		if active:g.begin_reload(id)
		return
	var used=minf(dt,minf(float(p.mag[wid])/100.,(1.-heat)*HEAT_SECONDS))
	if used<=0:return
	p.laser_firing=true;p.mag[wid]=maxf(0.,float(p.mag[wid])-used*100.);p.laser_heat=minf(1.,heat+used/HEAT_SECONDS);p.shot_time=g.clock
	var origin=a.muzzle_world();var eye=a.eye();var direction=a.direction()
	var hit=g.ray(eye,eye+direction*float(w.max_range),[a.get_rid()])
	var end:Vector3=hit.get("position",eye+direction*float(w.max_range))
	var obstruction=g.ray(eye,a.desired_muzzle(),[a.get_rid()],1|4|8)
	if not obstruction.is_empty():hit=obstruction;end=hit.position
	else:hit=g.ray(origin,end,[a.get_rid()]);end=hit.get("position",end)
	var amount=dps((heat+float(p.laser_heat))*.5)*used*CombatBalance.range_factor(w,origin.distance_to(end))
	if not hit.is_empty():
		var collider=hit.collider
		if collider is Actor:
			var zone=str(hit.get("zone","torso"));var multiplier=1.5 if zone=="head" else .5 if zone in ["legs","feet"] else 1.
			g.damage(collider.pid,amount*multiplier,id,zone=="head",wid,origin,end)
		elif collider.has_meta("device"):
			var did=int(collider.get_meta("device"))
			if g.devices.has(did):
				var d=g.devices[did]
				if int(d.team)==int(p.team) and int(g.options.mode)!=1:
					if origin.distance_to(end)<=100.:d.hp=minf(float(d.max_hp),float(d.hp)+30.*used)
				else:g.damage_device(did,amount,id)
		elif collider is InteractiveProp:collider.hit(end,direction,amount)
	if g.clock>=float(p.get("laser_fx_ready",0.)):
		p.laser_fx_ready=g.clock+.08
		g.effect.rpc("laser",origin,end,id,g.clock,{"weapon":wid})
		if not hit.is_empty() and not hit.collider is Actor and not hit.collider.has_meta("device"):g.wall_marks_batch.rpc([{"pos":end,"normal":hit.normal,"scorch":true}])
	if float(p.laser_heat)>=.99999:
		p.laser_heat=1.;p.laser_lock=g.clock+LOCK_SECONDS;p.laser_firing=false
		g.effect.rpc("laser_vent",origin,origin,id)
	if float(p.mag[wid])<=0:g.begin_reload(id)
