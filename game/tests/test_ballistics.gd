extends SceneTree
var checks=0
var failures=0
class TraceWorld extends Node:
	var devices={}
	var calls=0
	var barrier=INF
	func ray(start:Vector3,end:Vector3,_exclude:Array=[]) -> Dictionary:
		calls+=1
		if start.z>-barrier and end.z<=-barrier:
			var t=(-barrier-start.z)/(end.z-start.z)
			return {"position":start.lerp(end,t),"normal":Vector3.BACK}
		return {}
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	expect(Ballistics.drop(0.)==0. and Ballistics.drop(-10.)==0.,"no negative or point blank gravity error")
	expect(Ballistics.drop(25.)<.015 and Ballistics.drop(50.)<.06,"near combat remains easy to aim")
	expect(is_equal_approx(Ballistics.drop(100.),2./9.) and Ballistics.drop(200.)<.9,"distant shots have modest arcade drop")
	var world=TraceWorld.new();root.add_child(world)
	var origin=Vector3(0,3,0)
	var flight=Ballistics.trace(world,origin,Vector3.FORWARD,300.)
	expect(flight.hit.is_empty() and flight.end.is_equal_approx(Vector3(0,1,-300)),"full range shot ends two metres below the aiming line")
	expect(world.calls<=12,"ballistics has a fixed per-shot ray budget")
	world.calls=0;world.barrier=50.
	flight=Ballistics.trace(world,origin,Vector3.FORWARD,300.)
	expect(not flight.hit.is_empty() and flight.end.z==-50. and world.calls==2,"first obstruction stops the trajectory and subsequent work")
	expect(is_equal_approx(flight.end.y,3.-Ballistics.drop(50.)),"collision uses the gravity path rather than the reticle ray")
	var end=Ballistics.point(origin,Vector3.FORWARD,200.)
	expect(Ballistics.between(origin,end,0.)==origin and Ballistics.between(origin,end,1.)==end,"replay arc preserves the authoritative shot endpoints")
	expect(Ballistics.between(origin,end,.5).distance_to(Ballistics.point(origin,Vector3.FORWARD,100.))<.001,"replay arc matches the flight curve")
	world.free();print("BALLISTICS_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
