extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	Catalog.load_all()
	var options=Rules.default_options();options.mode=4;options.map=19;options.map_random=false
	expect(options.bomb_seconds==45 and options.buy_seconds==60,"default bomb and post-preparation purchase timers")
	for pair in [[-1,30],[29,30],[45,45],[120,120],[999,120]]:
		options.bomb_seconds=pair[0];Rules.sanitize_room(options);expect(options.bomb_seconds==pair[1],"bounded detonation timer")
	options.round_minutes=1;options.buy_seconds=300;Rules.sanitize_room(options);expect(options.buy_seconds==60,"purchase cannot exceed round duration")
	options.round_minutes=10;options.buy_seconds=999;Rules.sanitize_room(options);expect(options.buy_seconds==300,"purchase capped to five minutes")
	options.buy_seconds=-10;Rules.sanitize_room(options);expect(options.buy_seconds==0,"zero disables combat purchases")
	options.bomb_seconds=72;options.buy_seconds=91
	var wire=ModeOptions.network(options);expect(wire.bomb_seconds==72 and wire.buy_seconds==91,"both room timers survive network contract")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.phase="lobby";g.options=options
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(80,80);g.arena.has_water=false;g.arena.sites=[Vector3(10,0,10),Vector3(-10,0,-10)]
	g.add_player(1,"Carrier","one");g.add_player(2,"Defender","two");g.players[1].team=0;g.players[2].team=1;g.clock=100.;g.start_match()
	var p=g.players[1];var q=g.players[2];p.cash=8000;p.protect=0.;q.protect=0.
	expect(DefusalEconomy.can_buy(g,1),"preparation permits purchases separately")
	for i in range(20):
		BombLogic.assign(g);expect(g.bomb.carrier==1,"only an attacking living player can receive bomb")
	g.ui.gear();await process_frame
	expect(g.ui.gear_cash.text=="8000" and g.ui.gear_cash.get_theme_color("font_color")==Color("ffda73"),"large yellow balance in store")
	expect(g.ui.gear_cash.get_parent().get_parent() is PanelContainer and g.ui.gear_price.get_parent().get_parent() is PanelContainer,"separate rectangular balance and cost boxes")
	expect(g.ui.gear_cash.get_theme_font_size("font_size")==32 and g.ui.gear_price.get_theme_font_size("font_size")==32,"large matching price typography")
	g.ui.exit_gear();g.phase="combat";g.bomb.buy_until=g.clock+60.;g.actors[1].position=Vector3.ZERO
	var chosen={"role":0,"primary":"a1","secondary":"pistol","armor":0,"gadget":8,"confirmed":true}
	var cost=DefusalEconomy.cost(p,chosen);g.apply_loadout(1,chosen)
	expect(p.primary=="a1" and p.cash==8000-cost and p.pending_loadout.is_empty(),"combat-window purchase is charged and immediately equipped")
	g.clock+=60.;var before=p.cash;chosen.primary="a2";g.apply_loadout(1,chosen)
	expect(p.primary=="a1" and p.cash==before,"authority rejects purchase at deadline")
	g.bomb.buy_until=g.clock+10.;p.alive=false;expect(not DefusalEconomy.can_buy(g,1),"dead player cannot buy gear")
	p.alive=true;g.bomb.carrier=1
	expect(BombLogic.hint(g,1)=="폭탄 보유 중","carrier hint outside site")
	g.actors[1].position=Vector3(11,0,10)
	expect(BombLogic.hint(g,1).begins_with("E키를 눌러 폭탄 설치"),"plant hint replaces carrier hint inside site")
	expect(not BombLogic.hint(g,2).contains("설치"),"non-carrier never receives plant prompt")
	g.actors[1].input_state.use=true;expect(not DefusalEconomy.can_buy(g,1),"cannot buy while operating bomb")
	for i in range(185):g.interact(1,1./60.)
	expect(g.bomb.planted and g.bomb.time==72. and g.bomb.total_time==72.,"configured fuse is authoritative at actual plant point")
	expect(BombLogic.hint(g,1).is_empty(),"carrier banner disappears after planting")
	g.actors[2].position=g.bomb.position+Vector3.RIGHT;q.gadget=9;q.owned_gadget=false
	expect(BombLogic.defuse_seconds(q)==15. and BombLogic.hint(g,2).contains("15초"),"unowned kit cannot shorten defuse")
	g.bomb.actor=0;g.bomb.progress=0.;g.interact(2,14.9);expect(not g.bomb.get("defused",false),"ordinary defuse requires full fifteen seconds")
	g.interact(2,.11);expect(g.bomb.defused,"ordinary defuse completes at fifteen seconds")
	g.phase="combat";g.bomb.defused=false;g.bomb.actor=0;g.bomb.progress=0.;q.owned_gadget=true
	expect(BombLogic.defuse_seconds(q)==5. and BombLogic.hint(g,2).contains("5초"),"owned kit matches five-second HUD")
	g.interact(2,4.9);expect(not g.bomb.defused,"kit also requires full timer");g.interact(2,.11);expect(g.bomb.defused,"kit completes at five seconds")
	g.phase="combat";g.bomb.planted=false;g.bomb.defused=false;g.bomb.carrier=1;g.actors[1].position=Vector3.ZERO
	BombLogic.tap(g,1);g.clock+=.2;BombLogic.tap(g,1);expect(g.bomb.dropped and g.bomb.carrier==0,"rapid double E drops outside site")
	g.ui.show_hud();g.bomb.carrier=2;g.actors[2].aim_yaw=.65;g.combat_fx.sync_bomb(g)
	var normal=g.combat_fx.bomb_visual.basis.y.normalized();var back=Basis(Vector3.UP,.65)*Vector3.BACK
	expect(normal.dot(back)>.99,"carrier bomb top and red beacon face outward from back")
	g.ui.refresh();expect(g.ui.cash_hint.visible and g.ui.cash_hint.get_theme_font_size("font_size")==28,"in-game money visible with larger text")
	g.leave_game();g.queue_free();await process_frame
	print("RESULT defusal_v124 ",checks-failures,"/",checks);quit(1 if failures else 0)
