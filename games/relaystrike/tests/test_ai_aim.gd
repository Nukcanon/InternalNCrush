extends SceneTree
var g:Node
var checks=0
var failures=0
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
	else:print("PASS ",message)
func _initialize():call_deferred("run")
func reset_bot(role:int,primary:String):
	g.clock+=5
	var p=g.players[-1];p.team=0;p.role=role;p.primary=primary;p.secondary=Rules.SECONDARIES[role];p.slot=0;p.hp=100.;p.armor=0.;p.skill_ready=0.;p.gadget_ready=0.;p.gadget_count=3;p.smoke=2;p.flash_count=1;p.fire_ready=0.;p.reload=0.;p.protect=0.;p.shield=0.;p.flash=0.;p.slow=0.;p.mark=0.;p.dash=0.;p.heal_ready=0.;p.heal_mag=3;p.last_hit=-100.;p.switch_until=0.;g.equip_ammo(p)
	var a=g.actors[-1];a.position=Vector3(70,0,60);a.reset_view(0);a.input_state.crouch=false
	var b=g.bot_agents[-1];b.target=0;b.visible_target=false;b.last_seen=-100.;b.next_decision=0.;b.next_path=0.;b.goal=a.position;b.instant_look(a.eye()+Vector3.FORWARD*10)
	g.players[-2].alive=true;g.players[-2].team=1;g.players[-2].hp=100.;g.actors[-2].position=Vector3(70,0,48);g.players[-2].protect=0.
	return p
