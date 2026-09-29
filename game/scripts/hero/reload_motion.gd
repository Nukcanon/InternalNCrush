class_name ReloadMotion
extends RefCounted
## Procedural reload hand work for the hero rigs (first and third person share
## it through HeroCharacter.solve_hands). The shooting hand stays on the grip;
## the support hand does the work in the gun's own space, phased over the
## weapon's reload progress `t` (0..1):
##  rifle / box / battery / tool: grab the magazine, pull it out with the
##    magazine animation, seat the new one, then rack the charging handle when
##    the gun was run dry (chambered guns keep their round: no racking).
##  pistol: the free hand comes in from the side, swaps the magazine under the
##    grip and racks the slide when needed.
##  shell / break: fetch a shell from the belt and push it into the loading port.
##  rocket: fetch a rocket, carry it to the tube and push it in.
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
## Support-hand handle for the current reload state, in the gun node's space.
## Returns {} when the ordinary grip applies.
static func support(gun:GunModel,s:Dictionary) -> Dictionary:
	var t=float(s.get("reload",-1.))
	var w=gun.spec;var style=str(w.get("reload_style","rifle"))
	var scale:Vector3=gun.base.scale*gun.scale.x
	var grip:Vector3=gun.right_grip.position*scale;var fore:Vector3=gun.left_grip.position*scale
	var top=gun.muzzle.position.y*scale.y+.05
	var pump=false
	if t<0.:
		# Pump-action shells: the support hand works the slide after each shot.
		if style=="shell" and w.get("single_load",false) and float(s.get("shot",99.))<.42:
			var age=float(s.get("shot",99.));var stroke=sin(clampf((age-.08)/.34,0.,1.)*PI)
			return {"position":fore+Vector3(0,0,.09*stroke),"style":"support"}
		return {}
	var tactical=bool(s.get("reload_tactical",false))
	var mag:Vector3=(gun.magazine.position*scale) if is_instance_valid(gun.magazine) else grip+Vector3(0,-.06,-.07)
	match style:
		"pistol":
			var approach=Vector3(-.16,-.22,.10)
			var slide=Vector3(0,top+.01,grip.z-.03)
			if t<.2:return {"position":approach.lerp(mag,smoothstep(0.,.2,t)),"style":"pistol"}
			if t<.8:return {"position":mag+mag_offset(t),"style":"pistol"}
			if tactical:return {"position":mag.lerp(approach,smoothstep(.8,1.,t)),"style":"pistol"}
			return rack(mag,slide,approach,t,.06,"pistol")
		"shell","break":
			var belt=Vector3(-.06,-.30,-.15);var port=Vector3(0,grip.y-.05,grip.z-.14) if style=="shell" else Vector3(0,top+.02,grip.z-.10)
			if t<.3:return {"position":fore.lerp(belt,smoothstep(0.,.3,t)),"style":"hold"}
			if t<.7:return {"position":belt.lerp(port,smoothstep(.3,.7,t)),"style":"hold"}
			return {"position":port.lerp(fore,smoothstep(.7,1.,t)),"style":"support"}
		"rocket":
			var count=int(s.get("rounds",0))
			var fetch=Vector3(-.22,-.36,-.25)
			if t<.35:return {"position":fore.lerp(fetch,smoothstep(0.,.35,t)),"style":"pistol"}
			if t<.85:
				# The hand holds the tail of the rocket as it slides into the tube.
				var rocket=gun.loading_round_position(count,minf(t,.8))
				var tail=rocket+Vector3(0,-.03,.12)
				return {"position":fetch.lerp(tail,smoothstep(.35,.45,t)) if t<.45 else tail,"style":"knife"}
			return {"position":(gun.loading_round_position(count,.8)+Vector3(0,-.03,.12)).lerp(fore,smoothstep(.85,1.,t)),"style":"pistol"}
		"battery":
			var pack=Vector3(0,top+.02,grip.z-.04)
			if t<.2:return {"position":fore.lerp(pack,smoothstep(0.,.2,t)),"style":"pistol"}
			if t<.8:
				var lift=sin(clampf((t-.2)/.6,0.,1.)*PI)
				return {"position":pack+Vector3(0,.12*lift,.04*lift),"style":"pistol"}
			return {"position":pack.lerp(fore,smoothstep(.8,1.,t)),"style":"support"}
		_:
			# Box magazines under the receiver (rifles, SMGs, machine guns, tools).
			if t<.08:return {"position":fore.lerp(mag,smoothstep(0.,.08,t)),"style":"pistol"}
			if t<.8:return {"position":mag+mag_offset(t),"style":"pistol"}
			if tactical:return {"position":mag.lerp(fore,smoothstep(.8,1.,t)),"style":"support"}
			var handle=Vector3(0,top+.02,grip.z-.06)
			return rack(mag,handle,fore,t,.08,"support")
# Charging handle / slide: reach it, pull it back, let it go, return to `home`.
static func rack(from:Vector3,handle:Vector3,home:Vector3,t:float,travel:float,home_style:String) -> Dictionary:
	if t<.87:return {"position":from.lerp(handle,smoothstep(.8,.87,t)),"style":"pistol"}
	if t<.93:return {"position":handle+Vector3(0,0,travel*sin(clampf((t-.87)/.06,0.,1.)*PI)),"style":"pistol"}
	return {"position":handle.lerp(home,smoothstep(.93,1.,t)),"style":home_style}
