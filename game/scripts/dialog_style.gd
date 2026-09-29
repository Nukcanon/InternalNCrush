class_name DialogStyle
extends RefCounted
static func apply(dialog:AcceptDialog,theme:Theme,navigation=false):
	dialog.theme=theme
	# Menus are laid out at 1280x720 and scaled; dialogs follow the same scale.
	var factor=clampf(dialog.get_tree().root.size.y/720.,1.,3.) if dialog.is_inside_tree() else 1.
	if factor>1.01:
		dialog.content_scale_factor=factor
		# The title bar is drawn by the parent window: scale it explicitly.
		dialog.add_theme_font_size_override("title_font_size",roundi(20*factor));dialog.add_theme_constant_override("title_height",roundi(36*factor))
		var border=theme.get_stylebox("embedded_border","Window")
		if border is StyleBoxFlat:
			border=border.duplicate();border.expand_margin_top=36*factor;dialog.add_theme_stylebox_override("embedded_border",border);dialog.add_theme_stylebox_override("embedded_unfocused_border",border)
	# Fit the window to its message and buttons (callers pass generous sizes).
	dialog.about_to_popup.connect(func():
		(func():
			if not is_instance_valid(dialog):return
			var content=Vector2(dialog.get_contents_minimum_size())
			var count=dialog.get_ok_button().get_parent().get_children().filter(func(c):return c is Button and c.visible).size()
			var fitted=Vector2(maxf(maxf(content.x+24.,420.),250.*count+40.),content.y+12.)
			dialog.size=Vector2i(fitted*factor)
			dialog.position=(dialog.get_tree().root.size-dialog.size)/2).call_deferred())
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
		# 1.4 cartoon skin: green = go ahead / stay, coral = cancel / leave.
		UiSkin.paint(button,"go" if affirmative else "stop")

static func finish_keyboard(dialog,accepted:bool):
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion():return
	if not dialog.visible:return
	dialog.hide()
	if accepted:dialog.confirmed.emit()
	else:dialog.canceled.emit()
	if is_instance_valid(dialog) and not dialog.is_queued_for_deletion():dialog.set_meta("keyboard_close_pending",false)

