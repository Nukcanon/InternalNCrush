class_name BombHandling
extends RefCounted
static func active(actor:Node) -> bool:
	var g=actor.game
	return int(g.options.mode)==4 and g.phase=="combat" and (int(g.bomb.get("actor",0))==int(actor.pid) or (actor.local and BombLogic.busy(g,actor.pid)))
static func view(actor:Node,p:Dictionary,now:float):
	var working=active(actor)
	if not working:
		if is_instance_valid(actor.bomb_view):actor.bomb_view.hide()
		return
	if not is_instance_valid(actor.bomb_view):
		var model=Node3D.new();model.name="BombHandling";actor.camera.add_child(model);actor.bomb_view=model
		var payload=Node3D.new();payload.name="Payload";model.add_child(payload);BombLogic.model(payload);payload.scale=Vector3.ONE*.52
		for side in [-1,1]:
			var hand=HeldGrip.new();hand.name="HandLeft" if side<0 else "HandRight";model.add_child(hand);hand.build(int(p.role),.024);hand.scale.x=side
			var wrist=Vector3(side*.17,.085,.04);hand.position=wrist
			var arm=WeaponHand.forearm(model,int(p.role));WeaponHand.fit_forearm(arm,Vector3(side*.30,-.21,.35),wrist+Vector3(side*.04,0,.03))
	actor.bomb_view.show();actor.bomb_view.position=Vector3(0,-.39,-.56)
	actor.bomb_view.rotation=Vector3(.12,0,0)
	actor.bomb_view.get_node("HandRight").position=Vector3(.13,.115+sin(now*12.)*.012,-.04)
	actor.view_weapon.hide();actor.item_model.hide()
	if is_instance_valid(actor.melee_view):actor.melee_view.hide()
