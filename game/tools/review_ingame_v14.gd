extends SceneTree
# In-game check of the 1.4 heroes: first person (hip / aim / pistol), and a third
# person group shot with several roles and weapons on a real map.
var g:Node
var out="res://../validation/v14-ingame/"
func _initialize():call_deferred("run")
func shot(label:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func settle(actors:Array,frames:int=20):
	for i in range(frames):
		for a in actors:a.visual(1./30.,g.players[a.pid],g.clock)
		await process_frame
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.slot=0;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	await settle([a])
	print("DBG hand ",a.handedness," p.hand ",p.get("hand","none")," gun.scale ",a.gun.scale," gun.pos ",a.gun.position)
	print("DBG gun_in_cam ",a.camera.to_local(a.view_weapon.global_position)," mount ",a.camera.to_local(a.view_mount.global_position)," frame ",a.camera.to_local(a.view_body.weapon_frame.global_position)," parent ",a.view_weapon.get_parent().name," body ",a.camera.to_local(a.view_body.global_position))
	await shot("fp-rifle-hip")
	a.input_state.ads=true;a.aim_progress=1.;a.ads_blend=1.;await settle([a]);await shot("fp-rifle-aim")
	a.input_state.ads=false;a.ads_blend=0.
	p.primary="r2";a.shown_weapon="";await settle([a]);await shot("fp-sniper-hip")
	p.slot=1;p.secondary="pistol";a.shown_weapon="";await settle([a]);await shot("fp-pistol")
	p.slot=0;p.primary="h4";a.shown_weapon="";await settle([a]);await shot("fp-rocket")
	# Charge handling: keypad presses in first person.
	g.options.mode=4;g.bomb={"planted":false,"site":0,"time":0.,"actor":1,"progress":.3,"position":Vector3.ZERO};p.slot=0;p.primary="a1";a.shown_weapon=""
	for k in range(3):
		g.clock=100.+k*.11;await settle([a],12);await shot("fp-bomb-%d"%k)
	g.options.mode=0;g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO}
	# Third person group.
	var group=[]
	var loadout=[[0,"a1"],[1,"r1"],[2,"h1"],[3,"e1"],[4,"c2"],[5,"m2"]]
	for i in range(loadout.size()):
		var id=-(i+1);g.add_player(id,"BOT%d"%i,"v14_bot%d"%i);g.spawn(id)
		var q=g.players[id];q.role=loadout[i][0];q.primary=loadout[i][1];q.slot=0;q.team=i%2;q.protect=0.;q.alive=true
		var b=g.actors[id];b.set_team(q.team);b.position=a.position+Vector3(-3.75+i*1.5,0,-5.);b.aim_yaw=PI+(i-2.5)*.15;b.rotation.y=b.aim_yaw;group.append(b)
	a.set_local(false);a.visible=false
	var camera=Camera3D.new();root.add_child(camera);camera.fov=55;camera.current=true
	camera.position=a.position+Vector3(0,1.7,-1.2);camera.look_at(a.position+Vector3(0,1.1,-5.))
	await settle(group,30);await shot("tp-group")
	for i in range(group.size()):group[i].input_state.crouch=i%2==0;group[i].aim_pitch=-.25+i*.1
	await settle(group,30);await shot("tp-group-crouch-pitch")
	print("V14_INGAME_OK");quit()
