extends SceneTree
var g:Node
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,what:String):
	checks+=1
	if ok:print("PASS ",what)
	else:failures+=1;printerr("FAIL ",what)
func state(seq:int) -> Dictionary:
	return {"sequence":seq,"clock":float(seq),"phase":"lobby","remaining":600.,"scores":[0,0],"tickets":[10,10],"round":0,"players":[],"devices":{},"fields":[],"drops":[],"zones":[-1,-1,-1],"supplies":[],"bomb":{"planted":false},"padding":Crypto.new().generate_random_bytes(900)}
func chunks(s:Dictionary) -> Array:
	var bytes=var_to_bytes(s).compress(FileAccess.COMPRESSION_DEFLATE);var out=[]
	for i in range(int(ceil(bytes.size()/500.))):out.append(bytes.slice(i*500,mini(bytes.size(),(i+1)*500)))
	return out
func send_frame(seq:int,parts:Array):
	for i in range(parts.size()-1,-1,-1):g.snapshot_chunk(seq,i,parts.size(),parts[i])
func burst(interval:float,shots:int) -> Dictionary:
	var p=g.players[1];var a=g.actors[1]
	p.primary="a1";p.slot=0;p.reload=0.;p.fire_ready=0.;p.bloom=0.;p.spray_phase=0.;p.spray_index=0;p.shot_time=-100.;p.switch_until=0.;p.shield=0.;g.equip_ammo(p)
	a.sprint_release=0.;a.last_sprint=false;a.input_state.sprint=false
	for shot in range(shots):
		g.fire(1)
		for i in range(int(round(interval/.01))):g.clock+=.01;AimModel.recover(p,Catalog.get_weapon("a1"),.01,g.clock)
	return {"bloom":p.bloom,"phase":p.spray_phase,"used":30-p.mag.a1}
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g);g.host_game();g.set_physics_process(false);g.clock=100.
	g.add_player(-1,"Member","member_token_0001");g.add_player(-2,"Other","member_token_0002")
	var member=g.players[-1];var other=g.players[-2];var before=other.team
	expect(g.change_team(-1,-1,1-member.team),"lobby member chooses own team")
	expect(not g.change_team(-1,-2,1-before) and other.team==before,"member cannot move another player")
	g.handle_command(-1,"team",{"player_id":1,"team":1-g.players[1].team})
	expect(g.change_team(1,-2,1-other.team),"host arranges lobby players")
	g.phase="combat";before=member.team
	expect(not g.change_team(-1,-1,1-before) and member.team==before,"combat member team change denied")
	var deaths=member.deaths;var lives=member.lives
	expect(g.change_team(1,-1,1-before) and not member.alive and member.respawn>g.clock and member.deaths==deaths and member.lives==lives,"host combat transfer schedules respawn without death penalty")
	g.options.mode=4
	expect(g.change_team(1,-1,before) and member.spectator,"bomb team transfer waits until next round")
	g.options.mode=1;before=member.team
	expect(not g.change_team(1,-1,1-before),"free for all has no team switching")
	g.options.mode=0;member.team=0;other.team=1
	expect(not g.swap_teams(-1,-1,-2) and member.team==0,"member cannot invoke host team swap")
	expect(g.swap_teams(1,-1,-2) and member.team==1 and other.team==0,"host atomically swaps opposing participants")
	g.options.mode=0;g.spawn(1);var p=g.players[1];var a=g.actors[1];p.protect=0.;a.position=Vector3(25,0,60);a.reset_view(0)
	expect(p.armor==0,"ordinary spawn still has no automatic armor")
	await physics_frame;await physics_frame
	var sustained=burst(.12,10);var tapping=burst(.32,10)
	expect(sustained.used==10 and tapping.used==10,"spread comparison fires ten real shots each")
	expect(tapping.bloom<sustained.bloom*.5 and tapping.phase<sustained.phase*.5,"pausing between shots reduces accumulated spread and recoil")
	burst(.12,12);var wide=p.bloom;var high_phase=p.spray_phase
	for i in range(35):g.clock+=.01;AimModel.recover(p,Catalog.get_weapon("a1"),.01,g.clock)
	expect(p.bloom<wide and p.bloom>0 and p.spray_phase<high_phase and p.spray_phase>0,"long burst recovers gradually after release")
	for i in range(400):g.clock+=.01;AimModel.recover(p,Catalog.get_weapon("a1"),.01,g.clock)
	expect(is_zero_approx(p.bloom) and is_zero_approx(p.spray_phase),"resting completely restores first shot accuracy")
	a.input_state.z=-1
	for i in range(90):a.simulate(.016,g.clock,true)
	var moving=a.spread_angle
	a.input_state.z=0
	for i in range(120):a.simulate(.016,g.clock,true)
	expect(a.spread_angle<moving*.6,"stopping movement closes the crosshair")
	p.primary="r2";p.secondary="heavy_pistol";p.slot=1;p.hp=1.;p.protect=0.;g.equip_ammo(p);g.damage(1,2,0)
	expect(g.drops.back().weapon=="heavy_pistol","elimination drops the equipped secondary model")
	expect(g.drops.back().until-g.clock>=39,"dropped weapon outlasts the fallen character")
	g.update_world_visuals(.1)
	var drop=g.drop_nodes.values().back()
	expect(drop is WeaponVisual and drop.find_children("*","MeshInstance3D",true,false).size()>4,"pickup renders the actual multi-part weapon")
	var board=MatchScoreboard.new();board.game=g;g.ui.root.add_child(board);board.refresh_scores()
	expect(board.columns.get_child(0).get_child(0).text.begins_with("◆ BLUE") and board.columns.get_child(1).get_child(0).text.begins_with("● ORANGE"),"scoreboard groups teams into separate labeled panels")
	g.options.mode=1;board.timer=0;board.refresh_scores()
	expect(board.columns.get_child(0).get_child(0).text.contains("개인전"),"FFA scoreboard uses individual rankings")
	board.queue_free()
	g.server=false;g.options.password="kept_local_password";g.configure({"mode":0,"room":"Public room"})
	expect(g.options.password=="kept_local_password" and g.options.has("max_players"),"public configuration preserves local password and fills defaults")
	g.received_sequence=999;g.snapshot_buffers[1]={};g.incoming_at[1]={};g.reset_transport_state()
	expect(g.received_sequence==-1 and g.snapshot_buffers.is_empty() and g.incoming_at.is_empty(),"new connection clears old sequence and rate limit state")
	var frame=chunks(state(10));g.snapshot_chunk(10,0,frame.size(),frame[0]);g.snapshot_chunk(10,0,frame.size(),frame[0])
	expect(g.received_sequence==-1,"duplicate incomplete pieces do not apply a frame")
	send_frame(10,frame);expect(g.received_sequence==10 and g.clock==10.,"out of order pieces assemble a complete snapshot")
	frame=chunks(state(11));g.snapshot_chunk(11,0,frame.size(),frame[0]);send_frame(12,chunks(state(12)))
	expect(g.received_sequence==12,"a missing frame does not block later complete snapshots")
	send_frame(11,frame);expect(g.received_sequence==12,"late older snapshot cannot rewind state")
	for seq in range(20,35):g.snapshot_chunk(seq,0,3,PackedByteArray([1,2,3]))
	expect(g.snapshot_buffers.size()<=4,"incomplete snapshot storage remains bounded")
	g.ui.join_menu();expect(g.room_search_active and g.browser!=null,"LAN browser searches immediately on entry")
	g.ui.menu();expect(not g.room_search_active and g.browser==null,"leaving LAN browser closes discovery socket")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio_manifest.json"));var hashes={};var gun_count=0
	for key in manifest:
		if not key.begins_with("gun_"):continue
		gun_count+=1;hashes[FileAccess.get_sha256(manifest[key].file)]=true
	expect(gun_count==25 and hashes.size()==25,"all 25 attack weapons have distinct sound files")
	expect(manifest.has("step_water_3") and manifest.has("step_stone_3") and manifest.has("step_metal_3"),"three walking surfaces include four variants each")
	print("V04_RESULT ",checks-failures,"/",checks)
	g.leave_game();await create_timer(.15).timeout;g.queue_free();await process_frame;await process_frame;quit(1 if failures else 0)
