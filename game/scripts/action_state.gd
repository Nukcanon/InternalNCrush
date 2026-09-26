class_name ActionState
extends RefCounted
## UI availability mirrors server rules. The server still validates every action.
static func available(game:Node,id:int,action:String) -> bool:
	var p=game.players.get(id,{})
	if p.is_empty() or not game.actors.has(id):return false
	if action in ["menu","score","gear","auto_fire"]:return true
	if action=="fire" and not p.alive:return true # Replay skip / spectator cycle.
	if not p.alive:return false
	var a=game.actors[id];var combat=game.phase=="combat" and game.can_attack(p)
	var now=float(game.clock);var w=game.current_weapon(p)
	if action.begins_with("slot"):
		var slot=int(action.trim_prefix("slot"))
		return slot==MeleeCombat.SLOT or slot<2 or (game.options.classes and slot==2)
	match action:
		"melee":return MeleeCombat.ready(game,p)
		"skill":
			if p.get("placing","")=="turret":return combat
			var state=AbilityBalance.skill_state(game,id)
			return state.enabled and state.remaining<=0.
		"gadget":
			if p.get("placing","")=="cover":return combat
			if not combat or not game.options.classes or p.gadget==9 or MarkerTracker.equipped(p):return false
			if p.get("cooking",0)>0:return true
			if p.gadget_count<=0 or p.gadget_ready>now:return false
			if p.role==0 and not GrenadeLogic.equipped(p):return p.armor<50
			if GrenadeLogic.equipped(p):return GrenadeLogic.remaining(p)>0
			if p.role==2:return false
			if p.role==3:
				return game.devices.values().filter(func(d):return d.kind=="cover" and int(d.owner)==id).size()<2
			if p.role==4:return p.flash_count>0 if p.gadget==1 else p.smoke>0
			if p.role==5:
				var target=game.aim_player(id,4.,true)
				return game.players[target if target else id].hp<100.
			return true
		"bomb":return not BombLogic.action(game,id).is_empty()
		"gadget_mode":return false
		"reload":
			var wid=p.primary if p.slot==0 else p.secondary
			return combat and p.slot<2 and w.kind=="gun" and p.reload<=0 and int(p.mag.get(wid,0))<int(w.mag) and (game.options.infinite or int(p.reserve.get(wid,0))>0)
		"fire":
			if not combat:return false
			if p.get("placing","")!="":return Deployment.candidate(game,id,p.placing).valid
			if p.get("invul_select",0)>now:return true
			if p.slot==MeleeCombat.SLOT:return MeleeCombat.ready(game,p)
			if MeleeCombat.active(p,now):return false
			if p.slot>=2:return available(game,id,"gadget")
			return p.reload<=0 and p.get("cooking",0)<=0 and (w.kind!="gun" or int(p.mag.get(p.primary if p.slot==0 else p.secondary,0))>0)
		"medical":return combat and p.role==5 and p.primary in ["m2","m3"] and p.slot==0 and p.heal_ready<=now and p.reload<=0
		"slide":return combat and a.is_on_floor() and p.shield<=now and p.slow<=now and p.get("cooking",0)<=0 and p.get("slide_ready",0)<=now
		"jump":return game.phase in ["combat","buy"] and a.is_on_floor()
		"ads":return p.slot<2 and p.reload<=0
		"sprint":return game.phase in ["combat","buy"] and p.get("cooking",0)<=0
		"use":return game.phase=="combat"
	return game.phase in ["combat","buy"]

static func equipment_ready(game:Node,id:int,slot:int) -> bool:
	if not available(game,id,"slot"+str(slot)):return false
	if slot==MeleeCombat.SLOT:return MeleeCombat.ready(game,game.players[id])
	if slot<2:return true
	var p=game.players[id]
	if p.gadget==9:return game.phase=="combat" # Passive kit, used by interaction.
	if MarkerTracker.equipped(p):return game.phase=="combat"
	if p.role==4 and not GrenadeLogic.equipped(p):
		return game.phase=="combat" and game.can_attack(p) and p.gadget_ready<=game.clock and p.gadget_count>0 and (p.flash_count>0 if p.gadget==1 else p.smoke>0)
	return available(game,id,"gadget")
