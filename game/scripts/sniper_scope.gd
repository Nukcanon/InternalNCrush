class_name SniperScope
extends RefCounted
const SCREEN_RADIUS=.49
static func supported(w:Dictionary) -> bool:return w.get("category","")=="저격소총"
static func steps(w:Dictionary) -> Array:return w.get("scope_steps",[4,8])
static func magnification(profile:Dictionary,w:Dictionary) -> float:
	var fallback=float(w.get("scope_default",4.))
	var value=float(profile.get("scope_zoom",{}).get(w.name,fallback))
	return value if value in steps(w) else fallback
static func fov(profile:Dictionary,w:Dictionary) -> float:
	return rad_to_deg(2.*atan(tan(deg_to_rad(82.)*.5)/magnification(profile,w))) if supported(w) else float(w.zoom)
static func active(game:Node) -> bool:
	return game.players.has(game.local_id) and game.players[game.local_id].alive and not MeleeCombat.shown(game.players[game.local_id],game.clock) and game.actors[game.local_id].input_state.ads and SniperScope.supported(game.current_weapon(game.players[game.local_id]))
static func change(game:Node,direction:int):
	var w=game.current_weapon(game.players[game.local_id])
	if not supported(w):return
	var values=steps(w);var index=0
	for i in range(values.size()):
		if is_equal_approx(float(values[i]),magnification(game.profile,w)):index=i;break
	if not game.profile.get("scope_zoom",{}) is Dictionary:game.profile.scope_zoom={}
	game.profile.scope_zoom[w.name]=values[clampi(index+direction,0,values.size()-1)]
	game.save_profile()
static func sensitivity(game:Node,touch:bool=false) -> float:
	var w=game.current_weapon(game.players[game.local_id])
	return clampf(float(game.profile.get("sniper_touch_sensitivity" if touch else "sniper_mouse_sensitivity",.75)),.1,2.)*4./magnification(game.profile,w)

