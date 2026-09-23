extends Node3D
class_name CharacterVisual
const M=preload("res://scripts/mesh_factory.gd")
const ROLE_NAMES=["Vanguard","Pathfinder","Bulwark","Mechanic","Warden","Lifeline"]
const ROLE_ACCENTS=[Color("dfd3ae"),Color("89ab80"),Color("dbb765"),Color("e69d47"),Color("b0a0cd"),Color("62d4b4")]
static var templates={}
var rig:Node3D
var hips:Node3D
var chest:Node3D
var head:Node3D
var right_arm:Node3D
var left_arm:Node3D
var right_elbow:Node3D
var left_elbow:Node3D
var socket:Node3D
var animator:AnimationPlayer
var current_state=""
var role=0
var team=0
var hit_time=0.
var hit_sign=0.
var shot=0.
var airborne_time=0.
var motion_seed=0.
var motion_clock=0.
var movement_blend=0.
var visual_crouch=0.
var visual_sprint=0.
var pelvis_yaw=0.
var turn_phase=0.
var previous_velocity=Vector3.ZERO
var acceleration_lean=Vector3.ZERO
var lower_lag=Vector3.ZERO
var pose_grounded=true
var landing_compression=0.
var arm_right=Vector3(.98,-.08,-.21)
var arm_left=Vector3(1.15,.32,.27)
func build(which:int,side:int):
	role=which;team=side
	var key=str(role)+"_"+str(team)
	var path="res://assets/models/operator_"+key+".scn"
	if ResourceLoader.exists(path):rig=load(path).instantiate()
	else:
		if not templates.has(key):
			var source=make_rig(role,team);M.own_recursive(source,source);var packed=PackedScene.new();packed.pack(source);templates[key]=packed;source.free()
		rig=templates[key].instantiate()
	add_child(rig);hips=rig.get_node("Hips");chest=hips.get_node("Chest");head=chest.get_node("Head");right_arm=chest.get_node("RightArm");left_arm=chest.get_node("LeftArm");right_elbow=right_arm.get_node("Elbow");left_elbow=left_arm.get_node("Elbow");socket=chest.get_node("WeaponSocket");animator=rig.get_node("AnimationPlayer")
	animator.play("idle")
