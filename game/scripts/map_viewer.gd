extends PanelContainer
class_name MapViewer
signal closed
var view:MapPlanView
var choices=[]
var active_index=0
var layer_buttons=[]
var header:HBoxContainer
var controls:HBoxContainer
var column:VBoxContainer
var select:OptionButton
func build(indices:Array):
	choices=indices;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left=20;offset_top=18;offset_right=-20;offset_bottom=-18;z_index=120
	column=VBoxContainer.new();add_child(column)
	header=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	select=OptionButton.new();select.custom_minimum_size.x=210;header.add_child(select)
	controls=HBoxContainer.new();controls.add_theme_constant_override("separation",8);header.add_child(controls)
	for index in indices:select.add_item(Rules.MAPS[index],index)
	for i in range(3):
		var b=Button.new();b.text=["지상","상층","지하"][i];b.custom_minimum_size=Vector2(64,42);controls.add_child(b)
		layer_buttons.append(b)
		b.pressed.connect(func():view.level=i;view.queue_redraw())
	var reset=Button.new();reset.text="크기 초기화";reset.custom_minimum_size.y=42;controls.add_child(reset);reset.pressed.connect(func():view.reset_view())
	var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(spacer)
	var close=Button.new();close.text="닫기";close.custom_minimum_size=Vector2(88,42);header.add_child(close);close.pressed.connect(dismiss)
	UiSkin.paint(close,"stop")
	view=MapPlanView.new();view.interactive=true;view.size_flags_vertical=Control.SIZE_EXPAND_FILL;view.custom_minimum_size.y=120;column.add_child(view);select_map(indices[0])
	select.item_selected.connect(func(i):active_index=i;select_map(choices[i]))
	if indices.size()>1:
		var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=115;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
		var cards=HBoxContainer.new();scroll.add_child(cards)
		for i in range(indices.size()):
			var card=VBoxContainer.new();cards.add_child(card);var thumb=MapPlanView.new();thumb.custom_minimum_size=Vector2(140,80);card.add_child(thumb);thumb.select_map(indices[i])
			var title=Label.new();title.text=Rules.MAPS[indices[i]];title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(title)
			thumb.activated.connect(func():active_index=i;select.select(i);select_map(choices[i]))
	var hint=Label.new();hint.text="휠 / 두 손가락: 확대 · 드래그: 이동 · ESC: 닫기  |  파랑·주황: 시작 위치  ·  A/B/C: 목표 구역";hint.add_theme_font_size_override("font_size",15);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(hint)
	resized.connect(adapt_header);call_deferred("adapt_header")
func adapt_header():
	if not is_instance_valid(controls):return
	var narrow=get_viewport_rect().size.x<760
	select.custom_minimum_size.x=160 if narrow else 210
	if narrow and controls.get_parent()==header:
		controls.reparent(column);column.move_child(controls,1)
	elif not narrow and controls.get_parent()==column:
		controls.reparent(header);header.move_child(controls,1)
func select_map(index:int):
	view.select_map(index)
	for i in range(layer_buttons.size()):layer_buttons[i].disabled=view.plan.get("triangles",{}).get(["ground","upper","lower"][i],[]).is_empty()
	if layer_buttons[view.level].disabled:view.level=0;view.queue_redraw()
func dismiss():closed.emit();queue_free()
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:dismiss();get_viewport().set_input_as_handled()
