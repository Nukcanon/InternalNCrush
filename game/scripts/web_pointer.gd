extends Node
class_name WebPointer
## Pointer lock is owned by the browser. A requested lock is not a granted lock.
var game:Node
var document
var window
var callback
func _ready():
	if not OS.has_feature("web"):return
	document=JavaScriptBridge.get_interface("document")
	window=JavaScriptBridge.get_interface("window")
	callback=JavaScriptBridge.create_callback(_browser_changed)
	document.addEventListener("pointerlockchange",callback)
	document.addEventListener("pointerlockerror",callback)
	window.addEventListener("blur",callback)
	_browser_changed([])
func _browser_changed(_args):
	var locked=bool(JavaScriptBridge.eval("document.hasFocus() && document.pointerLockElement === document.getElementById('canvas')"))
	game.web_pointer_active=locked
	if not locked:
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if game.actors.has(game.local_id):
			game.actors[game.local_id].input_state.fire=false
			game.actors[game.local_id].input_state.ads=false
func _exit_tree():
	if document!=null and callback!=null:
		document.removeEventListener("pointerlockchange",callback)
		document.removeEventListener("pointerlockerror",callback)
		window.removeEventListener("blur",callback)
	callback=null;document=null;window=null
