class_name DialogStyle
extends RefCounted
static func apply(dialog:AcceptDialog,theme:Theme,navigation=false):
	dialog.theme=theme
	dialog.window_input.connect(func(event):
		if not event is InputEventKey or not event.pressed or event.echo:return
		if event.keycode not in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:return
		dialog.set_input_as_handled()
		if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
			if not dialog.get_ok_button().disabled:dialog.hide();dialog.confirmed.emit()
		else:dialog.hide();dialog.canceled.emit())
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
		var affirmative=(button!=positive) if navigation else (button==positive)
		for state in ["normal","hover","pressed","focus"]:
			var style=StyleBoxFlat.new();style.set_corner_radius_all(5);style.set_border_width_all(1)
			style.bg_color=Color("285a43") if affirmative else Color("593b4b")
			if state in ["hover","pressed"]:style.bg_color=Color("367a58") if affirmative else Color("805263")
			style.border_color=Color("76c89a") if affirmative else Color("c28c9a")
			style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color.WHITE)