func react(direction:float):hit_time=.32;hit_sign=direction
func update_pose(dt:float,move:Vector3,sprint:bool,crouch:bool,grounded:bool,pitch:float,reloading:float,kick:float,gait_phase:float=-1.,turn:float=0.):
	var speed=Vector2(move.x,move.z).length()
	var next="idle"
	if not grounded:next="jump" if move.y>0 else "fall"
	elif crouch:next="crouch_walk" if speed>.25 else "crouch"
	elif speed>.25:next="run" if sprint else "walk"
	if next!=current_state:animator.play(next,.18);current_state=next
	motion_clock+=dt
	visual_crouch=lerpf(visual_crouch,1. if crouch else 0.,1.-exp(-dt*10))
	visual_sprint=lerpf(visual_sprint,1. if sprint and speed>.6 else 0.,1.-exp(-dt*9))
	var local_velocity=global_basis.inverse()*move
	var acceleration=(local_velocity-previous_velocity)/maxf(dt,.005);previous_velocity=local_velocity
	lower_lag=lower_lag.lerp(Vector3(clampf(-acceleration.x*.002,-.075,.075),0,clampf(-acceleration.z*.002,-.08,.08)),1.-exp(-dt*8))
	acceleration_lean=acceleration_lean.lerp(Vector3(clampf(acceleration.z*.004,-.13,.13),0,clampf(-acceleration.x*.003,-.1,.1)),1.-exp(-dt*9))
	pelvis_yaw=clampf(pelvis_yaw-turn*dt,-.55,.55)
	pelvis_yaw=move_toward(pelvis_yaw,0,dt*(5. if speed>.25 else .85))
	turn_phase+=absf(turn)*dt*.8
	if grounded and not pose_grounded:landing_compression=.16
	pose_grounded=grounded;landing_compression=move_toward(landing_compression,0,dt*.7)
	var phase=maxf(0,gait_phase)
	if grounded:
		solve_feet(dt,move,crouch,sprint,phase)
		if speed<.25 and absf(turn)>.3:
			for i in range(2):
				var leg=hips.get_node("LeftLeg" if i==0 else "RightLeg");var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
				var step=maxf(0,sin((turn_phase+i*.5)*TAU))
				var angles=leg_angles(hips.position.y,0,step*.065)
				leg.rotation=Vector3(angles.x,turn*.055*step,0);knee.rotation.x=angles.y;foot.rotation=Vector3(angles.z,-pelvis_yaw*.35,0)
	else:
		airborne_time+=dt
		hips.position=Vector3(0,.89-visual_crouch*.19,0)
		hips.rotation=Vector3(-.08,0,0)
		var tuck=clampf(move.y/6.,0,1)
		for i in range(2):
			var leg=hips.get_node("LeftLeg" if i==0 else "RightLeg");var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
			leg.rotation=Vector3(.18+tuck*.55+(i*2.-1.)*minf(speed/20.,.18),0,(i*2.-1.)*.055)
			knee.rotation=Vector3(-.25-tuck*.95,0,0);foot.rotation=Vector3(.1+tuck*.28,0,0)
	if grounded:airborne_time=0.
	hips.rotation.y+=pelvis_yaw
	hips.rotation+=acceleration_lean*.35
	hips.position+=lower_lag
	chest.position=Vector3(-lower_lag.x*.75,.3,-lower_lag.z*.75)
	var cycle=phase*TAU
	var movement=clampf(speed/7.4,0,1) if grounded else 0.
	var breath=sin(motion_clock*1.9+motion_seed)
	var aiming=clampf(pitch,-.9,.9)
	chest.rotation=Vector3(-aiming*.45+visual_crouch*.13-visual_sprint*.10+acceleration_lean.x*.8+breath*.008,-pelvis_yaw*.72+sin(cycle)*movement*.07,-local_velocity.x*.006+sin(cycle)*movement*.025)
	head.rotation=Vector3(-aiming*.55-landing_compression*.25,-pelvis_yaw*.28-sin(cycle)*movement*.03,0)
	var right_target=Vector3(.98+aiming*.55,-.08,-.21)
	var left_target=Vector3(1.15+aiming*.55,.32,.27)
	# Right hand carries the lowered rifle; the free support arm counter-swings.
	right_target=right_target.lerp(Vector3(.65+sin(cycle)*.27,-.10,-.14),visual_sprint)
	left_target=left_target.lerp(Vector3(.35-sin(cycle)*.68,.1,.12),visual_sprint)
	if not grounded:
		right_target.x+=.12;left_target.x+=.18;left_target.z+=.10
	var reach=sin(maxf(0,reloading)*PI) if reloading>=0 else 0.
	left_target+=Vector3(reach*.45,0,-reach*.25)
	right_target.x-=kick*.09
	arm_right=arm_right.lerp(right_target,1.-exp(-dt*18));arm_left=arm_left.lerp(left_target,1.-exp(-dt*18))
	right_arm.rotation=arm_right;left_arm.rotation=arm_left
	right_arm.position.y=.13+cos(cycle)*movement*.016;left_arm.position.y=.13-cos(cycle)*movement*.025
	right_elbow.rotation=Vector3(lerpf(.92,.7+sin(cycle)*.14,visual_sprint),0,0)
	left_elbow.rotation=Vector3(lerpf(.38,.70+cos(cycle)*.23,visual_sprint)-reach*.35,0,0)
	socket.position=Vector3(.07,-.09-visual_sprint*.08+cos(cycle)*movement*.012,-.07+visual_sprint*.08)
	socket.rotation=Vector3(-aiming*.5+visual_sprint*.3-kick*.08,visual_sprint*.12-turn*.012,visual_sprint*.18-reach*.18+sin(cycle)*movement*.035)
	hit_time=maxf(0,hit_time-dt);var hit=sin(hit_time/.32*PI)*.2
	chest.rotation+=Vector3(hit*.45,0,hit*hit_sign);head.rotation.x-=hit*.4
	grip_weapon(dt)

static func joint(parent:Node,name:String,pos:Vector3) -> Node3D:
	var n=Node3D.new();n.name=name;n.position=pos;parent.add_child(n);return n
