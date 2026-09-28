extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	root.gui_embed_subwindows=false
	for accepted in [false,true]:
		for navigation in [false,true]:
			var dialog=ConfirmationDialog.new();root.add_child(dialog)
			var calls=[0,0]
			dialog.canceled.connect(func():calls[0]+=1;dialog.queue_free())
			dialog.confirmed.connect(func():calls[1]+=1;dialog.queue_free())
			DialogStyle.apply(dialog,Theme.new(),navigation)
			dialog.popup_centered(Vector2i(440,160));await process_frame
			check(not dialog.dialog_close_on_escape,"only one Escape handler")
			var key=InputEventKey.new();key.keycode=KEY_ENTER if accepted else KEY_ESCAPE;key.pressed=true
			dialog.window_input.emit(key)
			dialog.window_input.emit(key)
			check(dialog.visible and not dialog.is_queued_for_deletion(),"native window survives input dispatch")
			check(calls==[0,0],"callbacks wait until dispatch completes")
			await process_frame;await process_frame
			check(calls==([0,1] if accepted else [1,0]),"one matching callback only")
			check(not is_instance_valid(dialog),"dialog released after deferred close")
	print("DIALOG_KEYBOARD_LIFETIME ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
