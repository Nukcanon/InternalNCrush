class_name AllyHealthLabels
extends RefCounted
const NEAR_SIZE=.0015
const FAR_SIZE=.0009
static func pixel_size(distance:float) -> float:
	return lerpf(NEAR_SIZE,FAR_SIZE,clampf((distance-5.)/35.,0.,1.))
static func layout(actor:Node):
	var viewer=actor.game.actors.get(actor.game.local_id)
	if not is_instance_valid(viewer):return
	var distance=viewer.camera.global_position.distance_to(actor.global_position)
	actor.health_tag.pixel_size=pixel_size(distance)
	# Fixed-size HP remains readable far away. Convert its half-height back to
	# world space so the HP line stays immediately above the perspective nickname.
	var depth=maxf(1.,-viewer.camera.to_local(actor.tag.global_position).z)
	actor.health_tag.position.y=actor.tag.position.y+.10+depth*(actor.health_tag.font_size*actor.health_tag.pixel_size*.5+.004)
