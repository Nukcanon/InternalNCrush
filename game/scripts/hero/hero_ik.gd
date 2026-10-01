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
const POLE_FP={"R":Vector3(.45,-1.,.1),"L":Vector3(-.45,-1.,.1)} # first person: elbows hang below and out
# First person (1.4.4) is a view model, not the third-person body: as in
# shooters' first-person arm rigs, each arm hangs from a fixed shoulder well
# below the view (Actor.FP_ARMS, camera space, meta "fp_shoulders") and its
# forearm rises into the frame from the lower corner on its side (meta
# "fp_forearm": the direction from the wrist toward the elbow, camera space).
# The elbow on the IK circle nearest that forearm line is taken, so the elbow
# and upper arm stay below the frame. The forearm keeps its length; a hand
# beyond reach pulls its (hidden) shoulder toward it (meta "fp_stretch_<side>").
const FP_REACH=.985
const FP_ELBOW_W=3. # cost per metre of elbow distance from the forearm line's end
# Forearm twist beyond this (rad) costs in the elbow search: the forearm mesh
# twists like a wrapper when its bone rolls far about its own axis.
const TWIST_FREE=.6
const TWIST_W=1.4
static func fp_anchor(hero:HeroCharacter,side:String) -> Vector3:
	var cam=hero.get_meta("fp_camera",null)
	var anchors=hero.get_meta("fp_shoulders",{})
	if not (cam is Camera3D and is_instance_valid(cam)) or not anchors.has(side):return Vector3.INF
	# The view model's own (scaled) space when there is one (Actor.view_space).
	if hero.has_meta("fp_space"):
		var space=hero.get_meta("fp_space")
		if space is Node3D and is_instance_valid(space):return space.global_transform*Vector3(anchors[side])
	return cam.global_transform*Vector3(anchors[side])
static func on_screen(cam:Camera3D,p:Vector3) -> bool:
	var local:Vector3=cam.global_transform.affine_inverse()*p
	if local.z>-.02:return false
	var size:Vector2=cam.get_viewport().get_visible_rect().size
	var t=tan(deg_to_rad(cam.fov)*.5)*1.04
	return absf(local.y)<-local.z*t and absf(local.x)<-local.z*t*size.x/maxf(1.,size.y)
# Human limits: wrist bend (flexion / deviation) and forearm twist.
const WRIST_LIMIT=1.25
const TWIST_LIMIT=1.3
static var calibration={}
static func rot(hero:HeroCharacter,index:int) -> Quaternion:return hero.bone_world(index).basis.get_rotation_quaternion()
# Rotation taking unit vector `from` to `to`. Quaternion(from,to) is numerically
# poor for nearly opposite vectors (a pose flipping between frames gave an
# unnormalized quaternion and engine errors downstream): those turn PI about
# a perpendicular axis instead.
static func arc(from:Vector3,to:Vector3) -> Quaternion:
	var d=from.dot(to)
	if d<-.9995:
		var axis=from.cross(Vector3.UP if absf(from.y)<.9 else Vector3.RIGHT).normalized()
		return Quaternion(axis,PI)
	return Quaternion(from,to).normalized()
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
const CURLS={"rest":{"index":.35,"fingers":[.4,.35,.2],"thumb":.2},
	# A closed fist round a tool handle (first-person melee).
	"fist":{"index":1.,"fingers":[1.25,1.4,1.0],"thumb":.9},
	# Cupped round a grenade, and the open hand after the throw.
	"hold":{"index":.9,"fingers":[.9,1.0,.7],"thumb":.6},
	"open":{"index":.6,"fingers":[.25,.2,.1],"thumb":.2}}
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
	if shape.get("thumb_over",false):out.thumb_over=true
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
	var offset=placed_on_surface(hero,side,style,wrist_offset(hero,side,style,shape,hand_scale)+centre,hand_scale,contact,ws.has("trigger"),Vector3(ws.get("trigger",Vector3.INF)),centre.y+float(shape.half.y) if style=="pistol" else INF)
	offset_cache[key]=offset
	return offset
