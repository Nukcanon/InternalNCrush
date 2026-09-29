extends SceneTree
# First-person and third-person check of everything held besides guns:
# gadgets per role, grenade cooking, knife / wrench (idle and mid swing), the
# bomb keypad, turret / cover placing, medic LINK, FIX and TETHER.
var g:Node
var out="res://../validation/gear/"
func _initialize():call_deferred("run")
func shot(label:String):
	g.ui.refresh()
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+label+".png")
func settle(actors:Array,frames:int=20):
	for i in range(frames):
		for a in actors:a.visual(1./30.,g.players[a.pid],g.clock)
		await process_frame
func reset(p:Dictionary):
	p.slot=0;p.cooking=0;p.erase("grenade_started");p.placing="";p.erase("melee_started");p.gadget_count=3;p.owned_gadget=true
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(20):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=13
	g.build_world();g.add_player(1,"PLAYER","v14_local")
	g.ui.show_hud();g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true;p.role=0;p.primary="a1";p.secondary="pistol";p.slot=0;p.team=0;p.hand=1
	var a=g.actors[1];a.set_local(true);a.set_team(0)
	a.position=Vector3(0,.1,g.arena.bounds.y-8.);a.reset_view(0);await physics_frame
	# Held gadgets per role (slot 2): plate, bipod-less roles skip passives.
	for entry in [[0,0,"plate"],[0,1,"frag"],[3,0,"cover"],[4,0,"smoke"],[4,1,"flash"],[5,0,"medkit"],[0,9,"defuse"]]:
		reset(p);p.role=entry[0];p.gadget=entry[1];p.slot=2;a.shown_weapon="";await settle([a]);await shot("fp-gadget-"+entry[2])
	# Grenade cooking.
	reset(p);p.role=0;p.gadget=1;p.slot=2;p.cooking=1;p.grenade_started=g.clock-.4;await settle([a]);await shot("fp-grenade-cook")
	# Placing a turret (engineer skill) and a cover.
	reset(p);p.role=3;p.placing="turret";await settle([a]);await shot("fp-place-turret")
	reset(p);p.role=3;p.gadget=0;p.placing="cover";await settle([a]);await shot("fp-place-cover")
	# Melee: knife and wrench, idle / wind-up / cut.
	for role in [0,3]:
		reset(p);p.role=role;p.slot=MeleeCombat.SLOT;a.shown_weapon="";await settle([a])
		var tag="knife" if role!=3 else "wrench"
		await shot("fp-%s-idle"%tag)
		for age in [.08,.16,.26]:
			p.melee_started=g.clock-age;await settle([a],2);await shot("fp-%s-%02d"%[tag,int(age*100)])
		p.erase("melee_started")
	# Medic LINK, engineer FIX and TETHER.
	reset(p);p.role=5;p.primary="m1";a.shown_weapon="";await settle([a]);await shot("fp-link")
	reset(p);p.role=3;p.slot=1;p.secondary="repair";a.shown_weapon="";await settle([a]);await shot("fp-fix")
	reset(p);p.role=3;p.slot=0;p.primary="remote";a.shown_weapon="";await settle([a]);await shot("fp-tether")
	# Bomb keypad.
	reset(p);p.role=0;p.primary="a1";a.shown_weapon=""
	g.options.mode=4;g.bomb={"planted":false,"site":0,"time":0.,"actor":1,"progress":.3,"position":Vector3.ZERO}
	for k in range(2):
		g.clock=100.+k*.11;await settle([a],12);await shot("fp-bomb-%d"%k)
	g.options.mode=0;g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO};g.clock=100.
	# Third person: a lineup holding the same things.
	var group=[]
	var lineup=[[0,0,2,""],[3,0,2,""],[4,0,2,""],[5,0,2,""],[3,0,0,"turret"],[0,1,2,"cook"],[5,0,0,""],[3,0,1,""]]
	for i in range(lineup.size()):
		var id=-(i+1);g.add_player(id,"BOT%d"%i,"v14_bot%d"%i);g.spawn(id)
		var q=g.players[id];reset(q);q.role=lineup[i][0];q.gadget=lineup[i][1];q.slot=lineup[i][2];q.team=0;q.protect=0.;q.alive=true;q.hand=1
		q.primary={0:"a1",3:"e1",4:"c1",5:"m1"}.get(q.role,"a1");q.secondary="repair" if q.role==3 else "pistol"
		if lineup[i][3]=="turret":q.placing="turret"
		if lineup[i][3]=="cook":q.cooking=1;q.grenade_started=g.clock-.4
		if q.role==5 and q.slot==0:q.primary="m1"
		var b=g.actors[id];b.set_team(0);b.position=a.position+Vector3(-3.5+i*1.0,0,-4.);b.aim_yaw=PI;b.rotation.y=PI;group.append(b)
	a.set_local(false);a.visible=false
	var camera=Camera3D.new();root.add_child(camera);camera.fov=50;camera.current=true
	camera.position=a.position+Vector3(0,1.5,-1.4);camera.look_at(a.position+Vector3(0,1.1,-4.))
	await settle(group,30);await shot("tp-lineup")
	camera.position=a.position+Vector3(2.8,1.4,-2.2);camera.look_at(a.position+Vector3(-.5,1.1,-4.))
	await shot("tp-lineup-side")
	print("GEAR_OK");quit()
