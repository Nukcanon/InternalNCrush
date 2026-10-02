extends RefCounted
class_name Catalog
static var weapons:Dictionary={}
# 1.5.3 (the user): a gun's stability sets its spread. The geometric mean of its hip and
# aimed spread is SPREAD_AT_ZERO * exp(-SPREAD_PER_POINT * stability) (degrees), and
# "aim_ratio" (aimed / hip) splits it into the two; each gun's stability was worked back
# from its spread before. (The old stability numbers moved to "shake": the view gun's kick.)
const SPREAD_AT_ZERO=3.2
const SPREAD_PER_POINT=.0306
static func stability_spread(stability:float) -> float:return SPREAD_AT_ZERO*exp(-SPREAD_PER_POINT*stability)
static func derive_spread(w:Dictionary):
	if not w.has("aim_ratio"):return
	var mean=stability_spread(float(w.get("stability",50)));var ratio=sqrt(float(w.aim_ratio))
	w.spread=mean/ratio;w.ads_spread=mean*ratio
static func load_all():
	if weapons.is_empty():
		weapons=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons.json"))
		for id in weapons:derive_spread(weapons[id])
static func get_weapon(id:String) -> Dictionary:
	load_all(); return weapons.get(id,weapons["pistol"])
static func list_for(c:int, classes:bool=true) -> Array:
	load_all();var out=[]
	for k in weapons:
		if weapons[k].slot==0 and (not classes or int(weapons[k].role)==c):out.append(k)
	return out
static func first(c:int) -> String:
	return list_for(c)[0]
static func secondaries_for(role:int) -> Array:
	var ids=["pistol","heavy_pistol","auto_pistol","dual_pistols"]
	if Rules.SECONDARIES[role] not in ids:ids.append(Rules.SECONDARIES[role])
	if role==3:ids.append("repair")
	return ids
