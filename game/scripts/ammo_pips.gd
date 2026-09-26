class_name AmmoPips
extends Control
var game:Node
func _ready():
	custom_minimum_size=Vector2(228,52);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_dt):queue_redraw()
func _draw():
	if not game or not game.players.has(game.local_id):return
	var p=game.players[game.local_id]
	if MeleeCombat.shown(p,game.clock) or p.slot>=2 or p.get("cooking",0)>0 or p.reload>game.clock:return
	var id=p.primary if p.slot==0 else p.secondary;var w=Catalog.get_weapon(id)
	if w.kind in ["heal","repair"]:
		var energy=float(p.energy)/180. if w.kind=="heal" else float(p.get("repair_energy",100))/100.
		draw_rect(Rect2(14,16,200,12),Color(0,0,0,.35));draw_rect(Rect2(14,16,200*clampf(energy,0.,1.),12),Color("64ddbd"));return
	var capacity=int(w.mag);var remaining=int(p.mag.get(id,0));var columns=mini(capacity,20);var rows=ceili(float(capacity)/columns)
	var step_x=minf(18.,220./columns);var step_y=minf(18.,50./rows)
	for i in range(capacity):
		var row=i/columns;var row_count=mini(columns,capacity-row*columns);var x=(228.-row_count*step_x)*.5+(i%columns)*step_x
		var y=(52.-rows*step_y)*.5+row*step_y;var width=step_x*.48;var height=step_y*.77
		var fill=Color("f4d19a") if i<remaining else Color(.015,.025,.035,.42)
		var points=PackedVector2Array([Vector2(x,y+height),Vector2(x,y+height*.24),Vector2(x+width*.5,y),Vector2(x+width,y+height*.24),Vector2(x+width,y+height)])
		draw_colored_polygon(points,fill);points.append(points[0]);draw_polyline(points,Color("efc88c") if i<remaining else Color(.65,.72,.77,.35),.8,true)
	var font=get_theme_default_font()
	if game.options.infinite:draw_string(font,Vector2(0,64),"∞",HORIZONTAL_ALIGNMENT_CENTER,228,17,Color("c1d3d9"))
	else:
		var reserve=maxi(0,int(p.reserve.get(id,0)));var magazines=ceili(float(reserve)/capacity)
		for i in range(magazines):
			var x=(228.-magazines*13)*.5+i*13;var loaded=clampf(float(reserve-i*capacity)/capacity,0.,1.)
			draw_rect(Rect2(x,57,8,10),Color(0,0,0,.35));draw_rect(Rect2(x,67-10*loaded,8,10*loaded),Color("91aab4"))

