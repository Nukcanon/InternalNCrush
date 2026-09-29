extends Node
# Event-driven fitting for ordinary buttons, options and checkbox labels.
func _ready():
	get_tree().node_added.connect(_watch)
	for button in get_tree().root.find_children("*","Button",true,false):_watch(button)
func _watch(node:Node):
	if node is Button and not node.has_meta("auto_text_fit"):
		node.set_meta("auto_text_fit",true)
		_register.call_deferred(node)
func _register(button):
	if not is_instance_valid(button):return
	# Text-sized controls keep native sizing. Constrained controls must not use
	# text width as their minimum, otherwise shrinking feeds back into layout.
	var constrained=button.clip_text or button.custom_minimum_size.x>0. or (button.size_flags_horizontal & Control.SIZE_EXPAND)!=0
	if not constrained:return
	button.clip_text=true
	if button is OptionButton:button.fit_to_longest_item=false
	button.set_meta("auto_text_base",button.get_theme_font_size("font_size"))
	var refresh=func():
		if is_instance_valid(button):fit.call_deferred(button)
	button.resized.connect(refresh)
	button.theme_changed.connect(refresh)
	button.draw.connect(refresh)
	fit(button)
static func fit(button):
	if not is_instance_valid(button) or button.size.x<=1. or button.text.is_empty() or button.get_meta("no_text_fit",false):return
	var style=button.get_theme_stylebox("normal")
	var available=maxf(1.,button.size.x-style.get_minimum_size().x-8.)
	var separation=button.get_theme_constant("h_separation")
	if button.icon:available-=button.icon.get_width()+separation
	if button is OptionButton and button.has_theme_icon("arrow"):
		available-=button.get_theme_icon("arrow").get_width()+button.get_theme_constant("arrow_margin")+separation
	elif button is CheckBox or button is CheckButton:
		if button.has_theme_icon("checked"):available-=button.get_theme_icon("checked").get_width()+separation
	var font=button.get_theme_font("font")
	var font_size=int(button.get_meta("auto_text_base",button.get_theme_font_size("font_size")))
	while font_size>1 and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>maxf(1.,available):font_size-=1
	if button.get_theme_font_size("font_size")!=font_size:button.add_theme_font_size_override("font_size",font_size)
