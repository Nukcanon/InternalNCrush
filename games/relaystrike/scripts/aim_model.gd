extends RefCounted
class_name AimModel
static func spread(w:Dictionary,speed:float,ads:bool,crouch:bool,sprint:bool,grounded:bool,bloom:float,mounted=false,vertical_speed=0.) -> float:
	if w.kind!="gun":return .1
	var movement=clampf(speed/7.4,0,1.5)
	var base=float(w.spread);var penalty=float(w.get("move_spread",1.))*movement
	if crouch:base*=.68;penalty*=.65
	if ads:
		base*=.85 if int(w.pellets)>1 else .22;penalty*=.65 if int(w.pellets)>1 else .38;bloom*=.5
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
	var scale=.7 if int(w.role)==4 else 1.15 if int(w.role)==2 else .9
	if w.fire_mode=="semi":return Vector2(0,minf(index,4)*.23)
	# Original game pattern: initial vertical stem, then horizontal branches.
	if index<8:return Vector2(sin(index*.8)*.055,index*.29)*scale
	var phase=(index-8)%22;var x=0.
	if phase<6:x=lerpf(0.,1.7,phase/5.)
	elif phase<16:x=lerpf(1.7,-1.7,(phase-6)/9.)
	else:x=lerpf(-1.7,0.,(phase-16)/5.)
	return Vector2(x,2.18+sin(phase*.55)*.11)*scale

static func recover(p:Dictionary,w:Dictionary,dt:float,now:float):
	var age=maxf(0,now-float(p.get("shot_time",-100.)))
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	var long_burst=phase>6.
	var delay=.22 if long_burst else .12
	if age>delay:
		p.bloom=move_toward(float(p.get("bloom",0)),0.,dt*(.9 if long_burst else 1.9))
		phase=move_toward(phase,0.,dt*(18. if long_burst else 25.));p.spray_phase=phase;p.spray_index=int(phase)
static func current_spray(w:Dictionary,p:Dictionary) -> Vector2:
	var phase=float(p.get("spray_phase",p.get("spray_index",0)))
	return spray_offset(w,int(floor(phase))).lerp(spray_offset(w,int(floor(phase))+1),fmod(phase,1.))
