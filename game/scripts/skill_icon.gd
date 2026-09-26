class_name SkillIcon
extends HudSymbols
var role=0
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE;set_process(false);resized.connect(queue_redraw)
func _draw():
	var scale_factor=maxf(.1,minf(size.x,size.y)/94.)
	draw_set_transform(size*.5,0.,Vector2.ONE*scale_factor)
	badge(role,Vector2.ZERO,0.,1.,true,.8)
