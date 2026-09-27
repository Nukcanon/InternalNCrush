extends SceneTree
const OUT="res://../validation/v124/"
func _initialize():call_deferred("run")
func capture(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	Catalog.load_all();root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env)
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("526779");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.9
	var light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,-20,0)
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.04;camera.fov=82.
	var mount=Node3D.new();camera.add_child(mount)
	for id in ["dual_pistols","pistol","h4"]:
		mount.position=Vector3(0,-.19,-.56) if id=="dual_pistols" else Vector3(.255,-.255,-.46)
		for handed in [-1,1]:
			mount.scale.x=handed
			var gun=WeaponVisual.new();mount.add_child(gun);gun.build(Catalog.get_weapon(id));gun.scale=Vector3.ONE*.85
			for phase in [-1.,.2,.4,.65,.85]:
				gun.animate_reload(phase,0.,10.);await capture("hands-%s-%s-%s"%[id,handed,phase])
			gun.free()
	world.free();await process_frame
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=root.size
	preview.display(1,0,0,"dual_pistols");await capture("duet-inspection")
	for role in [0,1,5]:
		preview.display(0,role,0,"pistol",0,0);preview.camera.position=Vector3(0,1.05,-3);preview.camera.look_at(Vector3(0,1.05,0));preview.camera.size=.6
		await capture("waist-"+str(role))
	for item in [[1,0],[4,0],[4,1],[5,0],[0,9]]:
		preview.display(2,item[0],0,"pistol",item[1]);await capture("gadget-%d-%d"%[item[0],item[1]])
	preview.free();await process_frame
	world=Node3D.new();root.add_child(world)
	env=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env)
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("526779");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.9
	light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,-20,0)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.position=Vector3(0,1.5,4.2);camera.look_at(Vector3(0,1.5,0))
	var arena=Arena.new();world.add_child(arena);arena.props_authoritative=false
	for side in [-1,1]:arena.box(Vector3(side*2.075,1.5,0),Vector3(1.85,3.,.18),Color("a39d86"))
	arena.box(Vector3(0,-.05,0),Vector3(7,.1,5),Color("596a75"))
	var door=InteractiveDoor.new();arena.add_child(door);door.build(arena,1,Vector3.ZERO,0.);door.set_physics_process(false)
	for phase in [0.,.5,1.]:
		door.progress=phase;door.apply_pose();await capture("door-"+str(phase))
	door.free();arena.box(Vector3(0,1.5,0),Vector3(2.3,3.,.18),Color("a39d86"))
	for i in range(3):
		var mark=BulletMark.make(false) if i==0 else MeleeMark.make(false,i==2)
		world.add_child(mark);mark.position=Vector3((i-1)*.7,1.5,.095);mark.quaternion=Quaternion(Vector3.UP,Vector3.BACK);mark.scale=Vector3.ONE*3.
	camera.position=Vector3(0,1.5,2.5);await capture("flat-impact-marks")
	world.free();print("HANDS_REVIEW_OK");quit()
