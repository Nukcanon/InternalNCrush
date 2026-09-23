extends RefCounted
class_name BotAgent
var game:Node
var id=0
var target=0
var visible_target=false
var last_known=Vector3.ZERO
var last_seen=-100.
var ready_to_fire=0.
var next_perception=0.
var next_decision=0.
var next_path=0.
var next_utility=0.
var next_click=0.
var goal=Vector3.ZERO
var path=PackedVector3Array()
var waypoint=0
var action="patrol"
var previous_pos=Vector3.ZERO
var progress_time=0.
var stuck_count=0
var purchase_round=-1
var ally=0
var repair_target=0
var roam_index=0
var difficulty=1
var rng=RandomNumberGenerator.new()
var stats={"repaths":0,"gadgets":0,"skills":0,"heals":0,"repairs":0,"interactions":0}
func setup(world:Node,pid:int):
	game=world;id=pid;difficulty=clampi(int(game.options.get("bot_difficulty",1)),0,2);rng.seed=abs(id)*7189+227;goal=game.arena.zones[abs(id)%3];previous_pos=game.actors[id].position;roam_index=abs(id)%5
func tick(dt:float):
	var p=game.players[id];var a=game.actors[id];var now=game.clock
	var previous_yaw=float(a.input_state.yaw)
	if target!=0 and not game.players.has(target):target=0;visible_target=false
	a.input_state.fire=false;a.input_state.alt=false;a.input_state.use=false;a.input_state.jump=false;a.input_state.crouch=false;a.input_state.sprint=false;a.input_state.ads=false;a.input_state.x=0.;a.input_state.z=0.
	if not p.alive:path.clear();target=0;visible_target=false;next_decision=0.;return
	if game.phase=="buy":shop();return
	if game.phase!="combat":return
	if p.flash>now:
		if p.role==5:game.use_skill(id)
		return
	if now>=next_perception:perceive();next_perception=now+[.28,.19,.12][difficulty]
	if now>=next_decision:choose_action();next_decision=now+.45
	p.bot_action=action
	if action in ["heal","repair"] and support_action():return
	var destination=goal
	if action=="engage" and target!=0 and visible_target:
		var enemy_pos=game.actors[target].position;var distance=a.position.distance_to(enemy_pos)
		var ideal=9. if p.role==3 and p.slot==0 else 34. if p.role==1 else 21.
		if distance>ideal:destination=last_known
		else:destination=a.position
	navigate(destination,dt)
	if visible_target and target!=0 and game.players.has(target) and game.players[target].alive:
		var opponent=game.actors[target];var aim_at=opponent.position+Vector3.UP*(.73 if opponent.input_state.crouch else 1.14)
		look(aim_at,dt,true)
		var distance=a.position.distance_to(opponent.position);a.input_state.ads=distance>12;a.input_state.sprint=false
		var w=game.current_weapon(p)
		if w.kind!="gun" or (p.role==3 and distance>40 and p.secondary!="repair"):
			game.handle_command(id,"slot",{"slot":1});w=game.current_weapon(p)
		elif p.slot!=0 and p.primary!="m1" and (p.role!=3 or distance<30):game.handle_command(id,"slot",{"slot":0})
		var cadence=[2.,1.6,1.3][difficulty];var firing=fmod(now+abs(id)*.17,cadence)<[.45,.65,.72][difficulty]
		var aligned=absf(angle_difference(float(a.input_state.yaw),atan2(-(aim_at-a.eye()).x,-(aim_at-a.eye()).z)))<.15
		if now>=ready_to_fire and firing and aligned and w.kind=="gun":
			a.input_state.fire=true
			if now>=next_click:a.input_state.trigger_seq=int(a.input_state.get("trigger_seq",0))+1;next_click=now+maxf(float(w.interval),.19)
			if difficulty>0 and (distance>13 or p.role==1):a.input_state.x=0.;a.input_state.z=0.
			if p.role==2:a.input_state.crouch=true;a.input_state.x=0.;a.input_state.z=0.
	else:
		var next_point=path[mini(waypoint,path.size()-1)] if not path.is_empty() else goal
		if a.position.distance_to(next_point)>1.2:look(next_point+Vector3.UP*1.4,dt,false)
		if a.position.distance_to(goal)>13:a.input_state.sprint=true
	# Navigation produces a world direction before the head turns. Keep that direction.
	var world_move=Basis(Vector3.UP,previous_yaw)*Vector3(a.input_state.x,0,a.input_state.z)
	var corrected=Basis(Vector3.UP,float(a.input_state.yaw)).inverse()*world_move
	a.input_state.x=corrected.x;a.input_state.z=corrected.z
	var wid=p.primary if p.slot==0 else p.secondary
	if int(p.mag.get(wid,0))==0 or (not visible_target and int(p.mag.get(wid,0))<int(game.current_weapon(p).mag)*.5):game.begin_reload(id)
	if p.reload>0 and visible_target and p.hp<45:action="retreat"
	objective_interaction()
	if now>=next_utility:utilities();next_utility=now+[1.8,1.1,.65][difficulty]
