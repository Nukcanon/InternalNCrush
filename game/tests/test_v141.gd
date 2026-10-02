extends SceneTree
# 1.4.1 fixes: launcher models with visible rounds, the QUAD tube-by-tube reload
# rule, reload hand work, symbol glyph coverage, defusal fuse clock, menu copy.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func run():
	Catalog.load_all()
	# Launchers: COMET holds one visible rocket, QUAD four; loading slides the next one in.
	var comet=GunModel.new();root.add_child(comet);comet.build(Catalog.get_weapon("h4"),false)
	var quad=GunModel.new();root.add_child(quad);quad.build(Catalog.get_weapon("h5"),false)
	expect(comet.launcher and comet.rounds.size()==1 and quad.launcher and quad.rounds.size()==4,"launchers built in code with their round nodes")
	expect(comet.muzzle.position.z<comet.right_grip.position.z and quad.muzzle.position.z<quad.right_grip.position.z,"launcher muzzles ahead of the grips")
	quad.set_rounds(2);expect(quad.rounds[0].visible and quad.rounds[1].visible and not quad.rounds[2].visible and not quad.rounds[3].visible,"QUAD shows exactly the loaded rockets")
	quad.set_rounds(2,.5);var seat:Vector3=quad.rounds[2].get_meta("seat")
	expect(quad.rounds[2].visible and quad.rounds[2].position.z>seat.z and not quad.rounds[3].visible,"the rocket being loaded comes in from behind its tube (rear loading)")
	quad.set_rounds(2,.95);expect(quad.rounds[2].position.is_equal_approx(seat),"loaded rocket seats at the end of the reload")
	# Rockets sit inside their tubes, nose toward the muzzle.
	for launcher in [comet,quad]:
		var r:Node3D=launcher.rounds[0]
		expect(float(r.get_meta("seat").z)-float(r.get_meta("front"))>=launcher.muzzle.position.z-.001,"seated rocket stays inside the tube: "+launcher.spec.name)
		expect(float(r.get_meta("front"))>float(r.get_meta("back")),"rocket nose (longer front) points to the muzzle: "+launcher.spec.name)
	comet.set_rounds(0);expect(not comet.rounds[0].visible,"an empty COMET shows no rocket")
	expect(GunLooks.hold_kind(Catalog.get_weapon("h4"))=="shoulder" and GunLooks.hold_kind(Catalog.get_weapon("h5"))=="rifle","launcher hold kinds")
	# Reload hand work exists for every reload style and returns to the grip.
	for wid in ["a1","pistol","e1","r2","h4","h5","h6","m2","c2"]:
		var gun=GunModel.new();root.add_child(gun);gun.build(Catalog.get_weapon(wid),false)
		var w=Catalog.get_weapon(wid)
		var mid=ReloadMotion.support(gun,{"reload":.45,"reload_tactical":false,"rounds":0})
		var idle=ReloadMotion.support(gun,{"reload":-1.,"shot":5.})
		expect(not mid.is_empty() and mid.position.is_finite(),"reload hand work mid-reload: "+w.name)
		expect(idle.is_empty(),"support hand back on the grip when idle: "+w.name)
		# (1.5.0, the user: a slide pistol run dry has its slide locked back and the seated magazine sends it forward - no rack at the end)
		if w.kind=="gun" and not w.get("rocket",false) and not w.get("laser",false) and w.reload_style not in ["shell","break","box","pistol"]:
			var racking=ReloadMotion.support(gun,{"reload":.9,"reload_tactical":false,"rounds":0});var tactical=ReloadMotion.support(gun,{"reload":.9,"reload_tactical":true,"rounds":0})
			expect(racking.position.y>tactical.position.y-.001 and racking.position!=tactical.position,"run-dry reload racks the bolt, tactical reload does not: "+w.name)
		if w.reload_style=="pistol" and not w.get("dual",false):
			var dry=ReloadMotion.support(gun,{"reload":.9,"reload_tactical":false,"rounds":0});var tac=ReloadMotion.support(gun,{"reload":.9,"reload_tactical":true,"rounds":0})
			expect(dry.position.distance_to(tac.position)<.002,"run-dry pistol reload ends without a slide rack: "+w.name)
		gun.free()
	var pump=GunModel.new();root.add_child(pump);pump.build(Catalog.get_weapon("e1"),false)
	var stroke=ReloadMotion.support(pump,{"reload":-1.,"shot":.25});expect(not stroke.is_empty() and stroke.position.z>pump.left_grip.position.z*pump.base.scale.z,"pump shotgun works the slide after a shot")
	pump.free();comet.free();quad.free()
	# Hands: every gun carries grip shapes; on a posed hero the palm lies on the
	# grip, the fingers wrap without sinking into it, the index finger reaches
	# the trigger and the wrist bend stays human.
	var hero=HeroCharacter.new();root.add_child(hero);hero.build(0,0,false)
	for wid in ["a1","c1","e1","e3","r1","r2","pistol","heavy_pistol","dual_pistols","h4","h5","h6","m1"]:
		var w=Catalog.get_weapon(wid)
		var gun=GunModel.new();gun.build(w,false);hero.hold(gun)
		var shapes:Dictionary=gun.get_meta("grip_shapes",{})
		expect(shapes.has("R") and shapes.R.has("half"),"grip shape on the shooting hand: "+w.name)
		var kind=GunLooks.hold_kind(w);if kind=="shoulder":kind="rifle"
		var s={"hold":kind,"hands":1.,"two_hands":true}
		# Fingers ease into a new grip over a few frames (finger memory).
		for i in range(12):hero.drive(1./30.,s)
		var handle=gun.right_grip.global_transform;var to_handle=Transform3D(handle.basis.orthonormalized(),handle.origin).affine_inverse()
		var ws=HeroIK.world_shape(handle,"pistol",shapes.get("R",{}))
		# 1.4.2: against the model's real surface (baked grip field): no finger
		# or thumb bone of either hand passes into the gun.
		var deepest=INF;var where=""
		for side in ["R","L"]:
			var g=gun.grip(side);var c=GripField.contact(gun,g.global_transform)
			if c.is_empty():continue
			var to_g=Transform3D(g.global_transform.basis.orthonormalized(),g.global_transform.origin).affine_inverse()
			var chains=HeroIK.finger_chains(hero,side)
			for finger in chains:
				for b in chains[finger].slice(1):
					var d=GripField.distance(c,to_g*hero.bone_world(b).origin)
					# 1.4.4: the thumb's bones lie deep in the thenar mass; its
					# centre line may sit up to 8 mm in where the pad presses on.
					if finger=="Thumb":d+=.004
					if d<deepest:deepest=d;where=side+" "+hero.skeleton.get_bone_name(b)
		expect(deepest>-.004,"fingers wrap the real grip surface without sinking in: %s (%.3f %s)"%[w.name,deepest,where])
		var wrist=hero.bone_world(hero.bone["Wrist.R"]);var fore=hero.bone_world(hero.bone["LowerArm.R"])
		var bend=(fore.basis.get_rotation_quaternion().inverse()*wrist.basis.get_rotation_quaternion())
		var twist=Quaternion(0.,bend.y,0.,bend.w).normalized();var swing=(twist.inverse()*bend).normalized()
		if swing.w<0.:swing=-swing
		expect(swing.get_angle()<=HeroIK.WRIST_LIMIT+.02,"wrist bend within human range: %s (%.2f rad)"%[w.name,swing.get_angle()])
		if ws.has("trigger"):
			var chain:Array=HeroIK.finger_chains(hero,"R").Index
			var tip=hero.bone_world(chain[chain.size()-1])*Vector3(0,.02,0)
			# 1.4.4: the firing hand may slide up to FIRING_SLIDE down the grip so the middle finger clears the guard.
			expect((to_handle*tip).distance_to(ws.trigger)<.045+HeroIK.FIRING_SLIDE*.5,"index finger at the trigger: %s (%.3f m)"%[w.name,(to_handle*tip).distance_to(ws.trigger)])
		# 1.4.2: no finger joint bends backwards (flexion is a rotation about -X),
		# on either hand; the arms stay outside the torso.
		var backward=0.
		for side in ["R","L"]:
			var chains:Dictionary=HeroIK.finger_chains(hero,side)
			for finger in chains:
				for b in chains[finger].slice(1):
					var rel:Quaternion=hero.skeleton.get_bone_rest(b).basis.get_rotation_quaternion().inverse()*hero.skeleton.get_bone_pose_rotation(b)
					if rel.w<0.:rel=-rel
					backward=maxf(backward,rel.x)
		expect(backward<.03,"no finger bent backwards: %s (%.3f)"%[w.name,backward])
		var torso=HeroIK.torso_frame(hero);var inside=0.
		for side in ["R","L"]:
			var s0=hero.bone_world(hero.bone["UpperArm."+side]).origin;var e0=hero.bone_world(hero.bone["LowerArm."+side]).origin;var w0=hero.bone_world(hero.bone["Wrist."+side]).origin
			for k in range(3,9):inside=maxf(inside,HeroIK.torso_depth(torso,s0.lerp(e0,k/8.)))
			for k in range(9):inside=maxf(inside,HeroIK.torso_depth(torso,e0.lerp(w0,k/8.)))
		expect(inside<.05,"arms outside the torso: %s (%.2f)"%[w.name,inside])
		gun.queue_free();await process_frame
	hero.queue_free()
	# Support hand: knuckles forward and across the handguard, forearm from below.
	var support:Basis=HeroIK.FRAMES.support.L
	expect(support.y.z<-.4 and support.y.x>.4 and support.y.y>0. and -support.z.y>.7,"support hand: knuckles forward-across-up, palm up")
	# First person: the arms come up from below the view (shoulders behind the eye).
	expect(Actor.VIEW_BODY_OFFSET.z>0.,"first-person shoulders sit behind the eye")
	# Rocket reload (1.4.2): underhand in a C (thumb under, fingers over the top); TETHER: a game-pad grip for both hands.
	var loader=GunModel.new();loader.build(Catalog.get_weapon("h4"),false);root.add_child(loader)
	var load_hand=ReloadMotion.support(loader,{"reload":.45,"rounds":0})
	# 1.4.4: a side C-grip (palm on the near side, fingers over the top, thumb under).
	expect(str(load_hand.get("style",""))=="pistol" and load_hand.get("basis",Basis.IDENTITY)==ReloadMotion.ROCKET_FIST,"rocket loading hand: a fist round the rocket body")
	var fist:Basis=ReloadMotion.ROCKET_FIST*HeroIK.FRAMES.pistol.L
	expect(fist.z.x<-.9 and fist.y.y>.9,"rocket fist: left palm on the rocket's near side, knuckles up over the top")
	loader.queue_free()
	var pad=GunModel.new();pad.build(Catalog.get_weapon("remote"),false);root.add_child(pad)
	expect(pad.get_meta("grip_styles",{})=={"R":"pistol","L":"pistol"} and pad.right_grip.position.y<-.03 and pad.left_grip.position.y<-.03,"TETHER: both fists on the grips under the pad")
	pad.queue_free()
	# Medkit carried low with both hands; the grenade fist closes on its body.
	var kit_holder=Node3D.new();root.add_child(kit_holder);var kit=GearModels.held(kit_holder,5,0)
	expect(kit.two_handed and kit.right.y<-.1 and float(kit.view_lift)>0.,"medkit carried low in both hands")
	var nade=GearModels.held(kit_holder,0,1)
	expect(nade.right.distance_to(Vector3(0,.02,-.02))<.01 and float(nade.grip.R.shape.half.x)>=.035,"grenade grip centred on its body")
	kit_holder.queue_free()
	# ATLAS: semi-sniper without optics; only snipers, DMRs and the laser rifle have scopes.
	var atlas=Catalog.get_weapon("a3")
	expect(bool(atlas.get("semi_scope",false)) and float(atlas.zoom)<58. and not SniperScope.overlay(atlas),"ATLAS zooms further than other rifles, without a scope overlay")
	expect(not "scope" in GunLooks.look(atlas).get("attach",[]),"ATLAS carries no scope")
	for wid in Catalog.weapons:
		var w=Catalog.weapons[wid]
		if w.get("kind","")!="gun":continue
		var scoped=SniperScope.overlay(w)
		expect(scoped==(w.get("category","") in ["저격소총","지정사수소총"] or w.get("laser",false)),"scope overlay only on snipers, DMRs and the laser: "+str(w.name))
	# DUET is held wide in third person too.
	var duet=GunModel.new();root.add_child(duet);duet.build(Catalog.get_weapon("dual_pistols"),false)
	expect(absf(duet.dual_guns[1].position.x)>=.25,"DUET pistols held apart")
	duet.free()
	# Glyphs: the symbol font covers what the menus use.
	var symbols:Font=load("res://assets/fonts/Symbols.ttf")
	for ch in "·−…◆●∞→✓⚠★×≥":expect(symbols.has_char(ch.unicode_at(0)),"symbol font has "+ch)
	# Gameplay: QUAD reload rule and the defusal fuse clock.
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	for i in range(6):await process_frame
	g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.mode=0;g.build_world();g.add_player(1,"P","t141")
	g.phase="combat";g.clock=100.;g.spawn(1)
	var p=g.players[1];var a=g.actors[1];p.protect=0.;p.alive=true;p.role=2;p.primary="h5";p.slot=0;p.owned_primary=true;p.mag["h5"]=2;p.reserve["h5"]=20;p.fire_ready=0.;p.reload=0.
	a.reset_view(0);await physics_frame
	# Reloading tube by tube; firing interrupts after a short settle and the reload does not resume by itself.
	g.begin_reload(1);expect(p.reload>g.clock and p.reload_count==1,"QUAD reloads one rocket at a time")
	a.input_state.fire=true;a.input_state.trigger_seq=1;g.process_trigger(1)
	expect(p.reload<=0. and p.fire_ready>=g.clock+.19,"firing mid-reload stops the reload with a 0.2 s settle")
	a.input_state.fire=false;g.clock+=.25
	var before=int(p.mag["h5"]);g.fire(1)
	expect(int(p.mag["h5"])==before-1 and p.reload<=0.,"a launcher with rockets left does not reload by itself after a shot")
	g.clock+=2.;p.mag["h5"]=1;p.fire_ready=0.;g.fire(1)
	expect(int(p.mag["h5"])==0 and p.reload>g.clock,"an empty launcher starts reloading")
	# Fully loaded tubes fire without the settle delay.
	p.reload=0.;p.mag["h5"]=4;p.fire_ready=0.;g.clock+=2.;a.input_state.trigger_seq=2;a.input_state.fire=true;g.process_trigger(1)
	expect(p.fire_ready<=g.clock+float(Catalog.get_weapon("h5").interval)+.001 and int(p.mag["h5"])==3,"fully loaded QUAD fires at once")
	a.input_state.fire=false
	g.options.mode=4;g.bomb.planted=true;g.bomb.time=17.4;g.remaining=-3.;g.ui.show_hud();g.ui.refresh()
	await process_frame;await process_frame
	expect("00:18" in str(g.ui.status.text) and "폭발" in str(g.ui.status.text),"planted charge: the HUD clock counts the fuse (%s)"%g.ui.status.text)
	expect("경기 시작" in g.ui.PRIMARY_ACTIONS and not ("다음 · 경기 시작" in g.ui.PRIMARY_ACTIONS),"bot battle starts with the plain 경기 시작 button")
	print("V141_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
