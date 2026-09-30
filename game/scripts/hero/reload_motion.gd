class_name ReloadMotion
extends RefCounted
## Procedural reload hand work for the hero rigs (first and third person share
## it through HeroCharacter.solve_hands). The shooting hand stays on the grip;
## the support hand does the work in the gun's own space, phased over the
## weapon's reload progress `t` (0..1). Every phase names the grip style (hand
## frame) and the shape the hand closes on, so the fingers wrap what they hold:
##  rifle / box / battery / tool: grab the magazine where it sits on this gun,
##    pull it down and out of the view with the magazine (GunModel.animate_reload
##    moves it on the same curve), bring the new one up, seat it, then rack the
##    charging handle overhand when the gun was run dry.
##  pistol: the free hand comes in from the side and swaps the magazine under
##    the grip the same way, then racks the slide overhand when needed.
##  shell: fetch a shell, bring it under the loading port just ahead of the
##    trigger guard and push it up into the tube (one shell per cycle).
##  break: fetch a shell and push it into the breech at the back of the barrels.
##  revolver: one round per cycle into the loading gate at the rear of the
##    cylinder (the cycle is the full reload time divided by the rounds).
##  rocket: fetch a rocket, bring it up behind the tipped launcher and push it,
##    nose first, into the open rear end, held underhand in a C (thumb under,
##    fingers over the top).
##  dual (DUET): each hand takes its own pistol out of view and back in turn;
##    the grips simply follow the pistols (GunModel.animate_reload).
## Also the pump on shell guns after every shot.
# Magazine timeline (1.4.2): the rounds leave with the magazine at DETACH and
# come back when the new one is seated at SEAT (AmmoPips shows the same).
const GRAB=.06
const DETACH=.12
const OUT_END=.30
const IN_START=.50
const SEAT=.74
const RACK=.80
static func mag_drop(t:float) -> float:
	return smoothstep(DETACH,OUT_END,t)*(1.-smoothstep(IN_START,SEAT,t))
## Magazine offset in gun space: well below and behind the gun, out of the
## first-person view, while the magazines are swapped.
static func mag_offset(t:float) -> Vector3:
	var drop=mag_drop(t)
	return Vector3(-.05*drop,-.62*drop,.30*drop)
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
	# Rest position (the magazine node may be mid-swap right now).
	var centre:Vector3=gun.mag_rest*box.get_center()
	var half=(box.size*.5).clamp(Vector3(.008,.02,.012),Vector3(.03,.07,.05))*scale.x
	# The hand closes round the upper half (near the magazine well).
	var upper=centre+Vector3(0,box.size.y*.18,0)
	return [upper*scale,{"half":half,"round":minf(half.x,.012)}]