func perceive():
	var p=game.players[id];var a=game.actors[id];var now=game.clock;var selected=0;var best=1e8
	for other in game.players:
		var q=game.players[other]
		if other==id or not q.alive or not game.enemies(p,q):continue
		var actor=game.actors[other];var distance=a.position.distance_to(actor.position)
		if distance>[55.,75.,95.][difficulty] or distance>best:continue
		var toward=(actor.eye()-a.eye()).normalized()
		if distance>12 and a.direction().dot(toward)<-.35:continue
		if game.in_smoke_line(a.eye(),actor.eye()) or not game.clear_line(a.eye(),actor.eye(),[a.get_rid(),actor.get_rid()]):continue
		selected=other;best=distance
	visible_target=selected!=0
	if selected!=0:
		if selected!=target:ready_to_fire=now+[.85,.45,.22][difficulty]
		target=selected;last_seen=now;last_known=game.actors[selected].position
	elif now-last_seen>4.:target=0
func choose_action():
	var p=game.players[id];var a=game.actors[id];var now=game.clock
	ally=0;repair_target=0
	# A bot only pursues an enemy it has actually seen; objectives are public information.
	if p.role==5 and game.options.classes:
		var best=40.
		for other in game.players:
			var q=game.players[other]
			if other==id or not q.alive or game.enemies(p,q) or q.hp>=85:continue
			var distance=a.position.distance_to(game.actors[other].position)
			if distance<best and game.clear_line(a.eye(),game.actors[other].eye(),[a.get_rid(),game.actors[other].get_rid()]):best=distance;ally=other
		if ally!=0 and (not visible_target or p.hp>35):action="heal";set_goal(game.actors[ally].position);return
	if p.role==3 and p.secondary=="repair" and not visible_target:
		var best=24.
		for did in game.devices:
			var d=game.devices[did];var distance=a.position.distance_to(d.pos)
			if d.team==p.team and d.hp<d.max_hp*.8 and distance<best:repair_target=did;best=distance
		if repair_target!=0:action="repair";set_goal(game.devices[repair_target].pos);return
	var primary=Catalog.get_weapon(p.primary)
	if not game.options.infinite and primary.kind=="gun" and int(p.reserve.get(p.primary,0))<int(primary.mag):
		var best=1e8;var supply_pos=a.position
		for supply in game.arena.supplies:
			var distance=a.position.distance_to(supply.pos)
			if supply.ready<=now and distance<best:best=distance;supply_pos=supply.pos
		if best<80 and (not visible_target or int(p.mag.get(p.primary,0))==0):action="resupply";set_goal(supply_pos);return
	if p.hp<28 and visible_target and difficulty>0:
		var away=(a.position-last_known).normalized();action="retreat";set_goal(a.position+away*12);return
	if int(game.options.mode)==4:
		var attackers=(game.round_no-1)/3%2
		if game.bomb.planted:
			action="defuse" if p.team!=attackers else "guard_bomb";set_goal(game.bomb.position+Vector3((abs(id)%3-1)*7,0,7) if p.team==attackers else game.bomb.position)
		else:
			var site=abs(id)%2 if p.team!=attackers else int(game.bot_attack_site)
			action="plant" if p.team==attackers else "defend_site";set_goal(game.arena.sites[site]+Vector3(0,0,8 if p.team!=attackers else 0))
		if visible_target and a.position.distance_to(goal)>7:action="engage"
		return
	if int(game.options.mode)==3:
		var best=-1e8;var best_index=0
		for i in range(3):
			var assigned=0
			for bot in game.bot_agents.values():
				if bot.id!=id and game.players.has(bot.id) and game.players[bot.id].team==p.team and bot.goal.distance_to(game.arena.zones[i])<5:assigned+=1
			var score=(90. if game.zone_owner[i]!=p.team else 15.)-a.position.distance_to(game.arena.zones[i])*.35-assigned*17
			if score>best:best=score;best_index=i
		action="capture";set_goal(game.arena.zones[best_index]+Vector3((abs(id)%3-1)*1.5,0,0));return
	if visible_target:action="engage";set_goal(last_known);return
	if target!=0 and now-last_seen<4:action="investigate";set_goal(last_known);return
	action="patrol"
	if a.position.distance_to(goal)<3 or path.is_empty():
		roam_index=(roam_index+1)%5
		set_goal([game.arena.zones[0],Vector3(-game.arena.bounds.x*.66,0,game.arena.bounds.y/3.),game.arena.zones[1],game.arena.zones[2],Vector3(game.arena.bounds.x*.66,0,-game.arena.bounds.y/3.)][roam_index])