static func make_rig(which:int,side:int) -> Node3D:
	var root=Node3D.new();root.name=ROLE_NAMES[which]
	var team_color=Color("17baff") if side==0 else Color("ff931f")
	var cloth=Color("344f63") if side==0 else Color("675344")
	var plate=Color("c9d2cd") if which==5 else Color("788b8e") if which==3 else Color("476679") if side==0 else Color("80634e")
	var dark=Color("243844");var accent=ROLE_ACCENTS[which];var skin=Color("be987e")
	var h=joint(root,"Hips",Vector3(0,.94,0));var torso=joint(h,"Chest",Vector3(0,.3,0))
	M.tapered(h,Vector3(0,.005,0),Vector3(.43,.25,.28),cloth,.83)
	M.box(h,Vector3(0,.065,-.01),Vector3(.48,.055,.31),dark)
	M.box(h,Vector3(0,.065,-.178),Vector3(.085,.055,.022),accent)
	M.tapered(torso,Vector3(0,.015,0),Vector3(.52 if which!=2 else .61,.46,.31),cloth,.75)
	M.tapered(torso,Vector3(0,.015,-.135),Vector3(.42,.36,.12),plate,.87)
	M.box(torso,Vector3(0,.158,-.21),Vector3(.30,.035,.025),Color("d9f7ff") if side==0 else Color("fff0bc"))
	M.box(torso,Vector3(0,.12,.19),Vector3(.36,.08,.045),team_color.lightened(.26))
	for side_x in [-1,1]:
		M.box(torso,Vector3(side_x*.188,.05,-.19),Vector3(.034,.33,.038),dark,Vector3(0,0,side_x*-.15))
		var arm=joint(torso,"LeftArm" if side_x<0 else "RightArm",Vector3(side_x*.29,.13,0))
		M.tapered(arm,Vector3(0,-.135,0),Vector3(.19,.29,.21),cloth,.82)
		M.box(arm,Vector3(side_x*.024,-.045,.006),Vector3(.23 if which==2 else .19,.16,.245),team_color,Vector3(0,0,side_x*.13))
		M.box(arm,Vector3(side_x*.128,-.04,0),Vector3(.018,.095,.16),team_color.lightened(.28))
		var elbow=joint(arm,"Elbow",Vector3(0,-.28,0));M.sphere(elbow,Vector3.ZERO,Vector3(.145,.15,.15),dark)
		M.tapered(elbow,Vector3(0,-.115,0),Vector3(.145,.235,.17),plate if which in [2,5] else cloth,.76)
		M.box(elbow,Vector3(0,-.235,0),Vector3(.16,.055,.185),dark)
		var hand=joint(elbow,"Hand",Vector3(0,-.275,0));M.box(hand,Vector3.ZERO,Vector3(.10,.095,.10),dark)
		M.box(hand,Vector3(side_x*-.07,.008,-.026),Vector3(.035,.066,.075),accent if which==3 else dark)
		var thigh=joint(h,"LeftLeg" if side_x<0 else "RightLeg",Vector3(side_x*.14,-.025,0))
		M.tapered(thigh,Vector3(0,-.2,0),Vector3(.215,.39,.24),cloth,.8)
		M.box(thigh,Vector3(side_x*.04,-.16,.01),Vector3(.22,.055,.25),dark)
		var knee=joint(thigh,"Knee",Vector3(0,-.415,0));M.box(knee,Vector3(0,-.02,-.11),Vector3(.17,.16,.065),plate)
		M.tapered(knee,Vector3(0,-.19,0),Vector3(.17,.36,.195),cloth,.9)
		var foot=joint(knee,"Foot",Vector3(0,-.415,0));M.box(foot,Vector3(0,.03,-.06),Vector3(.19,.14,.29),dark,Vector3.ZERO,.4)
		M.box(foot,Vector3(0,-.035,-.067),Vector3(.195,.042,.30),Color("182b35"))
		M.box(foot,Vector3(0,.045,-.2),Vector3(.19,.07,.04),team_color)
	var head=joint(torso,"Head",Vector3(0,.36,0))
	M.cylinder(torso,Vector3(0,.255,0),.095,.14,skin)
	M.sphere(head,Vector3(0,.035,0),Vector3(.29,.35,.30),skin)
	M.sphere(head,Vector3(0,.107,.016),Vector3(.34,.27,.36),plate if which==5 else accent if which==3 else team_color)
	M.box(head,Vector3(0,.061,-.172),Vector3(.29,.112,.073),Color("1b3442"),Vector3.ZERO,.45)
	M.box(head,Vector3(0,.087,-.216),Vector3(.24,.022,.012),Color("89d2d6"),Vector3.ZERO,.1)
	for x in [-.18,.18]:M.cylinder(head,Vector3(x,.034,.015),.07,.055,dark,Vector3(0,0,PI/2))
	match which:
		0:
			for x in [-.085,.085]:M.box(torso,Vector3(x,-.048,-.228),Vector3(.12,.14,.05),accent,Vector3(-.12,0,0))
			M.box(torso,Vector3(.13,.14,.22),Vector3(.13,.28,.14),dark)
			M.cylinder(torso,Vector3(.15,.42,.22),.008,.35,accent)
		1:
			M.sphere(head,Vector3(0,.105,.055),Vector3(.45,.35,.44),accent)
			M.box(head,Vector3(0,.088,-.23),Vector3(.255,.085,.02),Color("273d41"))
			M.tapered(torso,Vector3(0,-.12,.21),Vector3(.5,.66,.085),accent,.68)
			M.box(torso,Vector3(-.16,.05,-.225),Vector3(.09,.28,.04),Color("c1c9ad"))
		2:
			M.box(torso,Vector3(0,.08,.255),Vector3(.46,.48,.23),dark)
			for x in [-.33,.33]:M.box(torso,Vector3(x,.17,0),Vector3(.26,.17,.37),plate,Vector3(0,0,sign(x)*.18))
			M.box(head,Vector3(0,-.061,-.14),Vector3(.31,.16,.18),plate)
			for x in [-.1,.1]:M.box(torso,Vector3(x,-.1,-.25),Vector3(.085,.22,.11),accent)
		3:
			M.cylinder(head,Vector3(0,.12,0),.235,.03,accent,Vector3.ZERO,-1.,12)
			M.box(head,Vector3(0,.225,0),Vector3(.047,.05,.29),Color("efd19c"))
			for x in [-.26,.26]:M.box(h,Vector3(x,-.05,.01),Vector3(.15,.18,.22),accent)
			M.cylinder(torso,Vector3(.13,.02,.255),.048,.47,accent)
			M.box(torso,Vector3(-.1,.045,.235),Vector3(.21,.32,.12),dark)
			M.box(h,Vector3(.29,-.23,-.02),Vector3(.05,.31,.05),Color("a9b3b0"),Vector3(0,0,.2))
		4:
			for x in [-.11,.11]:M.cylinder(head,Vector3(x,-.073,-.176),.06,.08,plate,Vector3(PI/2,0,0))
			for x in [-.14,.14]:M.cylinder(torso,Vector3(x,.04,.27),.083,.48,accent)
			M.box(torso,Vector3(0,.1,-.217),Vector3(.18,.12,.06),accent)
		5:
			M.box(torso,Vector3(0,.02,.255),Vector3(.4,.4,.18),Color("dce1d1"))
			M.box(torso,Vector3(0,.03,.356),Vector3(.065,.24,.016),accent);M.box(torso,Vector3(0,.03,.357),Vector3(.24,.065,.016),accent)
			M.box(torso,Vector3(0,.08,-.213),Vector3(.045,.16,.025),accent);M.box(torso,Vector3(0,.08,-.214),Vector3(.16,.045,.025),accent)
			for x in [-.2,.2]:M.cylinder(h,Vector3(x,-.12,-.1),.033,.16,accent)
	M.box(torso,Vector3(0,.07,.17),Vector3(.38,.3,.045),team_color)
	role_badge(torso,which,Vector3(0,.10,-.26),1.)
	role_badge(torso,which,Vector3(0,.09,.39),1.4)
	M.box(head,Vector3(0,.17,-.153),Vector3(.25,.04,.03),team_color)
	joint(torso,"WeaponSocket",Vector3(.10,-.13,-.37))
	add_uniform_detail(root,h,torso,head,which,team_color,dark,accent)
	M.merge_rig(root);add_clips(root)
	return root
