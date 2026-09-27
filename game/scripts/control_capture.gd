class_name ControlCapture
extends RefCounted
const LABELS=["A","C","B"]
static func in_zone(position:Vector3,origin:Vector3) -> bool:
	return absf(position.y-origin.y)<2. and Vector2(position.x-origin.x,position.z-origin.z).length_squared()<49.
static func speed(count:int) -> float:return 1.+.5*clampi(count-1,0,3)
static func base_seconds(options:Dictionary) -> float:return clampf(float(options.get("capture_seconds",5)),1.,60.)
static func tick(g:Node,dt:float):
	for i in range(3):
		var counts=[0,0]
		for id in g.players:
			if g.players[id].alive and g.actors.has(id) and in_zone(g.actors[id].position,g.arena.zones[i]):counts[int(g.players[id].team)]+=1
		g.zone_counts[i]=counts
		if (counts[0]>0)==(counts[1]>0):continue
		var team=0 if counts[0]>0 else 1
		g.zone_capture[i]=clampf(g.zone_capture[i]+dt*(5./base_seconds(g.options))*speed(counts[team])*(1 if team==0 else -1),-5.,5.)
		if absf(g.zone_capture[i])>=5. and g.zone_owner[i]!=team:
			g.zone_owner[i]=team
			for id in g.players:
				if g.players[id].alive and g.players[id].team==team and g.actors.has(id) and in_zone(g.actors[id].position,g.arena.zones[i]):g.players[id].objective+=2
			g.zone_announcement.rpc(i,team)
static func state(g:Node,index:int) -> Dictionary:
	var counts=g.zone_counts[index];var owner=int(g.zone_owner[index]);var value=float(g.zone_capture[index])
	var team=0 if counts[0]>0 and counts[1]==0 else 1 if counts[1]>0 and counts[0]==0 else 0 if value>0 else 1 if value<0 else -1
	if (counts[0]>0)==(counts[1]>0) and owner>=0 and absf(value)<5.:team=1-owner
	var contested=counts[0]>0 and counts[1]>0
	var progress=1. if team==owner and team>=0 else clampf((value*(1 if team==0 else -1)+5.)/10.,0.,1.) if owner>=0 else absf(value)/5.
	return {"owner":owner,"team":team,"progress":progress,"contested":contested,"count":counts[maxi(0,team)],"active":counts[0]+counts[1]>0}
