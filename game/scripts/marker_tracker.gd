class_name MarkerTracker
extends RefCounted
const DWELL_SECONDS=2.
static func equipped(p:Dictionary) -> bool:return int(p.role)==1 and int(p.gadget)==0
static func select_target(game:Node,id:int) -> int:
	var p=game.players[id];var a=game.actors[id];var w=game.current_weapon(p)
	var fov=float(w.zoom)
	if SniperScope.supported(w):
		var zoom=float(a.input_state.get("scope_zoom",w.get("scope_default",4.)))
		if not zoom in SniperScope.steps(w):zoom=float(w.get("scope_default",4.))
		fov=rad_to_deg(2.*atan(tan(deg_to_rad(82.)*.5)/zoom))
	var threshold=cos(atan(tan(deg_to_rad(fov)*.5)*SniperScope.SCREEN_RADIUS*2.));var best=threshold;var target=0
	for other in game.players:
		var q=game.players[other]
		if other==id or not q.alive or not game.enemies(p,q) or q.get("cleanse",0)>game.clock:continue
		var actor=game.actors[other];var point=actor.eye()-Vector3.UP*.25;var delta=point-a.eye()
		if delta.length()>160. or delta.length_squared()<.001:continue
		var alignment=a.direction().dot(delta.normalized())
		if alignment<=best or game.in_smoke_line(a.eye(),point) or not game.clear_line(a.eye(),point,[a.get_rid(),actor.get_rid()]):continue
		best=alignment;target=other
	return target
static func tick(game:Node,id:int,dt:float):
	var p=game.players[id];var a=game.actors[id];var w=game.current_weapon(p)
	if not equipped(p) or not game.options.classes or not game.can_attack(p) or not a.input_state.ads or p.slot>1 or float(w.zoom)>38 or p.reload>game.clock or p.flash>game.clock or a.aim_progress<.9:
		p.marker_target=0;p.marker_progress=0.;p.marker_scan=0.;return
	p.marker_scan=float(p.get("marker_scan",0))+dt
	if p.marker_scan<.1:return
	var elapsed=minf(.15,p.marker_scan);p.marker_scan=0.
	var target=select_target(game,id)
	if target==0 or target!=int(p.get("marker_target",0)):p.marker_progress=0.
	p.marker_target=target
	if target==0:return
	p.marker_progress=float(p.get("marker_progress",0))+elapsed
	if p.marker_progress>=DWELL_SECONDS-.00001:
		TargetReveal.mark(game,target,id,6.);p.marker_progress=0.
		game.feedback(target,"","표식 감지 · 6초 동안 위치가 노출됩니다.")
