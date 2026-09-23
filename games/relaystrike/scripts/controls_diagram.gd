extends Control
class_name ControlsDiagram
var key_rects={}
var font:Font
var color=Color("7be2ce")
func _ready():
	font=get_theme_default_font();mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()
func keycap(text:String,pos:Vector2,width=42.,active=false):
	var rect=Rect2(pos,Vector2(width,37));var style=StyleBoxFlat.new();style.bg_color=Color("305e6c") if active else Color("233a4a");style.border_color=color if active else Color("4d6575");style.set_border_width_all(1);style.set_corner_radius_all(6);draw_style_box(style,rect)
	draw_string(font,pos+Vector2(7,25),text,HORIZONTAL_ALIGNMENT_CENTER,width-14,16,Color.WHITE);key_rects[text]=rect
func callout(key:String,text:String,to:Vector2,above:bool):
	var rect:Rect2=key_rects[key];var start=Vector2(rect.get_center().x,rect.position.y if above else rect.end.y)
	var end=to+Vector2(3,7 if above else -18);var bend=Vector2(start.x,end.y)
	draw_polyline(PackedVector2Array([start,bend,end]),color,1.5,true);draw_circle(start,2.5,color);draw_string(font,to,text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e8f4f5"))
func _draw():
	if font==null:return
	key_rects.clear()
	var rows=[["Esc","1","2","3","4","5","6","7","8","9","0"],["Tab","Q","W","E","R","T","Y","U","I","O","P"],["Caps","A","S","D","F","G","H","J","K","L"],["Shift","Z","X","C","V","B","N","M"]]
	var active=["Esc","1","2","3","4","Tab","Q","W","E","R","Ctrl","A","S","D","F","G","Shift","V","B"]
	for row in range(rows.size()):
		var x=18.
		for key in rows[row]:
			var width=66. if key in ["Esc","Tab","Caps","Shift"] else 42.
			keycap(key,Vector2(x,100+row*43),width,key in active);x+=width+5
	keycap("Ctrl",Vector2(18,272),66,true)
	keycap("Space",Vector2(172,272),244,true)
	callout("Esc","메뉴",Vector2(18,44),true);callout("1","1–4 장비 선택",Vector2(135,73),true);callout("R","R 재장전",Vector2(318,44),true)
	callout("W","WASD 이동",Vector2(365,330),false);callout("Shift","Shift 달리기",Vector2(18,371),false);callout("Ctrl","Ctrl 앉기",Vector2(18,333),false);callout("Space","Space 점프",Vector2(290,389),false)
	var mouse=Rect2(673,130,129,191);var style=StyleBoxFlat.new();style.bg_color=Color("233a4a");style.border_color=Color("7b96a6");style.set_border_width_all(2);style.set_corner_radius_all(46);draw_style_box(style,mouse)
	draw_line(Vector2(737,130),Vector2(737,231),color,2);draw_line(Vector2(675,229),Vector2(800,229),color,2)
	var wheel=StyleBoxFlat.new();wheel.bg_color=color;wheel.set_corner_radius_all(5);draw_style_box(wheel,Rect2(731,164,12,34))
	draw_polyline(PackedVector2Array([Vector2(703,173),Vector2(636,173),Vector2(636,100)]),color,1.5,true);draw_string(font,Vector2(590,88),"왼쪽 · 발사",HORIZONTAL_ALIGNMENT_LEFT,-1,18)
	draw_polyline(PackedVector2Array([Vector2(771,173),Vector2(842,173),Vector2(842,100)]),color,1.5,true);draw_string(font,Vector2(745,88),"오른쪽 · 정조준",HORIZONTAL_ALIGNMENT_LEFT,-1,18)
	draw_line(Vector2(737,324),Vector2(737,350),color,1.5);draw_string(font,Vector2(640,376),"마우스 이동 · 시점",HORIZONTAL_ALIGNMENT_LEFT,-1,18)
