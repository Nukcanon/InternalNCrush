extends SceneTree
# 1.4.5: magazine travel by magazine height, aimed recoil kick, marker gadget
# cone / dwell / percent, spawn screens, forearm follow bend, loading thumb,
# load-round bullet cone, QUAD hand clearance, wrench clang on friendly turrets.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	for i in range(2):await process_frame
	# --- Marker gadget ---------------------------------------------------------
	expect(is_equal_approx(MarkerTracker.DWELL_SECONDS,1.8),"marker dwell is 1.8 s")
	var sniper=Catalog.get_weapon("r1");var dmr=Catalog.get_weapon("r3")
	expect(is_equal_approx(MarkerTracker.half_angle(sniper),MarkerTracker.HALF_ANGLE_DEGREES*1.5),"sniper scopes: 1.5x the base cone")
	expect(is_equal_approx(MarkerTracker.half_angle(dmr),MarkerTracker.HALF_ANGLE_DEGREES*2.),"designated marksman rifles: 2x the base cone")
	expect(str(dmr.get("category",""))=="지정사수소총","ECHO is a designated marksman rifle")
	var hud=FileAccess.get_file_as_string("res://scripts/hud_symbols.gd");var reticle=FileAccess.get_file_as_string("res://scripts/reticle.gd")
	expect(not hud.contains('"표식 추적 %d%%"'),"no marker percentage line in the HUD details")
	expect(reticle.contains('"%d%%"%int(clampf(float(p.get("marker_progress",0.))/MarkerTracker.DWELL_SECONDS'),"reticle shows the marker progress as a percentage over the target")
	# --- Magazine travel scales with the magazine --------------------------------
	var pistol=GunModel.new();root.add_child(pistol);pistol.build(Catalog.get_weapon("pistol"),true)
	var rifle=GunModel.new();root.add_child(rifle);rifle.build(Catalog.get_weapon("a1"),true)
	expect(pistol.mag_height>.03 and rifle.mag_height>pistol.mag_height*1.5,"rifle magazine is taller than the pistol's (%.3f vs %.3f)"%[rifle.mag_height,pistol.mag_height])
	var pt=ReloadMotion.mag_travel(pistol,.4);var rt=ReloadMotion.mag_travel(rifle,.4)
	expect(pt.y<0. and rt.y<pt.y and absf(pt.y)>=pistol.mag_height*1.2 and absf(pt.y)<pistol.mag_height*1.6,"each magazine drops by about its own height (pistol %.3f, rifle %.3f)"%[pt.y,rt.y])
	expect(ReloadMotion.mag_travel(rifle,0.).length()<.001 and ReloadMotion.mag_travel(rifle,.9).length()<.001,"the magazine is home at the start and once seated")
	pistol.queue_free();rifle.queue_free()
	# --- Aimed recoil ------------------------------------------------------------
	expect(Actor.ADS_KICK_PITCH<.06 and Actor.ADS_KICK_BACK>.01 and Actor.ADS_KICK_DROP>=0.,"aimed recoil pitches little and pushes the gun back")
	# --- Arms --------------------------------------------------------------------
	expect(Actor.FOLLOW_BEND>.3 and Actor.FOLLOW_BEND<.7 and Actor.FOLLOW_DROP>.1 and Actor.FOLLOW_BEND_DUAL<Actor.FOLLOW_BEND and Actor.FP_UPPER_DUAL_X>.2,"forearm tilted below the hand; DUET arms opened out with less bend")
	expect(HeroCharacter.FP_WRIST_MATCH>1. and HeroCharacter.FP_WRIST_MATCH<1.3 and is_equal_approx(Actor.VIEW_HAND,HeroCharacter.FP_HAND),"forearm tapers to the hand's own wrist girth")
	expect(HeroIK.THUMB_PINCH_BASE<-.4,"loading thumb lies forward along the round")
	expect(GunModel.LOAD_SHOW<.2,"the rocket is in the hand almost from the start of the cycle")
	var gm=FileAccess.get_file_as_string("res://scripts/weapons/gun_model.gd")
	expect(gm.contains("Vector3(-PI/2,0,0),r*.35,10)"),"load-round bullet cone points forward")
	expect(gm.contains("point.z=maxf(point.z,rear+.09)"),"QUAD loading fist stays a hand and a half behind the tubes")
	# --- Spawn screens -----------------------------------------------------------
	expect(DistrictLayout.SPAWN_SCREENS.has(1) and DistrictLayout.SPAWN_SCREENS.has(8) and not DistrictLayout.SPAWN_SCREENS.has(4),"spawn screens on the maps whose street ran spawn to spawn")
	var plan=DistrictLayout.read_plan(8)
	var here=Vector2(plan.spawns[0][0],plan.spawns[0][1]);var there=Vector2(plan.spawns[1][0],plan.spawns[1][1]);var dir=(there-here).normalized()
	var span=DistrictLayout.lane_extent(plan,here+dir*DistrictLayout.SCREEN_DISTANCE,Vector2(-dir.y,dir.x))
	expect(span.size()==2 and float(span[1])-float(span[0])>3.,"the street in front of a spawn is measured (%s)"%str(span))
	expect(ArenaCache.REVISION>=159,"arena cache revision bumped for the new geometry")
	# --- Wrench on a friendly turret -------------------------------------------
	var mc=FileAccess.get_file_as_string("res://scripts/melee_combat.gd")
	expect(mc.contains('g.effect.rpc("melee_repair",origin,hit.position,id)\n\t\t\tif gain>0.:') or mc.contains('g.effect.rpc("melee_repair",origin,hit.position,id)\r\n\t\t\tif gain>0.:'),"the clang plays on every friendly turret hit, the repair text only when it repaired")
	# --- Sounds ------------------------------------------------------------------
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	expect(float(manifest.reload.duration)>.3 and float(manifest.rocket_insert.duration)>.6 and float(manifest.wrench_repair.duration)>.5,"recorded reload / rocket / clang clips replaced the synthetic ones")
	# --- Muzzle on the aim line, LINK range, killcam view model ------------------
	var ac=FileAccess.get_file_as_string("res://scripts/actor.gd")
	expect(not ac.contains("rotation_target.x-=(.0 if throwable") and ac.contains("rotation_target.y+=(HIP_YAW_GEAR if gadget_up else 0.)"),"guns keep the barrel parallel to the aim at the hip (no dip, no turn-in)")
	expect(is_equal_approx(MedicLink.RANGE,16.) and int(Catalog.get_weapon("m1").reach)==16,"LINK heals to 16 m")
	var kr=FileAccess.get_file_as_string("res://scripts/kill_replay.gd")
	expect(kr.contains("Actor.VIEW_BODY_SCALE*Actor.VIEW_DEPTH") and kr.contains('"fp_follow",Actor.fp_follow_for(') and kr.contains("Actor.hip_base_for(spec)") and kr.contains("Actor.view_weapon_scale(spec)"),"the kill replay builds its first-person view like live play")
	expect(Actor.hip_base_for(Catalog.get_weapon("pistol")).y>Actor.hip_base_for(Catalog.get_weapon("a1")).y and Actor.fp_follow_for("pistol",true,1.).has("L") and not Actor.fp_follow_for("rifle",false,1.).has("L"),"shared hip anchor and arm-follow helpers")
	var hc=FileAccess.get_file_as_string("res://scripts/hero/hero_character.gd")
	expect(HeroCharacter.FP_ELBOW_FILL>=.2 and hc.contains("2.*sqrt(maxf(0.,upper*fore))"),"bare elbows filled to about 1.2x across the joint zone")
	# --- Covered-room masses stand on pillars (baked supports) --------------------
	var plan7=DistrictLayout.read_plan(7)
	var plan13=DistrictLayout.read_plan(13)
	expect(plan7.get("supports",[]).size()>=1 and plan13.get("supports",[]).size()>=8 and float(plan13.supports[0][2])>3. and plan13.supports[0].size()>4,"covered-room openings without a wall beneath stand on pillars (map 7: %d, map 13: %d)"%[plan7.get("supports",[]).size(),plan13.get("supports",[]).size()])
	expect(is_equal_approx(DistrictProps.SINK_LIMIT,.02),"props may not sink into walls or each other (2 cm)")
	var ik=FileAccess.get_file_as_string("res://scripts/hero/hero_ik.gd")
	expect(ik.contains('var pinch=style=="hold" and maxf(half.x,half.y)<.03'),"a long thin round still gets the loading thumb")
	expect(HeroIK.THUMB_LOAD_TIP<-.5 and HeroIK.THUMB_LOAD[0]>0.,"the loading thumb stands as before and bends its tip forward toward the gun")
	expect(Actor.PAIR_HIP>=.5 and Actor.PAIR_AIM>.3,"DUET pistols held wider apart")
	# Forearm twist bones in first person: the elbow no longer collapses under roll.
	var fp_hero=HeroCharacter.new();root.add_child(fp_hero);fp_hero.build(1,0,false);fp_hero.first_person_only()
	var fp_arms:MeshInstance3D=fp_hero.skeleton.get_node("FPArms")
	var body_binds=0
	for m in fp_hero.meshes():
		if str(m.name).ends_with("_Body") and m.skin:body_binds=m.skin.get_bind_count()
	expect(fp_hero.skeleton.find_bone("ForeTwist0.L")>=0 and fp_hero.skeleton.find_bone("ForeTwist2.R")>=0 and fp_arms.skin.get_bind_count()==body_binds+HeroCharacter.TWIST_LEVELS*2,"first-person arms carry forearm twist bones")
	var lower=fp_hero.bone["LowerArm.L"]
	fp_hero.skeleton.set_bone_pose_rotation(lower,fp_hero.skeleton.get_bone_rest(lower).basis.get_rotation_quaternion()*Quaternion(Vector3.UP,1.2));fp_hero.update_twist_bones()
	var t0:Quaternion=fp_hero.skeleton.get_bone_pose_rotation(fp_hero.bone["ForeTwist0.L"])
	expect(absf(t0.get_angle()-1.2)<.01,"the elbow-side twist bone takes the whole roll back (%.2f)"%t0.get_angle())
	fp_hero.queue_free()
	expect(ArenaCache.REVISION>=160,"arena cache revision bumped for the pillars")
	# --- Round 4 (2026-10-02) ------------------------------------------------------
	expect(ArenaCache.REVISION>=161,"arena cache revision bumped for the remodelled props")
	expect(not FileAccess.get_file_as_string("res://scripts/actor.gd").contains('tag.text=("??"'),"ally name tags keep their marker glyphs (no '??')")
	var turret_src=FileAccess.get_file_as_string("res://scripts/turret_logic.gd")
	expect(turret_src.contains("static func behind_cover") and not turret_src.contains("COVER_REACH"),"turrets 1-2 never shoot over cover, whatever the distance (no extra range rule)")
	expect(GadgetVisual.field_key(3,1,true)==GadgetVisual.field_key(3,0,true) and GripField.lookup(GadgetVisual.field_key(3,0,true)).size()>0,"the carried turret has one baked grip field whichever gadget is selected")
	expect(GripField.lookup(GadgetVisual.field_key(0,0,false)).size()>0 and GripField.lookup(GadgetVisual.field_key(1,1,false)).size()>0,"held gear (plate, marker) has baked grip fields")
	var game_src=FileAccess.get_file_as_string("res://scripts/game.gd")
	expect(game_src.contains("heal_marks.size()<4"),"a heal shot shows at most four green crosses")
	var fx_src=FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	expect(fx_src.contains("var spin=randf_range(1.,2.2)*(1. if randf()<.5 else -1.)") and fx_src.contains("randf_range(.32,.5)"),"heal crosses turn at a random speed and way round while rising")
	var frag_scene=GunModel.base_scene("Grenade").instantiate();var fire_scene=GunModel.base_scene("FireGrenade").instantiate()
	var frag_parts=GearModels.split_ring(frag_scene.find_children("*","MeshInstance3D",true,false)[0].mesh,"frag")
	var fire_parts=GearModels.split_ring(fire_scene.find_children("*","MeshInstance3D",true,false)[0].mesh,"fire")
	frag_scene.free();fire_scene.free()
	expect(frag_parts.size()==2 and fire_parts.size()==2,"grenades carry a separate pull ring for the pin pull")
	var cook0=Actor.cook_pose(0.);var cook_end=Actor.cook_pose(Actor.COCK_TIME+.1);var cook_pin=Actor.cook_pose(Actor.PIN_REACH+.05)
	expect(Vector3(cook0[0]).length()<.001 and Vector3(cook_end[0]).is_equal_approx(Actor.COCK_OFFSET) and Vector3(cook_pin[0]).distance_to(Actor.PIN_OFFSET)<.01,"cooking: hands meet for the pin, then the grenade is drawn back")
	expect(HeroIK.CURLS.has("flat") and HeroIK.CURLS.has("pinch"),"the free hand opens flat to aim and pinches the ring")
	var lying=0
	for id in range(40):if InteractiveProp.tyre_lying(13,id):lying+=1
	expect(lying>8 and lying<32,"junk tyres lie flat or stand (%d of 40 lying)"%lying)
	var old_sizes={"vehicle_pickup":5.15,"vehicle_van":5.25,"vehicle_delivery":5.86,"vehicle_flatbed":6.06,"vehicle_utility":4.24,"vehicle_dump":6.46,"vehicle_compact":3.3,"vehicle_hatch":3.85,"vehicle_tow":6.87}
	var too_long=[]
	for kind in old_sizes:
		var kit=DistrictFacade.Kit.new();var box:AABB=PropModels.build(kit,kind,3)
		var mesh=kit.detail.commit();var length=mesh.get_aabb().size.x
		if not PropModels.has(kind) or length>float(old_sizes[kind])+.05 or box.size.x>float(old_sizes[kind])+.05:too_long.append("%s %.2f"%[kind,length])
	expect(too_long.is_empty(),"remodelled vehicles fit the old footprints %s"%str(too_long))
	for kind in ["drums","cask_pair","cable_drum","watertank_floor"]:
		var kit=DistrictFacade.Kit.new();PropModels.build(kit,kind,0)
		expect(kit.tris>200,"%s remodelled (%d triangles)"%[kind,kit.tris])
	var tyre_kit=DistrictFacade.Kit.new();PropModels.tyre(tyre_kit)
	expect(tyre_kit.tris<=12*9*2,"a loose tyre is a cheap 12-sided ring (%d triangles)"%tyre_kit.tris)
	expect(HeroIK.TP_SOLVES_PER_FRAME>=1 and HeroIK.TP_SOLVE_GAP>0,"third-person finger solves are budgeted per frame")
	expect(is_equal_approx(GunModel.PAIR_CONVERGE,Actor.HIP_CONVERGE),"DUET pistols turn in to cross the aim line where the hip guns do")
	# --- Shotgun pattern: pellets fill the cone (measured through Game.fire) ------
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.map_random=false;g.options.map=13;g.build_world();g.phase="lobby";g.add_player(1,"TEST","test_v145");g.phase="combat";g.clock=100.
	var p=g.players[1];var actor=g.actors[1];var ends=[];g.set_meta("probe_pellets",ends)
	var at=Vector3(0,.1,g.arena.bounds.y-7);actor.position=at;actor.reset_view(0);p.protect=0.;p.role=2;p.slot=0;p.primary="e1";g.equip_ammo(p)
	g.arena.box(at+Vector3(0,3.,-8.5),Vector3(12,8,1),Color.GRAY)
	await physics_frame;await physics_frame
	for i in range(60):actor.simulate(.016,g.clock,false);await physics_frame
	for shot in range(6):
		p.fire_ready=0.;p.spray_phase=0.;p.bloom=0.;p.reload=0.;p.mag.e1=10;g.clock+=1.;g.fire(1)
	var rs=[];var eye=actor.eye()
	for e in ends:rs.append(Vector2(e.x-eye.x,e.y-eye.y).length())
	rs.sort()
	var cone=8.5*tan(deg_to_rad(actor.spread_angle));var mean=0.
	for r in rs:mean+=r
	mean/=maxf(1.,rs.size())
	var core=rs.filter(func(r):return r<cone*.3).size()
	expect(rs.size()==60 and rs[-1]>cone*.8 and mean>cone*.5 and core<rs.size()*.25,"PULSE pellets fill the whole cone at 8 m (cone %.2f m: mean %.2f, max %.2f, %d of %d in the inner 30%%)"%[cone,mean,rs[-1] if rs.size() else 0.,core,rs.size()])
	g.leave_game();g.free();await process_frame
	print("V145_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