static func placed_on_surface(hero:HeroCharacter,side:String,style:String,offset:Vector3,hand_scale:float,contact:Dictionary,trigger:bool=false,trigger_point:Vector3=Vector3.INF,grip_top:float=INF) -> Vector3:
	var frame:Basis=FRAMES.get(style,FRAMES.pistol)[side];var normal:Vector3=-frame.z
	var k_hand:Dictionary=knuckles(hero,side)
	# Palm surface points (hand space, bone units): under the knuckles and mid palm.
	var points=[]
	for f in ["Index","Middle","Ring","Pinky"]:
		if k_hand.has(f):points.append(Vector3(k_hand[f].x,k_hand[f].y*.9,k_hand[f].z-PALM_SKIN))
	if k_hand.has("Middle"):points.append(Vector3(k_hand.Middle.x,k_hand.Middle.y*.5,k_hand.Middle.z-PALM_SKIN))
	# 1.4.4: the thumb's base joint too (it sank into bulging parts beside the palm).
	if k_hand.has("Thumb"):points.append(Vector3(k_hand.Thumb.x,k_hand.Thumb.y,k_hand.Thumb.z)+Vector3(0,0,-THUMB_RADIUS*.5))
	# World metres per model metre: the view model is drawn larger, so every
	# metric limit below scales with it (tuned at k = 1).
	var k=float(contact.k)
	var moved=0.;var far=GripField.FAR*k*.99
	for i in range(3):
		var gap=INF
		for p in points:gap=minf(gap,GripField.distance(contact,frame*(p*hand_scale)+offset))
		if debug_contact:print("PALM ",contact.field.id," ",side," ",style," iter ",i," gap ",snappedf(gap,.0001)," moved ",snappedf(moved,.0001))
		if gap>=far:break
		var step=clampf(gap,-.08*k,PALM_PULL*k-moved)
		if absf(step)<.0005:break
		offset+=normal*step;moved+=step
	# 1.4.4 firing hand: the index finger lines up with the trigger, which put
	# the middle finger's base in the trigger guard / receiver on most guns (it
	# then poked through the far side). The hand slides down the grip until the
	# middle and ring fingers' bases and first bones, tucked under the guard,
	# are clear of the real surface; the index finger reaches up instead.
	if style=="pistol" and trigger:
		var probes=[]
		for f in ["Middle","Ring"]:
			if not k_hand.has(f):continue
			var kn:Vector3=k_hand[f]
			var phalanx=.03
			var chains:Dictionary=finger_chains(hero,side)
			if chains.has(f) and chains[f].size()>2:phalanx=hero.skeleton.get_bone_rest(chains[f][2]).origin.length()
			# Knuckle, and the first bone tucked under the guard (MIDDLE_TUCK):
			# its middle and its end (the second joint).
			probes.append(kn)
			for along in [.5,1.]:probes.append(kn+Vector3(0,cos(MIDDLE_TUCK[1])*phalanx*along,-sin(MIDDLE_TUCK[1])*phalanx*along))
		var down=Vector3(0,-1,0) # handle frame: down the grip
		# Round 4: first by geometry — the middle finger's knuckle (plus its
		# radius) must sit below the trigger guard's bar, GUARD_DROP under the
		# trigger point; short grips (DUET) had the middle finger in the guard.
		# The index finger's knuckle also stays at or below the top of the grip
		# (the web of the hand sits in the grip's top curve; the finger reaches
		# up along the frame to the trigger from there).
		if trigger_point!=Vector3.INF and k_hand.has("Middle"):
			var knuckle:Vector3=frame*(Vector3(k_hand.Middle)*hand_scale)+offset
			var need=knuckle.y+FINGER_RADIUS[1]*hand_scale-(trigger_point.y-GUARD_DROP*k)
			if grip_top<INF and k_hand.has("Index"):
				var index:Vector3=frame*(Vector3(k_hand.Index)*hand_scale)+offset
				need=maxf(need,index.y-grip_top)
			if debug_contact:print("GUARD ",contact.field.id," ",side," knuckle_y ",snappedf(knuckle.y,.001)," trigger_y ",snappedf(trigger_point.y,.001)," grip_top ",snappedf(grip_top,.001)," need ",snappedf(need,.001))
			if need>0.:offset+=down*minf(need,FIRING_SLIDE*k)
		var slid=0.
		for i in range(12):
			var worst=INF
			for p in probes:worst=minf(worst,GripField.distance(contact,frame*(p*hand_scale)+offset)-FINGER_RADIUS[2]*hand_scale)
			if worst>=.002*k or worst>=far or slid>=FIRING_PROBE_SLIDE*k:break
			var step=minf(maxf(.003*k,-worst+.001*k),FIRING_PROBE_SLIDE*k-slid)
			offset+=down*step;slid+=step
		return offset
	# 1.4.4 support fist on a magazine / vertical grip (pistol style, no
	# trigger): the lowest fingers' bases sink where a curved magazine bends
	# away; the fist slides up the grip until every knuckle is clear.
	if style=="pistol":
		var bases=[]
		for f in ["Index","Middle","Ring","Pinky"]:
			if k_hand.has(f):bases.append(k_hand[f])
		# Up along a magazine, down off a foregrip whose body sits above it:
		# whichever direction clears the knuckles with the least movement.
		var clearance=func(o:Vector3) -> float:
			var worst=INF
			for p in bases:worst=minf(worst,GripField.distance(contact,frame*(p*hand_scale)+o)-FINGER_RADIUS[2]*hand_scale)
			return worst
		var best=offset;var best_clear=clearance.call(offset)
		if best_clear<.001*k:
			for direction in [1.,-1.]:
				var o=offset;var slid=0.
				for i in range(8):
					var worst=clearance.call(o)
					if worst>best_clear:best=o;best_clear=worst
					if worst>=.001*k or worst>=far or slid>=.03*k:break
					var step=minf(maxf(.003*k,-worst+.001*k),.03*k-slid)
					o+=Vector3(0,direction,0)*step;slid+=step
				if best_clear>=.001*k:break
		return best
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
		if worst>=0. or worst>=far or slid>=.03*k:break
		var step=minf(-worst+.001*k,.03*k-slid)
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
	# 1.4.4 round 8: a gun hand's forearm continues the hand (the wrist straight,
	# as the user drew it); the hidden shoulder is then placed so that elbow is
	# reachable (meta "fp_follow": side -> elbow-to-shoulder direction, camera
	# space). With a fixed shoulder beyond reach the arm was pulled straight and
	# the forearm had to run from shoulder to wrist, bending the wrist 28-50deg.
	var follow:Dictionary=hero.get_meta("fp_follow",{}) if fp else {}
	var following=fp and wrist_basis and follow.has(side)
	var elbow_goal=Vector3.INF
	if fp:
		# First person: the arm hangs from its fixed shoulder anchor (the shoulder
		# bone is moved so the upper arm starts there), stretched toward the hand
		# only when the hand is out of reach.
		var anchor=fp_anchor(hero,side)
		if following:
			var cam=hero.get_meta("fp_camera",null)
			if cam is Camera3D and is_instance_valid(cam):
				# follow[side]: {"upper": elbow -> shoulder direction, "weight": 0..1
				# (below 1 the forearm turns part way toward the fixed line instead;
				# e.g. a revolver turned sideways to load keeps a bent wrist, or its
				# forearm would cross the view from the side)}
				# 1.4.5 "line" (world): a straight stock's wrist line, back along the
				# stock - the forearm lies along it rather than continuing the hand
				# (the hand wraps the wrist with its knuckles down).
				# (half way between the stock and the hand's own line, so the wrist
				# bends moderately rather than at a right angle)
				var f:Dictionary=follow[side];var line:Vector3=-target.basis.y.normalized()
				if f.has("line"):line=(line+Vector3(f.line).normalized()).normalized()
				# Round 9: "bend" tilts the forearm below the hand's line (the elbow
				# lower, the wrist moderately bent as the user drew it: a fully
				# straight wrist ran the forearm up through a raked grip's stock), and
				# "drop" is the least slope below the horizon the forearm then keeps.
				var bend=float(f.get("bend",0.));var down:Vector3=-cam.global_basis.y.normalized()
				var perp:Vector3=down-line*line.dot(down)
				if bend>0. and perp.length_squared()>.0001:
					perp=perp.normalized()
					var tilted:Vector3=(line*cos(bend)+perp*sin(bend)).normalized()
					var drop=float(f.get("drop",0.))
					if drop>0. and tilted.dot(down)<sin(drop):
						# Tilt further (within the same plane) until the slope is reached.
						var want=sin(drop);var lo=bend;var hi=PI*.5
						for _i in range(16):
							var mid=(lo+hi)*.5
							var trial:Vector3=(line*cos(mid)+perp*sin(mid)).normalized()
							if trial.dot(down)<want:lo=mid
							else:hi=mid
						tilted=(line*cos(hi)+perp*sin(hi)).normalized()
					line=tilted
				var lines:Dictionary=hero.get_meta("fp_forearm",{})
				if float(f.get("weight",1.))<1. and lines.has(side):
					line=line.slerp((cam.global_basis*Vector3(lines[side])).normalized(),1.-float(f.weight)).normalized()
				elbow_goal=t+line*lb
				anchor=elbow_goal+(cam.global_basis*Vector3(f.upper)).normalized()*la
		if anchor!=Vector3.INF:
			var over=anchor.distance_to(t)-(la+lb)*FP_REACH
			if over>0.:anchor+=(t-anchor).normalized()*over
			hero.set_meta("fp_stretch_"+side,maxf(0.,over))
			var parent=hero.bone_world(sk.get_bone_parent(shoulder))
			sk.set_bone_pose_position(shoulder,sk.get_bone_pose_position(shoulder)+parent.basis.inverse()*(anchor-a))
			wu=hero.bone_world(upper);wl=hero.bone_world(lower);ww=hero.bone_world(wrist)
			a=wu.origin;b=wl.origin;c=ww.origin
	var d=clampf(a.distance_to(t),absf(la-lb)+.01,(la+lb)*.999)
	var dir=(t-a).normalized()
	var pole:Vector3=a+hero.facing_basis()*(POLE_FP if fp else POLE)[side]
	# First person: where the forearm line from the wrist ends (the elbow the
	# view model wants); also the reference direction round the circle.
	if fp and elbow_goal==Vector3.INF:
		var cam=hero.get_meta("fp_camera",null);var lines:Dictionary=hero.get_meta("fp_forearm",{})
		if cam is Camera3D and is_instance_valid(cam) and lines.has(side):
			elbow_goal=t+(cam.global_basis*Vector3(lines[side])).normalized()*lb
	if elbow_goal!=Vector3.INF:pole=elbow_goal
	var perp=((pole-a)-dir*(pole-a).dot(dir))
	if perp.length_squared()<.000001:perp=hero.facing_basis()*Vector3.DOWN
	perp=perp.normalized()
	var cos_a=clampf((la*la+d*d-lb*lb)/(2.*la*d),-1.,1.)
	var centre=a+dir*la*cos_a;var radius=la*sqrt(1.-cos_a*cos_a)
	# The elbow may sit anywhere on its circle. People keep the wrist fairly
	# straight: pick the elbow whose forearm best continues the hand, staying
	# near the natural (down and out) elbow and never above the shoulder.
	if wrist_basis and radius>.001:
		var hand_dir:Vector3=target.basis.y.normalized()
		var up:Vector3=hero.facing_basis().y.normalized()
		var side_axis=dir.cross(perp).normalized()
		# First person: the elbows hang below and out (the arm is seen from the
		# shoulder). Third person: the upper arm and forearm stay outside the torso.
		var align_w=2.2 if fp else 1.;var pole_w=0. if elbow_goal!=Vector3.INF else .25 if fp else .45
		var torso=torso_frame(hero) if not fp else {}
		var w_end=a+dir*d
		var want:Quaternion=target.basis.get_rotation_quaternion()
		var from_b:Vector3=(b-a).normalized();var wl_rot:Quaternion=wl.basis.get_rotation_quaternion()
		# 12 samples round the circle, then three halving refinements (18
		# evaluations; 1.4.1 used 32 through a lambda, the costliest part of a pose).
		var best_angle=0.;var best_cost=INF
		var candidates=PackedFloat32Array()
		for k in range(ELBOW_SAMPLES):candidates.append(k*TAU/ELBOW_SAMPLES)
		var step=TAU/(ELBOW_SAMPLES*2.)
		for level in range(4):
			for angle in candidates:
				var e=centre+(perp*cos(angle)+side_axis*sin(angle))*radius
				var cost=align_w*(w_end-e).normalized().angle_to(hand_dir)+pole_w*absf(wrapf(angle,-PI,PI))+(0. if following else maxf(0.,(e-a).dot(up)/la-.15)*4.)
				# 1.4.4: the forearm roll this elbow forces (the wrist cannot twist;
				# a large roll wrings the forearm mesh).
				var cq1=arc(from_b,(e-a).normalized())
				var cq2=arc((e+cq1*(c-b)-e).normalized(),(w_end-e).normalized())
				var cl=((cq2*cq1*wl_rot).normalized().inverse()*want).normalized()
				if cl.w<0.:cl=-cl
				var roll=absf(wrapf(2.*atan2(cl.y,cl.w),-PI,PI))
				cost+=TWIST_W*maxf(0.,roll-TWIST_FREE)
				if elbow_goal!=Vector3.INF:cost+=FP_ELBOW_W*e.distance_to(elbow_goal)
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
	var q1=arc((b-a).normalized(),(elbow-a).normalized())
	var upper_world=(q1*wu.basis.get_rotation_quaternion()).normalized()
	var c1=elbow+q1*(c-b)
	var q2=arc((c1-elbow).normalized(),(a+dir*d-elbow).normalized())
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
	# 1.4.4: roll past the forearm's limit goes to the wrist joint instead of
	# being dropped, so the hand still lands on its grip.
	var excess=Quaternion.IDENTITY
	if twist.length_squared()<.0000001:twist=Quaternion.IDENTITY
	else:
		twist=twist.normalized()
		var angle=wrapf(2.*atan2(twist.y,twist.w),-PI,PI)
		var kept=clampf(angle,-TWIST_LIMIT,TWIST_LIMIT)
		twist=Quaternion(Vector3.UP,kept);excess=Quaternion(Vector3.UP,angle-kept)
	var swing=(twist.inverse()*excess.inverse()*local).normalized()
	# q and -q are the same rotation: measure the short way round.
	if swing.w<0.:swing=-swing
	var bend=swing.get_angle()
	if bend>WRIST_LIMIT:swing=Quaternion.IDENTITY.slerp(swing,WRIST_LIMIT/bend)
	lower_world=(lower_world*twist).normalized()
	wrist_world=(lower_world*excess*swing).normalized()
	if fp:hero.set_meta("fp_twist_"+side,twist.get_angle()) # review tools: forearm roll taken (rad)
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
	sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index).normalized().slerp(local,weight))
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
static func flexed(sk:Skeleton3D,bone:int,amount:float,spread:float=0.) -> Transform3D:
	var rest:Transform3D=sk.get_bone_rest(bone)
	return Transform3D(Basis(rest.basis.get_rotation_quaternion()*Quaternion(Vector3.BACK,spread)*Quaternion(Vector3.RIGHT,-amount)),rest.origin)
