extends SceneTree
var failures=0
var checks=0
func expect(ok:bool,desc:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",desc)
	else:print("PASS ",desc)
func _initialize():call_deferred("run")
func run():
	expect(Rules.medic_cap(4)==1 and Rules.medic_cap(6)==1 and Rules.medic_cap(7)==2 and Rules.medic_cap(16)==5,"medic team caps")
	expect(Rules.loss_reward(1)==1900 and Rules.loss_reward(2)==3000 and Rules.loss_reward(8)==3300,"loss economy")
	expect(Rules.damage_water(true,true,true)==.5 and Rules.damage_water(false,false,false)==1,"water attenuation applied once")
	expect(Rules.ammo_pickup(120)==30,"partial ammo refill")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.dedicated=true;g.host_game();g.set_physics_process(false)
	g.add_player(1,"Test One","test_one_123456789");g.add_player(2,"Test Two","test_two_123456789")
	g.phase="combat";g.clock=100;g.players[1].protect=0.;g.players[2].protect=0.
	g.actors[1].position=Vector3(0,0,60);g.actors[2].position=Vector3(0,0,55)
	await physics_frame;await physics_frame
	g.players[2].armor=50;g.damage(2,40,1)
	expect(g.players[2].armor==10 and g.players[2].hp==100,"armor absorbs damage first")
	g.damage(2,30,1);expect(g.players[2].hp==80 and g.players[2].armor==0,"excess damage reaches health")
	g.damage(2,200,1);expect(not g.players[2].alive and g.players[1].kills==1 and g.drops.size()==1,"elimination score and weapon drop")
	g.spawn(2);expect(g.players[2].alive and g.actors[2].collision_layer==2,"respawn restores collision")
	g.players[1].role=3;g.players[1].skill_ready=0;g.actors[1].position=Vector3(25,0,65);g.actors[1].aim_yaw=0.;g.actors[1].aim_pitch=0
	await physics_frame;await physics_frame
	g.use_skill(1);expect(g.devices.size()==1,"engineer turret placement")
	if g.devices.size()>0:
		var did=g.devices.keys()[0];expect(g.players[1].skill_ready==130,"30-second turret charge")
		g.update_world_visuals(.1);await physics_frame;await physics_frame
		g.clock=131;g.actors[1].aim_pitch=.05
		g.use_skill(1);expect(g.devices.size()==1 and g.devices[did].level==2,"aimed turret upgrade preserves singleton")
		g.remove_device(did);expect(g.players[1].skill_ready==161,"destruction does not refund charge")
	g.players[1].alive=false;g.phase="buy";g.options.mode=4;g.players[1].cash=800;g.players[1].armor=0;g.players[1].primary="pistol";g.players[1].owned_primary=false
	g.apply_loadout(1,{"role":0,"primary":"a1","armor":2});expect(g.players[1].cash==800 and g.players[1].primary=="pistol","insufficient funds rejected")
	g.players[1].cash=4000;g.apply_loadout(1,{"role":0,"primary":"a1","armor":2});expect(g.players[1].cash==1000 and g.players[1].primary=="a1","purchase costs deducted")
	g.players[1].alive=false;g.apply_loadout(1,{"role":0,"primary":"r2"});expect(g.players[1].primary=="a1","class weapon restriction")
	g.phase="combat";g.remaining=500;g.players[1].alive=true;g.players[1].protect=0;g.players[1].slot=0;g.players[1].mag.a1=0;g.players[1].reserve.a1=20;g.clock=200
	g.handle_command(1,"reload",{});g.clock=203;g.server_tick(.01);expect(g.players[1].mag.a1==20 and g.players[1].reserve.a1==0,"finite reload transfers existing reserve")
	g.options.infinite=true;g.players[1].mag.a1=0;g.players[1].reserve.a1=0;g.clock=204;g.handle_command(1,"reload",{});g.clock=207;g.server_tick(.01);expect(g.players[1].mag.a1==30,"infinite reserve still reloads magazine")
	g.players[1].fire_ready=0;g.players[1].reload=0;g.actors[1].sprint_release=208;g.fire(1);expect(g.players[1].mag.a1==30,"sprint-to-fire delay enforced")
	g.players[1].role=5;g.players[1].primary="m2";g.players[1].slot=0;g.players[1].fire_ready=0;g.players[1].heal_ready=0;g.players[1].heal_mag=3;g.actors[1].sprint_release=0;g.actors[1].last_sprint=false
	g.players[2].team=g.players[1].team;g.players[2].hp=40;g.players[2].last_hit=0;g.actors[1].position=Vector3(25,0,60);g.actors[2].position=Vector3(25,0,55);g.actors[1].aim_yaw=0;g.actors[1].aim_pitch=0;g.actors[2].collision_layer=2
	await physics_frame;await physics_frame
	g.heal_burst(1);expect(g.players[2].hp==60 and g.players[1].heal_ready==209,"medical shot heals 20 and enforces 2-second gap")
	g.heal_burst(1);expect(g.players[2].hp==60,"medical shot cannot bypass cooldown")
	g.options.mode=4;g.phase="combat";g.scores=[0,0];g.losses=[0,0];g.players[1].team=0;g.players[2].team=1;g.players[1].cash=0;g.players[2].cash=0
	g.finish_round(0,"test");expect(g.players[1].cash==3500 and g.players[2].cash==1900,"round payouts")
	g.phase="combat";g.finish_round(0,"test");expect(g.players[2].cash==4900,"second loss recovery")
	var teams=Rules.balanced_ids(g.players);expect(abs(teams[0].size()-teams[1].size())<=1,"team rebalance player counts")

	g.options.mode=2;g.options.shared_lives=true;g.phase="combat";g.tickets=[1,1];g.players[2].protect=0;g.players[2].hp=100;g.players[2].armor=0;g.players[2].alive=true
	g.damage(2,150,1);expect(g.tickets[1]==0 and g.players[2].can_respawn,"shared respawn ticket reserved once")
	g.spawn(2);g.players[2].protect=0;g.damage(2,150,1);expect(not g.players[2].can_respawn and g.tickets[1]==0,"exhausted shared tickets prevent respawn")
	g.options.mode=4;g.phase="combat";g.round_no=1;g.players[1].team=0;g.players[1].alive=true;g.actors[1].position=g.arena.sites[0];g.actors[1].input_state.use=true
	g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO}
	for i in range(31):g.clock+=.1;g.interact(1,.1)
	expect(g.bomb.planted and g.bomb.site==0,"three-second objective placement")
	g.players[2].alive=true;g.actors[2].position=g.arena.sites[0];g.actors[2].input_state.use=true;g.scores=[0,0];g.phase="combat"
	for i in range(51):g.clock+=.1;g.interact(2,.1)
	expect(g.phase=="round_end" and g.scores[1]==1,"five-second objective disarm awards defenders")
	g.options.mode=3;g.phase="combat";g.remaining=300;g.players[1].alive=true;g.players[2].alive=false;g.zone_capture=[0.,0.,0.];g.zone_owner=[-1,-1,-1];g.actors[1].position=g.arena.zones[0]
	for i in range(51):g.check_objectives(.1)
	expect(g.zone_owner[0]==0,"uncontested zone capture")
	print("RESULT ",checks-failures,"/",checks," passed")
	g.leave_game();g.queue_free();await process_frame;quit(1 if failures else 0)
