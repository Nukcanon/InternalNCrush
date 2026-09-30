class_name AmmoPips
extends Control
## Bottom-right ammo box (1.4.2): loaded rounds drawn as cartridges (shells for
## shotguns), spent ones as empty case outlines, and the reserve as grey
## magazines on one line that always fits the box, each emptying in proportion
## as the reserve is used.
## The rounds stay up while reloading: a magazine reload shows them leave with
## the magazine (a chambered round stays) and come back full when the new one
## seats (ReloadMotion.DETACH / SEAT); round-by-round loads count up. A +1
## chambered round keeps its slot once fired (shown spent).
var game:Node
var last_state:Array=[]
var peak={} # weapon id -> most rounds shown since its last reload began
var peak_reload={} # weapon id -> reload_started that reset its peak
const WIDTH=228.
const ROUNDS_H=44.
const RESERVE_Y=50.
const MAX_MAGS=14
const CASE=Color("e0b25c")
const TIP=Color("b87a45")
const SHELL=Color("cf4a3c")
const SPENT=Color(.62,.70,.76,.42)
const MAG_FULL=Color("a9b5bd")
const MAG_EMPTY=Color(.08,.10,.12,.55)
func _ready():
	custom_minimum_size=Vector2(WIDTH,66);mouse_filter=Control.MOUSE_FILTER_IGNORE
static func magazine_fed(w:Dictionary) -> bool:
	return w.kind=="gun" and not w.get("single_load",false) and not w.get("rocket",false) and str(w.get("reload_style","")) in ["rifle","box","pistol","battery"]
## Rounds shown now: the magazine's own count, or the reload's phase.
func shown(p:Dictionary,w:Dictionary,id:String) -> int:
	var rounds=int(p.mag.get(id,0))
	if p.reload<=game.clock or str(p.get("reload_weapon",""))!=id or not magazine_fed(w):return rounds
	var t=MagazineReload.progress(game,p,w)
	if t<ReloadMotion.DETACH:return rounds
	if t<ReloadMotion.SEAT:return 1 if bool(p.get("reload_tactical",false)) else 0
	return rounds+int(p.get("reload_count",0))
func refresh_state() -> bool:
	var next:Array=[]
	if is_instance_valid(game) and game.players.has(game.local_id):
		var p=game.players[game.local_id];var id=p.primary if p.slot==0 else p.secondary;var w=Catalog.get_weapon(id)
		var phase=-1
		if p.reload>game.clock:
			var t=MagazineReload.progress(game,p,w);phase=0 if t<ReloadMotion.DETACH else 1 if t<ReloadMotion.SEAT else 2
		next=[p.slot,id,int(p.mag.get(id,0)),int(p.reserve.get(id,0)),bool(game.options.infinite),int(p.get("energy",0)),int(p.get("repair_energy",0)),phase,p.get("cooking",0)>0,MeleeCombat.shown(p,game.clock)]
	if next==last_state:return false
	last_state=next;return true
func _process(_dt):
	if is_visible_in_tree() and refresh_state():queue_redraw()