static func role_badge(parent:Node3D,which:int,pos:Vector3,factor:float):
	var badge=joint(parent,"RoleBadge",pos);badge.scale=Vector3.ONE*factor
	M.box(badge,Vector3.ZERO,Vector3(.18,.16,.015),Color("17364a"))
	var white=Color("edf8eb");var depth=-.012 if pos.z<0 else .012
	match which:
		0:
			for side in [-1,1]:M.box(badge,Vector3(side*.032,0,depth),Vector3(.024,.093,.015),white,Vector3(0,0,side*-.65))
		1:
			M.cylinder(badge,Vector3(0,0,depth),.047,.012,white,Vector3(PI/2,0,0),-1.,12)
			M.cylinder(badge,Vector3(0,0,depth*1.6),.025,.014,Color("17364a"),Vector3(PI/2,0,0),-1.,12)
		2:
			for x in [-.04,0,.04]:M.box(badge,Vector3(x,0,depth),Vector3(.024,.095,.016),white)
		3:
			for rot in [-.7,.7]:M.box(badge,Vector3(0,0,depth),Vector3(.023,.115,.016),Color("ffd27c"),Vector3(0,0,rot))
		4:
			for x in [-.038,.038]:M.cylinder(badge,Vector3(x,0,depth),.024,.016,white,Vector3(PI/2,0,0))
		5:
			M.box(badge,Vector3(0,0,depth),Vector3(.031,.117,.015),Color("78ffcb"));M.box(badge,Vector3(0,0,depth*1.1),Vector3(.117,.031,.015),Color("78ffcb"))
