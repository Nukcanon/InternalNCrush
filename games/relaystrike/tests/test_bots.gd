extends SceneTree
var g:Node
var checks=0
var failures=0
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
	else:print("PASS ",message)
func _initialize():call_deferred("run")
func steps(count:int):
	for i in range(count):
		g.clock+=1./60;g.server_tick(1./60)
		await physics_frame
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.dedicated=true;g.host_game();g.set_physics_process(false);g.options.skills=false;g.options.classes=false;g.options.mode=3;g.options.target=10000;g.phase="combat";g.remaining=1000
	g.add_player(-1,"NAV","nav");var p=g.players[-1];p.team=0;p.role=0;p.primary="a1";g.spawn(-1);g.actors[-1].position=Vector3(35,0,77)
	var brain=g.bot_agents[-1];var route=g.bot_navigation.route(Vector3(35,0,77),Vector3(-44,0,-23));expect(route.size()>20,"path crosses map around warehouse obstacles")
	var clear=true
	for pos in route:
		for rect in g.arena.obstacles:
			if rect.has_point(Vector2(pos.x,pos.z)):clear=false
	expect(clear,"path nodes avoid expanded static collision rectangles")
	var start=g.actors[-1].position;await steps(900)
	expect(g.actors[-1].position.distance_to(start)>25,"bot leaves spawn and passes obstacles")
	await steps(600)
	expect(0 in g.zone_owner,"bot autonomously captures a zone")
	print("BOT_NAV_POSITION ",g.actors[-1].position," goal=",brain.goal," action=",brain.action," stuck=",brain.stuck_count)
	g.options.mode=4;g.round_no=1;g.phase="combat";g.remaining=1000;g.bot_attack_site=0;g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO};brain.next_decision=0;brain.next_path=0;g.actors[-1].position=g.arena.sites[0]+Vector3(0,0,12)
	await steps(720)
	expect(g.bomb.planted,"attacking bot reaches site and plants")
	g.phase="combat";g.remaining=1000;p.team=1;g.bomb.planted=true;g.bomb.position=g.arena.sites[0];g.bomb.site=0;g.bomb.time=35.;g.bomb.actor=0;g.bomb.progress=0.;g.actors[-1].position=g.arena.sites[0]+Vector3(0,0,12);brain.next_decision=0;brain.next_path=0
	await steps(720)
	expect(g.scores[1]>0,"defending bot reaches device and defuses")
	print("BOT_TEST_RESULT ",checks-failures,"/",checks)
	g.leave_game();g.queue_free();await process_frame;quit(1 if failures else 0)
