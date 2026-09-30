class_name HeroIK
extends RefCounted
## Arm and hand posing on the hero skeleton.
##  * Two-bone arm IK (UpperArm -> LowerArm -> Wrist) toward a wrist transform.
##    The forearm takes any twist about its own axis (the wrist cannot twist)
##    and the wrist itself only bends within human limits.
##  * Grips: an item marker ("handle") plus a grip shape (a rounded box in the
##    handle frame). The palm is laid on the shape, the knuckles at its far
##    edge, and every finger joint bends until the finger touches the surface,
##    so fingers wrap handles of any size without passing through them. On gun
##    grips the index finger reaches for the trigger instead.
const POLE={"R":Vector3(.55,-.75,.35),"L":Vector3(-.55,-.75,.35)} # hero-local: +x right, -z forward
const ELBOW_SAMPLES=12
const TORSO_W=24. # elbow cost per unit of arm depth inside the torso (third person)
const POLE_FP={"R":Vector3(.3,-1.,.15),"L":Vector3(-.3,-1.,.15)} # first person: elbows hang below the view
# First person (1.4.2): only forearms and hands are drawn, so each forearm is
# laid out like a shooter view model instead of hanging from a real shoulder:
# from the wrist it runs back, down and out toward its lower screen corner
# (hero-local: +x right, +y up, +z back), bent from the hand by at most
# FP_BEND. The hidden shoulder slides so the upper arm meets that elbow.
const FOREARM_FP={"R":Vector3(.32,-.52,.79),"L":Vector3(-.46,-.58,.67)}
const FP_BEND=.8
static func fp_forearm(hero:HeroCharacter,side:String,hand_dir:Vector3,wrist:Vector3=Vector3.INF,length:float=0.) -> Vector3:
	var natural:Vector3=(hero.facing_basis()*FOREARM_FP[side]).normalized()
	var back:Vector3=-hand_dir.normalized()
	var angle=natural.angle_to(back)
	var f=natural if angle<=FP_BEND else back.slerp(natural,FP_BEND/angle).normalized()
	# Only forearms are drawn: the elbow end must stay out of view (reloads and
	# gear bring the hands low and close), so swing it further down until the
	# end of the forearm leaves the screen.
	var cam=hero.get_meta("fp_camera",null)
	if cam is Camera3D and is_instance_valid(cam) and wrist!=Vector3.INF:
		# Down and back toward the eye (down alone cannot leave the frame when
		# the hand is far forward), and out to the arm's own side.
		var away=fp_away(hero,side,cam)
		for i in range(12):
			if not on_screen(cam,wrist+f*length) and not on_screen(cam,wrist+f*length*.85):break
			f=(f+away*.25).normalized()
	return f
# Down, back toward the eye and out to the arm's own side (down alone cannot
# leave the frame when the hand is far forward).
static func fp_away(hero:HeroCharacter,side:String,cam:Camera3D) -> Vector3:
	var b:Basis=cam.global_basis
	var out=hero.facing_basis().x.normalized()*(1. if side=="R" else -1.)
	return (-b.y*.7+b.z*.6+out*.3).normalized()
# The drawn arm's open end is the (hidden) shoulder: point the upper arm from
# the elbow toward the resting shoulder, swung out of view if needed.
static func fp_upper(hero:HeroCharacter,side:String,elbow:Vector3,rest_shoulder:Vector3,length:float) -> Vector3:
	var u=(rest_shoulder-elbow).normalized()
	var cam=hero.get_meta("fp_camera",null)
	if cam is Camera3D and is_instance_valid(cam):
		var away=fp_away(hero,side,cam)
		for i in range(12):
			if not on_screen(cam,elbow+u*length) and not on_screen(cam,elbow+u*length*.8):break
			u=(u+away*.25).normalized()
	return u
static func on_screen(cam:Camera3D,p:Vector3) -> bool:
	var local:Vector3=cam.global_transform.affine_inverse()*p
	if local.z>-.02:return false
	var size:Vector2=cam.get_viewport().get_visible_rect().size
	var t=tan(deg_to_rad(cam.fov)*.5)*1.04
	return absf(local.y)<-local.z*t and absf(local.x)<-local.z*t*size.x/maxf(1.,size.y)
# Human limits: wrist bend (flexion / deviation) and forearm twist.
const WRIST_LIMIT=1.15
const TWIST_LIMIT=1.9
static var calibration={}
static func rot(hero:HeroCharacter,index:int) -> Quaternion:return hero.bone_world(index).basis.get_rotation_quaternion()
# Wrist orientation relative to the facing frame in the two-handed aim clip
# (legacy markers without grip styles: the bomb keypad).
static func calibrate(hero:HeroCharacter) -> Dictionary:
	var key=hero.role
	if calibration.has(key):return calibration[key]
	var saved=hero.tree.active;hero.tree.active=false
	var anim=hero.player.get_animation("Pistol_Aim_Neutral")
	var out={}
	for side in ["R","L"]:
		var wrist=hero.skeleton.find_bone("Wrist."+side)
		var pose={}
		for t in range(anim.get_track_count()):
			if anim.track_get_type(t)!=Animation.TYPE_ROTATION_3D:continue
			var b=hero.skeleton.find_bone(str(anim.track_get_path(t)).get_slice(":",1))
			if b>=0:pose[b]=anim.rotation_track_interpolate(t,.1)
		var chain=[];var i=wrist
		while i>=0:chain.push_front(i);i=hero.skeleton.get_bone_parent(i)
		var q=Quaternion.IDENTITY
		for b in chain:q=q*Quaternion(pose.get(b,hero.skeleton.get_bone_pose_rotation(b)))
		# Clip space: glTF +Z forward; hero facing is the model rotated by PI.
		out[side]=Quaternion(Vector3.UP,PI)*q
	hero.tree.active=saved
	calibration[key]=out;return out