func align(at:Vector3):g.bot_agents[-1].instant_look(at)
func run():
	Catalog.load_all();var w=Catalog.get_weapon("a1")
	var standing=AimModel.spread(w,0,false,false,false,true,0)
	expect(AimModel.spread(w,7.4,false,false,false,true,0)>AimModel.spread(w,3,false,false,false,true,0) and AimModel.spread(w,3,false,false,false,true,0)>standing,"accuracy scales with movement speed")
	expect(AimModel.spread(w,0,false,false,false,true,.5)>standing,"sustained firing bloom widens the cone")
	expect(AimModel.spread(w,0,true,true,false,true,0)<standing,"crouch and ADS improve accuracy")
	expect(AimModel.spread(w,0,false,false,false,false,0,false,6)>AimModel.spread(w,0,false,false,false,false,0,false,0) and AimModel.spread(w,0,false,false,false,false,0,false,0)>standing,"jump apex is more accurate than ascent but worse than standing")
	var early=AimModel.spray_offset(w,7);var left=AimModel.spray_offset(w,23);var right=AimModel.spray_offset(w,13)
	expect(absf(early.x)<.1 and early.y>1.5 and left.x< -1 and right.x>1 and absf(left.y-right.y)<.3,"T spray has vertical stem and both horizontal branches")
	var inside=true
	for i in range(100):
		var d=AimModel.cone_direction(Vector3.FORWARD,2.,i/99.,i*.37)
		if rad_to_deg(Vector3.FORWARD.angle_to(d))>2.001:inside=false
	expect(inside,"spread samples stay inside declared reticle cone")
	expect(AimModel.pixel_radius(2,52,720)>AimModel.pixel_radius(2,82,720),"reticle projects the same cone through camera FOV")
	for role in range(6):
		var model=CharacterVisual.new();root.add_child(model);model.build(role,0)
		var animator=model.animator;var clips=animator.get_animation_list();expect(clips.size()>=17 and clips.has("run") and clips.has("reload") and clips.has("hit"),"operator %d contains locomotion and five distinct fall clips"%role)
		animator.play("walk");animator.seek(.2,true);var start=model.rig.get_node("Hips/LeftLeg").rotation.x;animator.seek(.6,true)
		expect(absf(start-model.rig.get_node("Hips/LeftLeg").rotation.x)>.2,"operator %d walking moves actual leg joints"%role)
		model.queue_free()
	g=load("res://scripts/game.gd").new();root.add_child(g);g.dedicated=true;g.host_game();g.set_physics_process(false);g.options.classes=true;g.options.skills=true;g.options.mode=0;g.phase="combat";g.clock=100;g.remaining=1000
	expect(g.players.is_empty(),"dedicated server does not occupy a player slot")
	g.options.classes=false;g.add_player(-5,"NOCLASS","noclass");expect(g.players[-5].armor==0 and g.current_weapon(g.players[-5]).kind=="gun","classless bots start with an attack weapon and zero armor");g.disconnected(-5);g.options.classes=true
	g.add_player(-1,"TEST","test");g.add_player(-2,"ALLY","ally");g.spawn(-1);g.spawn(-2)
	var b=g.bot_agents[-1];var a=g.actors[-1];var q=g.players[-2];var p=reset_bot(5,"m1");q.team=0;q.hp=40.;q.last_hit=0.;g.actors[-2].position=a.position+Vector3(0,0,-5)
	await physics_frame
	b.choose_action();align(g.actors[-2].eye());b.support_action();g.options.skills=false;g.fire(-1)
	expect(b.action=="heal" and q.hp>40 and p.energy<180,"medic chooses injured teammate and LINK heals with skills off")
	p=reset_bot(5,"m2");q.team=0;q.hp=40.;q.last_hit=0.;g.actors[-2].position=a.position+Vector3(0,0,-5);await physics_frame
	b.choose_action();align(g.actors[-2].eye());b.support_action();g.heal_burst(-1);var health=q.hp;g.heal_burst(-1)
	expect(health==60 and q.hp==health and is_equal_approx(p.heal_ready,g.clock+2),"combat medic healing respects two-second cooldown")
	p=reset_bot(0,"a1");p.hp=60;g.options.skills=true;b.goal=a.position+Vector3(0,0,-30);b.utilities()
	expect(p.armor==25 and p.dash>g.clock,"assault bot uses protection and movement skill")
	p=reset_bot(1,"r1");b.visible_target=true;align(g.actors[-2].eye());await physics_frame;b.utilities()
	expect(q.mark>g.clock and p.gadget_count==2 and p.skill_ready>g.clock,"recon bot uses marker and scan")
	p=reset_bot(2,"h1");p.hp=40;b.visible_target=true;b.utilities()
	expect(p.get("mounted",0)>g.clock and p.shield>g.clock,"heavy bot mounts and shields under pressure")
	p=reset_bot(3,"e1");p.secondary="repair";b.goal=a.position;b.utilities();await physics_frame
	expect(g.devices.size()==1 and p.skill_ready==g.clock+30,"engineer bot places one turret with 30-second charge")
	var did=g.devices.keys()[0];g.update_world_visuals(.1);await physics_frame
	p.skill_ready=0.;b.utilities();expect(g.devices[did].level==2 and g.devices.size()==1,"engineer bot upgrades existing turret")
	p.skill_ready=g.clock+30;b.visible_target=true;p.gadget_ready=0.;b.utilities();g.update_world_visuals(.1);await physics_frame
	expect(g.devices.size()==2,"engineer bot places cover beside turret")
	a.position+=Vector3(0,0,-.8);await physics_frame
	g.devices[did].hp=80.;g.devices[did].last_hit=0.;b.visible_target=false;b.choose_action();align(g.devices[did].pos+Vector3.UP*.85);b.support_action();p.switch_until=0.;p.fire_ready=0.;g.fire(-1)
	expect(b.action=="repair" and g.devices[did].hp>80,"engineer repairs damaged friendly device")
	g.bot_navigation.refresh(g.devices,g.clock+1);var route=g.bot_navigation.route(a.position,a.position+Vector3(0,0,-12));var avoids=true
	for pos in route:
		if g.bot_navigation.dynamic_solid.has(g.bot_navigation.cell(pos)):avoids=false
	expect(avoids and route.size()>0,"paths avoid newly built devices")
	for device in g.devices.keys():g.remove_device(device)
	await physics_frame
	p=reset_bot(4,"c1");b.visible_target=true;b.last_known=a.position+Vector3(0,0,-35);q.team=1;g.actors[-2].position=a.position+Vector3(0,0,-30);p.flash_count=0;g.options.skills=false;b.utilities()
	expect(g.fields.any(func(f):return f.kind=="smoke") and p.smoke==1,"control bot deploys smoke with skills off")
	p.gadget_ready=0.;p.flash_count=1;p.hp=100;g.actors[-2].position=a.position+Vector3(0,0,-20);g.options.skills=true;await physics_frame;b.utilities();g.clock+=.36;g.update_fields(.36)
	expect(p.flash_count==0 and q.flash>g.clock and g.fields.any(func(f):return f.kind=="slow"),"control bot uses flash and slow field")
	g.fields.clear();p=reset_bot(5,"m1");p.hp=50;p.mark=g.clock+3;b.utilities()
	expect(p.hp>50 and p.mark==0 and p.skill_ready>g.clock,"medic bot treats itself and clears status")
	p=reset_bot(0,"a1");p.hp=20;b.visible_target=true;b.last_known=a.position+Vector3(0,0,-10);b.difficulty=1;b.choose_action();expect(b.action=="retreat","bot changes goal when critically low")
	p.hp=100.;p.reserve[p.primary]=0;b.visible_target=false;b.choose_action();expect(b.action=="resupply","bot changes goal when ammunition is low")
	p=reset_bot(0,"a1");g.actors[-2].position=Vector3(43,0,51);await physics_frame;b.perceive();expect(not b.visible_target,"bot cannot acquire an enemy through warehouse walls")
	g.actors[-2].position=Vector3(70,0,48);await physics_frame
	var reaction=[]
	for level in range(3):b.difficulty=level;b.target=0;b.perceive();reaction.append(b.ready_to_fire-g.clock)
	expect(reaction[0]>reaction[1] and reaction[1]>reaction[2] and reaction[2]>0,"easy medium hard have distinct nonzero reaction delays")
	print("AI_AIM_RESULT ",checks-failures,"/",checks)
	g.leave_game();g.queue_free();await process_frame;quit(1 if failures else 0)
