extends Node3D
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/catalog.gd")
const A=preload("res://scripts/actor.gd")
const W=preload("res://scripts/arena.gd")
const UI=preload("res://scripts/ui.gd")
var demo_mode=false
var demo_map=7
var render_actors=DisplayServer.get_name()!="headless"
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
var grenades=[]
var rockets=[]
var placement_preview:DeploymentPreview
var next_grenade=1
const DROP_LIFETIME=180.0
const MAX_DROPS=96
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
var direction_taps={}
var last_shift_ms=-1000
var preview:Node3D
var round_no=0
var completed_games=0
var overtime_attacker=0
var capture_team=-1
var capture_elapsed=0.
var result={"team":-1,"player":0}
var control_leg=0
var next_device=1
var zone_owner=[-1,-1,-1]
var zone_capture=[0.0,0.0,0.0]
var zone_counts=[[0,0],[0,0],[0,0]]
var bomb={"planted":false,"site":-1,"time":0.0,"actor":0,"progress":0.0,"position":Vector3.ZERO}
var server=false
var dedicated=false
var local_id=1
var profile={"nick":"Player%04d"%randi_range(0,9999),"token":"","sensitivity":.0023,"ads_sensitivity":.75,"sniper_mouse_sensitivity":.75,"sniper_touch_sensitivity":.65,"scope_zoom":{},"volume":.65,"window":true,"resolution":0,"monitor":0,"display_mode":-1,"width":0,"height":0,"ui_volume":.75,"hit_volume":.85,"gunfire_reduction":false,"lobby_url":"","graphics_auto":true,"graphics_quality":1,"antialias":0,"shadow_quality":0,"decor_quality":1,"frame_limit":60,"lighting_quality":1,"physics_effects":1,"corpse_quality":1,"fog_enabled":false,"menu_animation":true,"visual_revision":0,"display_revision":0,"hud_scale":.8,"hud_opacity":.38,"performance_revision":0,"mobile_initialized":false,"touch_sensitivity":.0028,"touch_aim_assist":true,"touch_auto_fire":false,"web_render_scale":1.,"web_quality":-1,"web_options":{}}
var bot_start_loadout={}
var pending_loadout={"role":0,"primary":"a1","secondary":"pistol","armor":0,"team":-1,"gadget":0}
var snapshot_timer=0.0
var input_timer=0.0
var web_hud_timer=0.0
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
var web_pointer_active=false
var last_server_ip=""
var connection_busy=false
var connection_deadline=0
var peer_activity={}
var pending_peers={}
var full_sync_timer=0.
var room_search_active=false
var room_search_timer=0.
var room_search_sent=0
var connection_notice=false
var public_room:PublicRoom
var internet:InternetLobby
var rtc:RtcTransport
var touch:TouchControls
var web_graphics:WebGraphics
var native_graphics:NativeGraphics
var join_ticket=""
func _ready():
	if not demo_mode and not OS.has_feature("web") and DisplayServer.get_name()!="headless":
		get_window().focus_exited.connect(func():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE)
		get_window().focus_entered.connect(func():call_deferred("restore_native_pointer"))
	if demo_mode:
		start_demo();return
	profile.blood_effects=false
	C.load_all();load_profile()
	if not TouchControls.supported():profile.touch_aim_assist=false;profile.touch_auto_fire=false
	if str(profile.lobby_url).is_empty():
		var defaults=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lobby_defaults.json"))
		if defaults is Dictionary:profile.lobby_url=str(defaults.get("url",""))
	if TouchControls.supported() and not profile.get("mobile_initialized",false):
		profile.merge({"mobile_initialized":true,"graphics_quality":0,"shadow_quality":0,"decor_quality":0,"antialias":0,"frame_limit":60,"width":1280,"height":720},true)
	if int(profile.performance_revision)<2:
		if int(profile.graphics_quality)!=3:profile.merge({"graphics_quality":0 if TouchControls.supported() else 1,"shadow_quality":0,"decor_quality":0 if TouchControls.supported() else 1,"antialias":0},true)
		profile.performance_revision=2
	if not OS.has_feature("web") and int(profile.visual_revision)<115:
		profile.menu_animation=true
		if int(profile.graphics_quality)!=3:profile.merge(GraphicsOptions.PRESETS[clampi(int(profile.graphics_quality),0,2)],true)
		profile.visual_revision=115
	if not OS.has_feature("web") and int(profile.get("map_quality_revision",0))<126:
		if int(profile.graphics_quality)!=3:profile.merge(GraphicsOptions.PRESETS[clampi(int(profile.graphics_quality),0,2)],true)
		profile.map_quality_revision=126
	if OS.has_feature("web"):
		web_graphics=WebGraphics.new();web_graphics.game=self;add_child(web_graphics)
		var pointer=WebPointer.new();pointer.game=self;add_child(pointer)
	else:
		native_graphics=NativeGraphics.new();native_graphics.game=self;add_child(native_graphics)
	if not OS.has_feature("web") and int(profile.display_revision)<115 and DisplayServer.get_name()!="headless":
		profile.monitor=DisplayServer.window_get_current_screen()
		var native_size=DisplayServer.screen_get_size(int(profile.monitor))
		profile.width=native_size.x;profile.height=native_size.y;profile.display_mode=1;profile.window=false
		profile.graphics_quality=1;profile.merge(GraphicsOptions.PRESETS[1],true);profile.display_revision=115
	setup_input();apply_display_settings()
	if OS.has_feature("web"):get_viewport().size_changed.connect(apply_display_settings)
	GraphicsOptions.apply(self)
	internet=InternetLobby.new();internet.game=self;add_child(internet)
	rtc=RtcTransport.new();rtc.game=self;add_child(rtc)
	public_room=PublicRoom.new();add_child(public_room)
	combat_fx=CombatFX.new();add_child(combat_fx)
	audio_bank=GameAudio.new();add_child(audio_bank);audio_bank.profile=profile
	version_check=VersionCheck.new();add_child(version_check)
	ui=UI.new();ui.game=self;add_child(ui);ui.menu();save_profile()
	var diagnostics=StabilityMonitor.new();diagnostics.game=self;add_child(diagnostics)
	placement_preview=DeploymentPreview.new();placement_preview.game=self;add_child(placement_preview)
	if TouchControls.supported():
		touch=TouchControls.new();touch.game=self;ui.root.add_child(touch)
	if DisplayServer.get_name()!="headless":kill_replay=KillReplay.new();kill_replay.game=self;add_child(kill_replay)
	if render_actors:
		var warmup=VisualWarmup.new();warmup.game=self;add_child(warmup)
	version_check.changed.connect(func():ui.update_version_badge())
	if DisplayServer.get_name()!="headless" and not "--no-update-check" in OS.get_cmdline_user_args():version_check.call_deferred("check")
	multiplayer.peer_disconnected.connect(disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(func():leave_game("서버에 연결하지 못했습니다. IP·방화벽을 확인하고 다시 접속하세요."))
	multiplayer.peer_connected.connect(peer_opened)
	multiplayer.server_disconnected.connect(func():leave_game("서버 연결이 종료되었습니다."))
	cli_args=OS.get_cmdline_user_args()
	if OS.get_name()=="Windows" and DisplayServer.get_name()!="headless" and not "--no-save-profile" in cli_args:
		var startup_access=StartupNetworkAccess.new();add_child(startup_access);startup_access.begin()
	if "--public-room" in cli_args:
		public_room.configure(self)
		if not public_room.enabled:push_error("Missing public room configuration");get_tree().quit(2);return
	for s in cli_args:
		if s.begins_with("--nick="):profile.nick=s.trim_prefix("--nick=");profile.token=profile.nick.sha256_text()
	if "--server" in cli_args:
		dedicated=true;options.bots=4 if "--training" in cli_args else 0;host_game()
		if "--auto-start" in cli_args:start_match()
	elif "--practice" in cli_args:
		PracticeSession.start(self)
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
	if str(profile.nick).strip_edges() in ["","Player"]:profile.nick="Player%04d"%randi_range(0,9999)
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
	if OS.has_feature("web"):
		var viewport=get_tree().root;viewport.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;viewport.content_scale_size=Vector2i.ZERO
		# A saved desktop/mobile 720p preference must not blur a larger browser.
		viewport.scaling_3d_scale=WebGraphics.render_scale(profile,web_graphics.scale_3d if is_instance_valid(web_graphics) else 1.)
		return
	var monitor=clampi(int(profile.monitor),0,maxi(0,DisplayServer.get_screen_count()-1))
	profile.monitor=monitor
	if int(profile.display_mode)<0:profile.display_mode=0 if profile.window else 1
	var mode=clampi(int(profile.display_mode),0,2)
	profile.window=mode==0
	var size=display_window_size()
	var native=DisplayServer.screen_get_size(monitor)
	size=Vector2i(clampi(size.x,640,maxi(640,native.x)),clampi(size.y,360,maxi(360,native.y)))
	profile.width=size.x;profile.height=size.y
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
	# Keep text/HUD at physical output resolution. Only the 3D buffer scales.
	var window=get_tree().root
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size=Vector2i.ZERO;window.content_scale_factor=1.
	var output=DisplayServer.window_get_size()
	window.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	window.scaling_3d_scale=clampf(minf(float(size.x)/maxi(1,output.x),float(size.y)/maxi(1,output.y)),.25,1.)
func display_window_size() -> Vector2i:
	var legacy=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)][clampi(int(profile.resolution),0,2)]
	return Vector2i(maxi(640,int(profile.width)),maxi(360,int(profile.height))) if int(profile.width)>0 and int(profile.height)>0 else legacy
func start_demo():
	C.load_all();server=true;local_id=0
	combat_fx=CombatFX.new();add_child(combat_fx)
	audio_bank=GameAudio.new();add_child(audio_bank);audio_bank.profile=profile
	ui=UI.new();ui.game=self;add_child(ui);ui.hide()
	options.map=demo_map;options.bots=6;options.mode=0;options.minutes=60;options.target=9999
	phase="lobby";build_world()
	for i in range(1,7):add_player(-i,"DEMO %d"%i,"menu_demo_%d"%i)
	phase="combat";remaining=3600.
	for id in players:players[id].protect=0.;players[id].fire_ready=0.
	set_process_unhandled_input(false)
func restore_native_pointer():
	if demo_mode or not is_inside_tree() or not get_window().has_focus():return
	capture_pointer()
func pointer_needs_visibility() -> bool:
	if phase in ["menu","lobby","result"] or not get_window().has_focus():return true
	if not is_instance_valid(ui):return true
	if is_instance_valid(ui.panel) or is_instance_valid(ui.map_viewer):return true
	if is_instance_valid(ui.scoreboard) and ui.scoreboard.visible:return true
	for window in ui.root.find_children("*","Window",true,false):
		if window.visible:return true
	return is_instance_valid(touch)
