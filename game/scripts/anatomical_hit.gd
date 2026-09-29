class_name AnatomicalHit
extends RefCounted

# Combat volumes follow the hero skeleton (HeroHitbox, measured from each
# outfit's mesh). Movement clearance is the capsule and stays independent.
static func trace(actor:Actor,from:Vector3,to:Vector3) -> Dictionary:
	var center=actor.global_position+Vector3.UP*actor.body_height*.5
	var nearest=Geometry3D.get_closest_point_to_segment(center,from,to)
	if nearest.distance_squared_to(center)>1.7:return {}
	actor.ensure_hit_pose()
	var hit=HeroHitbox.trace(actor.character,from,to)
	if hit.is_empty():return {}
	var delta=to-from
	return {"position":from+delta*float(hit.t),"normal":-delta.normalized(),"collider":actor,"zone":hit.zone,"rid":actor.get_rid()}