# 1.4.5: sideways swing of a finger at its base joint (about the bone's Z:
# positive toward the thumb), set while one finger is solved so every search
# (wrap, trigger) sees it. The firing index reaches up into the trigger
# guard; middle, ring and little fingers spread a little down the grip.
static var frame_spread=0.
const FIRING_SPREAD={"Middle":0.,"Ring":.12,"Pinky":.25} # ring and little finger closed up to the middle
const FIRING_SQUEEZE=0. # (no pressing into the grip: the user preferred fingers just touching)
const INDEX_SPREADS=[0.,.08,.16,.24,.32,.4,-.08]
# Joint frames of one finger for the given flexion angles (hand space).
static func finger_frames(sk:Skeleton3D,bones:Array,angles:Array) -> Array:
	var frames=[];var t=Transform3D.IDENTITY
	for i in range(bones.size()):
		t=t*flexed(sk,bones[i],angles[i],frame_spread if i==0 else 0.);frames.append(t)
	return frames
static func segment_end(sk:Skeleton3D,bones:Array,frames:Array,i:int,tip:float) -> Vector3:
	return frames[i]*(sk.get_bone_rest(bones[i+1]).origin if i+1<bones.size() else Vector3(0,tip,0))
# Solved finger rotations, cached per rig, style and grip geometry (hand units).
static var grip_cache={}
const MAX_FLEX=[.4,.4,1.65,1.8,1.35]
# Least flexion of the firing hand's middle finger per joint (see grip_pose).
const MIDDLE_TUCK=[0.,1.0,1.1,.8]
# Thumb contact radius (hand units): the thumb is thicker than the fingers and
# its bones lie deeper in the mesh, so it keeps a little more clearance.
const THUMB_RADIUS=.016
const WRAP_MARGIN=.0015
# How far the firing hand may slide down a grip so the middle finger clears the
# trigger guard. 1.4.4 round 4: far enough for short grips (DUET's small
# revolver): only the index finger goes in the guard; the middle, ring and
# little fingers hold the grip, even if the little finger hangs off its end.
const FIRING_SLIDE=.04
# ...and how far the surface probes (middle and ring finger bases under the
# guard) may then slide it on top of that.
const FIRING_PROBE_SLIDE=.014
# The trigger guard's bar lies about this far below the trigger point (model metres).
const GUARD_DROP=.03
# The firing hand's thumb lies raised along the side of the frame (nearly
# straight) rather than curling round the back of the grip.
const THUMB_RAISED=.15
const THUMB_RAISED_BASE=.95 # swung well forward from the base so it lies along the frame pointing ahead, never back
# A thumb holding a small round against the index finger: nearly straight,
# lying along the round beside the index (round 6: it bent over the round).
const THUMB_PINCH=[0.,.3,.65] # ...with its last joint bent forward onto the round
# Round 9: the pinching thumb lies forward along the round beside the index
# finger (base swung toward the fingers; positive flexion swings it back toward
# the wrist on this rig, so the thumb stood up and back - measured with
# tools/review_hands.gd thumbprobe: -.7 points it along -Z of the gun).
const THUMB_PINCH_BASE=-.7
# 1.4.5 round 3: the loading hand's thumb stands where it stood (the user's
# screenshots) - [base, middle] - and only its tip joint bends forward
# (THUMB_LOAD_TIP, toward the gun); the pinch above hid the whole thumb.
const THUMB_OVER=[-.3,1.2,.5]
const THUMB_LOAD=[.2,.1]
# (thumbprobe, gun space: -.6 turns the last segment from up-and-aside to
# straight ahead along the gun; positive bends it out to the side)
const THUMB_LOAD_TIP=-.8
const THUMB_BASE={"pistol":.2,"support":.1,"knife":.25,"hold":.2,"top":.1,"over":.15}
## `contact` (GripField.contact) / `hand_scale`: fingers wrap the model's real
## surface instead of the grip box.
static func grip_pose(hero:HeroCharacter,side:String,style:String,offset:Vector3,shape:Dictionary,pointing:bool,contact:Dictionary={},hand_scale:float=1.) -> Dictionary:
	var trigger=shape.get("trigger",null)
	var where=""
	if not contact.is_empty():
		var tg:Transform3D=contact.to_gun
		where=str([contact.field.id,tg.origin.snapped(Vector3.ONE*.002),tg.basis.x.snapped(Vector3.ONE*.01),tg.basis.y.snapped(Vector3.ONE*.01),snappedf(float(contact.k)/hand_scale,.001),Vector3(contact.get("box",{}).get("half",Vector3.ZERO)).snapped(Vector3.ONE*.001)])
	var key=str([hero.role,side,style,offset.snapped(Vector3.ONE*.002),shape.half.snapped(Vector3.ONE*.002),snappedf(shape.round,.002),trigger.snapped(Vector3.ONE*.002) if trigger!=null else null,pointing,where,shape.get("thumb_over",false)])
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
			# Firing hand: the thumb rests raised along the frame's side, straight
			# but for a slight bend, as a pistol or rifle is held; it only curls
			# round the grip when a straight thumb would run into the gun.
			# (1.4.5: not on a straight stock's wrist - the thumb wraps over the top)
			var raised=style=="pistol" and trigger!=null and not shape.get("thumb_over",false)
			if raised:
				angles[0]=THUMB_RAISED_BASE
				for i in range(1,bones.size()):angles[i]=THUMB_RAISED
				if chain_clearance(sk,bones,angles,tip,dist)<-.004:raised=false
			# Round 5: a small round held at the fingertips (revolver / shotgun
			# loading) is pinched — the thumb closes over it toward the index
			# finger; the wrap search found nothing to wrap and left it standing
			# up, bent back away from the palm.
			# 1.4.5: thin, whatever its length (the longer, more visible rounds of
			# 1.4.5 failed a size test on all three axes, so the thumb fell back to
			# the wrap search and stood up and back again).
			var pinch=style=="hold" and maxf(half.x,half.y)<.03
			if pinch:
				angles[0]=THUMB_LOAD[0]
				for i in range(1,bones.size()):angles[i]=THUMB_LOAD_TIP if i==bones.size()-1 else THUMB_LOAD[mini(i,THUMB_LOAD.size()-1)]
			# 1.4.5: round a straight stock's wrist the thumb lies over the top
			# (THUMB_OVER, from tools/review_hands.gd thumbsweep: the tip on the
			# top of the wrist, touching; the wrap search left it straight along
			# the right side).
			var over=shape.get("thumb_over",false) and not pinch
			if over:
				for i in range(bones.size()):angles[i]=THUMB_OVER[mini(i,THUMB_OVER.size()-1)]
			if not raised and not pinch and not over:
				for i in range(1,bones.size()):angles[i]=wrap_joint(sk,bones,angles,i,tip,dist,THUMB_RADIUS,0.,1.2,.9)
			# On the real surface the thumb may run into the receiver / tube above
			# the grip: swing it further across (round the handle) until it lies
			# clear, keeping the least swing that works.
			if not raised and not pinch and not over and not contact.is_empty() and chain_clearance(sk,bones,angles,tip,dist)<-.004:
				var best=angles.duplicate();var best_clear=chain_clearance(sk,bones,angles,tip,dist)
				for extra in [.25,.5,.75,1.,-.25]:
					var trial=angles.duplicate();trial[0]=float(THUMB_BASE.get(style,.15))+extra
					for i in range(1,bones.size()):trial[i]=wrap_joint(sk,bones,trial,i,tip,dist,THUMB_RADIUS,0.,1.2,.9)
					var clear=chain_clearance(sk,bones,trial,tip,dist)
					if clear>best_clear+.001:best=trial;best_clear=clear
					if clear>=-.002:break
				angles=best
		else:
			angles[0]={"Index":.05,"Middle":.06,"Ring":.1,"Pinky":.15}.get(finger,.06)
			frame_spread=float(FIRING_SPREAD.get(finger,0.)) if style=="pistol" and trigger!=null and not pointing else 0.
			if finger=="Index" and pointing:
				for i in range(1,bones.size()):angles[i]=0.
			elif finger=="Index" and trigger!=null:
				# The trigger sits inside a thin guard that the grip field (6.5 mm
				# cells) cannot resolve: the index finger keeps the grip box.
				# 1.4.5: its base also swings up toward the thumb as far as needed
				# (INDEX_SPREADS) so the finger goes into the guard onto the trigger.
				var best_angles=angles;var best_cost=INF;var best_spread=0.
				for s in INDEX_SPREADS:
					frame_spread=s
					var trial=trigger_finger(sk,bones,angles.duplicate(),tip,box_dist,to_handle.affine_inverse()*trigger,dist if not contact.is_empty() else Callable())
					var c=float(trigger_cost)+absf(s)*.01
					if c<best_cost:best_cost=c;best_angles=trial;best_spread=s
				angles=best_angles;frame_spread=best_spread
			else:
				# 1.4.5: on the firing hand the middle, ring and little fingers squeeze
				# the grip, a few millimetres into the model, so they hold it tight
				# (and close up together) instead of resting just off it.
				var squeeze=FIRING_SQUEEZE if style=="pistol" and trigger!=null else 0.
				for i in range(1,bones.size()):
					angles[i]=wrap_joint(sk,bones,angles,i,tip,dist,FINGER_RADIUS[mini(i+1,4)]-squeeze,0.,MAX_FLEX[mini(i+1,4)],MAX_FLEX[mini(i+1,4)])
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
						if chain_clearance(sk,bones,angles,tip,dist)>=.0005-squeeze:break
						for i in range(bones.size()-1,0,-1):angles[i]=maxf(float(wrapped[i]),float(angles[i])-.06)
		if debug_contact and not contact.is_empty():
			var frames=finger_frames(sk,bones,angles);var ends=[]
			for i in range(bones.size()):ends.append(snappedf(dist.call(segment_end(sk,bones,frames,i,tip)),.0001))
			print("FINGER ",contact.field.id," ",side," ",style," ",finger," angles ",angles.map(func(x):return snappedf(x,.01))," end_dist ",ends)
		for i in range(bones.size()):
			var rest:Quaternion=sk.get_bone_rest(bones[i]).basis.get_rotation_quaternion()
			out[bones[i]]=(rest*Quaternion(Vector3.BACK,frame_spread if i==0 else 0.)*Quaternion(Vector3.RIGHT,-float(angles[i]))).normalized()
		frame_spread=0.
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
	# 1.4.4: a small margin over the finger radius (the field's cells are 6.5 mm;
	# a bone centre exactly one radius out still read as sunk on the mesh).
	radius+=WRAP_MARGIN
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
static func trigger_finger(sk:Skeleton3D,bones:Array,angles:Array,tip:float,dist:Callable,trigger:Vector3,field:Callable=Callable()) -> Array:
	var n=bones.size()
	if n<4:return angles.duplicate()
	# Round 6: a trigger point measured inside the model's surface (shotgun
	# stocks, the FOLD) pulled the finger into the receiver. It is moved out
	# along the field's gradient until a finger pad fits there.
	if field.is_valid():
		var want=FINGER_RADIUS[4]*.8
		for step in range(8):
			var f=float(field.call(trigger))
			if f>=want:break
			var e=.004;var g=Vector3(float(field.call(trigger+Vector3(e,0,0)))-float(field.call(trigger-Vector3(e,0,0))),float(field.call(trigger+Vector3(0,e,0)))-float(field.call(trigger-Vector3(0,e,0))),float(field.call(trigger+Vector3(0,0,e)))-float(field.call(trigger-Vector3(0,0,e))))
			if g.length_squared()<1e-10:break
			trigger+=g.normalized()*minf(want-f+.001,.006)
	var cost_of=func(trial:Array) -> float:
		var frames=finger_frames(sk,bones,trial)
		var cost=0.
		for i in range(1,n):
			var end:Vector3=segment_end(sk,bones,frames,i,tip)
			var d=dist.call(end)-FINGER_RADIUS[mini(i+1,4)]
			# 1.4.5: inside the trigger guard's opening (round the trigger) the
			# field reads solid - its 6.5 mm cells fill the thin guard's hole - so
			# it would keep the finger out of the guard, under its bar.
			var in_guard=end.distance_to(trigger)<GUARD_OPENING
			# 1.4.4: the first bone also keeps out of the real receiver / guard.
			if i<=2 and field.is_valid() and not in_guard:d=minf(d,field.call(end)-FINGER_RADIUS[mini(i+1,4)])
			if d<0.:cost+=-d*40.
			# Round 6: the last bone and the tip may touch the guard (the field
			# cannot tell the thin guard from the trigger) but not go deep into
			# the receiver behind it (shotgun stocks: the tip sank 11-18 mm).
			if i>2 and field.is_valid() and not in_guard:
				var deep=field.call(segment_end(sk,bones,frames,i,tip))-FINGER_RADIUS[mini(i+1,4)]+.003
				if deep<0.:cost+=-deep*160.
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
	trigger_cost=best_cost
	return best
