extends Node3D
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/catalog.gd")
const A=preload("res://scripts/actor.gd")
const W=preload("res://scripts/arena.gd")
const UI=preload("res://scripts/ui.gd")
var demo_mode=false
var kill_replay:KillReplay
var bot_navigation:BotNavigation
var bot_agents={}
var bot_attack_site=0
var combat_fx:CombatFX
var heal_sound_times={}
var version_check:VersionCheck
var vote={}
var vote_cooldowns={}
var banned_tokens={}
var public_serial=0
var kill_events=[]
var kill_serial=0
var options=R.default_options()
var players={}
var actors={}
var devices={}
var device_nodes={}
var fields=[]
var drops=[]
var reconnects={}
var arena:Arena
var ui:CanvasLayer
var clock=0.0
var phase="menu"
var remaining=0.0
var scores=[0,0]
var losses=[0,0]
var tickets=[0,0]
var spectator_target=0
var spectator_camera:Camera3D
var spectator_yaw=0.0
var spectator_pitch=-.12
var trigger_seq=0
var preview:Node3D
var round_no=0
var next_device=1
var zone_owner=[-1,-1,-1]
var zone_capture=[0.0,0.0,0.0]
var bomb={"planted":false,"site":-1,"time":0.0,"actor":0,"progress":0.0,"position":Vector3.ZERO}
var server=false
var dedicated=false
var local_id=1
var profile={"nick":"Player","token":"","sensitivity":.0023,"ads_sensitivity":.75,"volume":.65,"window":true,"resolution":0,"monitor":0,"display_mode":-1,"width":0,"height":0,"ui_volume":.75,"hit_volume":.85}
var pending_loadout={"role":0,"primary":"a1","secondary":"pistol","armor":0,"team":-1,"gadget":0}
var snapshot_timer=0.0
var input_timer=0.0
var discovery:PacketPeerUDP
var browser:PacketPeerUDP
var discover_timer=0.0
var rooms={}
var sounds={}
var audio_bank:GameAudio
var ping_ms=0
var ping_timer=0.0
var test_mode=false
var last_hurt_sound=-100.
var smoke_visuals=[]
var world_timer=0.0
var step_events=0.0
var wall_marks=[]
var drop_nodes={}
var incoming_at={}
var cli_args=[]
var snapshot_sequence=0
var received_sequence=-1
var received_parts={}
var expected_parts=0
var snapshot_buffers={}
var session_started=0
var last_snapshot_ms=0
var last_server_ip=""
var connection_busy=false
var connection_deadline=0
var peer_activity={}
var pending_peers={}
var full_sync_timer=0.
var room_search_active=false
var room_search_timer=0.
var connection_notice=false
func _ready():
	if demo_mode:
		start_demo();return
	C.load_all();load_profile();setup_input();apply_display_settings()
	combat_fx=CombatFX.new();add_child(combat_fx)
	audio_bank=GameAudio.new();add_child(audio_bank);audio_bank.profile=profile
	version_check=VersionCheck.new();add_child(version_check)
	ui=UI.new();ui.game=self;add_child(ui);ui.menu();save_profile()
	if DisplayServer.get_name()!="headless":kill_replay=KillReplay.new();kill_replay.game=self;add_child(kill_replay)
	version_check.changed.connect(func():ui.update_version_badge())
	if DisplayServer.get_name()!="headless" and not "--no-update-check" in OS.get_cmdline_user_args():version_check.call_deferred("check")
	multiplayer.peer_disconnected.connect(disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(func():leave_game("서버에 연결하지 못했습니다. IP·방화벽을 확인하고 다시 접속하세요."))
	multiplayer.peer_connected.connect(peer_opened)
	multiplayer.server_disconnected.connect(func():leave_game("서버 연결이 종료되었습니다."))
	cli_args=OS.get_cmdline_user_args()
	for s in cli_args:
		if s.begins_with("--nick="):profile.nick=s.trim_prefix("--nick=");profile.token=profile.nick.sha256_text()
	if "--server" in cli_args:
		dedicated=true;options.bots=4 if "--training" in cli_args else 0;host_game()
		if "--auto-start" in cli_args:start_match()
	elif "--training" in cli_args:
		options.bots=7;host_game();start_match()
	elif "--host-test" in cli_args:
		test_mode=true;options.bots=0;host_game();start_match()
	for s in cli_args:
		if s.begins_with("--connect="):test_mode=true;join_game(s.trim_prefix("--connect="))
	for arg in cli_args:
		if arg.begins_with("--capture="):
			await get_tree().create_timer(4).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	if "--screenshot" in cli_args:
		await get_tree().create_timer(4).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir().path_join("game-capture.png"))
	if "--quit-test" in cli_args:
		await get_tree().create_timer(12).timeout;print("TEST_EXIT players=",players.size()," phase=",phase);get_tree().quit()
func exit_game():
	set_physics_process(false);audio_bank.stop_all();combat_fx.clear()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
func load_profile():
	if DisplayServer.get_name()=="headless" or "--no-save-profile" in OS.get_cmdline_user_args():return
	var cfg=ConfigFile.new()
	var loaded=cfg.load("user://settings.cfg")
	# Preserve the previous title's local preferences and player identity.
	if loaded!=OK:
		var previous=OS.get_user_data_dir().get_base_dir().path_join("RelayStrike LAN/settings.cfg")
		if FileAccess.file_exists(previous):loaded=cfg.load(previous)
	if loaded==OK:
		for k in profile:profile[k]=cfg.get_value("player",k,profile[k])
	if str(profile.token).is_empty():profile.token=Crypto.new().generate_random_bytes(16).hex_encode()
func save_profile():
	if DisplayServer.get_name()=="headless" or demo_mode or "--no-save-profile" in OS.get_cmdline_user_args():return
	var cfg=ConfigFile.new()
	for k in profile:cfg.set_value("player",k,profile[k])
	cfg.save("user://settings.cfg")
	AudioServer.set_bus_mute(0,float(profile.volume)<=0)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,float(profile.volume))))
func apply_display_settings():
	if DisplayServer.get_name()=="headless" or demo_mode:return
	var monitor=clampi(int(profile.monitor),0,maxi(0,DisplayServer.get_screen_count()-1))
	profile.monitor=monitor
	if int(profile.display_mode)<0:profile.display_mode=0 if profile.window else 1
	var mode=clampi(int(profile.display_mode),0,2)
	profile.window=mode==0
	var size=display_window_size()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_current_screen(monitor)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	if mode==0:
		var usable=DisplayServer.screen_get_usable_rect(monitor)
		size=Vector2i(mini(size.x,usable.size.x),mini(size.y,maxi(360,usable.size.y-40)))
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(usable.position+(usable.size-size)/2)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if mode==1 else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
func display_window_size() -> Vector2i:
	var legacy=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)][clampi(int(profile.resolution),0,2)]
	return Vector2i(maxi(640,int(profile.width)),maxi(360,int(profile.height))) if int(profile.width)>0 and int(profile.height)>0 else legacy
func start_demo():
	C.load_all();server=true;local_id=0
	combat_fx=CombatFX.new();add_child(combat_fx)
	audio_bank=GameAudio.new();add_child(audio_bank);audio_bank.profile=profile
	ui=UI.new();ui.game=self;add_child(ui);ui.hide()
	options.map=7;options.bots=6;options.mode=0;options.minutes=60;options.target=9999
	phase="lobby";build_world()
	for i in range(1,7):add_player(-i,"DEMO %d"%i,"menu_demo_%d"%i)
	phase="combat";remaining=3600.
	for id in players:players[id].protect=0.;players[id].fire_ready=0.
	set_process_unhandled_input(false)
func setup_input():
	var binds={"left":KEY_A,"right":KEY_D,"forward":KEY_W,"back":KEY_S,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"jump":KEY_SPACE,"reload":KEY_R,"use":KEY_E,"skill":KEY_F,"gadget":KEY_G,"gear":KEY_B,"score":KEY_TAB,"primary":KEY_1,"secondary":KEY_2,"medical":KEY_Q,"gadget_mode":KEY_V,"item3":KEY_3,"item4":KEY_4}
	for k in binds:
		if not InputMap.has_action(k):InputMap.add_action(k)
		var ev=InputEventKey.new();ev.physical_keycode=binds[k];InputMap.action_add_event(k,ev)
func build_world():
	if arena:arena.queue_free()
	arena=W.new();arena.props_authoritative=server or demo_mode;add_child(arena);arena.build(int(options.map))
	bot_navigation=BotNavigation.new();bot_navigation.build(arena);bot_agents.clear()
	if not is_instance_valid(spectator_camera):
		spectator_camera=Camera3D.new();spectator_camera.near=.1;spectator_camera.far=350;add_child(spectator_camera)
func host_game():
	if phase!="menu" or connection_busy:return
	reset_transport_state();stop_room_search()
	var peer=ENetMultiplayerPeer.new();var err=peer.create_server(R.PORT,32,3)
	if err!=OK:ui.notice("방을 만들 수 없습니다. 다른 서버가 실행 중인지 확인하세요. 코드 "+str(err));return
	multiplayer.multiplayer_peer=peer;multiplayer.server_relay=false;server=true;local_id=1;phase="lobby";public_serial=0;banned_tokens.clear();vote.clear();vote_cooldowns.clear();build_world()
	discovery=PacketPeerUDP.new();discovery.set_broadcast_enabled(true)
	if discovery.bind(R.DISCOVERY)!=OK:discovery=null
	if not dedicated:add_player(1,profile.nick,profile.token)
	for i in range(mini(int(options.bots),int(options.max_players)-(0 if dedicated else 1))):add_player(-i-1,"BOT %02d"%(i+1),"bot"+str(i))
	ui.lobby();broadcast_state(true);print("SERVER_READY port=",R.PORT)
func reset_transport_state():
	received_sequence=-1;snapshot_sequence=0;snapshot_buffers.clear();received_parts.clear();expected_parts=0;incoming_at.clear();peer_activity.clear();pending_peers.clear();snapshot_timer=0.;input_timer=0.;ping_timer=0.;ping_ms=0;full_sync_timer=0.;connection_busy=false;connection_notice=false;last_snapshot_ms=Time.get_ticks_msec();session_started=last_snapshot_ms
func peer_opened(id:int):
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		var peer=multiplayer.multiplayer_peer.get_peer(id)
		peer.set_timeout(32,10000,45000);peer.ping_interval(1000)
	if server:pending_peers[id]=Time.get_ticks_msec()