func capture_pointer(from_input_event:bool=false):
	# The background match shares the native Window and global Input singleton.
	# It must never capture or release the real player's mouse.
	if demo_mode:return
	if pointer_needs_visibility():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;return
	# Menus and dialogs always own a visible pointer, including respawn/focus callbacks.
	if phase in ["menu","lobby","result"] or (not OS.has_feature("web") and not get_window().has_focus()):Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;return
	if is_instance_valid(ui) and (is_instance_valid(ui.panel) or is_instance_valid(ui.map_viewer) or is_instance_valid(ui.navigation_confirm)):
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;return
	if is_instance_valid(ui) and is_instance_valid(ui.scoreboard) and ui.scoreboard.pinned:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;return
	if is_instance_valid(touch):Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;return
	# Browser capture must originate in an active input callback, not an RPC,
	# respawn timer or scene-load completion callback.
	if OS.has_feature("web") and not from_input_event:
		web_pointer_active=false
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		if is_instance_valid(ui):ui.notice("화면을 클릭하면 조준이 시작됩니다.")
		return
	# Escape/Alt-Tab can release the DOM lock independently of Godot's cached mode.
	# Reset it inside this user gesture so the engine issues a fresh request.
	if OS.has_feature("web") and not web_pointer_active:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func pointer_input_active() -> bool:
	return not is_instance_valid(ui.map_viewer) and not (is_instance_valid(ui.scoreboard) and ui.scoreboard.pinned) and not Input.is_action_pressed("score") and not is_instance_valid(ui.panel) and (web_pointer_active if OS.has_feature("web") else Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
func setup_input():
	var binds={"left":KEY_A,"right":KEY_D,"forward":KEY_W,"back":KEY_S,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"jump":KEY_SPACE,"reload":KEY_R,"use":KEY_E,"skill":KEY_F,"gadget":KEY_G,"gear":KEY_B,"score":KEY_TAB,"primary":KEY_1,"secondary":KEY_2,"medical":KEY_C,"melee":KEY_Q,"item5":KEY_5,"gadget_mode":KEY_V,"item3":KEY_3,"item4":KEY_4}
	for k in binds:
		if not InputMap.has_action(k):InputMap.add_action(k)
		var ev=InputEventKey.new();ev.physical_keycode=binds[k];InputMap.action_add_event(k,ev)
	for pair in [["left",KEY_LEFT],["right",KEY_RIGHT],["forward",KEY_UP],["back",KEY_DOWN]]:
		var ev=InputEventKey.new();ev.physical_keycode=pair[1];InputMap.action_add_event(pair[0],ev)
func build_world():
	if render_actors and not dedicated:CombatFX.prepare_devices();Construction.prepare(self)
	if is_instance_valid(kill_replay):kill_replay.reset()
	if arena:remove_child(arena);arena.queue_free()
	arena=W.new();arena.props_authoritative=server or demo_mode;add_child(arena);arena.build(int(options.map))
	var markers=ObjectiveMarkers.new();arena.add_child(markers);markers.setup(self)
	bot_navigation=BotNavigation.new();bot_navigation.build(arena);bot_agents.clear()
	if not is_instance_valid(spectator_camera):
		spectator_camera=Camera3D.new();spectator_camera.near=.1;spectator_camera.far=350;add_child(spectator_camera)
func start_bot_match(selection:Dictionary):
	bot_start_loadout=selection.duplicate(true)
	host_game(OfflineMultiplayerPeer.new())
	bot_start_loadout.clear()
	if phase=="lobby":start_match()
func host_game(transport:MultiplayerPeer=null):
	if phase!="menu" or connection_busy:return
	R.sanitize_room(options)
	if options.get("map_random",false):options.map=R.random_map(options)
	reset_transport_state();stop_room_search()
	var peer:MultiplayerPeer;var err:int;var port=R.PORT
	if transport!=null:peer=transport;err=OK
	elif OS.has_feature("web"):peer=OfflineMultiplayerPeer.new();err=OK
	elif is_instance_valid(public_room) and public_room.enabled:
		port=int(public_room.config.port);peer=WebSocketMultiplayerPeer.new();peer.handshake_timeout=5.;peer.max_queued_packets=256;err=peer.create_server(port)
	else:peer=ENetMultiplayerPeer.new();err=peer.create_server(port,32,4)
	if err!=OK:ui.notice("방을 만들 수 없습니다. 다른 서버가 실행 중인지 확인하세요. 코드 "+str(err));return
	multiplayer.multiplayer_peer=peer;multiplayer.server_relay=false;server=true;local_id=1;phase="lobby";public_serial=0;banned_tokens.clear();vote.clear();vote_cooldowns.clear();build_world()
	if transport==null and not OS.has_feature("web") and not (is_instance_valid(public_room) and public_room.enabled):
		discovery=PacketPeerUDP.new();discovery.set_broadcast_enabled(true)
		if discovery.bind(R.DISCOVERY)!=OK:discovery=null
	if not dedicated:
		add_player(1,profile.nick,profile.token)
		if not bot_start_loadout.is_empty():commit_loadout(1,bot_start_loadout)
	for i in range(mini(int(options.bots),int(options.max_players)-(0 if dedicated else 1))):add_player(-i-1,"BOT %02d"%(i+1),"bot"+str(i))
	TeamBalance.reconcile(self)
	ui.lobby();broadcast_state(true);print("SERVER_READY port=",port)
func reset_transport_state():
	received_sequence=-1;snapshot_sequence=0;snapshot_buffers.clear();received_parts.clear();expected_parts=0;incoming_at.clear();peer_activity.clear();pending_peers.clear();snapshot_timer=0.;input_timer=0.;ping_timer=0.;ping_ms=0;full_sync_timer=0.;connection_busy=false;connection_notice=false;last_snapshot_ms=Time.get_ticks_msec();session_started=last_snapshot_ms
func peer_opened(id:int):
	if server and multiplayer.get_peers().size()>int(options.max_players)+4:multiplayer.multiplayer_peer.disconnect_peer(id);return
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
	var peer:MultiplayerPeer;var err:int
	if last_server_ip.begins_with("wss://") or last_server_ip.begins_with("ws://127.0.0.1:"):
		peer=WebSocketMultiplayerPeer.new();peer.handshake_timeout=10.;peer.max_queued_packets=512;err=peer.create_client(last_server_ip)
	else:
		join_ticket="";peer=ENetMultiplayerPeer.new();err=peer.create_client(last_server_ip,R.PORT,4)
	if err!=OK:ui.notice("연결을 시작할 수 없습니다. IP를 확인하세요.");return
	multiplayer.multiplayer_peer=peer;server=false;connection_busy=true;connection_deadline=Time.get_ticks_msec()+15000;ui.notice("서버에 연결 중… 취소하거나 다시 시도할 수 있습니다.")
func connected():
	local_id=multiplayer.get_unique_id();peer_opened(1)
	if is_instance_valid(rtc) and rtc.active:
		register.rpc_id(1,profile.nick,rtc.local_uid,options.password,R.VERSION,"");return
	# Public admission uses its signed identity; do not disclose the persistent LAN token.
	register.rpc_id(1,profile.nick,"" if not join_ticket.is_empty() else profile.token,"" if not join_ticket.is_empty() else options.password,R.VERSION,join_ticket);join_ticket=""
func begin_rtc_client(peer:WebRTCMultiplayerPeer):
	reset_transport_state();stop_room_search();multiplayer.multiplayer_peer=peer;multiplayer.server_relay=false
	server=false;connection_busy=true;connection_deadline=Time.get_ticks_msec()+25000
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
func register(nick:String,token:String,password:String,version:String,ticket:String=""):
	if not server or nick.length()>80 or password.length()>128 or version.length()>32:return
	var id=multiplayer.get_remote_sender_id()
	if players.has(id):return
	if not rate_limit(id,"register",.5):return
	var claims={}
	if is_instance_valid(rtc) and rtc.active:
		if not rtc.identities.has(id):reject.rpc_id(id,"로비에서 인증한 참가자가 아닙니다.");return
		token=str(rtc.identities[id].uid);nick=str(rtc.identities[id].nick)
	if is_instance_valid(public_room) and public_room.enabled:
		claims=public_room.verify(ticket)
		if claims.is_empty():reject.rpc_id(id,"입장권이 만료되었거나 유효하지 않습니다. 로비에서 다시 참가하세요.");return
		token=str(claims.uid);nick=str(claims.nick)
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
	# A person always takes a bot's seat: balance/replacement bots first, then
	# any bot when the room is full. Only a room of people rejects the join.
	var seat_team=TeamBalance.admit(self)
	if seat_team<0:reject.rpc_id(id,"방이 가득 찼습니다.");return
	add_player(id,nick.left(20),token,seat_team);peer_activity[id]=Time.get_ticks_msec();pending_peers.erase(id)
	if not claims.is_empty():public_room.accepted(id,claims);options.room_owner=public_room.owner_peer
	TeamBalance.reconcile(self)
	configure.rpc_id(id,public_options());broadcast_state(true,id)
	announce(players[id].nick+"님이 입장했습니다.")
	print("JOIN ",id," count=",players.size())
@rpc("authority","call_remote","reliable",0)
func reject(message:String):
	leave_game(message)
func public_options() -> Dictionary:
	var d=options.duplicate();d.erase("password");return d
@rpc("authority","call_remote","reliable",0)
func configure(opts:Dictionary):
	var saved_password=str(options.get("password",""));options=R.default_options();options.merge(opts,true);options.password=saved_password;connection_busy=false;received_sequence=-1;snapshot_buffers.clear();last_snapshot_ms=Time.get_ticks_msec();build_world();phase="lobby";ui.lobby()
	last_snapshot_ms=Time.get_ticks_msec()
func add_player(id:int,nick:String,token:String,team:int=-1):
	prune_reconnects()
	var t=0;var counts=[0,0]
	for p in players.values():
		if not p.get("auto_balance",false):counts[p.team]+=1
	t=randi()%2 if counts[0]==counts[1] else 0 if counts[0]<counts[1] else 1
	if team in [0,1]:t=team
	var role=0 if id>0 or not options.classes else absi(id)%6
	if role==5 and medic_count(t)>=R.medic_cap(counts[t]+1):role=0
	var p={"id":id,"nick":nick,"token":token,"team":t,"role":role,"primary":C.first(role),"secondary":R.SECONDARIES[role],"slot":0,"hp":R.CLASS_HP[role],"armor":0.,"armor_max":0,"alive":false,"kills":0,"match_kills":0,"deaths":0,"assists":0,"objective":0,"healed":0.,"builds":0,"played":0.,"cash":800,"lives":int(options.lives),"respawn":0.,"mag":{},"reserve":{},"reload":0.,"reload_weapon":"","fire_ready":0.,"heal_ready":0.,"heal_mag":3,"heal_reserve":3,"energy":180.,"repair_energy":100.,"skill_ready":clock+30. if role==5 else 0.,"initial_skill_until":clock+30.,"gadget_count":1,"gadget":0,"protect":0.,"shield":0.,"slow":0.,"dash":0.,"mark":0.,"flash":0.,"last_hit":-20.,"contributors":{},"input_time":clock,"gadget_ready":0.,"last_pos":Vector3.ZERO,"spectator":false,"round_bonus":0,"can_respawn":true,"smoke":2,"flash_count":1}
	if int(options.mode)==4:DefusalEconomy.reset(p,int(options.starting_cash))
	if reconnects.has(token):
		p=reconnects[token].duplicate(true);p.id=id;p.nick=nick;p.alive=false;p.respawn=clock+3;reconnects.erase(token)
		if team in [0,1]:p.team=team
	elif phase!="lobby":
		p.spectator=int(options.join)==1
		p.alive=false;p.respawn=clock+3 if int(options.join)==2 and int(options.mode)!=4 else 1e12
	p.bloom=0.;p.shot_time=-100.;p.spray_index=0;p.spray_phase=0.;p.bot_action=""
	p.pending_loadout={};p.trigger_seen=0;p.fire_prev=false;p.burst_left=0;p.trigger_until=0.;p.reload_started=0.;p.switch_until=0.
	if id<0 and p.role==3 and int(options.mode)!=4:p.secondary="repair"
	if not p.has("number"):public_serial+=1;p.number=public_serial
	p.base_nick=nick.strip_edges().replace("\n"," ").replace("\r"," ").left(20)
	if p.base_nick.is_empty():p.base_nick="Player"
	p.nick=p.base_nick+" #%02d"%int(p.number) if id>0 else p.base_nick
	players[id]=p;ensure_actor(id);equip_ammo(p)
	if phase=="lobby":spawn(id)
	if id<0:
		var brain=BotAgent.new();brain.setup(self,id);bot_agents[id]=brain;p.bot_difficulty=brain.difficulty
func ensure_actor(id:int):
	if actors.has(id):return
	var a=A.new();a.pid=id;a.game=self;a.name="Player_"+str(id);add_child(a);actors[id]=a;a.set_local(id==local_id and not dedicated);a.set_team(int(players[id].team));a.target_pos=Vector3.ZERO
func equip_ammo(p:Dictionary):
	WeaponRules.enforce(options,p)
	for id in [p.primary,p.secondary]:
		if str(id).is_empty():continue
		var w=C.get_weapon(id);p.mag[id]=int(w.mag);p.reserve[id]=int(w.reserve)
func spawn(id:int):
	BotSettings.apply_role(self,id)
	players[id].use_prev=false
	var p=players[id];var a=actors[id]
	p.gadget_ready=0.;p.marker_progress=0.;p.marker_target=0;p.marker_scan=0.
	if not p.get("pending_loadout",{}).is_empty():
		var requested=p.pending_loadout.duplicate();p.pending_loadout={};commit_loadout(id,requested)
	var best=choose_spawn(id)
	var armor_before=float(p.armor)
	a.collision_layer=2;a.position=best;a.target_pos=best;a.velocity=Vector3.ZERO;p.alive=true;p.plate=0.;p.laser_heat=0.;p.laser_lock=0.;p.laser_firing=false;p.laser_dt=0.;p.cooking=0;p.slide_until=0.;p.hp=R.max_hp(p);p.armor=p.armor_max;p.reload=0.;p.protect=clock+R.SPAWN_PROTECTION;p.energy=180.;p.heal_mag=3;p.heal_reserve=3;p.repair_energy=100.;p.last_hit=clock;p.contributors={};p.spectator=false
	if int(options.mode)==4:p.armor=armor_before
	else:p.owned_primary=true;p.owned_secondary=true;p.owned_gadget=true;GadgetLoadout.reset(p)
	p.placing="";p.invul_select=0.;p.invulnerable=0.;p.dash=0.;p.dash_recovery=0.;p.shield=0.;p.slow=0.;p.mark=0.;p.reveal_to={}
	# 1.4.2: only bots are sometimes left-handed (variety in third person); a
	# player's own hands no longer swap sides from one life to the next.
	p.hand=(-1 if randf()<.12 else 1) if id<0 else 1
	a.reset_view((0. if p.team==MatchFlow.attackers(self) else PI) if int(options.mode)==4 and DefusalLayout.enabled(int(options.map)) else 0. if options.get("practice",false) and id==1 else 0. if p.team==1 else PI);p.fire_ready=clock+.3;p.burst_left=0;p.fire_prev=false;p.trigger_until=0.;p.trigger_seen=int(a.input_state.get("trigger_seq",0));p.slot=0 if p.get("owned_primary",true) else 1;p.link_target=0;p.link_fx_ready=0.;p.melee_started=-100.;p.melee_ready=0.;p.melee_step=MeleeCombat.STEPS;p.step_distance=0.;p.step_index=0;p.gait=0.;p.bloom=0.;p.spray_index=0;p.spray_phase=0.;p.shot_time=-100.;p.switch_until=clock+.3;equip_ammo(p)
	if bot_agents.has(id):bot_agents[id].reset_after_spawn()
	if id==local_id:capture_pointer()
func choose_spawn(id:int) -> Vector3:
	if options.get("practice",false):return PracticeSession.spawn_point(id)
	var p=players[id];var spawn_team=(0 if int(p.team)==MatchFlow.attackers(self) else 1) if int(options.mode)==4 and DefusalLayout.enabled(int(options.map)) else (int(p.team)+control_leg)%2 if int(options.mode)==3 else int(p.team);var pts=arena.spawn_candidates(spawn_team,int(options.mode)==1)
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
func can_attack(p:Dictionary) -> bool:return not (int(options.mode)==4 and phase=="buy") and p.alive and Rules.attack_blocked_until(p)<=clock and not BombLogic.busy(self,int(p.id))
func passive_regen(p:Dictionary,dt:float):
	if options.autoheal and p.alive and clock-maxf(p.last_hit,float(p.get("shot_time",-100.)))>=R.REGEN_DELAY:p.hp=minf(R.max_hp(p),p.hp+R.REGEN_RATE*dt)
func kick_player(requester:int,target:int,by_vote=false) -> bool:
	if not server or (not TeamBalance.host(self,requester) and not by_vote) or TeamBalance.host(self,target) or not players.has(target):return false
	if players[target].get("auto_balance",false):feedback(requester,"","균형 봇은 참가 인원에 맞춰 자동으로 관리됩니다.",true);return false
	var name=players[target].nick;var token=players[target].token
	if target>0:
		banned_tokens[token]=Time.get_ticks_msec()+180000
		if target in multiplayer.get_peers():
			reject.rpc_id(target,"투표로 강퇴되었습니다. 3분 뒤 다시 참가할 수 있습니다." if by_vote else "방장이 강퇴했습니다. 3분 뒤 다시 참가할 수 있습니다.")
			get_tree().create_timer(.25).timeout.connect(func():
				if server and target in multiplayer.get_peers():multiplayer.multiplayer_peer.disconnect_peer(target))
	disconnected(target,true);reconnects.erase(token);announce(name+" 강퇴");return true
func start_kick_vote(requester:int,target:int) -> bool:
	if not server or requester<=0 or target<=0 or TeamBalance.host(self,target) or requester==target or not players.has(requester) or not players.has(target) or not vote.is_empty():return false
	if Time.get_ticks_msec()<int(vote_cooldowns.get(requester,0)):return false
	var eligible=[]
	for id in players:
		if id>0 and id!=target:eligible.append(id)
	if eligible.size()<2:feedback(requester,"","강퇴 투표는 대상 외 참가자가 2명 이상 있어야 합니다.",true);return false
	vote={"target":target,"name":players[target].nick,"eligible":eligible,"votes":{requester:true},"needed":maxi(2,int(ceil(eligible.size()*.6))),"until":clock+15.}
	vote_cooldowns[requester]=Time.get_ticks_msec()+60000;announce(players[target].nick+" 강퇴 투표 · 숫자키 9 찬성 / 숫자키 0 반대");broadcast_state(true);return true
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
func disconnected(id:int,kicked=false):
	peer_activity.erase(id);pending_peers.erase(id)
	if not players.has(id):return
	if server and id>0 and not kicked:announce(players[id].nick+"님이 퇴장했습니다.")
	var departed=players[id].duplicate(true);var departed_pos:Vector3=actors[id].position if actors.has(id) else Vector3.ZERO
	if server:
		BombLogic.drop(self,id)
		var p=players[id];p.alive=false;prune_reconnects();reconnects[p.token]=p.duplicate(true);reconnects[p.token].disconnected_at=clock
		for did in devices.keys():
			if devices[did].owner==id:remove_device(did)
	players.erase(id);bot_agents.erase(id)
	if actors.has(id):actors[id].queue_free();actors.erase(id)
	if server:TeamBalance.replace_departed(self,departed,departed_pos);TeamBalance.reconcile(self);call_deferred("broadcast_state",true)
func prune_reconnects():
	for token in reconnects.keys():
		if clock-float(reconnects[token].get("disconnected_at",clock))>300.:reconnects.erase(token)
	while reconnects.size()>=64:reconnects.erase(reconnects.keys()[0])
func leave_game(message:String=""):
	if is_instance_valid(rtc):rtc.close()
	var return_to_lan=phase=="menu" and ui.screen=="join"
	if options.get("practice",false):options=R.default_options()
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
	device_nodes.clear();devices.clear();fields.clear();grenades.clear();rockets.clear();drops.clear();reconnects.clear()
	for node in drop_nodes.values():node.queue_free()
	drop_nodes.clear()
	for node in wall_marks:
		if is_instance_valid(node):node.queue_free()
	wall_marks.clear()
	if arena:arena.queue_free();arena=null
	if discovery:discovery.close();discovery=null
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if return_to_lan:ui.join_menu()
	else:ui.menu()
	ui.notice(message)
func search_rooms():
	if OS.has_feature("web"):return
	room_search_sent=Time.get_ticks_msec()
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
				discovery.set_dest_address(ip,port);discovery.put_packet(JSON.stringify({"game":"RelayStrike","name":options.room,"count":TeamBalance.humans(self),"bots":players.size()-TeamBalance.humans(self),"max":options.max_players,"mode":R.MODES[int(options.mode)],"version":R.VERSION,"locked":not str(options.get("password","")).is_empty()}).to_utf8_buffer())
	if browser:
		while browser.get_available_packet_count()>0:
			var raw=browser.get_packet();var ip=browser.get_packet_ip()
			if raw.size()>2048:continue
			var d=JSON.parse_string(raw.get_string_from_utf8())
			if d is Dictionary and d.get("game")=="RelayStrike":
				d.ping=maxi(0,Time.get_ticks_msec()-room_search_sent);rooms[ip]=d;ui.update_rooms()
func _input(event):
	if demo_mode:return
	if is_instance_valid(ui) and ui.menu_key(event):get_viewport().set_input_as_handled();return
	if not vote.is_empty() and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_9,KEY_0,KEY_KP_9,KEY_KP_0]:
		command("vote",{"yes":event.keycode in [KEY_9,KEY_KP_9]});get_viewport().set_input_as_handled()
