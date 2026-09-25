extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	Catalog.load_all()
	var model=CharacterVisual.new();root.add_child(model);model.build(0,0)
	var body=model.rig.get_node("ContinuousBody")
	expect(body.skin!=null and body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()<18000,"comic character retains GPU skinning within the base mesh triangle budget")
	model.free()
	for gender in ["male","female"]:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/human/"+gender+".json"));var invalid=false;var longest=0.
		for weights in data.weights:
			var total=0.
			for pair in weights:total+=pair[1];invalid=invalid or pair[0]<0 or pair[0]>=15 or pair[1]<0
			invalid=invalid or absf(total-1.)>.00001
		expect(not invalid,gender+" every anatomy vertex has normalized valid skin weights")
		var cloth_on_jaw=false
		for index in range(data.vertices.size()):
			var p=data.vertices[index]
			if p[1]>1.49 and p[2]<-.04 and absf(p[0])<.065:cloth_on_jaw=cloth_on_jaw or int(data.kinds[index])!=0
		expect(not cloth_on_jaw,gender+" jaw and upper neck retain skin instead of cloth")
		for face in data.faces:
			for i in range(3):
				var a=data.vertices[face[i]];var b=data.vertices[face[(i+1)%3]]
				longest=maxf(longest,Vector3(a[0],a[1],a[2]).distance_to(Vector3(b[0],b[1],b[2])))
		expect(longest<.10,gender+" retargeting has no stretched fingers or stray triangles")
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
		var rag=PhysicsRagdoll.new();world.add_child(rag);rag.build(null,Vector3.ZERO,Vector3(1,.08,0),0,0,0.,false,Vector3.ZERO,hit)
		var origin=rag.bodies[0].global_position;var largest=0.
		for frame in range(150):
			await physics_frame
			var delta=rag.bodies[0].global_position-origin;largest=maxf(largest,Vector2(delta.x,delta.z).length())
		trajectories.append(largest);expect(largest>=1. and largest<=3.1,"fatal hit launches corpse 1–3m on an unobstructed level surface: "+str(largest))
		expect(rag.bodies.filter(func(b):return b.has_meta("fatal_impact")).size()==1,"fatal impulse targets a single closest body")
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
