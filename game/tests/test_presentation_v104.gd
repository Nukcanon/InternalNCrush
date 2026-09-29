extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	Catalog.load_all()
	var model=HeroCharacter.new();root.add_child(model);model.build(0,0)
	expect(model.meshes().all(func(m):return m.skin!=null),"GPU skinning is preserved on every hero part")
	model.free()
	for length in [.1,.8,1.5,4.,30.,120.]:
		var start=Vector3(0,1.5,0);var end=start+Vector3.FORWARD*length
		var previous=-100.
		for tick in range(21):
			var p=KillReplay.bullet_camera_point(start,end,tick/20.);var along=(p-start).dot(Vector3.FORWARD)
			expect(p.distance_to(end)>=1.35 and along>=previous-.001,"bullet camera keeps body clearance and moves forward")
			previous=along
	var listener=StartupNetworkAccess.new();root.add_child(listener)
	expect(listener.begin()==OK and listener.listener!=null,"startup permission probe opens a separate ephemeral listener")
	listener.close();expect(listener.listener==null,"startup permission probe releases its socket");listener.free()
	var world=Node3D.new();root.add_child(world)
	var floor=StaticBody3D.new();world.add_child(floor);var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(30,.2,30);shape.shape=box;shape.position.y=-.1;floor.add_child(shape)
	await physics_frame;await physics_frame
	var trajectories=[]
	for hit in [Vector3(0,1.63,0),Vector3(0,1.24,0),Vector3(.10,.5,0)]:
		var rag=HeroRagdoll.new();world.add_child(rag);rag.build(null,Vector3.ZERO,Vector3(1,.08,0),0,0,0.,false,Vector3.ZERO,hit)
		var origin=rag.bodies[0].global_position;var largest=0.
		for frame in range(150):
			await physics_frame
			var delta=rag.bodies[0].global_position-origin;largest=maxf(largest,Vector2(delta.x,delta.z).length())
		trajectories.append(largest);expect(largest>=1. and largest<=3.1,"fatal hit launches corpse 1–3m on an unobstructed level surface: "+str(largest))
		expect(rag.bodies.filter(func(b):return b.has_meta("fatal_impact")).size()==1,"fatal impulse targets a single closest body")
		if hit.y>1.5:expect(rag.bodies.any(func(b):return str(b.get_meta("fatal_impact_part","")).ends_with("Head")),"head impact remains on the head after the corpse turns flat")
		expect(rag.bodies.all(func(b):return b.global_position.is_finite() and b.global_position.y>-.3),"ragdoll remains finite and collides with floor")
		rag.free();await physics_frame
	world.free()
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.build_world();g.add_player(1,"HUD","presentation_test");g.phase="combat";g.clock=100.;g.ui.show_hud();g.ui.refresh()
	expect(not g.ui.ammo.visible and g.ui.hud.get_node("Hud_ammo").get_children().any(func(n):return n is AmmoPips),"gun magazine is shown as bullet silhouettes")
	for scale in [.65,.8,1.1]:
		g.profile.hud_scale=scale;HudLayout.apply(g.ui)
		expect(g.ui.hud.get_node("Hud_ammo").scale.is_equal_approx(Vector2.ONE*scale),"HUD scale applies to all corner ammo elements")
	g.ui.gear();expect(not g.ui.hud.visible,"equipment menu hides all match HUD/status")
	g.leave_game();g.free();await process_frame
	print("RAGDOLL_DISTANCES ",trajectories)
	print("PRESENTATION_V104_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
