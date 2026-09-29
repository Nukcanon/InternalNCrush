class_name HeroHitbox
extends RefCounted
## Ray test against a hero's bone-attached hit volumes (assets/heroes/hitboxes.json,
## measured from the mesh by tools/hitbox_bake.gd). Volumes follow the current
## animated pose, identically on server and clients.
static var volumes={}
static func load_volumes():
	if not volumes.is_empty():return
	volumes=JSON.parse_string(FileAccess.get_file_as_string("res://assets/heroes/hitboxes.json"))
static func v3(a:Array) -> Vector3:return Vector3(a[0],a[1],a[2])
static func sphere(from:Vector3,delta:Vector3,center:Vector3,radius:float) -> float:
	var o=from-center;var a=delta.length_squared();var b=o.dot(delta);var c=o.length_squared()-radius*radius
	if c<=0.:return 0.
	var disc=b*b-a*c
	if disc<0. or a<.0000001:return INF
	var t=(-b-sqrt(disc))/a
	return t if t>=0. and t<=1. else INF
# Segment a-b capsule of radius r; ray from->from+delta. Returns the hit fraction.
static func capsule(from:Vector3,delta:Vector3,a:Vector3,b:Vector3,r:float) -> float:
	var best=minf(sphere(from,delta,a,r),sphere(from,delta,b,r))
	var axis=b-a;var length=axis.length()
	if length<.0001:return best
	var u=axis/length
	var o=from-a
	var d_perp=delta-u*delta.dot(u);var o_perp=o-u*o.dot(u)
	var aa=d_perp.length_squared();var bb=o_perp.dot(d_perp);var cc=o_perp.length_squared()-r*r
	var disc=bb*bb-aa*cc
	if aa>.0000001 and disc>=0.:
		var t=(-bb-sqrt(disc))/aa
		if t>=0. and t<=1.:
			var s=(o+delta*t).dot(u)
			if s>=0. and s<=length:best=minf(best,t)
	return best
## Returns {"t": fraction along from->to, "zone": String} or {} when missed.
static func trace(hero:HeroCharacter,from:Vector3,to:Vector3) -> Dictionary:
	load_volumes()
	var list:Array=volumes.get(HeroCharacter.OUTFITS[hero.role],[])
	var best=INF;var zone="torso"
	var cache={}
	for v in list:
		var index=hero.skeleton.find_bone(v.bone)
		if index<0:continue
		if not cache.has(index):cache[index]=hero.bone_world(index).affine_inverse()
		var inv:Transform3D=cache[index]
		var start=inv*from;var end=inv*to
		var t:float
		if v.type=="capsule":t=capsule(start,end-start,v3(v.a),v3(v.b),float(v.r))
		else:
			var c=v3(v.c);var e=v3(v.e)
			t=sphere((start-c)/e,(end-start)/e,Vector3.ZERO,1.)
		if t<best:best=t;zone=v.zone
	if best==INF:return {}
	return {"t":best,"zone":zone}
