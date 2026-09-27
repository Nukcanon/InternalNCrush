class_name ControlCaptureHud
extends Control
var game:Node
var elapsed=0.
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt:float):
	elapsed+=dt
	if elapsed<.1:return
	elapsed=0.;visible=int(game.options.mode)==3 and game.phase=="combat"
	if visible:queue_redraw()
func _draw():
	var font=get_theme_default_font()
	for order in range(3):
		var index=[0,2,1][order];var state=ControlCapture.state(game,index)
		var origin=Vector2(481+order*108,83)
		var base=color_for(state.owner);var fill=color_for(state.team)
		draw_style_box(plate(),Rect2(origin,Vector2(102,38)))
		draw_string(font,origin+Vector2(8,24),ControlCapture.LABELS[index],HORIZONTAL_ALIGNMENT_LEFT,-1,23,base)
		draw_rect(Rect2(origin+Vector2(34,14),Vector2(60,10)),base.darkened(.6))
		draw_rect(Rect2(origin+Vector2(34,14),Vector2(60*state.progress,10)),fill)
		if state.contested:draw_string(font,origin+Vector2(40,34),"경합",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	if not game.players.has(game.local_id) or not game.actors.has(game.local_id) or not game.players[game.local_id].alive:return
	for index in range(3):
		if not ControlCapture.in_zone(game.actors[game.local_id].position,game.arena.zones[index]):continue
		var state=ControlCapture.state(game,index);var caption="거점 확보"
		if state.contested:caption="경합 중 · 적을 몰아내세요"
		elif state.owner!=state.team:caption="점령 중  %d%% · %d명 · %.1f배"%[roundi(state.progress*100),state.count,ControlCapture.speed(state.count)]
		var text=ControlCapture.LABELS[index]+"  ·  "+caption
		draw_style_box(plate(),Rect2(435,130,410,42))
		draw_string(font,Vector2(640-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x*.5,158),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color_for(state.team))
		break
static func color_for(team:int) -> Color:return Color("69bdff") if team==0 else Color("ffad68") if team==1 else Color("f5dfa1")
static var background:StyleBoxFlat
static func plate() -> StyleBoxFlat:
	if background==null:
		background=StyleBoxFlat.new();background.bg_color=Color(.025,.045,.065,.65);background.set_corner_radius_all(5)
	return background
