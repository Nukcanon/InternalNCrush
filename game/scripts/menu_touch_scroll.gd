extends ScrollContainer
# Handle real touch drags even when the browser does not report touchscreen hardware.
var finger=-1
var start=Vector2.ZERO
var origin=0
var dragging=false
func _input(event):
	if not is_visible_in_tree():finger=-1;dragging=false;return
	if event is InputEventScreenTouch:
		var point=get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed and finger<0 and Rect2(Vector2.ZERO,size).has_point(point):
			finger=event.index;start=point;origin=scroll_vertical;dragging=false
		elif not event.pressed and event.index==finger:
			finger=-1
			if dragging:
				dragging=false;scroll_ended.emit();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==finger:
		var point=get_global_transform_with_canvas().affine_inverse()*event.position
		var delta=point-start
		if not dragging and absf(delta.y)>12. and absf(delta.y)>absf(delta.x)*1.2:
			dragging=true;scroll_started.emit()
		if dragging:
			scroll_vertical=origin-roundi(delta.y);get_viewport().set_input_as_handled()