# --- Hand frames -------------------------------------------------------------
# Wrist-local axes of this rig: +Y wrist -> knuckles, -Z palm, thumb -X (right
# hand) / +X (left hand). A "handle" is the item point the palm wraps, in a
# frame with -Z along the item and +Y up. FRAMES give the wrist axes (columns
# x, y, z) inside that handle frame for each grip style and side.
static func knife_frame(side:String) -> Basis:
	# Hammer grip on a handle along Z: the handle crosses the palm diagonally,
	# knuckles forward-down, the wrist above and behind the handle.
	var f=Basis(Vector3(0,0,1),Vector3(0,-1,0),Vector3(1,0,0)) if side=="R" else Basis(Vector3(0,0,-1),Vector3(0,-1,0),Vector3(-1,0,0))
	return Basis(Vector3.RIGHT,.75)*f
static func support_frame(side:String) -> Basis:
	# A shooter's support hand under a handguard: the palm faces up (a little
	# toward the gun's far side), the knuckles point forward, across and up, the
	# thumb lies along the near side pointing forward, and the fingers curl up
	# the far side. The forearm then continues down, back and out from the wrist
	# instead of crossing the gun at right angles. Built for the left hand; the
	# right hand is its mirror image (M * B * M keeps the basis right-handed).
	var knuckles=SUPPORT_KNUCKLES.normalized()
	var palm=(SUPPORT_PALM-knuckles*SUPPORT_PALM.dot(knuckles)).normalized()
	var z=-palm;var y=knuckles;var x=y.cross(z).normalized()
	var left=Basis(x,y,z)
	if side=="L":return left
	var m=Basis.from_scale(Vector3(-1,1,1))
	return m*left*m
# Overhand ("top"): palm down, knuckles forward and across so the forearm comes
# from the near side (not straight back at the eye in first person).
static func top_frame(side:String) -> Basis:
	var y=TOP_KNUCKLES.normalized();var z=Vector3.UP;var x=y.cross(z).normalized()
	var left=Basis(x,y,z)
	if side=="L":return left
	var m=Basis.from_scale(Vector3(-1,1,1))
	return m*left*m
const TOP_KNUCKLES=Vector3(.6,0.,-.8)
const SUPPORT_KNUCKLES=Vector3(.62,.40,-.68) # handle frame: +x far side (left hand), +y up, -z forward
const SUPPORT_PALM=Vector3(.25,1.,0.)
static var FRAMES={
	# Fist around a vertical grip: palm toward the gun, thumb up, knuckles forward.
	"pistol":{"R":Basis(Vector3(0,-1,0),Vector3(0,0,-1),Vector3(1,0,0)),"L":Basis(Vector3(0,1,0),Vector3(0,0,-1),Vector3(-1,0,0))},
	"support":{"R":support_frame("R"),"L":support_frame("L")},
	"knife":{"R":knife_frame("R"),"L":knife_frame("L")},
	# Small object cupped in the palm (grenades): the pistol fist around a ball.
	"hold":{"R":Basis(Vector3(0,-1,0),Vector3(0,0,-1),Vector3(1,0,0)),"L":Basis(Vector3(0,1,0),Vector3(0,0,-1),Vector3(-1,0,0))},
	# Overhand on top of the item (charging handle, slide, battery pack): palm
	# down, fingers forward and hooked over, thumb toward the body's centre.
	"top":{"R":top_frame("R"),"L":top_frame("L")},
	# Overhand on a round body along Z (a rocket being loaded): palm down on
	# top, knuckles across to the far side, fingers curl down around it, thumb
	# back along the near side.
	"over":{"R":Basis(Vector3(0,0,-1),Vector3(-1,0,0),Vector3(0,1,0)),"L":Basis(Vector3(0,0,1),Vector3(1,0,0),Vector3(0,1,0))},
	# Hanging at the side: fingers down, palm toward the body, thumb forward.
	"rest":{"R":Basis(Vector3(0,0,1),Vector3(0,-1,0),Vector3(1,0,0)),"L":Basis(Vector3(0,0,-1),Vector3(0,-1,0),Vector3(-1,0,0))}}
# Handle position inside the wrist frame for shapeless styles (metres at hand scale 1).
const PALM={"pistol":Vector3(0,.085,-.025),"over":Vector3(0,.09,-.03),"support":Vector3(0,.09,-.03),"knife":Vector3(0,.08,-.025),"hold":Vector3(0,.095,-.04),"top":Vector3(0,.09,-.03),"rest":Vector3(0,.09,-.03)}
# Relaxed finger curl for the shapeless "rest" hand.
const CURLS={"rest":{"index":.35,"fingers":[.4,.35,.2],"thumb":.2}}
# Hand geometry of the Quaternius rig in bone units (tools/probe_hand_mesh.gd):
# palm skin below the metacarpals, finger radius per joint, fingertip length.
const PALM_SKIN=.026
const FINGER_RADIUS=[0.,0.,.0125,.0115,.0095]
const TIP={"Index":.028,"Middle":.031,"Ring":.03,"Pinky":.024,"Thumb":.033}
# Default grip shapes (handle frame, metres at item scale 1): half extents and rounding.
const SHAPES={"pistol":{"half":Vector3(.016,.05,.03),"round":.013},"support":{"half":Vector3(.024,.024,.06),"round":.02},
	"knife":{"half":Vector3(.013,.013,.05),"round":.012},"hold":{"half":Vector3(.032,.032,.032),"round":.032},
	"top":{"half":Vector3(.018,.012,.02),"round":.01},"over":{"half":Vector3(.024,.024,.06),"round":.024}}
