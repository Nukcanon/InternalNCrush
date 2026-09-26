extends SceneTree
var checks=0
var failures=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func _initialize():call_deferred("run")
func run():
	expect(Rules.VERSION==ProjectSettings.get_setting("application/config/version"),"visible version matches packaged game version")
	TouchControls.supported_cache=0
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Medic","m");g.add_player(2,"Ally","a");g.add_player(3,"Enemy","e")
	g.phase="combat";g.clock=100.;g.options.mode=0;g.options.friendly=false
	var p=g.players[1];var q=g.players[2];var e=g.players[3];var a=g.actors[1];var b=g.actors[2]
	p.role=5;p.primary="m1";p.slot=0;p.team=0;q.team=0;e.team=1;p.protect=0.;q.protect=0.;e.protect=0.;p.placing="";p.reload=0.;p.energy=180.;q.hp=10.;q.armor=0.;a.position=Vector3.ZERO;b.position=Vector3(0,0,-12);g.actors[3].position=Vector3(20,0,0)
	a.aim_yaw=0.;a.aim_pitch=0.;a.input_state.yaw=0.;a.input_state.pitch=0.;a.input_state.fire=true;a.last_sprint=false;a.sprint_release=0.
	await physics_frame;await physics_frame
	for i in range(60):g.clock+=1./60.;MedicLink.tick(g,1,1./60.)
	expect(is_equal_approx(q.hp,35.),"LINK heals 25 per second at 12 metres")
	expect(int(p.link_target)==2,"initial acquisition links teammate")
	a.aim_yaw=deg_to_rad(99.);a.input_state.yaw=a.aim_yaw
	expect(MedicLink.valid(g,1,2),"link retains 99 degree yaw")
	g.clock+=.1;MedicLink.tick(g,1,.1);expect(q.hp>35.,"off-crosshair link still heals")
	a.aim_yaw=deg_to_rad(101.);expect(not MedicLink.valid(g,1,2),"101 degree yaw breaks link")
	a.aim_yaw=0.;a.input_state.yaw=0.;b.position.z=-15.1;expect(not MedicLink.valid(g,1,2),"range over 15 breaks link");b.position.z=-12
	a.input_state.fire=false;MedicLink.tick(g,1,.1);expect(p.link_target==0,"release click clears link")
	TouchControls.supported_cache=1;g.profile.touch_auto_fire=true
	expect(TouchAim.can_auto_fire(g,a),"mobile auto starts LINK on ally")
	p.link_target=2;a.input_state.yaw=deg_to_rad(60.);a.aim_yaw=deg_to_rad(60.);expect(TouchAim.can_auto_fire(g,a),"mobile auto sustains latched link")
	a.input_state.yaw=0.;a.aim_yaw=0.;p.link_target=0
	var wall=StaticBody3D.new();g.add_child(wall);wall.position=Vector3(0,1,-6)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(4,3,.2);shape.shape=box;wall.add_child(shape);await physics_frame
	expect(not MedicLink.valid(g,1,2),"wall blocks link")
	wall.free();await physics_frame
	b.position=Vector3(0,0,-3);a.aim_pitch=atan2(1.15-a.eye().y,3.);a.input_state.pitch=a.aim_pitch
	for wid in ["m2","m3"]:
		p.primary=wid;p.slot=0;p.fire_ready=0.;p.reload=0.;p.mag[wid]=10;p.reserve[wid]=50;p.bloom=0.;p.spray_phase=0.;a.spread_angle=0.;q.hp=10.;q.last_hit=g.clock;q.healing_until=0.
		await physics_frame;g.fire(1)
		expect(is_equal_approx(q.hp,15. if wid=="m2" else 40.),wid+" heals expected amount, shotgun capped at 30")
		p.reload=0.;expect(TouchAim.can_auto_fire(g,a),wid+" auto fires at ally")
		q.team=1;expect(TouchAim.can_auto_fire(g,a),wid+" auto fires at enemy");q.team=0
		var w=Catalog.get_weapon(wid);expect(CombatBalance.range_factor(w,50.)<CombatBalance.range_factor(w,1.),wid+" healing decreases with distance")
	expect(is_equal_approx(CombatBalance.firing_dps(Catalog.get_weapon("m3")),CombatBalance.firing_dps(Catalog.get_weapon("e1"))*.8),"medical shotgun 80 percent ordinary shotgun DPS")
	for role in range(6):
		p.role=role;p.gadget=8;GadgetLoadout.reset(p);expect(p.gadget_count==2 and GrenadeLogic.equipped(p),"all roles select frag "+str(role))
	p.role=4
	for variant in [0,1]:
		p.gadget=variant;GadgetLoadout.reset(p);expect(p.smoke+p.flash_count==3 and (p.smoke==0 or p.flash_count==0),"controller selects one grenade kind")
	expect(AbilityBalance.flash_duration(1.,1.)>3. and AbilityBalance.flash_duration(12.,1.)>0. and AbilityBalance.flash_duration(18.1,1.)==0.,"flash radius and distance duration")
	p.role=2;p.gadget=0;p.slot=0;expect(GadgetLoadout.mounted(p,true) and not GadgetLoadout.mounted(p,false),"bipod passively activates crouched")
	p.gadget=8;expect(not GadgetLoadout.mounted(p,true),"frag replaces bipod")
	p.primary="h4";p.mag.h4=1;p.reserve.h4=2;p.fire_ready=0.;p.reload=0.;p.melee_started=-100.;g.fire(1)
	expect(p.mag.h4==0 and p.reload>g.clock and g.rockets.size()==1,"rocket single round and automatic reload")
	g.rockets.clear();p.team=1;q.team=0;q.hp=200.;q.armor=0.;q.protect=0.;q.invulnerable=0.;b.velocity=Vector3.ZERO
	RocketCombat.explode(g,{"owner":1,"origin":Vector3.ZERO,"velocity":Vector3(0,0,-30)}, {"position":b.eye()-Vector3.UP*.3,"normal":Vector3.BACK,"collider":b})
	expect(q.hp>=139. and q.hp<=141.,"rocket direct is sixty total without duplicate splash")
	expect(b.velocity.z< -7. and b.velocity.y>5. and q.blast_until>g.clock,"living direct target knocked back in arc")
	p.role=5;p.primary="m2";p.slot=0;p.team=0;p.fire_ready=0.;p.heal_ready=0.;p.reload=0.;p.alive=true;q.hp=10.;q.team=0;e.hp=10.;e.team=1
	a.position=Vector3.ZERO;a.aim_yaw=0.;a.aim_pitch=0.;a.last_sprint=false;a.sprint_release=0.;b.position=Vector3(0,0,-3);g.actors[3].position=Vector3(-2,0,-3)
	g.add_player(4,"Nearby","n");g.players[4].team=0;g.players[4].hp=10.;g.players[4].alive=true;g.actors[4].position=Vector3(2,0,-3)
	await physics_frame;await physics_frame
	g.heal_burst(1)
	expect(is_equal_approx(q.hp,40.) and g.players[4].hp>25. and e.hp==10.,"medical pulse heals multiple allies with falloff but not enemies")
	var healed=q.hp;g.heal_burst(1);expect(q.hp==healed and is_equal_approx(p.heal_ready,g.clock+10.),"area healing cannot bypass ten second cooldown")
	p.primary="m3";p.heal_ready=0.;p.fire_ready=0.;g.actors[4].position=Vector3(5,0,-3);g.players[4].hp=10.;await physics_frame
	g.heal_burst(1);expect(q.hp>healed and g.players[4].hp==10.,"medical shotgun has same area pulse; targets outside four metres are excluded")
	p.heal_ready=0.;p.fire_ready=0.;g.actors[4].position=Vector3(2,0,-3);g.players[4].hp=10.
	var pulse_wall=StaticBody3D.new();g.add_child(pulse_wall);pulse_wall.position=Vector3(1,1,-3)
	var pulse_shape=CollisionShape3D.new();var pulse_box=BoxShape3D.new();pulse_box.size=Vector3(.2,3,2);pulse_shape.shape=pulse_box;pulse_wall.add_child(pulse_shape)
	await physics_frame;await physics_frame;g.heal_burst(1)
	expect(g.players[4].hp==10.,"area healing cannot pass through walls")
	pulse_wall.free()
	for i in range(1100):
		var n=MeshFactory.cylinder(g,Vector3.ZERO,.01,1.+i*.001,Color(float(i)/1100.,.3,.4));n.free()
	expect(MeshFactory.meshes.size()<=MeshFactory.MESH_CACHE_LIMIT,"random-length geometry cache stays bounded")
	expect(MeshFactory.materials.size()<=MeshFactory.MATERIAL_CACHE_LIMIT,"material cache stays bounded")
	expect(is_equal_approx(g.web_mark_lifetime(60.),2.5) and is_equal_approx(g.web_mark_lifetime(0.),2.5),"web marks last 2.5 seconds at normal or unknown frame rate")
	expect(is_equal_approx(g.web_mark_lifetime(40.),1.5) and is_equal_approx(g.web_mark_lifetime(20.),1.),"web marks expire faster below 45 and 30 FPS")
	ProjectSettings.set_setting("application/config/web_assets",true)
	var expired_mark=MeshInstance3D.new();g.add_child(expired_mark);g.register_wall_mark(expired_mark)
	var fresh_mark=MeshInstance3D.new();g.add_child(fresh_mark);g.register_wall_mark(fresh_mark)
	expect(expired_mark.has_meta("expires_msec"),"web mark receives expiry deadline")
	expired_mark.set_meta("expires_msec",Time.get_ticks_msec()-1);fresh_mark.set_meta("expires_msec",Time.get_ticks_msec()+2500)
	g.expire_web_marks()
	expect(expired_mark.is_queued_for_deletion() and not g.wall_marks.has(expired_mark) and g.wall_marks.has(fresh_mark),"only expired web marks are removed and freed")
	ProjectSettings.set_setting("application/config/web_assets",false)
	var native_mark=MeshInstance3D.new();g.add_child(native_mark);g.register_wall_mark(native_mark)
	g.expire_web_marks();expect(not native_mark.has_meta("expires_msec") and g.wall_marks.has(native_mark) and not native_mark.is_queued_for_deletion(),"native marks preserve existing lifetime")
	g.free();await process_frame
	print("SUPPORT_V118_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
