extends PanelContainer
class_name MapViewer
signal closed
var view:MapPlanView
var choices=[]
var active_index=0
func build(indices:Array):
	choices=indices;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left=20;offset_top=18;offset_right=-20;offset_bottom=-18;z_index=120
	var column=VBoxContainer.new();add_child(column)
	var header=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	var select=OptionButton.new();select.custom_minimum_size.x=210;header.add_child(select)
	for index in indices:select.add_item(Rules.MAPS[index],index)
	for i in range(3):
		var b=Button.new();b.text=["지상","상층","지하"][i];b.custom_minimum_size=Vector2(80,42);header.add_child(b)
		b.pressed.connect(func():view.level=i;view.queue_redraw())
	var close=Button.new();close.text="닫기";close.custom_minimum_size=Vector2(80,42);header.add_child(close);close.pressed.connect(dismiss)
	var reset=Button.new();reset.text="크기 초기화";reset.custom_minimum_size.y=42;header.add_child(reset);reset.pressed.connect(func():view.reset_view())
	view=MapPlanView.new();view.interactive=true;view.size_flags_vertical=Control.SIZE_EXPAND_FILL;view.custom_minimum_size.y=300;column.add_child(view);view.select_map(indices[0])
	select.item_selected.connect(func(i):active_index=i;view.select_map(choices[i]))
	if indices.size()>1:
		var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=115;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
		var cards=HBoxContainer.new();scroll.add_child(cards)
		for i in range(indices.size()):
			var card=VBoxContainer.new();cards.add_child(card);var thumb=MapPlanView.new();thumb.custom_minimum_size=Vector2(140,80);card.add_child(thumb);thumb.select_map(indices[i])
			var title=Label.new();title.text=Rules.MAPS[indices[i]];title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(title)
			thumb.activated.connect(func():active_index=i;select.select(i);view.select_map(choices[i]))
	var hint=Label.new();hint.text="휠 / 두 손가락: 확대 · 드래그: 이동 · ESC: 닫기  |  파랑·주황: 시작 위치  ·  A/B/C: 목표 구역";hint.add_theme_font_size_override("font_size",15);column.add_child(hint)
func dismiss():closed.emit();queue_free()
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:dismiss();get_viewport().set_input_as_handled()
