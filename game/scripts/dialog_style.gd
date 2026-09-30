class_name DialogStyle
extends RefCounted
static func apply(dialog:AcceptDialog,theme:Theme,navigation=false):
	dialog.theme=theme
	# Rounded body corners show the window background: keep it transparent.
	dialog.transparent_bg=true
	# Menus are laid out at 1280x720 and scaled; dialogs follow the same scale.
	var factor=scale_factor(dialog)
	# The title bar is drawn by the parent window: size it like the body text
	# (28 px on touch, 20 px on desktop) and scale it explicitly.
	var title_size=theme.default_font_size if theme.has_default_font_size() else 20
	var bar=title_size+20 # title bar tall enough for the larger touch title
	dialog.add_theme_font_size_override("title_font_size",roundi(title_size*factor));dialog.add_theme_constant_override("title_height",roundi(bar*factor))
	if absf(factor-1.)>.01:dialog.content_scale_factor=factor
	# The outline is drawn outside the body; its top margin is the title bar.
	var border=theme.get_stylebox("embedded_border","Window")
	if border is StyleBoxFlat:
		border=border.duplicate();border.expand_margin_top=bar*factor;border.expand_margin_left=8*factor;border.expand_margin_right=8*factor;border.expand_margin_bottom=8*factor;border.set_border_width_all(roundi(4*factor));border.set_corner_radius_all(roundi(16*factor));dialog.add_theme_stylebox_override("embedded_border",border);dialog.add_theme_stylebox_override("embedded_unfocused_border",border)
	# Late text changes still refit (normally a no-op: popup() already fitted).
	dialog.about_to_popup.connect(func():
		(func():
			if is_instance_valid(dialog) and dialog.visible:
				hide_spacers(dialog)
				var size=fitted_size(dialog)
				if size!=dialog.size:dialog.size=size;dialog.position=(dialog.get_tree().root.size-dialog.size)/2).call_deferred())
	var positive=dialog.get_ok_button();var row=positive.get_parent();var buttons=[]
	for child in row.get_children(true):
		if child is Button:buttons.append(child)
	hide_spacers(dialog)
	# Ignore platform-specific OK/Cancel ordering; every confirmation is LTR.
	row.layout_direction=Control.LAYOUT_DIRECTION_LTR
	row.move_child(positive,row.get_child_count()-1)
	# Touch: the pair sits centred under the message; desktop keeps the usual right alignment.
	row.alignment=BoxContainer.ALIGNMENT_CENTER if TouchControls.supported() else BoxContainer.ALIGNMENT_END
	# Buttons are as wide as their caption (at least 120 px); the window fits them.
	# Equal buttons, as wide as the longest caption (also refreshed on popup).
	var caption=120.
	for button in buttons:
		caption=maxf(caption,button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+button.get_theme_stylebox("normal").get_minimum_size().x+18.)
	# AcceptDialog applies these constants to every button on theme changes.
	dialog.add_theme_constant_override("buttons_min_width",roundi(caption));dialog.add_theme_constant_override("buttons_min_height",64 if TouchControls.supported() else 48)
	for button in buttons:
		button.custom_minimum_size=Vector2(caption,64 if TouchControls.supported() else 48)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.clip_text=false
		var affirmative=(button!=positive) if navigation else (button==positive)
		# 1.4 cartoon skin: green = go ahead / stay, coral = cancel / leave.
		UiSkin.paint(button,"go" if affirmative else "stop")

# 1.4.4: AcceptDialog keeps (internal) spacers in its button row, and
# add_button() brings more; all of them are hidden so three buttons sit at
# equal gaps (they used to bunch the left pair and leave a hole before OK).
static func hide_spacers(dialog:AcceptDialog):
	var row=dialog.get_ok_button().get_parent()
	for child in row.get_children(true):
		if child is Control and not child is Button:child.hide()

static func finish_keyboard(dialog,accepted:bool):
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion():return
	if not dialog.visible:return
	dialog.hide()
	if accepted:dialog.confirmed.emit()
	else:dialog.canceled.emit()
	if is_instance_valid(dialog) and not dialog.is_queued_for_deletion():dialog.set_meta("keyboard_close_pending",false)

static func scale_factor(dialog:Window) -> float:
	# Same uniform scale as the menus (smaller axis of the 1280x720 layout).
	if not dialog.is_inside_tree():return 1.
	var size=Vector2(dialog.get_tree().root.size)
	return clampf(minf(size.x/1280.,size.y/720.),.75,3.)
## Window size for the dialog's final message and buttons (equal-width
## buttons as wide as the longest caption), in window pixels.
static func fitted_size(dialog:AcceptDialog) -> Vector2i:
	hide_spacers(dialog)
	var row_buttons=dialog.get_ok_button().get_parent().get_children().filter(func(c):return c is Button and c.visible)
	var widest=120.
	for b in row_buttons:
		var base=int(b.get_meta("auto_text_base",b.get_theme_font_size("font_size")))
		b.set_meta("no_text_fit",true);b.clip_text=false;b.remove_theme_font_size_override("font_size")
		widest=maxf(widest,b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,base).x+b.get_theme_stylebox("normal").get_minimum_size().x+18.)
	dialog.add_theme_constant_override("buttons_min_width",roundi(widest))
	for b in row_buttons:b.custom_minimum_size.x=widest
	var content=Vector2(dialog.get_contents_minimum_size())
	return Vector2i(Vector2(maxf(content.x+24.,300.),content.y+12.)*scale_factor(dialog))
## Opens the dialog centred at its fitted size (no first-frame resize).
static func popup(dialog:AcceptDialog):
	dialog.popup_centered(fitted_size(dialog))
