extends SceneTree
# Rear-loading check of the launchers: first person reload phases (right and
# left handed), third person reload from the side, and a rocket in flight.
var g:Node
var out="res://../validation/launchers/"
func _initialize():call_deferred("run")
func shot(label:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func settle(actors:Array,frames:int=20):
	for i in range(frames):
		for a in actors:a.visual(1./30.,g.players[a.pid],g.clock)
		await process_frame
func reload_at(p:Dictionary,id:String,phase:float):
	var w=Catalog.get_weapon(id)
	p.reload=g.clock+float(w.reload)*(1.-phase);p.reload_started=g.clock-float(w.reload)*phase;p.reload_tactical=false;p.reload_weapon=id
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=2;p.primary="h4";p.secondary="pistol";p.slot=0;p.team=0
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	for hand in [1,-1]:
		p.hand=hand
		for entry in [["h4","comet",0],["h5","quad",2]]:
			p.primary=entry[0];a.shown_weapon="";p.reload=0.;p.mag[entry[0]]=int(Catalog.get_weapon(entry[0]).mag);await settle([a])
			if hand==1:await shot("fp-%s-loaded"%entry[1])
			p.mag[entry[0]]=entry[2]
			for phase in ([.2,.4,.52,.66,.8,.93] if hand==1 else [.52,.7]):
				reload_at(p,entry[0],phase)
				await settle([a],14);await shot("fp-%s%s-%02d"%[entry[1],"" if hand==1 else "-left",int(phase*100)])
			p.reload=0.;await settle([a],14)
	p.hand=1
	# Third person: two heavies mid reload, seen from the side and the back.
	var group=[]
	for i in range(2):
		var id=-(i+1);g.add_player(id,"BOT%d"%i,"v14_bot%d"%i);g.spawn(id)
		var q=g.players[id];q.role=2;q.primary=["h4","h5"][i];q.slot=0;q.team=i;q.protect=0.;q.alive=true;q.mag[q.primary]=[0,2][i]
		var b=g.actors[id];b.set_team(q.team);b.position=a.position+Vector3(-.9+i*1.8,0,-5.);b.aim_yaw=PI;b.rotation.y=b.aim_yaw;group.append(b)
	a.set_local(false);a.visible=false
	var camera=Camera3D.new();root.add_child(camera);camera.fov=40;camera.current=true
	for phase in [.0,.45,.6,.8]:
		for i in range(2):
			if phase>0.:reload_at(g.players[-(i+1)],["h4","h5"][i],phase)
		await settle(group,20)
		camera.position=a.position+Vector3(3.2,1.5,-4.4);camera.look_at(a.position+Vector3(0,1.15,-5.))
		await shot("tp-side-%02d"%int(phase*100))
		camera.position=a.position+Vector3(-.6,1.7,-8.2);camera.look_at(a.position+Vector3(0,1.15,-5.))
		await shot("tp-back-%02d"%int(phase*100))
	# A rocket in flight, flying left to right past the camera.
	for i in range(2):g.players[-(i+1)].reload=0.
	var from=a.position+Vector3(-1.5,1.4,-3.)
	g.combat_fx.sync_rockets([{"pos":from,"velocity":Vector3(30,2,0)}])
	camera.position=from+Vector3(0,.2,1.6);camera.look_at(from);camera.fov=30
	await shot("rocket-flight")
	print("LAUNCHERS_OK");quit()