func _unhandled_input(event):
	if is_instance_valid(ui.map_viewer):return
	if event.is_action("score") and not is_instance_valid(ui.panel):
		if event.is_pressed():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		else:capture_pointer(true)
		get_viewport().set_input_as_handled();return
	if is_instance_valid(touch) and (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):return
	if OS.has_feature("web") and not is_instance_valid(touch) and not is_instance_valid(ui.panel) and phase in ["buy","combat","round_end"] and not web_pointer_active:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			capture_pointer(true);get_viewport().set_input_as_handled();return
	if is_instance_valid(kill_replay) and kill_replay.active:
		if event.is_action_pressed("gear") and not event.is_echo() and int(options.mode)!=4:ui.gear()
		elif event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE,KEY_ESCAPE]:kill_replay.finish()
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if ui.screen=="settings" and ui.settings_exit.is_valid():ui.settings_exit.call();get_viewport().set_input_as_handled();return
		if phase!="menu":ui.toggle_pause();get_viewport().set_input_as_handled()
	if not actors.has(local_id) or not pointer_input_active():return
	var a=actors[local_id]
	if event is InputEventMouseMotion:
		if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and not (event.button_mask&(MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_RIGHT)):return
		var sensitivity=float(profile.sensitivity)*(float(profile.ads_sensitivity) if a.input_state.ads and players[local_id].alive else 1.)
		if SniperScope.active(self):sensitivity=float(profile.sensitivity)*SniperScope.sensitivity(self)
		if players[local_id].alive:
			a.input_state.yaw-=event.relative.x*sensitivity;a.input_state.pitch=clampf(a.input_state.pitch-event.relative.y*sensitivity,-1.45,1.45)
		else:
			spectator_yaw-=event.relative.x*sensitivity;spectator_pitch=clampf(spectator_pitch-event.relative.y*sensitivity,-1.2,1.2)
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and players[local_id].alive:
		trigger_seq+=1;a.input_state.trigger_seq=trigger_seq
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and players[local_id].alive:
		a.input_state.fire=event.pressed
		if players[local_id].slot==2 and GrenadeLogic.equipped(players[local_id]):command("trigger_press" if event.pressed else "trigger_release",{"seq":trigger_seq})
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and players[local_id].alive:
		if SniperScope.active(self):SniperScope.change(self,1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)
		else:cycle_weapon(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)
		get_viewport().set_input_as_handled()
	for index in range(3,6):
		if event.is_action_pressed("item"+str(index)):command("slot",{"slot":index-1})
	if event.is_action_pressed("sprint") and not event.is_echo():
		var stamp=Time.get_ticks_msec()
		if stamp-last_shift_ms<=R.SLIDE_TAP_MS:command("slide",{"forward":Vector2(a.velocity.x,a.velocity.z).length()<.5});last_shift_ms=-1000
		else:last_shift_ms=stamp
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_LEFT,KEY_DOWN,KEY_RIGHT]:
		var key={KEY_UP:KEY_W,KEY_LEFT:KEY_A,KEY_DOWN:KEY_S,KEY_RIGHT:KEY_D}.get(event.physical_keycode,event.physical_keycode);var stamp=Time.get_ticks_msec()
		if stamp-int(direction_taps.get(key,-2000))<=R.SLIDE_TAP_MS:
			var direction={KEY_W:Vector2(0,-1),KEY_A:Vector2(-1,0),KEY_S:Vector2(0,1),KEY_D:Vector2(1,0)}[key]
			command("slide",{"x":direction.x,"z":direction.y});direction_taps[key]=-2000
		else:direction_taps[key]=stamp
	if event.is_action_pressed("melee") and not event.is_echo():command("melee",{})
	if event.is_action_pressed("use") and not event.is_echo():command("bomb_tap",{})
	if event.is_action_pressed("reload"):command("reload",{})
	if event.is_action_pressed("primary"):command("slot",{"slot":0})
	if event.is_action_pressed("secondary"):command("slot",{"slot":1})
	if event.is_action_pressed("skill"):command("skill",{})
	if event.is_action_pressed("gadget"):command("gadget_press",{})
	if event.is_action_released("gadget"):command("gadget_release",{})
	if event.is_action_pressed("gear"):ui.gear()
	if event.is_action_pressed("gadget_mode"):command("gadget_mode",{})
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not players[local_id].alive:cycle_spectator()
func cycle_weapon(direction:int):
	var p=players[local_id];var available=[0,1]
	if options.classes and GadgetLoadout.selectable(p):available.append(2)
	if false:available.append(3)
	available.append(MeleeCombat.SLOT)
	available=available.filter(func(slot):return WeaponRules.allows_slot(options,int(slot)))
	command("slot",{"slot":available[posmod(available.find(int(p.slot))+direction,available.size())]})
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
	if not server or data.size()>20:return
	var id=multiplayer.get_remote_sender_id()
	if not players.has(id) or not rate_limit(id,"input",.015):return
	var a=actors[id]
	var normalized=InputGuard.normalize(data)
	if normalized.is_empty():return
	a.input_state=normalized
	players[id].input_time=clock;peer_activity[id]=Time.get_ticks_msec()
func collect_input():
	if not actors.has(local_id):return
	var a=actors[local_id];var on=(touch.active() if is_instance_valid(touch) else pointer_input_active()) and players[local_id].alive and not (is_instance_valid(kill_replay) and kill_replay.active)
	a.input_state.x=Input.get_axis("left","right") if on else 0.;a.input_state.z=Input.get_axis("forward","back") if on else 0.
	for k in ["sprint","crouch","jump","use"]:a.input_state[k]=on and Input.is_action_pressed(k)
	a.input_state.melee=on and Input.is_action_pressed("melee")
	a.input_state.ads=on and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT);a.input_state.fire=on and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT);a.input_state.alt=on and Input.is_action_pressed("medical")
	if is_instance_valid(touch):touch.apply_input(a,on)
	var w=current_weapon(players[local_id])
	a.input_state.scope_zoom=SniperScope.magnification(profile,w) if SniperScope.supported(w) else 4.
	if server:players[local_id].input_time=clock
	else:send_input.rpc_id(1,a.input_state)
func _physics_process(dt:float):
	if not demo_mode and not dedicated and not OS.has_feature("web") and pointer_needs_visibility() and Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	expire_web_marks()
	clock+=dt
	if is_instance_valid(kill_replay):kill_replay.capture(dt)
	if not demo_mode:network_discovery();connection_watchdog()
	if server:update_kick_vote()
	if room_search_active:
		room_search_timer-=dt
		if room_search_timer<=0:search_rooms()
	if phase=="menu":return
	var _t=Time.get_ticks_usec()
	input_timer-=dt
	if input_timer<=0:collect_input();input_timer=1./30
	if server:
		server_tick(dt)
		prof_add("server_tick",_t);_t=Time.get_ticks_usec()
		snapshot_timer-=dt
		full_sync_timer-=dt
		if snapshot_timer<=0 and not demo_mode:broadcast_state(full_sync_timer<=0);snapshot_timer=1./15
		if full_sync_timer<=0:full_sync_timer=3.
		prof_add("broadcast",_t);_t=Time.get_ticks_usec()
	else:
		if actors.has(local_id) and players[local_id].alive:
			AimModel.recover(players[local_id],current_weapon(players[local_id]),dt,clock)
			actors[local_id].simulate(dt,clock,phase in ["combat","lobby","buy"] and not BombLogic.busy(self,local_id))
			MatchFlow.preparation(self,local_id)
		ping_timer-=dt
		if ping_timer<=0:ping_request.rpc_id(1,Time.get_ticks_msec());ping_timer=1.
		prof_add("client_sim",_t);_t=Time.get_ticks_usec()
	if not render_actors:
		for id in actors:
			if players.has(id):actors[id].headless_pose(players[id])
		if not demo_mode:update_spectator()
	elif not is_physics_processing():render_update(dt)
	update_world_visuals(dt)
	prof_add("world_visual",_t)
func _process(dt:float):
	# Rendering work runs once per drawn frame. Catch-up physics steps after a
	# slow frame then only simulate, instead of re-posing every character and
	# rebuilding the HUD several times before the next image is shown.
	if phase=="menu" or not render_actors or not is_physics_processing():return
	render_update(dt)
func render_update(dt:float):
	var _t=Time.get_ticks_usec()
	for id in actors:
		if players.has(id):actors[id].visual(dt,players[id],clock)
	prof_add("actor_visual",_t);_t=Time.get_ticks_usec()
	if not demo_mode:
		update_spectator()
		web_hud_timer-=dt
		if not OS.has_feature("web") or web_hud_timer<=0:ui.refresh();web_hud_timer=1./20.
	prof_add("ui",_t)
