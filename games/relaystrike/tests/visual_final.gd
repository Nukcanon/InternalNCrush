extends SceneTree
var g:Node
func _initialize():call_deferred("run")
func capture(name:String):
	for frame in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-final-"+name+".png")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.profile.nick="Nukcanon";g.last_server_ip="";g.ui.menu()
	await create_timer(1.5).timeout;await capture("menu")
	g.server=true;g.phase="lobby";g.options.map=5;g.build_world();g.add_player(1,"Nukcanon","visual_final_host");g.players[1].team=0
	for i in range(1,32):g.add_player(-i,"BOT %02d"%i,"visual_final_bot"+str(i));g.players[-i].team=i%2;g.players[-i].role=i%6
	g.phase="combat";g.clock=100;g.remaining=568;g.ui.show_hud()
	var a=g.actors[1];a.position=Vector3(22,0,28);a.reset_view(0);a.camera.current=true
	for i in range(1,32):
		var actor=g.actors[-i];actor.position=a.position+Vector3((i%4-1.5)*3,0,-8-floor(i/4.)*6);actor.reset_view(PI);g.players[-i].protect=0.;actor.visual(.016,g.players[-i],100.)
	g.players[1].protect=0.;a.visual(.016,g.players[1],100.)
	for i in range(3):
		g.kill_event({"attacker":1 if i==0 else -i,"attacker_name":["Nukcanon #01","푸른하늘 #02","푸른하늘 #03"][i],"attacker_team":i%2,"victim":-i-4,"victim_name":["푸른하늘 #03","푸른하늘 #02","BOT 04"][i],"victim_team":1-i%2,"weapon":["a1","r2","turret"][i]})
	g.ui.refresh();await capture("killfeed")
	for i in [-1,-3,-5]:g.players[i].alive=false
	g.ui.scoreboard.visible=true;g.ui.scoreboard.refresh_scores();await capture("scoreboard")
	g.leave_game();g.queue_free();await process_frame;await process_frame;quit()
