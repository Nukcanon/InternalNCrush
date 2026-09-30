class_name GripField
extends RefCounted
## Signed distance to a weapon's real surface around its grips (1.4.2), baked
## by tools/bake_grip_fields.py: hands lie on and fingers wrap the actual model
## instead of a box approximation (HeroIK.apply_grip).
## An entry {"id", "boxes"}: one axis-aligned box per hand in GunModel space
## (metres), each {"dims":Vector3i, "origin":Vector3 (min corner), "cell", "unit",
## "data":PackedByteArray int8, x fastest}; negative inside the model.
const PATH="res://assets/weapons/grip_fields.res"
const FAR=.05
static var entries={}
static var names={}
static var loaded=false
static func ensure():
	if loaded:return
	loaded=true
	if not ResourceLoader.exists(PATH):return
	var raw:Dictionary=load(PATH).get_meta("fields",{})
	for wid in raw:
		var boxes=[]
		for side in ["R","L"]:
			if raw[wid].has(side):boxes.append(raw[wid][side])
		entries[wid]={"id":str(wid),"boxes":boxes}
static func id_of(w:Dictionary) -> String:
	if names.is_empty():
		Catalog.load_all()
		for id in Catalog.weapons:names[str(Catalog.weapons[id].get("name",""))]=id
	return str(names.get(str(w.get("name","")),""))
static func lookup(wid:String) -> Dictionary:
	ensure();return entries.get(wid,{})
## Hand contact for a gun: the field plus the map from a handle frame (world
## metres, orthonormal, at the handle) into GunModel space, and world metres per
## GunModel metre.
static func contact(gun:Node3D,handle:Transform3D) -> Dictionary:
	if not gun is GunModel:return {}
	var entry=lookup(str(gun.get_meta("wid","")))
	if entry.is_empty():return {}
	var g:Transform3D=gun.global_transform
	var to_gun=g.affine_inverse()*Transform3D(handle.basis.orthonormalized(),handle.origin)
	# A handle moved away from the baked grips (third-person reach) has no field.
	var covered=false
	for box in entry.boxes:
		var lo:Vector3=box.origin+Vector3.ONE*.06;var hi:Vector3=box.origin+Vector3(box.dims-Vector3i.ONE)*float(box.cell)-Vector3.ONE*.06
		var p=to_gun.origin
		if p.x>=lo.x and p.y>=lo.y and p.z>=lo.z and p.x<=hi.x and p.y<=hi.y and p.z<=hi.z:covered=true;break
	if not covered:return {}
	return {"field":entry,"to_gun":to_gun,"k":absf(g.basis.get_scale().y)}
## Distance (GunModel metres, negative inside) at a GunModel-space point.
static func sample(entry:Dictionary,p:Vector3) -> float:
	for box in entry.boxes:
		var d:Vector3i=box.dims
		var g:Vector3=(p-box.origin)/float(box.cell)
		if g.x<0. or g.y<0. or g.z<0. or g.x>d.x-1.001 or g.y>d.y-1.001 or g.z>d.z-1.001:continue
		var x0=int(g.x);var y0=int(g.y);var z0=int(g.z)
		var fx=g.x-x0;var fy=g.y-y0;var fz=g.z-z0
		var data:PackedByteArray=box.data;var sy=d.x;var sz=d.x*d.y
		var i=x0+y0*sy+z0*sz
		var c00=lerpf(data.decode_s8(i),data.decode_s8(i+1),fx)
		var c10=lerpf(data.decode_s8(i+sy),data.decode_s8(i+sy+1),fx)
		var c01=lerpf(data.decode_s8(i+sz),data.decode_s8(i+sz+1),fx)
		var c11=lerpf(data.decode_s8(i+sz+sy),data.decode_s8(i+sz+sy+1),fx)
		return lerpf(lerpf(c00,c10,fy),lerpf(c01,c11,fy),fz)*float(box.unit)
	return FAR
## World-metre distance at a handle-frame point (world metres) of a contact.
static func distance(c:Dictionary,p:Vector3) -> float:
	var d=sample(c.field,c.to_gun*p)*float(c.k)
	# An extra rounded box in the handle frame (the firing hand round a pistol
	# grip, which the support hand closes over).
	if c.has("box"):d=minf(d,HeroIK.box_distance(p,c.box.half,float(c.box.round)))
	return d
## Distance from a handle-frame point inside the model to its surface along a
## direction (sphere tracing on the field; world metres), or -1 if the point is
## outside or no surface is met within `limit`.
static func reach(c:Dictionary,from:Vector3,dir:Vector3,limit:float=.09) -> float:
	var t=0.
	for i in range(40):
		var d=distance(c,from+dir*t)
		if d>=0.:return t if i>0 else -1.
		t+=maxf(.0015,-d)
		if t>limit:return -1.
	return -1.
## The real cross-section of a handle at its marker: centre offset and half
## extents (handle frame, world metres) across the two axes the hand wraps
## round — x/z for a vertical grip ("pistol"), x/y for a handguard along z
## ("support"). Averaged over three slices along the handle. {} if the marker
## is not inside the model there.
static var measure_cache={}
static func measure(c:Dictionary,style:String,along_half:float) -> Dictionary:
	if c.is_empty() or not style in ["pistol","support"]:return {}
	var tg:Transform3D=c.to_gun
	var key=str([c.field.id,style,tg.origin.snapped(Vector3.ONE*.001),tg.basis.x.snapped(Vector3.ONE*.01),tg.basis.y.snapped(Vector3.ONE*.01),snappedf(float(c.k),.001),snappedf(along_half,.001),Vector3(c.get("box",{}).get("half",Vector3.ZERO)).snapped(Vector3.ONE*.001)])
	if measure_cache.has(key):return measure_cache[key]
	if measure_cache.size()>256:measure_cache.clear()
	var along=Vector3.UP if style=="pistol" else Vector3.BACK
	var second=Vector3.BACK if style=="pistol" else Vector3.UP
	var sums={"xp":0.,"xn":0.,"sp":0.,"sn":0.};var n=0
	# Limits in world metres scale with the model (the view model is drawn larger).
	var ku=float(c.k)
	for f in [-.5,0.,.5]:
		var o=along*along_half*f
		var xp=reach(c,o,Vector3.RIGHT,.09*ku);var xn=reach(c,o,Vector3.LEFT,.09*ku);var sp=reach(c,o,second,.09*ku);var sn=reach(c,o,-second,.09*ku)
		if xp<0. or xn<0. or sp<0. or sn<0.:continue
		sums.xp+=xp;sums.xn+=xn;sums.sp+=sp;sums.sn+=sn;n+=1
	var out={}
	if n>0:
		for k in sums:sums[k]/=n
		var centre=Vector3.RIGHT*(sums.xp-sums.xn)*.5+second*(sums.sp-sums.sn)*.5
		out={"centre":centre.limit_length(.02*ku),"half_x":(sums.xp+sums.xn)*.5,"half_s":(sums.sp+sums.sn)*.5,"second":second}
	measure_cache[key]=out
	return out
