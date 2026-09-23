extends Control
class_name HudSymbols
var game:Node
var ui:Node
const WHITE=Color("f1f4f6")
const GOLD=Color("ffc66b")
static func key_style() -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=Color(.12,.16,.20,.85);s.border_color=Color("b7c5cf");s.set_border_width_all(1);s.border_width_bottom=3;s.set_corner_radius_all(4);return s
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_dt):queue_redraw()
func keycap(text:String,pos:Vector2,width:float=26.):
	draw_style_box(key_style(),Rect2(pos,Vector2(width,25)))
	draw_string(get_theme_default_font(),pos+Vector2(1,18),text,HORIZONTAL_ALIGNMENT_CENTER,width-2,13,WHITE)
func icon(role:int,center:Vector2,radius:float,color:Color):
	match role:
		0:
			for shift in [-.25,.25]:draw_polyline(PackedVector2Array([center+Vector2(-.6+shift,.45)*radius,center+Vector2(shift,-.55)*radius,center+Vector2(.1+shift,.25)*radius]),color,3.,true)
		1:
			for r in [.3,.65,1.]:draw_arc(center,radius*r,-PI*.9,-PI*.1,24,color,2.,true)
			draw_circle(center+Vector2(0,radius*.1),3.,color)
		2:draw_polyline(PackedVector2Array([center+Vector2(-.65,-.6)*radius,center+Vector2(.65,-.6)*radius,center+Vector2(.5,.3)*radius,center+Vector2(0,.8)*radius,center+Vector2(-.5,.3)*radius,center+Vector2(-.65,-.6)*radius]),color,3.,true)
		3:
			draw_rect(Rect2(center-Vector2(radius*.55,radius*.35),Vector2(radius*1.1,radius*.55)),color)
			draw_line(center+Vector2(0,-radius*.08),center+Vector2(radius,-radius*.08),color,5.)
			for side in [-1,1]:draw_line(center,center+Vector2(side*.65,.8)*radius,color,3.)
		4:
			draw_arc(center,radius*.8,0,TAU,32,color,2.,true)
			for side in [-1,1]:draw_line(center+Vector2(side*.9,0)*radius,center+Vector2(side*.25,0)*radius,color,3.)
		5:
			draw_rect(Rect2(center-Vector2(radius*.2,radius*.7),Vector2(radius*.4,radius*1.4)),color)
			draw_rect(Rect2(center-Vector2(radius*.7,radius*.2),Vector2(radius*1.4,radius*.4)),color)
func _draw():
	if not is_instance_valid(game) or not game.players.has(game.local_id):return
	var p=game.players[game.local_id];var font=get_theme_default_font()
	var center=Vector2(914,608);var remaining=maxf(0.,float(p.skill_ready)-game.clock);var duration=[18.,30.,30.,30.,25.,20.][int(p.role)];var enabled=game.options.skills and game.options.classes
	draw_circle(center,38.,Color(.08,.11,.15,.78));draw_arc(center,36.,0,TAU,64,Color("6c7a87"),2.,true)
	var ready=remaining<=0. and enabled;var color=GOLD if ready else Color("8697a4")
	draw_arc(center,36.,-PI/2,-PI/2+TAU*(1.-clampf(remaining/duration,0.,1.)),64,color,4.,true)
	icon(int(p.role),center,21.,color)
	if remaining>0.:
		draw_circle(center,25.,Color(.04,.07,.10,.80));draw_string(font,center+Vector2(-25,8),str(ceili(remaining)),HORIZONTAL_ALIGNMENT_CENTER,50,24,WHITE)
	keycap("F",Vector2(901,654));draw_string(font,Vector2(855,694),Rules.SKILLS[p.role] if enabled else "스킬 OFF",HORIZONTAL_ALIGNMENT_CENTER,120,13,WHITE)
	for i in range(4):keycap(str(i+1),Vector2(314+i*132,635))
	var x=309.
	for hint in [["B","장비"],["E","상호작용"],["TAB","기록"],["ESC","메뉴"]]:
		var width=38. if hint[0].length()>1 else 25.;keycap(hint[0],Vector2(x,689),width);draw_string(font,Vector2(x+width+6,707),hint[1],HORIZONTAL_ALIGNMENT_LEFT,-1,13,WHITE);x+=width+(74. if hint[1].length()>3 else 47.)
	if p.get("slide_ready",0)>game.clock:draw_string(font,Vector2(45,584),"슬라이딩 %.1f"%(p.slide_ready-game.clock),HORIZONTAL_ALIGNMENT_LEFT,-1,14,WHITE)
	var details=[]
	if p.primary=="m2":details.append("Q  회복탄 %d"%p.heal_mag)
	if p.get("mounted",0)>game.clock:details.append("거치 %.0f초"%(p.mounted-game.clock))
	if p.shield>game.clock:details.append("방호 활성")
	if game.options.mode==4:details.append("%d 크레딧"%p.cash)
	if not p.get("pending_loadout",{}).is_empty():details.append("다음 부활 장비 예약")
	if not p.alive:details=["마우스 · 관전 시점", "클릭 · 대상 전환", "B · 다음 장비"]
	draw_string(font,Vector2(309,609),"   ·   ".join(details),HORIZONTAL_ALIGNMENT_LEFT,550,14,WHITE)
