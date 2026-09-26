extends SceneTree
const OUT="res://../validation/v118/"
func _initialize():call_deferred("run")
func capture(name:String):
	for frame in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.save_jpg(OUT+name+".jpg",.92)
func run():
	root.size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env);env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("526779");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.9;env.environment.ambient_light_sky_contribution=0.
	var light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,-20,0)
	var fill=DirectionalLight3D.new();world.add_child(fill);fill.light_energy=1.5
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.04;camera.fov=82.
	var mount=Node3D.new();camera.add_child(mount);mount.position=Vector3(.255,-.255,-.46)
	for wid in Catalog.weapons:
		if "--quick" in OS.get_cmdline_user_args() and wid not in ["m1","h4","m3","a1"]:continue
		var w=Catalog.get_weapon(wid);var gun=WeaponVisual.new();mount.add_child(gun);gun.build(w);gun.scale=Vector3.ONE*.85
		for index in range(3):
			gun.animate_reload([-1.,.40,.65][index],0.,10.);await capture("weapon-%s-%d"%[wid,index])
		gun.free()
	for role in [0,3]:
		for handed in [1,-1]:
			mount.scale.x=handed;mount.position.x=.255*handed
			var melee=MeleeVisual.new();mount.add_child(melee);melee.build(role==3,role,true)
			for index in range(4):melee.pose([-1.,.07,.13,.2][index]);await capture("melee-%d-%d-%d"%[role,handed,index])
			melee.free()
	mount.scale.x=1.;mount.position.x=.255
	for role in range(6):
		for variant in [0,1,8]:
			if variant==1 and role not in [0,3,4]:continue
			var item=GadgetVisual.new();mount.add_child(item);item.build(role,variant,true);await capture("gadget-%d-%d"%[role,variant]);item.free()
	world.free();await process_frame
	TouchControls.supported_cache=0
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.phase="lobby";g.server=true;g.local_id=1;g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(50,50);g.arena.has_water=false;g.arena.spawn_points=[[Vector3.ZERO],[Vector3(10,0,10)]];g.add_player(1,"Review","review");g.players[1].alive=true
	g.ui.gear()
	for role in range(6):
		g.ui.gear_class.select(role);g.ui.refresh_weapons();g.ui.gear_category=4;g.ui.preview_kind=4;g.ui.refresh_gear_detail();g.ui.refresh_gear_cards();await capture("skill-%d"%role)
	g.ui.gear_category=0;g.ui.preview_kind=1;g.ui.gear_class.select(2);g.ui.refresh_weapons();g.ui.refresh_gear_cards();await capture("gear-heavy")
	g.ui.settings();await capture("settings")
	g.free();await process_frame;print("V118_REVIEW_OK");quit()
