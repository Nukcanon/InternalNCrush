class_name StartupNetworkAccess
extends Node
## Prime Windows' normal app firewall decision before a player starts a match.
## Windows owns the prompt and persists its app/path rule; do not alter firewall policy.
var listener:ENetMultiplayerPeer
func begin() -> Error:
	listener=ENetMultiplayerPeer.new()
	var error=listener.create_server(0,1,1)
	if error!=OK:listener=null;return error
	var timer=Timer.new();timer.one_shot=true;timer.wait_time=5.;add_child(timer)
	timer.timeout.connect(close);timer.start()
	return OK
func close():
	if listener:listener.close();listener=null
func _exit_tree():close()
