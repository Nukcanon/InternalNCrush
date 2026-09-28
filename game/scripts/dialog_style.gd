class_name DialogStyle
extends RefCounted
static func apply(dialog:AcceptDialog,theme:Theme,navigation=false):
	dialog.theme=theme
	var positive=dialog.get_ok_button();var row=positive.get_parent();var buttons=[]
	for child in row.get_children():
		if child is Button:buttons.append(child)
		elif child is Control:child.hide()
	# Ignore platform-specific OK/Cancel ordering; every confirmation is LTR.
	row.layout_direction=Control.LAYOUT_DIRECTION_LTR
	row.move_child(positive,row.get_child_count()-1)
	row.alignment=BoxContainer.ALIGNMENT_END
	var available=maxf(240.,dialog.get_tree().root.size.x-64.)
	var width=minf(240.,(available-16.*buttons.size())/maxi(1,buttons.size()))
	for button in buttons:
		button.custom_minimum_size=Vector2(width,48)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.clip_text=true
		button.resized.connect(func():fit_text(button))
		fit_text.call_deferred(button)
		var affirmative=(button!=positive) if navigation else (button==positive)
		for state in ["normal","hover","pressed","focus"]:
			var style=StyleBoxFlat.new();style.set_corner_radius_all(5);style.set_border_width_all(1)
			style.bg_color=Color("285a43") if affirmative else Color("593b4b")
			if state in ["hover","pressed"]:style.bg_color=Color("367a58") if affirmative else Color("805263")
			style.border_color=Color("76c89a") if affirmative else Color("c28c9a")
			style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color.WHITE)

static func fit_text(button:Button):
	if not is_instance_valid(button):return
	var style=button.get_theme_stylebox("normal")
	var available=maxf(1.,button.size.x-style.get_minimum_size().x-8.)
	var font=button.get_theme_font("font");var font_size=20
	while font_size>1 and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>available:
		font_size-=1
	if button.get_theme_font_size("font_size")!=font_size:button.add_theme_font_size_override("font_size",font_size)
