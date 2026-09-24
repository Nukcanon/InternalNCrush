extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var w=Catalog.get_weapon("r2")
	for zone in ["head","torso","legs"]:
		for distance in [0.,30.,120.]:expect(is_equal_approx(CombatBalance.damage_at(w,distance,zone),100.),"MONOLITH unarmored lethal body zone")
	for zone in ["hands","feet"]:expect(CombatBalance.damage_at(w,30.,zone)<100.,"extremity not one-shot")
	expect(CombatBalance.damage_at(w,180.)<100.,"long range falloff preserved")
	expect(w.interval==2.35 and w.mag==4 and w.reload==3.8,"heavy sniper tradeoffs preserved")
	var male=AuthoredHuman.source(0)
	for role in HumanModel.FEMALE_ROLES:
		var female=AuthoredHuman.source(role);var same=true
		for i in range(male.vertices.size()):
			if male.vertices[i][1]<=1.53 and female.vertices[i]!=male.vertices[i]:same=false
		expect(same,"female torso neck and shoulder geometry uses male source")
		expect(female.weights==male.weights,"female skin uses common male joint weights")
		var rig=HumanModel.pose_rig(role);root.add_child(rig)
		expect(is_equal_approx(rig.scale.x,.95) and is_equal_approx(rig.scale.z,1.),"female only lateral width five percent slimmer")
		expect(is_equal_approx(rig.get_node("Hips/Chest/LeftArm").position.y,.105),"shared shoulder animation baseline")
		rig.free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.options.bots=0;g.host_game();g.start_match();g.set_physics_process(false)
	var p=g.players[1];p.protect=0.;p.armor=50.;p.hp=100.;p.shield=0.;p.invulnerable=0.
	g.damage(1,100.,1,false,"r2");expect(p.hp==50. and p.alive,"armor prevents unarmored one-shot rule")
	p.armor=0.;g.damage(1,100.,1,false,"r2");expect(not p.alive,"unarmored 100HP target dies")
	g.spawn(1);p=g.players[1];p.protect=0.;p.invulnerable=g.clock+4.
	g.actors[1].visual(.016,p,g.clock);expect(g.actors[1].protected_visual.visible,"medic uses spawn protection shell")
	p.invulnerable=0.;p.protect=g.clock+4.;g.actors[1].visual(.016,p,g.clock);expect(g.actors[1].protected_visual.visible,"respawn uses same shell")
	p.protect=0.;g.actors[1].visual(.016,p,g.clock);expect(not g.actors[1].protected_visual.visible,"expired protection shell removed")
	expect(not g.has_node("Web3D") and not root.disable_3d,"native rendering remains enabled")
	expect(MarkerTracker.DWELL_SECONDS==2.,"mark takes two seconds")
	g.free();await process_frame
	var arena=Node3D.new();root.add_child(arena);var props={}
	for i in range(6):
		var prop=InteractiveProp.new();prop.configure(i,"barrel",false);arena.add_child(prop);prop.position=Vector3(i*2,0,0);props[i]=prop
	var batch=WebPropBatch.new();arena.add_child(batch);batch.build(props)
	expect(batch.batches.size()==2 and batch.members.size()==6,"six barrels share two visual draw groups")
	var member=batch.members[0];member.source.get_parent().position.y=3.;batch._process(.016)
	expect(is_equal_approx(member.pose.origin.y,3.),"batched props still follow physics")
	for prop in props.values():expect(prop.collision_layer==8,"batched props retain original collision")
	arena.free();await process_frame
	for id in Catalog.weapons:
		var original=WeaponVisual.new();root.add_child(original);original.build(Catalog.get_weapon(id),false)
		var reused=WeaponVisual.new();root.add_child(reused);var restored=reused.restore_web_model(Catalog.get_weapon(id),false)
		expect(restored and reused.muzzle.position.is_equal_approx(original.muzzle.position) and reused.mag_origin.is_equal_approx(original.mag_origin),"baked web weapon sockets "+id)
		reused.animate_reload(.84,0.,1.);reused.animate_reload(-1.,0.,1.)
		expect(reused.magazine.position.is_equal_approx(reused.mag_origin),"baked reload resets "+id)
		original.free();reused.free()
	print("V113_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
