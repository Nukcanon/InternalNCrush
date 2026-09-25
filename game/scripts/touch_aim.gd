class_name TouchAim
extends RefCounted
## Gentle, bounded camera assistance. Never changes damage or server hit tests.
static func assist(game:Node,actor:Actor,dt:float):
	var p=game.players[game.local_id]
	if not game.profile.get("touch_aim_assist",true) or not game.can_attack(p) or game.phase!="combat" or p.slot>1 or p.reload>0 or p.get("placing","")!="" or game.current_weapon(p).kind!="gun":return
	var forward=Basis(Vector3.UP,actor.input_state.yaw)*Basis(Vector3.RIGHT,actor.input_state.pitch)*Vector3.FORWARD
	var best=cos(deg_to_rad(4.));var direction=Vector3.ZERO
	for id in game.players:
		var other=game.players[id]
		if id==game.local_id or not other.alive or not game.enemies(p,other) or not game.actors.has(id):continue
		var target=game.actors[id];var point=target.eye()-Vector3.UP*.35;var delta=point-actor.eye()
		if delta.length_squared()>3600. or delta.length_squared()<.01:continue
		var dot=forward.dot(delta.normalized())
		if dot<=best or game.in_smoke_line(actor.eye(),point) or not game.clear_line(actor.eye(),point,[actor.get_rid(),target.get_rid()]):continue
		best=dot;direction=delta.normalized()
	if direction==Vector3.ZERO:return
	var limit=deg_to_rad(30.)*minf(dt,.05)
	var response=1.-exp(-12.*minf(dt,.05))
	# Reduce assistance under high magnification; user input remains dominant.
	if SniperScope.active(game):limit*=4./SniperScope.magnification(game.profile,game.current_weapon(p))
	var yaw=atan2(-direction.x,-direction.z);var pitch=asin(clampf(direction.y,-1.,1.))
	actor.input_state.yaw+=clampf(wrapf(yaw-actor.input_state.yaw,-PI,PI)*response,-limit,limit)
	actor.input_state.pitch=clampf(actor.input_state.pitch+clampf((pitch-actor.input_state.pitch)*response,-limit,limit),-1.45,1.45)
static func can_auto_fire(game:Node,actor:Actor) -> bool:
	var p=game.players[game.local_id]
	if not game.profile.get("touch_auto_fire",false) or not game.can_attack(p) or game.phase!="combat" or p.slot>1 or p.reload>0 or p.get("placing","")!="" or p.get("invul_select",0)>game.clock or p.get("cooking",0)>0:return false
	var w=game.current_weapon(p)
	if w.kind!="gun" or int(p.mag.get(p.primary if p.slot==0 else p.secondary,0))<=0:return false
	var direction=Basis(Vector3.UP,actor.input_state.yaw)*Basis(Vector3.RIGHT,actor.input_state.pitch)*Vector3.FORWARD
	var hit=game.ray(actor.eye(),actor.eye()+direction*minf(100.,float(w.get("max_range",100.))),[actor.get_rid()])
	if hit.is_empty() or not hit.collider is Actor:return false
	var target=game.players.get(hit.collider.pid,{})
	return not target.is_empty() and target.alive and game.enemies(p,target) and target.get("protect",0)<=game.clock and target.get("invulnerable",0)<=game.clock and not game.in_smoke_line(actor.eye(),hit.position)
