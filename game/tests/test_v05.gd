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
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=0;g.options.max_players=32;g.build_world()
	g.add_player(1,"같은 이름","v05_host_token_01");g.add_player(2,"같은 이름","v05_member_token2");g.add_player(3,"같은 이름","v05_member_token3");g.add_player(4,"넷","v05_member_token4")
	expect(g.players[1].nick!=g.players[2].nick and g.players[2].nick!=g.players[3].nick,"identical nicknames receive unique room numbers")
	var original=g.players[2].nick;g.disconnected(2);g.add_player(5,"같은 이름","v05_member_token2")
	expect(g.players[5].nick==original,"reconnecting player retains public nickname number")
	expect(not g.kick_player(3,5) and g.players.has(5),"member cannot perform host kick")
	expect(not g.kick_player(1,1),"host cannot be removed through moderation commands")
	expect(g.start_kick_vote(3,5) and g.vote.needed==2,"lobby member can start vote with 60 percent quorum")
	expect(not g.cast_kick_vote(3,true) and not g.cast_kick_vote(5,true),"duplicate vote and target vote are rejected")
	expect(g.cast_kick_vote(4,true) and not g.players.has(5) and g.vote.is_empty(),"two eligible votes kick the target and close the vote")
	expect(g.banned_tokens.has("v05_member_token2") and not g.reconnects.has("v05_member_token2"),"kicked identity is temporarily blocked and reconnect state removed")
	g.phase="combat";g.spawn(3);g.spawn(4)
	expect(not g.start_kick_vote(3,4),"vote initiator cooldown prevents immediate repeated votes")
	g.vote_cooldowns.clear();expect(g.start_kick_vote(4,3),"kick vote also starts during combat")
	g.clock=float(g.vote.until)+.1;g.update_kick_vote();expect(g.vote.is_empty() and g.players.has(3),"expired vote without quorum does not kick")
	expect(g.kick_player(1,4) and not g.players.has(4),"host can kick during combat")
	var p=g.players[1];g.clock=100.;g.spawn(1);p.fire_ready=0.;p.switch_until=0.;p.role=0;p.skill_ready=0.;p.gadget_ready=0.;p.armor=0.;var rounds=p.mag[p.primary];var gadgets=p.gadget_count
	g.fire(1);g.use_skill(1);g.use_gadget(1)
	expect(p.mag[p.primary]==rounds and p.skill_ready==0 and p.gadget_count==gadgets,"spawn protection blocks fire, skills, and gadgets")
	g.players[3].team=1-p.team;g.damage(1,40,3);expect(p.hp==100.,"protected player cannot take damage")
	g.clock+=Rules.SPAWN_PROTECTION+.01;g.fire(1)
	expect(p.mag[p.primary]<rounds,"weapon works as soon as protection expires")
	p.hp=40.;p.shot_time=0.;p.last_hit=0.;g.options.autoheal=false;g.passive_regen(p,10.)
	expect(p.hp==40. and not Rules.default_options().autoheal,"automatic healing defaults OFF")
	g.options.autoheal=true;p.last_hit=g.clock-9.;g.passive_regen(p,1.);expect(p.hp==40.,"healing waits ten seconds after being hit")
	p.last_hit=0.;p.shot_time=g.clock-9.;g.passive_regen(p,1.);expect(p.hp==40.,"firing also restarts passive healing delay")
	p.shot_time=0.;g.passive_regen(p,10.);expect(p.hp==50.,"passive heal restores only ten health over ten seconds")
	for mode in [0,1,2,3,4]:
		g.options.mode=mode;p.hp=99.5;g.passive_regen(p,1.);expect(p.hp==100.,"healing respects max HP independently of respawn mode "+str(mode))
	g.options.mode=0;p.team=0;g.players[3].team=1;g.actors[3].position=Vector3(-78,.1,-75);g.players[3].alive=true
	await physics_frame;await physics_frame
	var positions={};var safe=true
	for i in range(20):
		var spawn=g.choose_spawn(1);positions[str(spawn)]=true
		if spawn.z> -68 or spawn.z< -84 or spawn.distance_to(g.actors[3].position)<45 or not g.arena.point_clear(spawn):safe=false
	expect(safe,"TDM spawn remains in region and avoids nearby enemy")
	expect(positions.size()>1,"spawn location varies across respawns")
	g.audio_bank.profile={"weapon_volume":0.,"step_volume":0.,"ui_volume":.2,"hit_volume":.4}
	expect(g.audio_bank.category_gain("combat")==1. and g.audio_bank.category_gain("weapon_volume")==1. and g.audio_bank.category_gain("step_volume")==1.,"legacy settings cannot individually mute combat audio")
	expect(g.audio_bank.category_gain("ui_volume")==.2 and g.audio_bank.category_gain("hit_volume")==.4,"UI and hit volumes remain adjustable")
	expect(VersionCheck.newer("0.10.0","0.9.9") and not VersionCheck.newer("0.5.0","0.5.0"),"update comparison is numeric, not lexicographic")
	expect(not VersionCheck.newer("9.x.0","0.5.0") and not VersionCheck.newer("0.4.9","0.5.0"),"malformed and older versions do not produce false updates")
	var version=VersionCheck.new();root.add_child(version);version.completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"version":str(int(Rules.VERSION.split(".")[0])+1)+".0.0"}).to_utf8_buffer());expect(version.state=="newer","new manifest triggers update warning")
	version.completed(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray());expect(version.state=="offline" and g.phase=="combat","offline update check does not stop the game");version.queue_free()
	g.leave_game();g.queue_free();await process_frame;await process_frame
	for index in range(Rules.MAPS.size()):
		var arena=Arena.new();root.add_child(arena);arena.build(index);var nav=BotNavigation.new();nav.build(arena);var connected=true;var clear=true
		for team in [0,1]:
			for pos in arena.spawn_candidates(team,false):
				if not arena.point_clear(pos):clear=false
			for target in arena.sites+arena.zones:
				var route=nav.route(arena.spawn_candidates(team,false)[0],target)
				if route.is_empty() or route[-1].distance_to(target)>4.5:connected=false
		expect(clear,"map "+str(index)+" spawns avoid solid objects")
		expect(connected,"map "+str(index)+" both teams can reach every objective")
		var fields=[{"kind":"smoke","pos":Vector3.ZERO,"until":100.,"team":0}];var fx=CombatFX.new();root.add_child(fx);fx.sync_fields(fields,0);var first=fx.field_nodes.values()[0];fx.sync_fields(fields,1);expect(fx.field_nodes.values()[0]==first,"map "+str(index)+" smoke does not recreate meshes every frame");fx.queue_free();arena.queue_free();await process_frame;await process_frame
	print("V05_RESULT ",checks-failures,"/",checks);await create_timer(.15).timeout;quit(1 if failures else 0)
