extends SceneTree
var g:Node
var started=0
var ticks=0
var start_sent=false
var done=false
func _initialize():call_deferred("run")
func run():
	var config=JSON.parse_string(OS.get_environment("INC_TEST_JOIN"))
	# Private test CA only; the shipped client keeps Godot's default trust store.
	if not OS.get_environment("INC_TEST_CA").is_empty():ProjectSettings.set_setting("network/tls/certificate_bundle_override",OS.get_environment("INC_TEST_CA"))
	g=load("res://scripts/game.gd").new();g.name="Game";root.add_child(g);g.input_timer=1e6;g.profile.nick="PUBLIC_TEST";g.profile.token="untrusted_local_profile_token"
	g.join_ticket=config.ticket;g.join_game(config.url);started=Time.get_ticks_msec();physics_frame.connect(drive)
func drive():
	if done:return
	if Time.get_ticks_msec()-started>25000:done=true;print("PUBLIC_TIMEOUT phase=",g.phase," peers=",g.players.size());quit(1);return
	if not g.players.has(g.local_id):return
	if g.phase=="lobby" and g.players.size()>=2 and not start_sent:
		g.command("start",{});start_sent=true
	if g.phase!="combat":return
	var p=g.players[g.local_id];var a=g.actors[g.local_id]
	if not p.alive or p.protect>g.clock:return
	ticks+=1
	a.input_state.fire=true;a.input_state.yaw=.4;a.input_state.pitch=-.2
	if ticks%2==0:g.send_input.rpc_id(1,a.input_state)
	if ticks>180 and int(p.mag.get(p.primary,30))<30 and g.players.size()>=2:
		print("PUBLIC_PASS players=",g.players.size()," phase=",g.phase," ammo=",p.mag[p.primary]," secure_identity=",not p.has("token")," ping=",g.ping_ms)
		done=true;await g.request_leave();g.queue_free();await process_frame;quit()
