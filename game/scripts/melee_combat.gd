class_name MeleeCombat
extends RefCounted
# The server samples a short blade/tool arc during the visible contact phase.
# One target can receive at most one hit (or repair) from a complete swing.
const SLOT=4
const REACH=1.45
const INTERVAL=1.4
const CONTACT_START=.07
const CONTACT_END=.20
const DURATION=.44
const STEPS=64
const ZONES={"head":1.5,"torso":1.,"hands":.65,"legs":.75,"feet":.55}
static func wrench(p:Dictionary) -> bool:return int(p.role)==3
static func label(p:Dictionary) -> String:return "렌치" if wrench(p) else "칼"
static func active(p:Dictionary,now:float) -> bool:return now<float(p.get("melee_started",-100.))+DURATION
static func shown(p:Dictionary,now:float) -> bool:return int(p.slot)==SLOT or active(p,now)
static func ready(g:Node,p:Dictionary) -> bool:
	return g.phase=="combat" and g.can_attack(p) and g.clock>=float(p.get("melee_ready",0.)) and p.get("cooking",0)<=0 and p.get("placing","")=="" and p.get("invul_select",0)<=g.clock
static func begin(g:Node,id:int) -> bool:
	var p=g.players[id]
	if not ready(g,p):return false
	p.melee_started=g.clock;p.melee_ready=g.clock+INTERVAL;p.melee_step=-1;p.melee_hits={};p.melee_wall=false
	p.reload=0.;p.burst_left=0;p.trigger_until=0.;p.fire_ready=maxf(p.fire_ready,p.melee_ready)
	g.effect.rpc("melee_swing",g.actors[id].eye(),Vector3.ZERO,id,g.clock,{"wrench":wrench(p)})
	return true
static func tick(g:Node,id:int):
	var p=g.players[id];var age=g.clock-float(p.get("melee_started",-100.))
	if age<CONTACT_START or int(p.get("melee_step",STEPS))>=STEPS:return
	if not p.alive or not g.can_attack(p):p.melee_step=STEPS;return
	var last=clampi(int(floor((age-CONTACT_START)/(CONTACT_END-CONTACT_START)*STEPS)),0,STEPS)
	var a=g.actors[id];var eye=a.eye()-Vector3.UP*.10
	for step in range(int(p.get("melee_step",-1))+1,last+1):
		var arc=lerpf(-1.28,1.28,float(step)/STEPS)*float(p.get("hand",1))
		for height in [0.,-.08,.08]:
			var direction=Basis(Vector3.UP,a.aim_yaw+arc)*Basis(Vector3.RIGHT,a.aim_pitch+height)*Vector3.FORWARD
			var hit=g.ray(eye,eye+direction*REACH,[a.get_rid()])
			if hit.is_empty():continue
			contact(g,id,hit,eye,direction)
	p.melee_step=last
static func contact(g:Node,id:int,hit:Dictionary,origin:Vector3,direction:Vector3):
	var p=g.players[id];var collider=hit.collider;var key=collider.get_instance_id()
	if p.melee_hits.has(key):return
	p.melee_hits[key]=true
	var tool=wrench(p);var base=30. if tool else 40.;var wid="wrench" if tool else "knife"
	if collider is Actor:
		var zone=str(hit.get("zone","torso"))
		var before=float(g.players[collider.pid].hp)+float(g.players[collider.pid].armor)
		g.damage(collider.pid,base*float(ZONES.get(zone,1.)),id,zone=="head",wid,origin,hit.position)
		if float(g.players[collider.pid].hp)+float(g.players[collider.pid].armor)<before:g.effect.rpc("melee_flesh",hit.position,Vector3.ZERO,id)
	elif collider.has_meta("device"):
		var did=int(collider.get_meta("device"))
		if not g.devices.has(did):return
		var d=g.devices[did]
		if tool and d.kind=="turret" and int(d.team)==int(p.team) and int(g.options.mode)!=1:
			var gain=minf(20.,maxf(0.,float(d.max_hp)-float(d.hp)))
			d.hp+=gain
			if gain>0.:
				g.feedback(id,"","포탑 수리 +%d"%roundi(gain));g.effect.rpc("melee_repair",origin,hit.position,id)
		else:g.damage_device(did,base,id)
	elif collider is InteractiveProp:collider.hit(hit.position,direction,base)
	elif not p.get("melee_wall",false):
		p.melee_wall=true;g.melee_mark.rpc(hit.position,hit.normal,direction,tool)
		g.effect.rpc("melee_wall",hit.position,Vector3.ZERO,id,-100.,{"wrench":tool})
