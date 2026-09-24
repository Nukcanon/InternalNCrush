class_name HudPreview
extends Control
var game:Node
func _ready():custom_minimum_size=Vector2(0,230);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	if not game:return
	var factor=minf(size.x/1280.,size.y/720.);var offset=(size-Vector2(1280,720)*factor)*.5
	draw_set_transform(offset,0,Vector2.ONE*factor)
	draw_rect(Rect2(0,0,1280,720),Color("3f5965"));draw_rect(Rect2(0,330,1280,390),Color("7c7562"))
	for box in [Rect2(85,180,210,330),Rect2(965,140,215,340),Rect2(455,290,370,160)]:draw_rect(box,Color("697982"))
	var amount=float(game.profile.hud_scale);var font=get_theme_default_font();var fill=Color(.035,.075,.1,float(game.profile.hud_opacity))
	for key in HudLayout.ORIGINS:
		var point=HudLayout.position_for(key,amount)
		var dimensions={"health":Vector2(259,98),"ammo":Vector2(263,116),"gear":Vector2(650,139),"time":Vector2(468,49)}[key]
		draw_rect(Rect2(point,dimensions*amount),fill)
		var content={"health":"MASON\nBLUE   100 HP","ammo":"VECTOR-24","gear":"1   2   3   4       F\nB 병과/장비    E 상호작용","time":"12         08:42         9"}[key]
		var index=0
		for line in content.split("\n"):
			draw_string(font,point+Vector2(12,(28+index*32))*amount,line,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi((20 if key=="time" else 25)*amount),Color("77caff") if key=="health" else Color("f0f5f6"));index+=1
		if key=="ammo":
			for i in range(15):
				var x=point.x+(20+i*15)*amount;var y=point.y+55*amount
				draw_colored_polygon(PackedVector2Array([Vector2(x,y+19*amount),Vector2(x,y+4*amount),Vector2(x+4*amount,y),Vector2(x+8*amount,y+4*amount),Vector2(x+8*amount,y+19*amount)]),Color("f4d19a") if i<11 else Color(0,0,0,.35))
	draw_line(Vector2(633,360),Vector2(647,360),Color.WHITE,2.);draw_line(Vector2(640,353),Vector2(640,367),Color.WHITE,2.)
