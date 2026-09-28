extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	Catalog.load_all()
	var audio_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"))
	for key in ["ui","heal","hurt","explosion","laser_vent"]:expect(VocalGunfire.family(key,audio_catalog)=="","voice option changes firearm sounds only: "+key)
	for pair in [["gun_pistol","pistol"],["gun_h1","machinegun"],["gun_r2","sniper"],["gun_e1","shotgun"],["laser_fire","energy"],["link_fire","energy"]]:expect(VocalGunfire.family(pair[0],audio_catalog)==pair[1],"vocal weapon category "+pair[0])
	expect(Catalog.get_weapon("h1").mag==90 and is_equal_approx(CombatBalance.sustained_rpm(Catalog.get_weapon("h1")),450.),"ANCHOR capacity/rate")
	expect(SniperScope.overlay(Catalog.get_weapon("h6")) and SniperScope.fov({},Catalog.get_weapon("h6"))>38.,"ARC rangefinder is inside a low-magnification optic")
	expect(Catalog.get_weapon("h2").mag==120 and is_equal_approx(CombatBalance.sustained_rpm(Catalog.get_weapon("h2")),400.),"BASTION capacity/rate")
	for id in ["a1","pistol","r1","e2"]:
		var w=Catalog.get_weapon(id)
		expect(MagazineReload.capacity(w,1)==int(w.mag)+1 and MagazineReload.capacity(w,0)==int(w.mag),"chamber conservation "+id)
	for id in ["heavy_pistol","h4","h5","e1","e3","h6","h1"]:expect(MagazineReload.capacity(Catalog.get_weapon(id),1)==int(Catalog.get_weapon(id).mag),"no extra chamber "+id)
	expect(not str(ReloadAudio.cues(Catalog.get_weapon("a1"),10,true)).contains("bolt"),"tactical reload omits bolt cue")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.local_id=1;g.dedicated=true;g.phase="combat";g.options=Rules.default_options();g.options.bots=0;g.options.map_random=false
	expect(g.profile.has("gunfire_reduction") and not g.profile.gunfire_reduction,"vocal option persists and defaults off")
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false
	for id in [1,2,3]:g.add_player(id,"Test"+str(id),"test"+str(id))
	var p=g.players[1];var q=g.players[2];var z=g.players[3];var a=g.actors[1]
	g.clock=100.;p.alive=true;p.team=0;p.protect=0.;p.role=1;p.gadget=0;p.gadget_count=1;p.slot=0;p.primary="r1";p.reload=0.;p.flash=0.;p.owned_gadget=true
	for id in [2,3]:g.players[id].alive=true;g.players[id].team=1;g.players[id].protect=0.;g.players[id].cleanse=0.;g.players[id].mark=0.;g.players[id].reveal_to={}
	a.position=Vector3(0,60,0);a.aim_yaw=0.;a.aim_pitch=0.;a.aim_progress=1.;a.input_state.ads=true
	g.actors[2].position=Vector3(0,60.25,-30);g.actors[3].position=Vector3(.12,60.25,-40)
	await physics_frame
	for i in range(7):MarkerTracker.tick(g,1,.1)
	expect(p.marker_target==2,"nearest enemy selected")
	g.actors[3].position.z=-20
	for i in range(7):MarkerTracker.tick(g,1,.1)
	expect(p.marker_target==2 and q.mark==0.,"closer entrant cannot steal partial lock")
	MarkerTracker.tick(g,1,.1);expect(q.mark==106.,"mark at 1.5 seconds")
	MarkerTracker.tick(g,1,.1);expect(p.marker_target==3,"marked target excluded and next selected")
	a.aim_yaw=.4;MarkerTracker.tick(g,1,.1);expect(p.marker_progress==0. and p.marker_target==0,"cone exit resets timer")
	a.aim_yaw=0.;g.clock=107.;expect(MarkerTracker.select_target(g,1)==3,"expired marks eligible again by distance")
	p.primary="a1";p.mag.a1=7;p.reserve.a1=60;p.reload=0.;g.begin_reload(1);g.clock=p.reload;MagazineReload.finish(g,1)
	expect(p.mag.a1==31 and p.reserve.a1==36,"tactical reload transfers 24 existing rounds without creating ammo")
	p.primary="h5";p.mag.h5=0;p.reserve.h5=4;p.reload=0.;g.begin_reload(1);g.clock=p.reload;MagazineReload.finish(g,1)
	expect(p.mag.h5==1 and p.reserve.h5==3 and p.reload>g.clock,"QUAD loads one at a time and continues")
	p.fire_ready=0.;p.switch_until=0.;a.last_sprint=false;a.sprint_release=0.;a.input_state.fire=true;a.input_state.trigger_seq=1;p.trigger_seen=0;p.fire_prev=false;g.process_trigger(1)
	expect(p.mag.h5==0 and g.rockets.size()==1,"QUAD fires an inserted round during reload")
	p.role=2;p.primary="h6";p.mag.h6=500.;p.reload=0.;p.switch_until=0.;p.laser_heat=0.;p.laser_lock=0.;p.fire_ready=0.;a.last_sprint=false;a.sprint_release=0.;a.input_state.fire=true;a.input_state.ads=false;a.aim_yaw=PI
	for i in range(32):g.clock+=.1;LaserCombat.tick(g,1,.1)
	expect(is_equal_approx(p.laser_heat,1.) and p.laser_lock>g.clock,"laser overheats at 3.2 seconds")
	expect(absf(float(p.mag.h6)-180.)<.01,"battery consumed by firing duration")
	var rounds=float(p.mag.h6)
	for i in range(10):g.clock+=.1;LaserCombat.tick(g,1,.1)
	expect(is_equal_approx(float(p.mag.h6),rounds) and absf(float(p.laser_heat)-.5)<.01,"locked laser cools and cannot fire")
	a.input_state.fire=false
	for i in range(11):g.clock+=.1;LaserCombat.tick(g,1,.1)
	expect(p.laser_heat<.001,"overheat cooldown finishes at zero")
	expect(LaserCombat.dps(0.)==60. and LaserCombat.dps(.98)==120.,"heat damage endpoints")
	expect(is_equal_approx(CombatBalance.range_factor(Catalog.get_weapon("h6"),100.),1.) and is_equal_approx(CombatBalance.range_factor(Catalog.get_weapon("h6"),150.),.3),"laser range endpoints")
	var reticle=load("res://scripts/reticle.gd")
	expect(reticle.distance_text(1234.56)=="1234.6 m" and reticle.distance_text(10000.)=="∞ m","rangefinder formatting and maximum")
	g.options.mode=4;g.options.map=23;g.arena.map_index=23;g.phase="combat";g.bomb.buy_until=g.clock+60.;p.alive=true;p.lives=0
	expect(not RedeployRules.available(g,p),"defusal redeploy hidden when no personal respawns remain")
	var selection={"role":int(p.role),"primary":"h6","secondary":"pistol","armor":0,"gadget":-1,"immediate":true,"redeploy_confirmed":true,"confirmed":true}
	var deaths=int(p.deaths);g.apply_loadout(1,selection)
	expect(int(p.deaths)==deaths and p.alive,"server rejects defusal redeploy without lives")
	p.lives=1;var center=MatchFlow.spawn_rect(g,int(p.team)).get_center();a.position=Vector3(center.x,0,center.y)
	expect(RedeployRules.available(g,p) and DefusalEconomy.can_buy(g,1),"one remaining life enables redeploy and own spawn allows purchase")
	a.position.x+=100.;expect(not DefusalEconomy.can_buy(g,1),"server disallows purchase outside own spawn")
	a.position=Vector3(center.x,0,center.y);p.redeploy_ready=0.;p.cash=8000;p.secondary="pistol";p.gadget=-1
	g.arena.spawn_points=[[Vector3(center.x,0,center.y)],[Vector3(center.x+30,0,center.y)]]
	g.apply_loadout(1,selection)
	expect(int(p.lives)==0 and int(p.deaths)==deaths+1 and p.alive,"defusal redeploy consumes the last life exactly once")
	expect(p.primary=="h6","redeploy purchases selected weapon at spawn: primary=%s position=%s cash=%s"%[p.primary,a.position,p.cash])
	expect(not RedeployRules.available(g,p),"redeploy button unavailable after final respawn is spent")
	p.redeploy_ready=g.clock+15.;expect(RedeployRules.wait_seconds(g,p)==15.,"redeploy cooldown authoritative")
	g.options.practice=true;expect(RedeployRules.wait_seconds(g,p)==0.,"practice bypasses cooldown")
	g.options.practice=false
	g.options.rounds=8;g.round_no=5;g.scores=[0,5]
	expect(DefusalMatch.decided(g) and MatchFlow.at_limit(g),"8-round match finishes immediately at fifth win")
	g.round_no=8;g.scores=[4,4];expect(not DefusalMatch.decided(g),"4-4 requires deciding round")
	g.round_no=9;g.scores=[4,5];expect(DefusalMatch.decided(g),"deciding round ends tied regulation")
	g.phase="combat";expect(not TeamBalance.allowed(g,2,2) and TeamBalance.allowed(g,1,2),"defusal team locked except room host")
	p.lives=0;g.round_no=4;g.scores=[0,4];g.begin_round()
	expect(p.lives==0 and p.primary=="h6","halftime neither restores respawn budget nor removes survivor weapon")
	g.phase="combat";var departed=g.players[2].duplicate(true);departed.alive=false;departed.lives=0;departed.can_respawn=false
	TeamBalance.replace_departed(g,departed,Vector3(1,2,3));var replacements=TeamBalance.replacement_ids(g)
	expect(replacements.size()==1 and g.bot_agents[replacements[0]].difficulty==2,"departed player replaced by hard bot")
	expect(not g.players[replacements[0]].alive and g.players[replacements[0]].lives==0,"replacement cannot revive eliminated player or replenish lives")
	g.queue_free();await process_frame;print("COMBAT_REFRESH ",checks," checks / ",failures," failures");quit(1 if failures else 0)
