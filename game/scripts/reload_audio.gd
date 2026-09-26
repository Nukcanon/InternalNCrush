class_name ReloadAudio
extends RefCounted
static func cues(w:Dictionary,count:int) -> Array:
	var style=str(w.reload_style);var name=str(w.name)
	if name=="CHIME":return [[.02,"reload"],[.55,"shell_insert"],[.86,"action_close"]]
	if style=="shell":
		var events=[[.01,"reload"]]
		for i in range(maxi(1,count)):events.append([.08+.72*(i+.55)/maxi(1,count),"shell_insert"])
		events.append([.86,"bolt"]);return events
	if style=="break":return [[.08,"action_close"],[.50,"shell_insert"],[.85,"action_close"]]
	if style=="rocket":return [[.05,"reload"],[.68,"rocket_insert"],[.84,"action_close"]]
	return [[.02,"reload"],[.50,"magazine"],[.84,"bolt"]]
static func tick(g:Node,id:int):
	var p=g.players[id]
	if p.reload<=0.:return
	var w=Catalog.get_weapon(p.reload_weapon)
	var progress=clampf((g.clock-float(p.reload_started))/maxf(.01,float(w.reload)),0.,1.)
	var events=cues(w,int(p.get("reload_count",3)));var played=int(p.get("reload_cues",0))
	while played<events.size() and progress>=events[played][0]:
		g.reload_sound.rpc(id,str(events[played][1]));played+=1
	p.reload_cues=played
