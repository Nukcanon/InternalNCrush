extends Control
class_name WeaponGlyph
var weapon="a1"
var ink=Color("eff6fa")
func _ready():
	custom_minimum_size=Vector2(88,27);mouse_filter=Control.MOUSE_FILTER_IGNORE
func shape(points:Array):
	var polygon=PackedVector2Array()
	for point in points:polygon.append(Vector2(point[0],point[1]))
	draw_colored_polygon(polygon,ink)
func _draw():
	draw_set_transform(Vector2((size.x-88)/2.,(size.y-27)/2.))
	if weapon=="turret":
		shape([[24,5],[59,5],[59,9],[80,9],[80,13],[54,13],[51,18],[33,18],[24,14]])
		draw_rect(Rect2(39,18,6,5),ink);draw_line(Vector2(42,21),Vector2(22,26),ink,3);draw_line(Vector2(42,21),Vector2(64,26),ink,3);return
	if not Catalog.weapons.has(weapon):
		shape([[44,2],[56,14],[44,26],[32,14]]);return
	var data=Catalog.get_weapon(weapon);var variant=int(data.get("model_index",0))%3
	if int(data.slot)==1:
		var length=47+variant*5
		shape([[20,5],[length+20,5],[length+20,13],[43,13],[37,25],[23,25],[29,13],[20,13]])
		draw_rect(Rect2(25,2,5,4),ink);draw_rect(Rect2(length+12,2,4,4),ink)
		if weapon=="auto_pistol":draw_rect(Rect2(47,13,6,12),ink)
		return
	var role=int(data.role);var barrel=84 if role==1 else 79 if role in [2,3] else 68 if role==4 else 76
	shape([[4,10],[17,10],[22,7],[56,7],[61,10],[barrel,10],[barrel,14],[56,14],[50,18],[32,18],[29,26],[23,26],[25,17],[17,16],[4,20]])
	if role==1:
		draw_rect(Rect2(28,1,22,5),ink);draw_rect(Rect2(33,5,3,4),ink);draw_rect(Rect2(44,5,3,4),ink)
	elif role==2:
		draw_rect(Rect2(35,17,16,10),ink);draw_line(Vector2(62,15),Vector2(68,26),ink,2)
	elif role==3:
		draw_rect(Rect2(46,14,24,4),ink)
	else:
		shape([[38,17],[45,17],[48+variant,26],[40+variant,26]])
		draw_rect(Rect2(30+variant*4,3,10,5),ink)