func join_game(ip:String):
	if phase!="menu" or connection_busy:return
	last_server_ip=ip.strip_edges()
	if last_server_ip.is_empty():ui.notice("서버 IP를 입력하세요.");return
	if multiplayer.multiplayer_peer:multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();reset_transport_state();stop_room_search()
	var peer=ENetMultiplayerPeer.new();var err=peer.create_client(last_server_ip,R.PORT,3)
	if err!=OK:ui.notice("연결을 시작할 수 없습니다. IP를 확인하세요.");return
	multiplayer.multiplayer_peer=peer;server=false;connection_busy=true;connection_deadline=Time.get_ticks_msec()+15000;ui.notice("서버에 연결 중… 취소하거나 다시 시도할 수 있습니다.")
func connected():
	local_id=multiplayer.get_unique_id();peer_opened(1)
	register.rpc_id(1,profile.nick,profile.token,options.password,R.VERSION)
func request_leave():
	if not server and phase!="menu" and multiplayer.multiplayer_peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:
		depart.rpc_id(1);await get_tree().create_timer(.12).timeout
	leave_game()
@rpc("any_peer","call_remote","reliable",0)
func depart():
	if server:disconnected(multiplayer.get_remote_sender_id())
func connection_watchdog():
	var now=Time.get_ticks_msec()
	if connection_busy and now>connection_deadline:leave_game("연결 시간이 초과되었습니다. 재접속 버튼으로 다시 시도하세요.");return
	if server:
		for id in pending_peers.keys():
			if now-int(pending_peers[id])>20000:multiplayer.multiplayer_peer.disconnect_peer(id);pending_peers.erase(id)
		for id in peer_activity.keys():
			if now-int(peer_activity[id])>45000:multiplayer.multiplayer_peer.disconnect_peer(id);disconnected(id)
	elif phase!="menu" and not connection_busy:
		var age=now-last_snapshot_ms
		if age>20000:leave_game("서버 응답이 끊겼습니다. 게임을 종료하지 않고 재접속할 수 있습니다.")
		elif age>4000 and not connection_notice:connection_notice=true;ui.notice("서버 응답 대기 중… 연결을 확인하고 있습니다.")
@rpc("any_peer","call_remote","reliable",0)
func register(nick:String,token:String,password:String,version:String):
	if not server:return
	var id=multiplayer.get_remote_sender_id()
	if players.has(id):return
	var reason=""
	if Time.get_ticks_msec()<int(banned_tokens.get(token,0)):
		reject.rpc_id(id,"강퇴된 방입니다. 잠시 후 다시 참가하세요.");return
	if version!=R.VERSION:reason="버전이 다릅니다. 서버 "+R.VERSION+" / 내 게임 "+version+". 같은 버전을 내려받으세요."
	elif password!=options.password:reason="방 비밀번호가 다릅니다."
	elif phase!="lobby" and int(options.join)==0:reason="진행 중 참가가 금지된 방입니다."
	elif token.length()<16 or token.length()>80:reason="플레이어 식별 정보가 올바르지 않습니다."
	if not reason.is_empty():reject.rpc_id(id,reason);return
	for old_id in players.keys():
		if players[old_id].token!=token:continue
		if old_id==1 or Time.get_ticks_msec()-int(peer_activity.get(old_id,0))<5000:
			reject.rpc_id(id,"같은 플레이어의 이전 연결이 아직 남아 있습니다. 5초 뒤 다시 접속하세요.");return
		multiplayer.multiplayer_peer.disconnect_peer(old_id);disconnected(old_id)
	if players.size()>=int(options.max_players):reject.rpc_id(id,"방이 가득 찼습니다.");return
	add_player(id,nick.left(20),token);peer_activity[id]=Time.get_ticks_msec();pending_peers.erase(id)
	configure.rpc_id(id,public_options());broadcast_state(true,id)
	print("JOIN ",id," count=",players.size())
@rpc("authority","call_remote","reliable",0)
func reject(message:String):
	leave_game(message)
func public_options() -> Dictionary:
	var d=options.duplicate();d.erase("password");return d
@rpc("authority","call_remote","reliable",0)
func configure(opts:Dictionary):
	var saved_password=str(options.get("password",""));options=R.default_options();options.merge(opts,true);options.password=saved_password;connection_busy=false;received_sequence=-1;snapshot_buffers.clear();last_snapshot_ms=Time.get_ticks_msec();build_world();phase="lobby";ui.lobby()
func add_player(id:int,nick:String,token:String):
	var t=0;var counts=[0,0]
	for p in players.values():counts[p.team]+=1
	t=randi()%2 if counts[0]==counts[1] else 0 if counts[0]<counts[1] else 1
	var role=0 if id>0 or not options.classes else absi(id)%6
	if role==5 and medic_count(t)>=R.medic_cap(counts[t]+1):role=0
	var p={"id":id,"nick":nick,"token":token,"team":t,"role":role,"primary":C.first(role),"secondary":R.SECONDARIES[role],"slot":0,"hp":100.,"armor":0.,"armor_max":0,"alive":false,"kills":0,"deaths":0,"assists":0,"objective":0,"healed":0.,"played":0.,"cash":800,"lives":int(options.lives),"respawn":0.,"mag":{},"reserve":{},"reload":0.,"reload_weapon":"","fire_ready":0.,"heal_ready":0.,"heal_mag":3,"heal_reserve":3,"energy":180.,"repair_energy":100.,"skill_ready":0.,"gadget_count":1,"gadget":0,"protect":0.,"shield":0.,"slow":0.,"dash":0.,"mark":0.,"flash":0.,"last_hit":-20.,"contributors":{},"input_time":clock,"gadget_ready":0.,"last_pos":Vector3.ZERO,"spectator":false,"round_bonus":0,"can_respawn":true,"smoke":2,"flash_count":1}
	if reconnects.has(token):
		p=reconnects[token].duplicate(true);p.id=id;p.nick=nick;p.alive=false;p.respawn=clock+3;reconnects.erase(token)
	elif phase!="lobby":
		p.spectator=int(options.join)==1
		p.alive=false;p.respawn=clock+3 if int(options.join)==2 and int(options.mode)!=4 else 1e12
	p.bloom=0.;p.shot_time=-100.;p.spray_index=0;p.spray_phase=0.;p.bot_action=""
	p.pending_loadout={};p.trigger_seen=0;p.fire_prev=false;p.burst_left=0;p.trigger_until=0.;p.reload_started=0.;p.switch_until=0.
	if id<0 and p.role==3:p.secondary="repair"
	if not p.has("number"):public_serial+=1;p.number=public_serial
	p.base_nick=nick.strip_edges().replace("\n"," ").replace("\r"," ").left(20)
	if p.base_nick.is_empty():p.base_nick="Player"
	p.nick=p.base_nick+" #%02d"%int(p.number) if id>0 else p.base_nick
	players[id]=p;ensure_actor(id);equip_ammo(p)
	if phase=="lobby":spawn(id)
	if id<0:
		var brain=BotAgent.new();brain.setup(self,id);bot_agents[id]=brain
func ensure_actor(id:int):
	if actors.has(id):return
	var a=A.new();a.pid=id;a.game=self;a.name="Player_"+str(id);add_child(a);actors[id]=a;a.set_local(id==local_id and not dedicated);a.set_team(int(players[id].team));a.target_pos=Vector3.ZERO
func equip_ammo(p:Dictionary):
	for id in [p.primary,p.secondary]:
		var w=C.get_weapon(id);p.mag[id]=int(w.mag);p.reserve[id]=int(w.reserve)
func spawn(id:int):
	var p=players[id];var a=actors[id]
	if not p.get("pending_loadout",{}).is_empty():
		var requested=p.pending_loadout.duplicate();p.pending_loadout={};commit_loadout(id,requested)
	var best=choose_spawn(id)
	a.collision_layer=2;a.position=best;a.target_pos=best;a.velocity=Vector3.ZERO;p.alive=true;p.hp=100.;p.armor=p.armor_max;p.reload=0.;p.protect=clock+R.SPAWN_PROTECTION;p.energy=180.;p.heal_mag=3;p.heal_reserve=3;p.repair_energy=100.;p.gadget_count=2 if p.role==3 else 3 if p.role==4 else 1;p.smoke=1 if p.role==4 and p.gadget==1 else 2;p.flash_count=2 if p.role==4 and p.gadget==1 else 1;p.last_hit=clock;p.contributors={};p.spectator=false
	a.reset_view(0. if p.team==1 else PI);p.fire_ready=clock+.3;p.burst_left=0;p.fire_prev=false;p.trigger_until=0.;p.trigger_seen=int(a.input_state.get("trigger_seq",0));p.slot=0;p.step_distance=0.;p.step_index=0;p.gait=0.;p.bloom=0.;p.spray_index=0;p.spray_phase=0.;p.shot_time=-100.;p.switch_until=clock+.3;equip_ammo(p)
	if id==local_id:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func choose_spawn(id:int) -> Vector3:
	var p=players[id];var pts=arena.spawn_candidates(int(p.team),int(options.mode)==1 or int(options.mode)==3)
	var best=pts[0];var best_score=-1e9
	for pos in pts:
		var enemy_distance=160.;var ally_distance=60.;var exposed=0.;var occupied=false
		for prop in arena.props.values():
			if prop.global_position.distance_to(pos)<1.5:occupied=true
		for other in players:
			if other==id or not players[other].alive:continue
			var distance=pos.distance_to(actors[other].position)
			if distance<1.3:occupied=true
			if enemies(p,players[other]):
				enemy_distance=minf(enemy_distance,distance)
				if distance<65 and clear_line(pos+Vector3.UP*1.5,actors[other].eye()):exposed+=35.
			else:ally_distance=minf(ally_distance,distance)
		if occupied:continue
		var score=minf(enemy_distance,100.)*1.5-ally_distance*.35-exposed+randf()*7
		if score>best_score:best_score=score;best=pos
	return best
func can_attack(p:Dictionary) -> bool:return p.alive and float(p.get("protect",0))<=clock
func passive_regen(p:Dictionary,dt:float):
	if options.autoheal and p.alive and clock-maxf(p.last_hit,float(p.get("shot_time",-100.)))>=R.REGEN_DELAY:p.hp=minf(100.,p.hp+R.REGEN_RATE*dt)
func kick_player(requester:int,target:int,by_vote=false) -> bool:
	if not server or (requester!=1 and not by_vote) or target==1 or not players.has(target):return false
	var name=players[target].nick;var token=players[target].token
	if target>0:
		banned_tokens[token]=Time.get_ticks_msec()+180000
		if target in multiplayer.get_peers():
			reject.rpc_id(target,"투표로 강퇴되었습니다. 3분 뒤 다시 참가할 수 있습니다." if by_vote else "방장이 강퇴했습니다. 3분 뒤 다시 참가할 수 있습니다.")
			get_tree().create_timer(.25).timeout.connect(func():
				if server and target in multiplayer.get_peers():multiplayer.multiplayer_peer.disconnect_peer(target))
	disconnected(target);reconnects.erase(token);announce(name+" 강퇴");return true
