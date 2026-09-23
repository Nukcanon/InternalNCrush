extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",message)
func sign_ticket(room:PublicRoom,claims:Dictionary) -> String:
	var encoded=Marshalls.utf8_to_base64(JSON.stringify(claims));var signature=Crypto.new().hmac_digest(HashingContext.HASH_SHA256,str(room.config.key).to_utf8_buffer(),encoded.to_utf8_buffer()).hex_encode()
	return encoded+"."+signature
func run():
	var valid={"x":0.,"z":1.,"yaw":0.,"pitch":0.,"trigger_seq":1,"fire":true}
	expect(not InputGuard.normalize(valid).is_empty(),"ordinary player input accepted")
	for key in ["x","z","yaw","pitch"]:
		for value in [NAN,INF,{},[],"1"]:
			var bad=valid.duplicate();bad[key]=value;expect(InputGuard.normalize(bad).is_empty(),"malformed numeric input rejected: "+key)
	for value in [-1,2147483648,{},"1",1.2]:
		var bad=valid.duplicate();bad.trigger_seq=value;expect(InputGuard.normalize(bad).is_empty(),"malformed trigger sequence rejected")
	for key in ["fire","ads","sprint","jump","use","alt","crouch"]:
		var bad=valid.duplicate();bad[key]={};expect(InputGuard.normalize(bad).is_empty(),"non-boolean action rejected: "+key)
	var clamped=valid.duplicate();clamped.x=100.;clamped.pitch=100.;var normalized=InputGuard.normalize(clamped)
	expect(normalized.x==1. and normalized.pitch==1.45,"movement and view inputs clamped on server")
	var room=PublicRoom.new();root.add_child(room);room.enabled=true;room.set_process(false);room.config={"key":Crypto.new().generate_random_bytes(32).hex_encode(),"room_id":"test_room"}
	var claims={"room":"test_room","uid":"0123456789abcdef0123456789abcdef","nonce":"fedcba9876543210fedcba9876543210","exp":Time.get_unix_time_from_system()+30,"nick":"Test","owner":false}
	var ticket=sign_ticket(room,claims)
	expect(not room.verify(ticket).is_empty(),"signed short-lived admission ticket accepted")
	expect(room.verify(ticket).is_empty(),"same admission ticket cannot be replayed")
	claims.nonce="11111111111111111111111111111111";ticket=sign_ticket(room,claims)
	expect(room.verify(ticket.left(-1)+("0" if not ticket.ends_with("0") else "1")).is_empty(),"modified signature rejected")
	claims.exp=Time.get_unix_time_from_system()-1;expect(room.verify(sign_ticket(room,claims)).is_empty(),"expired admission rejected")
	claims.exp=Time.get_unix_time_from_system()+3600;expect(room.verify(sign_ticket(room,claims)).is_empty(),"excessively long ticket lifetime rejected")
	claims.exp=Time.get_unix_time_from_system()+30;claims.room="another_room";expect(room.verify(sign_ticket(room,claims)).is_empty(),"cross-room admission rejected")
	room.free();print("NETWORK_SECURITY_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
