class_name Ballistics
extends RefCounted
## Arcade gravity, evaluated as a short ray chain at shot time. No projectile
## bodies, network tick delay, wind or drag. Identical on Windows and Web hosts.
const GRAVITY=4.0
const SPEED=300.0
const SEGMENT_METRES=25.0
const MAX_SEGMENTS=12
static func drop(distance:float) -> float:
	var time=maxf(0.,distance)/SPEED
	return .5*GRAVITY*time*time
static func point(origin:Vector3,direction:Vector3,distance:float) -> Vector3:
	return origin+direction.normalized()*distance-Vector3.UP*drop(distance)
static func between(start:Vector3,end:Vector3,progress:float) -> Vector3:
	# Reconstruct the gentle arc from the authoritative impact endpoints for FX.
	var t=clampf(progress,0.,1.)
	return start.lerp(end,t)+Vector3.UP*drop(start.distance_to(end))*t*(1.-t)
static func trace(game:Node,origin:Vector3,direction:Vector3,reach:float,exclude:Array=[]) -> Dictionary:
	var distance=clampf(reach,0.,300.)
	var count=clampi(ceili(distance/SEGMENT_METRES),1,MAX_SEGMENTS)
	var start=origin;var passed={}
	for i in range(1,count+1):
		var end=point(origin,direction,distance*float(i)/count)
		var hit=game.ray(start,end,exclude)
		passed.merge(Construction.crossed(game,start,hit.get("position",end)))
		if not hit.is_empty():return {"hit":hit,"end":hit.position,"passed":passed}
		start=end
	return {"hit":{},"end":start,"passed":passed}