static func shaped(style:String) -> bool:return SHAPES.has(style)
# Shape of a handle in world metres, trigger in the handle frame (or null).
static func world_shape(handle:Transform3D,style:String,shape:Dictionary) -> Dictionary:
	var base:Dictionary=SHAPES.get(style,SHAPES.pistol)
	var scale=absf(handle.basis.get_scale().y)
	var half:Vector3=shape.get("half",base.half)*scale
	var out={"half":half,"round":minf(float(shape.get("round",base.round))*scale,minf(half.x,minf(half.y,half.z)))}
	if shape.has("trigger"):out.trigger=shape.trigger*scale
	return out
# Knuckle (proximal finger joint) positions in the wrist frame, per hero rig.
static var knuckle_cache={}
static func knuckles(hero:HeroCharacter,side:String) -> Dictionary:
	var key=str([hero.role,side])
	if knuckle_cache.has(key):return knuckle_cache[key]
	var out={};var chains=finger_chains(hero,side)
	for finger in chains:
		var bones:Array=chains[finger]
		if bones.size()<2:continue
		var rest1:Transform3D=hero.skeleton.get_bone_rest(bones[0])
		out[finger]=Transform3D(Basis(rest1.basis.get_rotation_quaternion()),rest1.origin)*hero.skeleton.get_bone_rest(bones[1]).origin
	knuckle_cache[key]=out;return out
# Wrist placement (in the handle frame, world metres) that lays the palm on
# the grip shape with the knuckles at its far edge. On a gun grip the knuckle
# line is shifted so the index finger lines up with the trigger.
static func wrist_offset(hero:HeroCharacter,side:String,style:String,shape:Dictionary,hand_scale:float) -> Vector3:
	var frame:Basis=FRAMES.get(style,FRAMES.pistol)[side]
	var normal:Vector3=-frame.z;var along:Vector3=frame.y;var across:Vector3=frame.x
	var half:Vector3=shape.half
	var extent_n=absf(normal.x)*half.x+absf(normal.y)*half.y+absf(normal.z)*half.z
	var extent_d=absf(along.x)*half.x+absf(along.y)*half.y+absf(along.z)*half.z
	var k:Dictionary=knuckles(hero,side)
	var middle:Vector3=k.get("Middle",Vector3(0,.152,0))
	var lateral=0.
	if shape.has("trigger"):
		# Index finger in line with the trigger (a finger radius below the frame),
		# but never above the top of the grip: on raked grips with a high trigger
		# the hand stays on the grip and the index finger reaches up instead.
		lateral=across.dot(shape.trigger)-k.get("Index",Vector3(-.023,.15,0)).x*hand_scale
		var top=-(absf(across.x)*half.x+absf(across.y)*half.y+absf(across.z)*half.z)*.8
		lateral=maxf(lateral,top-k.get("Index",Vector3(-.023,.15,0)).x*hand_scale)
	else:
		# Fingers centred on the handle.
		var sum=0.;var n=0
		for f in ["Index","Middle","Ring","Pinky"]:
			if k.has(f):sum+=k[f].x;n+=1
		lateral=-(sum/maxf(1.,n))*hand_scale
	var reach=extent_d-(middle.y-.004)*hand_scale
	return -normal*(extent_n+PALM_SKIN*hand_scale)+along*reach+across*lateral
# With a grip field (the model's real surface, GripField) the palm is then
# moved along its normal until it lies on the surface: out of the model where
# the box was too small, in to the surface where it was too big.
const PALM_PULL=.02
static var offset_cache={}
static var debug_contact=false
static func grip_offset(hero:HeroCharacter,side:String,style:String,ws:Dictionary,hand_scale:float,contact:Dictionary) -> Vector3:
	if contact.is_empty():return wrist_offset(hero,side,style,ws,hand_scale)
	var tg:Transform3D=contact.to_gun
	var key=str([hero.role,side,style,ws.half.snapped(Vector3.ONE*.001),ws.get("trigger",Vector3.ZERO).snapped(Vector3.ONE*.001),contact.field.id,tg.origin.snapped(Vector3.ONE*.002),tg.basis.x.snapped(Vector3.ONE*.01),tg.basis.y.snapped(Vector3.ONE*.01),snappedf(float(contact.k),.001),snappedf(hand_scale,.001),Vector3(contact.get("box",{}).get("half",Vector3.ZERO)).snapped(Vector3.ONE*.001)])
	if offset_cache.has(key):return offset_cache[key]
	if offset_cache.size()>512:offset_cache.clear()
	# The real handle: its measured width and depth (or height) replace the box
	# and the hand centres on it.
	var shape=ws;var centre=Vector3.ZERO
	var fit=GripField.measure(contact,style,ws.half.y if style=="pistol" else ws.half.z)
	if not fit.is_empty():
		shape=ws.duplicate();var h:Vector3=ws.half;h.x=fit.half_x
		if style=="pistol":h.z=fit.half_s
		else:h.y=fit.half_s
		shape.half=h;shape.round=minf(float(ws.round),minf(h.x,minf(h.y,h.z)));centre=fit.centre
	var offset=placed_on_surface(hero,side,style,wrist_offset(hero,side,style,shape,hand_scale)+centre,hand_scale,contact)
	offset_cache[key]=offset
	return offset
