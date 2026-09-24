extends SceneTree
# Repeatable torso-target accuracy audit. It measures cone loss separately from
# uncompensated recoil; real player aim, armor, movement and cover remain external.
func _initialize():call_deferred("run")
func ideal_ttk(w:Dictionary,distance:float) -> float:
	var damage=CombatBalance.damage_at(w,distance)*int(w.pellets)
	if damage<=0.:return -1.
	var gaps=maxi(0,ceili(100./damage)-1)
	var bursts=int(gaps/3)
	return bursts*(float(w.interval)*2.+float(w.get("burst_pause",.3)))+(gaps%3)*float(w.interval) if w.get("fire_mode","")=="burst" else gaps*float(w.interval)
func accuracy(w:Dictionary,distance:float,speed:float,burst:bool,compensated:bool) -> float:
	var p={"bloom":0.,"spray_phase":0.,"shot_time":-100.};var clock=0.;var hits=0;var total=0
	var rng=RandomNumberGenerator.new();rng.seed=103
	for shot in range(mini(int(w.mag),24)):
		var cone=AimModel.spread(w,speed,true,false,false,true,p.bloom)
		var offset=Vector2.ZERO if compensated else AimModel.current_spray(w,p,1.)
		var forward=Basis(Vector3.UP,-deg_to_rad(offset.x))*Basis(Vector3.RIGHT,deg_to_rad(offset.y))*Vector3.FORWARD
		for sample in range(384):
			var dir=AimModel.cone_direction(forward,cone,rng.randf(),rng.randf());var point=dir*(distance/maxf(.01,-dir.z))
			if absf(point.x)<.23 and absf(point.y)<.36:hits+=1
			total+=1
		p.shot_time=clock;p.bloom=minf(float(w.bloom_max),p.bloom+float(w.shot_bloom));p.spray_phase+=1.
		var wait=float(w.interval)
		if w.get("fire_mode","")=="burst" and shot%3==2:wait=float(w.get("burst_pause",.3))
		if burst and shot%3==2:wait=maxf(wait,.38)
		var elapsed=0.
		while elapsed<wait:
			var dt=minf(1./120.,wait-elapsed);elapsed+=dt;clock+=dt;AimModel.recover(p,w,dt,clock)
	return snappedf(float(hits)/total,.001)
func run():
	Catalog.load_all();var report={"version":Rules.VERSION,"target":"0.46m wide x 0.72m torso rectangle, center aim, full ADS, first 24 rounds; 384 fixed-seed samples/round", "assumptions":"Accuracy excludes target movement and cover. Compensated columns assume the player cancels the deterministic recoil. Burst pauses are 0.38s after each 3 rounds. TTK assumes all pellets hit, 100 HP and no armor.","weapons":[]}
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.kind!="gun":continue
		var row={"id":id,"name":w.name,"dps":snappedf(CombatBalance.firing_dps(w),.1),"sustained_dps":snappedf(CombatBalance.sustained_dps(w),.1),"spray_build_seconds":w.spray_build_seconds,"recovery_delay":w.recovery_delay,"range":[]}
		for distance in [5.,15.,30.,60.]:
			row.range.append({"meters":distance,"torso_damage":snappedf(CombatBalance.damage_at(w,distance),.01),"head_damage":snappedf(CombatBalance.damage_at(w,distance,"head"),.01),"ideal_ttk":snappedf(ideal_ttk(w,distance),.001),"hold_compensated":accuracy(w,distance,0.,false,true),"burst_compensated":accuracy(w,distance,0.,true,true),"strafe_compensated":accuracy(w,distance,3.7,false,true),"hold_uncompensated":accuracy(w,distance,0.,false,false)})
		report.weapons.append(row);print("BALANCE ",id," DPS=",row.dps," sustained=",row.sustained_dps," 15m_hold=",row.range[1].hold_compensated," burst=",row.range[1].burst_compensated)
	FileAccess.open("res://../validation/v103-balance-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("BALANCE_AUDIT_COMPLETE ",report.weapons.size());quit()