func _draw():
	if not game or not game.players.has(game.local_id):return
	var p=game.players[game.local_id]
	if MeleeCombat.shown(p,game.clock) or p.slot>=2 or p.get("cooking",0)>0:return
	var id=p.primary if p.slot==0 else p.secondary;var w=Catalog.get_weapon(id)
	if w.get("laser",false):
		draw_rect(Rect2(14,16,200,14),Color(0,0,0,.5));draw_rect(Rect2(14,16,200*clampf(float(p.mag.get(id,0))/float(w.mag),0.,1.),14),Color("efd64f"));return
	if w.kind in ["heal","repair"]:
		var energy=float(p.energy)/180. if w.kind=="heal" else float(p.get("repair_energy",100))/100.
		draw_rect(Rect2(14,16,200,12),Color(0,0,0,.35));draw_rect(Rect2(14,16,200*clampf(energy,0.,1.),12),Color("64ddbd"));return
	var remaining=shown(p,w,id)
	# A new reload resets the remembered +1 slot.
	if float(p.get("reload_started",0))!=float(peak_reload.get(id,-1.)) and p.reload>game.clock:
		peak_reload[id]=float(p.get("reload_started",0));peak[id]=0
	peak[id]=maxi(int(peak.get(id,0)),remaining)
	var capacity=maxi(int(w.mag),int(peak[id]))
	var shells=str(w.get("reload_style","")) in ["shell","break"]
	var columns=mini(capacity,20);var rows=ceili(float(capacity)/columns)
	var step_x=minf(18.,(WIDTH-8.)/columns);var step_y=minf(22.,ROUNDS_H/rows)
	for i in range(capacity):
		var row=i/columns;var row_count=mini(columns,capacity-row*columns)
		var x=(WIDTH-row_count*step_x)*.5+(i%columns)*step_x+step_x*.2
		var y=(ROUNDS_H-rows*step_y)*.5+row*step_y
		cartridge(Rect2(x,y+step_y*.08,step_x*.6,step_y*.84),i<remaining,shells)
	var font=get_theme_default_font()
	if game.options.infinite:draw_string(font,Vector2(0,RESERVE_Y+14),"∞",HORIZONTAL_ALIGNMENT_CENTER,WIDTH,17,Color("c1d3d9"));return
	# Reserve: magazines of the gun's capacity, at most MAX_MAGS on one line; a
	# larger reserve spreads over them, each icon emptying in proportion.
	var reserve=maxi(0,int(p.reserve.get(id,0)));var full=maxi(int(w.get("reserve",reserve)),reserve)
	var icons=clampi(ceili(float(full)/maxf(1.,float(w.mag))),1,MAX_MAGS)
	var per=float(full)/icons;var gap=4.;var mag_w=minf(10.,(WIDTH-gap*(icons-1))/icons)
	var start=(WIDTH-(icons*mag_w+(icons-1)*gap))*.5
	for i in range(icons):
		var fill=clampf((float(reserve)-i*per)/per,0.,1.)
		magazine_icon(Rect2(start+i*(mag_w+gap),RESERVE_Y,mag_w,14),fill)
# A cartridge: case with a rim and a pointed bullet (or a shotgun shell with a
# brass head); spent: the empty case outline only.
func cartridge(r:Rect2,loaded:bool,shell:bool):
	var x=r.position.x;var y=r.position.y;var w=r.size.x;var h=r.size.y
	if not loaded:
		var outline=PackedVector2Array([Vector2(x,y+h),Vector2(x,y+h*.36),Vector2(x+w,y+h*.36),Vector2(x+w,y+h),Vector2(x,y+h)])
		draw_polyline(outline,SPENT,1.,true);return
	if shell:
		draw_rect(Rect2(x,y,w,h*.74),SHELL);draw_rect(Rect2(x,y+h*.74,w,h*.26),CASE)
		draw_rect(Rect2(x-w*.08,y+h*.92,w*1.16,h*.08),CASE.darkened(.25));return
	var neck=y+h*.38
	var tip=PackedVector2Array([Vector2(x+w*.12,neck),Vector2(x+w*.18,y+h*.14),Vector2(x+w*.5,y),Vector2(x+w*.82,y+h*.14),Vector2(x+w*.88,neck)])
	draw_colored_polygon(tip,TIP)
	draw_rect(Rect2(x,neck,w,h*.58),CASE)
	draw_rect(Rect2(x-w*.06,y+h*.94,w*1.12,h*.06),CASE.darkened(.3))
	draw_line(Vector2(x+w*.25,neck+h*.08),Vector2(x+w*.25,y+h*.88),CASE.lightened(.35),maxf(1.,w*.14))
# A grey box magazine (slightly curved front), filled from the bottom.
func magazine_icon(r:Rect2,fill:float):
	var x=r.position.x;var y=r.position.y;var w=r.size.x;var h=r.size.y
	var body=PackedVector2Array([Vector2(x,y),Vector2(x+w,y),Vector2(x+w*1.12,y+h),Vector2(x+w*.12,y+h)])
	draw_colored_polygon(body,MAG_EMPTY)
	if fill>0.:
		var top=y+h*(1.-fill)
		var part=PackedVector2Array([Vector2(x+w*.12*(top-y)/h,top),Vector2(x+w+w*.12*(top-y)/h,top),Vector2(x+w*1.12,y+h),Vector2(x+w*.12,y+h)])
		draw_colored_polygon(part,MAG_FULL)
	var edge=body.duplicate();edge.append(body[0]);draw_polyline(edge,MAG_FULL.darkened(.35),1.,true)
	draw_rect(Rect2(x+w*.2,y-1.5,w*.6,1.5),MAG_FULL.darkened(.2))