var prof={}
var prof_enabled=OS.has_environment("INC_PROFILE")
func prof_add(key:String,start:int):
	if prof_enabled:prof[key]=int(prof.get(key,0))+Time.get_ticks_usec()-start
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
		if id<0:
			if options.get("practice",false):PracticeSession.input(self,id)
			else:bot_input(id,dt)
		elif clock-p.input_time> .5:
			a.input_state.x=0.;a.input_state.z=0.;a.input_state.fire=false;a.input_state.melee=false;a.input_state.alt=false;a.input_state.use=false
		if not p.alive:
			if phase=="combat" and clock>=p.respawn and not p.spectator and (int(options.mode) not in [2,4] or p.can_respawn):spawn(id)
			continue
		AimModel.recover(p,current_weapon(p),dt,clock)
		var before_move=a.position;var grounded_before=a.is_on_floor()
		var busy=BombLogic.busy(self,id)
		if busy:a.input_state.crouch=true;a.input_state.x=0.;a.input_state.z=0.;a.input_state.fire=false;a.input_state.jump=false;a.velocity.x=0.;a.velocity.z=0.
		a.simulate(dt,clock,phase in ["combat","lobby","buy"] and not busy)
		MatchFlow.preparation(self,id)
		p.gait=a.gait
		p.step_distance=float(p.get("step_distance",0))+(Vector2(a.position.x-before_move.x,a.position.z-before_move.z).length() if a.is_on_floor() else 0.)
		if a.is_on_floor() and int(floor(a.gait*2))>int(p.get("step_index",0)):
			p.step_index=int(floor(a.gait*2));p.step_variant=int(p.step_index)%4
			var surface="water" if arena.wading(a.position) else "metal" if absf(a.position.x)>72 and absf(a.position.z)<35 else "stone"
			if not a.input_state.crouch and float(p.get("slide_until",0))<=clock:step_sound.rpc(a.position,id,surface,p.step_variant,4. if a.last_sprint else 1.)
		if not a.input_state.crouch and ((grounded_before and not a.is_on_floor() and a.velocity.y>1.) or (not grounded_before and a.is_on_floor())):
			step_sound.rpc(a.position,id,"water" if arena.wading(a.position) else "stone",int(p.get("step_variant",0)),5.)
		if phase!="combat":continue
		p.played+=dt
		MarkerTracker.tick(self,id,dt)
		var held_weapon=current_weapon(p)
		ReloadAudio.tick(self,id);MagazineReload.tick(self,id)
		if p.reload>0 and clock>=p.reload:
			MagazineReload.finish(self,id)
		passive_regen(p,dt)
		if int(options.mode) in [0,1,3]:
			p.energy=minf(180,p.energy+dt*5)
		p.repair_energy=minf(100,p.repair_energy+dt*8 if not a.input_state.fire else p.repair_energy)
		MeleeCombat.tick(self,id)
		MedicLink.tick(self,id,dt)
		LaserCombat.tick(self,id,dt)
		process_trigger(id)
		if a.input_state.alt and p.role==5 and p.primary in ["m2","m3"] and p.slot==0:heal_burst(id)
		if a.input_state.use:interact(id,dt)
		p.use_prev=bool(a.input_state.use)
		p.last_pos=a.position
	update_devices(dt);update_fields(dt);update_pickups();GrenadeLogic.tick(self,dt)
	MatchFlow.update_gate(self)
	if options.get("practice",false):PracticeSession.tick(self);return
	if phase in ["buy","combat","result","round_end"]:
		remaining-=dt
		if phase=="buy" and remaining<=0:
			phase="combat";remaining=ModeOptions.seconds(options);announce("라운드 시작")
			bomb.buy_until=clock+clampf(float(options.get("buy_seconds",60)),0.,minf(300.,remaining))
			if not dedicated and ui.screen=="gear":ui.show_hud();capture_pointer()
			if round_no==1:
				for player in players.values():
					player.initial_skill_until=clock+30.
					if player.role==5:player.skill_ready=maxf(float(player.skill_ready),clock+30.)
		elif phase=="round_end" and remaining<=0:
			if MatchFlow.at_limit(self):MatchFlow.return_to_lobby(self)
			else:begin_round()
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
	if action not in ["bot_add","bot_remove","start","slot","reload","loadout","bot_settings","kick","vote_kick","vote","team","team_swap","team_policy","slide","skill","gadget","gadget_press","gadget_release","gadget_mode","melee","trigger_press","trigger_release","bomb_tap"] or data.size()>16:return
	for key in data:
		if not (key is String or key is StringName) or str(key).length()>32:return
		var value=data[key]
		if not (value is bool or value is int or value is float or value is String):return
		if value is String and value.length()>80:return
		if (value is float or value is int) and (not is_finite(float(value)) or absf(float(value))>100000):return
	if not players.has(id) or not rate_limit(id,"cmd_"+action,.08):return
	var p=players[id]
	match action:
		"bot_add":RosterControls.add_bot(self,id,int(data.get("team",0)))
		"bot_remove":RosterControls.remove_bot(self,id,int(data.get("target",0)))
		"start":
			if phase=="lobby" and (id==1 or (is_instance_valid(public_room) and public_room.enabled and public_room.can_start(id))):start_match()
		"slot":
			var slot=clampi(int(data.get("slot",0)),0,4)
			if not WeaponRules.allows_slot(options,slot):return
			if slot in [2,3] and not options.classes:return
			if slot==3 or (slot==2 and not GadgetLoadout.selectable(p)) or (slot==0 and not p.get("owned_primary",true)):return
			if MeleeCombat.active(p,clock):return
			if slot==p.slot:return
			GrenadeLogic.release(self,id)
			p.slot=slot;p.reload=0.;p.revolver_open=false;p.burst_left=0;p.trigger_until=0.;p.fire_ready=maxf(p.fire_ready,clock+.32);p.switch_until=clock+.32
			p.placing=""
			if slot==2 and p.role==3 and p.gadget in [0,1,2] and can_attack(p) and p.gadget_count>0 and clock>=p.gadget_ready:Deployment.begin(self,id,"cover")
			feedback(id,"switch","")
		"melee":MeleeCombat.begin(self,id)
		"reload":begin_reload(id)
		"loadout":apply_loadout(id,data)
		"bot_settings":BotSettings.change(self,id,data)
		"kick":kick_player(id,int(data.get("target",0)))
		"vote_kick":start_kick_vote(id,int(data.get("target",0)))
		"vote":cast_kick_vote(id,bool(data.get("yes",false)))
		"team":change_team(id,int(data.get("player_id",id)),int(data.get("team",0)))
		"team_swap":swap_teams(id,int(data.get("first",0)),int(data.get("second",0)))
		"team_policy":
			if not TeamBalance.host(self,id):return
			options.next_teams=clampi(int(data.get("next_teams",options.next_teams)),0,2);broadcast_state(true)
		"slide":begin_slide(id,bool(data.get("forward",false)),Vector2(float(data.get("x",0)),float(data.get("z",0))))
		"skill":use_skill(id)
		"gadget":use_gadget(id)
		"gadget_press":
			if MeleeCombat.active(p,clock):return
			if GrenadeLogic.equipped(p):GrenadeLogic.begin(self,id)
			else:use_gadget(id)
		"gadget_release":GrenadeLogic.release(self,id)
		"trigger_press":
			var seq=int(data.get("seq",0))
			if p.slot==2 and seq>int(p.get("grenade_click_seq",-1)):
				p.grenade_click_seq=seq;GrenadeLogic.begin(self,id,"direct")
		"trigger_release":GrenadeLogic.release(self,id)
		"bomb_tap":BombLogic.tap(self,id)
		"gadget_mode":
			pass # Only the selected loadout can be used; no mixed smoke/flash pack.
func change_team(requester:int,target:int,team:int) -> bool:
	var ok=TeamBalance.move(self,requester,target,team)
	if not ok:feedback(requester,"","본인 또는 방장이 관리하는 봇만 인원 균형을 유지하며 이동할 수 있습니다.",true)
	return ok
func swap_teams(requester:int,first:int,second:int) -> bool:
	if first==second or not players.has(first) or not players.has(second) or int(options.mode)==1:return false
	if not TeamBalance.allowed(self,requester,first) or not TeamBalance.allowed(self,requester,second):return false
	if players[first].team==players[second].team:return false
	if TeamBalance.host(self,requester):options.manual_roster=true;players[first].auto_balance=false;players[second].auto_balance=false
	var team=players[first].team;players[first].team=players[second].team;players[second].team=team
	finish_team_change(first);finish_team_change(second);TeamBalance.reconcile(self);enforce_medics();broadcast_state(true);return true
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
	if not ((int(options.mode)==4 or WeaponRules.mode(options)>0) and wid.is_empty()):
		if not C.weapons.has(wid) or C.get_weapon(wid).slot!=0:return false
		if options.classes and int(C.get_weapon(wid).role)!=role:return false
		if not options.classes and C.get_weapon(wid).kind!="gun":return false
	var secondary=str(d.get("secondary","repair" if role==3 and d.get("repair",false) else R.SECONDARIES[role]))
	if secondary not in C.secondaries_for(role):return false
	var allowed=[0,8]+([1] if role in [0,4] else [1,2] if role==3 else [])
	if int(options.mode)==4:allowed.append(-1);allowed.append(9)
	return int(d.get("gadget",p.gadget)) in allowed
func loadout_cost(p:Dictionary,d:Dictionary) -> int:
	return DefusalEconomy.cost(p,d) if int(options.mode)==4 else 0

func apply_loadout(id:int,d:Dictionary):
	d=WeaponRules.selection(options,d)
	var p=players[id]
	if bool(d.get("immediate",false)):
		if not RedeployRules.available(self,p):feedback(id,"","남은 부활 횟수가 없거나 지금은 즉시 적용할 수 없습니다.",true);return
		if RedeployRules.wait_seconds(self,p)>0.:feedback(id,"","즉시 적용은 %.1f초 후 다시 사용할 수 있습니다."%RedeployRules.wait_seconds(self,p),true);return
		if not d.get("redeploy_confirmed",false):feedback(id,"","사망 및 부활 횟수 소모를 먼저 확인하세요.",true);return
		if not valid_loadout(p,d):return
		# Purchases still require the team's spawn and an open buy window.
		if int(options.mode)==4 and not DefusalEconomy.can_buy(self,id):feedback(id,"","구매 시간 안에 팀 시작 위치에서 변경할 수 있습니다.",true);return
		p.redeploy_ready=clock+RedeployRules.COOLDOWN;p.protect=0.;p.invulnerable=0.;p.pending_loadout={}
		damage(id,100000.,id,false,"redeploy")
		if int(options.mode)==0 and not options.get("practice",false):scores[1-int(p.team)]+=1
		spawn(id)
		var chosen=d.duplicate();chosen.erase("immediate");chosen.confirmed=true
		commit_loadout(id,chosen)
		return
	if int(options.mode)==4 and not DefusalEconomy.can_buy(self,id):feedback(id,"","현재 장비를 구매할 수 없습니다. 구매 시간과 생존 상태를 확인하세요.",true);return
	if int(options.mode)==4 and DefusalEconomy.replacement(p,d) and not d.get("confirmed",false):feedback(id,"","기존 장비 교체를 먼저 확인하세요.",true);return
	if not valid_loadout(p,d):feedback(id,"","이 병과에서 선택할 수 없는 무기입니다.",true);return
	if phase not in ["lobby","buy"] and int(options.mode)!=4 and not options.get("practice",false):
		p.pending_loadout=d.duplicate();loadout_accepted(id)
		feedback(id,"","선택 예약 완료 · 다음 부활"+(" / 다음 라운드 구매 시간" if int(options.mode)==4 else "")+"에 적용됩니다.",true);return
	commit_loadout(id,d)
func commit_loadout(id:int,d:Dictionary):
	d=WeaponRules.selection(options,d)
	var p=players[id]
	if int(options.mode)==4 and (not DefusalEconomy.can_buy(self,id) or (DefusalEconomy.replacement(p,d) and not d.get("confirmed",false))):return
	if not valid_loadout(p,d):return
	var role=clampi(int(d.get("role",p.role)),0,5)
	if role==5 and p.role!=5 and options.classes and medic_count(p.team)>=R.medic_cap(team_count(p.team)):feedback(id,"","메딕 정원이 차서 이전 장비를 유지합니다.",true);return
	var wid=str(d.get("primary",C.first(role)));var sec=str(d.get("secondary",R.SECONDARIES[role]))
	if role==3 and d.get("repair",false):sec="repair"
	var armor=clampi(int(d.get("armor",0)),0,2)*25;var gadget=-1 if int(options.mode)==4 and int(d.get("gadget",0))<0 else 9 if int(options.mode)==4 and int(d.get("gadget",0))==9 else 8 if int(d.get("gadget",0))==8 else clampi(int(d.get("gadget",0)),0,2)
	var cost=loadout_cost(p,d)
	if p.cash<cost:feedback(id,"","구매 실패 · 필요 %d / 보유 %d 크레딧"%[cost,p.cash],true);return
	p.cash-=cost
	if p.role!=role:
		for did in devices.keys():
			if devices[did].owner==id and devices[did].kind=="turret":remove_device(did)
	if role!=int(p.role):
		var elapsed=clock-(float(p.skill_ready)-AbilityBalance.COOLDOWNS[int(p.role)])
		if p.skill_ready>0.:p.skill_ready=clock+maxf(0.,AbilityBalance.COOLDOWNS[role]-elapsed)
		if role==5:p.skill_ready=maxf(p.skill_ready,float(p.get("initial_skill_until",clock+30.)))
	var health_fraction=clampf(float(p.hp)/R.max_hp(p),0.,1.)
	p.role=role;p.hp=R.max_hp(p)*health_fraction;p.primary=wid;p.secondary=sec;p.armor_max=armor;p.armor=armor;p.slot=0 if not wid.is_empty() else 1;p.gadget=gadget;GadgetLoadout.reset(p);p.owned_gadget=gadget>=0;p.owned_secondary=sec!="pistol";p.reload=0.;p.owned_primary=not wid.is_empty();p.burst_left=0;p.trigger_until=0.;p.switch_until=clock+.32;p.fire_ready=clock+.32;equip_ammo(p)
	loadout_accepted(id)
	feedback(id,"","구매 완료 · %d 크레딧 사용"%cost if cost>0 else "장비 적용 완료",true)
func loadout_accepted(id:int):
	if id==local_id:close_loadout()
	elif id>0 and id in multiplayer.get_peers():close_loadout.rpc_id(id)
@rpc("authority","call_remote","reliable",0)
func close_loadout():
	if is_instance_valid(ui) and ui.screen=="gear":ui.exit_gear()
func begin_reload(id:int):
	var p=players[id]
	if not p.alive or p.reload>0 or p.slot>1 or MeleeCombat.active(p,clock):return
	var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
	if w.kind!="gun":return
	var capacity=MagazineReload.capacity(w,int(p.mag.get(wid,0)))
	if int(p.mag.get(wid,0))<capacity and (options.infinite or int(p.reserve.get(wid,0))>0):
		p.reload=clock+MagazineReload.duration(w);p.reload_started=clock;p.reload_weapon=wid;p.burst_left=0;p.reload_half=false
		if str(w.get("reload_style",""))=="revolver" and not p.get("revolver_open",false):p.revolver_open=true;reload_sound.rpc(id,"reload")
		p.reload_capacity=capacity;p.reload_tactical=MagazineReload.chambered(w) and int(p.mag.get(wid,0))>0
		p.reload_count=mini(capacity-int(p.mag.get(wid,0)),capacity if options.infinite else int(p.reserve.get(wid,0)))
		if w.get("single_load",false):p.reload_count=1
		p.reload_cues=0;ReloadAudio.tick(self,id)
func process_trigger(id:int):
	var p=players[id];var a=actors[id];var held=bool(a.input_state.fire);var seq=int(a.input_state.get("trigger_seq",0))
	var pressed=seq>int(p.get("trigger_seen",0)) or (held and not p.get("fire_prev",false))
	p.trigger_seen=maxi(seq,int(p.get("trigger_seen",0)));p.fire_prev=held
	if MeleeCombat.active(p,clock):return
	if bool(a.input_state.get("melee",false)):
		MeleeCombat.begin(self,id);return
	if p.slot==MeleeCombat.SLOT:
		if held or pressed:MeleeCombat.begin(self,id)
		return
	if p.get("placing","")!="":
		if pressed:Deployment.confirm(self,id)
		return
	if p.get("invul_select",0)>clock:
		if pressed:grant_invulnerability(id,invulnerability_target(id))
		return
	if p.slot==2 and GrenadeLogic.equipped(p):
		if pressed and seq>int(p.get("grenade_click_seq",-1)):
			p.grenade_click_seq=seq;GrenadeLogic.begin(self,id,"mouse")
		if not held and not pressed and p.get("cook_input","")=="mouse":GrenadeLogic.release(self,id)
		return
	if p.get("cooking",0)>0:return
	if p.slot>=2:
		if pressed and clock>=p.fire_ready:
			if p.slot==4:use_skill(id)
			else:
				use_gadget(id)
		return
	var w=current_weapon(p);var mode=w.get("fire_mode","auto")
	if w.get("single_load",false) and (pressed or held) and p.reload>0 and int(p.mag.get(p.primary if p.slot==0 else p.secondary,0))>0:
		p.reload=0.;MagazineReload.settle(self,p,w);MagazineReload.close_cylinder(self,id,w);p.trigger_until=clock+.55
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
			if mode=="burst" and p.burst_left==0:p.fire_ready=clock+float(w.get("burst_pause",.3))