static func placed_on_surface(hero:HeroCharacter,side:String,style:String,offset:Vector3,hand_scale:float,contact:Dictionary) -> Vector3:
	var frame:Basis=FRAMES.get(style,FRAMES.pistol)[side];var normal:Vector3=-frame.z
	var k_hand:Dictionary=knuckles(hero,side)
	# Palm surface points (hand space, bone units): under the knuckles and mid palm.
	var points=[]
	for f in ["Index","Middle","Ring","Pinky"]:
		if k_hand.has(f):points.append(Vector3(k_hand[f].x,k_hand[f].y*.9,k_hand[f].z-PALM_SKIN))
	if k_hand.has("Middle"):points.append(Vector3(k_hand.Middle.x,k_hand.Middle.y*.5,k_hand.Middle.z-PALM_SKIN))
	var moved=0.;var far=GripField.FAR*float(contact.k)*.99
	for i in range(3):
		var gap=INF
		for p in points:gap=minf(gap,GripField.distance(contact,frame*(p*hand_scale)+offset))
		if debug_contact:print("PALM ",contact.field.id," ",side," ",style," iter ",i," gap ",snappedf(gap,.0001)," moved ",snappedf(moved,.0001))
		if gap>=far:break
		var step=clampf(gap,-.08,PALM_PULL-moved)
		if absf(step)<.0005:break
		offset+=normal*step;moved+=step
	# Support hands: knuckles past the handguard's far edge (fingers can only
	# wrap from there), sliding along the knuckle direction until the finger
	# bases are clear. (A firing hand stays on its grip.)
	if style!="support":return offset
	var along:Vector3=frame.y;var slid=0.
	var bases=[]
	for f in ["Index","Middle","Ring","Pinky"]:
		if k_hand.has(f):bases.append(k_hand[f])
	for i in range(4):
		var worst=INF
		for p in bases:worst=minf(worst,GripField.distance(contact,frame*(p*hand_scale)+offset)-FINGER_RADIUS[2]*hand_scale)
		if worst>=0. or worst>=far or slid>=.03:break
		var step=minf(-worst+.001,.03-slid)
		offset+=along*step;slid+=step
	return offset
# World wrist transform for a handle. Shaped styles use the grip shape;
# shapeless ones keep the fixed palm offset.
static func wrist_target(handle:Transform3D,side:String,style:String,hand_scale:float,hero:HeroCharacter=null,shape:Dictionary={},contact:Dictionary={}) -> Transform3D:
	var frame:Basis=FRAMES.get(style,FRAMES.pistol)[side]
	var hb:Basis=handle.basis.orthonormalized()
	var basis:Basis=hb*frame
	if hero==null or not shaped(style):
		return Transform3D(basis,handle.origin-basis*(PALM.get(style,PALM.pistol)*hand_scale))
	var ws=world_shape(handle,style,shape)
	return Transform3D(basis,handle.origin+hb*grip_offset(hero,side,style,ws,hand_scale,contact))
