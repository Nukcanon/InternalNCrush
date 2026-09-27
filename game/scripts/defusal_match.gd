extends RefCounted
class_name DefusalMatch
static func begin(g:Node):
	RoundCleanup.clear(g)
	if g.server and is_instance_valid(g.arena):g.arena.reset_props()
	g.round_no+=1;g.bot_attack_site=randi()%2;g.phase="buy";g.remaining=float(g.options.prep_seconds)
	g.bomb={"planted":false,"site":-1,"time":0.,"actor":0,"progress":0.,"position":Vector3.ZERO}
	var halftime=g.round_no==int(g.options.rounds)/2+1
	if g.round_no>int(g.options.rounds):g.overtime_attacker=randi()%2
	if halftime:g.losses=[0,0]
	for id in g.players:
		var p=g.players[id];p.round_bonus=0;p.lives=int(g.options.lives);p.can_respawn=p.lives>0
		if g.round_no==1 or halftime:reset_player(g,p)
		g.spawn(id)
	BombLogic.assign(g);MatchFlow.update_gate(g)
	g.announce("준비 시간 · 장비 구매"+(" · 공수 변경: 금액과 장비 초기화" if halftime else ""))
	g.call_deferred("open_buy_menu")
static func reset_player(g:Node,p:Dictionary):
	DefusalEconomy.reset(p,int(g.options.starting_cash));g.equip_ammo(p)
static func bot_buy(g:Node,id:int):
	var p=g.players[id]
	if g.phase!="buy" or p.get("owned_primary",false):return
	for wid in Catalog.list_for(int(p.role),bool(g.options.classes)):
		var d={"role":p.role,"primary":wid,"secondary":p.secondary,"armor":0,"gadget":p.gadget,"confirmed":true}
		if DefusalEconomy.cost(p,d)<=p.cash:g.commit_loadout(id,d);return
static func finish(g:Node,winner:int,reason:String):
	if g.phase!="combat":return
	g.scores[winner]+=1;g.losses[winner]=maxi(0,g.losses[winner]-1);g.losses[1-winner]+=1
	for p in g.players.values():p.cash=mini(8000,p.cash+(3500 if p.team==winner else Rules.loss_reward(g.losses[p.team])))
	g.completed_games+=1;g.winner_voice.rpc(winner)
	if g.round_no>=int(g.options.rounds) and g.scores[0]!=g.scores[1]:
		var champion=0 if g.scores[0]>g.scores[1] else 1
		g.phase="result";g.remaining=12.;g.result={"team":champion,"player":0};g.announce(("BLUE" if champion==0 else "ORANGE")+" 최종 승리")
		if champion!=winner:g.get_tree().create_timer(2.).timeout.connect(func():
			if is_instance_valid(g) and g.phase=="result":g.winner_voice.rpc(champion))
	else:g.phase="round_end";g.remaining=7.;g.announce(reason+" · "+("BLUE" if winner==0 else "ORANGE")+" 승리")