func start_kick_vote(requester:int,target:int) -> bool:
	if not server or requester<=0 or target<=0 or target==1 or requester==target or not players.has(requester) or not players.has(target) or not vote.is_empty():return false
	if Time.get_ticks_msec()<int(vote_cooldowns.get(requester,0)):return false
	var eligible=[]
	for id in players:
		if id>0 and id!=target:eligible.append(id)
	if eligible.size()<2:feedback(requester,"","강퇴 투표는 대상 외 참가자가 2명 이상 있어야 합니다.");return false
	vote={"target":target,"name":players[target].nick,"eligible":eligible,"votes":{requester:true},"needed":maxi(2,int(ceil(eligible.size()*.6))),"until":clock+25.}
	vote_cooldowns[requester]=Time.get_ticks_msec()+60000;announce(players[target].nick+" 강퇴 투표 · F6 찬성 / F7 반대");broadcast_state(true);return true
func cast_kick_vote(id:int,yes:bool) -> bool:
	if not server or vote.is_empty() or id not in vote.eligible or vote.votes.has(id):return false
	vote.votes[id]=yes;update_kick_vote();broadcast_state(true);return true
func update_kick_vote():
	if vote.is_empty():return
	if not players.has(vote.target):vote.clear();return
	var yes=0
	for id in vote.votes:
		if players.has(id) and vote.votes[id]:yes+=1
	if yes>=int(vote.needed):
		var target=int(vote.target);vote.clear();kick_player(1,target,true)
	elif clock>=float(vote.until):vote.clear();announce("강퇴 투표가 종료되었습니다.")
func disconnected(id:int):
	peer_activity.erase(id);pending_peers.erase(id)
	if not players.has(id):return
	if server:
		var p=players[id];p.alive=false;reconnects[p.token]=p.duplicate(true)
		for did in devices.keys():
			if devices[did].owner==id:remove_device(did)
	players.erase(id);bot_agents.erase(id)
	if actors.has(id):actors[id].queue_free();actors.erase(id)
	if server:call_deferred("broadcast_state",true)
func leave_game(message:String=""):
	kill_events.clear();kill_serial=0
	if is_instance_valid(kill_replay):kill_replay.reset()
	if is_instance_valid(ui.damage_indicator):ui.damage_indicator.clear_hits()
	combat_fx.clear();heal_sound_times.clear()
	if is_instance_valid(audio_bank):audio_bank.stop_all()
	if multiplayer.multiplayer_peer:multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	server=false;phase="menu";vote.clear();vote_cooldowns.clear();reset_transport_state();stop_room_search()
	for a in actors.values():a.queue_free()
	actors.clear();players.clear();bot_agents.clear();bot_navigation=null
	for n in device_nodes.values():n.queue_free()
	device_nodes.clear();devices.clear();fields.clear();drops.clear();reconnects.clear()
	for node in drop_nodes.values():node.queue_free()
	drop_nodes.clear()
	for node in wall_marks:
		if is_instance_valid(node):node.queue_free()
	wall_marks.clear()
	if arena:arena.queue_free();arena=null
	if discovery:discovery.close();discovery=null
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;ui.menu();ui.notice(message)
func search_rooms():
	room_search_active=true;room_search_timer=3.;rooms.clear()
	ui.update_rooms()
	if browser:browser.close()
	browser=PacketPeerUDP.new();browser.bind(0);browser.set_broadcast_enabled(true);browser.set_dest_address("255.255.255.255",R.DISCOVERY);browser.put_packet("RELAYSTRIKE_DISCOVER".to_utf8_buffer())
	browser.set_dest_address("127.0.0.1",R.DISCOVERY);browser.put_packet("RELAYSTRIKE_DISCOVER".to_utf8_buffer())
func stop_room_search():
	room_search_active=false
	if browser:browser.close();browser=null
func network_discovery():
	if discovery:
		while discovery.get_available_packet_count()>0:
			var msg=discovery.get_packet().get_string_from_utf8();var ip=discovery.get_packet_ip();var port=discovery.get_packet_port()
			if msg=="RELAYSTRIKE_DISCOVER":
				discovery.set_dest_address(ip,port);discovery.put_packet(JSON.stringify({"game":"RelayStrike","name":options.room,"count":players.size(),"max":options.max_players,"mode":R.MODES[int(options.mode)],"version":R.VERSION}).to_utf8_buffer())
	if browser:
		while browser.get_available_packet_count()>0:
			var raw=browser.get_packet();var ip=browser.get_packet_ip()
			if raw.size()>2048:continue
			var d=JSON.parse_string(raw.get_string_from_utf8())
			if d is Dictionary and d.get("game")=="RelayStrike":rooms[ip]=d;ui.update_rooms()
func _unhandled_input(event):
	if is_instance_valid(kill_replay) and kill_replay.active:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE,KEY_ESCAPE]:kill_replay.finish()
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F6,KEY_F7]:
		command("vote",{"yes":event.keycode==KEY_F6});get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if phase!="menu":ui.toggle_pause();get_viewport().set_input_as_handled()
	if not actors.has(local_id) or Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:return
	var a=actors[local_id]
	if event is InputEventMouseMotion:
		var sensitivity=float(profile.sensitivity)*(float(profile.ads_sensitivity) if a.input_state.ads and players[local_id].alive else 1.)
		if players[local_id].alive:
			a.input_state.yaw-=event.relative.x*sensitivity;a.input_state.pitch=clampf(a.input_state.pitch-event.relative.y*sensitivity,-1.45,1.45)
		else:
			spectator_yaw-=event.relative.x*sensitivity;spectator_pitch=clampf(spectator_pitch-event.relative.y*sensitivity,-1.2,1.2)
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and players[local_id].alive:
		trigger_seq+=1;a.input_state.trigger_seq=trigger_seq
	for index in range(3,5):
		if event.is_action_pressed("item"+str(index)):command("slot",{"slot":index-1})
	if event.is_action_pressed("reload"):command("reload",{})
	if event.is_action_pressed("primary"):command("slot",{"slot":0})
	if event.is_action_pressed("secondary"):command("slot",{"slot":1})
	if event.is_action_pressed("skill"):command("skill",{})
	if event.is_action_pressed("gadget"):command("gadget",{})
	if event.is_action_pressed("gear"):ui.gear()
	if event.is_action_pressed("gadget_mode"):command("gadget_mode",{})
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not players[local_id].alive:cycle_spectator()
func command(action:String,data:Dictionary):
	if server:handle_command(local_id,action,data)
	else:request_command.rpc_id(1,action,data)
@rpc("any_peer","call_remote","reliable",0)
func request_command(action:String,data:Dictionary):
	if server:handle_command(multiplayer.get_remote_sender_id(),action,data)
func rate_limit(id:int,key:String,interval:float) -> bool:
	var k=str(id)+key
	if incoming_at.get(k,-100.)+interval>clock:return false
	incoming_at[k]=clock;return true
@rpc("any_peer","call_remote","unreliable_ordered",1)
func send_input(data:Dictionary):
	if not server:return
	var id=multiplayer.get_remote_sender_id()
	if not players.has(id) or not rate_limit(id,"input",.015):return
	var a=actors[id]
	for k in ["x","z","yaw","pitch"]:
		if not data.has(k) or not (data[k] is float or data[k] is int) or not is_finite(float(data[k])):return
	if absf(data.yaw)>1e8:return
	a.input_state={"x":clampf(data.x,-1,1),"z":clampf(data.z,-1,1),"yaw":wrapf(data.yaw,-PI,PI),"pitch":clampf(data.pitch,-1.45,1.45),"ads":bool(data.get("ads",false)),"sprint":bool(data.get("sprint",false)),"crouch":bool(data.get("crouch",false)),"fire":bool(data.get("fire",false)),"alt":bool(data.get("alt",false)),"jump":bool(data.get("jump",false)),"use":bool(data.get("use",false)),"trigger_seq":maxi(0,int(data.get("trigger_seq",0)))}
	players[id].input_time=clock;peer_activity[id]=Time.get_ticks_msec()
func collect_input():
	if not actors.has(local_id):return
	var a=actors[local_id];var on=Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and players[local_id].alive and not (is_instance_valid(kill_replay) and kill_replay.active)
	a.input_state.x=Input.get_axis("left","right") if on else 0.;a.input_state.z=Input.get_axis("forward","back") if on else 0.
	for k in ["sprint","crouch","jump","use"]:a.input_state[k]=on and Input.is_action_pressed(k)
	a.input_state.ads=on and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT);a.input_state.fire=on and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT);a.input_state.alt=on and Input.is_action_pressed("medical")
	if server:players[local_id].input_time=clock
	else:send_input.rpc_id(1,a.input_state)
func _physics_process(dt:float):
	clock+=dt
	if is_instance_valid(kill_replay):kill_replay.capture(dt)
	if not demo_mode:network_discovery();connection_watchdog()
	if server:update_kick_vote()
	if room_search_active:
		room_search_timer-=dt
		if room_search_timer<=0:search_rooms()
	if phase=="menu":return
	input_timer-=dt
	if input_timer<=0:collect_input();input_timer=1./30
	if server:
		server_tick(dt)
		snapshot_timer-=dt
		full_sync_timer-=dt
		if snapshot_timer<=0 and not demo_mode:broadcast_state(full_sync_timer<=0);snapshot_timer=1./15
		if full_sync_timer<=0:full_sync_timer=3.
	else:
		if actors.has(local_id) and players[local_id].alive:
			AimModel.recover(players[local_id],current_weapon(players[local_id]),dt,clock)
			actors[local_id].simulate(dt,clock,phase=="combat" or phase=="lobby")
		ping_timer-=dt
		if ping_timer<=0:ping_request.rpc_id(1,Time.get_ticks_msec());ping_timer=1.
	for id in actors:
		if players.has(id):
			if DisplayServer.get_name()=="headless":actors[id].headless_pose(players[id])
			else:actors[id].visual(dt,players[id],clock)
	update_world_visuals(dt)
	if not demo_mode:update_spectator();ui.refresh()
