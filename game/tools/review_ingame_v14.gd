extends SceneTree
# In-game check of the 1.4 heroes: first person (hip / aim for rifles, pistol,
# dual pistols, knife, wrench, grenade, launcher, bomb keypad), and a third person
# group shot with several roles, weapons and held items on a real map.
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
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	await settle([a])
	print("DBG hand ",a.handedness," p.hand ",p.get("hand","none")," gun.scale ",a.gun.scale," gun.pos ",a.gun.position)
	print("DBG gun_in_cam ",a.camera.to_local(a.view_weapon.global_position)," mount ",a.camera.to_local(a.view_mount.global_position)," frame ",a.camera.to_local(a.view_body.weapon_frame.global_position)," parent ",a.view_weapon.get_parent().name," body ",a.camera.to_local(a.view_body.global_position))
	print("DBG gun.rot ",a.gun.rotation," weapon_in_cam_euler ",(a.camera.global_basis.inverse()*a.view_weapon.global_basis).get_euler()," weapon.transform ",a.view_weapon.transform," frame_basis ",a.view_body.weapon_frame.basis," mount_basis ",a.view_mount.basis)
	await shot("fp-rifle-hip")
	print("DBG after shot gun.rot ",a.gun.rotation," gun.pos ",a.gun.position," weapon_in_cam ",a.camera.to_local(a.view_weapon.global_position)," euler ",(a.camera.global_basis.inverse()*a.view_weapon.global_basis).get_euler()," muzzle_in_cam ",a.camera.to_local(a.view_weapon.muzzle.global_position)," sprint ",a.last_sprint," cam.rot ",a.camera.rotation," cam.pos ",a.camera.position)
	print("DBG unproject butt ",a.camera.unproject_position(a.view_weapon.global_position)," muzzle ",a.camera.unproject_position(a.view_weapon.muzzle.global_position)," cam_basis ",a.camera.global_basis," det ",a.camera.global_basis.determinant()," actor_basis ",a.global_basis," current_cam ",get_root().get_camera_3d()==a.camera," fov ",a.camera.fov)
	print("DBG wristR ",a.camera.unproject_position(a.view_body.bone_world(a.view_body.bone["Wrist.R"]).origin)," wristL ",a.camera.unproject_position(a.view_body.bone_world(a.view_body.bone["Wrist.L"]).origin)," rightgrip ",a.camera.unproject_position(a.view_weapon.right_grip.global_position)," leftgrip ",a.camera.unproject_position(a.view_weapon.left_grip.global_position))
	if "quick" in OS.get_cmdline_user_args():quit();return
	var aim=func(on:bool):
		a.input_state.ads=on;a.aim_progress=1. if on else 0.;a.ads_blend=1. if on else 0.
	aim.call(true);await settle([a]);await shot("fp-rifle-aim");aim.call(false)
	p.primary="e1";a.shown_weapon="";await settle([a]);await shot("fp-shotgun-hip")
	aim.call(true);await settle([a]);await shot("fp-shotgun-aim");aim.call(false)
	p.primary="r2";a.shown_weapon="";await settle([a]);await shot("fp-sniper-hip")
	p.slot=1;p.secondary="pistol";a.shown_weapon="";await settle([a]);await shot("fp-pistol-hip")
	aim.call(true);await settle([a]);await shot("fp-pistol-aim");aim.call(false)
	p.secondary="dual_pistols";a.shown_weapon="";await settle([a]);await shot("fp-dual-hip")
	aim.call(true);await settle([a]);await shot("fp-dual-aim");aim.call(false)
	p.slot=0;p.primary="h4";a.shown_weapon="";await settle([a]);await shot("fp-rocket")
	# Melee: knife (any role) and the engineer's wrench, idle and mid swing.
	p.slot=MeleeCombat.SLOT;p.primary="a1";a.shown_weapon="";await settle([a]);await shot("fp-knife-idle")
	p.melee_started=g.clock-.09;await settle([a],2);await shot("fp-knife-swing");p.erase("melee_started")
	p.role=3;a.set_team(0);await settle([a]);await shot("fp-wrench-idle");p.role=0;a.set_team(0)
	# Grenade held (cooking) in one hand.
	p.slot=2;p.gadget=1;p.cooking=1;p.grenade_started=g.clock-.4;await settle([a]);await shot("fp-grenade-cook")
	p.cooking=0;p.erase("grenade_started");p.slot=0
	# Reload hand work: three phases per reload style (magazine out, swap, rack /
	# shell to port / rocket into the tube), plus the launchers at rest.
	for entry in [["a1",0,"rifle"],["pistol",1,"pistol"],["e1",0,"shotgun"],["h4",0,"comet"],["h5",0,"quad"],["h6",0,"laser"]]:
		p.slot=entry[1]
		if entry[1]==0:p.primary=entry[0]
		else:p.secondary=entry[0]
		a.shown_weapon="";p.reload=0.;p.mag[entry[0]]=0 if entry[2]!="quad" else 2;await settle([a])
		if entry[2] in ["comet","quad"]:
			p.mag[entry[0]]=1 if entry[2]=="comet" else 4;await settle([a]);await shot("fp-%s-loaded"%entry[2]);p.mag[entry[0]]=0 if entry[2]=="comet" else 2
		var w=Catalog.get_weapon(entry[0]);p.reload_tactical=false;p.reload_weapon=entry[0]
		for phase in [.15,.45,.7,.9]:
			p.reload=g.clock+float(w.reload)*(1.-phase);p.reload_started=g.clock-float(w.reload)*phase
			await settle([a],3);await shot("fp-reload-%s-%02d"%[entry[2],int(phase*100)])
		p.reload=0.;p.mag[entry[0]]=int(w.mag)
	p.slot=0;p.primary="a1";a.shown_weapon="";await settle([a])
	# Left-handed (mirrored) player: rifle, aim, pistol, pair and knife.
	p.hand=-1;p.primary="a1";a.shown_weapon="";await settle([a]);await shot("fp-left-rifle-hip")
	aim.call(true);await settle([a]);await shot("fp-left-rifle-aim");aim.call(false)
	p.slot=1;p.secondary="pistol";a.shown_weapon="";await settle([a]);await shot("fp-left-pistol-hip")
	p.secondary="dual_pistols";a.shown_weapon="";await settle([a]);await shot("fp-left-dual-hip")
	p.slot=MeleeCombat.SLOT;await settle([a]);await shot("fp-left-knife-idle")
	p.hand=1;p.slot=0;a.shown_weapon="";await settle([a])
	# Charge handling: keypad presses in first person.
	g.options.mode=4;g.bomb={"planted":false,"site":0,"time":0.,"actor":1,"progress":.3,"position":Vector3.ZERO};p.slot=0;p.primary="a1";a.shown_weapon=""
	for k in range(3):
		g.clock=100.+k*.11;await settle([a],12);await shot("fp-bomb-%d"%k)
	g.options.mode=0;g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO}
	# Third person group: rifle, sniper, launcher, wrench, dual pistols, pistol.
	var group=[]
	var loadout=[[0,"a1","pistol",0],[1,"r1","pistol",0],[5,"m2","pistol",1],[3,"e1","pistol",MeleeCombat.SLOT],[4,"c2","dual_pistols",1],[2,"h1","pistol",0]]
	for i in range(loadout.size()):
		var id=-(i+1);g.add_player(id,"BOT%d"%i,"v14_bot%d"%i);g.spawn(id)
		var q=g.players[id];q.role=loadout[i][0];q.primary=loadout[i][1];q.secondary=loadout[i][2];q.slot=loadout[i][3];q.team=i%2;q.protect=0.;q.alive=true
		var b=g.actors[id];b.set_team(q.team);b.position=a.position+Vector3(-3.75+i*1.5,0,-5.);b.aim_yaw=PI+(i-2.5)*.15;b.rotation.y=b.aim_yaw;group.append(b)
	a.set_local(false);a.visible=false
	var camera=Camera3D.new();root.add_child(camera);camera.fov=55;camera.current=true
	camera.position=a.position+Vector3(0,1.7,-1.2);camera.look_at(a.position+Vector3(0,1.1,-5.))
	# BOT0 (rifle) and BOT2 (pistol) are mid-reload: the support hand works the gun.
	for k in [0,2]:
		var q=g.players[-(k+1)];var wq=Catalog.get_weapon(q.primary if q.slot==0 else q.secondary)
		q.reload=g.clock+float(wq.reload)*.55;q.reload_started=g.clock-float(wq.reload)*.45;q.reload_tactical=false;q.reload_weapon=q.primary if q.slot==0 else q.secondary
	await settle(group,30);await shot("tp-group")
	for k in [0,2]:g.players[-(k+1)].reload=0.
	for i in range(group.size()):group[i].input_state.crouch=i%2==0;group[i].aim_pitch=-.25+i*.1
	await settle(group,30);await shot("tp-group-crouch-pitch")
	# Close-up of the held items from the side.
	for i in range(group.size()):group[i].input_state.crouch=false;group[i].aim_pitch=0.
	camera.position=a.position+Vector3(2.4,1.5,-4.2);camera.look_at(a.position+Vector3(-1.,1.15,-5.));camera.fov=40
	await settle(group,30);await shot("tp-group-side")
	print("V14_INGAME_OK");quit()
