class_name TouchAim
extends RefCounted
## Gentle, bounded camera assistance. Never changes damage or server hit tests.
# User-selected maximum magnetic assistance distance, in world metres.
const MAX_DISTANCE=40.
static func scoped_weapon(w:Dictionary) -> bool:
	return w.get("category","") in ["저격소총","지정사수소총"] and float(w.get("zoom",82.))<=38.
static func capture_angle(game:Node,w:Dictionary) -> float:
	# Keep the capture area within 3.5% of the zoomed screen half-height.
	return atan(tan(deg_to_rad(SniperScope.fov(game.profile,w))*.5)*.035) if scoped_weapon(w) else deg_to_rad(4.)
static func assist(game:Node,actor:Actor,dt:float):
	if not TouchControls.supported():return
	var p=game.players[game.local_id]
	if not game.profile.get("touch_aim_assist",true) or not game.can_attack(p) or game.phase!="combat" or p.slot>1 or MeleeCombat.active(p,game.clock) or p.reload>0 or p.get("placing","")!="" or game.current_weapon(p).kind!="gun":return
	var weapon=game.current_weapon(p);var scoped=scoped_weapon(weapon)
	if scoped and (not actor.input_state.ads or actor.ads_blend<=.9):return
	var forward=Basis(Vector3.UP,actor.input_state.yaw)*Basis(Vector3.RIGHT,actor.input_state.pitch)*Vector3.FORWARD
	var best=cos(capture_angle(game,weapon));var direction=Vector3.ZERO
	for id in game.players:
		var other=game.players[id]
		if id==game.local_id or not other.alive or not game.enemies(p,other) or not game.actors.has(id):continue
		var target=game.actors[id];var point=target.eye()-Vector3.UP*.35;var delta=point-actor.eye()
		if delta.length_squared()>MAX_DISTANCE*MAX_DISTANCE or delta.length_squared()<.01:continue
		var dot=forward.dot(delta.normalized())
		if dot<=best or game.in_smoke_line(actor.eye(),point) or not game.clear_line(actor.eye(),point,[actor.get_rid(),target.get_rid()]):continue
		best=dot;direction=delta.normalized()
	if direction==Vector3.ZERO:return
	var limit=deg_to_rad(30.)*minf(dt,.05)
	var response=1.-exp(-12.*minf(dt,.05))
	# Reduce assistance under high magnification; user input remains dominant.
	if scoped:
		limit*=clampf(SniperScope.fov(game.profile,weapon)/82.,.05,1.)
		response=1.-exp(-6.*minf(dt,.05))
	var yaw=atan2(-direction.x,-direction.z);var pitch=asin(clampf(direction.y,-1.,1.))
	actor.input_state.yaw+=clampf(wrapf(yaw-actor.input_state.yaw,-PI,PI)*response,-limit,limit)
	actor.input_state.pitch=clampf(actor.input_state.pitch+clampf((pitch-actor.input_state.pitch)*response,-limit,limit),-1.45,1.45)
static func can_auto_fire(game:Node,actor:Actor) -> bool:
	if not TouchControls.supported():return false
	var p=game.players[game.local_id]
	if not game.profile.get("touch_auto_fire",false) or not game.can_attack(p) or game.phase!="combat" or p.slot>1 or MeleeCombat.active(p,game.clock) or p.reload>0 or p.get("placing","")!="" or p.get("invul_select",0)>game.clock or p.get("cooking",0)>0:return false
	var w=game.current_weapon(p)
	if w.kind=="heal":return p.energy>0 and MedicLink.target(game,game.local_id)!=0
	if w.kind!="gun" or int(p.mag.get(p.primary if p.slot==0 else p.secondary,0))<=0:return false
	var direction=Basis(Vector3.UP,actor.input_state.yaw)*Basis(Vector3.RIGHT,actor.input_state.pitch)*Vector3.FORWARD
	var hit=game.ray(actor.eye(),actor.eye()+direction*minf(100.,float(w.get("max_range",100.))),[actor.get_rid()])
	if hit.is_empty() or not hit.collider is Actor:return false
	var target=game.players.get(hit.collider.pid,{})
	return not target.is_empty() and target.alive and (game.enemies(p,target) or float(w.get("heal_per_pellet",0.))>0.) and target.get("protect",0)<=game.clock and target.get("invulnerable",0)<=game.clock and not game.in_smoke_line(actor.eye(),hit.position)
