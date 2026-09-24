extends SceneTree
var g:Node
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if ok:print("PASS ",message)
	else:failures+=1;printerr("FAIL ",message)
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.build_world()
	g.add_player(1,"같은닉네임","killfeed_host_1234");g.add_player(2,"같은닉네임","killfeed_target_1234");g.players[1].team=0;g.players[2].team=1;g.phase="combat";g.clock=100;g.ui.show_hud()
	g.players[2].protect=0;g.damage(2,25,1,false,"a1")
	expect(g.kill_events.is_empty(),"nonlethal hits never create feed entries")
	g.damage(2,1000,1,false,"a1");var first=g.kill_events.back().duplicate()
	expect(first.weapon=="a1" and first.attacker_name==g.players[1].nick and first.victim_name==g.players[2].nick,"primary kill preserves weapon and both room identities")
	expect(first.attacker_team==0 and first.victim_team==1 and KillFeed.team_color(0)!=KillFeed.team_color(1),"attacker and victim preserve separate team colors")
	g.damage(2,1000,1,false,"a1");expect(g.kill_events.size()==1,"repeated damage to a dead player does not duplicate feed")
	g.players[1].primary="h1";g.players[1].team=1;expect(g.kill_events[0].weapon=="a1" and g.kill_events[0].attacker_team==0,"later loadout or team changes do not rewrite existing feed")
	g.players[1].team=0;g.spawn(2);g.players[2].protect=0;g.damage(2,1000,1,false,"heavy_pistol")
	expect(g.kill_events.back().weapon=="heavy_pistol","secondary weapon is identified independently of primary")
	g.spawn(2);g.players[2].protect=0;g.damage(2,1000,1,false,"turret")
	expect(g.kill_events.back().weapon=="turret" and g.kill_events.back().attacker==1,"turret kill identifies its owner and turret")
	g.spawn(2);g.players[2].protect=0;g.damage(2,1000,0)
	expect(g.kill_events.back().weapon=="world" and g.kill_events.back().attacker_name=="환경","world damage has a neutral source instead of a misleading gun")
	g.players[2].nick="변경한 이름";expect(g.kill_events[0].victim_name==first.victim_name,"renaming cannot change names captured at the time of a kill")
	for i in range(12):g.kill_event(first)
	expect(g.kill_events.size()==KillFeed.MAX_ROWS,"busy combat keeps feed storage bounded")
	g.ui.kill_feed.refresh(g.kill_events,1,Time.get_ticks_msec());expect(g.ui.kill_feed.get_child_count()==6,"HUD renders recent kills as six independent rows")
	g.ui.kill_feed.refresh(g.kill_events,1,Time.get_ticks_msec()+KillFeed.LIFETIME_MS+1);expect(g.ui.kill_feed.get_child_count()==0,"feed expires without requiring another kill")
	expect(KillFeed.compact_name("아주아주긴중복닉네임입니다 #08").ends_with(" #08"),"long nicknames keep the identifying room number visible")
	g.players[1].alive=false;g.ui.refresh();expect(g.ui.health.text.begins_with("Dead"),"local death status uses Dead")
	g.leave_game();expect(g.kill_events.is_empty(),"leaving a room clears its kill feed")
	g.queue_free();await process_frame;await process_frame;print("KILL_FEED_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
