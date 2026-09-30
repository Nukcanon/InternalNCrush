extends SceneTree
# Magazine split review (1.4.4): each magazine gun from the left side with the
# magazine seated and dropped 12 cm (a hollow magazine or a sliver left on the
# body shows here). Output: validation/hands2/mag-<wid>[-out].png
var out="res://../validation/hands2/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	Catalog.load_all()
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.55,.6,.66);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(1,1,1);env.environment.ambient_light_energy=.6;root.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation=Vector3(-.9,.6,0);root.add_child(sun)
	var cam=Camera3D.new();root.add_child(cam);cam.current=true;cam.fov=42.
	var only=OS.get_cmdline_user_args()
	for wid in ["a1","a3","c1","c4","r2","r1","h6","pistol","auto_pistol","e2"]:
		if not only.is_empty() and not wid in only:continue
		var gun=GunModel.new();gun.build(Catalog.get_weapon(wid),false);root.add_child(gun)
		for state in ["","-out","-out2"]:
			var t=-1. if state=="" else .18 if state=="-out" else .27
			gun.animate_reload(t)
			var centre:Vector3=gun.global_transform*(gun.right_grip.position*gun.base.scale+Vector3(0,-.04,-.12))
			var dist=.7 if wid in ["pistol","auto_pistol"] else 1.
			if wid in ["pistol","auto_pistol"]:dist=.45
			cam.global_position=centre+Vector3(-dist,.05,.05);cam.look_at(centre)
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"mag-"+wid+state+".png")
			# From below-front, where the well shows.
			cam.global_position=centre+Vector3(-dist*.5,-dist*.6,-dist*.5);cam.look_at(centre)
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"mag-"+wid+state+"-below.png")
		print("MAG ",wid," magazine=",gun.magazine!=null," surfaces=",gun.magazine.mesh.get_surface_count() if gun.magazine and gun.magazine is MeshInstance3D and gun.magazine.mesh else -1)
		gun.queue_free()
	print("MAG_REVIEW_OK");quit()
