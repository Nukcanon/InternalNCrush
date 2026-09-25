extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	for role in range(6):
		var rig=CharacterVisual.make_rig(role,0);root.add_child(rig)
		var skeleton=OperatorSkin.install(rig,"%d_review"%role)
		var body=rig.get_node("ContinuousBody");var arrays=body.mesh.surface_get_arrays(0)
		expect(arrays[Mesh.ARRAY_INDEX].size()<18000,"comic operator has fewer than 6000 triangles, role "+str(role))
		expect(skeleton.get_bone_count()==15 and rig.has_node("Hips/Chest/WeaponSocket"),"combat joints and weapon grip remain available, role "+str(role))
		var material=body.mesh.surface_get_material(0)
		expect(material is ShaderMaterial and "toon_surface" in material.shader.code and not "texture(" in material.shader.code,"operator has no sampled facial texture, role "+str(role))
		rig.free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(200,1,200),Color.GRAY)
	g.add_player(1,"Review","review_fixture");g.phase="combat";g.clock=100.
	var p=g.players[1];var actor=g.actors[1];p.protect=0.;p.role=3;p.primary="e1";p.slot=0;p.skill_ready=135.;actor.position=Vector3(20,0,20)
	expect(not ActionState.available(g,1,"skill"),"cooldown disables skill action")
	g.clock=135.;expect(ActionState.available(g,1,"skill"),"skill re-enables at deadline")
	p.mag[p.primary]=0;p.reserve[p.primary]=60;p.reload=0.
	expect(not ActionState.available(g,1,"fire") and ActionState.available(g,1,"reload"),"empty magazine disables firing but permits reload")
	p.reload=138.;expect(not ActionState.available(g,1,"reload"),"active reload cannot be restarted")
	p.reload=0.;p.role=4;p.gadget=0;p.gadget_count=2;p.smoke=0;p.flash_count=1
	expect(not ActionState.equipment_ready(g,1,2) and ActionState.equipment_ready(g,1,3),"empty smoke does not grey out an available flash grenade")
	g.options.mode=0;expect(not ActionState.available(g,1,"bomb"),"bomb action unavailable in other game modes")
	g.options.mode=4;g.arena.sites=[Vector3(20,0,20)];g.bomb={"planted":false,"carrier":1};p.team=MatchFlow.attackers(g)
	expect(ActionState.available(g,1,"bomb"),"carrier can plant inside the site")
	actor.position.x+=20.;expect(not ActionState.available(g,1,"bomb"),"plant button becomes unavailable outside the site")
	g.options.mode=0;actor.position=Vector3(20,0,20);actor.velocity=Vector3.ZERO;actor.reset_view(.7)
	await physics_frame;await physics_frame
	actor.simulate(1./60.,g.clock,true)
	expect(not g.begin_slide(1),"desktop slide still requires running momentum")
	expect(g.begin_slide(1,true) and p.slide_direction.is_equal_approx(Basis(Vector3.UP,.7)*Vector3.FORWARD),"touch slide starts from rest in the facing direction")
	expect(not g.begin_slide(1,true),"repeated touch slide obeys its cooldown")
	p.slide_until=0.;p.slide_ready=0.;p.role=0;p.primary="a1";p.mag[p.primary]=30;actor.reset_view(0.)
	g.add_player(2,"Target","aim_fixture");g.spawn(2);g.players[2].team=1-p.team;g.players[2].protect=0.;g.actors[2].position=Vector3(21,0,0)
	await physics_frame;await physics_frame
	g.profile.touch_aim_assist=true;TouchAim.assist(g,actor,1./30.)
	expect(actor.input_state.yaw<0. and absf(actor.input_state.yaw)<=deg_to_rad(12.)/30.+.00001,"aim assistance turns gently toward a visible nearby enemy")
	var direction=(g.actors[2].eye()-Vector3.UP*.35-actor.eye()).normalized()
	actor.input_state.yaw=atan2(-direction.x,-direction.z);actor.input_state.pitch=asin(direction.y);g.profile.touch_auto_fire=true
	expect(TouchAim.can_auto_fire(g,actor),"optional auto fire recognises a visible enemy under the crosshair")
	g.arena.box(Vector3(20.5,1.,10.),Vector3(3,2,.4),Color.GRAY)
	await physics_frame;await physics_frame
	expect(not TouchAim.can_auto_fire(g,actor),"auto fire never shoots at a target hidden behind a wall")
	actor.input_state.yaw=0.;actor.input_state.pitch=0.;TouchAim.assist(g,actor,1./30.)
	expect(actor.input_state.yaw==0. and actor.input_state.pitch==0.,"aim assistance never follows a target through a wall")
	GraphicsOptions.physics_effects=0
	var corpse=g.combat_fx.ragdoll(null,Vector3.ZERO,Vector3.BACK,0,0,0.,false,Vector3.ZERO)
	expect(corpse is AnimatedDeath and corpse.find_children("*","RigidBody3D",true,false).is_empty(),"low quality retains a visible death animation without rigid bodies")
	var burst=BurstVisual.new();g.add_child(burst);burst.build(true)
	expect(burst.puffs.size()==24 and burst.find_children("*","RigidBody3D",true,false).is_empty(),"low physics retains explosion fire/smoke while removing decorative debris bodies")
	expect(Rules.MODES.size()==5 and Rules.MAPS.size()==32,"five modes and the practice arena remain available")
	g.free();await process_frame
	print("CARTOON_REVIEW_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
