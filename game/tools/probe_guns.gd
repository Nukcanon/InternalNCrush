extends SceneTree
# Side views of every baked gun base (scale 1) with a 10 cm grid and the
# markers (RightGrip red, LeftGrip blue, Muzzle green) to author hand handles.
const BASES=["AK","SMG","Pistol","Revolver","Revolver_Small","Shotgun","ShortCannon","Sniper","Sniper_2","RocketLauncher","GrenadeLauncher","Knife_1"]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1600,1000)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e8ecef");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,60,0);scene.add_child(light)
	# Grid lines every 10 cm (z along, y up) drawn as thin boxes in the plane x=-.2.
	var grid=Node3D.new();scene.add_child(grid)
	for i in range(-14,5):MeshFactory.box(grid,Vector3(-.25,0,i*.1),Vector3(.002,1.,.002),Color("b0b8c0") if i%5 else Color("606870"))
	for j in range(-4,6):MeshFactory.box(grid,Vector3(-.25,j*.1,-.5),Vector3(.002,.002,1.9),Color("b0b8c0") if j%5 else Color("606870"))
	var cam=Camera3D.new();scene.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=1.0;cam.position=Vector3(2,.05,-.5);cam.look_at(Vector3(0,.05,-.5));cam.current=true
	for name in BASES:
		var gun:Node3D=GunModel.base_scene(name).instantiate();scene.add_child(gun)
		for m in gun.find_children("*","MeshInstance3D",true,false):
			for s in range(m.mesh.get_surface_count()):m.set_surface_override_material(s,HeroStyle.tinted(Color("7d8794"),false,.2))
		for marker in [["RightGrip",Color.RED],["LeftGrip",Color.BLUE],["Muzzle",Color.GREEN]]:
			var n=gun.get_node_or_null(marker[0])
			if n:MeshFactory.sphere(scene,n.position,Vector3.ONE*.012,marker[1])
		var label=Label3D.new();label.text=name;label.position=Vector3(0,.42,-.5);label.rotation.y=PI*.5;label.font_size=40;label.pixel_size=.003;label.modulate=Color.BLACK;scene.add_child(label)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/guns/"+name+".png")
		gun.queue_free();label.queue_free()
		for s in scene.get_children():
			if s is MeshInstance3D:s.queue_free()
		await process_frame
	quit()
