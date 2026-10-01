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
		for distance in [0.,30.,120.]:expect(is_equal_approx(CombatBalance.damage_at(w,distance,zone),300. if zone=="head" else 120. if zone=="torso" else 90.),"MONOLITH revised zone damage")
	for zone in ["hands","feet"]:expect(CombatBalance.damage_at(w,30.,zone)<100.,"extremity not one-shot")
	expect(CombatBalance.damage_at(w,180.)<150.,"long range falloff preserved")
	expect(w.interval==2.35 and w.mag==4 and w.reload==3.8,"heavy sniper tradeoffs preserved")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.options.bots=0;g.host_game();g.start_match();g.set_physics_process(false)
	var p=g.players[1];p.protect=0.;p.armor=50.;p.hp=100.;p.shield=0.;p.invulnerable=0.
	g.damage(1,100.,1,false,"r2");expect(p.hp==50. and p.alive,"armor prevents unarmored one-shot rule")
	p.armor=0.;g.damage(1,100.,1,false,"r2");expect(not p.alive,"unarmored 100HP target dies")
	g.spawn(1);p=g.players[1];p.protect=0.;p.invulnerable=g.clock+4.
	g.actors[1].visual(.016,p,g.clock);expect(g.actors[1].protected_visual.visible,"medic uses spawn protection shell")
	p.invulnerable=0.;p.protect=g.clock+4.;g.actors[1].visual(.016,p,g.clock);expect(g.actors[1].protected_visual.visible,"respawn uses same shell")
	p.protect=0.;g.actors[1].visual(.016,p,g.clock);expect(not g.actors[1].protected_visual.visible,"expired protection shell removed")
	expect(not g.has_node("Web3D") and not root.disable_3d,"native rendering remains enabled")
	expect(is_equal_approx(MarkerTracker.DWELL_SECONDS,1.8),"mark takes 1.8 seconds (1.4.5)")
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
		var original=GunModel.new();root.add_child(original);original.build(Catalog.get_weapon(id),false)
		var reused=GunModel.new();root.add_child(reused);reused.build(Catalog.get_weapon(id),false)
		expect(reused.muzzle.position.is_equal_approx(original.muzzle.position) and reused.base.scale.is_equal_approx(original.base.scale),"shared weapon bases keep sockets "+id)
		reused.animate_reload(.84,0.,1.);reused.animate_reload(-1.,0.,1.)
		expect(not is_instance_valid(reused.magazine) or reused.magazine.transform.is_equal_approx(reused.mag_rest),"reload resets "+id)
		original.free();reused.free()
	print("V113_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