func current_weapon(p:Dictionary) -> Dictionary:return C.get_weapon(p.primary if p.slot==0 else p.secondary)
func ray(from:Vector3,to:Vector3,exclude:Array=[],mask:int=15) -> Dictionary:
	var ignored=exclude.duplicate()
	for did in device_nodes:
		if devices.has(did) and Construction.active(self,devices[did]):ignored.append(device_nodes[did].get_rid())
	var q=PhysicsRayQueryParameters3D.create(from,to,mask&~2);q.exclude=ignored
	if mask&1:q.collision_mask|=48
	var hit=get_world_3d().direct_space_state.intersect_ray(q)
	if mask&2:
		var end:Vector3=hit.get("position",to)
		for id in actors:
			var actor=actors[id]
			if actor.get_rid() in exclude or not players.get(id,{}).get("alive",false):continue
			var body_hit=AnatomicalHit.trace(actor,from,end)
			if not body_hit.is_empty():hit=body_hit;end=hit.position
	return hit
func clear_line(from:Vector3,to:Vector3,exclude:Array=[]) -> bool:return ray(from,to,exclude,1|4|8).is_empty()
func fire(id:int):
	var p=players[id];var a=actors[id]
	if not WeaponRules.allows_slot(options,int(p.slot)):return
	if WeaponRules.mode(options)==2 and p.secondary not in WeaponRules.PISTOLS:return
	if p.get("cooking",0)>0 or p.slot>1 or MeleeCombat.active(p,clock) or not can_attack(p) or clock<p.fire_ready or p.reload>0 or clock<a.sprint_release or a.last_sprint:return
	var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
	if w.kind=="remote":return
	if w.get("laser",false):return # Continuous integration belongs to LaserCombat.
	if w.kind=="heal":return # MedicLink integrates healing once per server frame.
	if w.kind=="repair":repair(id);return
	if int(p.mag.get(wid,0))<=0:begin_reload(id);return
	p.mag[wid]-=1;p.fire_ready=clock+float(w.interval)
	if w.get("rocket",false):
		# A launcher only reloads by itself when its tubes are empty; a QUAD
		# fired mid-reload stays as loaded until reload is pressed again.
		RocketCombat.launch(self,id,w)
		if int(p.mag[wid])==0:begin_reload(id)
		return
	var spread=a.spread_angle
	var spray=AimModel.current_spray(w,p,a.aim_progress,bool(a.input_state.crouch))
	if GadgetLoadout.mounted(p,bool(a.input_state.crouch)):spray*=.4
	p.shot_time=clock;p.spray_phase=float(p.get("spray_phase",0))+1.;p.spray_index=int(p.spray_phase);p.bloom=minf(float(w.get("bloom_max",1.2)),float(p.get("bloom",0))+float(w.get("shot_bloom",.12)))
	var origin=a.muzzle_world();var eye=a.eye();var last_end=origin+a.direction()*float(w.get("max_range",300.));var pattern_rotation=randf();var pellet_ends=[];var marks=[];var healed_targets={}
	# A visible camera above cover does not permit firing a barrel embedded in that cover.
	var blocked_barrel=ray(eye,a.desired_muzzle(),[a.get_rid()],1|4|8)
	for pellet in range(int(w.pellets)):
		var forward=Basis(Vector3.UP,a.aim_yaw-deg_to_rad(spray.x))*Basis(Vector3.RIGHT,a.aim_pitch+deg_to_rad(spray.y))*Vector3.FORWARD
		var sample=CombatBalance.pellet_sample(pellet,int(w.pellets),pattern_rotation) if int(w.pellets)>1 else Vector2(randf(),randf())
		if w.has("pellet_core_angle"):
			var core_count=ceili(int(w.pellets)*float(w.get("pellet_core_fraction",.6)))
			if pellet<core_count:
				# Tighter central pellets, without aim assistance; movement still broadens the core.
				var core=float(w.pellet_core_angle)*maxf(1.,spread/maxf(.01,float(w.get("ads_spread",w.spread))))
				sample.x=(float(pellet)+.5)/core_count*pow(minf(1.,core/maxf(.001,spread)),2.)
		var dir=AimModel.cone_direction(forward,spread,sample.x,sample.y)
		var reach=float(w.get("max_range",300.));var aim_hit=ray(eye,eye+dir*reach,[a.get_rid()]);var aim_point=aim_hit.get("position",eye+dir*reach)
		# Keep close-range muzzle convergence, then trace the full range with mild
		# gravity. A missed distant target must not terminate the ray at its chest.
		var flight=Ballistics.trace(self,origin,(aim_point-origin).normalized(),reach,[a.get_rid()]) if blocked_barrel.is_empty() else {"hit":blocked_barrel,"end":blocked_barrel.position}
		var hit:Dictionary=flight.hit;last_end=flight.end
		for did in flight.get("passed",{}):damage_device(did,CombatBalance.structure_damage(w,origin.distance_to(flight.passed[did])),id)
		pellet_ends.append(last_end)
		if hit.is_empty():continue
		var dist=origin.distance_to(hit.position);var dmg=CombatBalance.damage_at(w,dist)
		var collider=hit.collider
		if collider is Actor:
			var q=players[collider.pid]
			if not q.alive:continue
			if float(w.get("heal_per_pellet",0.))>0. and not enemies(p,q):
				var spent=float(healed_targets.get(collider.pid,0.));var cap=float(w.get("heal_cap",100.))
				var amount=minf(maxf(0.,cap-spent),float(w.heal_per_pellet)*CombatBalance.range_factor(w,dist))
				healed_targets[collider.pid]=spent+amount;heal_target(id,collider.pid,amount,true);continue
			var zone=str(hit.get("zone",CombatBalance.hit_zone(hit.position.y-collider.position.y,collider.body_height,bool(collider.input_state.crouch))))
			var head=zone=="head";dmg=CombatBalance.damage_at(w,dist,zone)
			dmg*=R.damage_water(arena.submerged(hit.position),arena.wading(a.position),not arena.wading(collider.position))
			damage(collider.pid,dmg,id,head,wid,origin,hit.position)
		elif collider is InteractiveProp:collider.hit(hit.position,(hit.position-origin).normalized(),dmg)
		elif collider.has_meta("device"):damage_device(int(collider.get_meta("device")),CombatBalance.structure_damage(w,dist),id)
		else:marks.append({"pos":hit.position,"normal":hit.normal})
	if not marks.is_empty():wall_marks_batch.rpc(marks)
	effect.rpc("shot",origin,last_end,id,clock,{"weapon":wid,"bloom":p.bloom,"spray_phase":p.spray_phase,"pellets":pellet_ends})
	if int(p.mag[wid])==0:begin_reload(id)
@rpc("authority","call_local","reliable",0)
func blast_push(id:int,impulse:Vector3,duration:float):
	if not actors.has(id) or not players.has(id):return
	actors[id].velocity+=impulse
	players[id].blast_until=clock+duration
func damage(target:int,amount:float,source:int,critical:bool=false,weapon_id:String="world",hit_origin:Vector3=Vector3.INF,hit_point:Vector3=Vector3.INF):
	if not players.has(target) or not players[target].alive:return
	if weapon_id!="redeploy" and int(options.mode)==4 and (phase=="buy" or MatchFlow.protected_spawn(self,target)):return
	var p=players[target]
	if p.protect>clock or p.get("invulnerable",0)>clock:return
	if players.has(source) and target!=source and not enemies(players[source],p) and not options.friendly:return
	if weapon_id!="fall" and p.shield>clock and actors.has(source):
		var dir=(actors[source].position-actors[target].position).normalized()
		dir.y=0.;dir=dir.normalized()
		if (Basis(Vector3.UP,actors[target].aim_yaw)*Vector3.FORWARD).dot(dir)>.4:amount*=.15
	var armored=(p.armor>0 or float(p.get("plate",0))>0) and weapon_id!="fall"
	# Bonus consumes armor only; any base damage left after breaking armor remains unscaled.
	if armored and weapon_id=="h6":amount+=minf(float(p.armor)+float(p.get("plate",0)),amount*1.3)*(1.-1./1.3)
	var plate_absorb=minf(float(p.get("plate",0)),amount) if weapon_id!="fall" else 0.
	p.plate=float(p.get("plate",0))-plate_absorb
	var absorb=minf(p.armor,amount-plate_absorb) if weapon_id!="fall" else 0.;p.armor-=absorb;p.hp-=amount-plate_absorb-absorb;p.last_hit=clock
	if target<0 and bot_navigation:bot_navigation.danger(actors[target].position)
	var origin=hit_origin if hit_origin.is_finite() else actors[source].position if actors.has(source) and source!=target else actors[target].position
	var push=(actors[target].position-origin).normalized() if origin.distance_squared_to(actors[target].position)>.001 else Vector3.FORWARD
	var point=hit_point if hit_point.is_finite() else actors[target].eye()-Vector3.UP*.35
	if absorb>0:impact.rpc(point,push,false,int(p.team))
	if amount>absorb:flesh_hit.rpc(point,push,amount-absorb,target,source)
	hit_reaction.rpc(target,push)
	if target==local_id:damage_notice(target,origin,amount,armored)
	elif target>0 and target in multiplayer.get_peers():damage_notice.rpc_id(target,target,origin,amount,armored)
	if source!=target:p.contributors[source]=clock
	if source>0 and source!=target:feedback(source,"hit",("정밀 명중" if critical else "방어구 명중" if armored else "명중")+" · "+str(int(round(amount))))
	if p.hp<=0:
		impact.rpc(actors[target].position,push,true,int(p.team),int(p.role),randi()%5,actors[target].aim_yaw,bool(actors[target].input_state.crouch),target,actors[target].velocity,point)
		BombLogic.drop(self,target)
		for did in devices.keys():
			if devices[did].kind=="turret" and int(devices[did].owner)==target:
				event_fx.rpc("turret_break",devices[did].pos+Vector3.UP*.6,Vector3.ZERO,target);remove_device(did)
		p.hp=0;p.alive=false;p.deaths+=1;
		p.can_respawn=int(p.lives)>0
		if int(options.mode)==4 and p.can_respawn:p.lives-=1
		p.respawn=clock+(3. if options.get("practice",false) else 5.2);
		if int(options.mode)==2:
			p.can_respawn=tickets[p.team]>0
			if p.can_respawn:tickets[p.team]-=1
		actors[target].collision_layer=0
		var wid=p.secondary if p.slot==1 or WeaponRules.mode(options)==2 else p.primary
		if not wid.is_empty() and WeaponRules.mode(options)!=1:drops.append({"pos":actors[target].position+Vector3.UP*.18,"yaw":actors[target].aim_yaw,"amount":int(p.mag.get(wid,0))+int(p.reserve.get(wid,0)),"weapon":wid,"until":clock+DROP_LIFETIME})
		if int(options.mode)==4:DefusalEconomy.reset(p);equip_ammo(p)
		if players.has(source) and source!=target and enemies(players[source],p):
			players[source].kills+=1;players[source].match_kills=int(players[source].get("match_kills",0))+1
			if int(options.mode)==0:scores[players[source].team]+=1
			var reward=mini(100,600-int(players[source].round_bonus));players[source].cash=mini(8000,players[source].cash+reward);players[source].round_bonus+=reward
			feedback(source,"confirm",str(p.nick)+" 처치")
		for aid in p.contributors:
			if aid!=source and players.has(aid) and enemies(players[aid],p) and clock-p.contributors[aid]<8:players[aid].assists+=1
		var attacker=players.get(source,{})
		kill_event.rpc({"attacker":source,"attacker_name":str(attacker.get("nick","환경")),"attacker_team":int(attacker.get("team",-1)),"victim":target,"victim_name":str(p.nick),"victim_team":int(p.team),"weapon":weapon_id,"critical":critical,"origin":origin,"hit_point":hit_point if hit_point.is_finite() else actors[target].eye()-Vector3.UP*.3,"victim_pos":actors[target].position})
@rpc("authority","call_local","reliable",0)
func kill_event(event:Dictionary):
	var item=event.duplicate(true);kill_serial+=1;item.serial=kill_serial;item.received=Time.get_ticks_msec();kill_events.append(item)
	while kill_events.size()>KillFeed.MAX_ROWS:kill_events.pop_front()
	if is_instance_valid(kill_replay):kill_replay.request(item)
func damage_device(did:int,amount:float,source:int):
	if not devices.has(did) or amount<=0.:return
	var d=devices[did]
	if players.has(source) and d.team==players[source].team and int(options.mode)!=1 and not options.friendly:return
	Construction.advance(self,d)
	if Construction.active(self,d):amount*=1.5
	var dealt=minf(amount,maxf(0.,float(d.hp)))
	d.hp-=amount;d.last_hit=clock
	if dealt>0. and source>0:feedback(source,"hit",("포탑 명중" if d.kind=="turret" else "엄폐물 명중")+" · "+str(roundi(dealt)))
	if d.hp<=0:event_fx.rpc("turret_break" if d.kind=="turret" else "cover_break",d.pos+Vector3.UP*.85,Vector3.ZERO,source);remove_device(did)
func aim_player(id:int,range_m:float,ally:bool) -> int:
	var a=actors[id];var hit=ray(a.eye(),a.eye()+a.direction()*range_m,[a.get_rid()])
	if hit.is_empty() or not hit.collider is Actor:return 0
	var tid=hit.collider.pid
	if not players[tid].alive:return 0
	return tid if enemies(players[id],players[tid])!=ally else 0
func heal_target(id:int,tid:int,amount:float,weapon_heal:bool=false,visual:bool=true):
	if tid==0:return
	var p=players[id];var q=players[tid];var healed=minf(maxf(0.,R.max_hp(q)-q.hp),amount*(1. if weapon_heal else .5 if clock-q.last_hit<2 else 1.))
	if q.get("healing_until",0)>clock and q.get("healer",id)!=id:return
	q.hp+=healed;q.healing_until=clock+.12;q.healer=id
	if tid!=id and not enemies(p,q):p.healed+=healed
	if healed>0 and visual:effect.rpc("heal",actors[id].muzzle_world(),actors[tid].position+Vector3.UP*(.90 if actors[tid].input_state.crouch else 1.15)*actors[tid].body_height/1.8,id,-100.,{"target":tid})
