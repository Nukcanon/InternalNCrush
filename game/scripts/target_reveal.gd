class_name TargetReveal
extends RefCounted
static func observer_key(game:Node,id:int) -> String:
	return "player:"+str(id) if int(game.options.mode)==1 else "team:"+str(game.players[id].team)
static func mark(game:Node,target:int,source:int,seconds:float):
	var p=game.players[target]
	var marks:Dictionary=p.get("reveal_to",{})
	var key=observer_key(game,source);marks[key]=maxf(float(marks.get(key,0)),game.clock+seconds)
	p.reveal_to=marks;p.mark=maxf(float(p.get("mark",0)),game.clock+seconds)
static func visible_to(game:Node,target:int,observer:int) -> bool:
	if target==observer or not game.players.has(observer) or not game.players.has(target):return false
	var p=game.players[target]
	return p.alive and p.mark>game.clock and float(p.get("reveal_to",{}).get(observer_key(game,observer),0))>game.clock
static func apply(actor:Node,p:Dictionary):
	var shown=visible_to(actor.game,actor.pid,actor.game.local_id)
	DeploymentSilhouette.apply(actor.character,{"owner":actor.game.local_id if shown else 0,"team":p.team,"level":str([p.role,actor.shown_weapon])},actor.game.local_id)
