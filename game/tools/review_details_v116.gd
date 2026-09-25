extends SceneTree
var directory="res://../validation/details-v116/"
func _initialize():call_deferred("run")
func picture() -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run():
	root.size=Vector2i(640,480);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(directory)
	Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	var environment=WorldEnvironment.new();environment.environment=Environment.new();world.add_child(environment)
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("677c89")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.8
	var lamp=DirectionalLight3D.new();world.add_child(lamp);lamp.rotation_degrees=Vector3(-40,-25,0)
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=70.
	for id in Catalog.weapons:
		var gun=WeaponVisual.new();world.add_child(gun);gun.build(Catalog.get_weapon(id),true,false)
		var sheet=Image.create(1280,1440,false,Image.FORMAT_RGB8)
		for index in range(6):
			camera.position=Vector3.ZERO;camera.rotation=Vector3.ZERO
			gun.position=Vector3(.255,-.255,-.46);gun.scale.x=1.
			var phase=-1.
			if index==1:gun.position.x=-.255;gun.scale.x=-1.
			if index>=2:
				phase=[.30,.48,.62,.85][index-2]
				gun.position=Vector3.ZERO;camera.position=Vector3(-.75,.08,.50);camera.look_at(Vector3(0,-.13,-.20))
			gun.animate_reload(phase,0.)
			var image=await picture();image.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(image,Rect2i(0,0,640,480),Vector2i((index%2)*640,(index/2)*480))
		sheet.save_jpg(directory+id+".jpg",.94);gun.free()
	var model=CharacterVisual.new();model.enable_physics=false;world.add_child(model);model.build(0,0)
	var weapon=WeaponVisual.new();model.socket.add_child(weapon);weapon.build(Catalog.get_weapon("a1"),false);weapon.scale=Vector3.ONE*.8
	camera.position=Vector3(1.55,1.15,-2.2);camera.look_at(Vector3(0,.78,0))
	var floor_mesh=MeshFactory.box(world,Vector3(0,-.05,0),Vector3(6,.1,6),Color("99a3a5"))
	for state in range(6):
		var move=Vector3.ZERO if state<2 else Vector3(0,0,-1.5) if state<4 else Vector3(0,4 if state==4 else -4,0)
		for frame in range(40):
			model.update_pose(1./60.,move,false,state in [1,2,3],state<4,0.,-1.,0.,.12 if state==2 else .62)
			await process_frame
		var img=await picture();img.save_jpg(directory+"motion-"+str(state)+".jpg",.94)
	world.free();await process_frame;print("DETAILS_REVIEW_OK weapons=",Catalog.weapons.size());quit()
