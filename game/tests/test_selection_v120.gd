extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false;g.arena.box(Vector3(0,-.5,0),Vector3(200,1,200),Color.GRAY)
	for id in [1,2,3]:g.add_player(id,"Builder%d"%id,"builder%d"%id);g.players[id].team=0 if id<3 else 1;g.players[id].protect=0.;g.actors[id].position=Vector3(id*20,0,20)
	g.phase="combat";g.clock=100.;var p=g.players[1];p.role=3;p.primary="e1";p.skill_ready=0.;var a=g.actors[1];a.position=Vector3.ZERO;a.reset_view(0.)
	for id in [1,2,3]:
		g.devices[id]={"kind":"turret","owner":id,"team":0 if id<3 else 1,"pos":Vector3(2,0,-2) if id==1 else Vector3(0,0,-3) if id==2 else Vector3(.1,0,-1),"yaw":0.,"level":1,"hp":180.,"max_hp":180.,"upgrade_ready":0.,"building_until":0.,"expires":300.,"disabled":0.}
	await physics_frame;await physics_frame
	expect(TurretSelection.target(g,1)==2,"aim-nearest allied turret beats a slightly nearer off-axis own turret; enemy excluded")
	expect(TurretSelection.caption(g,1,1)=="나의 포탑 업그레이드 (F키)","own caption")
	expect(TurretSelection.caption(g,1,2)==str(g.players[2].nick)+"의 포탑 업그레이드 (F키)","allied owner caption")
	expect(TurretSelection.caption(g,1,2,true).ends_with("(스킬 버튼)"),"touch caption uses its actual control")
	g.update_world_visuals(0.);g.ui.show_hud();g.ui.refresh()
	expect(g.device_nodes[2].get_meta("upgrade_selected",false) and not g.device_nodes[1].get_meta("upgrade_selected",false),"exactly selected turret is outlined")
	expect(g.ui.upgrade_hint.visible and g.ui.upgrade_hint.text==TurretSelection.caption(g,1,2),"HUD matches outline")
	expect(g.ui.upgrade_hint.position.y>430 and g.ui.upgrade_hint.position.y<570,"hint leaves reticle and lower equipment unobstructed")
	p.skill_ready=101.;g.update_world_visuals(0.);g.ui.refresh()
	expect(TurretSelection.target(g,1)==0 and not g.ui.upgrade_hint.visible,"cooldown hides target and caption")
	expect(AbilityBalance.skill_state(g,1).label=="포탑 강화","existing nearby cooldown skill label retained without actionable prompt")
	expect(not g.device_nodes[2].get_meta("upgrade_selected",false),"cooldown clears outline immediately")
	p.skill_ready=0.;g.devices[2].upgrade_ready=101.
	expect(TurretSelection.target(g,1)==1,"unready allied device excluded in favor of ready own turret")
	g.devices[2].upgrade_ready=0.;g.devices[1].upgrade_ready=101.
	expect(TurretSelection.target(g,1)==0,"owned turret cooldown cannot be bypassed via allied upgrade")
	g.devices[1].upgrade_ready=0.;g.devices[2].building_until=101.
	expect(TurretSelection.target(g,1)==1,"construction cannot be selected")
	g.devices[2].building_until=0.;g.devices[2].level=4
	expect(TurretSelection.target(g,1)==1,"max level cannot be selected")
	g.devices[1].level=4
	expect(TurretSelection.target(g,1)==0 and not AbilityBalance.skill_state(g,1).enabled,"only max-level turrets: no target and existing disabled skill state retained")
	g.use_skill(1);expect(p.placing=="" and g.devices[1].level==4,"blocked max-level F action cannot deploy or upgrade unexpectedly")
	g.devices[1].level=1
	g.devices[2].level=1;g.devices[2].pos=Vector3(0,0,-5.1)
	expect(TurretSelection.target(g,1)==1,"five metre interaction range enforced")
	g.devices[2].pos=Vector3(0,0,3)
	expect(TurretSelection.target(g,1)==1,"turret behind player cannot become an invisible selection")
	g.devices[2].pos=Vector3(0,0,-3)
	a.reset_view(PI);expect(Deployment.nearby_turret(g,1)==0,"F cannot upgrade a ready turret hidden behind the player");a.reset_view(0.)
	var wall=g.arena.box(Vector3(0,1,-1.5),Vector3(.5,3,.2),Color.GRAY)
	await physics_frame;await physics_frame
	expect(TurretSelection.target(g,1)==1,"wall occludes central turret without hiding clear off-axis alternative")
	wall.free();await physics_frame;await physics_frame
	g.use_skill(1)
	expect(g.devices[2].level==2 and g.devices[1].level==1,"F upgrades exactly highlighted allied turret")
	expect(g.devices[2].owner==2 and p.skill_ready==130. and g.devices[2].building_until==103.,"ownership preserved; upgrade duration and shared cooldown retained")
	g.ui.refresh();g.update_world_visuals(0.)
	expect(not g.ui.upgrade_hint.visible and not g.device_nodes[2].get_meta("upgrade_selected",false),"upgrade immediately hides prompt and outline")
	p.skill_ready=0.;TurretLogic.upgrade(g,1,3);expect(g.devices[3].level==1,"server rejects enemy upgrade")
	g.devices[2].upgrade_ready=0.;g.devices[2].building_until=0.;g.devices[2].pos=Vector3(0,0,-20);TurretLogic.upgrade(g,1,2);expect(g.devices[2].level==2,"server rejects remote upgrade")
	p.role=5;p.invul_select=g.clock+5.;g.actors[2].position=Vector3(0,0,-3);g.actors[2].set_team(0);g.actors[2].ensure_character()
	await process_frame
	MedicSelection.apply(g.actors[2])
	expect(g.actors[2].character.get_meta("medic_selected",false),"medic ally selection keeps white outline")
	p.invul_select=0.;await process_frame;MedicSelection.apply(g.actors[2]);expect(not g.actors[2].character.get_meta("medic_selected",false),"medic outline removed after selection")
	for i in range(5):
		expect(g.ui.slots[i].horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and is_equal_approx(g.ui.slots[i].position.x+g.ui.slots[i].size.x*.5,g.ui.slot_panels[i].position.x+50.),"slot %d content horizontally centered"%i)
	expect(AllyHealthLabels.pixel_size(5.)>AllyHealthLabels.pixel_size(20.) and AllyHealthLabels.pixel_size(20.)>AllyHealthLabels.pixel_size(100.),"ally HP shrinks smoothly with distance")
	expect(AllyHealthLabels.pixel_size(100.)==AllyHealthLabels.pixel_size(1000.) and AllyHealthLabels.pixel_size(1000.)==AllyHealthLabels.FAR_SIZE,"distant HP has a readable minimum")
	AllyHealthLabels.layout(g.actors[2]);expect(g.actors[2].health_tag.position.y>g.actors[2].tag.position.y and g.actors[2].health_tag.no_depth_test,"HP above nickname and visible through walls")
	g.ui.gear();expect(g.ui.weapon_ids.has("m3"),"MENDER remains in medic primary choices")
	expect(g.ui.gear_gadget.get_item_index(8)>=0,"frag remains in medic gadget choices")
	g.free();await process_frame
	print("SELECTION_V120_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