static func solve_arm(hero:HeroCharacter,side:String,target:Transform3D,weight:float,wrist_basis:bool=false):
	var sk=hero.skeleton
	var upper=hero.bone["UpperArm."+side];var lower=hero.bone["LowerArm."+side];var wrist=hero.bone["Wrist."+side]
	var shoulder=hero.bone["Shoulder."+side]
	var wu=hero.bone_world(upper);var wl=hero.bone_world(lower);var ww=hero.bone_world(wrist)
	var a:Vector3=wu.origin;var b:Vector3=wl.origin;var c:Vector3=ww.origin
	var la=a.distance_to(b);var lb=b.distance_to(c)
	var t:Vector3=target.origin
	var fp=hero.first_person
	var fp_elbow=Vector3.INF
	if fp and wrist_basis:
		# View-model forearm: choose the elbow, then slide the (hidden) shoulder
		# so the upper arm keeps its length and ends there.
		fp_elbow=t+fp_forearm(hero,side,target.basis.y,t,lb)*lb
		var moved=fp_elbow+fp_upper(hero,side,fp_elbow,a,la)*la
		var parent=hero.bone_world(sk.get_bone_parent(shoulder))
		sk.set_bone_pose_position(shoulder,sk.get_bone_pose_position(shoulder)+parent.basis.inverse()*(moved-a))
		wu=hero.bone_world(upper);wl=hero.bone_world(lower);ww=hero.bone_world(wrist)
		a=wu.origin;b=wl.origin;c=ww.origin
	var d=clampf(a.distance_to(t),absf(la-lb)+.01,(la+lb)*.999)
	var dir=(t-a).normalized()
	var pole:Vector3=a+hero.facing_basis()*(POLE_FP if fp else POLE)[side]
	var perp=((pole-a)-dir*(pole-a).dot(dir))
	if perp.length_squared()<.000001:perp=hero.facing_basis()*Vector3.DOWN
	perp=perp.normalized()
	var cos_a=clampf((la*la+d*d-lb*lb)/(2.*la*d),-1.,1.)
	var centre=a+dir*la*cos_a;var radius=la*sqrt(1.-cos_a*cos_a)
	# The elbow may sit anywhere on its circle. People keep the wrist fairly
	# straight: pick the elbow whose forearm best continues the hand, staying
	# near the natural (down and out) elbow and never above the shoulder.
	if fp_elbow!=Vector3.INF:
		var off=(fp_elbow-a)-dir*(fp_elbow-a).dot(dir)
		if off.length_squared()>.0000001:perp=off.normalized()
	elif wrist_basis and radius>.001:
		var hand_dir:Vector3=target.basis.y.normalized()
		var up:Vector3=hero.facing_basis().y.normalized()
		var side_axis=dir.cross(perp).normalized()
		# First person: the elbows hang (only forearms rise into view). Third
		# person: the upper arm and forearm stay outside the torso.
		var align_w=.5 if fp else 1.;var pole_w=1.2 if fp else .45
		var torso=torso_frame(hero) if not fp else {}
		var w_end=a+dir*d
		# 12 samples round the circle, then three halving refinements (18
		# evaluations; 1.4.1 used 32 through a lambda, the costliest part of a pose).
		var best_angle=0.;var best_cost=INF
		var candidates=PackedFloat32Array()
		for k in range(ELBOW_SAMPLES):candidates.append(k*TAU/ELBOW_SAMPLES)
		var step=TAU/(ELBOW_SAMPLES*2.)
		for level in range(4):
			for angle in candidates:
				var e=centre+(perp*cos(angle)+side_axis*sin(angle))*radius
				var cost=align_w*(w_end-e).normalized().angle_to(hand_dir)+pole_w*absf(wrapf(angle,-PI,PI))+maxf(0.,(e-a).dot(up)/la-.15)*4.
				if not torso.is_empty():
					cost+=TORSO_W*(torso_depth(torso,e)+torso_depth(torso,(a+e)*.5)+torso_depth(torso,(e+w_end)*.5)+torso_depth(torso,e.lerp(w_end,.25)))
				if cost<best_cost:best_cost=cost;best_angle=angle
			if level==3:break
			candidates=PackedFloat32Array([best_angle-step,best_angle+step]);step*=.5
		var chosen=perp*cos(best_angle)+side_axis*sin(best_angle)
		# Ease the elbow between frames (no popping between circle samples).
		# Remembered in the hero's own frame so turning the body does not lag.
		var key="elbow_"+side;var facing=hero.facing_basis()
		if hero.frame_dt>0. and hero.has_meta(key):
			var previous:Vector3=facing*Vector3(hero.get_meta(key))
			if previous.length_squared()>.5:
				var blended=previous.normalized().slerp(chosen,1.-exp(-hero.frame_dt*14.))
				blended=blended-dir*blended.dot(dir)
				if blended.length_squared()>.000001:chosen=blended.normalized()
		hero.set_meta(key,facing.inverse()*chosen)
		perp=chosen
	var elbow=centre+perp*radius
	var q1=Quaternion((b-a).normalized(),(elbow-a).normalized())
	var upper_world=(q1*wu.basis.get_rotation_quaternion()).normalized()
	var c1=elbow+q1*(c-b)
	var q2=Quaternion((c1-elbow).normalized(),(a+dir*d-elbow).normalized())
	var lower_world=(q2*q1*wl.basis.get_rotation_quaternion()).normalized()
	var wrist_world:Quaternion
	if wrist_basis:wrist_world=target.basis.get_rotation_quaternion()
	else:
		# Legacy markers: identity basis means the aim clip's own wrist orientation.
		var cal:Dictionary=calibrate(hero)
		var facing=hero.facing_basis().get_rotation_quaternion()
		var grip=target.basis.get_rotation_quaternion()*facing.inverse()
		wrist_world=(grip*facing*cal[side]).normalized()
	# The forearm rolls about its own axis (+Y) to take the twist; the wrist
	# keeps only a limited bend.
	var local=(lower_world.inverse()*wrist_world).normalized()
	if local.w<0.:local=-local
	var twist=Quaternion(0.,local.y,0.,local.w)
	if twist.length_squared()<.0000001:twist=Quaternion.IDENTITY
	else:
		twist=twist.normalized()
		var angle=wrapf(2.*atan2(twist.y,twist.w),-PI,PI)
		twist=Quaternion(Vector3.UP,clampf(angle,-TWIST_LIMIT,TWIST_LIMIT))
	var swing=(twist.inverse()*local).normalized()
	# q and -q are the same rotation: measure the short way round.
	if swing.w<0.:swing=-swing
	var bend=swing.get_angle()
	if bend>WRIST_LIMIT:swing=Quaternion.IDENTITY.slerp(swing,WRIST_LIMIT/bend)
	lower_world=(lower_world*twist).normalized()
	wrist_world=(lower_world*swing).normalized()
	var parent_world=hero.bone_world(shoulder).basis.get_rotation_quaternion()
	set_world(sk,upper,parent_world,upper_world,weight)
	set_world(sk,lower,upper_world,lower_world,weight)
	set_world(sk,wrist,lower_world,wrist_world,weight)
	if hero.has_meta("ik_debug"):
		print("IKDBG ",side," want ",target.basis.get_rotation_quaternion()," solved ",wrist_world," got ",hero.bone_world(wrist).basis.get_rotation_quaternion()," bend ",bend," twist ",twist.get_angle()," parent_err ",hero.bone_world(shoulder).basis.get_rotation_quaternion().angle_to(parent_world))
# Torso as an elliptic cylinder between the abdomen and the chest (world),
# built once per pose (both arms share it).
static func torso_frame(hero:HeroCharacter) -> Dictionary:
	if hero.torso_serial==hero.drive_serial and not hero.torso_cache.is_empty():return hero.torso_cache
	var sk=hero.skeleton
	var ab=sk.find_bone("Abdomen");var ch=sk.find_bone("Chest")
	if ab<0 or ch<0:return {}
	var low:Vector3=hero.bone_world(ab).origin;var high:Vector3=hero.bone_world(ch).origin
	var f:Basis=hero.facing_basis().orthonormalized()
	var s=low.distance_to(high)/.354 # rig: abdomen to chest 0.354 m at scale 1
	var axis=high-low
	hero.torso_cache={"low":low,"axis":axis.normalized(),"length":axis.length(),"x":f.x/(.115*s),"z":f.z/(.10*s),"top":.12*s}
	hero.torso_serial=hero.drive_serial
	return hero.torso_cache