func continuous_heal(id:int):
	# Compatibility entry point; normal input uses delta-integrated MedicLink.tick.
	MedicLink.tick(self,id,.1)
func heal_burst(id:int):
	var p=players[id];var a=actors[id]
	if not p.alive or p.role!=5 or p.primary not in ["m2","m3"] or p.slot!=0:return
	if clock<p.heal_ready or clock<p.fire_ready or p.reload>0 or a.last_sprint or clock<a.sprint_release:return
	var target=aim_player(id,15,true)
	var center=a.eye()+a.direction()*15.
	if target!=0:center=actors[target].eye()
	else:
		var hit=ray(a.eye(),center,[a.get_rid()])
		if not hit.is_empty():center=hit.position+hit.normal*.08
	p.heal_ready=clock+10.;p.fire_ready=maxf(p.fire_ready,clock+.2)
	for tid in players:
		var q=players[tid]
		if not q.alive or enemies(p,q):continue
		var distance=center.distance_to(actors[tid].eye())
		if distance>4. or not clear_line(center,actors[tid].eye(),[a.get_rid(),actors[tid].get_rid()]):continue
		heal_target(id,tid,lerpf(30.,15.,distance/4.),true,false)
	effect.rpc("heal_area",center,center,id)
func repair(id:int):
	var p=players[id];var a=actors[id];p.fire_ready=clock+.1
	if p.repair_energy<2:return
	var hit=ray(a.eye(),a.eye()+a.direction()*10.,[a.get_rid()])
	if hit.is_empty() or not hit.collider.has_meta("device"):return
	var did=int(hit.collider.get_meta("device"))
	if not devices.has(did):return
	var d=devices[did]
	if d.team!=p.team or d.hp>=d.max_hp or d.get("repair_until",0)>clock:return
	d.hp=minf(d.max_hp,d.hp+3.);d.repair_until=clock+.09;p.repair_energy-=2;effect.rpc("repair",a.muzzle_world(),d.pos+Vector3.UP,id)
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
	devices[did]={"id":did,"kind":kind,"pos":pos,"yaw":actors[id].aim_yaw,"owner":id,"team":players[id].team,"hp":hp,"max_hp":hp,"level":1,"upgrade_ready":clock+AbilityBalance.COOLDOWNS[3],"next_fire":clock+1,"target":0,"lock":0.,"last_hit":-100.,"disabled":0.,"expires":1e12}
	return did
func invulnerability_target(id:int) -> int:
	var a=actors[id];var best=cos(deg_to_rad(10.));var target=0
	for tid in players:
		if tid==id or not players[tid].alive or enemies(players[id],players[tid]):continue
		var point=actors[tid].eye()-Vector3.UP*.25;var delta=point-a.eye()
		if delta.length()>30. or delta.length()<.05:continue
		var alignment=a.direction().dot(delta.normalized())
		if alignment>best and clear_line(a.eye(),point,[a.get_rid(),actors[tid].get_rid()]):target=tid;best=alignment
	return target
func grant_invulnerability(id:int,target:int):
	var p=players[id]
	if p.skill_ready>clock or not p.alive:return
	if target!=0 and (not players.has(target) or not players[target].alive or enemies(p,players[target])):target=0
	var recipients=[id]
	if target!=0 and target!=id:recipients.append(target)
	for tid in recipients:
		var q=players[tid];q.invulnerable=clock+6.;q.cleanse=clock+6.;q.slow=0.;q.mark=0.;q.reveal_to={};q.flash=0.
		feedback(tid,"heal","무적 보호 · 6초");effect.rpc("skill",actors[tid].position,Vector3.ZERO,id)
	p.invul_select=0.;p.skill_ready=clock+AbilityBalance.COOLDOWNS[5]
func use_skill(id:int):
	if WeaponRules.mode(options)>0:return
	if MeleeCombat.active(players[id],clock):return
	var p=players[id];var a=actors[id]
	if not options.skills or not options.classes or not can_attack(p) or phase!="combat":return
	if p.role==3:
		if p.get("placing","")=="turret":Deployment.begin(self,id,"turret");return
		var nearby=Deployment.nearby_turret(self,id)
		if nearby:TurretLogic.upgrade(self,id,nearby);return
	if clock<p.skill_ready:feedback(id,"","스킬 충전 중: "+str(int(ceil(p.skill_ready-clock)))+"초");return
	match int(p.role):
		0:p.dash=clock+5.;p.dash_recovery=clock+8.;p.skill_ready=clock+AbilityBalance.COOLDOWNS[0]
		1:
			var radius=AbilityBalance.scan_range(arena.bounds)
			for qid in players:
				if players[qid].alive and enemies(p,players[qid]) and a.position.distance_to(actors[qid].position)<radius and players[qid].get("cleanse",0)<=clock:
					TargetReveal.mark(self,qid,id,4.);feedback(qid,"","하드비트센서 노출 · 4초 동안 위치가 표시됩니다.")
			p.skill_ready=clock+40.;announce(p.nick+" · 하드비트센서",false)
		2:p.shield=clock+6.;p.skill_ready=clock+AbilityBalance.COOLDOWNS[2]
		3:Deployment.begin(self,id,"turret");return
		4:
			var target=placement(id);target.y=arena.walk_height(target)+.04
			fields.append({"kind":"slow","pos":target,"until":clock+AbilityBalance.DURATIONS[4],"team":p.team,"owner":id});p.skill_ready=clock+AbilityBalance.COOLDOWNS[4]
		5:
			if id<0:grant_invulnerability(id,id);return
			p.invul_select=clock+10.;p.invul_pressed=clock;p.fire_prev=true;p.trigger_seen=int(a.input_state.get("trigger_seq",0))
			feedback(id,"","아군 클릭: 함께 6초 무적 · 빈 곳 클릭: 자신만 보호")
			return
	effect.rpc("skill",a.position,Vector3.ZERO,id)
	feedback(id,"",["기동: 5초 고속이동 / 3초 빠른이동","하드비트센서 · 4초","방호 · 6초 / 전방 피해 85% 감소","설치 위치 선택","둔화 구역 · 반경 15m / 65% 둔화","무적 보호"][int(p.role)])
func use_gadget(id:int):
	if MeleeCombat.active(players[id],clock):return
	if int(players[id].gadget)==9:feedback(id,"","해체 키트 · 폭탄 앞에서 E를 5초 유지");return
	var p=players[id];var a=actors[id]
	if p.get("placing","")=="cover":Deployment.begin(self,id,"cover");return
	if MarkerTracker.equipped(p):feedback(id,"","표식기 자동 추적 · 무기 조준경으로 적을 1.5초간 추적하세요.");return
	if GadgetLoadout.mounted(p,true):feedback(id,"","거치대 장착 중 · 앉으면 자동으로 정확도·반동 개선");return
	if not options.classes or not can_attack(p) or phase!="combat" or p.gadget_count<=0 or clock<p.gadget_ready:return
	if GrenadeLogic.equipped(p):
		if GrenadeLogic.begin(self,id):GrenadeLogic.release(self,id)
		return
	match int(p.role):
		0:
			if float(p.get("plate",0))>0:feedback(id,"","하나의 보호판만 사용할 수 있습니다.");return
			p.plate=25.
		1:
			var tid=aim_player(id,160,false)
			if tid==0:feedback(id,"","표식할 상대를 조준하세요.");return
			if players[tid].get("cleanse",0)<=clock:TargetReveal.mark(self,tid,id,6.);feedback(tid,"","표식 감지 · 6초 동안 위치가 노출됩니다.")
		2:
			if not a.input_state.crouch:feedback(id,"","앉아서 거치대를 사용하세요.");return
			p.mounted=clock+15 # Legacy field; equipped support is now passive.
		3:Deployment.begin(self,id,"cover");return
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
				p.smoke-=1;effect.rpc("throw",a.muzzle_world(),end,id);fields.append({"kind":"smoke","pos":end,"starts":clock+.35,"until":clock+AbilityBalance.SMOKE_DURATION+.35,"team":p.team,"owner":id,"deployed":false})
		5:
			var tid=aim_player(id,4,true)
			if tid==0:tid=id
			if players[tid].hp>=R.max_hp(players[tid]):feedback(id,"","체력이 이미 가득 찼습니다.");return
			heal_target(id,tid,25)
	p.gadget_count-=1;p.gadget_ready=clock+.8;p.fire_ready=maxf(p.fire_ready,clock+.4)
	if p.role!=4:event_fx.rpc("deploy",a.position,Vector3.ZERO,id)
	feedback(id,"",["보호판 장착 · 내구도 25","상대 표식 · 6초","거치대 활성 · 15초 동안 정지 사격 정확도 증가","엄폐물 설치 완료","섬광탄 사용" if p.gadget==1 else "연막탄 전개 · 10초","응급 회복 +25"][int(p.role)])
func remove_device(did:int):
	devices.erase(did)
	if device_nodes.has(did):device_nodes[did].queue_free();device_nodes.erase(did)
func in_smoke_line(from:Vector3,to:Vector3) -> bool:
	for f in fields:
		if f.kind=="smoke" and float(f.get("starts",0))<=clock and Geometry3D.get_closest_point_to_segment(f.pos+Vector3.UP*2,from,to).distance_to(f.pos+Vector3.UP*2)<5:return true
	return false
func update_devices(dt:float):
	TurretLogic.tick(self,dt)
func update_fields(dt:float):
	fields=fields.filter(func(f):return f.until>clock)
	for f in fields:
		if float(f.get("starts",0))>clock:continue
		if f.kind=="flash_pending":
			for qid in players:
				if players[qid].alive and players[qid].get("cleanse",0)<=clock and clear_line(f.pos+Vector3.UP,actors[qid].eye(),[actors[qid].get_rid()]):
					var distance=actors[qid].eye().distance_to(f.pos+Vector3.UP)
					var facing=actors[qid].direction().dot((f.pos+Vector3.UP-actors[qid].eye()).normalized())
					players[qid].flash=maxf(players[qid].flash,clock+AbilityBalance.flash_duration(distance,facing))
			for device in devices.values():
				if device.pos.distance_to(f.pos)<AbilityBalance.FLASH_RANGE and clear_line(f.pos+Vector3.UP,device.pos+Vector3.UP*.8):device.disabled=clock+2.2
			event_fx.rpc("flash",f.pos,f.pos,int(f.owner));f.until=clock-1
		elif f.kind=="smoke" and not f.get("deployed",true):f.deployed=true;event_fx.rpc("smoke",f.pos,f.pos,int(f.owner))
		elif f.kind=="slow":
			for id in players:
				if players[id].alive and players[id].team!=f.team and players[id].get("cleanse",0)<clock and actors[id].position.distance_to(f.pos)<AbilityBalance.SLOW_RADIUS and clear_line(f.pos+Vector3.UP*.35,actors[id].position+Vector3.UP*.8,[actors[id].get_rid()]):players[id].slow=clock+.2
func update_pickups():
	drops=drops.filter(func(d):return d.until>clock and not d.get("collected",false))
	while drops.size()>MAX_DROPS:drops.pop_front()
	for id in players:
		var p=players[id]
		if not p.alive:continue
		for drop in drops:
			if drop.get("collected",false) or actors[id].position.distance_to(drop.pos)>2.:continue
			var candidates=[p.primary,p.secondary] if p.slot!=1 else [p.secondary,p.primary]
			var ammo_id="";var take=0
			for candidate in candidates:
				if str(candidate).is_empty():continue
				var weapon=C.get_weapon(candidate)
				if weapon.kind!="gun":continue
				take=mini(maxi(0,int(weapon.reserve)-int(p.reserve.get(candidate,0))),mini(R.ammo_pickup(int(weapon.reserve)),int(drop.amount)))
				if take>0:ammo_id=candidate;break
			var gadget_missing=GadgetLoadout.can_replenish(p)
			if take<=0 and not gadget_missing:continue
			if not clear_line(actors[id].position+Vector3.UP*.5,drop.pos+Vector3.UP*.15,[actors[id].get_rid()]):continue
			drop.collected=true
			if take>0:p.reserve[ammo_id]=int(p.reserve.get(ammo_id,0))+take
			var replenished=gadget_missing and randf()<.1
			if replenished:GadgetLoadout.replenish(p)
			feedback(id,"","떨어진 총 회수"+(" · 탄약 +%d"%take if take>0 else "")+(" · 가젯 +1" if replenished else ""))
		var wid=p.primary if p.slot==0 else p.secondary;var w=C.get_weapon(wid)
		if w.kind!="gun":continue
		for supply in arena.supplies:
			if supply.ready<=clock and actors[id].position.distance_to(supply.pos)<1.8 and int(p.reserve[wid])<int(w.reserve):
				p.reserve[wid]=mini(int(w.reserve),int(p.reserve[wid])+R.ammo_pickup(int(w.reserve)));supply.ready=clock+30;feedback(id,"","탄약 보급 +25%")
func interact(id:int,dt:float):
	var p=players[id];var a=actors[id]
	if int(options.mode)==4 and phase=="combat" and BombLogic.pickup(self,id):return
	var door=InteractiveDoor.target(self,id) if BombLogic.action(self,id).is_empty() else null
	if door:
		if not p.get("use_prev",false):
			if door.toggle(actors):effect.rpc("door",door.global_position,Vector3.ZERO,id)
			else:feedback(id,"","통로에 사람이 있어 닫을 수 없습니다.")
		return
	if int(options.mode)!=4 or phase!="combat":return
	var attackers=MatchFlow.attackers(self)
	if not bomb.planted and p.team==attackers and int(bomb.get("carrier",0))==id:
		for i in range(arena.sites.size()):
			if a.position.distance_to(arena.sites[i])<5:
				if bomb.actor!=id:bomb.actor=id;bomb.progress=0
				bomb.last_touch=clock;bomb.progress+=dt
				if bomb.progress>=3:
					bomb.planted=true;bomb.carrier=0;bomb.dropped=false;bomb.site=i;bomb.position=a.position+Vector3.UP*.015;bomb.time=float(options.get("bomb_seconds",45));bomb.total_time=bomb.time;bomb.actor=0;bomb.progress=0;p.objective+=3
					for q in players.values():
						if q.team==p.team:q.cash=mini(8000,q.cash+300)
					announce("폭탄 설치 완료 · %d초 내 해체"%int(bomb.time));bomb_announcement.rpc("bomb_planted");return
	elif bomb.planted and p.team!=attackers and a.position.distance_to(bomb.position)<1.8:
		if bomb.actor!=id:bomb.actor=id;bomb.progress=0
		bomb.last_touch=clock;bomb.progress+=dt
		if bomb.progress>=BombLogic.defuse_seconds(p):
			p.objective+=5;bomb.defused=true;bomb.actor=0;bomb.progress=0.;bomb_announcement.rpc("bomb_defused");finish_round(p.team,"폭탄 해체 완료")
