extends SceneTree
# Close side views (right side, muzzle to the right) of the grip area of every
# baked base with a 1 cm grid (5 cm darker) to author grip boxes and triggers.
# Image 1000x1000, ortho size .30 m: 1 px = .3 mm. The centre point is printed.
const BASES=["AK","SMG","Pistol","Revolver","Revolver_Small","Shotgun","ShortCannon","Sniper","Sniper_2"]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1000,1000)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("f4f6f8");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,70,0);scene.add_child(light)
	var cam=Camera3D.new();scene.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=.30;cam.current=true
	DirAccess.make_dir_recursive_absolute("res://../validation/grips")
	for name in BASES:
		var gun:Node3D=GunModel.base_scene(name).instantiate();scene.add_child(gun)
		var h:Dictionary=GunModel.HANDLES.get(name,{})
		var right:Vector3=h.get("right",gun.get_node("RightGrip").position)
		var centre=Vector3(0,right.y+.03,right.z-.07)
		for m in gun.find_children("*","MeshInstance3D",true,false):
			for s in range(m.mesh.get_surface_count()):m.set_surface_override_material(s,HeroStyle.tinted(Color("9aa3ad"),false,.2))
		var grid=Node3D.new();scene.add_child(grid)
		for i in range(-16,17):
			var z=snappedf(centre.z,.01)+i*.01;var y=snappedf(centre.y,.01)+i*.01
			var dark=absi(int(round(z*100)))%5==0
			MeshFactory.box(grid,Vector3(.08,centre.y,z),Vector3(.0005,.4,.0006 if not dark else .0012),Color("7a8490") if dark else Color("c3cad2"))
			dark=absi(int(round(y*100)))%5==0
			MeshFactory.box(grid,Vector3(.08,y,centre.z),Vector3(.0005,.0006 if not dark else .0012,.4),Color("7a8490") if dark else Color("c3cad2"))
		MeshFactory.sphere(grid,right+Vector3(.06,0,0),Vector3.ONE*.004,Color.RED)
		cam.position=centre+Vector3(1,0,0);cam.look_at(centre)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/grips/"+name+".png")
		print("GRIP ",name," centre z=%.3f y=%.3f  right=%s"%[centre.z,centre.y,right])
		gun.queue_free();grid.queue_free();await process_frame
	quit()
