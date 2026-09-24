extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func recovery(w:Dictionary,shots:int) -> float:
	var p={"bloom":minf(w.bloom_max,w.shot_bloom*shots),"spray_phase":float(shots),"shot_time":0.}
	var elapsed=0.
	while elapsed<3. and (p.bloom>.001 or p.spray_phase>.001):
		elapsed+=.005;AimModel.recover(p,w,.005,elapsed)
	return elapsed
func run():
	Catalog.load_all();var report={}
	for id in Catalog.weapons:
		var w=Catalog.weapons[id]
		if w.kind!="gun":continue
		var short_burst=recovery(w,3);var long_burst=recovery(w,12)
		expect(short_burst<.65 and long_burst>short_burst,"burst recovery rewards short bursts: "+id)
		var moving=0;var stopped=0
		for i in range(120):
			var motion=BotAgent.combat_strafe(w,10.,i*.05,-3,1,true)
			if absf(motion)>.01:moving+=1
			else:stopped+=1
		expect(moving>0 and stopped>0,"bots alternate movement and stationary fire: "+id)
		expect(BotAgent.combat_strafe(w,10.,2.,0,0,true)<BotAgent.combat_strafe(w,10.,2.,0,2,true),"difficulty changes combat movement: "+id)
		if float(w.zoom)<=38:expect(BotAgent.combat_strafe(w,30.,2.,0,2,true)==0.,"scoped long shots favor a planted stance: "+id)
		report[id]={"three_shot_reset_seconds":short_burst,"twelve_shot_reset_seconds":long_burst,"recovery_delay":w.recovery_delay,"pattern_recovery":w.pattern_recovery}
	for id in ["a1","a2","r2","e1","pistol"]:
		var weapon=WeaponVisual.new();root.add_child(weapon);weapon.build(Catalog.get_weapon(id),true)
		for hand in [-1,1]:
			weapon.scale.x=hand
			for phase in [-1.,0.,.25,.5,.75,1.]:
				weapon.animate_reload(phase,1.,.04)
				for rig in [weapon.support_rig,weapon.firing_rig]:
					for finger in rig.fingers:
						var curl:Vector3=finger.get_meta("joint_flexion")
						expect(curl.x>=0 and curl.y>=0 and curl.z>=0 and curl.x<=1.35 and curl.y<=1.65 and curl.z<=1.2,"anatomical flexion for "+id)
		weapon.free()
	DirAccess.make_dir_recursive_absolute("res://../validation")
	FileAccess.open("res://../validation/v104-recovery.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("COMBAT_V104_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
