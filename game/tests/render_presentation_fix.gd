extends SceneTree
var folder="res://../validation/presentation-fix/"
func _initialize():call_deferred("run")
func shot(label:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	root.size=Vector2i(960,640)
	var world=Node3D.new();root.add_child(world)
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("6b8394")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.7;world.add_child(environment)
	var light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-35,-25,0)
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=70
	Catalog.load_all()
	for id in Catalog.weapons:
		var spec=Catalog.get_weapon(id)
		if spec.kind!="gun":continue
		var gun=WeaponVisual.new();world.add_child(gun);gun.build(spec,true)
		gun.position=Vector3(.255,-.255,-.46);gun.animate_reload(-1.,0.)
		await shot(id+"-idle")
		gun.position=Vector3(0,-.14,-.5);await shot(id+"-ads")
		gun.position=Vector3(.255,-.255,-.46)
		for i in range(1,10):
			gun.animate_reload(i/10.,0.);await shot(id+"-reload-"+str(i))
		gun.free()
	camera.position=Vector3(0,1.60,-.65);camera.look_at(Vector3(0,1.60,0))
	for role in range(6):
		var model=CharacterVisual.new();world.add_child(model);model.build(role,0);await shot("face-"+str(role));model.free()
	camera.position=Vector3(2,2,-3);camera.look_at(Vector3(0,.9,0))
	var turret=Node3D.new();world.add_child(turret);CombatFX.device(turret,"turret",0)
	await shot("turret-plain")
	DeploymentSilhouette.apply(turret,{"owner":1,"team":0,"level":1},1)
	await shot("turret-overlay-visible")
	world.free();await process_frame;print("PRESENTATION_RENDER_OK");quit()
