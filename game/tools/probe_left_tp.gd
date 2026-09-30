extends SceneTree
## Debug: third-person heroes mirrored (scale.x = -1, left-handed) and not,
## holding a rifle and a pistol; prints the muzzle direction in hero space.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();root.size=Vector2i(1400,700)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");env.environment=e;world.add_child(env)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.4
	var i=0
	for hand in [1,-1]:
		for wid in ["a1","pistol","e1"]:
			var h=HeroCharacter.new();world.add_child(h);h.build(0,0,false);h.position=Vector3((i-2.5)*1.1,0,0);h.scale.x=hand;i+=1
			var gun=GunModel.new();gun.build(Catalog.get_weapon(wid),false);h.hold(gun)
			for k in range(20):h.drive(1./60.,{"hold":GunLooks.hold_kind(Catalog.get_weapon(wid)),"pitch":0.})
			await process_frame
			var d=h.global_basis.inverse()*(gun.muzzle.global_position-gun.right_grip.global_position).normalized()
			print("TP hand=",hand," ",wid," muzzle_dir_hero=",d.snapped(Vector3.ONE*.01))
	cam.position=Vector3(0,1.2,-5);cam.look_at(Vector3(0,1.,0))
	for k in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands2/tp-left-right.png")
	cam.position=Vector3(5,1.4,-1);cam.look_at(Vector3(0,1.,0))
	for k in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands2/tp-left-right-side.png")
	quit()