func set_goal(pos:Vector3):
	var bounds=game.arena.bounds-Vector2.ONE*6
	pos.x=clampf(pos.x,-bounds.x,bounds.x);pos.z=clampf(pos.z,-bounds.y,bounds.y)
	if goal.distance_to(pos)>3:next_path=0.
	goal=pos
func navigate(destination:Vector3,dt:float):
	var a=game.actors[id];var now=game.clock
	if a.position.distance_to(destination)<1.6:return
	if now>=next_path or path.is_empty():
		path=game.bot_navigation.route(a.position,destination);waypoint=1 if path.size()>1 else 0;next_path=now+1.4+rng.randf()*.4;stats.repaths+=1
	if path.is_empty():return
	while waypoint<path.size()-1 and a.position.distance_to(path[waypoint])<1.05:waypoint+=1
	var toward=path[waypoint]-a.position;toward.y=0
	if toward.length()<.7:return
	var desired=toward.normalized()
	var hit=game.ray(a.position+Vector3.UP*.65,a.position+Vector3.UP*.65+desired*1.25,[a.get_rid()],1|4)
	if not hit.is_empty():
		var found=false
		for angle in [.65,-.65,1.2,-1.2]:
			var candidate=Basis(Vector3.UP,angle)*desired
			if game.ray(a.position+Vector3.UP*.65,a.position+Vector3.UP*.65+candidate*1.4,[a.get_rid()],1|4).is_empty():desired=candidate;found=true;break
		if not found:next_path=0.;return
	var local_dir=Basis(Vector3.UP,float(a.input_state.yaw)).inverse()*desired
	a.input_state.x=local_dir.x;a.input_state.z=local_dir.z
	progress_time+=dt
	if progress_time>.85:
		if a.position.distance_to(previous_pos)<.4:stuck_count+=1;next_path=0.;game.bot_navigation.danger(a.position+desired*2,1.)
		else:stuck_count=0
		previous_pos=a.position;progress_time=0.
func look(at:Vector3,dt:float,enemy:bool):
	var a=game.actors[id];var p=game.players[id];var delta=at-a.eye();var yaw=atan2(-delta.x,-delta.z);var pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
	if enemy:
		var error=deg_to_rad([3.8,1.8,.65][difficulty]);yaw+=sin(game.clock*2.1+id)*error;pitch+=cos(game.clock*1.8+id*.7)*error*.65
		var spray=AimModel.spray_offset(game.current_weapon(p),int(p.get("spray_index",0)));pitch-=deg_to_rad(spray.y)*[0.,.35,.7][difficulty];yaw+=deg_to_rad(spray.x)*[0.,.35,.7][difficulty]
	a.input_state.yaw=lerp_angle(float(a.input_state.yaw),yaw,1.-exp(-dt*[5.,8.,12.][difficulty]));a.input_state.pitch=lerpf(float(a.input_state.pitch),clampf(pitch,-1.3,1.3),1.-exp(-dt*10))
func support_action() -> bool:
	var p=game.players[id];var a=game.actors[id]
	if action=="heal" and game.players.has(ally) and game.players[ally].alive:
		var at=game.actors[ally].eye();navigate(game.actors[ally].position,.016);look(at,.1,false)
		if a.position.distance_to(game.actors[ally].position)<8:
			a.input_state.x=0.;a.input_state.z=0.;game.handle_command(id,"slot",{"slot":0})
			a.input_state.fire=p.primary=="m1";a.input_state.alt=p.primary=="m2";stats.heals+=1
		return true
	if action=="repair" and game.devices.has(repair_target):
		var d=game.devices[repair_target];navigate(d.pos,.016);look(d.pos+Vector3.UP*.85,.1,false)
		if a.position.distance_to(d.pos)<3:
			a.input_state.x=0.;a.input_state.z=0.;game.handle_command(id,"slot",{"slot":1});a.input_state.fire=true;stats.repairs+=1
		return true
	return false
