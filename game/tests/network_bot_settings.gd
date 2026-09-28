extends SceneTree
var g:Node
var host=false
var began=0
var attempted=0
var changed=false
func _initialize():call_deferred("run")
func run():
	began=Time.get_ticks_msec();host="--bot-host" in OS.get_cmdline_user_args()
	g=load("res://scripts/game.gd").new();g.name="BotNetworkTest";root.add_child(g)
	g.options.map_random=false;g.options.map=0;g.options.bots=1;g.options.max_players=8;g.options.bot_difficulty=2
	if host:g.host_game()
	else:g.profile.token="botsettingsguest000000000000";g.profile.nick="Bot settings guest";g.join_game("127.0.0.1")
	physics_frame.connect(tick)
func tick():
	if Time.get_ticks_msec()-began>25000:printerr("FAIL bot settings network timeout");quit(1);return
	if not g.players.has(-1):return
	if host:
		if not changed and g.multiplayer.get_peers().size()>0:
			changed=BotSettings.change(g,1,{"player_id":-1,"role":2,"difficulty":0})
		if changed and (int(g.players[-1].role)!=2 or int(g.players[-1].bot_difficulty)!=0):printerr("FAIL guest mutated bot");quit(1)
	elif g.players.has(g.local_id) and int(g.players[-1].get("bot_difficulty",2))==0:
		if attempted==0:
			if int(g.players[-1].role)!=2:printerr("FAIL class not replicated");quit(1);return
			g.command("bot_settings",{"player_id":-1,"role":4,"difficulty":1});attempted=Time.get_ticks_msec()
		elif Time.get_ticks_msec()-attempted>1500:
			if int(g.players[-1].role)!=2:printerr("FAIL guest changed class");quit(1);return
			print("BOT_NETWORK_PASS host choices replicated; guest change rejected");quit()
