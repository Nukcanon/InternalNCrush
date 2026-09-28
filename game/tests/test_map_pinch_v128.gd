extends SceneTree
func _initialize():call_deferred("run")
func finger(view:Control,id:int,position:Vector2,pressed:bool):
	var e=InputEventScreenTouch.new();e.index=id;e.position=position;e.pressed=pressed;view._gui_input(e)
func drag(view:Control,id:int,position:Vector2):
	var e=InputEventScreenDrag.new();e.index=id;e.position=position;e.relative=Vector2(900,-700);view._gui_input(e)
func run():
	var view=MapPlanView.new();root.add_child(view);view.size=Vector2(800,500);view.interactive=true
	finger(view,0,Vector2(250,200),true);finger(view,1,Vector2(450,200),true)
	drag(view,0,Vector2(200,200));drag(view,1,Vector2(500,200))
	assert(is_equal_approx(view.zoom,1.5))
	# The world point below the original midpoint remains below the new midpoint.
	var origin=Vector2(350,200)-view.size*.5
	assert((origin*view.zoom+view.size*.5+view.pan).distance_to(Vector2(350,200))<.01)
	var before=view.pan
	var mouse=InputEventMouseMotion.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.relative=Vector2(800,800)
	view.dragging=true;view._gui_input(mouse);assert(view.pan==before)
	finger(view,1,Vector2(500,200),false);drag(view,0,Vector2(210,205));assert(view.pan==before+Vector2(10,5))
	view.reset_view();assert(view.fingers.is_empty() and view.zoom==1. and view.pan==Vector2.ZERO)
	view.free();print("MAP_PINCH_V128_PASS");quit()
