extends SceneTree
var folder="res://../validation/combat-review/"
func _initialize():call_deferred("run")
func shot(label:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute(folder);root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720));root.content_scale_size=Vector2i(1280,720)
	Catalog.load_all();ToonMaterials.configure(true)
	var stage=Node3D.new();root.add_child(stage)
	var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("607789");world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=.5;stage.add_child(world)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,150,0);light.light_energy=1.15;light.shadow_enabled=true;stage.add_child(light)
	var camera=Camera3D.new();stage.add_child(camera);camera.current=true;camera.fov=65
	for id in ["h2","h5","h6"]:
		var gun=WeaponVisual.new();stage.add_child(gun);gun.build(Catalog.get_weapon(id),false,false);gun.rotation.y=PI/2
		camera.position=Vector3(-.35,.22,1.4);camera.look_at(Vector3(-.35,-.01,0))
		await shot(id+"-side");gun.free()
	camera.position=Vector3.ZERO;camera.rotation=Vector3.ZERO
	var laser=WeaponVisual.new();stage.add_child(laser);laser.build(Catalog.get_weapon("h6"),true,false);laser.position=Vector3(.255,-.255,-.46)
	for heat in [0.,.5,1.]:
		laser.get_node("HeatGauge").update_heat(heat,heat>=1.);await shot("laser-heat-"+str(heat))
	laser.free()
	var bodies=[]
	for role in [0,1,5]:
		var actor=CharacterVisual.new();stage.add_child(actor);actor.build(role,0);actor.position.x=bodies.size()*1.25;actor.update_pose(.016,Vector3.ZERO,false,false,true,0.,-1.,0.,0.);bodies.append(actor)
	camera.position=Vector3(1.25,1.1,-4.);camera.look_at(Vector3(1.25,.95,0));await shot("proportions")
	for b in bodies:b.free()
	for i in range(4):
		var mesh=MeshFactory.box(stage,Vector3((i-1.5)*3,0.,0),Vector3(3,2,.2),Color.WHITE);mesh.material_override=WorldSurface.material("wall",17,false,0);mesh.material_override.set_shader_parameter("dynamic_lighting",true)
	camera.position=Vector3(0,.2,9);camera.look_at(Vector3.ZERO);await shot("brick-family")
	stage.free();await process_frame;quit()
