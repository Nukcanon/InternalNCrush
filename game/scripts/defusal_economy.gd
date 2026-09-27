extends RefCounted
class_name DefusalEconomy
static func purchase_seconds(g:Node) -> float:
	return maxf(0.,float(g.bomb.get("buy_until",0.))-g.clock) if g.phase=="combat" else maxf(0.,g.remaining) if g.phase=="buy" else 0.
static func can_buy(g:Node,id:int) -> bool:
	return int(g.options.mode)==4 and g.players.has(id) and g.players[id].alive and purchase_seconds(g)>0. and not BombLogic.busy(g,id)
static func reset(p:Dictionary,cash:int=-1):
	p.primary="";p.secondary="pistol";p.slot=1;p.owned_primary=false;p.owned_secondary=false;p.owned_gadget=false
	p.armor_max=0;p.armor=0.;p.gadget=-1;p.gadget_count=0;p.smoke=0;p.flash_count=0
	p.mag={};p.reserve={};p.reload=0.;p.reload_weapon="";p.pending_loadout={};p.placing="";p.cooking=0;p.burst_left=0;p.trigger_until=0.
	if cash>=0:p.cash=cash
static func gadget_cost(role:int,kind:int) -> int:
	if kind<0:return 0
	if kind==9:return 400
	if kind==8:return 300
	if role==3:return [300,600,1000][clampi(kind,0,2)]
	return 400 if role in [1,4] else 300
static func selection(p:Dictionary,d:Dictionary) -> Dictionary:
	var role=clampi(int(d.get("role",p.role)),0,5)
	var secondary=str(d.get("secondary","repair" if role==3 and d.get("repair",false) else p.secondary))
	if secondary not in Catalog.secondaries_for(role):secondary="pistol"
	return {"role":role,"primary":str(d.get("primary",p.primary)),"secondary":secondary,"armor":clampi(int(d.get("armor",int(p.armor_max)/25)),0,2)*25,"gadget":clampi(int(d.get("gadget",p.gadget)),-1,9)}
static func cost(p:Dictionary,d:Dictionary) -> int:
	var chosen=selection(p,d);var changed=chosen.role!=int(p.role);var total=0
	if not chosen.primary.is_empty() and (changed or not p.get("owned_primary",false) or chosen.primary!=p.primary):total+=int(Catalog.get_weapon(chosen.primary).price)
	if chosen.secondary!="pistol" and (changed or chosen.secondary!=p.secondary or not p.get("owned_secondary",false)):total+=int(Catalog.get_weapon(chosen.secondary).price)
	if chosen.armor>0 and (changed or chosen.armor>p.armor):total+=300 if chosen.armor==25 else 600
	var probe={"role":chosen.role,"gadget":chosen.gadget}
	if chosen.gadget>=0 and (changed or not p.get("owned_gadget",false) or chosen.gadget!=p.gadget or int(p.gadget_count)<GadgetLoadout.count(probe)):total+=gadget_cost(chosen.role,chosen.gadget)
	return total
static func replacement(p:Dictionary,d:Dictionary) -> bool:
	var c=selection(p,d)
	if int(c.role)!=int(p.role):return true
	return (p.get("owned_primary",false) and c.primary!=p.primary) or (p.get("owned_secondary",false) and c.secondary!=p.secondary) or (p.get("owned_gadget",false) and c.gadget!=p.gadget) or (int(p.armor_max)>0 and int(c.armor)!=int(p.armor_max))
