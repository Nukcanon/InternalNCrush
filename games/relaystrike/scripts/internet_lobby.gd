extends Node
class_name InternetLobby
var game:Node
var endpoint=""
var token=""
var busy=false
var error=""
var pending=""
func valid_endpoint(url:String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://127.0.0.1:")
func request(path:String,data:Variant=null) -> Dictionary:
	if busy:return {"error":"이전 요청을 처리 중입니다."}
	if not valid_endpoint(endpoint):return {"error":"HTTPS 서버 주소를 입력하세요."}
	busy=true;var http=HTTPRequest.new();http.timeout=12.;http.body_size_limit=65536;add_child(http)
	var headers=PackedStringArray(["Content-Type: application/json"])
	if not token.is_empty():headers.append("Authorization: Bearer "+token)
	var result=http.request(endpoint+path,headers,HTTPClient.METHOD_GET if data==null else HTTPClient.METHOD_POST,"" if data==null else JSON.stringify(data))
	if result!=OK:http.queue_free();busy=false;return {"error":"요청을 시작할 수 없습니다."}
	var response=await http.request_completed;http.queue_free();busy=false
	if response[0]!=HTTPRequest.RESULT_SUCCESS:return {"error":"서버 연결을 확인하세요. HTTPS 인증서와 주소가 필요합니다."}
	var value=JSON.parse_string(response[3].get_string_from_utf8())
	if not value is Dictionary:return {"error":"서버 응답 형식이 올바르지 않습니다."}
	if int(response[1])>=400:
		if int(response[1])==401:token=""
		return {"error":str(value.get("detail","요청 실패"))}
	return value
func connect_service(url:String) -> Dictionary:
	endpoint=url.strip_edges().trim_suffix("/");token=""
	var value=await request("/v1/sessions",{"nick":game.profile.nick,"version":Rules.VERSION})
	if value.has("token"):token=value.token;game.profile.lobby_url=endpoint;game.save_profile()
	return value
func join(room_id:String) -> Dictionary:
	var value=await request("/v1/rooms/"+room_id+"/join",{})
	if value.has("ticket"):enter(value)
	return value
func matchmake(mode:int) -> Dictionary:
	var value=await request("/v1/match",{"mode":null if mode<0 else mode})
	if value.has("ticket"):enter(value)
	elif value.get("pending",false):pending=value.room.id
	return value
func enter(value:Dictionary):
	var url=str(value.get("url",""))
	if not url.begins_with("wss://") and not (endpoint.begins_with("http://127.0.0.1:") and url.begins_with("ws://127.0.0.1:")):
		game.ui.notice("암호화된 게임 주소가 필요합니다.");return
	game.options.password="";game.join_ticket=str(value.ticket);game.join_game(url)
