extends RefCounted
class_name AimModel
static func spread(w:Dictionary,speed:float,ads:bool,crouch:bool,sprint:bool,grounded:bool,bloom:float,mounted=false,vertical_speed=0.,aim_fraction:float=-1.) -> float:
	if w.get("laser",false):return 0.
	if w.kind!="gun":return .1
	var movement=maxf(0.,speed)/Rules.WALK_SPEED
	var aiming=clampf(aim_fraction,0.,1.) if aim_fraction>=0 else (1. if ads else 0.)
	var base=lerpf(float(w.spread),float(w.get("ads_spread",float(w.spread)*.22)),aiming)
	var penalty=float(w.get("move_spread",1.))*movement
	if crouch:base*=.85 if int(w.pellets)>1 else .68;penalty*=.65
	penalty*=lerpf(1.,float(w.get("ads_move_scale",.45)),aiming);bloom*=lerpf(1.,.65,aiming)
	if not grounded:penalty+=(1.8 if int(w.pellets)==1 else 1.3)+minf(absf(vertical_speed)*.18,1.8)
	if sprint:penalty+=2.6
	if mounted:base*=.35;bloom*=.35;penalty*=.6
	return base+penalty+bloom
static func cone_direction(forward:Vector3,angle_degrees:float,u:float,v:float) -> Vector3:
	var right=forward.cross(Vector3.UP).normalized()
	if right.length_squared()<.01:right=Vector3.RIGHT
	var up=right.cross(forward).normalized();var radius=sqrt(clampf(u,0,1))*tan(deg_to_rad(angle_degrees));var theta=v*TAU
	return (forward+right*cos(theta)*radius+up*sin(theta)*radius).normalized()
static func pixel_radius(angle_degrees:float,fov:float,height:float) -> float:return tan(deg_to_rad(angle_degrees))*height*.5/tan(deg_to_rad(fov*.5))

# 1.5.4 (the user: a Counter-Strike style "T" spray): the first round goes where the cone
# puts it; then the muzzle climbs, then drifts to one side, then sweeps across to the
# other - the bar of the T - each gun with its own height, width and side (one side per
# class: "spray_direction", +1 = right first; never mirrored by the hand). The three
# legs share the magazine: a long belt climbs and sweeps by smaller steps, so its pattern
# keeps the same size. Degrees: x right, y up.
const T_RISE=.34 # share of the magazine spent climbing
const T_SWING=.64 # end of the first sideways leg
static func spray_offset(w:Dictionary,index:int) -> Vector2:
	if w.get("laser",false):return Vector2.ZERO
	if w.kind!="gun" or int(w.pellets)>1 or index<=0:return Vector2.ZERO
	var scale=float(w.get("pattern_scale",1.5))
	var height=float(w.get("spray_height",2.18))*scale;var width=float(w.get("spray_width",1.7))*scale
	var side=float(w.get("spray_direction",1.))
	var t=clampf(float(index)/maxf(5.,float(int(w.get("mag",30))-1)),0.,1.)
	var seed=float(w.get("spray_seed",0.))
	var x:float;var y:float
	# (1.5.4: a gun may lean its bar further one way - "spray_swing": how far the first leg goes,
	# "spray_cross": how far back across it comes, both shares of the width)
	var swing=float(w.get("spray_swing",.55));var cross=float(w.get("spray_cross",1.05))
	if t<T_RISE:
		var u=t/T_RISE
		y=height*(1.-pow(1.-u,1.7));x=side*width*.06*sin(u*PI)
	elif t<T_SWING:
		var u=(t-T_RISE)/(T_SWING-T_RISE)
		y=height*(1.+.06*u);x=side*width*swing*smoothstep(0.,1.,u)
	else:
		var u=(t-T_SWING)/(1.-T_SWING)
		y=height*(1.06+.04*sin(u*PI));x=side*width*(swing-cross*smoothstep(0.,1.,u))
	# each gun's own small wobble along the line (the same every spray: learnable)
	x+=sin(index*1.7+seed)*width*.025;y+=sin(index*2.3+seed*1.3)*height*.015
	return Vector2(x,y)
# 1.5.4: rounds after the first follow the pattern with only this share of the cone (the
# crosshair still opens): the T stays readable; moving still throws them wide.
const FOLLOW_CONE=.18
const FOLLOW_BLOOM=.03
static func follow_spread(w:Dictionary,speed:float,ads:bool,crouch:bool,sprint:bool,grounded:bool,bloom:float,mounted=false,vertical_speed=0.,aim_fraction:float=-1.) -> float:
	return spread(w,speed,ads,crouch,sprint,grounded,0.,mounted,vertical_speed,aim_fraction)*FOLLOW_CONE+bloom*FOLLOW_BLOOM
static func recover(p:Dictionary,w:Dictionary,dt:float,now:float):
	var age=maxf(0,now-float(p.get("shot_time",-100.)))
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	var long_burst=phase>6.
	var delay=float(w.get("recovery_delay",.14))+(.035 if long_burst else 0.)
	# (1.5.4: held automatic fire never recovers between its own rounds - the T builds round by round)
	if str(w.get("fire_mode","semi"))!="semi":delay=maxf(delay,float(w.get("interval",.1))*1.25)
	if age>delay:
		p.bloom=move_toward(float(p.get("bloom",0)),0.,dt*float(w.get("bloom_recovery",5.))*(.88 if long_burst else 1.))
		phase=move_toward(phase,0.,dt*float(w.get("pattern_recovery",34.))*(.78 if long_burst else 1.));p.spray_phase=phase;p.spray_index=int(phase)
static func current_spray(w:Dictionary,p:Dictionary,aim_fraction:float=0.,crouch:bool=false) -> Vector2:
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	return spray_offset(w,int(floor(phase))).lerp(spray_offset(w,int(floor(phase))+1),fmod(phase,1.))*lerpf(1.,.68,aim_fraction)*(.82 if crouch else 1.)
static func reticle_angle(w:Dictionary,p:Dictionary,cone:float,aim_fraction:float=0.,crouch:bool=false) -> float:
	# Envelope around the screen centre includes both random spread and pattern recoil.
	return cone+current_spray(w,p,aim_fraction,crouch).length()
