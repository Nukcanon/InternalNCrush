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
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("263b46");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.95;world.environment=env;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,150,0);key.light_energy=1.3;stage.add_child(key)
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
	resized.connect(fit_frame)
func fit_frame():
	if is_instance_valid(camera):camera.size=maxf(frame_height,frame_width/maxf(.3,size.x/maxf(1.,size.y)))
	if is_instance_valid(skill_symbol):
		skill_symbol.size=Vector2(76,76);skill_symbol.position=(size-skill_symbol.size)*.5
func display(kind:int,role:int,team:int,weapon:String,gadget:int=0):
	if not is_instance_valid(stage):return
	preview_kind=kind
	if is_instance_valid(model):stage.remove_child(model);model.queue_free()
	model=Node3D.new();stage.add_child(model)
	if is_instance_valid(skill_symbol):skill_symbol.hide()
	if kind==0:
		var c=CharacterVisual.new();c.enable_physics=false;model.add_child(c);c.build(role,team);c.update_pose(.016,Vector3.ZERO,false,false,true,0.,-1.,0.,0.)
		var gun=WeaponVisual.new();c.socket.add_child(gun);gun.build(Catalog.get_weapon(weapon),false);gun.scale=Vector3.ONE*.8
		c.update_pose(.016,Vector3.ZERO,false,false,true,0.,-1.,0.,0.);c.grip_weapon(1.);c.sync_deform()
		model.rotation.y=-.35;camera.position=Vector3(0,1.4,-4);camera.look_at(Vector3(0,1.3,0));camera.size=1.15
	elif kind==1:
		var gun=WeaponVisual.new();model.add_child(gun);gun.build(Catalog.get_weapon(weapon),false);gun.rotation.y=PI/2;camera.position=Vector3(0,.4,-3);camera.look_at(Vector3(0,0,0));camera.size=.63
		var meshes=gun.find_children("*","MeshInstance3D",true,false);var bounds=AABB();var first=true
		for mesh in meshes:
			var box=mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var focus=bounds.get_center();camera.position=focus+Vector3(0,.35,-3);camera.look_at(focus);camera.size=maxf(.52,bounds.size.x*.70)
	elif kind==3:
		HumanModel.loft(model,Vector3(0,.15,0),[Vector4(-.2,.17,.13,0),Vector4(.05,.20,.14,0),Vector4(.18,.17,.11,0)],Color("718891") if gadget==0 else Color("596552") if gadget==1 else Color("3c514f"))
		for x in [-.12,0,.12]:HumanModel.oval(model,Vector3(x,.10,-.15),Vector3(.10,.15,.06),Color("6e7d63"))
		camera.position=Vector3(.5,.6,-3);camera.look_at(Vector3(0,.15,0));camera.size=1.0
	elif kind==4:
		if not is_instance_valid(skill_symbol):skill_symbol=SkillIcon.new();add_child(skill_symbol);skill_symbol.size=Vector2(76,76)
		skill_symbol.role=role;skill_symbol.show();skill_symbol.queue_redraw()

	else:
		gadget_model(model,role,gadget);camera.position=Vector3(1,.9,-3);camera.look_at(Vector3(0,.2,0));camera.size=1.3
	if kind in [1,2,3]:
		var bounds=AABB();var first=true
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var part=model.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
			bounds=part if first else bounds.merge(part);first=false
		var center=bounds.get_center()
		for child in model.get_children():
			if child is Node3D:child.position-=center
		var diameter=Vector2(bounds.size.x,bounds.size.z).length()
		var margin=1.85 if kind==1 else 1.25
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
static func gadget_model(parent:Node3D,role:int,variant:int):
	if variant==8:
		grenade_model(parent);MeshFactory.merge_children(parent);return
	if variant==9:
		MeshFactory.box(parent,Vector3.ZERO,Vector3(.45,.22,.32),Color("d2b869"))
		MeshFactory.box(parent,Vector3(0,.13,0),Vector3(.18,.04,.12),Color("425869"));return
	var m=MeshFactory;var dark=Color("304955");var light=Color("c2d4d8");var accent=CharacterVisual.ROLE_ACCENTS[role]
	match role:
		0:
			if variant==1:
				grenade_model(parent);m.merge_children(parent);return
			m.box(parent,Vector3(0,.25,0),Vector3(.43,.55,.09),Color("7294ae"),Vector3.ZERO,.55);m.box(parent,Vector3(0,.26,-.055),Vector3(.27,.35,.025),dark,Vector3.ZERO,.4)
		1:m.cylinder(parent,Vector3(0,.12,0),.18,.2,dark);m.cylinder(parent,Vector3(0,.24,0),.14,.04,accent);m.cylinder(parent,Vector3(.08,.4,0),.016,.36,light)
		2:
			m.box(parent,Vector3(0,.48,0),Vector3(.20,.07,.14),dark,Vector3.ZERO,.3)
			m.box(parent,Vector3(0,.527,0),Vector3(.14,.025,.10),light)
			for side in [-1,1]:
				var hinge=Vector3(side*.075,.46,0);var knee=Vector3(side*.18,.25,0);var foot=Vector3(side*.30,.025,0)
				m.cylinder(parent,hinge,.038,.09,light,Vector3(PI/2,0,0))
				rod(parent,hinge,knee,.026,dark);rod(parent,knee,foot,.018,Color("68777e"))
				var spring_a=hinge+Vector3(side*.033,-.025,.035);var spring_b=knee+Vector3(side*.032,.03,.035)
				rod(parent,spring_a,spring_b,.012,light)
				for i in range(12):
					var pt=spring_a.lerp(spring_b,i/11.)
					var coil=m.cylinder(parent,pt,.018,.006,dark);coil.quaternion=Quaternion(Vector3.UP,(spring_b-spring_a).normalized())
				m.box(parent,foot,Vector3(.082,.034,.10),Color("202a30"),Vector3(0,0,side*.12),.3)

		3:
			var cover=Node3D.new();parent.add_child(cover);CombatFX.device(cover,"cover",0);cover.scale=Vector3.ONE*.32
		4:
			m.cylinder(parent,Vector3(0,.2,0),.10,.35,Color("d4c691") if variant==1 else Color("81a292"));m.box(parent,Vector3(0,.4,0),Vector3(.12,.07,.12),dark)
		5:
			m.box(parent,Vector3(0,.22,0),Vector3(.55,.4,.18),light,Vector3.ZERO,.5);m.box(parent,Vector3(0,.22,-.1),Vector3(.07,.25,.025),accent);m.box(parent,Vector3(0,.22,-.101),Vector3(.25,.07,.025),accent)
	m.merge_children(parent)
static func grenade_model(parent:Node3D):
	var m=MeshFactory;var shell=Color("657350");var steel=Color("889895")
	HumanModel.loft(parent,Vector3(0,.16,0),[Vector4(-.14,.04,.04,0),Vector4(-.10,.09,.09,0),Vector4(.06,.095,.095,0),Vector4(.13,.065,.065,0)],shell,24)
	for y in [.08,.16,.24]:m.cylinder(parent,Vector3(0,y,0),.098,.015,Color("36473c"),Vector3.ZERO,-1,24)
	m.cylinder(parent,Vector3(0,.31,0),.042,.055,steel)
	m.box(parent,Vector3(.071,.20,0),Vector3(.022,.26,.047),steel,Vector3(0,0,.16))
	var ring=TorusMesh.new();ring.inner_radius=.025;ring.outer_radius=.032;ring.rings=16;ring.ring_segments=6;m.instance(parent,ring,Vector3(-.05,.32,0),steel,Vector3(PI/2,0,0))

static func rod(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color):
	var mesh=MeshFactory.cylinder(parent,(a+b)*.5,radius,a.distance_to(b),color)
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
