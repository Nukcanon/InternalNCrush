class_name HeroAnimation
extends RefCounted
## Code-built AnimationTree for heroes. Layers (bottom to top):
##  locomotion 2D blend (idle/walk/run in 4 directions) -> crouch -> sprint ->
##  airborne -> upper-body aim (pitch blend) -> shoot / reload / throw / hit
##  one-shots (upper body) -> slide / plant (full body).
## The tree is advanced manually by HeroCharacter.drive(), so the server and
## clients evaluate identical poses for the same inputs.
static var upper_filters={}
# Measured ground speed of each clip at normal playback (tests/probe_clips.gd):
# the feet stay planted when playback scales with actual speed / this.
const WALK_NATURAL=1.07
const RUN_NATURAL=2.72
const SPRINT_NATURAL=4.25
const CROUCH_NATURAL=.64
static func upper_bones(skeleton:Skeleton3D) -> Array:
	var roots=[];for name in HeroCharacter.UPPER_ROOTS:roots.append(skeleton.find_bone(name))
	var out=[]
	for i in range(skeleton.get_bone_count()):
		var j=i
		while j>=0:
			if j in roots:out.append(skeleton.get_bone_name(i));break
			j=skeleton.get_bone_parent(j)
	return out
static func clip(name:String) -> AnimationNodeAnimation:
	var node=AnimationNodeAnimation.new();node.animation=name;return node
static func filtered(node:AnimationNode,bones:Array):
	node.filter_enabled=true
	for b in bones:node.set_filter_path(NodePath("Skeleton3D:"+b),true)
static func build_tree(hero:HeroCharacter,player:AnimationPlayer) -> AnimationTree:
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var tree=AnimationTree.new();tree.name="AnimationTree";hero.model.add_child(tree)
	tree.add_animation_library("",HeroCharacter.clips(hero.role))
	tree.root_node=NodePath("..")
	tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var upper=upper_bones(hero.skeleton)
	var bt=AnimationNodeBlendTree.new()
	var loco=AnimationNodeBlendSpace2D.new();loco.min_space=Vector2(-1,-1);loco.max_space=Vector2(1,1)
	for p in [["Idle_Loop",Vector2.ZERO],["Walk_Loop",Vector2(0,WALK_NATURAL/RUN_NATURAL)],["Run",Vector2(0,1)],["Run_Back",Vector2(0,-1)],["Run_Left",Vector2(-1,0)],["Run_Right",Vector2(1,0)]]:
		loco.add_blend_point(clip(p[0]),p[1])
	bt.add_node("loco",loco,Vector2(0,0))
	bt.add_node("loco_speed",AnimationNodeTimeScale.new(),Vector2(200,0));bt.connect_node("loco_speed",0,"loco")
	var crouch=AnimationNodeBlendSpace1D.new();crouch.add_blend_point(clip("Crouch_Idle_Loop"),0.);crouch.add_blend_point(clip("Crouch_Fwd_Loop"),1.)
	bt.add_node("crouch",crouch,Vector2(0,150))
	bt.add_node("crouch_speed",AnimationNodeTimeScale.new(),Vector2(200,150));bt.connect_node("crouch_speed",0,"crouch")
	bt.add_node("crouch_mix",AnimationNodeBlend2.new(),Vector2(400,0));bt.connect_node("crouch_mix",0,"loco_speed");bt.connect_node("crouch_mix",1,"crouch_speed")
	bt.add_node("sprint_clip",clip("Sprint_Loop"),Vector2(400,150))
	bt.add_node("sprint_speed",AnimationNodeTimeScale.new(),Vector2(500,150));bt.connect_node("sprint_speed",0,"sprint_clip")
	bt.add_node("sprint_mix",AnimationNodeBlend2.new(),Vector2(600,0));bt.connect_node("sprint_mix",0,"crouch_mix");bt.connect_node("sprint_mix",1,"sprint_speed")
	bt.add_node("air_clip",clip("Jump_Loop"),Vector2(600,150))
	bt.add_node("air_mix",AnimationNodeBlend2.new(),Vector2(800,0));bt.connect_node("air_mix",0,"sprint_mix");bt.connect_node("air_mix",1,"air_clip")
	var aim=AnimationNodeBlendSpace1D.new();aim.min_space=-1.;aim.max_space=1.
	aim.add_blend_point(clip("Pistol_Aim_Down"),-1.);aim.add_blend_point(clip("Pistol_Aim_Neutral"),0.);aim.add_blend_point(clip("Pistol_Aim_Up"),1.)
	bt.add_node("aim",aim,Vector2(800,150))
	var hold=AnimationNodeBlend2.new();filtered(hold,upper)
	bt.add_node("hold",hold,Vector2(1000,0));bt.connect_node("hold",0,"air_mix");bt.connect_node("hold",1,"aim")
	var last="hold";var x=1200
	for shot in [["shoot","Pistol_Shoot",.04,.1],["reload","Pistol_Reload",.15,.2],["throw","OverhandThrow",.1,.2],["hit","Hit_Chest",.05,.15],["melee","Sword_Slash",.05,.12]]:
		var one=AnimationNodeOneShot.new();one.fadein_time=shot[2];one.fadeout_time=shot[3];filtered(one,upper)
		bt.add_node(shot[0],one,Vector2(x,0))
		bt.add_node(shot[0]+"_clip",clip(shot[1]),Vector2(x-100,150))
		bt.add_node(shot[0]+"_speed",AnimationNodeTimeScale.new(),Vector2(x,150));bt.connect_node(shot[0]+"_speed",0,shot[0]+"_clip")
		bt.connect_node(shot[0],0,last);bt.connect_node(shot[0],1,shot[0]+"_speed");last=shot[0];x+=200
	for full in [["slide","Slide_Loop"],["plant","Fixing_Kneeling"]]:
		bt.add_node(full[0]+"_clip",clip(full[1]),Vector2(x,150))
		bt.add_node(full[0],AnimationNodeBlend2.new(),Vector2(x,0));bt.connect_node(full[0],0,last);bt.connect_node(full[0],1,full[0]+"_clip");last=full[0];x+=200
	bt.connect_node("output",0,last)
	tree.tree_root=bt
	tree.active=true
	for name in ["loco_speed","crouch_speed","sprint_speed","shoot_speed","reload_speed","throw_speed","hit_speed","melee_speed"]:tree.set("parameters/%s/scale"%name,1.)
	return tree