func check_objectives(dt:float):
	match int(options.mode):
		0:
			if maxi(scores[0],scores[1])>=int(options.target) or remaining<=0:finish_match("무승부" if scores[0]==scores[1] else ("BLUE 승리" if scores[0]>scores[1] else "ORANGE 승리"))
		1:
			var best=-1;var winner=0;var tied=false
			for p in players.values():
				var kills=int(p.get("match_kills",0))
				if kills>best:best=kills;winner=int(p.id);tied=false
				elif kills==best:tied=true
			if best>=int(options.target) or remaining<=0:finish_match("무승부" if tied else str(players[winner].nick)+" 개인전 승리",-1,0 if tied else winner)
		2:
			var alive=[0,0]
			for p in players.values():
				if p.alive or p.can_respawn:alive[p.team]+=1
			if players.size()>1 and (alive[0]==0 or alive[1]==0):finish_match("무승부" if alive[0]==alive[1] else "BLUE 승리" if alive[0]>0 else "ORANGE 승리")
			elif remaining<=0:
				var reserve=[alive[0]+tickets[0],alive[1]+tickets[1]]
				finish_match("무승부" if reserve[0]==reserve[1] else "BLUE 승리" if reserve[0]>reserve[1] else "ORANGE 승리")
		3:
			ControlCapture.tick(self,dt)
			scores=[zone_owner.count(0),zone_owner.count(1)]
			var all_team=0 if scores[0]==3 else 1 if scores[1]==3 else -1
			if all_team!=capture_team:capture_elapsed=0.;capture_team=all_team
			if all_team>=0:capture_elapsed+=dt
			if (all_team>=0 and capture_elapsed>=float(options.capture_hold)) or remaining<=0:finish_match("무승부" if scores[0]==scores[1] else "BLUE 승리" if scores[0]>scores[1] else "ORANGE 승리")
		4:
			BombLogic.tick(self,dt)
			if bomb.actor!=0 and (not players.has(bomb.actor) or not players[bomb.actor].alive or not actors[bomb.actor].input_state.use or clock-bomb.get("last_touch",0)>.1):bomb.actor=0;bomb.progress=0
			var attackers=MatchFlow.attackers(self);var alive=[0,0]
			for p in players.values():
				if p.alive or p.can_respawn:alive[p.team]+=1
			if bomb.planted:
				bomb.time=maxf(0.,bomb.time-dt)
				if bomb.time<=0:BombLogic.detonate(self);return
				if alive[1-attackers]==0 and team_count(1-attackers)>0:finish_round(attackers,"수비팀 전원 Dead");return
			else:
				if remaining<=0:finish_round(1-attackers,"설치 시간 종료");return
				if alive[attackers]==0 and team_count(attackers)>0:finish_round(1-attackers,"공격팀 전원 Dead");return
				if alive[1-attackers]==0 and team_count(1-attackers)>0:finish_round(attackers,"수비팀 전원 Dead")
func start_match(reset_series:bool=true):
	if not server:return
	if reset_series:completed_games=0;control_leg=0
	RoundCleanup.clear(self)
	if arena:arena.reset_props()
	result={"team":-1,"player":0};capture_team=-1;capture_elapsed=0.
	for p in players.values():
		p.match_kills=0;p.lives=int(options.lives);p.skill_ready=clock+30. if p.role==5 else 0.;p.initial_skill_until=clock+30.;p.spectator=false;p.can_respawn=true
		if int(options.mode)==4:DefusalEconomy.reset(p,int(options.starting_cash))
	enforce_medics();tickets=[int(options.team_respawns),int(options.team_respawns)];scores=[0,0];losses=[0,0];round_no=0;zone_owner=[-1,-1,-1];zone_capture=[0.,0.,0.];zone_counts=[[0,0],[0,0],[0,0]]
	if int(options.mode)==4:begin_round()
	else:
		phase="combat";remaining=ModeOptions.seconds(options)
		for id in players:spawn(id)
	ui.show_hud();broadcast_state(true)

func enforce_medics():
	for team in [0,1]:
		var n=0
		for p in players.values():
			if p.team==team and p.role==5:
				n+=1
				if n>R.medic_cap(team_count(team)):
					p.role=0
					if int(options.mode)==4:DefusalEconomy.reset(p)
					else:p.primary="a1";p.secondary="pistol"
					equip_ammo(p)
func begin_round():DefusalMatch.begin(self)
func open_buy_menu():
	if not dedicated and phase=="buy" and players.has(local_id):ui.gear()

func finish_round(winner:int,reason:String):DefusalMatch.finish(self,winner,reason)

func finish_match(message:String,winner:int=-2,player:int=0):
	if phase!="combat":return
	if winner==-2:winner=0 if message.begins_with("BLUE") else 1 if message.begins_with("ORANGE") else -1
	result={"team":winner,"player":player};completed_games+=1
	if winner>=0:winner_voice.rpc(winner)
	phase="result";remaining=12;announce(message+" · 다음 경기까지 12초")
@rpc("authority","call_local","reliable",0)
func winner_voice(team:int):
	if not dedicated and team in [0,1]:play_sound("win_blue" if team==0 else "win_orange",Vector3.ZERO,false)

func next_match():
	if MatchFlow.at_limit(self):
		MatchFlow.rotate(self);start_match(false)
		return
	if int(options.mode)==3:control_leg=1-control_leg
	if int(options.mode)!=3 or control_leg==0:MatchFlow.rotate(self)
	RoundCleanup.clear(self)
	if int(options.next_teams)==2:
		var split=R.balanced_ids(players)
		for t in [0,1]:
			for id in split[t]:players[id].team=t;actors[id].set_team(t)
	elif int(options.next_teams)==1:
		var ids=players.keys();ids.shuffle()
		for i in range(ids.size()):players[ids[i]].team=i%2;actors[ids[i]].set_team(i%2)
	TeamBalance.reconcile(self)
	start_match(false)
func broadcast_state(force:bool,target_peer:int=0):
	if not server or arena==null or multiplayer.get_peers().is_empty():return
	var list=[]
	for id in players:
		var p=players[id];var a=actors[id];var d=p.duplicate();d.erase("token");d.erase("contributors");d.erase("melee_hits");d.pos=a.position;d.yaw=a.aim_yaw;d.pitch=a.aim_pitch;d.crouch=a.input_state.crouch;d.velocity=a.velocity;d.grounded=a.is_on_floor();d.sprint=a.last_sprint;d.ads=a.input_state.ads;d.spread_angle=a.spread_angle;list.append(d)
	var supplies=[]
	for s in arena.supplies:supplies.append(s.ready)
	var state={"map":options.map,"result":result,"overtime_attacker":overtime_attacker,"capture_elapsed":capture_elapsed,"completed_games":completed_games,"control_leg":control_leg,"clock":clock,"phase":phase,"remaining":remaining,"scores":scores,"tickets":tickets,"round":round_no,"players":list,"devices":devices,"fields":fields,"drops":drops,"zones":zone_owner,"zone_capture":zone_capture,"zone_counts":zone_counts,"supplies":supplies,"bomb":bomb,"props":arena.prop_states(),"doors":arena.door_states(),"grenades":grenades,"rockets":rockets}
	if multiplayer.get_peers().size()>0:
		snapshot_sequence+=1;state.sequence=snapshot_sequence
		state.team_policy={"teams":options.teams,"next_teams":options.next_teams,"room_owner":options.get("room_owner",1)};state.vote=vote
		var packed=var_to_bytes(state).compress(FileAccess.COMPRESSION_DEFLATE)
		var parts=int(ceil(packed.size()/1000.0))
		for peer in multiplayer.get_peers():
			if (target_peer!=0 and peer!=target_peer) or not players.has(peer):continue
			var link=multiplayer.multiplayer_peer.get_peer(peer)
			# A peer that is still handshaking or already tearing down has no
			# channels yet: sending would only log "Unable to send packet".
			if link is ENetPacketPeer and (link.get_state()!=ENetPacketPeer.STATE_CONNECTED or link.get_channels()==0):continue
			if link is WebSocketPeer and (link.get_ready_state()!=WebSocketPeer.STATE_OPEN or link.get_current_outbound_buffered_amount()>24000):continue
			if link is Dictionary and (not link.get("connected",false) or link.get("channels",[]).any(func(channel):return channel.get_ready_state()!=WebRTCDataChannel.STATE_OPEN)):continue
			# Reliable syncs carry the same deflated bytes as snapshots. A raw
			# dictionary was ~11x larger and stalled every peer's reliable channel.
			if force:full_state_packed.rpc_id(peer,packed)
			else:
				for i in range(parts):snapshot_chunk.rpc_id(peer,snapshot_sequence,i,parts,packed.slice(i*1000,mini(packed.size(),(i+1)*1000)))
@rpc("authority","call_remote","unreliable",3)
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
func full_state_packed(bytes:PackedByteArray):
	if bytes.size()>256000:return
	var state=bytes_to_var(bytes.decompress_dynamic(1048576,FileAccess.COMPRESSION_DEFLATE))
	if state is Dictionary:receive_state(state)
@rpc("authority","call_remote","unreliable_ordered",1)
func snapshot(s:Dictionary):receive_state(s)
func receive_state(s:Dictionary):
	if server or arena==null:return
	var _t=Time.get_ticks_usec();receive_state_body(s);prof_add("receive",_t)
func receive_state_body(s:Dictionary):
	var sequence=int(s.get("sequence",received_sequence+1))
	if sequence<=received_sequence:return
	received_sequence=sequence;last_snapshot_ms=Time.get_ticks_msec();connection_notice=false
	if s.has("team_policy"):options.merge(s.team_policy,true)
	if int(s.get("map",options.map))!=int(options.map):options.map=int(s.map);build_world()
	completed_games=int(s.get("completed_games",0));control_leg=int(s.get("control_leg",0))
	var old_round=round_no
	if int(s.round)!=old_round:RoundCleanup.clear(self)
	result=s.get("result",{"team":-1,"player":0});overtime_attacker=int(s.get("overtime_attacker",0));capture_elapsed=float(s.get("capture_elapsed",0.))
	vote=s.get("vote",{});clock=s.clock;var old_phase=phase;phase=s.phase;remaining=s.remaining;scores=s.scores;tickets=s.tickets;round_no=s.round;bomb=s.bomb;zone_owner=s.zones;zone_capture=s.get("zone_capture",[0.,0.,0.]);zone_counts=s.get("zone_counts",[[0,0],[0,0],[0,0]]);fields=s.fields;drops=s.drops;MatchFlow.update_gate(self)
	var present=[]
	for p in s.players:
		var id=int(p.id);var fresh=not players.has(id) or (not players[id].alive and p.alive);present.append(id);players[id]=p;ensure_actor(id);var a=actors[id];a.set_team(int(p.team));a.collision_layer=2 if p.alive else 0
		if id==local_id:
			if fresh:a.position=p.pos;a.velocity=Vector3.ZERO;a.reset_view(p.yaw)
			if a.position.distance_to(p.pos)>2 or not p.alive:a.position=p.pos
			else:a.position=a.position.lerp(p.pos,.25)
		else:a.target_pos=p.pos;a.aim_yaw=p.yaw;a.aim_pitch=p.pitch;a.input_state.crouch=p.crouch;a.net_velocity=p.get("velocity",Vector3.ZERO);a.net_grounded=p.get("grounded",true);a.net_sprint=p.get("sprint",false);a.remote_ads=p.get("ads",false);a.net_gait_target=float(p.get("gait",0.))
	for id in players.keys():
		if not present.has(id):players.erase(id);actors[id].queue_free();actors.erase(id)
	devices=s.devices;grenades=s.get("grenades",[]);rockets=s.get("rockets",[])
	arena.receive_props(s.get("props",[]))
	arena.receive_doors(s.get("doors",[]))
	for i in range(mini(s.supplies.size(),arena.supplies.size())):arena.supplies[i].ready=s.supplies[i]
	if phase=="buy" and (old_phase!=phase or old_round!=round_no):call_deferred("open_buy_menu")
	elif old_phase!=phase:
		if phase=="lobby":ui.lobby()
		elif phase=="combat":ui.clear_panel();ui.show_hud();capture_pointer()
func update_world_visuals(dt:float):
	if arena==null:return
	var upgrade_target=TurretSelection.target(self,local_id)
	for did in devices:
		var d=devices[did]
		if not device_nodes.has(did):
			var b=StaticBody3D.new();b.collision_layer=4;b.collision_mask=0;b.set_meta("device",did);add_child(b);device_nodes[did]=b
			CombatFX.device(b,d.kind,int(d.team),Construction.cover_variant(d))
			var c=CollisionShape3D.new();c.name="Collision";var sh=BoxShape3D.new();sh.size=Construction.cover_size(d) if d.kind=="cover" else Vector3(.85,2.,1.3);c.shape=sh;c.position=Vector3(0,sh.size.y/2.,-.12 if d.kind=="turret" else 0.);b.add_child(c)
			var top=1.55 if d.kind=="cover" else 2.4
			var label=arena.text3d("",Vector3(0,top,0),Color.WHITE,25,b);label.name="Label"
			var health_label=arena.text3d("",Vector3(0,top-.25,0),Color.WHITE,25,b);health_label.name="HealthLabel"
			var build_timer=arena.text3d("",Vector3(0,top+.3,0),Color.WHITE,28,b);build_timer.name="BuildTimer"
		var node=device_nodes[did];node.position=d.pos
		# 1.4.4: cover lies along the ground's slope (measured once; the ground is static).
		if not node.has_meta("ground_basis") or node.get_meta("ground_yaw",INF)!=d.yaw:
			node.set_meta("ground_basis",Deployment.basis_on_ground(self,d.pos,d.yaw,d.kind));node.set_meta("ground_yaw",d.yaw)
		node.basis=node.get_meta("ground_basis")
		var factor=TurretLogic.SCALES[int(d.level)-1] if d.kind=="turret" else 1.;node.scale=Vector3.ONE*factor
		if d.kind=="turret":
			var head=node.get_node("TurretHead");var target:Vector3=d.get("aim",TurretLogic.origin(d)+Basis(Vector3.UP,d.yaw)*Vector3.FORWARD*5.)
			if head.global_position.distance_squared_to(target)>.01:head.look_at(target)
			if int(d.level)==4 and not head.has_node("MissilePod"):
				var pod=MeshFactory.box(head,Vector3(0,.38,.08),Vector3(.66,.22,.50),Color("4e6069"));pod.name="MissilePod"
				for side in [-1,1]:MeshFactory.cylinder(head,Vector3(side*.21,.38,-.20),.075,.08,Color("191f25"),Vector3(PI/2,0,0),-1.,12)

		DeploymentSilhouette.apply(node,d,local_id)
		Construction.visual(self,node,d)
		Construction.labels(self,node,d)
		TurretSelection.apply(self,node,d,int(did)==upgrade_target)
	for did in device_nodes.keys():
		if not devices.has(did):device_nodes[did].queue_free();device_nodes.erase(did)
	for s in arena.supplies:
		s.node.visible=s.ready<=clock
	combat_fx.sync_fields(fields,clock)
	combat_fx.sync_grenades(grenades,clock)
	combat_fx.sync_rockets(rockets)
	combat_fx.sync_bomb(self)
	combat_fx.sync_status(self,clock)
	var live_drops={}
	for d in drops:
		var key=str(d.until)+str(d.pos)+d.weapon;live_drops[key]=true
		if not drop_nodes.has(key):
			var _dt=Prof.now();var n=GunModel.new();add_child(n);n.build(Catalog.get_weapon(d.weapon),false);n.position=d.pos+Vector3.UP*.04;n.rotation=Vector3(0,float(d.get("yaw",0)),PI/2);drop_nodes[key]=n;Prof.add("death_drop_model",_dt)
			for mesh in n.find_children("*","GeometryInstance3D",true,false):mesh.visibility_range_end=55. if RenderStyle.web() else 80.;mesh.visibility_range_end_margin=5.
			var tag=arena.text3d(Catalog.get_weapon(d.weapon).name,Vector3(0,.4,0),Color("d7e8ef"),24,n);tag.top_level=true;tag.global_position=d.pos+Vector3.UP*.5;tag.visibility_range_end=12;tag.visibility_range_end_margin=1.5;tag.pixel_size=.004
	for key in drop_nodes.keys():
		if not live_drops.has(key):drop_nodes[key].queue_free();drop_nodes.erase(key)
