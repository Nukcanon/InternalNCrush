extends RefCounted
class_name Catalog
static var weapons:Dictionary={}
static func load_all():
	if weapons.is_empty(): weapons=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons.json"))
static func get_weapon(id:String) -> Dictionary:
	load_all(); return weapons.get(id,weapons["pistol"])
static func list_for(c:int, classes:bool=true) -> Array:
	load_all();var out=[]
	for k in weapons:
		if weapons[k].slot==0 and (not classes or int(weapons[k].role)==c):out.append(k)
	return out
static func first(c:int) -> String:
	return list_for(c)[0]