## Where the round being loaded is (gun space) and whether it shows, for the
## shell, break and revolver cycles; the hand holds it there.
static func round_point(gun:GunModel,t:float) -> Array:
	var style=str(gun.spec.get("reload_style",""));var s:Vector3=gun.base.scale
	var h:Dictionary=GunModel.HANDLES.get(str(gun.look.get("base","")),{})
	match style:
		"shell":
			var port:Vector3=Vector3(h.get("port",Vector3(0,-.085,-.50)))*s
			var below=port+Vector3(-.02,-.10,.05);var belt=Vector3(-.16,-.42,.10)
			if t<.28:return [belt,false]
			if t<.58:return [belt.lerp(below,smoothstep(.28,.58,t)),true]
			if t<.78:return [below.lerp(port+Vector3(0,.012,-.03),smoothstep(.58,.78,t)),true]
			return [port,false]
		"break":
			var breech:Vector3=Vector3(h.get("breech",Vector3(0,.02,-.56)))*s
			var behind=breech+Vector3(-.02,.06,.09);var belt=Vector3(-.16,-.42,.10)
			if t<.25:return [belt,false]
			if t<.55:return [belt.lerp(behind,smoothstep(.25,.55,t)),true]
			if t<.76:return [behind.lerp(breech+Vector3(0,0,-.03),smoothstep(.55,.76,t)),true]
			return [breech,false]
		"revolver":
			var gate:Vector3=Vector3(h.get("gate",Vector3(-.022,.014,-.03)))*s
			var behind=gate+Vector3(-.006,-.005,.045);var low=gate+Vector3(-.07,-.16,.08)
			if t<.18:return [low,false]
			if t<.55:return [low.lerp(behind,smoothstep(.18,.55,t)),true]
			if t<.8:return [behind.lerp(gate+Vector3(0,0,-.012),smoothstep(.55,.8,t)),true]
			return [gate,false]
	return [Vector3.ZERO,false]
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
	if style=="dual":return {}
	var tactical=bool(s.get("reload_tactical",false))
	var mag_info=magazine(gun,scale,grip+Vector3(0,-.06,-.07))
	var mag:Vector3=mag_info[0];var mag_shape:Dictionary=mag_info[1]
	# Overhand on the charging handle / slide: palm down, fingers hooked over.
	var knob={"half":Vector3(.018,.012,.02),"round":.01}
	var cartridge={"half":Vector3(.009,.009,.026),"round":.009}
	match style:
		"pistol":
			var approach=Vector3(-.16,-.22,.10)
			var slide=Vector3(-(mag_shape.half.x+.014),top-.03,grip.z-.05)
			if t<.16:return hand(approach.lerp(mag,smoothstep(0.,.16,t)),"pistol",mag_shape)
			if t<RACK:return hand(mag+mag_offset(t),"pistol",mag_shape)
			if tactical:return hand(mag.lerp(approach,smoothstep(RACK,1.,t)),"pistol",mag_shape)
			return rack(mag,slide,approach,t,.06,hand(approach,"pistol",mag_shape),mag_shape,knob)
		"shell","break","revolver":
			# The hand carries the round along its path and lets go at the port.
			var r=round_point(gun,t);var at:Vector3=r[0]
			var start=(grip+Vector3(-.02,-.07,-.05)) if style=="revolver" else fore
			var back_style=fore_style if style!="revolver" else "pistol"
			var back_shape=fore_shape if style!="revolver" else cartridge
			var lead=.28 if style=="shell" else .25 if style=="break" else .18
			# A revolver round is small and goes in at the fingertips: the palm stays
			# behind and below it (on a rod reaching forward to the round) instead
			# of closing over the whole revolver.
			if style=="revolver":
				at+=Vector3(-.03,-.018,.05);cartridge={"half":Vector3(.009,.009,.055),"round":.009}
			if t<lead:return hand(start.lerp(at,smoothstep(0.,lead,t)),"hold",cartridge)
			var done=.78 if style=="shell" else .76 if style=="break" else .8
			if t<done:return hand(at,"hold",cartridge)
			if style=="revolver" and t<1.:return hand(at.lerp(start,smoothstep(done,1.,t)),"hold",cartridge)
			return hand(at.lerp(fore,smoothstep(done,1.,t)),back_style,back_shape,fore_basis)
		"rocket":
			# Rear loading, underhand: the palm under the tail, thumb along the
			# near side below it and the fingers round the top (a C), so the wrist
			# stays nearly straight as the rocket goes up and in.
			var count=int(s.get("rounds",0))
			var show=GunModel.LOAD_SHOW;var push=GunModel.LOAD_PUSH
			var rocket=gun.loading_round(count)
			var r=float(rocket.get("radius",.04))*scale.x;var length=float(rocket.get("length",.3))*scale.x
			var body={"half":Vector3(r,r,length*.22),"round":r}
			var tail_at=func(time:float) -> Vector3:return gun.loading_grip(count,time)
			var below=Vector3(-.10,-.26,.06)
			# 1.4.4: a side C-grip (HeroIK "cradle"): palm on the near side,
			# fingers over the top, thumb underneath; mirrored for the other hand.
			if t<show:
				var from=fore.lerp(below,smoothstep(0.,show*.6,t))
				return hand(from.lerp(tail_at.call(show),smoothstep(show*.6,show,t)),"cradle",body)
			if t<push+.04:return hand(tail_at.call(t),"cradle",body)
			return hand(tail_at.call(push).lerp(fore,smoothstep(push+.04,1.,t)),fore_style,fore_shape,fore_basis)
		"battery":
			# Laser rifle: two D-size cells under the receiver. A fist closes on
			# the pair, takes it down and out of view with the magazine, seats a
			# fresh pair and returns; there is no bolt to work.
			if t<GRAB:return hand(fore.lerp(mag,smoothstep(0.,GRAB,t)),"pistol",mag_shape)
			if t<RACK:return hand(mag+mag_offset(t),"pistol",mag_shape)
			return hand(mag.lerp(fore,smoothstep(RACK,1.,t)),fore_style,fore_shape,fore_basis)
		_:
			# Box magazines under the receiver (rifles, SMGs, machine guns, tools).
			if t<GRAB:return hand(fore.lerp(mag,smoothstep(0.,GRAB,t)),"pistol",mag_shape)
			if t<RACK:return hand(mag+mag_offset(t),"pistol",mag_shape)
			if tactical:return hand(mag.lerp(fore,smoothstep(RACK,1.,t)),fore_style,fore_shape,fore_basis)
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
