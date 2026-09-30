class_name ReloadMotion
extends RefCounted
## Procedural reload hand work for the hero rigs (first and third person share
## it through HeroCharacter.solve_hands). The shooting hand stays on the grip;
## the support hand does the work in the gun's own space, phased over the
## weapon's reload progress `t` (0..1). Every phase names the grip style (hand
## frame) and the shape the hand closes on, so the fingers wrap what they hold:
##  rifle / box / battery / tool: grab the magazine (fist around it), pull it
##    out with the magazine animation, seat the new one, then rack the charging
##    handle overhand when the gun was run dry (chambered guns keep their round).
##  pistol: the free hand comes in from the side, swaps the magazine under the
##    grip and racks the slide overhand when needed.
##  shell / break: fetch a shell from the belt and push it up into the port.
##  rocket: fetch a rocket, bring it up behind the tipped launcher and push it,
##    nose first, into the open rear end (overhand: palm on top of the tail,
##    fingers wrapped down around its far side).
## Also the pump on shell guns after every shot.
const OUT_START=.08
const OUT_END=.30
const IN_START=.55
const IN_END=.80
static func mag_offset(t:float) -> Vector3:
	# Same curve as GunModel.animate_reload: down, swap out of sight, back up.
	var out=smoothstep(OUT_START,OUT_END,t)*(1.-smoothstep(IN_START,IN_END,t))
	var dip=sin(clampf((t-OUT_END)/(IN_START-OUT_END),0.,1.)*PI)
	return Vector3(0,-.22*out-.12*dip,.03*out+.02*dip)
static func hand(position:Vector3,style:String,shape:Dictionary={},basis:Basis=Basis.IDENTITY) -> Dictionary:
	return {"position":position,"style":style,"shape":shape,"basis":basis}
# Magazine centre (gun space) and grip shape (handle frame, base units).
static func magazine(gun:GunModel,scale:Vector3,fallback:Vector3) -> Array:
	if not is_instance_valid(gun.magazine):return [fallback,{"half":Vector3(.014,.045,.028),"round":.01}]
	var box=AABB()
	for m in gun.magazine.find_children("*","MeshInstance3D",true,false)+([gun.magazine] if gun.magazine is MeshInstance3D else []):
		# Skip replaced parts (the laser's cells stand in for its box magazine).
		if not m.visible or m.mesh==null:continue
		var local:AABB=GunModel.relative(m,gun.magazine)*m.get_aabb()
		box=local if box.size==Vector3.ZERO else box.merge(local)
	var centre:Vector3=gun.magazine.transform*box.get_center()
	var half=(box.size*.5).clamp(Vector3(.008,.02,.012),Vector3(.03,.07,.05))*scale.x
	return [centre*scale,{"half":half,"round":minf(half.x,.012)}]
