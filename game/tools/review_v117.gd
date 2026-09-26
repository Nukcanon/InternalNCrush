extends SceneTree
const OUT="res://../validation/v117/"
func _initialize():call_deferred("run")
func capture(name:String):
	for frame in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image()
	if img.is_empty() or img.save_jpg(OUT+name+".jpg",.93)!=OK:quit(1)
func run():
	root.size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(OUT)
	TouchControls.supported_cache=0
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	g.ui.settings();await capture("settings")
	g.ui.join_menu();await capture("lan")
	g.ui.internet_menu();await capture("internet")
	PracticeSession.start(g);await create_timer(1.).timeout;g.set_physics_process(false);g.ui.practice_hint_until=0
	var p=g.players[1];var a=g.actors[1];p.protect=0.;g.ui.refresh();a.visual(1./60.,p,g.clock)
	await capture("controls")
	TouchControls.supported_cache=1
	g.touch=TouchControls.new();g.touch.game=g;g.ui.root.add_child(g.touch);g.ui.show_hud();g.touch._process(1.);g.ui.refresh()
	await capture("touch")
	g.touch.free();g.touch=null;TouchControls.supported_cache=0;g.ui.show_hud()
	p.slot=4;p.role=0;a.visual(1./60.,p,g.clock);g.ui.refresh();await capture("knife-held")
	for handed in [1,-1]:
		p.hand=handed
		for role in [0,3]:
			p.role=role
			for index in range(4):
				p.melee_started=g.clock-[0.,.18,.30,.42][index]
				for frame in range(12):a.visual(1./60.,p,g.clock)
				g.ui.refresh();await capture("grip-%d-%d-%d"%[role,handed,index])
	g.ui.hud.hide();p.hand=1;p.melee_started=-100.;a.visual(1./60.,p,g.clock)
	a.set_local(false);a.render_root.show()
	var camera=Camera3D.new();g.add_child(camera);camera.position=a.position+Vector3(1.4,1.1,-2.);camera.look_at(a.position+Vector3.UP*1.2);camera.current=true
	for role in [0,3]:
		p.role=role
		for index in range(3):
			p.melee_started=g.clock-[1.,.22,.40][index];a.visual(1./60.,p,g.clock);await capture("world-%d-%d"%[role,index])
	# Close-up replay-only copper bullet and separate knife/wrench wall marks.
	g.free();await process_frame
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env);env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("6b7c86");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8
	var light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,-20,0)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.near=.005;camera.position=Vector3(.07,.045,.11);camera.look_at(Vector3.ZERO)
	var bullet=ReplayProjectile.make(world);await capture("replay-bullet");bullet.free()
	for web in [false,true]:
		var wall=MeshFactory.box(world,Vector3(0,-.02,0),Vector3(1.5,.04,.65),Color("a7a398"))
		camera.position=Vector3(0,1.15,.35);camera.look_at(Vector3.ZERO)
		var marks=[]
		for index in range(3):
			var mark=BulletMark.make(web) if index==0 else MeleeMark.make(web,index==2);world.add_child(mark);mark.position=Vector3((index-1)*.48,.006,0);marks.append(mark)
		await capture("marks-web" if web else "marks-native")
		for mark in marks:mark.free()
		wall.free()
	world.free();print("V117_REVIEW_OK");quit()
