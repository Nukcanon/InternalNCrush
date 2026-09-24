extends RefCounted
class_name GrenadeLogic
const FUSE=3.0
const RADIUS=5.5
const DAMAGE=120.0
static func equipped(p:Dictionary) -> bool:return int(p.role)==0 and int(p.gadget)==1
static func begin(g:Node,id:int,source:String="key") -> bool:
	var p=g.players[id]
	if not equipped(p) or not g.options.classes or g.phase!="combat" or not g.can_attack(p) or p.gadget_count<=0 or g.clock<p.gadget_ready or p.get("cooking",0)>0:return false
	var serial=g.next_grenade;g.next_grenade+=1;p.cooking=serial;p.cook_input=source;p.gadget_count-=1;p.gadget_ready=g.clock+.5;p.grenade_started=g.clock
	g.grenades.append({"id":serial,"owner":id,"pos":g.actors[id].muzzle_world(),"velocity":Vector3.ZERO,"until":g.clock+FUSE,"held":true,"released":-100.})
	g.feedback(id,"bolt","수류탄 안전핀 해제 · 3초 · 놓으면 투척")
	return true
static func release(g:Node,id:int):
	if not g.players.has(id):return
	var p=g.players[id];var serial=int(p.get("cooking",0))
	if serial==0:return
	p.cooking=0;p.throw_until=g.clock+.45
	for item in g.grenades:
		if item.id!=serial:continue
		var a=g.actors[id];item.held=false;item.released=g.clock;item.pos=a.muzzle_world();item.velocity=a.direction()*15.+Vector3.UP*3.+a.velocity*.35
		return
static func tick(g:Node,dt:float):
	for item in g.grenades.duplicate():
		var id=int(item.owner)
		if item.held:
			if g.actors.has(id):item.pos=g.actors[id].muzzle_world()
			if not g.players.has(id) or not g.players[id].alive:
				item.held=false;item.velocity=Vector3.ZERO
				if g.players.has(id):g.players[id].cooking=0
		else:
			var steps=maxi(1,ceili(dt/.02));var step=dt/steps
			for substep in range(steps):
				item.velocity.y-=16.*step
				var end:Vector3=item.pos+item.velocity*step
				var excluded=[g.actors[id].get_rid()] if g.actors.has(id) and g.clock-float(item.released)<.3 else []
				var hit=g.ray(item.pos,end+item.velocity.normalized()*.09,excluded)
				if hit.is_empty():item.pos=end
				else:
					item.pos=hit.position+hit.normal*.095;item.velocity=item.velocity.bounce(hit.normal)*.46
					if hit.normal.y>.6:item.velocity.x*=.78;item.velocity.z*=.78
		if g.clock>=float(item.until):
			if g.players.has(id):g.players[id].cooking=0
			explode(g,item.pos,id);g.grenades.erase(item)
static func explode(g:Node,pos:Vector3,owner:int):
	g.event_fx.rpc("explosion",pos,Vector3.ZERO,owner)
	for id in g.players:
		if not g.players[id].alive:continue
		var a=g.actors[id];var center=a.position+Vector3.UP*(.83 if a.input_state.crouch else 1.)*a.body_height/1.8
		var distance=pos.distance_to(center)
		if distance>RADIUS or not g.clear_line(pos,center,[a.get_rid()]):continue
		var amount=DAMAGE*pow(1.-clampf((distance-.7)/(RADIUS-.7),0.,1.),1.2)
		g.damage(id,amount,owner,false,"frag",pos,center)
	for did in g.devices.keys():
		var d=g.devices[did];var point=d.pos+Vector3.UP*.8;var excluded=[g.device_nodes[did].get_rid()] if g.device_nodes.has(did) else []
		if pos.distance_to(point)<RADIUS and g.clear_line(pos,point,excluded):g.damage_device(did,DAMAGE*(1.-pos.distance_to(point)/RADIUS),owner)
	for prop in g.arena.props.values():
		var offset=prop.global_position-pos
		if offset.length()<RADIUS and g.clear_line(pos,prop.global_position,[prop.get_rid()]):prop.hit(prop.global_position,offset.normalized(),DAMAGE*(1.-offset.length()/RADIUS))