@rpc("any_peer","call_remote","unreliable",2)
func ping_request(sent:int):
	if server and players.has(multiplayer.get_remote_sender_id()) and rate_limit(multiplayer.get_remote_sender_id(),"ping",.5):
		peer_activity[multiplayer.get_remote_sender_id()]=Time.get_ticks_msec();ping_reply.rpc_id(multiplayer.get_remote_sender_id(),sent)
@rpc("authority","call_remote","unreliable",2)
func ping_reply(sent:int):ping_ms=maxi(0,Time.get_ticks_msec()-sent)
func server_tick(dt:float):
	if bot_navigation:bot_navigation.refresh(devices,clock,arena.props)
	for id in players:
		var p=players[id];var a=actors[id]
		if id<0:bot_input(id,dt)
		elif clock-p.input_time> .5:
			a.input_state.x=0.;a.input_state.z=0.;a.input_state.fire=false;a.input_state.alt=false;a.input_state.use=false
		if not p.alive:
			if phase=="combat" and clock>=p.respawn and not p.spectator and int(options.mode)!=4 and (int(options.mode)!=2 or (p.can_respawn if options.shared_lives else p.lives>0)):spawn(id)
			continue
		AimModel.recover(p,current_weapon(p),dt,clock)
		var before_move=a.position
		a.simulate(dt,clock,phase in ["combat","lobby"])
		p.gait=a.gait
		p.step_distance=float(p.get("step_distance",0))+(Vector2(a.position.x-before_move.x,a.position.z-before_move.z).length() if a.is_on_floor() else 0.)
		if a.is_on_floor() and int(floor(a.gait*2))>int(p.get("step_index",0)):
			p.step_index=int(floor(a.gait*2));p.step_variant=int(p.step_index)%4
			var surface="water" if arena.wading(a.position) else "metal" if absf(a.position.x)>72 and absf(a.position.z)<35 else "stone"
			step_sound.rpc(a.position,id,surface,p.step_variant,-7. if a.input_state.crouch else 2. if a.last_sprint else 0.)
		if phase!="combat":continue
		p.played+=dt
		var held_weapon=current_weapon(p)
		if p.reload>0 and clock>=p.reload:
			var wid=p.reload_weapon;var w=C.get_weapon(wid);var need=int(w.mag)-int(p.mag.get(wid,0));var got=need if options.infinite else mini(need,int(p.reserve.get(wid,0)))
			p.mag[wid]=int(p.mag.get(wid,0))+got
			if not options.infinite:p.reserve[wid]=int(p.reserve.get(wid,0))-got
			p.reload=0.;p.trigger_until=0.
		passive_regen(p,dt)
		if int(options.mode) in [0,1,3]:
			p.energy=minf(180,p.energy+dt*5)
			if clock>=p.heal_ready+8 and p.heal_mag<3:p.heal_mag+=1;p.heal_ready=clock
		p.repair_energy=minf(100,p.repair_energy+dt*8 if not a.input_state.fire else p.repair_energy)
		process_trigger(id)
		if a.input_state.alt and p.role==5 and p.primary=="m2" and p.slot==0:heal_burst(id)
		if a.input_state.use:interact(id,dt)
		p.last_pos=a.position
	update_devices(dt);update_fields(dt);update_pickups()
	if phase in ["buy","combat","result","round_end"]:
		remaining-=dt
		if phase=="buy" and remaining<=0:phase="combat";remaining=150.;announce("라운드 시작")
		elif phase=="round_end" and remaining<=0:begin_round()
		elif phase=="result" and remaining<=0:next_match()
		elif phase=="combat":check_objectives(dt)
func bot_input(id:int,dt:float):
	if bot_agents.has(id):bot_agents[id].tick(dt)
func enemies(p:Dictionary,q:Dictionary) -> bool:return int(options.mode)==1 or p.team!=q.team
func medic_count(team:int) -> int:
	var n=0
	for p in players.values():
		if p.team==team and p.role==5:n+=1
	return n
func team_count(team:int) -> int:
	var n=0
	for p in players.values():
		if p.team==team:n+=1
	return n
func handle_command(id:int,action:String,data:Dictionary):
	if not players.has(id) or not rate_limit(id,"cmd_"+action,.08):return
	var p=players[id]
	match action:
		"start":
			if id==1 and phase=="lobby":start_match()
		"slot":
			var slot=clampi(int(data.get("slot",0)),0,3)
			if slot>=2 and not options.classes:return
			if slot==3 and p.role!=4:return
			if slot==4 and not options.skills:return
			if slot==p.slot:return
			p.slot=slot;p.reload=0.;p.burst_left=0;p.trigger_until=0.;p.fire_ready=maxf(p.fire_ready,clock+.32);p.switch_until=clock+.32
			feedback(id,"switch","")
			if p.role==4 and slot in [2,3]:p.gadget=slot-2
		"reload":begin_reload(id)
		"loadout":apply_loadout(id,data)
		"kick":kick_player(id,int(data.get("target",0)))
		"vote_kick":start_kick_vote(id,int(data.get("target",0)))
		"vote":cast_kick_vote(id,bool(data.get("yes",false)))
		"team":change_team(id,int(data.get("player_id",id)),int(data.get("team",0)))
		"team_swap":swap_teams(id,int(data.get("first",0)),int(data.get("second",0)))
		"team_policy":
			if id!=1:return
			options.next_teams=clampi(int(data.get("next_teams",options.next_teams)),0,2);broadcast_state(true)
		"skill":use_skill(id)
		"gadget":use_gadget(id)
		"gadget_mode":
			if p.role==4:p.gadget=0 if p.gadget==1 else 1
func change_team(requester:int,target:int,team:int) -> bool:
	if not players.has(target) or team not in [0,1] or int(options.mode)==1:return false
	if requester!=1 and (phase!="lobby" or requester!=target):feedback(requester,"","경기 중 팀 변경은 방장만 할 수 있습니다.");return false
	var p=players[target]
	if p.team==team:return true
	if team_count(team)>=16:feedback(requester,"","한 팀은 최대 16명입니다.");return false
	p.team=team
	finish_team_change(target);enforce_medics();broadcast_state(true);return true
func swap_teams(requester:int,first:int,second:int) -> bool:
	if requester!=1 or first==second or not players.has(first) or not players.has(second) or int(options.mode)==1:return false
	var one=players[first];var two=players[second]
	if one.team==two.team:return false
	var old_team=one.team;one.team=two.team;two.team=old_team
	finish_team_change(first);finish_team_change(second);enforce_medics();broadcast_state(true);return true
func finish_team_change(target:int):
	var p=players[target]
	for did in devices.keys():
		if devices[did].owner==target:remove_device(did)
	if phase=="lobby":spawn(target)
	else:
		p.alive=false;p.protect=0.;p.reload=0.;p.respawn=clock+3.;p.spectator=int(options.mode)==4;p.can_respawn=p.lives>0;actors[target].collision_layer=0
	actors[target].set_team(p.team)
func valid_loadout(p:Dictionary,d:Dictionary) -> bool:
	var role=clampi(int(d.get("role",p.role)),0,5);var wid=str(d.get("primary",C.first(role)))
	if not C.weapons.has(wid) or C.get_weapon(wid).slot!=0:return false
	if options.classes and int(C.get_weapon(wid).role)!=role:return false
	if not options.classes and C.get_weapon(wid).kind!="gun":return false
	return true
func loadout_cost(p:Dictionary,d:Dictionary) -> int:
	if int(options.mode)!=4:return 0
	var cost=0;var wid=str(d.get("primary",p.primary));var role=int(d.get("role",p.role));var armor=clampi(int(d.get("armor",0)),0,2)*25
	if wid!=p.primary or not p.get("owned_primary",false):cost+=int(C.get_weapon(wid).price)
	if armor>p.armor:cost+=300 if armor==25 else 600
	if role==3:cost+=[300,600,1000][clampi(int(d.get("gadget",0)),0,2)]
	elif role==4:cost+=400
	return cost
func apply_loadout(id:int,d:Dictionary):
	var p=players[id]
	if not valid_loadout(p,d):feedback(id,"","이 병과에서 선택할 수 없는 무기입니다.");return
	if phase not in ["lobby","buy"]:
		p.pending_loadout=d.duplicate();feedback(id,"","선택 예약 완료 · 다음 부활"+(" / 다음 라운드 구매 시간" if int(options.mode)==4 else "")+"에 적용됩니다.");return
	commit_loadout(id,d)
func commit_loadout(id:int,d:Dictionary):
	var p=players[id]
	if not valid_loadout(p,d):return
	var role=clampi(int(d.get("role",p.role)),0,5)
	if role==5 and p.role!=5 and options.classes and medic_count(p.team)>=R.medic_cap(team_count(p.team)):feedback(id,"","메딕 정원이 차서 이전 장비를 유지합니다.");return
	var wid=str(d.get("primary",C.first(role)));var sec=R.SECONDARIES[role]
	if role==3 and d.get("repair",false):sec="repair"
	var armor=clampi(int(d.get("armor",0)),0,2)*25;var gadget=clampi(int(d.get("gadget",0)),0,2)
	var cost=loadout_cost(p,d) if phase=="buy" else 0
	if p.cash<cost:feedback(id,"","구매 실패 · 필요 %d / 보유 %d 크레딧"%[cost,p.cash]);return
	p.cash-=cost
	if p.role!=role:
		for did in devices.keys():
			if devices[did].owner==id:remove_device(did)
	p.role=role;p.primary=wid;p.secondary=sec;p.armor_max=armor;p.armor=armor;p.slot=0;p.gadget=gadget;p.gadget_count=2 if role==3 else 3 if role==4 else 1;p.smoke=1 if gadget==1 else 2;p.flash_count=2 if gadget==1 else 1;p.reload=0.;p.owned_primary=true;p.burst_left=0;p.trigger_until=0.;p.switch_until=clock+.32;p.fire_ready=clock+.32;equip_ammo(p)
	feedback(id,"","구매 완료 · %d 크레딧 사용"%cost if cost>0 else "장비 적용 완료")
func begin_reload(id:int):
	var p=players[id]
	if not p.alive or p.reload>0 or p.slot>1:return
	var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
	if w.kind!="gun":return
	if int(p.mag.get(wid,0))<int(w.mag) and (options.infinite or int(p.reserve.get(wid,0))>0):
		p.reload=clock+float(w.reload);p.reload_started=clock;p.reload_weapon=wid;p.burst_left=0;feedback(id,"reload","")
