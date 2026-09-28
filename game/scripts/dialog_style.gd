class_name DialogStyle
extends RefCounted
static func apply(dialog:AcceptDialog,theme:Theme,navigation=false):
	dialog.theme=theme
	# One keyboard handler owns cancellation. AcceptDialog's native Escape
	# handler runs before window_input, so enabling both closes the dialog twice.
	dialog.dialog_close_on_escape=false
	dialog.window_input.connect(func(event):
		if not event is InputEventKey or not event.pressed or event.echo:return
		if event.alt_pressed or event.ctrl_pressed or event.meta_pressed:return
		if event.keycode not in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:return
		dialog.set_input_as_handled()
		if dialog.get_meta("keyboard_close_pending",false):return
		var accepted=event.keycode in [KEY_ENTER,KEY_KP_ENTER]
		if accepted and dialog.get_ok_button().disabled:return
		dialog.set_meta("keyboard_close_pending",true)
		# A native Window must survive its current input dispatch. Hiding it
		# here destroys the OS window while Godot is still routing this key.
		finish_keyboard.bind(dialog,accepted).call_deferred())
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

static func finish_keyboard(dialog,accepted:bool):
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion():return
	if not dialog.visible:return
	dialog.hide()
	if accepted:dialog.confirmed.emit()
	else:dialog.canceled.emit()
	if is_instance_valid(dialog) and not dialog.is_queued_for_deletion():dialog.set_meta("keyboard_close_pending",false)

