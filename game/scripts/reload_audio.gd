class_name ReloadAudio
extends RefCounted
static func cues(w:Dictionary,count:int,tactical:bool=false) -> Array:
	var style=str(w.reload_style);var name=str(w.name)
	if style=="battery":return [[.08,"reload"],[ReloadMotion.SEAT,"magazine"],[.87,"action_close"]]
	# Revolvers: one round per cycle (the gate opens and closes in game.gd).
	if style=="revolver":return [[.6,"shell_insert"]]
	# DUET: each pistol out of view and back loaded in turn.
	if style=="dual":return [[.02,"reload"],[.36,"pistol_magazine"],[.86,"pistol_magazine"]]
	# 1.5.0 (the user): a pump gun loads one shell per cycle with no pump between -
	# the pump sounds once when the loading ends (MagazineReload.finish).
	if style=="shell" and bool(w.get("single_load",false)):return [[.66,"shell_insert"]]
	if style=="shell":
		var events=[[.01,"reload"]]
		for i in range(maxi(1,count)):events.append([.08+.72*(i+.55)/maxi(1,count),"shell_insert"])
		events.append([.86,"bolt"]);return events
	if style=="break":return [[.08,"action_close"],[.50,"shell_insert"],[.85,"action_close"]]
	if style=="rocket":return [[.05,"reload"],[.68,"rocket_insert"],[.84,"action_close"]]
	# The new magazine seats at ReloadMotion.SEAT (the rounds come back then).
	# 1.5.0 (the user): a pistol run dry has its slide locked back - the new magazine
	# seats and the slide snaps forward (no rack at the end).
	# (1.5.1, the user: a pistol's magazine seats with its own click, from their clip)
	if style=="pistol" and not tactical:return [[.02,"reload"],[ReloadMotion.SEAT,"pistol_magazine"],[ReloadMotion.SEAT+.04,"action_close"]]
	if style=="pistol":return [[.02,"reload"],[ReloadMotion.SEAT,"pistol_magazine"]]
	# (1.5.3, the user: every magazine-fed gun seats its magazine with the pistol's click)
	return [[.02,"reload"],[ReloadMotion.SEAT,"pistol_magazine"]] if tactical else [[.02,"reload"],[ReloadMotion.SEAT,"pistol_magazine"],[.86,"bolt"]]
static func tick(g:Node,id:int):
	var p=g.players[id]
	if p.reload<=0.:return
	var w=Catalog.get_weapon(p.reload_weapon)
	var progress=clampf((g.clock-float(p.reload_started))/maxf(.01,MagazineReload.duration(w)),0.,1.)
	var events=cues(w,int(p.get("reload_count",3)),bool(p.get("reload_tactical",false)));var played=int(p.get("reload_cues",0))
	while played<events.size() and progress>=events[played][0]:
		g.reload_sound.rpc(id,str(events[played][1]));played+=1
	p.reload_cues=played