func process_trigger(id:int):
	var p=players[id];var a=actors[id];var held=bool(a.input_state.fire);var seq=int(a.input_state.get("trigger_seq",0))
	var pressed=seq>int(p.get("trigger_seen",0)) or (held and not p.get("fire_prev",false))
	p.trigger_seen=maxi(seq,int(p.get("trigger_seen",0)));p.fire_prev=held
	if p.slot>=2:
		if pressed and clock>=p.fire_ready:
			if p.slot==4:use_skill(id)
			else:
				if p.role==4:p.gadget=p.slot-2
				use_gadget(id)
		return
	var w=current_weapon(p);var mode=w.get("fire_mode","auto")
	if pressed and p.reload<=0:p.trigger_until=clock+.55
	if mode=="auto":
		if held:fire(id)
		return
	if clock<p.fire_ready or p.reload>0 or clock<a.sprint_release or a.last_sprint:return
	if p.get("burst_left",0)==0 and p.get("trigger_until",0)>clock:
		p.trigger_until=0.;p.burst_left=3 if mode=="burst" else 1
	if p.get("burst_left",0)>0:
		var before=int(p.mag.get(p.primary if p.slot==0 else p.secondary,0));fire(id)
		if before>int(p.mag.get(p.primary if p.slot==0 else p.secondary,0)):
			p.burst_left=maxi(0,p.burst_left-1)
			if mode=="burst" and p.burst_left==0:p.fire_ready=clock+.3
func current_weapon(p:Dictionary) -> Dictionary:return C.get_weapon(p.primary if p.slot==0 else p.secondary)
func ray(from:Vector3,to:Vector3,exclude:Array=[],mask:int=15) -> Dictionary:
	var q=PhysicsRayQueryParameters3D.create(from,to,mask);q.exclude=exclude;return get_world_3d().direct_space_state.intersect_ray(q)
func clear_line(from:Vector3,to:Vector3,exclude:Array=[]) -> bool:return ray(from,to,exclude,1|4|8).is_empty()
func fire(id:int):
	var p=players[id];var a=actors[id]
	if p.slot>1 or not can_attack(p) or clock<p.fire_ready or p.reload>0 or clock<a.sprint_release or a.last_sprint or p.shield>clock:return
	var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
	if w.kind=="heal":continuous_heal(id);return
	if w.kind=="repair":repair(id);return
	if int(p.mag.get(wid,0))<=0:begin_reload(id);return
	p.mag[wid]-=1;p.fire_ready=clock+float(w.interval)
	var spread=a.spread_angle
	var spray=AimModel.current_spray(w,p)
	p.shot_time=clock;p.spray_phase=float(p.get("spray_phase",0))+1.;p.spray_index=int(p.spray_phase);p.bloom=minf(float(w.get("bloom_max",1.2)),float(p.get("bloom",0))+float(w.get("shot_bloom",.12)))
	var origin=a.muzzle_world();var eye=a.eye();var last_end=origin+a.direction()*200
	for pellet in range(int(w.pellets)):
		var forward=Basis(Vector3.UP,a.aim_yaw-deg_to_rad(spray.x))*Basis(Vector3.RIGHT,a.aim_pitch+deg_to_rad(spray.y))*Vector3.FORWARD
		var dir=AimModel.cone_direction(forward,spread,randf(),randf())
		var aim_hit=ray(eye,eye+dir*300,[a.get_rid()]);var aim_point=aim_hit.get("position",eye+dir*300)
		var hit=ray(origin,origin+(aim_point-origin).normalized()*minf(300,origin.distance_to(aim_point)+.15),[a.get_rid()]);last_end=hit.get("position",aim_point)
		if hit.is_empty():continue
		var dist=origin.distance_to(hit.position);var dmg=float(w.damage)*lerpf(1.,.4,clampf((dist-float(w.reach))/maxf(float(w.reach),1),0,1))
		var collider=hit.collider
		if collider is Actor:
			var q=players[collider.pid]
			if not q.alive:continue
			var head=hit.position.y-collider.position.y>collider.head_threshold()
			if head:dmg*=1.5
			dmg*=R.damage_water(arena.submerged(hit.position),arena.wading(a.position),not arena.wading(collider.position))
			damage(collider.pid,dmg,id,head,wid)
		elif collider is InteractiveProp:collider.hit(hit.position,(hit.position-origin).normalized(),dmg)
		elif collider.has_meta("device"):damage_device(int(collider.get_meta("device")),dmg,id)
		elif pellet==0:wall_mark.rpc(hit.position,hit.normal)
	effect.rpc("shot",origin,last_end,id,clock)
	if int(p.mag[wid])==0:begin_reload(id)
func damage(target:int,amount:float,source:int,critical:bool=false,weapon_id:String="world",hit_origin:Vector3=Vector3.INF):
	if not players.has(target) or not players[target].alive:return
	var p=players[target]
	if p.protect>clock:return
	if players.has(source) and target!=source and not enemies(players[source],p) and not options.friendly:return
	if p.shield>clock and actors.has(source):
		var dir=(actors[source].position-actors[target].position).normalized()
		if actors[target].direction().dot(dir)>.4:amount*=.15
	var armored=p.armor>0
	var absorb=minf(p.armor,amount);p.armor-=absorb;p.hp-=amount-absorb;p.last_hit=clock
	if target<0 and bot_navigation:bot_navigation.danger(actors[target].position)
	var origin=hit_origin if hit_origin.is_finite() else actors[source].position if actors.has(source) and source!=target else actors[target].position
	var push=(actors[target].position-origin).normalized() if origin.distance_squared_to(actors[target].position)>.001 else Vector3.FORWARD
	impact.rpc(actors[target].eye()-Vector3.UP*.35,push,false,int(p.team))
	hit_reaction.rpc(target,push)
	if target==local_id:damage_notice(target,origin,amount,armored)
	elif target>0 and target in multiplayer.get_peers():damage_notice.rpc_id(target,target,origin,amount,armored)
	if source!=target:p.contributors[source]=clock
	if source>0:feedback(source,"hit",("정밀 명중" if critical else "방어구 명중" if armored else "명중")+" · "+str(int(round(amount))))
	if p.hp<=0:
		impact.rpc(actors[target].position,push,true,int(p.team),int(p.role),randi()%5,actors[target].aim_yaw,bool(actors[target].input_state.crouch))
		p.hp=0;p.alive=false;p.deaths+=1;p.lives-=1;p.respawn=clock+4.;
		p.can_respawn=p.lives>0
		if int(options.mode)==2 and options.shared_lives:
			p.can_respawn=tickets[p.team]>0
			if p.can_respawn:tickets[p.team]-=1
		p.owned_primary=false
		actors[target].collision_layer=0
		var wid=p.secondary if p.slot==1 else p.primary;drops.append({"pos":actors[target].position+Vector3.UP*.18,"yaw":actors[target].aim_yaw,"amount":int(p.mag.get(wid,0))+int(p.reserve.get(wid,0)),"weapon":wid,"until":clock+40})
		if players.has(source) and source!=target:
			players[source].kills+=1
			if int(options.mode)==0:scores[players[source].team]+=1
			var reward=mini(100,600-int(players[source].round_bonus));players[source].cash=mini(8000,players[source].cash+reward);players[source].round_bonus+=reward
			feedback(source,"confirm","처치 확인")
		for aid in p.contributors:
			if aid!=source and players.has(aid) and clock-p.contributors[aid]<8:players[aid].assists+=1
		var attacker=players.get(source,{})
		kill_event.rpc({"attacker":source,"attacker_name":str(attacker.get("nick","환경")),"attacker_team":int(attacker.get("team",-1)),"victim":target,"victim_name":str(p.nick),"victim_team":int(p.team),"weapon":weapon_id,"critical":critical,"origin":origin,"victim_pos":actors[target].position})
@rpc("authority","call_local","reliable",0)
func kill_event(event:Dictionary):
	var item=event.duplicate(true);kill_serial+=1;item.serial=kill_serial;item.received=Time.get_ticks_msec();kill_events.append(item)
	while kill_events.size()>KillFeed.MAX_ROWS:kill_events.pop_front()
	if is_instance_valid(kill_replay):kill_replay.request(item)
func damage_device(did:int,amount:float,source:int):
	if not devices.has(did):return
	var d=devices[did]
	if players.has(source) and d.team==players[source].team and int(options.mode)!=1 and not options.friendly:return
	d.hp-=amount;d.last_hit=clock
	if d.hp<=0:effect.rpc("deploy",d.pos+Vector3.UP,Vector3.ZERO,source);remove_device(did)
func aim_player(id:int,range_m:float,ally:bool) -> int:
	var a=actors[id];var hit=ray(a.eye(),a.eye()+a.direction()*range_m,[a.get_rid()])
	if hit.is_empty() or not hit.collider is Actor:return 0
	var tid=hit.collider.pid
	if not players[tid].alive:return 0
	return tid if enemies(players[id],players[tid])!=ally else 0
func heal_target(id:int,tid:int,amount:float):
	if tid==0:return
	var p=players[id];var q=players[tid];var healed=minf(100-q.hp,amount*(.5 if clock-q.last_hit<2 else 1.))
	if q.get("healing_until",0)>clock and q.get("healer",id)!=id:return
	q.hp+=healed;q.healing_until=clock+.12;q.healer=id;p.healed+=healed
	if healed>0:effect.rpc("heal",actors[id].eye(),actors[tid].eye(),id)
func continuous_heal(id:int):
	var p=players[id];p.fire_ready=clock+.1
	if p.energy<2.4:return
	var tid=aim_player(id,10,true)
	if tid==0 or players[tid].hp>=100:return
	if players[tid].get("healing_until",0)>clock and players[tid].get("healer",id)!=id:return
	p.energy-=2.4;heal_target(id,tid,2.4)
func heal_burst(id:int):
	var p=players[id];var a=actors[id]
	if clock<p.heal_ready or clock<p.fire_ready or p.reload>0 or a.last_sprint or clock<a.sprint_release:return
	if p.heal_mag<=0:
		if p.heal_reserve>0:p.heal_mag=mini(3,p.heal_reserve);p.heal_reserve-=p.heal_mag;p.heal_ready=clock+2
		return
	var tid=aim_player(id,15,true)
	if tid==0 or players[tid].hp>=100:return
	if players[tid].get("healing_until",0)>clock and players[tid].get("healer",id)!=id:return
	p.heal_mag-=1;p.heal_ready=clock+2;p.fire_ready=maxf(p.fire_ready,clock+.2);heal_target(id,tid,20)
