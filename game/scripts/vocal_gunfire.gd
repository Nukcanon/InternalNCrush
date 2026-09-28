extends RefCounted
class_name VocalGunfire
const FAMILIES=["pistol","smg","rifle","machinegun","sniper","shotgun","energy"]
static func path(family:String) -> String:return "res://assets/audio/vocal_"+family+".wav"
static func ready() -> bool:
	return FAMILIES.all(func(family):return ResourceLoader.exists(path(family)))
static func family(key:String,catalog:Dictionary) -> String:
	if key in ["laser_fire","link_fire"]:return "energy"
	if not key.begins_with("gun_"):return ""
	var kind=str(catalog.get(key,{}).get("family","rifle"))
	match kind:
		"pistol","revolver":return "pistol"
		"smg":return "smg"
		"lmg","machinegun":return "machinegun"
		"sniper","dmr":return "sniper"
		"shotgun","rocket":return "shotgun"
		"laser","medic","medic_rifle","medic_shotgun","link","energy":return "energy"
	return "rifle"