# 0 outside, up to 1 at the torso axis.
static func torso_depth(t:Dictionary,p:Vector3) -> float:
	var rel:Vector3=p-t.low;var h=rel.dot(t.axis)
	if h<0. or h>float(t.length)+float(t.top):return 0.
	var q:Vector3=rel-t.axis*h
	var qx=q.dot(t.x);var qz=q.dot(t.z)
	var r2=qx*qx+qz*qz
	return 0. if r2>=1. else 1.-sqrt(r2)
static func set_world(sk:Skeleton3D,index:int,parent_world:Quaternion,world:Quaternion,weight:float):
	var local=(parent_world.inverse()*world).normalized()
	sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index).slerp(local,weight))
# --- Fingers -------------------------------------------------------------------
# Each finger is a chain Finger1 (metacarpal) .. Finger4 (tip) with +Y along the
# bone; flexion is a rotation about the bone's -X from its rest pose (measured
# on the Quaternius rig, tools/probe_curl.gd). The thumb has three bones.
static var finger_bones={}
static func fingers_of(hero:HeroCharacter,side:String) -> Array:
	var key=str([hero.role,side])
	if finger_bones.has(key):return finger_bones[key]
	var out=[]
	for i in range(hero.skeleton.get_bone_count()):
		var n=hero.skeleton.get_bone_name(i)
		if not n.ends_with("."+side):continue
		for finger in ["Index","Middle","Ring","Pinky","Thumb"]:
			if n.begins_with(finger):out.append([i,finger,int(n.substr(finger.length(),1))]);break
	finger_bones[key]=out;return out
static var chain_cache={}
static func finger_chains(hero:HeroCharacter,side:String) -> Dictionary:
	var key=str([hero.role,side])
	if chain_cache.has(key):return chain_cache[key]
	var out={}
	for entry in fingers_of(hero,side):
		if not out.has(entry[1]):out[entry[1]]=[]
		out[entry[1]].append(entry)
	for finger in out:
		out[finger].sort_custom(func(x,y):return x[2]<y[2])
		out[finger]=out[finger].map(func(x):return x[0])
	chain_cache[key]=out;return out
# Rounded-box distance (handle frame).
static func box_distance(p:Vector3,half:Vector3,rounding:float) -> float:
	var q=p.abs()-(half-Vector3.ONE*rounding)
	return Vector3(maxf(q.x,0.),maxf(q.y,0.),maxf(q.z,0.)).length()+minf(maxf(q.x,maxf(q.y,q.z)),0.)-rounding
static func flexed(sk:Skeleton3D,bone:int,amount:float) -> Transform3D:
	var rest:Transform3D=sk.get_bone_rest(bone)
	return Transform3D(Basis(rest.basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-amount)),rest.origin)
# Joint frames of one finger for the given flexion angles (hand space).
static func finger_frames(sk:Skeleton3D,bones:Array,angles:Array) -> Array:
	var frames=[];var t=Transform3D.IDENTITY
	for i in range(bones.size()):
		t=t*flexed(sk,bones[i],angles[i]);frames.append(t)
	return frames
static func segment_end(sk:Skeleton3D,bones:Array,frames:Array,i:int,tip:float) -> Vector3:
	return frames[i]*(sk.get_bone_rest(bones[i+1]).origin if i+1<bones.size() else Vector3(0,tip,0))