func repair(id:int):
	var p=players[id];var a=actors[id];p.fire_ready=clock+.1
	if p.repair_energy<2:return
	var hit=ray(a.eye(),a.eye()+a.direction()*4,[a.get_rid()])
	if hit.is_empty() or not hit.collider.has_meta("device"):return
	var did=int(hit.collider.get_meta("device"))
	if not devices.has(did):return
	var d=devices[did]
	if d.team!=p.team or d.hp>=d.max_hp or d.get("repair_until",0)>clock:return
	d.hp=minf(d.max_hp,d.hp+(2 if clock-d.last_hit<2 else 8));d.repair_until=clock+.09;p.repair_energy-=2;effect.rpc("heal",a.eye(),d.pos+Vector3.UP,id)
func placement(id:int) -> Vector3:
	var a=actors[id];var forward=a.direction();forward.y=0;forward=forward.normalized();return a.position+forward*3
func valid_placement(pos:Vector3,yaw:float=0.) -> bool:
	if absf(pos.x)>94 or absf(pos.z)>71 or arena.wading(pos):return false
	for s in arena.sites:
		if s.distance_to(pos)<5:return false
	var query=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=Vector3(3.4,1.1,1.2);query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3(0,.7,0));query.collision_mask=15
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func add_device(kind:String,pos:Vector3,id:int,hp:float) -> int:
	var did=next_device;next_device+=1
	devices[did]={"id":did,"kind":kind,"pos":pos,"yaw":actors[id].aim_yaw,"owner":id,"team":players[id].team,"hp":hp,"max_hp":hp,"level":1,"next_fire":clock+1,"target":0,"lock":0.,"last_hit":-100.,"disabled":0.,"expires":clock+180 if kind=="cover" and int(options.mode)!=4 else 1e12}
	return did
func use_skill(id:int):
	var p=players[id];var a=actors[id]
	if not options.skills or not options.classes or not can_attack(p) or phase!="combat":return
	if clock<p.skill_ready:feedback(id,"","스킬 충전 중: "+str(int(ceil(p.skill_ready-clock)))+"초");return
	match int(p.role):
		0:p.dash=clock+.28;p.fire_ready=clock+.6;p.skill_ready=clock+18
		1:
			for qid in players:
				if players[qid].alive and enemies(p,players[qid]) and a.position.distance_to(actors[qid].position)<30:players[qid].mark=clock+3
			p.skill_ready=clock+30;announce(p.nick+" · 감지 파동")
		2:p.shield=clock+4;p.skill_ready=clock+30
		3:
			var existing=0
			for did in devices:
				if devices[did].owner==id and devices[did].kind=="turret":existing=did
			if existing and a.position.distance_to(devices[existing].pos)<5:
				var hit=ray(a.eye(),a.eye()+a.direction()*6,[a.get_rid()])
				if not hit.is_empty() and int(hit.collider.get_meta("device",0))==existing:
					var d=devices[existing]
					if d.level>=4:feedback(id,"","이미 최대 4단계입니다.");return
					d.level+=1;d.max_hp+=50;d.hp+=50;d.disabled=clock+2;p.skill_ready=clock+30;feedback(id,"heal","포탑 %d단계 업그레이드"%d.level);return
			var pos=placement(id)
			if not valid_placement(pos,a.aim_yaw):feedback(id,"","설치 공간이 부족하거나 제한 구역입니다.");return
			if existing:remove_device(existing)
			var did=add_device("turret",pos,id,200);devices[did].disabled=clock+2;p.skill_ready=clock+30
		4:
			fields.append({"kind":"slow","pos":placement(id)+a.direction()*5,"until":clock+8,"team":p.team,"owner":id});p.skill_ready=clock+25
		5:
			var tid=aim_player(id,15,true)
			if tid==0:tid=id
			players[tid].slow=0.;players[tid].mark=0.;players[tid].flash=0.;players[tid].cleanse=clock+4;p.skill_ready=clock+20
	effect.rpc("skill",a.position,Vector3.ZERO,id)
	feedback(id,"",["기동 스킬 사용","감지 파동 · 3초","방호 활성 · 4초","포탑 설치 완료 · 재충전 30초","둔화 구역 전개 · 8초","상태 정화 · 4초"][int(p.role)])
func use_gadget(id:int):
	var p=players[id];var a=actors[id]
	if not options.classes or not can_attack(p) or phase!="combat" or p.gadget_count<=0 or clock<p.gadget_ready:return
	match int(p.role):
		0:
			if p.armor>=50:feedback(id,"","방어구가 이미 가득 찼습니다.");return
			p.armor=minf(50,p.armor+25)
		1:
			var tid=aim_player(id,160,false)
			if tid==0:feedback(id,"","표식할 상대를 조준하세요.");return
			players[tid].mark=clock+4
		2:
			if not a.input_state.crouch:feedback(id,"","앉아서 거치대를 사용하세요.");return
			p.mounted=clock+15
		3:
			var count=0
			for d in devices.values():
				if d.owner==id and d.kind=="cover":count+=1
			if count>=2:feedback(id,"","동시 엄폐물 한도는 2개입니다.");return
			var pos=placement(id)
			if not valid_placement(pos,a.aim_yaw):feedback(id,"","여기에는 엄폐물을 설치할 수 없습니다.");return
			add_device("cover",pos,id,[250,500,800][int(p.gadget)])
		4:
			var end=a.eye()+a.direction()*18;var hit=ray(a.eye(),end,[a.get_rid()],1|4)
			if not hit.is_empty():end=hit.position
			end.y=.3
			if p.gadget==1:
				if p.flash_count<=0:feedback(id,"","섬광탄 없음 · V로 연막탄 선택");return
				p.flash_count-=1;effect.rpc("throw",a.muzzle_world(),end,id)
				fields.append({"kind":"flash_pending","pos":end,"starts":clock+.35,"until":clock+1.,"team":p.team,"owner":id})
			else:
				if p.smoke<=0:feedback(id,"","연막탄 없음 · V로 섬광탄 선택");return
				p.smoke-=1;effect.rpc("throw",a.muzzle_world(),end,id);fields.append({"kind":"smoke","pos":end,"starts":clock+.35,"until":clock+12.35,"team":p.team,"owner":id,"deployed":false})
		5:
			var tid=aim_player(id,4,true)
			if tid==0:tid=id
			if players[tid].hp>=100:feedback(id,"","체력이 이미 가득 찼습니다.");return
			heal_target(id,tid,25)
	p.gadget_count-=1;p.gadget_ready=clock+.6
	if p.role!=4:effect.rpc("deploy",a.position,Vector3.ZERO,id)
	feedback(id,"",["방어구 +25","상대 표식 · 4초","거치대 활성 · 15초 동안 정지 사격 정확도 증가","엄폐물 설치 완료","섬광탄 사용" if p.gadget==1 else "연막탄 전개 · 12초","응급 회복 +25"][int(p.role)])
func remove_device(did:int):
	devices.erase(did)
	if device_nodes.has(did):device_nodes[did].queue_free();device_nodes.erase(did)
func in_smoke_line(from:Vector3,to:Vector3) -> bool:
	for f in fields:
		if f.kind=="smoke" and float(f.get("starts",0))<=clock and Geometry3D.get_closest_point_to_segment(f.pos+Vector3.UP*2,from,to).distance_to(f.pos+Vector3.UP*2)<5:return true
	return false
func update_devices(dt:float):
	for did in devices.keys():
		var d=devices[did]
		if clock>d.expires:remove_device(did);continue
		if d.kind!="turret" or clock<d.disabled or phase!="combat":continue
		if players.has(d.owner) and players[d.owner].protect>clock:continue
		var origin=d.pos+Vector3.UP*1.75;var target=0;var best=25.+(d.level-1)*5
		for id in players:
			var p=players[id]
			if not p.alive or id==d.owner or (p.team==d.team and int(options.mode)!=1):continue
			var distance=origin.distance_to(actors[id].eye())
			if distance<best and not in_smoke_line(origin,actors[id].eye()) and clear_line(origin,actors[id].eye(),[actors[id].get_rid(),device_nodes[did].get_rid()] if device_nodes.has(did) else [actors[id].get_rid()]):best=distance;target=id
		if target!=int(d.target):d.target=target;d.lock=clock+.7
		if target!=0 and clock>=d.lock and clock>=d.next_fire:
			d.next_fire=clock+.25;var damage_amount=(20.+(d.level-1)*4)*.25
			if arena.wading(d.pos) and not arena.wading(actors[target].position):damage_amount*=.5
			damage(target,damage_amount,int(d.owner),false,"turret",origin);effect.rpc("shot",origin,actors[target].eye(),0)
func update_fields(dt:float):
	fields=fields.filter(func(f):return f.until>clock)
	for f in fields:
		if float(f.get("starts",0))>clock:continue
		if f.kind=="flash_pending":
			for qid in players:
				if players[qid].alive and actors[qid].position.distance_to(f.pos)<15 and clear_line(f.pos+Vector3.UP,actors[qid].eye(),[actors[qid].get_rid()]):players[qid].flash=clock+2.5
			for device in devices.values():
				if device.pos.distance_to(f.pos)<15:device.disabled=clock+3
			effect.rpc("flash",f.pos,f.pos,int(f.owner));f.until=clock-1
		elif f.kind=="smoke" and not f.get("deployed",true):f.deployed=true;effect.rpc("smoke",f.pos,f.pos,int(f.owner))
		elif f.kind=="slow":
			for id in players:
				if players[id].alive and players[id].team!=f.team and players[id].get("cleanse",0)<clock and actors[id].position.distance_to(f.pos)<5:players[id].slow=clock+.2
func update_pickups():
	drops=drops.filter(func(d):return d.until>clock and d.amount>0)
	for id in players:
		var p=players[id]
		if not p.alive:continue
		var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
		if w.kind!="gun":continue
		for supply in arena.supplies:
			if supply.ready<=clock and actors[id].position.distance_to(supply.pos)<1.8 and int(p.reserve[wid])<int(w.reserve):
				p.reserve[wid]=mini(int(w.reserve),int(p.reserve[wid])+R.ammo_pickup(int(w.reserve)));supply.ready=clock+30;feedback(id,"","탄약 보급 +25%")
func interact(id:int,dt:float):
	var p=players[id];var a=actors[id]
	for drop in drops:
		if drop.amount>0 and a.position.distance_to(drop.pos)<2.5:
			var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
			if w.kind=="gun":
				var take=mini(int(w.reserve)-int(p.reserve[wid]),mini(R.ammo_pickup(int(w.reserve)),int(drop.amount)))
				p.reserve[wid]+=take;drop.amount-=take
	if int(options.mode)!=4 or phase!="combat":return
	var attackers=(round_no-1)/3%2
	if not bomb.planted and p.team==attackers:
		for i in range(arena.sites.size()):
			if a.position.distance_to(arena.sites[i])<5:
				if bomb.actor!=id:bomb.actor=id;bomb.progress=0
				bomb.last_touch=clock;bomb.progress+=dt
				if bomb.progress>=3:
					bomb.planted=true;bomb.site=i;bomb.position=arena.sites[i];bomb.time=40.;bomb.actor=0;bomb.progress=0;p.objective+=3
					for q in players.values():
						if q.team==p.team:q.cash=mini(8000,q.cash+300)
					announce("장치 설치 완료 · 40초 내 해체")
	elif bomb.planted and p.team!=attackers and a.position.distance_to(bomb.position)<5:
		if bomb.actor!=id:bomb.actor=id;bomb.progress=0
		bomb.last_touch=clock;bomb.progress+=dt
		if bomb.progress>=5:p.objective+=5;finish_round(p.team,"장치 해체")
