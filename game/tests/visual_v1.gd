extends SceneTree
var output="res://../validation/v1-visual"
func _initialize():call_deferred("run")
func capture(label:String):
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run():
	DisplayServer.window_set_size(Vector2i(1440,900));root.size=Vector2i(1440,900)
	DirAccess.make_dir_recursive_absolute(output);Catalog.load_all()
	var stage=Node3D.new();root.add_child(stage)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("d5ddda");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("f1f0e3");e.ambient_light_energy=.65;env.environment=e;stage.add_child(env)
	var light=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=1.0;light.shadow_enabled=true
	MeshFactory.box(stage,Vector3(0,-.1,0),Vector3(20,.2,12),Color("b7c0b7"))
	var camera=Camera3D.new();stage.add_child(camera);camera.current=true;camera.position=Vector3(0,1.5,8.5);camera.look_at(Vector3(0,1.1,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.8
	var models=[]
	for role in range(6):
		var body=CharacterVisual.new();stage.add_child(body);body.position=Vector3((role-2.5)*1.3,0,0);body.build(role,role%2);body.rotation.y=PI;models.append(body)
		var weapon=WeaponVisual.new();body.socket.add_child(weapon);weapon.build(Catalog.get_weapon(["a1","r1","h1","e1","c1","m1"][role]),false);weapon.scale=Vector3.ONE*.8
		for i in range(12):body.update_pose(.016,Vector3.ZERO,false,false,true,0,-1,0,0,0)
		var label=Label3D.new();stage.add_child(label);label.position=body.position+Vector3(0,2.15,0);label.text=Rules.CLASSES[role]+" / %d cm"%int(HumanModel.HEIGHTS[role]*100);label.font=load("res://assets/Korean.ttf");label.font_size=36;label.pixel_size=.003;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("293e43");label.outline_size=0
	await capture("operators")
	for child in stage.get_children():
		if child is Label3D:child.visible=false
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=48
	camera.position=models[0].position+Vector3(.20,1.60,1.5);camera.look_at(models[0].position+Vector3(0,1.51,0));await capture("face")
	for model in models:model.visible=false
	var props=[]
	for i in range(5):
		var p=InteractiveProp.new();p.configure(i,WorldDressing.KINDS[i],false);p.position=Vector3((i-2)*1.2,.5,2.);stage.add_child(p);props.append(p)
	camera.position=Vector3(3,3,8.);camera.look_at(Vector3(0,.5,2.));await capture("props")
	stage.queue_free();await process_frame;await process_frame;quit()
