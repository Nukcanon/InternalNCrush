extends SceneTree
var out="res://../validation/v103-visual"
var scene:Node3D
var camera:Camera3D
var operators:Array=[]
func _initialize():call_deferred("run")
func capture(label:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720);Catalog.load_all()
	scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("283340");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.8;env.environment=settings;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,150,0);light.light_energy=1.3;light.shadow_enabled=true;scene.add_child(light)
	var floor=StaticBody3D.new();scene.add_child(floor);var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(30,.2,30);shape.shape=box;shape.position.y=-.1;floor.add_child(shape);MeshFactory.box(floor,Vector3(0,-.1,0),Vector3(30,.2,30),Color("4a545e"))
	camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(2.2,1.8,-4.5);camera.look_at(Vector3(0,1.0,0));camera.current=true
	for role in range(6):
		var c=CharacterVisual.new();c.enable_physics=false;scene.add_child(c);c.build(role,0);operators.append(c);c.position.x=role*1.1
		var w=WeaponVisual.new();c.socket.add_child(w);w.build(Catalog.get_weapon(Catalog.first(role)),false);w.scale=Vector3.ONE*.8
		c.update_pose(.016,Vector3.ZERO,false,false,true,0.,-1.,0.,0.)
	for role in [0,1,2,5]:
		camera.position=operators[role].position+Vector3(.20,1.70,-.58);camera.look_at(operators[role].position+Vector3.UP*1.62);await capture("face-"+str(role))
	camera.fov=40.;camera.position=Vector3(2.8,1.8,-6.9);camera.look_at(Vector3(2.8,1.,0));await capture("operators")
	for c in operators:c.enable_physics=true
	for frame in range(100):
		for c in operators:c.update_pose(.016,Vector3(0,0,-8.5),true,false,true,0.,-1.,0.,frame/42.)
		await physics_frame
		if frame in [20,42,66]:await capture("run-"+str(frame))
	print("SKIN_NATIVE bones=",operators[0].deform.get_bone_count()," active=",ActivePose.active_count)
	var rag=PhysicsRagdoll.new();scene.add_child(rag);rag.build(operators[0],Vector3(0,2.5,0),Vector3(1,.3,0),0,0,0.,false,Vector3(1,0,0),Vector3(0,3.8,0));operators[0].hide()
	await create_timer(.4).timeout;await capture("ragdoll-air")
	await create_timer(2.).timeout;await capture("ragdoll-floor")
	scene.queue_free();await process_frame;await process_frame
	print("NATIVE_V103_CHARACTER_COMPLETE");quit()
