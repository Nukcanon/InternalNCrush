extends SceneTree
var peer:WebSocketMultiplayerPeer
var elapsed=0.
func _initialize():call_deferred("run")
func run():
	if not OS.get_environment("INC_TEST_CA").is_empty():ProjectSettings.set_setting("network/tls/certificate_bundle_override",OS.get_environment("INC_TEST_CA"))
	peer=WebSocketMultiplayerPeer.new();peer.handshake_timeout=4.
	if peer.create_client(OS.get_environment("INC_TEST_URL"))!=OK:print("TLS_REJECT_PASS");quit();return
func _process(dt):
	if peer==null:return false
	elapsed+=dt;peer.poll()
	if peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:print("FAIL untrusted TLS connected");peer.close();quit(1)
	elif peer.get_connection_status()==MultiplayerPeer.CONNECTION_DISCONNECTED and elapsed>.1:print("TLS_REJECT_PASS");quit()
	elif elapsed>8.:print("FAIL TLS rejection timed out");quit(1)
	return false
