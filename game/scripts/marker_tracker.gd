class_name MarkerTracker
extends RefCounted
const DWELL_SECONDS=1.8 # 1.4.5: 1.8 s (was 1.5)
const HALF_ANGLE_DEGREES=1.25 # base cone; see half_angle()
# 1.4.5: the cone is 1.5x the base on the 4/8/16x sniper scopes and 2x on the
# designated marksman rifles.
static func half_angle(w:Dictionary) -> float:
	return HALF_ANGLE_DEGREES*(2. if str(w.get("category",""))=="지정사수소총" else 1.5)
static func equipped(p:Dictionary) -> bool:return int(p.role)==1 and int(p.gadget)==0 and GadgetLoadout.has_item(p)
static func eligible(game:Node,id:int,other:int) -> bool:
	if other==id or not game.players.has(other) or not game.actors.has(other):return false
	var p=game.players[id];var q=game.players[other]
	if not q.alive or not game.enemies(p,q) or q.get("cleanse",0)>game.clock or TargetReveal.visible_to(game,other,id):return false
	var a=game.actors[id];var actor=game.actors[other];var point=actor.eye()-Vector3.UP*.25;var delta=point-a.eye()
	if delta.length()>160. or delta.length_squared()<.001:return false
	return a.direction().dot(delta.normalized())>=cos(deg_to_rad(half_angle(game.current_weapon(p)))) and not game.in_smoke_line(a.eye(),point) and game.clear_line(a.eye(),point,[a.get_rid(),actor.get_rid()])
static func select_target(game:Node,id:int) -> int:
	var locked=int(game.players[id].get("marker_target",0))
	if eligible(game,id,locked):return locked
	var best=INF;var target=0
	for other in game.players:
		if not eligible(game,id,other):continue
		var distance=game.actors[id].eye().distance_squared_to(game.actors[other].eye())
		if distance<best or (is_equal_approx(distance,best) and other<target):best=distance;target=other
	return target
static func tick(game:Node,id:int,dt:float):
	var p=game.players[id];var a=game.actors[id];var w=game.current_weapon(p)
	if not equipped(p) or not game.options.classes or not game.can_attack(p) or not a.input_state.ads or p.slot>1 or w.get("category","") not in ["저격소총","지정사수소총"] or p.reload>game.clock or p.flash>game.clock or a.aim_progress<.9:
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
		TargetReveal.mark(game,target,id,6.);p.marker_progress=0.;p.marker_target=0
		game.feedback(id,"mark","표식 완료 · 6초 동안 팀에 위치 공유") # (1.5.4, the user: a soft bell when the mark lands)
		game.feedback(target,"","표식 감지 · 6초 동안 위치가 노출됩니다.")