# Solved finger rotations, cached per rig, style and grip geometry (hand units).
static var grip_cache={}
const MAX_FLEX=[.4,.4,1.65,1.8,1.35]
# Least flexion of the firing hand's middle finger per joint (see grip_pose).
const MIDDLE_TUCK=[0.,1.0,1.1,.8]
const THUMB_BASE={"pistol":.2,"support":.1,"knife":.25,"hold":.2,"top":.1,"over":.15}
## `contact` (GripField.contact) / `hand_scale`: fingers wrap the model's real
## surface instead of the grip box.
static func grip_pose(hero:HeroCharacter,side:String,style:String,offset:Vector3,shape:Dictionary,pointing:bool,contact:Dictionary={},hand_scale:float=1.) -> Dictionary:
	var trigger=shape.get("trigger",null)
	var where=""
	if not contact.is_empty():
		var tg:Transform3D=contact.to_gun
		where=str([contact.field.id,tg.origin.snapped(Vector3.ONE*.002),tg.basis.x.snapped(Vector3.ONE*.01),tg.basis.y.snapped(Vector3.ONE*.01),snappedf(float(contact.k)/hand_scale,.001),Vector3(contact.get("box",{}).get("half",Vector3.ZERO)).snapped(Vector3.ONE*.001)])
	var key=str([hero.role,side,style,offset.snapped(Vector3.ONE*.002),shape.half.snapped(Vector3.ONE*.002),snappedf(shape.round,.002),trigger.snapped(Vector3.ONE*.002) if trigger!=null else null,pointing,where])
	if grip_cache.has(key):return grip_cache[key]
	if grip_cache.size()>512:grip_cache.clear()
	var sk=hero.skeleton
	# Hand space (bone units) -> handle space (hand units).
	var to_handle=Transform3D(FRAMES.get(style,FRAMES.pistol)[side],offset)
	var half:Vector3=shape.half;var rounding=float(shape.round)
	var dist=func(p:Vector3) -> float:return box_distance(to_handle*p,half,rounding)
	var box_dist=dist
	if not contact.is_empty():
		dist=func(p:Vector3) -> float:return GripField.distance(contact,(to_handle*p)*hand_scale)/hand_scale
	var out={}
	var chains=finger_chains(hero,side)
	for finger in chains:
		var bones:Array=chains[finger]
		var angles=[]
		for i in range(bones.size()):angles.append(0.)
		var tip=float(TIP.get(finger,.03))
		if finger=="Thumb":
			angles[0]=float(THUMB_BASE.get(style,.15))
			for i in range(1,bones.size()):angles[i]=wrap_joint(sk,bones,angles,i,tip,dist,.013,0.,1.2,.9)
			# On the real surface the thumb may run into the receiver / tube above
			# the grip: swing it further across (round the handle) until it lies
			# clear, keeping the least swing that works.
			if not contact.is_empty() and chain_clearance(sk,bones,angles,tip,dist)<-.004:
				var best=angles.duplicate();var best_clear=chain_clearance(sk,bones,angles,tip,dist)
				for extra in [.25,.5,.75,1.,-.25]:
					var trial=angles.duplicate();trial[0]=float(THUMB_BASE.get(style,.15))+extra
					for i in range(1,bones.size()):trial[i]=wrap_joint(sk,bones,trial,i,tip,dist,.013,0.,1.2,.9)
					var clear=chain_clearance(sk,bones,trial,tip,dist)
					if clear>best_clear+.001:best=trial;best_clear=clear
					if clear>=-.002:break
				angles=best
		else:
			angles[0]={"Index":.05,"Middle":.06,"Ring":.1,"Pinky":.15}.get(finger,.06)
			if finger=="Index" and pointing:
				for i in range(1,bones.size()):angles[i]=0.
			elif finger=="Index" and trigger!=null:
				# The trigger sits inside a thin guard that the grip field (6.5 mm
				# cells) cannot resolve: the index finger keeps the grip box.
				angles=trigger_finger(sk,bones,angles,tip,box_dist,to_handle.affine_inverse()*trigger)
			else:
				for i in range(1,bones.size()):
					angles[i]=wrap_joint(sk,bones,angles,i,tip,dist,FINGER_RADIUS[mini(i+1,4)],0.,MAX_FLEX[mini(i+1,4)],MAX_FLEX[mini(i+1,4)])
				# 1.4.2: on the firing hand the middle finger touched the trigger
				# guard while still straight and stayed out along it; it now tucks
				# under the guard and closes round the front of the grip.
				if finger=="Middle" and trigger!=null:
					var wrapped=angles.duplicate()
					angles[0]=maxf(float(angles[0]),.12)
					for i in range(1,bones.size()):angles[i]=maxf(float(angles[i]),float(MIDDLE_TUCK[mini(i,MIDDLE_TUCK.size()-1)]))
					# ...but never into the grip: ease the tip joints back until the
					# finger lies on the surface (a touch, as the other fingers).
					for step in range(12):
						if chain_clearance(sk,bones,angles,tip,dist)>=-.003:break
						for i in range(bones.size()-1,0,-1):angles[i]=maxf(float(wrapped[i]),float(angles[i])-.06)
		if debug_contact and not contact.is_empty():
			var frames=finger_frames(sk,bones,angles);var ends=[]
			for i in range(bones.size()):ends.append(snappedf(dist.call(segment_end(sk,bones,frames,i,tip)),.0001))
			print("FINGER ",contact.field.id," ",side," ",style," ",finger," angles ",angles.map(func(x):return snappedf(x,.01))," end_dist ",ends)
		for i in range(bones.size()):
			var rest:Quaternion=sk.get_bone_rest(bones[i]).basis.get_rotation_quaternion()
			out[bones[i]]=(rest*Quaternion(Vector3.RIGHT,-float(angles[i]))).normalized()
		if finger=="Index" and pointing:
			for i in range(1,bones.size()):out[bones[i]]=straight(hero,bones[i])
	grip_cache[key]=out
	return out
# Least clearance (distance minus finger radius, hand units) along a finger.
static func chain_clearance(sk:Skeleton3D,bones:Array,angles:Array,tip:float,dist:Callable) -> float:
	var frames=finger_frames(sk,bones,angles);var worst=INF
	for i in range(bones.size()):
		var start:Vector3=frames[i].origin;var end=segment_end(sk,bones,frames,i,tip)
		var r=FINGER_RADIUS[mini(i+1,4)] if i>0 else .01
		worst=minf(worst,minf(dist.call(end),dist.call((start+end)*.5))-r)
	return worst
