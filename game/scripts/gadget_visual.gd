class_name GadgetVisual
extends Node3D
## Held gadget (1.4 cartoon gear, GearModels.held). Hands come from the hero's
## IK in both views, so this node only carries the item and its grip markers.
var right_socket=Vector3.ZERO
var left_socket=Vector3.ZERO
var two_handed=false
static var templates={}
func build(role:int,variant:int,_first_person:bool,turret:bool=false):
	var key=str([role,variant,turret])
	if not templates.has(key):
		var source=Node3D.new();var info=GearModels.held(source,role,variant,turret)
		MeshFactory.own_recursive(source,source)
		var packed=PackedScene.new();packed.pack(source)
		templates[key]={"scene":packed,"right":info.right,"left":info.left,"two_handed":info.two_handed}
		source.free()
	var entry=templates[key];var copy:Node=entry.scene.instantiate()
	for child in copy.get_children():
		copy.remove_child(child);MeshFactory.own_recursive(child,null);child.owner=null;add_child(child)
	copy.free()
	right_socket=entry.right;left_socket=entry.left;two_handed=entry.two_handed
static func prepare(role:int,variant:int,first_person:bool,turret:bool=false):
	var probe=GadgetVisual.new();probe.build(role,variant,first_person,turret);probe.free()
