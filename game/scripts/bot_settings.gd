extends RefCounted
class_name BotSettings

static func allowed(g:Node,requester:int) -> bool:
	return g.players.has(requester) and (TeamBalance.host(g,requester) or (g.options.get("practice",false) and requester==g.local_id))

static func change(g:Node,requester:int,data:Dictionary) -> bool:
	var id=int(data.get("player_id",0))
	if not g.server or not allowed(g,requester) or id>=0 or not g.players.has(id) or not g.bot_agents.has(id):return false
	var p=g.players[id]
	var difficulty=int(data.get("difficulty",p.get("bot_difficulty",g.bot_agents[id].difficulty)))
	var role=int(data.get("role",p.get("bot_role",p.role)))
	if difficulty not in [0,1,2] or role<0 or role>=Rules.CLASSES.size():return false
	if data.has("role") and not g.options.classes:return false
	if data.has("role") and role==5 and p.role!=5 and g.medic_count(p.team)>=Rules.medic_cap(g.team_count(p.team)):
		g.feedback(requester,"","이 팀의 메딕 정원이 찼습니다.",true);return false
	p.bot_difficulty=difficulty;g.bot_agents[id].difficulty=difficulty
	if data.has("role"):
		p.bot_role=role
		# A live bot keeps its current equipment until its next legitimate spawn.
		if g.phase=="lobby" or not p.alive:apply_role(g,id)
		elif role!=int(p.role):g.feedback(requester,"","봇 병과는 다음 부활부터 적용됩니다.",true)
	g.broadcast_state(true)
	return true

static func apply_role(g:Node,id:int):
	if id>=0 or not g.players.has(id):return
	var p=g.players[id]
	if not p.has("bot_role") or int(p.bot_role)==int(p.role):return
	var role=int(p.bot_role)
	if role==5 and g.medic_count(p.team)>=Rules.medic_cap(g.team_count(p.team)):return
	for did in g.devices.keys():
		if int(g.devices[did].owner)==id and g.devices[did].kind=="turret":g.remove_device(did)
	var elapsed=g.clock-(float(p.skill_ready)-AbilityBalance.COOLDOWNS[int(p.role)])
	if p.skill_ready>0.:p.skill_ready=g.clock+maxf(0.,AbilityBalance.COOLDOWNS[role]-elapsed)
	if role==5:p.skill_ready=maxf(p.skill_ready,float(p.get("initial_skill_until",g.clock+30.)))
	p.role=role;p.primary=Catalog.first(role);p.secondary=Rules.SECONDARIES[role];p.slot=0;p.reload=0.;p.pending_loadout={}
	p.gadget=0;GadgetLoadout.reset(p)
	p.owned_primary=true;p.owned_secondary=true
	if int(g.options.mode)==4:
		DefusalEconomy.reset(p)
	g.equip_ammo(p)

static func controls(g:Node,parent:Node,p:Dictionary):
	if int(p.id)>=0 or not allowed(g,g.local_id):return
	var role=OptionButton.new();role.name="BotRole";role.custom_minimum_size=Vector2(118,38);role.add_theme_font_size_override("font_size",16)
	for title in Rules.CLASSES:role.add_item(title)
	role.select(int(p.get("bot_role",p.role)));role.disabled=not g.options.classes;role.tooltip_text="봇 병과 · 전투 중 변경은 다음 부활에 적용"
	role.item_selected.connect(func(i):g.command("bot_settings",{"player_id":int(p.id),"role":i}))
	parent.add_child(role)
	var level=OptionButton.new();level.name="BotDifficulty";level.custom_minimum_size=Vector2(74,38);level.add_theme_font_size_override("font_size",16)
	for title in ["하","중","상"]:level.add_item(title)
	level.select(int(p.get("bot_difficulty",g.options.get("bot_difficulty",2))));level.tooltip_text="이 봇의 난이도"
	level.item_selected.connect(func(i):g.command("bot_settings",{"player_id":int(p.id),"difficulty":i}))
	parent.add_child(level)
