extends SceneTree
# 1.5.4 (the user's list): a respawned player fires at once (still protected); throwables
# come to rest after two or three bounces on one level, and bounce again after a drop of
# more than half a metre.
var checks=0
var failures=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
	else:print("PASS ",label)
func _initialize():call_deferred("run")
func throw_at(g:Node,from:Vector3,velocity:Vector3) -> Dictionary:
	var item={"id":g.grenades.size()+1,"owner":1,"pos":from,"velocity":velocity,"until":g.clock+30.,"held":false,"released":g.clock-1.,"cluster":false,"kind":"smoke","rotation":Vector3.ZERO}
	g.grenades.append(item);return item
func run():
	Catalog.load_all()
	expect(Rules.SPAWN_ATTACK_DELAY==0. and Rules.attack_blocked_until({"protect":10.})<=10.-Rules.SPAWN_PROTECTION+.001,"a respawned player may fire at once")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(160,1,160),Color.GRAY)
	g.arena.box(Vector3(40,1.,0),Vector3(20,2.,40),Color.GRAY) # a 2 m high block to throw off
	g.add_player(1,"Thrower","t");g.phase="combat";g.clock=100.
	await physics_frame;await physics_frame
	# flat ground: a hard throw
	var item=throw_at(g,Vector3(0,1.5,0),Vector3(0,3.,-15.))
	var touches=0;var last_left=-1;var steps=0
	while not bool(item.get("resting",false)) and steps<600:
		g.clock+=1./60.;GrenadeLogic.tick(g,1./60.);steps+=1
		var left=int(item.get("bounces_left",-1))
		if left!=last_left and left>=0:touches+=1;last_left=left
	var travel=Vector2(item.pos.x,item.pos.z).length()
	print("FLAT touches %d travel %.1f m rest after %.2f s"%[touches,travel,steps/60.])
	expect(bool(item.get("resting",false)) and touches>=2 and touches<=3,"on one level a throwable rests after two or three bounces (%d)"%touches)
	expect(travel<16.,"it no longer rolls far (%.1f m)"%travel)
	# off a 2 m block: bounces on top, falls, bounces again below
	item=throw_at(g,Vector3(46,2.6,0),Vector3(10.,0.,0.)) # (touches the block near its edge at x=50, then goes over it)
	var heights=[];last_left=-1;steps=0
	while not bool(item.get("resting",false)) and steps<900:
		g.clock+=1./60.;GrenadeLogic.tick(g,1./60.);steps+=1
		var left=int(item.get("bounces_left",-1))
		if left!=last_left and left>=0:heights.append(snappedf(float(item.bounce_y),.1));last_left=left
	print("DROP bounce heights %s rest at %s"%[str(heights),str(item.pos.snapped(Vector3.ONE*.1))])
	var low=heights.filter(func(h):return h<.5).size()
	expect(bool(item.get("resting",false)) and heights.size()>=3 and low>=2,"after falling off a 2 m block it bounces again below (%s)"%str(heights))
	# the medic kit: usable (not grey) with a hurt ally anywhere within 10 m, not only one aimed at
	g.options.classes=true;g.options.mode=0
	g.add_player(2,"Medic","m");g.add_player(3,"Ally","a");g.add_player(4,"Other","o")
	for id in [2,3,4]:g.players[id].team=0;g.players[id].alive=true;g.players[id].protect=0.
	g.players[1].team=1
	var medic=g.players[2];medic.role=5;medic.slot=2;medic.gadget=0;medic.gadget_count=2;medic.gadget_ready=0.
	g.actors[2].position=Vector3(0,0,0);g.actors[3].position=Vector3(8,0,0);g.actors[4].position=Vector3(30,0,0)
	for id in [2,3,4]:g.players[id].hp=Rules.max_hp(g.players[id])
	expect(not ActionState.available(g,2,"gadget"),"the kit is grey when nobody near is hurt")
	g.players[3].hp=40.
	expect(ActionState.available(g,2,"gadget"),"the kit is usable with a hurt ally 8 m away (not aimed at)")
	g.players[3].hp=Rules.max_hp(g.players[3]);g.players[4].hp=40.
	expect(not ActionState.available(g,2,"gadget"),"a hurt ally 30 m away does not count")
	# the medic cap: a second medic on a team of 3 is refused before the class is reserved
	g.players[3].role=0;g.players[4].role=0
	expect(g.medic_full(3,5) and not g.medic_full(2,5) and not g.medic_full(3,0),"the team's medic place is taken (cap %d)"%Rules.medic_cap(g.team_count(0)))
	g.apply_loadout(3,{"role":5,"primary":Catalog.first(5)})
	expect(g.players[3].role!=5 and g.players[3].get("pending_loadout",{}).is_empty(),"a refused medic is not reserved for the next respawn")
	# deployables keep clear of each other (a turret beside a cover, not inside it)
	g.actors[2].position=Vector3(-30,0,30)
	g.devices[900]={"id":900,"kind":"cover","pos":Vector3(-20,0,20),"yaw":0.,"owner":3,"team":0,"hp":100.,"max_hp":100.}
	var free_spot=Deployment.allowed(g,Vector3(-20,0,26),0.,"turret",2)
	var inside=Deployment.allowed(g,Vector3(-19,0,20.3),0.,"turret",2)
	expect(free_spot and not inside,"a turret may not stand in a cover (free %s, overlapping %s)"%[free_spot,inside])
	g.devices.erase(900)
	print("V154_RESULT %d/%d"%[checks-failures,checks])
	g.free()
	quit(1 if failures>0 else 0)
