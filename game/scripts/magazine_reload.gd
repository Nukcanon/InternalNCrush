class_name MagazineReload
extends RefCounted
static func settle(g:Node,p:Dictionary,w:Dictionary):
	if w.get("single_load",false) and w.reload_style in ["shell","break"]:
		p.fire_ready=maxf(float(p.fire_ready),g.clock+.3)
static func chambered(w:Dictionary) -> bool:
	return w.kind=="gun" and not w.get("rocket",false) and not w.get("laser",false) and w.name!="CHIME" and w.reload_style not in ["shell","break","box"]
static func capacity(w:Dictionary,rounds:int) -> int:
	return int(w.mag)+(2 if w.get("dual",false) else 1) if chambered(w) and rounds>0 else int(w.mag)
static func finish(g:Node,id:int):
	var p=g.players[id];var wid=p.reload_weapon;var w=Catalog.get_weapon(wid)
	var need=maxi(0,int(p.get("reload_capacity",w.mag))-int(p.mag.get(wid,0)))
	if w.get("single_load",false):need=mini(1,need)
	var got=need if g.options.infinite else mini(need,int(p.reserve.get(wid,0)))
	p.mag[wid]=int(p.mag.get(wid,0))+got
	if not g.options.infinite:p.reserve[wid]=int(p.reserve.get(wid,0))-got
	p.reload=0.;p.trigger_until=0.
	if w.get("single_load",false) and got>0 and int(p.mag[wid])<int(w.mag) and not g.actors[id].input_state.fire:g.begin_reload(id)
	if p.reload<=0:
		# Full reload timings already include returning the gun to firing position.
		# Only an early exit from a partial tube needs the extra settling delay.
		if int(p.mag[wid])<int(w.mag):settle(g,p,w)
		if w.get("single_load",false) and g.actors[id].input_state.fire:p.trigger_until=maxf(g.clock+.55,float(p.fire_ready)+.1)