func objective_interaction():
	var p=game.players[id];var a=game.actors[id]
	for drop in game.drops:
		if a.position.distance_to(drop.pos)<2.4:a.input_state.use=true
	if int(game.options.mode)!=4:return
	if game.bomb.actor!=0 and game.bomb.actor!=id:return
	var attackers=(game.round_no-1)/3%2
	if not game.bomb.planted and p.team==attackers:
		for site in game.arena.sites:
			if a.position.distance_to(site)<4.5:a.input_state.x=0.;a.input_state.z=0.;a.input_state.use=true;a.input_state.fire=false;stats.interactions+=1
	elif game.bomb.planted and p.team!=attackers and a.position.distance_to(game.bomb.position)<4.5:
		a.input_state.x=0.;a.input_state.z=0.;a.input_state.use=true;a.input_state.fire=false;stats.interactions+=1
func utilities():
	var p=game.players[id];var a=game.actors[id]
	if not game.options.classes:return
	var gadget_before=p.gadget_count;var skill_before=p.skill_ready
	match int(p.role):
		0:
			if p.armor<25 and (visible_target or p.hp<70):game.use_gadget(id)
			if not visible_target and a.position.distance_to(goal)>20:game.use_skill(id)
		1:
			if visible_target:game.use_gadget(id);game.use_skill(id)
		2:
			if visible_target:a.input_state.crouch=true;game.use_gadget(id)
			if visible_target and p.hp<45:game.use_skill(id)
		3:
			if a.position.distance_to(goal)<13 or visible_target:
				var existing=0
				for did in game.devices:
					if game.devices[did].owner==id and game.devices[did].kind=="turret":existing=did
				if existing and game.devices[existing].level<4 and a.position.distance_to(game.devices[existing].pos)<5:
					instant_look(game.devices[existing].pos+Vector3.UP*1.65);game.use_skill(id)
				elif existing==0:
					for angle in [0.,PI/2,-PI/2,PI]:
						a.aim_yaw=float(a.input_state.yaw)+angle
						if game.valid_placement(game.placement(id),a.aim_yaw):game.use_skill(id);break
				if p.gadget_count>0 and visible_target:
					for angle in [PI/2,-PI/2,PI,0.]:
						a.aim_yaw=float(a.input_state.yaw)+angle
						if game.valid_placement(game.placement(id),a.aim_yaw):game.use_gadget(id);break
		4:
			if visible_target and a.position.distance_to(last_known)>17:
				p.gadget=1 if p.flash_count>0 and p.hp>45 else 0;var end=a.eye()+a.direction()*18;var friend_close=false
				for other in game.players:
					if game.players[other].alive and not game.enemies(p,game.players[other]) and game.actors[other].position.distance_to(end)<15:friend_close=true
				if p.gadget!=1 or not friend_close:game.use_gadget(id)
				game.use_skill(id)
		5:
			if p.hp<76:instant_look(a.position+Vector3.UP*3);game.use_gadget(id)
			if p.slow>game.clock or p.mark>game.clock:game.use_skill(id)
	if p.gadget_count<gadget_before:stats.gadgets+=1
	if p.skill_ready>skill_before:stats.skills+=1
func instant_look(at:Vector3):
	var a=game.actors[id];var delta=at-a.eye();a.aim_yaw=atan2(-delta.x,-delta.z);a.aim_pitch=atan2(delta.y,Vector2(delta.x,delta.z).length());a.input_state.yaw=a.aim_yaw;a.input_state.pitch=a.aim_pitch
func shop():
	if purchase_round==game.round_no:return
	purchase_round=game.round_no;var p=game.players[id];var best="";var most=-1
	for wid in Catalog.list_for(p.role,game.options.classes):
		var price=int(Catalog.get_weapon(wid).price)
		if price<=p.cash-300 and price>most:best=wid;most=price
	if best.is_empty():return
	var armor=1 if p.cash-most>=300 else 0
	var request={"role":p.role,"primary":best,"armor":armor,"gadget":0,"repair":p.role==3}
	if game.loadout_cost(p,request)>p.cash:request.armor=0
	if game.loadout_cost(p,request)<=p.cash:game.apply_loadout(id,request)
