class_name MagazineReload
extends RefCounted
static func settle(g:Node,p:Dictionary,w:Dictionary):
	if w.get("single_load",false) and w.reload_style in ["shell","break"]:
		p.fire_ready=maxf(float(p.fire_ready),g.clock+.3)
	elif w.get("single_load",false) and w.reload_style=="rocket":
		# Interrupting a tube-by-tube rocket reload: a short settle before the shot.
		p.fire_ready=maxf(float(p.fire_ready),g.clock+.2)
	# Revolvers (1.4.2) fire at once: the loading simply stops.
## Magazine-fed guns keep a round in the chamber through a reload (+1). Tube,
## break-action, revolver, box-belt, launcher and laser loads do not.
static func chambered(w:Dictionary) -> bool:
	return w.kind=="gun" and not w.get("rocket",false) and not w.get("laser",false) and w.name!="CHIME" and w.reload_style not in ["shell","break","box","revolver","dual"]
static func capacity(w:Dictionary,rounds:int) -> int:
	return int(w.mag)+(2 if w.get("dual",false) else 1) if chambered(w) and rounds>0 else int(w.mag)
## Seconds of one reload cycle: a revolver's full reload time is spread over its
## rounds (loaded one by one); every other gun lists its cycle directly.
static func duration(w:Dictionary) -> float:
	if str(w.get("reload_style",""))=="revolver":return float(w.reload)/maxf(1.,float(w.mag))
	return float(w.reload)
static func progress(g:Node,p:Dictionary,w:Dictionary) -> float:
	return clampf((g.clock-float(p.get("reload_started",0)))/maxf(.01,duration(w)),0.,1.) if p.reload>g.clock else -1.
## Mid-reload steps (server): DUET loads its first pistol halfway through.
static func tick(g:Node,id:int):
	var p=g.players[id]
	if p.reload<=0. or p.get("reload_half",false):return
	var w=Catalog.get_weapon(p.reload_weapon)
	if str(w.get("reload_style",""))!="dual" or g.clock<float(p.reload_started)+duration(w)*.5:return
	p.reload_half=true
	var wid=p.reload_weapon;var need=maxi(0,int(p.get("reload_capacity",w.mag))-int(p.mag.get(wid,0)))
	var got=ceili(need*.5)
	if not g.options.infinite:got=mini(got,int(p.reserve.get(wid,0)))
	p.mag[wid]=int(p.mag.get(wid,0))+got
	if not g.options.infinite:p.reserve[wid]=int(p.reserve.get(wid,0))-got
static func finish(g:Node,id:int):
	var p=g.players[id];var wid=p.reload_weapon;var w=Catalog.get_weapon(wid)
	var need=maxi(0,int(p.get("reload_capacity",w.mag))-int(p.mag.get(wid,0)))
	if w.get("single_load",false):need=mini(1,need)
	var got=need if g.options.infinite else mini(need,int(p.reserve.get(wid,0)))
	p.mag[wid]=int(p.mag.get(wid,0))+got
	if not g.options.infinite:p.reserve[wid]=int(p.reserve.get(wid,0))-got
	p.reload=0.;p.trigger_until=0.;p.reload_half=false
	if w.get("single_load",false) and got>0 and int(p.mag[wid])<int(w.mag) and not g.actors[id].input_state.fire:g.begin_reload(id)
	if p.reload<=0 and str(w.get("reload_style",""))=="shell" and w.get("single_load",false):g.reload_sound.rpc(id,"bolt") # (1.4.10: the pump, once, when the loading ends)
	if p.reload<=0:
		# Full reload timings already include returning the gun to firing position.
		# Only an early exit from a partial tube needs the extra settling delay.
		if int(p.mag[wid])<int(w.mag):settle(g,p,w)
		if w.get("single_load",false) and g.actors[id].input_state.fire:p.trigger_until=maxf(g.clock+.55,float(p.fire_ready)+.1)
		close_cylinder(g,id,w)
## A revolver's loading gate closes when its loading stops (full, out of
## rounds, or a shot fired mid-load).
static func close_cylinder(g:Node,id:int,w:Dictionary):
	var p=g.players[id]
	if str(w.get("reload_style",""))=="revolver" and p.get("revolver_open",false):
		p.revolver_open=false;g.reload_sound.rpc(id,"action_close")