func check_objectives(dt:float):
	match int(options.mode):
		0:
			if maxi(scores[0],scores[1])>=int(options.target) or remaining<=0:finish_match("무승부" if scores[0]==scores[1] else ("BLUE 승리" if scores[0]>scores[1] else "ORANGE 승리"))
		1:
			var best=0;var winner=""
			for p in players.values():
				if p.kills>=best:best=p.kills;winner=p.nick
			if best>=int(options.target) or remaining<=0:finish_match(winner+" 개인전 승리")
		2:
			var alive=[0,0]
			for p in players.values():
				if p.alive or (p.can_respawn if options.shared_lives else p.lives>0):alive[p.team]+=1
			if players.size()>1 and (alive[0]==0 or alive[1]==0):finish_match("BLUE 승리" if alive[0]>0 else "ORANGE 승리")
			elif remaining<=0:finish_match("시간 종료")
		3:
			for i in range(3):
				var counts=[0,0]
				for id in players:
					if players[id].alive and actors[id].position.distance_to(arena.zones[i])<7:counts[players[id].team]+=1
				if (counts[0]>0)!=(counts[1]>0):
					var team=0 if counts[0]>0 else 1;zone_capture[i]=clampf(zone_capture[i]+dt*(1 if team==0 else -1),-5,5)
					if absf(zone_capture[i])>=5 and zone_owner[i]!=team:
						zone_owner[i]=team
						for id in players:
							if players[id].team==team and actors[id].position.distance_to(arena.zones[i])<7:players[id].objective+=2
				if zone_owner[i]>=0:scores[zone_owner[i]]+=dt*.4
			if maxf(scores[0],scores[1])>=int(options.target) or remaining<=0:finish_match("BLUE 승리" if scores[0]>scores[1] else "ORANGE 승리")
		4:
			if bomb.actor!=0 and (not players.has(bomb.actor) or not players[bomb.actor].alive or not actors[bomb.actor].input_state.use or clock-bomb.get("last_touch",0)>.1):bomb.actor=0;bomb.progress=0
			var attackers=(round_no-1)/3%2;var alive=[0,0]
			for p in players.values():
				if p.alive:alive[p.team]+=1
			if bomb.planted:
				bomb.time-=dt
				if bomb.time<=0:effect.rpc("explosion",bomb.position,Vector3.ZERO,0);finish_round(attackers,"장치 작동");return
				if alive[1-attackers]==0 and team_count(1-attackers)>0:finish_round(attackers,"수비팀 전원 Dead");return
			else:
				if remaining<=0:finish_round(1-attackers,"설치 시간 종료");return
				if alive[attackers]==0 and team_count(attackers)>0:finish_round(1-attackers,"공격팀 전원 Dead");return
				if alive[1-attackers]==0 and team_count(1-attackers)>0:finish_round(attackers,"수비팀 전원 Dead")
func start_match():
	if server and arena:arena.reset_props()
	kill_events.clear()
	if is_instance_valid(ui.damage_indicator):ui.damage_indicator.clear_hits()
	if not server:return
	for p in players.values():
		p.kills=0;p.deaths=0;p.assists=0;p.objective=0;p.healed=0.;p.played=0.;p.lives=int(options.lives);p.cash=800;p.skill_ready=0.;p.spectator=false;p.can_respawn=true
		if int(options.mode)==4:p.owned_primary=false;p.armor_max=0;p.primary="pistol"
	enforce_medics();tickets=[int(options.lives),int(options.lives)];scores=[0,0];losses=[0,0];round_no=0;zone_owner=[-1,-1,-1];zone_capture=[0.,0.,0.]
	if int(options.mode)==4:begin_round()
	else:
		phase="combat";remaining=float(options.minutes)*60
		for id in players:spawn(id)
	ui.show_hud();broadcast_state(true)
func enforce_medics():
	for team in [0,1]:
		var n=0
		for p in players.values():
			if p.team==team and p.role==5:
				n+=1
				if n>R.medic_cap(team_count(team)):p.role=0;p.primary="a1";p.secondary="pistol";equip_ammo(p)
func begin_round():
	if server and arena:arena.reset_props()
	round_no+=1;bot_attack_site=randi()%2;phase="buy";remaining=20.;bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO}
	for did in devices.keys():remove_device(did)
	fields.clear();drops.clear()
	if round_no>1 and (round_no-1)%3==0:
		losses=[0,0]
		for p in players.values():p.cash=800;p.owned_primary=false;p.armor_max=0;p.primary="pistol"
	for id in players:
		var p=players[id];p.skill_ready=0.;p.round_bonus=0
		if not p.get("owned_primary",false):p.primary="pistol";p.slot=0;p.armor_max=0
		spawn(id)
	announce("구매 시간 · B 장비 선택")
func finish_round(winner:int,reason:String):
	if phase!="combat":return
	scores[winner]+=1;losses[winner]=maxi(0,losses[winner]-1);losses[1-winner]+=1
	for p in players.values():p.cash=mini(8000,p.cash+(3500 if p.team==winner else R.loss_reward(losses[p.team])))
	announce(reason+" · "+("BLUE" if winner==0 else "ORANGE")+" 승리")
	if scores[winner]>=int(options.rounds):finish_match("BLUE 승리" if winner==0 else "ORANGE 승리")
	else:phase="round_end";remaining=7
func finish_match(message:String):
	phase="result";remaining=12;announce(message+" · 다음 경기까지 12초")
func next_match():
	for did in devices.keys():remove_device(did)
	fields.clear();drops.clear()
	if int(options.next_teams)==2:
		var split=R.balanced_ids(players)
		for t in [0,1]:
			for id in split[t]:players[id].team=t;actors[id].set_team(t)
	elif int(options.next_teams)==1:
		var ids=players.keys();ids.shuffle()
		for i in range(ids.size()):players[ids[i]].team=i%2;actors[ids[i]].set_team(i%2)
	start_match()
func broadcast_state(force:bool,target_peer:int=0):
	if not server or arena==null:return
	var list=[]
	for id in players:
		var p=players[id];var a=actors[id];var d=p.duplicate();d.erase("token");d.erase("contributors");d.pos=a.position;d.yaw=a.aim_yaw;d.pitch=a.aim_pitch;d.crouch=a.input_state.crouch;d.velocity=a.velocity;d.grounded=a.is_on_floor();d.sprint=a.last_sprint;d.ads=a.input_state.ads;d.spread_angle=a.spread_angle;list.append(d)
	var supplies=[]
	for s in arena.supplies:supplies.append(s.ready)
	var state={"clock":clock,"phase":phase,"remaining":remaining,"scores":scores,"tickets":tickets,"round":round_no,"players":list,"devices":devices,"fields":fields,"drops":drops,"zones":zone_owner,"supplies":supplies,"bomb":bomb,"props":arena.prop_states()}
	if multiplayer.get_peers().size()>0:
		snapshot_sequence+=1;state.sequence=snapshot_sequence
		state.team_policy={"teams":options.teams,"next_teams":options.next_teams};state.vote=vote
		var packed=var_to_bytes(state).compress(FileAccess.COMPRESSION_DEFLATE)
		var parts=int(ceil(packed.size()/1000.0))
		for peer in multiplayer.get_peers():
			if (target_peer!=0 and peer!=target_peer) or not players.has(peer):continue
			var link=multiplayer.multiplayer_peer.get_peer(peer)
			if link.get_state()!=ENetPacketPeer.STATE_CONNECTED:continue
			if force:full_state.rpc_id(peer,state)
			else:
				for i in range(parts):snapshot_chunk.rpc_id(peer,snapshot_sequence,i,parts,packed.slice(i*1000,mini(packed.size(),(i+1)*1000)))
@rpc("authority","call_remote","unreliable",1)
func snapshot_chunk(seq:int,index:int,count:int,bytes:PackedByteArray):
	# Individual chunks may arrive out of order; apply only complete, newer frames.
	if seq<=received_sequence or count<1 or count>128 or index<0 or index>=count or bytes.size()>1000:return
	if not snapshot_buffers.has(seq):snapshot_buffers[seq]={"count":count,"parts":{},"at":Time.get_ticks_msec()}
	var frame=snapshot_buffers[seq]
	if count!=int(frame.count):return
	frame.parts[index]=bytes
	if frame.parts.size()==count:
		var joined=PackedByteArray()
		for i in range(count):joined.append_array(frame.parts[i])
		var unpacked=joined.decompress_dynamic(512000,FileAccess.COMPRESSION_DEFLATE)
		var state=bytes_to_var(unpacked)
		if state is Dictionary:receive_state(state)
	var keys=snapshot_buffers.keys();keys.sort()
	for key in keys:
		if key<=received_sequence or snapshot_buffers.size()>4 or Time.get_ticks_msec()-int(snapshot_buffers[key].at)>1000:snapshot_buffers.erase(key)
