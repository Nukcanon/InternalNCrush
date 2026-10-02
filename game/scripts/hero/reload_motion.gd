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
	# 1.4.4 round 9: only as far as the bottom of the first-person view (the
	# hand follows it): dropped .62 m it vanished and the hand seemed to work
	# on nothing under the well.
	# 1.4.5: .28 left the magazine's top in the well (it did not read as pulled
	# out); .45 clears the well on every rifle and stays in the frame.
	return Vector3(-.04*drop,-.45*drop,.22*drop)
## The magazine's travel for this gun (gun-node space): proportional to its
## own height, so a pistol's short magazine comes just clear of the grip (and
## stays in view) while a rifle's long one travels further (1.4.5: the fixed
## offset put a pistol's magazine 80 cm below the eye, out of the view).
## 1.4.6 (the user: the magazine never came out - it only tipped back while the
## hand dropped): it slides STRAIGHT down out of the well first (no tilt), clear
## of the gun by its own height, and only then swings out toward the support
## hand's side and back; it goes in the same way in reverse (across under the
## well, then straight up).
static func mag_travel(gun:GunModel,t:float) -> Vector3:
	# (the user, round 2: the magazine leaves the screen completely with the
	# hand and comes back in with the new one - so past its own length it keeps
	# going down and back toward the body, out of the first-person view; how far
	# depends on the magazine's length, so it differs a little per gun)
	var drop=mag_drop(t);var h=float(gun.mag_height)
	var clear=smoothstep(0.,.35,drop);var away=smoothstep(.3,1.,drop)
	# (1.4.10, the user: the new magazine came in too low) on the way in it is back
	# under the well early and rises straight up from there
	if t>IN_START:clear=smoothstep(0.,.5,drop);away=smoothstep(.55,1.,drop)
	return Vector3(-(.55*h+.08)*away,-MAG_CLEAR*h*clear-OFF_VIEW*away,(.45*h+OFF_BACK)*away)
const OFF_VIEW=.6 # (the user: lower the hand further if needed - out of view on every gun)
const OFF_BACK=.34 # toward the body: the first-person arm can reach there (below the view)
## The magazine's lean once clear of the well: turned a little toward the
## support hand (a roll), never tipped back on the gun.
static func mag_lean(t:float) -> float:
	return .35*smoothstep(.3,1.,mag_drop(t))
## True while the support hand carries the magazine (it moves with the hand).
static func carrying(t:float) -> bool:return t>=DETACH and t<=SEAT
const MAG_CLEAR=1.05 # (1.4.10, the user: the magazine sat too low under the gun - just clear of the well, then away)
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
	# 1.4.10 (the user: hold it so the magazine sticks up out of the hand toward the
	# well): the hand closes round the lower part, the magazine standing above it.
	var upper=centre-Vector3(0,box.size.y*.22,0)
	return [upper*scale,{"half":half,"round":minf(half.x,.012)}]
## Where the round being loaded is (gun space) and whether it shows, for the
## shell, break and revolver cycles; the hand holds it there.
static func round_point(gun:GunModel,t:float) -> Array:
	var style=str(gun.spec.get("reload_style",""));var s:Vector3=gun.base.scale
	var h:Dictionary=GunModel.handles(str(gun.look.get("base","")))
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
## Pump-action stroke (0..1, 1 = pulled back): after each shot, and (1.4.10)
## once when shell loading ends - after the last shell or when a shot cuts it
## ("pump": seconds since that end, Actor tracks it).
const PUMP_TIME=.34
static func pumping(s:Dictionary) -> bool:
	return float(s.get("shot",99.))<.42 or float(s.get("pump",99.))<PUMP_TIME
