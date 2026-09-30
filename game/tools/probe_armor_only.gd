extends SceneTree
## Debug: the fitted armour alone (body hidden), culled and unculled.
const OUT="res://../validation/armor-v142/"
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1200,700)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");env.environment=e;world.add_child(env)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=1.2
	var heroes=[]
	for i in range(4):
		var h=HeroCharacter.new();world.add_child(h);h.build(0,0,false);h.play("Idle");h.set_armor(1 if i<2 else 2)
		h.position=Vector3((i-1.5)*.7,0,0);heroes.append(h)
		if i%2==1:
			for m in h.meshes():
				if m.name!="FittedArmor":m.hide()
	cam.position=Vector3(0,1.25,-6);cam.look_at(Vector3(0,1.25,0));await shot("probe-front")
	cam.position=Vector3(0,1.25,6);cam.look_at(Vector3(0,1.25,0));await shot("probe-back")
	for h in heroes:
		var a=h.skeleton.get_node("FittedArmor");var mat=StandardMaterial3D.new();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.vertex_color_use_as_albedo=true;a.set_surface_override_material(0,mat)
	cam.position=Vector3(0,1.25,-6);cam.look_at(Vector3(0,1.25,0));await shot("probe-front-nocull")
	quit()