## Support-hand grip for the current reload state, in the gun node's space:
## {position, basis, style, shape}. Returns {} when the ordinary grip applies.
static func support(gun:GunModel,s:Dictionary) -> Dictionary:
	var t=float(s.get("reload",-1.))
	var w=gun.spec;var style=str(w.get("reload_style","rifle"))
	# Gun-node space: marker positions times the base's own scale (the handle
	# transform adds the gun node's scale itself).
	var scale:Vector3=gun.base.scale
	var grip:Vector3=gun.right_grip.position*scale;var fore:Vector3=gun.left_grip.position*scale
	var fore_shape:Dictionary=scaled(gun.get_meta("grip_shapes",{}).get("L",{}),scale.x)
	var fore_basis:Basis=gun.left_grip.basis
	var fore_style=str(gun.get_meta("grip_styles",{}).get("L","support"))
	var top=gun.muzzle.position.y*scale.y+.05
	var home=hand(fore,fore_style,fore_shape,fore_basis)
	if t<0.:
		# Pump-action shells: the support hand works the slide after each shot.
		if style=="shell" and w.get("single_load",false) and float(s.get("shot",99.))<.42:
			var age=float(s.get("shot",99.));var stroke=sin(clampf((age-.08)/.34,0.,1.)*PI)
			home.position=fore+Vector3(0,0,.09*stroke);return home
		return {}
	var tactical=bool(s.get("reload_tactical",false))
	var mag_info=magazine(gun,scale,grip+Vector3(0,-.06,-.07))
	var mag:Vector3=mag_info[0];var mag_shape:Dictionary=mag_info[1]
	# Overhand on the charging handle / slide: palm down, fingers hooked over.
	var knob={"half":Vector3(.018,.012,.02),"round":.01}
	match style:
		"pistol":
			var approach=Vector3(-.16,-.22,.10)
			var slide=Vector3(-(mag_shape.half.x+.014),top-.03,grip.z-.05)
			if t<.2:return hand(approach.lerp(mag,smoothstep(0.,.2,t)),"pistol",mag_shape)
			if t<.8:return hand(mag+mag_offset(t),"pistol",mag_shape)
			if tactical:return hand(mag.lerp(approach,smoothstep(.8,1.,t)),"pistol",mag_shape)
			return rack(mag,slide,approach,t,.06,hand(approach,"pistol",mag_shape),mag_shape,knob)
		"shell","break":
			var shell={"half":Vector3(.011,.011,.03),"round":.011}
			var belt=Vector3(-.10,-.28,-.10)
			var port=Vector3(0,grip.y-.07,grip.z-.16) if style=="shell" else Vector3(0,top+.01,grip.z-.12)
			if t<.3:return hand(fore.lerp(belt,smoothstep(0.,.3,t)),"hold",shell)
			if t<.7:return hand(belt.lerp(port,smoothstep(.3,.7,t)),"hold" if style=="break" else "support",shell)
			var back=hand(port.lerp(fore,smoothstep(.7,1.,t)),fore_style,fore_shape,fore_basis)
			return back
		"rocket":
			# Rear loading: the hand grips the rocket's tail overhand,
			# brings it up behind the tube, pushes it in, then returns.
			var count=int(s.get("rounds",0))
			var show=GunModel.LOAD_SHOW;var push=GunModel.LOAD_PUSH
			var rocket=gun.loading_round(count)
			var r=float(rocket.get("radius",.04))*scale.x;var length=float(rocket.get("length",.3))*scale.x
			var body={"half":Vector3(r,r,length*.22),"round":r}
			var tail_at=func(time:float) -> Vector3:return gun.loading_grip(count,time)
			var below=Vector3(-.10,-.26,.06)
			if t<show:
				var from=fore.lerp(below,smoothstep(0.,show*.6,t))
				return hand(from.lerp(tail_at.call(show),smoothstep(show*.6,show,t)),"over",body)
			if t<push+.04:return hand(tail_at.call(t),"over",body)
			return hand(tail_at.call(push).lerp(fore,smoothstep(push+.04,1.,t)),fore_style,fore_shape,fore_basis)
		"battery":
			# Laser rifle: two D-size cells under the receiver. A fist closes on
			# the pair, pulls it down and away with the magazine animation, seats
			# a fresh pair and returns; there is no bolt to work.
			if t<.08:return hand(fore.lerp(mag,smoothstep(0.,.08,t)),"pistol",mag_shape)
			if t<.8:return hand(mag+mag_offset(t),"pistol",mag_shape)
			return hand(mag.lerp(fore,smoothstep(.8,1.,t)),fore_style,fore_shape,fore_basis)
		_:
			# Box magazines under the receiver (rifles, SMGs, machine guns, tools).
			if t<.08:return hand(fore.lerp(mag,smoothstep(0.,.08,t)),"pistol",mag_shape)
			if t<.8:return hand(mag+mag_offset(t),"pistol",mag_shape)
			if tactical:return hand(mag.lerp(fore,smoothstep(.8,1.,t)),fore_style,fore_shape,fore_basis)
			var knob_at=Vector3(-(mag_shape.half.x+.02),top-.04,grip.z-.2)
			return rack(mag,knob_at,fore,t,.08,home,mag_shape,knob)
static func scaled(shape:Dictionary,factor:float) -> Dictionary:
	if shape.is_empty():return shape
	var out=shape.duplicate();out.half=shape.half*factor;out.round=float(shape.round)*factor
	if shape.has("trigger"):out.trigger=shape.trigger*factor
	return out
# Charging handle / slide on the near (support-hand) side, ahead of the grip:
# the support hand hooks it from the side (palm toward the gun), pulls it back,
# lets go and returns. A top-rear handle put the whole forearm in front of
# the first-person eye.
const SIDE_GRAB=Basis(Vector3(0,0,1),PI/2)
static func rack(from:Vector3,knob:Vector3,home_position:Vector3,t:float,travel:float,home:Dictionary,from_shape:Dictionary,knob_shape:Dictionary) -> Dictionary:
	if t<.84:return hand(from,"pistol",from_shape)
	if t<.87:return hand(from.lerp(knob,smoothstep(.84,.87,t)),"top",knob_shape,SIDE_GRAB)
	if t<.93:return hand(knob+Vector3(0,0,travel*sin(clampf((t-.87)/.06,0.,1.)*PI)),"top",knob_shape,SIDE_GRAB)
	var back=home.duplicate();back.position=knob.lerp(home_position,smoothstep(.93,1.,t))
	return back