func feedback(id:int,sound:String,message:String,menu_notice=false):
	if id<0:return
	if id==local_id:personal(sound,message,menu_notice)
	elif id in multiplayer.get_peers():personal.rpc_id(id,sound,message,menu_notice)
@rpc("authority","call_remote","reliable",0)
func personal(sound:String,message:String,menu_notice=false):
	if not sound.is_empty():play_sound(sound,Vector3.ZERO,false)
	ui.notice(message,not menu_notice)
	if sound in ["hit","confirm"]:ui.hit_until=Time.get_ticks_msec()+180
func announce(message:String,important=true):
	announcement.rpc(message,important)
@rpc("authority","call_local","reliable",0)
func announcement(message:String,important=true):ui.notice(message,true,important)
@rpc("authority","call_local","reliable",0)
func zone_announcement(index:int,team:int):
	if index<0 or index>=3 or team not in [0,1]:return
	var letter=ControlCapture.LABELS[index]
	if not dedicated:play_sound("capture_"+("blue" if team==0 else "orange")+"_"+letter.to_lower(),Vector3.ZERO,false)
	ui.notice(("BLUE" if team==0 else "ORANGE")+" 팀 · "+letter+" 거점 점령",true)
@rpc("authority","call_local","reliable",0)
func bomb_announcement(kind:String):
	if kind not in ["bomb_planted","bomb_dropped","bomb_defused"]:return
	if not dedicated:play_sound(kind,Vector3.ZERO,false)
	ui.notice({"bomb_planted":"폭탄이 설치되었습니다.","bomb_dropped":"폭탄을 떨어뜨렸습니다.","bomb_defused":"폭탄 해체가 완료되었습니다."}[kind],true)
@rpc("authority","call_local","unreliable",2)
func effect(kind:String,from:Vector3,to:Vector3,owner:int,shot_at:float=-100.,shot_state:Dictionary={}):
	if dedicated:return
	if kind=="laser":
		# Draw from the muzzle the viewer sees (the first-person view model for the
		# shooter, the held weapon for others); the server origin sits at the eye.
		var start=actors[owner].visual_muzzle() if actors.has(owner) and is_instance_valid(actors[owner]) else from
		combat_fx.beam(start,to,false,true);play_sound("laser_fire",from,owner!=local_id);return
	if kind=="laser_vent":play_sound("laser_vent",from,owner!=local_id);return
	if kind=="heal_area":
		combat_fx.heal_area(from);play_sound("heal",from,owner!=local_id);return
	if kind=="rocket_launch":
		if actors.has(owner):actors[owner].show_shot(shot_at)
		play_sound("gun_"+str(shot_state.get("weapon","h4")),from,owner!=local_id);return
	if kind=="melee_swing":
		if players.has(owner):players[owner].melee_started=maxf(shot_at,float(players[owner].get("melee_started",-100.)))
		play_sound("wrench_swing" if shot_state.get("wrench",false) else "knife_swing",from,owner!=local_id);return
	if kind=="slide":play_sound("slide",from,owner!=local_id);return
	if kind=="melee_wall":
		if owner==local_id:play_sound("wrench_wall" if shot_state.get("wrench",false) else "knife_wall",from,false)
		return
	if kind=="melee_flesh":
		if owner==local_id:play_sound("wrench_flesh" if shot_state.get("wrench",false) else "knife_flesh",from,false)
		return
	if kind in ["grenade_throw","grenade_bounce"]:play_sound(kind.trim_prefix("grenade_"),from,owner!=local_id);return
	if kind=="bomb_explosion":
		combat_fx.explosion(from,true,maxf(2.5,to.x/3.),true)
		play_sound("bomb_explosion",from,true)
		if actors.has(local_id):actors[local_id].land_kick=.18
		return
	if kind=="shot" and players.has(owner) and not shot_state.is_empty():
		var p=players[owner]
		if shot_at>=float(p.get("shot_time",-100.)) and (p.primary if p.slot==0 else p.secondary)==shot_state.weapon:
			p.shot_time=shot_at;p.bloom=shot_state.bloom;p.spray_phase=shot_state.spray_phase;p.spray_index=int(p.spray_phase)
	if kind=="shot" and is_instance_valid(kill_replay):kill_replay.record_shot(from,to,owner)
	if kind=="turret_detect":play_sound("turret_detect",from,true);return
	var sound={"turret_break":"explosion","cover_break":"explosion","melee_flesh":"melee_flesh","melee_repair":"wrench_repair","repair":"heal","heal":"heal","flash":"flash","explosion":"explosion","deploy":"deploy","door":"door","skill":"skill","smoke":"smoke"}.get(kind,"")
	if kind=="heal":sound="link_fire"
	# 1.4.2: the beam's own connect sound and hum (HealingStream) replace the
	# repeated short cue, except for the optional vocal alternative.
	if kind in ["heal","repair"] and not audio_bank.profile.get("gunfire_reduction",false):sound=""
	if kind=="shot":sound="gun_"+(players[owner].primary if players[owner].slot==0 else players[owner].secondary) if players.has(owner) else "gun_a1"
	if kind not in ["heal","repair"] or clock-float(heal_sound_times.get(owner,-100))>.22:
		if not sound.is_empty() and (kind not in ["heal","repair","melee_repair"] or owner==local_id):play_sound(sound,from,owner!=local_id or kind in ["explosion","flash","smoke","turret_break","cover_break"])
		if kind in ["heal","repair"]:heal_sound_times[owner]=clock
	if kind in ["shot","heal","repair"] and arena:
		if actors.has(owner) and players[owner].alive and players[owner].slot<2:from=actors[owner].visual_muzzle()
		if kind in ["heal","repair"]:combat_fx.healing_link(self,from,to,owner,int(shot_state.get("target",0)),kind=="repair")
		else:
			var ends=shot_state.get("pellets",[to])
			for point in ends:combat_fx.beam(from,point)
			combat_fx.muzzle_light(from)
	elif arena and kind=="throw":combat_fx.throw_item(from,to)
	elif arena:
		var color=Color("78e1cb") if players.has(owner) and players[owner].team==0 else Color("ffd190")
		if kind=="skill" and players.has(owner):combat_fx.skill_burst(int(players[owner].role),from,color)
		else:combat_fx.burst(kind,from,color)
	if actors.has(owner) and kind=="shot":actors[owner].show_shot(shot_at if shot_at> -100 else clock)
@rpc("authority","call_local","reliable",2)
func event_fx(kind:String,from:Vector3,to:Vector3,owner:int):
	effect(kind,from,to,owner)
@rpc("authority","call_local","reliable",2)
func reload_sound(id:int,key:String):
	if actors.has(id):play_sound(key,actors[id].position,id!=local_id)
func play_sound(kind:String,pos:Vector3,spatial:bool):
	if dedicated or demo_mode or not is_instance_valid(audio_bank):return
	audio_bank.play(kind,pos,spatial)
@rpc("authority","call_local","unreliable",2)
func step_sound(pos:Vector3,id:int,surface:String,variant:int,gain:float):
	if dedicated or demo_mode:return
	audio_bank.play("step_"+surface+"_"+str(variant%4),pos,id!=local_id,gain)
@rpc("authority","call_local","unreliable",2)
func impact(pos:Vector3,push:Vector3,eliminated:bool,team:int,role:int=0,variant:int=0,facing:float=0.,crouched:bool=false,victim:int=0,velocity:Vector3=Vector3.ZERO,point:Vector3=Vector3.INF):
	if dedicated or arena==null:return
	if eliminated:
		var source=actors[victim].character if actors.has(victim) else null
		combat_fx.ragdoll(source,pos,push,role,team,facing,crouched,velocity,point)
	else:
		combat_fx.armor_impact(pos,push,Color("79d9ff") if team==0 else Color("ffd07a"))
		var floor_hit=ray(pos,pos-Vector3.UP*4,[],1)
		if not floor_hit.is_empty() and floor_hit.normal.y>.65:combat_fx.scuff(floor_hit.position+Vector3.UP*.012)

@rpc("authority","call_local","reliable",2)
func damage_notice(target:int,origin:Vector3,amount:float,armored:bool):
	if dedicated or target!=local_id or not actors.has(target):return
	var direction=origin-actors[target].position
	if is_instance_valid(ui.damage_indicator):ui.damage_indicator.register_hit(direction,amount,Time.get_ticks_msec()/1000.)
	var now=Time.get_ticks_msec()/1000.
	var female=int(players[target].role) in HeroCharacter.FEMALE_ROLES
	play_sound("armor_hurt_female" if armored and female else "hurt_female" if female else "armor_hurt" if armored else "hurt",Vector3.ZERO,false);last_hurt_sound=now

@rpc("authority","call_local","unreliable",2)
func flesh_hit(point:Vector3,push:Vector3,amount:float,victim:int,shooter:int=0):
	if dedicated or not is_instance_valid(arena):return
	combat_fx.blood_hit(point,push,amount)
	if shooter==local_id and victim!=local_id:play_sound("body_impact",point,false)
	if actors.has(victim):actors[victim].hit_time=clock

func cycle_spectator():
	if not players.has(local_id) or players[local_id].alive:return
	var ids=[]
	for id in players:
		if id!=local_id and players[id].alive and (int(options.mode)==1 or players[id].team==players[local_id].team):ids.append(id)
	if ids.is_empty():spectator_target=0;return
	spectator_target=ids[(ids.find(spectator_target)+1)%ids.size()]
func update_spectator():
	if is_instance_valid(kill_replay) and kill_replay.active:return
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
func wall_marks_batch(hits:Array):
	for hit in hits:wall_mark(hit.pos,hit.normal,bool(hit.get("scorch",false)))
@rpc("authority","call_local","unreliable",2)
func melee_mark(pos:Vector3,normal:Vector3,direction:Vector3,wrench:bool):
	if dedicated or arena==null:return
	var mark=MeleeMark.make(RenderStyle.web(),wrench)
	add_child(mark);mark.position=pos+normal*.005
	var tangent=direction.cross(Vector3.UP);tangent-=normal*tangent.dot(normal)
	if tangent.length_squared()<.001:tangent=normal.cross(Vector3.RIGHT if absf(normal.x)<.9 else Vector3.FORWARD)
	tangent=tangent.normalized();mark.basis=Basis(tangent,normal.normalized(),tangent.cross(normal).normalized())
	register_wall_mark(mark)
func register_wall_mark(mark:MeshInstance3D):
	wall_marks.append(mark);trim_wall_marks()
	if RenderStyle.web():mark.set_meta("expires_msec",Time.get_ticks_msec()+int(web_mark_lifetime(Engine.get_frames_per_second())*1000.))
static func web_mark_lifetime(fps:float) -> float:return 1.0 if fps>0 and fps<30. else 1.5 if fps>0 and fps<45. else 2.5
func expire_web_marks():
	if not RenderStyle.web() or wall_marks.is_empty():return
	var now=Time.get_ticks_msec()
	for mark in wall_marks.duplicate():
		if not is_instance_valid(mark):wall_marks.erase(mark)
		elif now>=int(mark.get_meta("expires_msec",now+2500)):wall_marks.erase(mark);mark.queue_free()
func trim_wall_marks():
	while wall_marks.size()>(64 if RenderStyle.web() else 128):
		var first=wall_marks.pop_front()
		if is_instance_valid(first):first.queue_free()

@rpc("authority","call_local","unreliable",2)
func wall_mark(pos:Vector3,normal:Vector3,scorch:bool=false):
	if dedicated or arena==null:return
	var mark=BulletMark.make(RenderStyle.web(),scorch)
	add_child(mark);mark.position=pos+normal*.004;mark.quaternion=Quaternion(Vector3.UP,normal.normalized());mark.rotate_object_local(Vector3.UP,randf()*TAU);register_wall_mark(mark)

func begin_slide(id:int,forward:bool=false,direction:Vector2=Vector2.ZERO) -> bool:
	if not players.has(id) or phase!="combat":return false
	var p=players[id];var a=actors[id];var velocity=Vector3(a.velocity.x,0,a.velocity.z)
	if not p.alive or p.shield>clock or p.slow>clock or p.get("cooking",0)>0 or not a.is_on_floor() or (not forward and direction.length()<.5 and velocity.length()<.5) or clock<float(p.get("slide_ready",0)):return false
	if direction.length()>=.5:velocity=Basis(Vector3.UP,a.aim_yaw)*Vector3(direction.x,0,direction.y).normalized()
	elif forward:velocity=Basis(Vector3.UP,a.aim_yaw)*Vector3.FORWARD
	p.slide_until=clock+R.SLIDE_DURATION;p.slide_ready=clock+1.8;p.slide_direction=velocity.normalized();p.slide_started=clock
	effect.rpc("slide",a.position,Vector3.ZERO,id,clock)
	return true