static func leg_angles(hip_y:float,foot_z:float,foot_y:float) -> Vector3:
	var dy=hip_y-.025-foot_y-.1;var d=clampf(sqrt(dy*dy+foot_z*foot_z),.12,.829)
	var bend=acos(clampf(d/(2*.415),-1,1));var upper=atan2(-foot_z,dy)+bend;var lower=-2*bend
	return Vector3(upper,lower,-upper-lower)
static func add_clips(root:Node3D):
	var player=AnimationPlayer.new();player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;player.name="AnimationPlayer";root.add_child(player);var library=AnimationLibrary.new()
	for state in ["idle","walk","run","crouch","crouch_walk","jump","fall","fire","reload","hit","land","death"]:
		var anim=Animation.new();anim.length={"idle":2.,"walk":.64,"run":.5,"crouch":2.,"crouch_walk":1.05,"jump":.32,"fall":.6,"fire":.15,"reload":2.2,"hit":.3,"land":.2,"death":.65}[state]
		anim.loop_mode=Animation.LOOP_LINEAR if state in ["idle","walk","run","crouch","crouch_walk","fall"] else Animation.LOOP_NONE
		var paths=["Hips:position","Hips:rotation","Hips/LeftLeg:rotation","Hips/LeftLeg/Knee:rotation","Hips/LeftLeg/Knee/Foot:rotation","Hips/RightLeg:rotation","Hips/RightLeg/Knee:rotation","Hips/RightLeg/Knee/Foot:rotation","Hips/Chest:rotation","Hips/Chest/Head:rotation","Hips/Chest/LeftArm:rotation","Hips/Chest/LeftArm/Elbow:rotation","Hips/Chest/RightArm:rotation","Hips/Chest/RightArm/Elbow:rotation","Hips/Chest/WeaponSocket:rotation"]
		for path in paths:var track=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(track,NodePath(path));anim.track_set_interpolation_type(track,Animation.INTERPOLATION_LINEAR)
		for frame in range(17):
			var t=frame/16.;var moving=state in ["walk","run","crouch_walk"];var crouched=state in ["crouch","crouch_walk"];var stride=.58 if state=="run" else .46 if state=="walk" else .25
			var y=.61 if crouched else .94
			if moving:y+=cos(t*TAU*2)*.018
			elif state=="idle":y+=sin(t*TAU)*.006
			if state=="jump":y-=sin(t*PI)*.13
			if state=="land":y-=sin(t*PI)*.11
			if state=="death":y=lerpf(.94,.25,sin(t*PI/2))
			anim.track_insert_key(0,t*anim.length,Vector3(0,y,0))
			anim.track_insert_key(1,t*anim.length,Vector3(-.09 if state=="run" else -t*1.45 if state=="death" else 0,0,sin(t*TAU)*.035 if moving else 0))
			for leg in range(2):
				var phase=fmod(t+leg*.5,1.);var stance=phase<.58;var z=lerpf(stride,-stride,phase/.58) if stance else lerpf(-stride,stride,smoothstep(.58,1.,phase));z=z if moving else -.09 if crouched else 0.;var foot_y=sin((phase-.58)/.42*PI)*(.18 if state=="run" else .11) if moving and not stance else 0.
				var angles=leg_angles(y,z,foot_y)
				for j in range(3):anim.track_insert_key(2+leg*3+j,t*anim.length,Vector3(angles[j],0,0))
			var pulse=sin(t*PI)
			var body=Vector3.ZERO;var head_pose=Vector3.ZERO;var left=Vector3(.96,0,0);var left_elbow=Vector3(.55,0,0);var right=Vector3(.65,0,0);var right_elbow=Vector3(.8,0,0);var weapon=Vector3.ZERO
			if state=="fire":right.x-=pulse*.12;weapon.x=-pulse*.075;body.x=pulse*.025
			if state=="reload":left.x+=pulse*.5;left.z=-pulse*.25;left_elbow.x-=pulse*.6;weapon.z=-pulse*.22;head_pose.x=.1*pulse
			if state=="hit":body=Vector3(pulse*.1,0,pulse*.14);head_pose.x=-pulse*.13
			if state=="run":left.x=.65+sin(t*TAU)*.14;right.x=.35-sin(t*TAU)*.14;weapon=Vector3(.2,0,.2)
			if crouched:body.x=.12
			var poses=[body,head_pose,left,left_elbow,right,right_elbow,weapon]
			for j in range(poses.size()):anim.track_insert_key(8+j,t*anim.length,poses[j])
		library.add_animation(state,anim)
	for index in range(5):
		var anim=Animation.new();anim.length=.9
		var tracks=["Hips:position","Hips:rotation","Hips/Chest:rotation","Hips/Chest/LeftArm:rotation","Hips/Chest/RightArm:rotation","Hips/LeftLeg:rotation","Hips/RightLeg:rotation","Hips/LeftLeg/Knee:rotation","Hips/RightLeg/Knee:rotation"]
		for path in tracks:var track=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(track,NodePath(path))
		for frame in range(13):
			var t=frame/12.;var fall=sin(clampf((t-.12)/.88,0,1)*PI/2);var crouch=sin(t*PI)*.15
			var end_rot=[Vector3(-1.45,0,.13),Vector3(1.45,0,-.12),Vector3(.15,0,-1.45),Vector3(-.12,0,1.45),Vector3(.9,.2,.7)][index]
			var hip=Vector3(0,lerpf(.94,.27,fall)-crouch,0)
			var poses=[hip,end_rot*fall,Vector3(sin(t*PI)*.16,0,0),Vector3(.96-fall*(1.3 if index%2==0 else .3),0,-fall*.4),Vector3(.65-fall*.7,0,fall*.35),Vector3(fall*.55,0,-fall*.16),Vector3(fall*.2,0,fall*.2),Vector3(-fall*.85,0,0),Vector3(-fall*.4,0,0)]
			for j in range(poses.size()):anim.track_insert_key(j,t*.9,poses[j])
		library.add_animation(["fall_back","fall_front","fall_left","fall_right","fall_fold"][index],anim)
	player.add_animation_library("",library)

