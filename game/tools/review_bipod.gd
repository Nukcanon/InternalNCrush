extends SceneTree
# 1.5.4 (the user: the bipod gadget clamps on the primary's barrel - ahead of the front grip
# if there is room, else just behind the muzzle - and must never drift from the gun):
# 1) every heavy primary from the side with its bipod, 2) first person crouched (mounted)
# and mid-reload, with the bipod's offset from the barrel measured every frame.
# Output validation/bipod/*.jpg
var g:Node
func _initialize():call_deferred("run")
func lit(parent:Node3D):
	var light=DirectionalLight3D.new();light.rotation=Vector3(-.8,.5,0);parent.add_child(light)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e9e4d8");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.8,.8,.8);parent.add_child(env)
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	DirAccess.make_dir_recursive_absolute("res://../validation/bipod/")
	Catalog.load_all()
	var stage=Node3D.new();root.add_child(stage);lit(stage)
	var cam=Camera3D.new();stage.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=1.5
	var tiles=[]
	for wid in ["h1","h2","h4","h5","h6"]:
		var gun=GunModel.new();stage.add_child(gun);gun.build(Catalog.get_weapon(wid),true);gun.set_bipod(true)
		var length=absf(GunModel.relative(gun.muzzle,gun).origin.z)+.6
		var tipz=GunModel.relative(gun.muzzle,gun).origin.z;cam.size=(absf(tipz)+.45)/1.55;cam.position=Vector3(1.5,-.02,(tipz+.4)*.5);cam.rotation=Vector3(0,PI/2,0)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		var img=root.get_texture().get_image();img.resize(640,360);tiles.append(img)
		# close-up on the clamp, three-quarter view from below the barrel
		var mount:Node3D=gun.base.get_node("BipodMount")
		var at=Vector3(0,GunModel.relative(gun.muzzle,gun).origin.y-.05,tipz+.15)
		cam.projection=Camera3D.PROJECTION_PERSPECTIVE;cam.fov=30;cam.position=at+Vector3(.75,-.12,.25);cam.look_at(at)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		var close=root.get_texture().get_image();close.resize(640,360);close.save_jpg("res://../validation/bipod/close_%s.jpg"%wid,.9)
		cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.rotation=Vector3(0,PI/2,0)
		gun.queue_free();await process_frame
	var sheet=Image.create(1280,1080,false,tiles[0].get_format());sheet.fill(Color("e9e4d8"))
	for i in range(tiles.size()):sheet.blit_rect(tiles[i],Rect2i(0,0,640,360),Vector2i((i%2)*640,(i/2)*360))
	sheet.save_jpg("res://../validation/bipod/side_all.jpg",.9)
	stage.queue_free();await process_frame
	# first person
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13;g.options.classes=true
	g.build_world();g.add_player(1,"PLAYER","bipod_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.team=0;p.role=2;p.primary="h1";p.secondary=Catalog.secondaries_for(2)[0];p.slot=0;p.gadget=0;p.gadget_count=1
	var a=g.actors[1];a.set_local(true);a.set_team(0);a.shown_role=-1;a.shown_weapon=""
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	var step=1./60.
	a.input_state.crouch=true
	for i in range(60):g.clock+=step;a.visual(step,p,g.clock);await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://../validation/bipod/fp_crouched.jpg",.9)
	# reload: the bipod against the barrel (muzzle) every frame
	var w=Catalog.get_weapon("h1");p.reload=g.clock+float(w.reload);p.reload_started=g.clock
	var worst=0.;var start=null;var shot=false
	for i in range(int(float(w.reload)*60.)):
		g.clock+=step;a.visual(step,p,g.clock);await process_frame
		var gun=a.view_weapon
		if not is_instance_valid(gun):continue
		var mount:Node3D=gun.base.get_node_or_null("BipodMount") if is_instance_valid(gun.base) else null
		if mount==null:continue
		var rel:Vector3=gun.muzzle.global_transform.affine_inverse()*mount.global_transform.origin
		if start==null:start=rel
		worst=maxf(worst,(rel-start).length())
		if not shot and i>int(float(w.reload)*60.*.4):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg("res://../validation/bipod/fp_reload.jpg",.9);shot=true
	print("BIPOD drift from the barrel during reload %.3f mm (mount found %s)"%[worst*1000.,str(start!=null)])
	print("BIPOD_DONE");quit()


