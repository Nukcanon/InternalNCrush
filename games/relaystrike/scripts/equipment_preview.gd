extends SubViewportContainer
class_name EquipmentPreview
var stage:Node3D
var model:Node3D
var camera:Camera3D
var viewport:SubViewport
var dragging=false
func _ready():
	stretch=true;size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL;custom_minimum_size=Vector2(330,270)
	viewport=SubViewport.new();viewport.size=Vector2i(440,330);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;viewport.msaa_3d=Viewport.MSAA_2X;add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("142632");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7;world.environment=env;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,150,0);key.light_energy=1.1;stage.add_child(key)
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
func display(kind:int,role:int,team:int,weapon:String,gadget:int=0):
	if not is_instance_valid(stage):return
	if is_instance_valid(model):stage.remove_child(model);model.queue_free()
	model=Node3D.new();stage.add_child(model)
	if kind==0:
		var c=CharacterVisual.new();model.add_child(c);c.build(role,team);c.animator.play("idle");c.animator.advance(.3)
		var gun=WeaponVisual.new();c.socket.add_child(gun);gun.build(Catalog.get_weapon(weapon),false);gun.scale=Vector3.ONE*.8
		model.rotation.y=-.35;camera.position=Vector3(0,1.1,-4);camera.look_at(Vector3(0,.95,0));camera.size=2.5
	elif kind==1:
		var gun=WeaponVisual.new();model.add_child(gun);gun.build(Catalog.get_weapon(weapon),false);gun.rotation.y=PI/2;camera.position=Vector3(0,.4,-3);camera.look_at(Vector3(0,0,0));camera.size=1.15
	else:
		gadget_model(model,role,gadget);camera.position=Vector3(1,.9,-3);camera.look_at(Vector3(0,.2,0));camera.size=1.3
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
	if event is InputEventMouseMotion and dragging and model:model.rotation.y+=event.relative.x*.013
static func gadget_model(parent:Node3D,role:int,variant:int):
	var m=MeshFactory;var dark=Color("304955");var light=Color("c2d4d8");var accent=CharacterVisual.ROLE_ACCENTS[role]
	match role:
		0:m.box(parent,Vector3(0,.25,0),Vector3(.43,.55,.09),Color("7294ae"),Vector3.ZERO,.55);m.box(parent,Vector3(0,.26,-.055),Vector3(.27,.35,.025),dark,Vector3.ZERO,.4)
		1:m.cylinder(parent,Vector3(0,.12,0),.18,.2,dark);m.cylinder(parent,Vector3(0,.24,0),.14,.04,accent);m.cylinder(parent,Vector3(.08,.4,0),.016,.36,light)
		2:
			for x in [-.22,.22]:m.cylinder(parent,Vector3(x,.16,0),.025,.4,light,Vector3(0,0,sign(x)*-.55))
			m.box(parent,Vector3(0,.35,0),Vector3(.3,.1,.14),dark)
		3:
			m.box(parent,Vector3(0,.26,0),Vector3(.94,.5,.16),dark,Vector3.ZERO,.2)
			for x in [-.3,0,.3]:m.box(parent,Vector3(x,.28,-.1),Vector3(.2,.38,.04),accent.darkened(variant*.13),Vector3.ZERO,.25)
			for x in [-.3,.3]:m.box(parent,Vector3(x,.02,0),Vector3(.1,.06,.44),light)
		4:
			m.cylinder(parent,Vector3(-.17,.2,0),.11,.35,Color("81a292"));m.cylinder(parent,Vector3(.18,.2,0),.1,.35,Color("d4c691"));m.box(parent,Vector3(-.17,.4,0),Vector3(.13,.07,.13),dark);m.box(parent,Vector3(.18,.4,0),Vector3(.12,.07,.12),dark)
		5:
			m.box(parent,Vector3(0,.22,0),Vector3(.55,.4,.18),light,Vector3.ZERO,.5);m.box(parent,Vector3(0,.22,-.1),Vector3(.07,.25,.025),accent);m.box(parent,Vector3(0,.22,-.101),Vector3(.25,.07,.025),accent)
	m.merge_children(parent)
