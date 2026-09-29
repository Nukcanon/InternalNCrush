extends SceneTree
# Heroes holding real GunModels (front and side views). Args: pitch
const WEAPONS=["a1","r2","e1","c1","pistol","heavy_pistol","h4","h5","h6","h1","e3","m2"]
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var args=OS.get_cmdline_user_args();var pitch=float(args[0]) if args.size()>0 else 0.
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,900)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,150,0);scene.add_child(light)
	var heroes=[]
	for i in range(WEAPONS.size()):
		var w=Catalog.get_weapon(WEAPONS[i])
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(i%6,i%2,true)
		hero.position=Vector3(-3.5+(i%6)*1.4,0,(i/6)*6.);hero.rotation.y=deg_to_rad(-150)
		var gun=GunModel.new();gun.build(w,true);hero.hold(gun)
		heroes.append([hero,{"pitch":pitch,"hold":GunLooks.hold_kind(w)}])
		var label=Label3D.new();label.text=str(w.name);label.position=hero.position+Vector3(0,2.05,0);label.font_size=40;label.pixel_size=.006;label.modulate=Color.BLACK;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;scene.add_child(label)
	for f in range(30):
		for pair in heroes:pair[0].drive(1./30.,pair[1].duplicate())
		await process_frame
	var camera=Camera3D.new();camera.fov=45;scene.add_child(camera);camera.current=true
	for row in range(2):
		camera.position=Vector3(0,1.7,4.3+row*6.);camera.look_at(Vector3(0,1.05,row*6.))
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../validation/armed-%d.png"%row)
	quit()
