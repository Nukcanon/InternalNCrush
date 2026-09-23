extends Node
class_name PublicRoom
var game:Node
var config={}
var used={}
var owner_peer=0
var http:HTTPRequest
var timer=0.
var busy=false
var lobby_age=0.
var enabled=false
func configure(g:Node):
	game=g
	var value=JSON.parse_string(OS.get_environment("INC_ROOM_CONFIG"))
	if not value is Dictionary or str(value.get("key","")).length()!=64:return
	config=value;enabled=true
	game.options.merge(config.options,true);Rules.sanitize_room(game.options)
	http=HTTPRequest.new();http.timeout=4.;add_child(http)
func verify(ticket:String) -> Dictionary:
	if not enabled or ticket.length()>1024:return {}
	var parts=ticket.split(".")
	if parts.size()!=2 or parts[1].length()!=64:return {}
	var digest=Crypto.new().hmac_digest(HashingContext.HASH_SHA256,str(config.key).to_utf8_buffer(),parts[0].to_utf8_buffer())
	if not Crypto.new().constant_time_compare(digest.hex_encode().to_utf8_buffer(),parts[1].to_utf8_buffer()):return {}
	var claims=JSON.parse_string(Marshalls.base64_to_utf8(parts[0]))
	if not claims is Dictionary:return {}
	var now=Time.get_unix_time_from_system()
	if claims.get("room","")!=config.room_id or float(claims.get("exp",0))<now or float(claims.get("exp",0))>now+35:return {}
	if str(claims.get("uid","")).length()!=32 or str(claims.get("nonce","")).length()!=32 or used.has(claims.nonce):return {}
	used[claims.nonce]=claims.exp
	return claims
func accepted(peer:int,claims:Dictionary):
	if claims.get("owner",false) and claims.uid==config.owner:owner_peer=peer
func can_start(peer:int) -> bool:return peer==owner_peer
func _process(dt:float):
	if not enabled or not game.server:return
	if game.phase=="lobby":
		lobby_age+=dt
		if bool(config.get("automatic",false)) and game.players.size()>=2 and lobby_age>3.:game.start_match()
	timer-=dt
	if timer>0. or busy:return
	timer=2.;busy=true
	var roster=[]
	for p in game.players.values():
		if p.id>0:roster.append(p.token)
	var now=Time.get_unix_time_from_system()
	for nonce in used.keys():
		if float(used[nonce])<now:used.erase(nonce)
	var body=JSON.stringify({"players":roster,"phase":game.phase})
	var error=http.request(str(config.api)+"/internal/rooms/"+str(config.room_id)+"/heartbeat",PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+str(config.key)]),HTTPClient.METHOD_POST,body)
	if error==OK:await http.request_completed
	busy=false
