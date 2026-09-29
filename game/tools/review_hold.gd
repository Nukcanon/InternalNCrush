extends SceneTree
# Heroes driven through HeroCharacter.drive() holding placeholder items.
func _initialize():call_deferred("run")
func placeholder(pistol:bool) -> Node3D:
	var item=Node3D.new()
	var mesh=MeshInstance3D.new();var box=BoxMesh.new()
	box.size=Vector3(.05,.1,.22) if pistol else Vector3(.06,.09,.8);mesh.mesh=box;mesh.position=Vector3(0,0,-.08) if pistol else Vector3(0,.0,-.38)
	var m=StandardMaterial3D.new();m.albedo_color=Color("333844");mesh.material_override=m;item.add_child(mesh)
	var right=Marker3D.new();right.name="RightGrip";right.position=Vector3(0,-.06,0) if pistol else Vector3(0,-.07,-.17);item.add_child(right)
	var left=Marker3D.new();left.name="LeftGrip";left.position=Vector3(-.035,-.07,.01) if pistol else Vector3(0,-.06,-.46);item.add_child(left)
	return item
func run():
	var args=OS.get_cmdline_user_args();var role=int(args[0]) if args.size()>0 else 0
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,900)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,150,0);scene.add_child(light)
	var cases=[["aim 0",{"pitch":0.}],["aim +0.7",{"pitch":.7}],["aim -0.7",{"pitch":-.7}],["walk",{"velocity":Vector3(0,0,-2.4)}],["run strafe",{"velocity":Vector3(4,0,0)}],["crouch",{"crouch":true}],
		["sprint",{"velocity":Vector3(0,0,-7),"sprint":true}],["air",{"grounded":false}],["pistol",{"hold":"pistol","pistol":true}],["pistol up",{"hold":"pistol","pistol":true,"pitch":.6}],["reload",{"reload":.4,"reload_time":2.}],["plant",{"plant":true,"hold":"none"}]]
	var heroes=[]
	for i in range(cases.size()):
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(role,i%2,true)
		hero.position=Vector3(-3.5+(i%6)*1.4,0,(i/6)*6.);hero.rotation.y=deg_to_rad(-150)
		var s:Dictionary=cases[i][1].duplicate()
		var item=placeholder(bool(s.get("pistol",false)));hero.hold(item)
		heroes.append([hero,s])
		var label=Label3D.new();label.text=cases[i][0];label.position=hero.position+Vector3(0,2.05,0);label.font_size=40;label.pixel_size=.006;label.modulate=Color.BLACK;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;scene.add_child(label)
	for f in range(40):
		for pair in heroes:
			var s:Dictionary=pair[1].duplicate()
			if s.has("velocity"):s.velocity=pair[0].global_basis*s.velocity
			pair[0].drive(1./30.,s)
		await process_frame
	var camera=Camera3D.new();camera.fov=45;scene.add_child(camera);camera.current=true
	if args.size()>1 and args[1]=="hands":
		var h:HeroCharacter=heroes[int(args[2]) if args.size()>2 else 0][0]
		var focus=h.bone_world(h.bone["Wrist.R"]).origin.lerp(h.bone_world(h.bone["Wrist.L"]).origin,.5)
		camera.fov=30;camera.position=focus+h.global_basis*Vector3(-.35,.12,-.55);camera.look_at(focus)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/hold-hands.png");quit();return
	for row in range(2):
		camera.position=Vector3(0,1.7,4.3+row*6.);camera.look_at(Vector3(0,1.05,row*6.))
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/hold-%d-%d.png"%[role,row])
	quit()
