extends Control
class_name DamageIndicator
var game:Node
var hits:Array=[]
const LIFETIME=1.15
const MAX_HITS=8
func _ready():z_index=20;mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func clear_hits():hits.clear();queue_redraw()
func register_hit(direction:Vector3,amount:float,now:float):
	var flat=Vector3(direction.x,0,direction.z).normalized()
	for hit in hits:
		if Vector3(hit.direction).dot(flat)>.94:
			hit.until=now+LIFETIME;hit.weight=clampf(float(hit.weight)+amount/100.,.25,1.);queue_redraw();return
	hits.append({"direction":flat,"until":now+LIFETIME,"weight":clampf(amount/45.,.25,1.)})
	while hits.size()>MAX_HITS:hits.pop_front()
	queue_redraw()
static func screen_direction(direction:Vector3,yaw:float) -> Vector2:
	var local=Basis(Vector3.UP,-yaw)*direction
	return Vector2(local.x,local.z).normalized()
func _process(_dt:float):
	var now=Time.get_ticks_msec()/1000.
	hits=hits.filter(func(hit):return float(hit.until)>now)
	queue_redraw()
func _draw():
	if not is_instance_valid(game) or not game.players.has(game.local_id) or not game.players[game.local_id].alive:return
	var actor=game.actors[game.local_id];var center=size*.5;var radius=minf(size.x,size.y)*.30;var now=Time.get_ticks_msec()/1000.
	for hit in hits:
		var fade=clampf((float(hit.until)-now)/.30,0,1);var direction=screen_direction(hit.direction,actor.aim_yaw)
		if direction.length()<.01:
			draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color(1,.12,.09,.28*fade),false,7.);continue
		var angle=direction.angle();var width=.24+float(hit.weight)*.12
		draw_arc(center,radius,angle-width,angle+width,18,Color(.12,.015,.015,.75*fade),14.,true)
		draw_arc(center,radius,angle-width,angle+width,18,Color(1,.08,.055,.90*fade),8.,true)
		var tip=center+direction*(radius+16);var tangent=Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([tip,tip-direction*10+tangent*6,tip-direction*10-tangent*6]),Color(1,.18,.12,fade))