@rpc("authority","call_remote","reliable",0)
func full_state(s:Dictionary):receive_state(s)
@rpc("authority","call_remote","unreliable_ordered",1)
func snapshot(s:Dictionary):receive_state(s)
func receive_state(s:Dictionary):
	if server or arena==null:return
	var sequence=int(s.get("sequence",received_sequence+1))
	if sequence<=received_sequence:return
	received_sequence=sequence;last_snapshot_ms=Time.get_ticks_msec();connection_notice=false
	if s.has("team_policy"):options.merge(s.team_policy,true)
	vote=s.get("vote",{});clock=s.clock;var old_phase=phase;phase=s.phase;remaining=s.remaining;scores=s.scores;tickets=s.tickets;round_no=s.round;bomb=s.bomb;zone_owner=s.zones;fields=s.fields;drops=s.drops
	var present=[]
	for p in s.players:
		var id=int(p.id);var fresh=not players.has(id) or (not players[id].alive and p.alive);present.append(id);players[id]=p;ensure_actor(id);var a=actors[id];a.set_team(int(p.team));a.collision_layer=2 if p.alive else 0
		if id==local_id:
			if fresh:a.position=p.pos;a.velocity=Vector3.ZERO;a.reset_view(p.yaw)
			if a.position.distance_to(p.pos)>2 or not p.alive:a.position=p.pos
			else:a.position=a.position.lerp(p.pos,.25)
		else:a.target_pos=p.pos;a.aim_yaw=p.yaw;a.aim_pitch=p.pitch;a.input_state.crouch=p.crouch;a.net_velocity=p.get("velocity",Vector3.ZERO);a.net_grounded=p.get("grounded",true);a.net_sprint=p.get("sprint",false);a.remote_ads=p.get("ads",false);a.net_gait=float(p.get("gait",0.))
	for id in players.keys():
		if not present.has(id):players.erase(id);actors[id].queue_free();actors.erase(id)
	devices=s.devices
	arena.receive_props(s.get("props",[]))
	for i in range(mini(s.supplies.size(),arena.supplies.size())):arena.supplies[i].ready=s.supplies[i]
	if old_phase!=phase:
		if phase=="lobby":ui.lobby()
		elif phase in ["buy","combat"]:ui.show_hud();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func update_world_visuals(dt:float):
	if arena==null:return
	for did in devices:
		var d=devices[did]
		if not device_nodes.has(did):
			var b=StaticBody3D.new();b.collision_layer=4;b.collision_mask=0;b.set_meta("device",did);add_child(b);device_nodes[did]=b
			var size=Vector3(3.4,1.25,.65) if d.kind=="cover" else Vector3(.8,1.9,.8)
			CombatFX.device(b,d.kind,int(d.team))
			var c=CollisionShape3D.new();var sh=BoxShape3D.new();sh.size=size;c.shape=sh;c.position.y=size.y/2;b.add_child(c)
			var label=arena.text3d("",Vector3(0,2.4,0),Color.WHITE,25,b);label.name="Label"
		var node=device_nodes[did];node.position=d.pos;node.rotation.y=d.yaw;node.get_node("Label").text=("포탑 "+str(d.level) if d.kind=="turret" else "엄폐물")+" · "+str(int(d.hp))
		if d.kind=="turret" and actors.has(int(d.target)):
			var head=node.get_node("TurretHead");var target=actors[int(d.target)].eye();head.look_at(Vector3(target.x,head.global_position.y,target.z))
	for did in device_nodes.keys():
		if not devices.has(did):device_nodes[did].queue_free();device_nodes.erase(did)
	for s in arena.supplies:
		s.node.visible=s.ready<=clock
	combat_fx.sync_fields(fields,clock)
	var live_drops={}
	for d in drops:
		var key=str(d.until)+str(d.pos)+d.weapon;live_drops[key]=true
		if not drop_nodes.has(key):
			var n=WeaponVisual.new();add_child(n);n.build(Catalog.get_weapon(d.weapon),false);n.position=d.pos;n.rotation=Vector3(0,float(d.get("yaw",0)),PI/2);drop_nodes[key]=n
			var tag=arena.text3d(Catalog.get_weapon(d.weapon).name+" · E",Vector3(0,.4,0),Color("d7e8ef"),24,n);tag.top_level=true;tag.global_position=d.pos+Vector3.UP*.5;tag.visibility_range_end=12;tag.visibility_range_end_margin=1.5;tag.pixel_size=.004
	for key in drop_nodes.keys():
		if not live_drops.has(key):drop_nodes[key].queue_free();drop_nodes.erase(key)
func feedback(id:int,sound:String,message:String):
	if id<0:return
	if id==local_id:personal(sound,message)
	else:personal.rpc_id(id,sound,message)
@rpc("authority","call_remote","reliable",0)
func personal(sound:String,message:String):
	if not sound.is_empty():play_sound(sound,Vector3.ZERO,false)
	ui.notice(message)
	if sound in ["hit","confirm"]:ui.hit_until=Time.get_ticks_msec()+180
func announce(message:String):
	announcement.rpc(message)
@rpc("authority","call_local","reliable",0)
func announcement(message:String):ui.notice(message)
@rpc("authority","call_local","unreliable",2)
func effect(kind:String,from:Vector3,to:Vector3,owner:int,shot_at:float=-100.):
	if dedicated:return
	if kind=="shot" and is_instance_valid(kill_replay):kill_replay.record_shot(from,to,owner)
	var sound={"heal":"heal","flash":"flash","explosion":"explosion","deploy":"deploy","skill":"skill","smoke":"smoke"}.get(kind,"")
	if kind=="shot":sound="gun_"+(players[owner].primary if players[owner].slot==0 else players[owner].secondary) if players.has(owner) else "gun_a1"
	if kind!="heal" or clock-float(heal_sound_times.get(owner,-100))>.22:
		if not sound.is_empty():play_sound(sound,from,owner!=local_id)
		if kind=="heal":heal_sound_times[owner]=clock
	if kind in ["shot","heal"] and arena:
		if owner==local_id and actors.has(owner) and players[owner].alive and players[owner].slot<2:from=actors[owner].visual_muzzle()
		combat_fx.beam(from,to,kind=="heal")
	elif arena and kind=="throw":combat_fx.throw_item(from,to)
	elif arena:
		var color=Color("78e1cb") if players.has(owner) and players[owner].team==0 else Color("ffd190")
		combat_fx.burst(kind,from,color)
	if actors.has(owner) and kind=="shot":actors[owner].show_shot(shot_at if shot_at> -100 else clock)
func play_sound(kind:String,pos:Vector3,spatial:bool):
	if dedicated or demo_mode or not is_instance_valid(audio_bank):return
	audio_bank.play(kind,pos,spatial)
@rpc("authority","call_local","unreliable",2)
func step_sound(pos:Vector3,id:int,surface:String,variant:int,gain:float):
	if dedicated or demo_mode:return
	audio_bank.play("step_"+surface+"_"+str(variant%4),pos,id!=local_id,gain)
@rpc("authority","call_local","unreliable",2)
func impact(pos:Vector3,push:Vector3,eliminated:bool,team:int,role:int=0,variant:int=0,facing:float=0.,crouched:bool=false):
	if dedicated or arena==null:return
	if eliminated:
		var model=combat_fx.group(pos)
		var body=CharacterVisual.new();model.add_child(body);body.build(role,team)
		var local_push=Basis(Vector3.UP,-facing)*push
		var fall_index=(3 if local_push.x>0 else 2) if absf(local_push.x)>absf(local_push.z) else (0 if local_push.z>0 else 1)
		body.animator.play(["fall_back","fall_front","fall_left","fall_right","fall_fold"][fall_index]);model.rotation.y=facing
		var pose=model.create_tween();pose.tween_method(func(t):
			if is_instance_valid(body):body.animator.seek(t,true),.12 if crouched else 0.,.9,.78 if crouched else .9)
		var flat=Vector3(push.x,0,push.z).normalized();var distance=1.1 if crouched else 1.5+variant*.22
		var end=pos+flat*distance
		var obstruction=ray(pos+Vector3.UP*.55,end+Vector3.UP*.55,[],1|4)
		if not obstruction.is_empty():end=obstruction.position+obstruction.normal*.45-Vector3.UP*.55
		end.y=pos.y
		var move=model.create_tween();move.tween_method(func(t):
			if is_instance_valid(model):model.position=pos.lerp(end,1.-pow(1.-t,2))+Vector3.UP*sin(t*PI)*(.12 if crouched else .28),0.,1.,.55)
		var lifetime=model.create_tween();lifetime.tween_interval(5.0);lifetime.tween_property(model,"scale",Vector3.ONE*.001,.5);lifetime.tween_callback(model.queue_free)
	else:
		combat_fx.armor_impact(pos,push,Color("79d9ff") if team==0 else Color("ffd07a"))
		var floor_hit=ray(pos,pos-Vector3.UP*4,[],1)
		if not floor_hit.is_empty() and floor_hit.normal.y>.65:combat_fx.scuff(floor_hit.position+Vector3.UP*.012)

@rpc("authority","call_local","reliable",2)
func damage_notice(target:int,origin:Vector3,amount:float,armored:bool):
	if dedicated or target!=local_id or not actors.has(target):return
	var direction=origin-actors[target].position
	ui.damage_indicator.register_hit(direction,amount,Time.get_ticks_msec()/1000.)
	var now=Time.get_ticks_msec()/1000.
	if now-last_hurt_sound>.075:play_sound("armor_hurt" if armored else "hurt",Vector3.ZERO,false);last_hurt_sound=now

func cycle_spectator():
	if not players.has(local_id) or players[local_id].alive:return
	var ids=[]
	for id in players:
		if id!=local_id and players[id].alive and (int(options.mode)==1 or players[id].team==players[local_id].team):ids.append(id)
	if ids.is_empty():spectator_target=0;return
	spectator_target=ids[(ids.find(spectator_target)+1)%ids.size()]
func update_spectator():
	if dedicated or not players.has(local_id) or not is_instance_valid(spectator_camera):return
	var local_actor=actors[local_id]
	if players[local_id].alive:
		local_actor.camera.current=true;return
	if not players.has(spectator_target) or not players[spectator_target].alive:cycle_spectator()
	var focus=actors[spectator_target].eye() if actors.has(spectator_target) else local_actor.eye()
	var facing=Basis(Vector3.UP,spectator_yaw)*Basis(Vector3.RIGHT,spectator_pitch)*Vector3.FORWARD
	var desired=focus-facing*3+Vector3.UP*.5
	var obstruction=ray(focus,desired,[],1|4)
	if not obstruction.is_empty():desired=obstruction.position+obstruction.normal*.2
	spectator_camera.global_position=desired;spectator_camera.rotation=Vector3(spectator_pitch,spectator_yaw,0);spectator_camera.current=true
@rpc("authority","call_local","unreliable",2)
func hit_reaction(id:int,push:Vector3):
	if actors.has(id):actors[id].react_hit(push)

@rpc("authority","call_local","unreliable",2)
func wall_mark(pos:Vector3,normal:Vector3):
	if dedicated or arena==null:return
	var mark=MeshInstance3D.new();var mesh=PlaneMesh.new();mesh.size=Vector2(.085,.085);mark.mesh=mesh
	var material=StandardMaterial3D.new();material.albedo_color=Color("3a4040");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mark.material_override=material
	add_child(mark);mark.position=pos+normal*.009;mark.quaternion=Quaternion(Vector3.UP,normal.normalized());wall_marks.append(mark)
	if wall_marks.size()>100:
		var first=wall_marks.pop_front()
		if is_instance_valid(first):first.queue_free()