static func pump_stroke(s:Dictionary) -> float:
	var after_shot=sin(clampf((float(s.get("shot",99.))-.08)/PUMP_TIME,0.,1.)*PI)
	var after_load=sin(clampf(float(s.get("pump",99.))/PUMP_TIME,0.,1.)*PI)
	return maxf(after_shot,after_load)
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
		# Pump-action shells: the support hand works the slide after each shot,
		# and (1.4.10) once after the last shell or when a shot cuts the loading.
		if style=="shell" and w.get("single_load",false) and pumping(s):
			home.position=fore+Vector3(0,0,.09*pump_stroke(s));return home
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
			if t<RACK:return hand(mag+mag_travel(gun,t),"pistol",mag_shape)
			# (1.4.10, the user: no rack at the end - the slide was locked back and runs
			# forward by itself as the magazine seats)
			return hand(mag.lerp(approach,smoothstep(RACK,1.,t)),"pistol",mag_shape)
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
			# 1.4.5: the round stays on its path into the gun; the hand is placed
			# so the round lies between the thumb tip and the index finger
			# (measured with tools/review_hands.gd thumbspot: the gap sat 3.7 cm,
			# for shells 5.9 cm, above the round).
			if style=="revolver":
				at+=Vector3(-.013,-.055,.046);cartridge={"half":Vector3(.009,.009,.055),"round":.009}
			# 1.4.5: shells likewise ride ahead of the fingertips (held in the fist
			# they were hidden inside the hand).
			elif style in ["shell","break"]:
				at+=Vector3(.003,-.073,.058);cartridge={"half":Vector3(.0095,.0095,.06),"round":.0095}
			# 1.4.10 (the user: shell, pump, down for a shell, pump...): shells loaded one
			# after another go in back to back - each cycle after the first starts down
			# at the shells, and only the last one returns the hand to the pump.
			var shell_chain=style=="shell" and bool(s.get("reload_chain",false))
			var last=style!="shell" or int(s.get("rounds",0))+1>=int(s.get("capacity",99)) or int(s.get("reserve",99))<=1
			var fetch:Vector3=round_point(gun,0.)[0]+Vector3(.003,-.073,.058)
			if shell_chain:start=fetch
			if t<lead:return hand(start.lerp(at,smoothstep(0.,lead,t)),"hold",cartridge)
			var done=.78 if style=="shell" else .76 if style=="break" else .8
			if style=="shell" and not last and t>=done:return hand(at.lerp(fetch,smoothstep(done,1.,t)),"hold",cartridge)
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
			# 1.4.4: a fist round the rocket's body (the grip solver's cylinder laid
			# along the rocket): palm on the near side, fingers over the top and
			# round it (a C seen from behind), thumb along the side pointing back.
			# The other hand mirrors it (left-handed heroes are mirrored).
			var body={"half":Vector3(r,length*.22,r),"round":r}
			var tail_at=func(time:float) -> Vector3:return gun.loading_grip(count,time)
			var below=Vector3(-.10,-.26,.06)
			if t<show:
				var from=fore.lerp(below,smoothstep(0.,show*.6,t))
				return hand(from.lerp(tail_at.call(show),smoothstep(show*.6,show,t)),"pistol",body,ROCKET_FIST)
			if t<push+.04:return hand(tail_at.call(t),"pistol",body,ROCKET_FIST)
			# 1.4.5: back to the front grip round the outside of the launcher (the
			# straight line from behind the tubes ran through the tube cluster).
			var rear_out:Vector3=tail_at.call(push)+Vector3(-.14,-.10,.04)
			var leg=smoothstep(push+.04,1.,t)
			if leg<.45:return hand(tail_at.call(push).lerp(rear_out,leg/.45),fore_style,fore_shape,fore_basis)
			return hand(rear_out.lerp(fore,(leg-.45)/.55),fore_style,fore_shape,fore_basis)
		"battery":
			# Laser rifle: two D-size cells under the receiver. A fist closes on
			# the pair, takes it down and out of view with the magazine, seats a
			# fresh pair and returns; there is no bolt to work.
			if t<GRAB:return hand(fore.lerp(mag,smoothstep(0.,GRAB,t)),"pistol",mag_shape)
			if t<RACK:return hand(mag+mag_travel(gun,t),"pistol",mag_shape)
			return hand(mag.lerp(fore,smoothstep(RACK,1.,t)),fore_style,fore_shape,fore_basis)
		_:
			# Box magazines under the receiver (rifles, SMGs, machine guns, tools).
			if t<GRAB:return hand(fore.lerp(mag,smoothstep(0.,GRAB,t)),"pistol",mag_shape)
			if t<RACK:return hand(mag+mag_travel(gun,t),"pistol",mag_shape)
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
# Handle frame for a fist round a rocket: the grip axis (+Y) along the rocket
# (gun +Z) and the knuckles (-Z of the handle) pointing up (gun +Y).
const ROCKET_FIST=Basis(Vector3(1,0,0),Vector3(0,0,1),Vector3(0,-1,0))
static func rack(from:Vector3,knob:Vector3,home_position:Vector3,t:float,travel:float,home:Dictionary,from_shape:Dictionary,knob_shape:Dictionary) -> Dictionary:
	if t<.84:return hand(from,"pistol",from_shape)
	if t<.87:return hand(from.lerp(knob,smoothstep(.84,.87,t)),"top",knob_shape,SIDE_GRAB)
	if t<.93:return hand(knob+Vector3(0,0,travel*sin(clampf((t-.87)/.06,0.,1.)*PI)),"top",knob_shape,SIDE_GRAB)
	var back=home.duplicate();back.position=knob.lerp(home_position,smoothstep(.93,1.,t))
	return back
