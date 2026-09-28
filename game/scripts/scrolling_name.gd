extends Control
## Long names scroll inside a fixed layout slot; text never expands the menu.
var display_text=""
var font_size=20
var caption:Label
var elapsed=0.
func _ready():
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE;tooltip_text=display_text
	caption=Label.new();caption.text=display_text;caption.autowrap_mode=TextServer.AUTOWRAP_OFF;caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.add_theme_font_size_override("font_size",font_size);add_child(caption)
func _process(dt:float):
	if not is_visible_in_tree():return
	var width=caption.get_minimum_size().x
	caption.size=Vector2(maxf(width,size.x),size.y)
	var overflow=maxf(0.,width-size.x)
	if overflow<=0.:caption.position.x=0.;elapsed=0.;return
	var travel=overflow/32.;var pause=1.2;var cycle=2.*(travel+pause)
	elapsed=fmod(elapsed+dt,cycle)
	var offset=0.
	if elapsed<pause:offset=0.
	elif elapsed<pause+travel:offset=(elapsed-pause)*32.
	elif elapsed<2.*pause+travel:offset=overflow
	else:offset=overflow-(elapsed-2.*pause-travel)*32.
	caption.position.x=-clampf(offset,0.,overflow)
