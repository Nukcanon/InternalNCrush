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
	print("V145_RESULT %d/%d"%[checks-failures,checks])
	quit(1 if failures>0 else 0)
