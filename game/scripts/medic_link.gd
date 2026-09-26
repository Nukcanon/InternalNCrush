class_name MedicLink
extends RefCounted
const RATE=20.
const RANGE=15.
const RETAIN_ANGLE=100.
static func valid(g:Node,id:int,target:int,check_angle=true) -> bool:
	if target==id or not g.players.has(target) or not g.actors.has(target):return false
	var p=g.players[id];var q=g.players[target]
	if not q.alive or g.enemies(p,q):return false
	var a=g.actors[id];var b=g.actors[target];var point=b.eye()-Vector3.UP*.3;var delta=point-a.eye()
	if delta.length()>RANGE:return false
	if check_angle:
		var yaw=atan2(-delta.x,-delta.z);var pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
		if absf(wrapf(yaw-a.aim_yaw,-PI,PI))>deg_to_rad(RETAIN_ANGLE) or absf(pitch-a.aim_pitch)>deg_to_rad(RETAIN_ANGLE):return false
	return g.clear_line(a.eye(),point,[a.get_rid(),b.get_rid()])
static func target(g:Node,id:int) -> int:
	var previous=int(g.players[id].get("link_target",0))
	if valid(g,id,previous):return previous
	var selected=g.aim_player(id,RANGE,true)
	return selected if valid(g,id,selected) else 0
static func tick(g:Node,id:int,dt:float):
	var p=g.players[id];var a=g.actors[id]
	if not p.alive or p.slot!=0 or g.current_weapon(p).kind!="heal" or not a.input_state.fire or not g.can_attack(p) or MeleeCombat.active(p,g.clock) or p.reload>0 or a.last_sprint or g.clock<a.sprint_release or p.get("cooking",0)>0 or p.get("placing","")!="":
		p.link_target=0;return
	var tid=target(g,id);p.link_target=tid
	if tid==0 or p.energy<=0:return
	var amount=minf(RATE*dt,float(p.energy))
	if g.players[tid].hp<Rules.max_hp(g.players[tid]):
		var before=float(g.players[tid].hp);g.heal_target(id,tid,amount,true,false)
		p.energy=maxf(0.,p.energy-(float(g.players[tid].hp)-before))
	if g.clock>=float(p.get("link_fx_ready",0)):
		p.link_fx_ready=g.clock+.1
		g.effect.rpc("heal",a.muzzle_world(),g.actors[tid].eye()-Vector3.UP*.3,id,-100.,{"target":tid})