func solve_feet(dt:float,move:Vector3,crouched:bool,sprinting:bool,phase:float):
	var horizontal=Vector3(move.x,0,move.z)
	var speed=horizontal.length()
	movement_blend=lerpf(movement_blend,clampf(speed/.7,0,1),1.-exp(-dt*12))
	var local_motion=global_basis.inverse()*horizontal
	var direction=local_motion.normalized() if speed>.05 else Vector3.FORWARD
	var stride=(.53 if sprinting else .40 if not crouched else .22)*movement_blend
	var hip_height=lerpf(.91,.62,visual_crouch)-landing_compression
	var cycle=fposmod(maxf(0,phase),1.)
	hips.position=Vector3(sin(cycle*TAU)*.018*movement_blend,hip_height+cos(cycle*TAU*2)*.013*movement_blend,0)
	hips.rotation=Vector3(-.07 if sprinting else .035 if crouched else 0,clampf(-direction.x*.12,-.12,.12)*movement_blend,sin(cycle*TAU)*.018*movement_blend)
	for i in range(2):
		var leg=hips.get_node("LeftLeg" if i==0 else "RightLeg")
		var knee=leg.get_node("Knee");var foot=knee.get_node("Foot")
		var p=fposmod(cycle+i*.5,1.)
		var stance=p<.62
		var travel=lerpf(stride,-stride,p/.62) if stance else lerpf(-stride,stride,smoothstep(.62,1.,p))
		var lift=0. if stance else sin((p-.62)/.38*PI)*(.16 if sprinting else .10)*movement_blend
		var foot_z=direction.z*travel-(.09 if crouched else 0.)
		var foot_x=direction.x*travel
		var angles=leg_angles(hips.position.y,foot_z,lift)
		var lateral=atan2(foot_x,maxf(.3,hips.position.y-.1))
		leg.rotation=Vector3(angles.x,0,lateral)
		knee.rotation=Vector3(angles.y,0,0)
		foot.rotation=Vector3(angles.z+(.11*sin(p/.62*PI) if stance else -.1*sin((p-.62)/.38*PI)),0,-lateral)