static var trigger_cost=0. # the last trigger_finger's best cost (index spread search)
const GUARD_OPENING=.03 # hand units round the trigger point treated as the guard's open hole
# Applies a grip's finger pose (weight blends from the animated pose). A small
# per-hero memory smooths changes between grips.
static func apply_grip(hero:HeroCharacter,side:String,handle:Transform3D,style:String,shape:Dictionary,weight:float,pointing:bool=false,contact:Dictionary={}):
	if not shaped(style):curl(hero,side,weight,style,pointing);return
	var hand_scale=hero.hand_scale()
	var ws=world_shape(handle,style,shape)
	var offset=grip_offset(hero,side,style,ws,hand_scale,contact)
	var hand={"half":ws.half/hand_scale,"round":float(ws.round)/hand_scale}
	if ws.has("trigger") and not pointing:hand.trigger=ws.trigger/hand_scale
	if ws.get("thumb_over",false):hand.thumb_over=true
	var pose=grip_pose(hero,side,style,offset/hand_scale,hand,pointing,contact,hand_scale)
	var sk=hero.skeleton;var blend=1.-exp(-hero.frame_dt*24.) if hero.frame_dt>0. else 1.
	for b in pose:
		var target:Quaternion=pose[b]
		if hero.finger_memory.has(b) and blend<1.:target=Quaternion(hero.finger_memory[b]).normalized().slerp(target.normalized(),blend)
		hero.finger_memory[b]=target
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).normalized().slerp(target.normalized(),weight))
# 1.4.4 round 6: fingers closed round a handle that rides the hand itself (the
# melee tools): the handle lies along the fist's thumb axis through `centre`
# (wrist-bone space), with the given half extents (metres: radius, half
# length, radius). The wrist is not moved; the fingers wrap the handle's box
# as they wrap a pistol grip, so they neither float nor sink into it.
static func fingers_round(hero:HeroCharacter,side:String,centre:Vector3,shape:Dictionary,weight:float):
	var wrist:Transform3D=hero.bone_world(hero.bone["Wrist."+side])
	var frame:Basis=FRAMES.pistol[side]
	var hb:Basis=wrist.basis.orthonormalized()*frame.inverse()
	var handle_origin:Vector3=wrist*centre
	# Tool-local units are the hand bone's units (the tool rides that bone).
	var hand_scale=hero.hand_scale()
	var offset:Vector3=(hb.inverse()*(wrist.origin-handle_origin))/hand_scale
	var hand={"half":Vector3(shape.half),"round":float(shape.round)}
	var pose=grip_pose(hero,side,"pistol",offset,hand,false,{},hand_scale)
	var sk=hero.skeleton
	for b in pose:
		hero.finger_memory.erase(b)
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).normalized().slerp(Quaternion(pose[b]).normalized(),weight))
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
		sk.set_bone_pose_rotation(b,sk.get_bone_pose_rotation(b).normalized().slerp(target.normalized(),weight))
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
