class_name GadgetVisual
extends Node3D
## Held gadget (1.4 cartoon gear, GearModels.held). Hands come from the hero's
## IK in both views, so this node only carries the item and its grip markers.
var right_socket=Vector3.ZERO
var left_socket=Vector3.ZERO
var two_handed=false
var grip={} # side -> {style, shape} (GearModels.held)
var view_lift=0. # first person: raise items carried low (the medkit) back into view
# 1.4.5: the baked surface field of this item round its grips (GripField),
# so the hands lie on and the fingers wrap the real gear, not a box.
var field_id=""
static var templates={}
# (the carried turret is one model whichever gadget is selected: one field)
static func field_key(role:int,variant:int,turret:bool) -> String:return "gear_%d_%d_%d"%[role,0 if turret else variant,int(turret)]
func build(role:int,variant:int,first_person:bool,turret:bool=false):
	field_id=field_key(role,variant,turret)
	# (first person: the grenades' pull ring is its own piece for the pin pull;
	# elsewhere one merged mesh)
	var ring=first_person and not turret
	var key=str([role,variant,turret,ring])
	if not templates.has(key):
		var source=Node3D.new();var info=GearModels.held(source,role,variant,turret,ring)
		MeshFactory.own_recursive(source,source)
		var packed=PackedScene.new();packed.pack(source)
		templates[key]={"scene":packed,"right":info.right,"left":info.left,"two_handed":info.two_handed,"grip":info.get("grip",{}),"view_lift":float(info.get("view_lift",0.))}
		source.free()
	var entry=templates[key];var copy:Node=entry.scene.instantiate()
	for child in copy.get_children():
		copy.remove_child(child);MeshFactory.own_recursive(child,null);child.owner=null;add_child(child)
	copy.free()
	right_socket=entry.right;left_socket=entry.left;two_handed=entry.two_handed;grip=entry.grip;view_lift=float(entry.get("view_lift",0.))
static func prepare(role:int,variant:int,first_person:bool,turret:bool=false):
	var probe=GadgetVisual.new();probe.build(role,variant,first_person,turret);probe.free()