static func add_uniform_detail(root:Node3D,h:Node3D,torso:Node3D,head:Node3D,which:int,team_color:Color,dark:Color,accent:Color):
	var fabric=Color("54656a");var hardware=Color("9aabac")
	# Plate carrier, stitched webbing, magazine retention and independent pouches.
	for row in range(4):
		M.box(torso,Vector3(0,-.10+row*.058,-.207),Vector3(.37,.015,.012),fabric)
	for x in [-.125,0,.125]:
		M.tapered(torso,Vector3(x,-.105,-.24),Vector3(.104,.17,.055),dark,.90)
		M.box(torso,Vector3(x,-.015,-.25),Vector3(.09,.019,.05),fabric)
		M.box(torso,Vector3(x,-.08,-.272),Vector3(.016,.12,.008),hardware)
	for sign_x in [-1,1]:
		M.box(torso,Vector3(sign_x*.155,.13,-.195),Vector3(.055,.21,.035),dark,Vector3(0,0,sign_x*.11))
		M.box(torso,Vector3(sign_x*.155,.185,-.22),Vector3(.042,.045,.01),hardware)
		M.box(h,Vector3(sign_x*.255,-.12,.055),Vector3(.10,.19,.16),fabric,Vector3(0,0,sign_x*.08))
		var leg=h.get_node("LeftLeg" if sign_x<0 else "RightLeg")
		M.box(leg,Vector3(sign_x*.108,-.20,.012),Vector3(.05,.17,.15),fabric)
		var arm=torso.get_node("LeftArm" if sign_x<0 else "RightArm")
		M.box(arm,Vector3(sign_x*.018,-.10,-.105),Vector3(.13,.11,.025),dark)
		M.box(arm,Vector3(sign_x*.018,-.12,-.12),Vector3(.12,.026,.012),team_color)
		M.box(head,Vector3(sign_x*.16,.105,.01),Vector3(.03,.043,.19),dark)
		for z in [-.07,.01,.08]:M.box(head,Vector3(sign_x*.18,.11,z),Vector3(.02,.023,.025),hardware)
	M.tapered(head,Vector3(0,-.075,-.122),Vector3(.22,.13,.07),dark,.7)
	M.box(head,Vector3(.06,.20,-.01),Vector3(.045,.03,.12),hardware)
	for y in [-.07,-.035,0.]:M.box(head,Vector3(0,y,-.167),Vector3(.12,.008,.007),fabric)

func grip_weapon(dt:float):
	var weapon:Node3D
	for child in socket.get_children():
		if child is WeaponVisual:weapon=child;break
	if not is_instance_valid(weapon):return
	var right_target=chest.to_local(weapon.right_hand.global_position)
	var left_target=chest.to_local(weapon.left_hand.global_position)
	solve_arm(right_arm,right_elbow,right_target,Vector3(1,-.65,.25),dt,1.)
	solve_arm(left_arm,left_elbow,left_target,Vector3(-1,-.4,.1),dt,1.-visual_sprint)
func solve_arm(arm:Node3D,elbow:Node3D,target:Vector3,pole:Vector3,dt:float,weight:float):
	var delta=target-arm.position
	var distance=clampf(delta.length(),.08,.548)
	var direction=delta.normalized()
	var along=(.28*.28-.275*.275+distance*distance)/(2.*distance)
	var bend=sqrt(maxf(0.,.28*.28-along*along))
	var plane=(pole-direction*pole.dot(direction)).normalized()
	var elbow_pos=arm.position+direction*along+plane*bend
	var upper=Quaternion(Vector3.DOWN,(elbow_pos-arm.position).normalized())
	arm.quaternion=arm.quaternion.slerp(upper,weight)
	var lower_direction=arm.basis.inverse()*(target-elbow_pos).normalized()
	elbow.quaternion=elbow.quaternion.slerp(Quaternion(Vector3.DOWN,lower_direction.normalized()),weight)
