extends RefCounted
class_name AimModel
static func spread(w:Dictionary,speed:float,ads:bool,crouch:bool,sprint:bool,grounded:bool,bloom:float,mounted=false,vertical_speed=0.,aim_fraction:float=-1.) -> float:
	if w.kind!="gun":return .1
	var movement=maxf(0.,speed)/7.4
	var aiming=clampf(aim_fraction,0.,1.) if aim_fraction>=0 else (1. if ads else 0.)
	var base=lerpf(float(w.spread),float(w.get("ads_spread",float(w.spread)*.22)),aiming)
	var penalty=float(w.get("move_spread",1.))*movement
	if crouch:base*=.85 if int(w.pellets)>1 else .68;penalty*=.65
	penalty*=lerpf(1.,float(w.get("ads_move_scale",.45)),aiming);bloom*=lerpf(1.,.65,aiming)
	if not grounded:penalty+=(1.8 if int(w.pellets)==1 else 1.3)+minf(absf(vertical_speed)*.18,1.8)
	if sprint:penalty+=2.6
	if mounted and speed<.3:base*=.35;bloom*=.35
	return base+penalty+bloom
static func cone_direction(forward:Vector3,angle_degrees:float,u:float,v:float) -> Vector3:
	var right=forward.cross(Vector3.UP).normalized()
	if right.length_squared()<.01:right=Vector3.RIGHT
	var up=right.cross(forward).normalized();var radius=sqrt(clampf(u,0,1))*tan(deg_to_rad(angle_degrees));var theta=v*TAU
	return (forward+right*cos(theta)*radius+up*sin(theta)*radius).normalized()
static func pixel_radius(angle_degrees:float,fov:float,height:float) -> float:return tan(deg_to_rad(angle_degrees))*height*.5/tan(deg_to_rad(fov*.5))

static func spray_offset(w:Dictionary,index:int) -> Vector2:
	if w.kind!="gun" or int(w.pellets)>1:return Vector2.ZERO
	var scale=float(w.get("pattern_scale",1.5))
	var time=float(index)*float(w.interval)
	var build=maxf(.15,float(w.get("spray_build_seconds",1.2)))
	var progress=time/build
	var width=float(w.get("spray_width",1.7));var height=float(w.get("spray_height",2.18))
	var seed=float(w.get("spray_seed",0.));var direction=float(w.get("spray_direction",1.))
	# A learnable vertical stem followed by each gun's own lateral sweep and tempo.
	var stem=clampf(progress/.55,0.,1.)
	var lateral=smoothstep(.22,1.,progress)*sin((progress-.22)*float(w.get("spray_frequency",2.6))+seed)*width
	var drift=sin(index*.79+seed)*.045*minf(progress,1.)
	var rise=height*(1.-exp(-progress*2.8))
	if index==0:return Vector2.ZERO
	return Vector2((lateral+drift)*direction,rise+sin(progress*5.1)*.045*stem)*scale

static func recover(p:Dictionary,w:Dictionary,dt:float,now:float):
	var age=maxf(0,now-float(p.get("shot_time",-100.)))
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	var long_burst=phase>6.
	var delay=float(w.get("recovery_delay",.14))+(.035 if long_burst else 0.)
	if age>delay:
		p.bloom=move_toward(float(p.get("bloom",0)),0.,dt*float(w.get("bloom_recovery",5.))*(.88 if long_burst else 1.))
		phase=move_toward(phase,0.,dt*float(w.get("pattern_recovery",34.))*(.78 if long_burst else 1.));p.spray_phase=phase;p.spray_index=int(phase)
static func current_spray(w:Dictionary,p:Dictionary,aim_fraction:float=0.,crouch:bool=false) -> Vector2:
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	return spray_offset(w,int(floor(phase))).lerp(spray_offset(w,int(floor(phase))+1),fmod(phase,1.))*lerpf(1.,.68,aim_fraction)*(.82 if crouch else 1.)
static func reticle_angle(w:Dictionary,p:Dictionary,cone:float,aim_fraction:float=0.,crouch:bool=false) -> float:
	# Envelope around the screen centre includes both random spread and pattern recoil.
	return cone+current_spray(w,p,aim_fraction,crouch).length()