static func request(tree:AnimationTree,name:String):
	tree.set("parameters/%s/request"%name,AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
static func update(hero:HeroCharacter,dt:float,s:Dictionary):
	var tree=hero.tree;var mem:Dictionary=hero.get_meta("anim_memory",{})
	var velocity:Vector3=s.get("velocity",Vector3.ZERO)
	var local=hero.facing_basis().inverse()*velocity
	var planar=Vector2(local.x,-local.z)
	var speed=planar.length()
	var k=1.-exp(-dt*10.) if dt>0. else 1.
	var crouch=move_toward(float(mem.get("crouch",0.)),1. if s.get("crouch",false) else 0.,dt*6. if dt>0. else 1.)
	var sprint=lerpf(float(mem.get("sprint",0.)),1. if s.get("sprint",false) and speed>2. else 0.,k)
	var air=lerpf(float(mem.get("air",0.)),0. if s.get("grounded",true) else 1.,1.-exp(-dt*8.) if dt>0. else 1.)
	var dir=(planar/RUN_NATURAL).limit_length(1.) if speed>.05 else Vector2.ZERO
	var blend:Vector2=Vector2(mem.get("dir",Vector2.ZERO)).lerp(dir,k)
	tree.set("parameters/loco/blend_position",blend)
	# Below the run clip's own speed the blend already matches; above it the
	# cycle speeds up so the planted foot never slides.
	tree.set("parameters/loco_speed/scale",clampf(speed/RUN_NATURAL,1.,1.9) if speed>.3 else 1.)
	tree.set("parameters/sprint_speed/scale",clampf(speed/SPRINT_NATURAL,.8,1.6))
	tree.set("parameters/crouch/blend_position",clampf(speed/2.,0.,1.))
	tree.set("parameters/crouch_speed/scale",clampf(speed/CROUCH_NATURAL,.7,2.6) if speed>.3 else 1.)
	tree.set("parameters/crouch_mix/blend_amount",crouch)
	tree.set("parameters/sprint_mix/blend_amount",sprint*(1.-crouch))
	tree.set("parameters/air_mix/blend_amount",air)
	var hold=str(s.get("hold","rifle"))
	var aiming=0. if hold=="none" else 1.
	tree.set("parameters/aim/blend_position",clampf(float(s.get("pitch",0.))/1.1,-1.,1.))
	tree.set("parameters/hold/blend_amount",aiming*(1.-sprint))
	# One-shots fire on state edges.
	var shot=float(s.get("shot",99.))
	if shot<float(mem.get("shot",99.)) and shot<.1:request(tree,"shoot")
	var reload=float(s.get("reload",-1.))
	if reload>=0. and float(mem.get("reload",-1.))<0.:
		var length=hero.player.get_animation("Pistol_Reload").length
		tree.set("parameters/reload_speed/scale",length/maxf(.3,float(s.get("reload_time",2.))))
		request(tree,"reload")
	elif reload<0. and float(mem.get("reload",-1.))>=0.:tree.set("parameters/reload/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	var throw=float(s.get("throw",-1.))
	if throw>=0. and float(mem.get("throw",-1.))<0.:request(tree,"throw")
	var hit=float(s.get("hit",0.))
	if hit>.9 and float(mem.get("hit",0.))<=.9:request(tree,"hit")
	var melee=float(s.get("melee",99.))
	if melee<.1 and float(mem.get("melee",99.))>=.1:
		tree.set("parameters/melee_speed/scale",hero.player.get_animation("Sword_Slash").length/.45);request(tree,"melee")
	mem.melee=melee
	var slide=float(s.get("slide",-1.))
	tree.set("parameters/slide/blend_amount",sin(clampf(slide*4.,0.,1.)*PI*.5)*sin(clampf((1.-slide)*4.,0.,1.)*PI*.5) if slide>=0. else 0.)
	tree.set("parameters/plant/blend_amount",move_toward(float(tree.get("parameters/plant/blend_amount")),1. if s.get("plant",false) else 0.,dt*5. if dt>0. else 1.))
	s["sprint_blend"]=sprint
	s["hands"]=float(s.get("hands",1.))*(1.-float(tree.get("parameters/plant/blend_amount")))
	mem.crouch=crouch;mem.sprint=sprint;mem.air=air;mem.dir=blend;mem.shot=shot;mem.reload=reload;mem.throw=throw;mem.hit=hit
	hero.set_meta("anim_memory",mem)
