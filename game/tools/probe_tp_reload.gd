extends SceneTree
## Debug: third-person reload frames (rifle magazine, revolver, DUET) side by side.
func _initialize():call_deferred("run")
func run():
	Catalog.load_all();root.size=Vector2i(1500,700)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");env.environment=e;world.add_child(env)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.2
	var i=0
	for spec in [["a1",.15],["a1",.4],["a1",.7],["heavy_pistol",.5],["dual_pistols",.25]]:
		var w=Catalog.get_weapon(spec[0])
		var h=HeroCharacter.new();world.add_child(h);h.build(0,0,false);h.position=Vector3((i-2.)*.9,0,0);h.rotation.y=-PI/2;i+=1
		var gun=GunModel.new();gun.build(w,false);h.hold(gun)
		for k in range(12):
			gun.animate_reload(spec[1]);h.drive(1./60.,{"hold":GunLooks.hold_kind(w),"pitch":0.,"reload":spec[1],"reload_time":float(w.reload),"two_hands":GunLooks.hold_kind(w)=="pistol"})
	cam.position=Vector3(0,1.,-6);cam.look_at(Vector3(0,1.,0))
	for k in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/hands2/tp-reloads.png")
	quit()
