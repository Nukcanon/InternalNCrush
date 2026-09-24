extends RefCounted
class_name CombatBalance

static func range_factor(w:Dictionary,distance:float) -> float:
	if distance>float(w.get("max_range",300.)):return 0.
	var start=float(w.get("reach",30.));var end=float(w.get("falloff_end",start*2.))
	return lerpf(1.,float(w.get("min_damage_scale",.4)),clampf((distance-start)/maxf(1.,end-start),0.,1.))
static func hit_zone(height:float,body_height:float,crouch:bool) -> String:
	var scale=body_height/1.8
	if height>(1.14 if crouch else 1.46)*scale:return "head"
	if height<( .53 if crouch else .78)*scale:return "legs"
	return "torso"
static func damage_at(w:Dictionary,distance:float,zone:String="torso") -> float:
	return float(w.damage)*range_factor(w,distance)*float(w.get("zone_multipliers",{}).get(zone,1.))
static func sustained_rpm(w:Dictionary) -> float:
	return 180./(float(w.interval)*2.+float(w.get("burst_pause",.3))) if w.get("fire_mode","")=="burst" else 60./float(w.interval)
static func firing_dps(w:Dictionary) -> float:
	return float(w.damage)*int(w.pellets)*sustained_rpm(w)/60. if w.kind=="gun" else 0.
static func magazine_seconds(w:Dictionary) -> float:
	var gaps=maxi(0,int(w.mag)-1)
	if w.get("fire_mode","")=="burst":return floor(gaps/3.)*(float(w.interval)*2.+float(w.burst_pause))+(gaps%3)*float(w.interval)
	return gaps*float(w.interval)
static func sustained_dps(w:Dictionary) -> float:
	if w.kind!="gun":return 0.
	return float(w.damage)*int(w.pellets)*int(w.mag)/(magazine_seconds(w)+maxf(float(w.reload),float(w.interval)))
static func pellet_sample(index:int,count:int,rotation:float) -> Vector2:
	# Stratified disc: prevents a random cluster of shotgun pellets acting like a slug.
	return Vector2((index+.5)/maxi(1,count),fposmod(rotation+index*.61803398875,1.))
