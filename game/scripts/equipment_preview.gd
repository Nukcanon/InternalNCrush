extends SubViewportContainer
class_name EquipmentPreview
var stage:Node3D
var model:Node3D
var camera:Camera3D
var viewport:SubViewport
var dragging=false
var skill_symbol:SkillIcon
var frame_width=1.3
var frame_height=1.3
var preview_kind=0
func _ready():
	stretch=true;size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL;custom_minimum_size=Vector2(330,160)
	viewport=SubViewport.new();viewport.size=Vector2i(440,330);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;viewport.msaa_3d=Viewport.MSAA_2X;add_child(viewport)
	GraphicsOptions.apply_viewport(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("bfe3f5");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.45;world.environment=env;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,150,0);key.light_energy=1.15;key.shadow_enabled=true;key.directional_shadow_max_distance=8.;key.shadow_bias=.03;stage.add_child(key)
	viewport.positional_shadow_atlas_size=512
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
	resized.connect(fit_frame)
func fit_frame():
	if is_instance_valid(camera):camera.size=maxf(frame_height,frame_width/maxf(.3,size.x/maxf(1.,size.y)))
	if is_instance_valid(skill_symbol):
		skill_symbol.size=Vector2(76,76);skill_symbol.position=(size-skill_symbol.size)*.5
func display(kind:int,role:int,team:int,weapon:String,gadget:int=0,armor_level:int=1):
	if not is_instance_valid(stage):return
	preview_kind=kind
	if is_instance_valid(model):stage.remove_child(model);model.queue_free()
	model=Node3D.new();stage.add_child(model)
	if is_instance_valid(skill_symbol):skill_symbol.hide()
	if (kind==1 and weapon.is_empty()) or (kind==2 and gadget in [-1,99]):
		custom_minimum_size.y=130.;return
	if kind==0:
		var c=HeroCharacter.new();model.add_child(c);c.build(role,team,true);c.set_armor(armor_level)
		var w=Catalog.get_weapon("pistol" if weapon.is_empty() else weapon)
		var held=GunModel.new();held.build(w,true);c.hold(held)
		var hold=GunLooks.hold_kind(w).replace("shoulder","rifle")
		for i in range(4):c.drive(.05,{"pitch":-.08,"hold":hold})
		model.rotation.y=-.35;camera.position=Vector3(0,1.25,-4);camera.look_at(Vector3(0,1.15,0));camera.size=2.05
	elif kind==1:
		var gun=GunModel.new();model.add_child(gun);gun.build(Catalog.get_weapon(weapon),true);gun.rotation.y=PI/2;camera.position=Vector3(0,.4,-3);camera.look_at(Vector3(0,0,0))
		var meshes=gun.find_children("*","MeshInstance3D",true,false);var bounds=AABB();var first=true
		for mesh in meshes:
			var box=mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var focus=bounds.get_center();camera.position=focus+Vector3(0,.35,-3);camera.look_at(focus);camera.size=maxf(.52,bounds.size.x*.70)
	elif kind==3:
		# 1.4.2: the armour as this hero wears it (fitted per hero and tier).
		var c=HeroCharacter.new();model.add_child(c);c.build(role,team,true);c.play("Idle",.4);c.set_armor(clampi(gadget,0,2))
		model.rotation.y=-.55;camera.position=Vector3(0,1.2,-4);camera.look_at(Vector3(0,1.17,0));camera.size=1.3
	elif kind==4:
		if not is_instance_valid(skill_symbol):skill_symbol=SkillIcon.new();add_child(skill_symbol);skill_symbol.size=Vector2(76,76)
		skill_symbol.role=role;skill_symbol.show();skill_symbol.queue_redraw()

	else:
		gadget_model(model,role,gadget);camera.position=Vector3(1,.9,-3);camera.look_at(Vector3(0,.2,0));camera.size=1.3
	# Preview owns lit material copies; global low/Web settings must not flatten it.
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var material=mesh.material_override
		if material is ShaderMaterial:
			mesh.material_override=material.duplicate();mesh.material_override.set_shader_parameter("dynamic_lighting",true)
	if kind in [1,2]:
		var bounds=AABB();var first=true
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var part=model.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
			bounds=part if first else bounds.merge(part);first=false
		var center=bounds.get_center()
		for child in model.get_children():
			if child is Node3D:child.position-=center
		var diameter=Vector2(bounds.size.x,bounds.size.z).length()
		var compact=kind==3 or (kind==2 and (gadget==8 or (role==0 and gadget==1) or (role==4 and gadget in [0,1])))
		var margin=1.85 if kind==1 else 2.5 if compact else 1.25
		frame_width=maxf(.3,diameter)*margin
		frame_height=maxf(.22,bounds.size.y+diameter*.13)*margin
		custom_minimum_size.y=clampf(440.*frame_height/frame_width,130.,280.)
		camera.position=Vector3(0,.35,-3);camera.look_at(Vector3.ZERO)
	elif kind==4:
		custom_minimum_size.y=100.;frame_height=1.;frame_width=1.
	else:
		custom_minimum_size.y=230.;frame_height=camera.size;frame_width=camera.size*1.35
	fit_frame()
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
	if event is InputEventMouseMotion and dragging and model:model.rotation.y+=event.relative.x*.013
# Gear preview uses the in-game cartoon gear (GearModels.held).
# Instances share the cached held-gadget template meshes.
static func gadget_model(parent:Node3D,role:int,variant:int):
	var holder=GadgetVisual.new();holder.name="Equipment";parent.add_child(holder)
	holder.build(role,variant,false)
