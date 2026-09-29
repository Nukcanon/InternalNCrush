class_name VisualWarmup
extends Node
## Builds held-item templates before they are first needed in combat. Each
## template costs one procedural build; later selections only instantiate it.
var game:Node
var elapsed=0.
var done={}
func _process(dt:float):
	if not is_instance_valid(game) or game.dedicated or game.demo_mode or not game.render_actors:return
	elapsed+=dt
	# One build per tick outside combat; in combat only rarely, as a fallback.
	var interval=.12 if game.phase in ["lobby","buy","round_end","result"] else 2.5
	if game.phase=="menu" or elapsed<interval:return
	elapsed=0.
	for request in pending():
		var key=str(request)
		if done.has(key):continue
		done[key]=true
		GadgetVisual.prepare(request[1],request[2],request[3],request[4])
		return
func pending() -> Array:
	var list=[]
	var ids=game.players.keys();ids.sort_custom(func(a,b):return a==game.local_id and b!=game.local_id)
	for id in ids:
		var p=game.players[id];var role=int(p.role) if game.options.classes else 0;var gadget=int(p.get("gadget",0))
		list.append(["gadget",role,gadget,false,false])
		if id==game.local_id:list.append(["gadget",role,gadget,true,false])
		if role==3:
			list.append(["gadget",role,gadget,false,true])
			if id==game.local_id:list.append(["gadget",role,gadget,true,true])
	return list
