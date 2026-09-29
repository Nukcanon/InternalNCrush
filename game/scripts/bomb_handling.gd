class_name BombHandling
extends RefCounted
## First-person charge handling (plant and defuse): the hero's left hand steadies
## the case while the right index finger taps the keypad, key by key.
const KEY_PERIOD=.22 # seconds per key press
static func active(actor:Node) -> bool:
	var g=actor.game
	return int(g.options.mode)==4 and g.phase=="combat" and (int(g.bomb.get("actor",0))==int(actor.pid) or (actor.local and BombLogic.busy(g,actor.pid)))
# Keypad (3x3) key centre in the view model's space; the charge is scaled .52.
static func key_position(index:int) -> Vector3:
	var column=index%3-1;var row=index/3-1
	return Vector3(column*.028,.197,-.068+row*.02)
static func view(actor:Node,p:Dictionary,now:float):
	var working=active(actor)
	if not working:
		if is_instance_valid(actor.bomb_view):actor.bomb_view.hide()
		return
	if not is_instance_valid(actor.bomb_view):
		var model=Node3D.new();model.name="BombHandling";actor.camera.add_child(model);actor.bomb_view=model
		var payload=Node3D.new();payload.name="Payload";model.add_child(payload);BombLogic.model(payload);payload.scale=Vector3.ONE*.52
		# The left hand lies on top of the case's side band, fingers over its far
		# edge (a grip shape); the right hand is a wrist target whose index finger
		# taps the keys (actor.update_view_body).
		var left=Marker3D.new();left.name="LeftGrip";left.position=Vector3(.125,.083,0);left.basis=Basis(Vector3.UP,PI);model.add_child(left)
		model.set_meta("grip_styles",{"L":"top"});model.set_meta("grip_shapes",{"L":{"half":Vector3(.035,.073,.1),"round":.015}})
		var right=Marker3D.new();right.name="RightGrip";model.add_child(right)
		# Fingers point down onto the keys.
		right.basis=Basis(Vector3.UP,PI)*Basis(Vector3.RIGHT,-.95)
	# Placed in camera space and turned so the keypad faces the player.
	actor.bomb_view.show();actor.bomb_view.global_transform=actor.camera.global_transform*Transform3D(Basis.from_euler(Vector3(.22,0,0))*Basis(Vector3.UP,PI),Vector3(0,-.38,-.6))
	# Key sequence: a pseudo-random key each period; press down, then lift.
	var step=int(floor(now/KEY_PERIOD));var phase=fposmod(now,KEY_PERIOD)/KEY_PERIOD
	var key=int(abs(sin(step*12.9898)*43758.5453))%9
	var press=sin(clampf(phase/.45,0.,1.)*PI)
	# The wrist sits behind and above the fingertip.
	actor.bomb_view.get_node("RightGrip").position=key_position(key)+Vector3(-.02,.075-press*.028,-.075)
	actor.view_weapon.hide();actor.item_model.hide()
	if is_instance_valid(actor.melee_view):actor.melee_view.hide()
