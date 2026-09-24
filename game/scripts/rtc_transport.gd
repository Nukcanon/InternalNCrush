class_name RtcTransport
extends Node
## TLS signaling only; encrypted WebRTC data channels carry the authoritative match.
var game:Node
var socket:WebSocketPeer
var peer:WebRTCMultiplayerPeer
var connections={}
var identities={}
var pending_ice={}
var descriptions={}
var admission={}
var active=false
var sent_auth=false
var signaled=false
var timer=0.
var deadline=0
var local_uid=""
var scope="internet"
const CHANNELS=[MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED,MultiplayerPeer.TRANSFER_MODE_RELIABLE,MultiplayerPeer.TRANSFER_MODE_UNRELIABLE]

func begin(value:Dictionary,endpoint:String):
	close();admission=value;local_uid=str(value.uid);scope=str(value.room.get("scope","internet"))
	var url=endpoint.replace("https://","wss://").replace("http://","ws://")+str(value.signal_path)
	socket=WebSocketPeer.new();socket.inbound_buffer_size=262144;socket.outbound_buffer_size=262144;socket.max_queued_packets=256
	var error=socket.connect_to_url(url)
	if error!=OK:game.ui.notice("로비 연결을 시작하지 못했습니다.");socket=null;return
	active=true;deadline=Time.get_ticks_msec()+25000;game.connection_busy=true;game.connection_deadline=deadline
	game.ui.notice("방장과 암호화된 연결을 준비합니다…")

func close():
	active=false;signaled=false;sent_auth=false;timer=0.
	if socket:socket.close()
	if peer:peer.close()
	socket=null;peer=null;connections.clear();identities.clear();pending_ice.clear();descriptions.clear();admission.clear();local_uid=""

func send(value:Dictionary):
	if socket and socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(value))

func make_connection(id:int,offer:bool):
	if connections.has(id):return
	var connection=WebRTCPeerConnection.new()
	if connection.initialize({"iceServers":admission.get("ice_servers",[])})!=OK:
		game.leave_game("WebRTC 통신 모듈을 초기화하지 못했습니다.");return
	connections[id]=connection;pending_ice[id]=[]
	connection.session_description_created.connect(func(type,sdp):
		connection.set_local_description(type,sdp);send({"op":"sdp","to":id,"type":type,"sdp":sdp}))
	connection.ice_candidate_created.connect(func(mid,index,candidate):send({"op":"ice","to":id,"mid":mid,"index":index,"candidate":candidate}))
	peer.add_peer(connection,id,100)
	if offer:connection.create_offer()

func receive(value:Dictionary):
	match str(value.get("op","")):
		"ready":
			var id=int(value.get("peer",0))
			if id!=int(admission.peer):return
			peer=WebRTCMultiplayerPeer.new();signaled=true
			if id==1:
				peer.create_server(CHANNELS);game.connection_busy=false
				var options:Dictionary=admission.room
				game.options.merge({"room":options.name,"mode":int(options.mode),"map":int(options.map),"max_players":int(options.capacity),"map_size":Rules.MAP_PLAYERS[int(options.map)],"map_random":bool(options.map_random),"map_rotation":bool(options.map_rotation),"rounds":int(options.rounds),"prep_seconds":int(options.prep_seconds),"bots":0},true)
				game.host_game(peer)
			else:
				peer.create_client(id,CHANNELS);game.begin_rtc_client(peer);make_connection(1,false)
		"peer":
			if int(admission.get("peer",0))!=1:return
			var id=int(value.get("peer",0))
			if id<2 or identities.size()>=32:return
			identities[id]={"uid":str(value.get("uid","")),"nick":str(value.get("nick","Player"))};make_connection(id,true)
		"sdp":
			var id=int(value.get("from",0))
			if not connections.has(id):return
			var connection:WebRTCPeerConnection=connections[id]
			if connection.set_remote_description(str(value.type),str(value.sdp))==OK:
				descriptions[id]=true
				for item in pending_ice[id]:connection.add_ice_candidate(item.mid,int(item.index),item.candidate)
				pending_ice[id].clear()
		"ice":
			var id=int(value.get("from",0))
			if not connections.has(id):return
			if descriptions.has(id):connections[id].add_ice_candidate(str(value.mid),int(value.index),str(value.candidate))
			elif pending_ice[id].size()<80:pending_ice[id].append(value)
		"left":
			var id=int(value.get("peer",0))
			if peer and peer.has_peer(id):peer.remove_peer(id)
			connections.erase(id);identities.erase(id);pending_ice.erase(id);descriptions.erase(id)
		"ping":send({"op":"pong","nonce":value.get("nonce",0)})
		"closed":game.leave_game(str(value.get("reason","방장이 방을 종료했습니다.")))

func _process(dt:float):
	if not active or socket==null:return
	socket.poll()
	var state=socket.get_ready_state()
	if state==WebSocketPeer.STATE_OPEN:
		if not sent_auth:sent_auth=true;send({"ticket":admission.ticket});admission.ticket=""
		while socket and socket.get_available_packet_count()>0:
			var packet=socket.get_packet()
			if packet.size()>24000:continue
			var value=JSON.parse_string(packet.get_string_from_utf8())
			if value is Dictionary:receive(value)
		timer-=dt
		if signaled and timer<=0.:
			timer=8.;send({"op":"keepalive"})
			if game.server:send({"op":"status","phase":game.phase,"map":int(game.options.map),"players":game.players.size()})
		if signaled and game.server and admission.get("automatic",false) and game.phase=="lobby" and game.players.size()>=2:game.start_match()
	elif state==WebSocketPeer.STATE_CLOSED:
		if game.phase=="menu":game.leave_game("로비 연결이 종료되었습니다. 서버 주소와 네트워크를 확인하세요.")
		else:game.ui.notice("로비 서버 연결이 끊겼습니다. 현재 직접 연결 경기는 유지됩니다.");socket=null
	if active and game.phase=="menu" and Time.get_ticks_msec()>deadline:
		game.leave_game("방장에게 연결하지 못했습니다. 다른 방을 시도하거나 로비 서버의 TURN 구성을 확인하세요.")
