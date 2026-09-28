extends SceneTree
class GroundedActor extends RefCounted:
	func is_on_floor():return true
class Recorder extends Node:
	var calls=[]
	var local_id=1
	var clock=10.
	var phase="combat"
	var players={1:{"alive":true,"shield":0.,"slow":0.}}
	var actors={1:GroundedActor.new()}
	func can_attack(_p):return true
	func current_weapon(_p):return {}
	func command(action:String,data:Dictionary):calls.append([action,data])
func _initialize():call_deferred("run")
func run():
	var recorder=Recorder.new();root.add_child(recorder)
	var controls=TouchControls.new();controls.game=recorder;root.add_child(controls);controls.set_process(false)
	controls.movement=Vector2.LEFT;controls.track_swipe()
	controls.movement=Vector2(.10,.10);controls.track_swipe()
	controls.movement=Vector2(-.85,.25);controls.track_swipe()
	assert(recorder.calls.size()==1 and recorder.calls[0][0]=="slide","Tolerant outward-neutral-outward gesture")
	controls.reset_physics_interpolation()
	controls.held={};controls.press("slide",true)
	assert(recorder.calls.size()==2 and recorder.calls[1][1].forward,"Slide button uses camera forward")
	assert(controls.buttons.crouch.size==controls.buttons.jump.size)
	assert(not controls.buttons.jump.intersects(controls.buttons.crouch))
	assert(controls.buttons.slide.position.y>630.)
	for aspect in [Vector2(1,1),Vector2(2.4,1),Vector2(1,1.8)]:
		controls.scale=aspect
		var radius=controls.circle_scale()*aspect
		assert(is_equal_approx(radius.x,radius.y),"Screen-space circles must stay circular")
	controls.free();recorder.free();print("MOBILE_V128_PASS");quit()