# Bends joint i until its segment touches the shape (distance <= radius).
# No contact within the range: `fallback` (a closed fist).
static func wrap_joint(sk:Skeleton3D,bones:Array,angles:Array,i:int,tip:float,dist:Callable,radius:float,lo:float,hi:float,fallback:float) -> float:
	var touching=func(a:float) -> bool:
		angles[i]=a
		var frames=finger_frames(sk,bones,angles)
		var start:Vector3=frames[i].origin;var end=segment_end(sk,bones,frames,i,tip)
		return dist.call(end)<=radius or dist.call((start+end)*.5)<=radius
	var previous=lo
	if touching.call(lo):
		# Already in contact straight (a real, larger surface than the box):
		# take the bend with the most clearance and stop there, rather than
		# bending on through the part to its far side.
		var best=lo;var best_clear=-INF;var a0=lo
		while a0<=hi+.0001:
			angles[i]=a0
			var frames=finger_frames(sk,bones,angles)
			var start:Vector3=frames[i].origin;var end=segment_end(sk,bones,frames,i,tip)
			var clear=minf(dist.call(end),dist.call((start+end)*.5))-radius
			if clear>best_clear+.0005:best_clear=clear;best=a0
			a0+=.06
		angles[i]=best;return best
	var a=lo
	while a<hi:
		a=minf(hi,a+.06)
		if touching.call(a):
			var inside=a;var outside=previous
			for k in range(6):
				var mid=(inside+outside)*.5
				if touching.call(mid):inside=mid
				else:outside=mid
			angles[i]=outside;return outside
		previous=a
	angles[i]=minf(hi,fallback);return angles[i]
# Index finger on a trigger: pick the joint angles whose finger pad comes
# closest to the trigger point without the finger sinking into the grip.
static func trigger_finger(sk:Skeleton3D,bones:Array,angles:Array,tip:float,dist:Callable,trigger:Vector3) -> Array:
	var n=bones.size()
	if n<4:return angles.duplicate()
	var cost_of=func(trial:Array) -> float:
		var frames=finger_frames(sk,bones,trial)
		var cost=0.
		for i in range(1,n):
			var d=dist.call(segment_end(sk,bones,frames,i,tip))-FINGER_RADIUS[mini(i+1,4)]
			if d<0.:cost+=-d*40.
		var pad:Vector3=frames[n-1]*Vector3(0,tip*.6,-FINGER_RADIUS[4]*.8)
		return cost+pad.distance_to(trigger)+float(trial[3])*.004
	# Coarse grid over the three joints, then a finer one around the best.
	var best=angles.duplicate();var best_cost=INF
	for a2 in range(0,8):
		for a3 in range(0,9):
			for a4 in range(0,5):
				var trial=[angles[0],a2*.2,a3*.2,a4*.3]
				var cost=cost_of.call(trial)
				if cost<best_cost:best_cost=cost;best=trial
	var centre=best.duplicate()
	for d2 in range(-4,5):
		for d3 in range(-4,5):
			for d4 in range(-2,3):
				var trial=[angles[0],maxf(0.,centre[1]+d2*.05),maxf(0.,centre[2]+d3*.05),maxf(0.,centre[3]+d4*.1)]
				var cost=cost_of.call(trial)
				if cost<best_cost:best_cost=cost;best=trial
	return best
# Applies a grip's finger pose (weight blends from the animated pose). A small
# per-hero memory smooths changes between grips.
static func apply_grip(hero:HeroCharacter,side:String,handle:Transform3D,style:String,shape:Dictionary,weight:float,pointing:bool=false,contact:Dictionary={}):
	if not shaped(style):curl(hero,side,weight,style,pointing);return
	var hand_scale=hero.hand_scale()
	var ws=world_shape(handle,style,shape)
	var offset=grip_offset(hero,side,style,ws,hand_scale,contact)
	var hand={"half":ws.half/hand_scale,"round":float(ws.round)/hand_scale}
	if ws.has("trigger") and not pointing:hand.trigger=ws.trigger/hand_scale
	var pose=grip_pose(hero,side,style,offset/hand_scale,hand,pointing,contact,hand_scale)
	var sk=hero.skeleton;var blend=1.-exp(-hero.frame_dt*24.) if hero.frame_dt>0. else 1.
	for b in pose:
		var target:Quaternion=pose[b]
		if hero.finger_memory.has(b) and blend<1.:target=Quaternion(hero.finger_memory[b]).slerp(target,blend)
		hero.finger_memory[b]=target
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).slerp(target,weight))
# Fixed curl (the shapeless "rest" hand). `pointing` keeps the index finger straight.
static func curl(hero:HeroCharacter,side:String,weight:float,style:String="rest",pointing:bool=false):
	var c:Dictionary=CURLS.get(style,CURLS.rest)
	var sk=hero.skeleton
	for entry in fingers_of(hero,side):
		var b:int=entry[0];var finger:String=entry[1];var joint:int=entry[2]
		var amount:float
		if finger=="Thumb":amount=[0.,.35,.6,.7][mini(joint,3)]*float(c.thumb)
		elif joint<=1:amount=.06
		else:amount=float(c.fingers[joint-2])*(float(c.index) if finger=="Index" else 1.)
		var target:Quaternion=sk.get_bone_rest(b).basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-amount)
		if pointing and finger=="Index":target=straight(hero,b)
		hero.finger_memory.erase(b)
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).slerp(target,weight))
# Local rotation of a bone in the skin bind (T) pose: a straight finger.
static var straight_cache={}
static func straight(hero:HeroCharacter,bone:int) -> Quaternion:
	var key=str([hero.role,bone])
	if not straight_cache.has(key):
		var skin:Skin
		for m in hero.meshes():
			if m.skin:skin=m.skin;break
		var binds={}
		for i in range(skin.get_bind_count()):binds[skin.get_bind_bone(i) if skin.get_bind_name(i)=="" else hero.skeleton.find_bone(skin.get_bind_name(i))]=skin.get_bind_pose(i).affine_inverse()
		var parent=hero.skeleton.get_bone_parent(bone)
		straight_cache[key]=(binds[parent].basis.get_rotation_quaternion().inverse()*binds[bone].basis.get_rotation_quaternion()).normalized() if binds.has(parent) and binds.has(bone) else hero.skeleton.get_bone_pose_rotation(bone)
	return straight_cache[key]
