extends SceneTree
var checks=0
var failures=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func _initialize():call_deferred("run")
func run():
	TouchControls.supported_cache=0
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false;g.arena.spawn_points=[[Vector3.ZERO],[Vector3(20,0,20)]];g.arena.box(Vector3(0,-.5,0),Vector3(100,1,100),Color.GRAY)
	g.add_player(1,"Tester","one");g.add_player(2,"Ally","two");g.phase="combat";g.clock=100.;g.options.mode=0
	var p=g.players[1];var q=g.players[2];var a=g.actors[1];var b=g.actors[2]
	p.role=3;p.primary="e1";p.team=0;p.skill_ready=125.;p.placing="";p.gadget=0;p.alive=true;q.team=0;q.alive=true
	g.spawn(1);expect(p.skill_ready==125.,"respawn preserves absolute skill deadline")
	g.commit_loadout(1,{"role":5,"primary":"m1","armor":0,"gadget":0})
	expect(p.skill_ready==140.,"class switch carries five elapsed seconds into medic charge")
	g.commit_loadout(1,{"role":3,"primary":"e1","armor":0,"gadget":0})
	expect(p.skill_ready==125.,"class switch cannot reset elapsed charge")
	p.role=5;p.skill_ready=0.;p.protect=0.;q.protect=0.;a.position=Vector3.ZERO;b.position=Vector3(.7,0,-8);a.aim_yaw=0.;a.aim_pitch=0.
	await physics_frame;await physics_frame
	expect(g.invulnerability_target(1)==2,"medic cone accepts slightly off-center ally")
	g.use_skill(1);g.grant_invulnerability(1,2)
	expect(p.invulnerable==106. and q.invulnerable==106. and p.skill_ready==145.,"click ally grants both six seconds once")
	p.skill_ready=0.;q.invulnerable=0.;g.grant_invulnerability(1,0)
	expect(p.invulnerable==106. and q.invulnerable==0.,"empty click grants only self")
	p.role=3;p.secondary="repair";p.slot=1;p.repair_energy=100.;p.invulnerable=0.;p.skill_ready=0.
	var did=g.add_device("turret",Vector3(0,0,-8),1,180.);g.devices[did].hp=20.;g.devices[did].last_hit=-100.;g.update_world_visuals(.016)
	a.aim_pitch=atan2(.8-a.eye().y,8.);await physics_frame
	for i in range(10):g.clock+=.1;g.repair(1)
	expect(is_equal_approx(g.devices[did].hp,50.),"FIX repairs exactly thirty HP per second at eight metres")
	g.devices[did].hp=100.;g.devices[did].building_until=g.clock+3.;q.team=1;g.damage_device(did,10.,2)
	expect(g.devices[did].hp==85.,"construction receives fifty percent extra damage")
	g.remove_device(did);q.team=0
	p.role=4;p.gadget=1;GadgetLoadout.reset(p);p.gadget_ready=0.;p.cooking=0.;a.aim_pitch=0.
	expect(GrenadeLogic.begin(g,1),"flash grenade begins physical throw")
	var grenade=g.grenades.back();expect(grenade.kind=="flash" and is_equal_approx(grenade.until-g.clock,2.5),"flash uses chosen model and short fuse")
	GrenadeLogic.release(g,1);expect(not grenade.held and grenade.velocity.length()>10.,"released grenade travels through world")
	g.clock+=2.6;GrenadeLogic.tick(g,.016);expect(g.fields.back().kind=="flash_pending","flash detonates at simulated endpoint")
	p.gadget=8;p.gadget_ready=0.;GadgetLoadout.reset(p);GrenadeLogic.begin(g,1);GrenadeLogic.release(g,1)
	grenade=g.grenades.back();grenade.pos=Vector3(10,.11,0);grenade.velocity=Vector3(4,-.5,0);grenade.released=g.clock-1.
	GrenadeLogic.tick(g,.1);expect(grenade.velocity.x>3.,"ground contact preserves rolling speed")
	g.grenades.clear();p.cooking=0.;p.role=0;p.slot=0;p.shield=0.;p.slow=0.;p.slide_ready=0.;a.position=Vector3.ZERO;a.velocity=Vector3.ZERO;a.input_state.jump=false;a.input_state.yaw=0.
	for i in range(30):a.simulate(.016,g.clock,true);await physics_frame
	expect(g.begin_slide(1,false,Vector2(-1,0)) and p.slide_direction.x<-.9,"double-tap slide follows requested left direction from rest")
	p.slide_until=0.;p.slide_ready=0.
	var touch=TouchControls.new();touch.game=g;g.add_child(touch);touch.movement=Vector2(0,-1);touch.track_swipe();touch.movement=Vector2.ZERO;touch.track_swipe();touch.movement=Vector2(.1,-1);touch.track_swipe()
	expect(p.slide_direction.z<-.9,"neutral then matching swipe starts forward slide")
	expect(not touch.buttons.has("slide"),"mobile slide button removed")
	expect(RocketCombat.RADIUS==9. and RocketCombat.GRAVITY<1. and Catalog.get_weapon("h4").damage==60,"launcher balance")
	expect(AbilityBalance.COOLDOWNS[3]==30. and AbilityBalance.SLOW_RADIUS==15.,"turret and control balance")
	# An unfinished cover cannot absorb a shot, but receives its own damage.
	p.team=0;q.team=1;p.primary="a1";p.slot=0;p.protect=0.;p.invulnerable=0.;p.hp=100.;q.hp=100.;q.protect=0.;q.invulnerable=0.;q.armor=0.;p.placing="";p.slide_until=0.
	a.position=Vector3.ZERO;b.position=Vector3(0,0,-8);a.aim_yaw=0.;a.aim_pitch=0.;a.input_state.yaw=0.
	var cover=g.add_device("cover",Vector3(0,0,-3),2,300.);g.devices[cover].building_started=g.clock;g.devices[cover].building_until=g.clock+5.;g.devices[cover].disabled=g.clock+5.
	g.update_world_visuals(.016);await physics_frame
	var flight=Ballistics.trace(g,Vector3(0,.8,0),Vector3.FORWARD,20.,[a.get_rid()])
	expect(flight.passed.has(cover) and flight.hit.get("collider")==b,"bullet crosses construction and still hits player behind")
	g.damage_device(cover,10.,1);expect(g.devices[cover].hp==285.,"crossed structure independently takes fifty percent extra bullet damage")
	expect(g.device_nodes[cover].collision_layer==0,"construction has no blocking collision")
	p.role=0;g.update_world_visuals(.016);expect(not g.device_nodes[cover].get_node("BuildTimer").visible,"other classes cannot see construction timer")
	p.role=3;p.team=1;g.update_world_visuals(.016);expect(g.device_nodes[cover].get_node("BuildTimer").visible,"allied engineer sees construction timer")
	p.team=0;var hp=q.hp;GrenadeLogic.explode(g,Vector3(0,.8,-2),1)
	expect(q.hp<hp,"explosion crosses unfinished cover")
	g.clock+=5.1;g.update_world_visuals(.016);await physics_frame
	if g.devices.has(cover):expect(g.device_nodes[cover].collision_layer==4,"completed cover becomes solid")
	for key in g.devices.keys():g.remove_device(key)
	p.skill_ready=0.;p.alive=true;p.protect=0.;a.position=Vector3(10,0,2);var tower=g.add_device("turret",Vector3(10,0,0),1,180.);g.devices[tower].upgrade_ready=0.
	TurretLogic.upgrade(g,1,tower)
	expect(is_equal_approx(g.devices[tower].building_until-g.clock,3.) and is_equal_approx(p.skill_ready-g.clock,30.),"upgrade starts three-second build and thirty-second charge together")
	var level=g.devices[tower].level;p.skill_ready=0.;g.devices[tower].upgrade_ready=0.;TurretLogic.upgrade(g,1,tower)
	expect(g.devices[tower].level==level,"cannot upgrade while construction is in progress")
	var progress_device={"hp":100.,"max_hp":200.,"build_growth":100.,"build_progress":0.,"building_started":g.clock,"building_until":g.clock+5.}
	g.clock+=2.5;Construction.advance(g,progress_device);expect(progress_device.hp==150.,"construction starts half full and gains health over time")
	progress_device.hp-=30.;g.clock+=2.5;Construction.advance(g,progress_device);expect(progress_device.hp==170.,"construction completion preserves all damage received")
	for key in g.devices.keys():g.remove_device(key)
	b.position=Vector3(20,0,20);a.position=Vector3.ZERO;a.velocity=Vector3.ZERO;a.input_state.yaw=0.;a.aim_yaw=0.;a.input_state.jump=false;a.input_state.crouch=false;p.placing="";p.slide_until=0.;p.slow=0.;p.shield=0.
	for frame in range(20):a.simulate(.016,g.clock,true);await physics_frame
	var ledge=g.arena.box(Vector3(0,.60,-.8),Vector3(3.,1.2,.65),Color.GRAY);await physics_frame
	a.input_state.jump=true;a.input_state.z=-1.
	expect(a.try_mantle() and a.position.y>1.15,"forward jump can climb a cover-height ledge")
	ledge.free();await physics_frame
	expect(AbilityBalance.scan_range(Vector2(10,10))==35. and AbilityBalance.scan_range(Vector2(500,500))==60. and AbilityBalance.scan_range(Vector2(60,70))>35.,"sensor scales with map size inside 35 to 60 metres")
	p.team=1;q.team=0;q.protect=0.;q.invulnerable=0.;q.armor=0.;q.alive=true
	for offset in [Vector3(0,1.7,0),Vector3(0,.8,0),Vector3(0,.25,0)]:
		q.hp=100.;q.alive=true
		RocketCombat.explode(g,{"owner":1,"origin":Vector3.ZERO,"velocity":Vector3(0,0,-30)}, {"position":b.position+offset,"normal":Vector3.BACK,"collider":b})
		expect(is_equal_approx(q.hp,40.),"rocket direct damage sixty independent of body part")
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(440,160)
	for wid in Catalog.weapons:
		preview.display(1,int(Catalog.get_weapon(wid).role),0,wid)
		var bounds=AABB();var first=true
		for mesh in preview.model.find_children("*","MeshInstance3D",true,false):
			var part=preview.model.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb();bounds=part if first else bounds.merge(part);first=false
		expect(bounds.get_center().length()<.015,"preview centered "+wid)
		expect(preview.custom_minimum_size.y<=280.,"compact preview "+wid)
	preview.display(4,5,0,"m1");expect(preview.skill_symbol.size==Vector2(76,76),"compact skill icon")
	preview.free();g.free();await process_frame
	print("V119_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
