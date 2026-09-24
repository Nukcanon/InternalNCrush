class_name AnatomicalHit
extends RefCounted

# Combat volumes sit inside the visible body. Movement clearance is independent.
const LIMBS=[
	["Hips/Chest/LeftArm",.28,.050,"torso"], ["Hips/Chest/RightArm",.28,.050,"torso"],
	["Hips/Chest/LeftArm/Elbow",.275,.038,"torso"], ["Hips/Chest/RightArm/Elbow",.275,.038,"torso"],
	["Hips/LeftLeg",.415,.074,"legs"], ["Hips/RightLeg",.415,.074,"legs"],
	["Hips/LeftLeg/Knee",.415,.053,"legs"], ["Hips/RightLeg/Knee",.415,.053,"legs"]]

static func sphere(from:Vector3,delta:Vector3,center:Vector3,radius:float) -> float:
	var o=from-center;var a=delta.length_squared();var b=o.dot(delta);var c=o.length_squared()-radius*radius
	if c<=0.:return 0.
	var disc=b*b-a*c
	if disc<0. or a<.0000001:return INF
	var t=(-b-sqrt(disc))/a
	return t if t>=0. and t<=1. else INF

static func capsule(from:Vector3,delta:Vector3,length:float,radius:float) -> float:
	var a=Vector3(0,-radius,0);var b=Vector3(0,-length+radius,0)
	var best=minf(sphere(from,delta,a,radius),sphere(from,delta,b,radius))
	var aa=delta.x*delta.x+delta.z*delta.z
	var bb=from.x*delta.x+from.z*delta.z;var cc=from.x*from.x+from.z*from.z-radius*radius
	var disc=bb*bb-aa*cc
	if aa>.0000001 and disc>=0.:
		var t=(-bb-sqrt(disc))/aa;var y=from.y+delta.y*t
		if t>=0. and t<=1. and y<=a.y and y>=b.y:best=minf(best,t)
	return best

static func trace(actor:Actor,from:Vector3,to:Vector3) -> Dictionary:
	var center=actor.global_position+Vector3.UP*actor.body_height*.5
	var nearest=Geometry3D.get_closest_point_to_segment(center,from,to)
	if nearest.distance_squared_to(center)>1.7:return {}
	actor.ensure_hit_pose()
	var rig=actor.character.rig;var best=INF;var zone="torso";var delta=to-from
	for part in LIMBS:
		var transform:Transform3D=rig.get_node(part[0]).global_transform.affine_inverse()
		var start=transform*from;var end=transform*to
		var t=capsule(start,end-start,part[1],part[2])
		if t<best:best=t;zone=part[3]
	for part in [["Hips",Vector3(0,-.02,0),Vector3(.143,.15,.115),"torso"],["Hips/Chest",Vector3(0,.012,0),Vector3(.162,.222,.115),"torso"],["Hips/Chest",Vector3(0,.25,0),Vector3(.043,.07,.042),"torso"],["Hips/Chest/Head",Vector3(0,.014,-.016),Vector3(.082,.126,.089),"head"]]:
		var transform:Transform3D=rig.get_node(part[0]).global_transform.affine_inverse()
		var start=(transform*from-part[1])/part[2];var end=(transform*to-part[1])/part[2]
		var t=sphere(start,end-start,Vector3.ZERO,1.)
		if t<best:best=t;zone=part[3]
	if best==INF:return {}
	return {"position":from+delta*best,"normal":-delta.normalized(),"collider":actor,"zone":zone,"rid":actor.get_rid()}
