extends Node3D
class_name CombatFX
var field_nodes={}
var transients=[]
var healing={}
var grenade_nodes={}
var status_nodes={}
var ragdolls=[]
var active_lights=0
var blood:BloodFX
static var cloud_shader:Shader
const M=preload("res://scripts/mesh_factory.gd")
func clear():
	for child in get_children():child.queue_free()
	field_nodes.clear();transients.clear();casings.clear();scuffs.clear();healing.clear();grenade_nodes.clear();status_nodes.clear();ragdolls.clear();active_lights=0
	blood=null
func blood_hit(point:Vector3,direction:Vector3,amount:float):
	if not GraphicsOptions.blood_enabled:return
	if not is_instance_valid(blood):blood=BloodFX.new();add_child(blood)
	blood.emit_hit(point,direction,amount)
func group(pos:Vector3) -> Node3D:
	while transients.size()>=96:
		var old=transients.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node=Node3D.new();add_child(node);node.position=pos;transients.append(node);return node
static func glow(color:Color) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;return mat
func cloud(color:Color,fire:bool=false) -> ShaderMaterial:
	if cloud_shader==null:
		cloud_shader=Shader.new();cloud_shader.code="""
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
uniform vec4 tint:source_color=vec4(.4,.45,.47,1.);
uniform float opacity=.7;
uniform bool fire=false;
varying vec3 p;
void vertex(){p=VERTEX;VERTEX+=NORMAL*(sin(VERTEX.x*13.+TIME*3.)*sin(VERTEX.z*11.-TIME*2.))*.045;}
void fragment(){
 float turbulence=.5+.25*sin(p.x*17.+TIME*4.)*sin(p.y*13.-TIME*3.)+.18*sin(p.z*21.+TIME*2.);
 float edge=smoothstep(.04,.65,abs(dot(normalize(NORMAL),normalize(VIEW))));
 vec3 smoke=mix(tint.rgb*.66,tint.rgb*1.18,turbulence);
 vec3 flame=mix(vec3(.65,.12,.025),mix(tint.rgb,vec3(1.,.86,.47),turbulence*.65),edge);
 ALBEDO=fire?flame:smoke;
 ALPHA=opacity*edge*mix(.62,1.,turbulence);
}
"""
	var mat=ShaderMaterial.new();mat.shader=cloud_shader;mat.set_shader_parameter("tint",color);mat.set_shader_parameter("fire",fire);mat.set_shader_parameter("opacity",color.a);return mat
func finish(node:Node3D,seconds:float):
	var tween=node.create_tween();tween.tween_interval(seconds);tween.tween_callback(node.queue_free)
func ring(parent:Node3D,radius:float,color:Color) -> MeshInstance3D:
	var node=MeshInstance3D.new();var mesh=TorusMesh.new();mesh.inner_radius=maxf(.01,radius-.06);mesh.outer_radius=radius;mesh.rings=32;mesh.ring_segments=6;node.mesh=mesh;node.material_override=glow(color);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);return node
func beam(from:Vector3,to:Vector3,heal=false):
	var length=from.distance_to(to)
	if length<.02:return
	var node=group((from+to)*.5);node.look_at(to)
	var mesh=M.cylinder(node,Vector3.ZERO,.018 if heal else .010,length,Color("65edc2") if heal else Color("ffecc0"),Vector3(PI/2,0,0),-1.,6)
	mesh.material_override=glow(Color(.3,1,.73,.85) if heal else Color(1,.81,.40,.72));mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	finish(node,.10 if heal else .048)
	if heal:
		var end=group(to);var halo=ring(end,.19,Color(.3,1,.75,.55));halo.rotation.x=PI/2;finish(end,.12)
func burst(kind:String,pos:Vector3,color:Color):
	if kind in ["explosion","turret_break","cover_break"]:explosion(pos,kind!="cover_break");return
	var node=group(pos+Vector3.UP*.15);var explosive=kind=="explosion";var radius=5.5 if explosive else 1.9 if kind=="flash" else 1.15
	var life=.85 if explosive else .48;var halo=ring(node,.5,color);halo.position.y=.04
	var tween=node.create_tween().set_parallel(true);tween.tween_property(halo,"scale",Vector3(radius,.6,radius),life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(halo.material_override,"albedo_color:a",0.,life)
	for i in range(16 if explosive else 8):
		var angle=TAU*i/(16 if explosive else 8);var dir=Vector3(cos(angle),randf_range(.3,1.5),sin(angle)).normalized()
		var spark=M.sphere(node,Vector3.ZERO,Vector3(.12,.12,.32) if explosive else Vector3(.055,.055,.18),color);spark.material_override=glow(color);spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.look_at_from_position(node.global_position,node.global_position+dir)
		tween.tween_property(spark,"position",dir*radius,life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(spark,"scale",Vector3.ZERO,life)
	if explosive or kind=="flash":
		var core=M.sphere(node,Vector3.UP*.4,Vector3.ONE*.6,color);core.material_override=glow(Color(1,.87,.56,.9) if explosive else Color(1,.98,.84,.8));core.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tween.tween_property(core,"scale",Vector3.ONE*(5 if explosive else 3),.22);tween.tween_property(core.material_override,"albedo_color:a",0.,.25)
	finish(node,life+.02)
func sync_fields(fields:Array,now:float):
	var live={}
	for field in fields:
		if field.kind not in ["smoke","slow"] or float(field.get("starts",0))>now:continue
		var key=str([field.kind,field.pos,field.until]);live[key]=true
		if not field_nodes.has(key):
			var node=Node3D.new();add_child(node);node.position=field.pos;field_nodes[key]=node
			if field.kind=="smoke":
				for i in range(10):
					var offset=Vector3(0,1.6,0) if i==0 else Vector3(sin(i*2.4)*2.6,1.2+float(i%3)*.8,cos(i*2.4)*2.6)
					var mesh=M.sphere(node,offset,Vector3.ONE*(8. if i==0 else 4.3),Color.WHITE)
					mesh.material_override=cloud(Color(.54,.61,.63,.99 if i==0 else .78));mesh.set_meta("density",.99 if i==0 else .78);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				var color=Color(.2,.68,1,.8) if field.team==0 else Color(1,.54,.18,.8);ring(node,5.,color).position.y=.06;ring(node,4.7,Color(color,.32)).position.y=.065
				var disc=M.cylinder(node,Vector3(0,.025,0),4.9,.02,Color(color,.10),Vector3.ZERO,-1.,48);disc.material_override=glow(Color(color,.10))
				for i in range(12):
					var a=TAU*i/12.;M.sphere(node,Vector3(cos(a)*4.7,.15,sin(a)*4.7),Vector3(.14,.3,.14),Color(color,1.))
		var node=field_nodes[key]
		if field.kind=="smoke":
			var fade=clampf(float(field.until)-now,0.,1.)*clampf((now-float(field.get("starts",now-1.)))/.35,0.,1.)
			for cloud_mesh in node.get_children():cloud_mesh.material_override.set_shader_parameter("opacity",float(cloud_mesh.get_meta("density"))*fade)
		else:node.rotation.y=sin(now*.6)*.015
	for key in field_nodes.keys():
		if not live.has(key):field_nodes[key].queue_free();field_nodes.erase(key)
static func device(parent:Node3D,kind:String,team:int):
	var color=Color("378fb2") if team==0 else Color("ba7440");var metal=Color("354d5c")
	if kind=="cover":
		M.box(parent,Vector3(0,.64,0),Vector3(3.4,1.25,.55),metal)
		for x in [-1.1,0,1.1]:
			M.box(parent,Vector3(x,.68,-.30),Vector3(1.0,1.1,.08),color);M.box(parent,Vector3(x,.9,-.35),Vector3(.65,.035,.018),Color("d6e8e2"))
		for x in [-1.25,1.25]:M.box(parent,Vector3(x,.12,0),Vector3(.24,.22,1.),metal)
	else:
		M.cylinder(parent,Vector3(0,.18,0),.58,.22,metal,Vector3.ZERO,.42,12)
		M.cylinder(parent,Vector3(0,.78,0),.13,1.15,color)
		for i in range(3):
			var a=TAU*i/3.;M.box(parent,Vector3(cos(a)*.37,.16,sin(a)*.37),Vector3(.18,.15,.8),metal,Vector3(0,-a+PI/2,0))
		var head=Node3D.new();head.name="TurretHead";head.position.y=1.7;parent.add_child(head)
		M.box(head,Vector3.ZERO,Vector3(.6,.32,.52),color)
		for x in [-.16,.16]:
			M.cylinder(head,Vector3(x,0,-.48),.063,.76,metal,Vector3(PI/2,0,0));M.cylinder(head,Vector3(x,0,-.86),.078,.055,Color("a4b9bd"),Vector3(PI/2,0,0))
		M.sphere(head,Vector3(0,.08,-.30),Vector3(.12,.1,.035),Color("72eed4"));M.merge_children(head)
	if kind=="turret":
		var head=parent.get_node("TurretHead")
		for side in [-1,1]:
			M.tapered(head,Vector3(side*.33,-.035,.03),Vector3(.15,.40,.50),metal,.65)
			M.cylinder(head,Vector3(side*.33,0,.02),.105,.16,Color("8e9b9c"),Vector3(0,0,PI/2),-1,16)
			M.box(head,Vector3(side*.38,-.10,.11),Vector3(.18,.24,.33),color)
			for z in [-.13,-.055,.02,.095]:M.box(head,Vector3(side*.402,.06,z),Vector3(.035,.12,.023),metal)
			for i in range(5):M.cylinder(head,Vector3(side*.16,0,-.32-i*.07),.077,.018,Color("74858b"),Vector3(PI/2,0,0),-1,12)
			M.cylinder(head,Vector3(side*.16,0,-.892),.049,.004,Color("121c23"),Vector3(PI/2,0,0),-1,12)
		M.box(head,Vector3(0,.235,-.12),Vector3(.25,.14,.22),metal)
		M.cylinder(head,Vector3(0,.235,-.242),.050,.012,Color("61d7dd"),Vector3(PI/2,0,0),-1,16)
		M.cylinder(head,Vector3(.27,.30,.15),.012,.34,metal)
		M.cylinder(parent,Vector3(0,1.10,0),.24,.14,Color("889da0"),Vector3.ZERO,-1,16)
		M.cylinder(parent,Vector3(0,1.36,.05),.18,.45,metal,Vector3.ZERO,.21,20)
		M.cylinder(parent,Vector3(0,1.52,.05),.25,.08,Color("9aa9a7"),Vector3.ZERO,-1,20)
		for side in [-1,1]:M.box(parent,Vector3(side*.28,1.42,.04),Vector3(.10,.43,.25),metal,Vector3(0,0,side*.10))
		for i in range(3):
			var angle=TAU*i/3.
			var anchor=Vector3(cos(angle)*.38,.42,sin(angle)*.38)
			M.cylinder(parent,anchor,.048,.64,Color("b3c2bd"),Vector3(sin(angle)*.6,0,cos(angle)*.6),-1,12)
			M.box(parent,Vector3(cos(angle)*.57,.07,sin(angle)*.57),Vector3(.24,.12,.26),metal)
		M.merge_children(head)
	else:
		for x in [-1.1,0,1.1]:
			M.box(parent,Vector3(x,.23,-.355),Vector3(.86,.20,.018),metal)
			for dx in [-.38,.38]:
				for y in [.25,1.08]:M.cylinder(parent,Vector3(x+dx,y,-.36),.025,.025,Color("b0bebd"),Vector3(PI/2,0,0),-1,8)
			M.box(parent,Vector3(x,1.28,0),Vector3(.85,.08,.69),Color("7d939c"))
	# A shared deployment language: anchored feet, team inserts, latches and status lamps.
	var accent=Color("66cfff") if team==0 else Color("ffb465")
	if kind=="turret":
		var head=parent.get_node("TurretHead")
		M.cylinder(parent,Vector3(0,.12,0),.77,.18,metal,Vector3.ZERO,.65,16)
		M.tapered(parent,Vector3(0,.53,.04),Vector3(.74,.72,.68),color,.76)
		M.cylinder(parent,Vector3(0,1.02,0),.30,.16,Color("92a1a4"),Vector3.ZERO,-1,16)
		for side in [-1,1]:
			M.box(parent,Vector3(side*.47,.75,.08),Vector3(.23,.67,.27),metal,Vector3(0,0,side*-.25))
			M.cylinder(parent,Vector3(side*.40,1.04,.08),.12,.12,Color("bbc5bf"),Vector3(0,0,PI/2),-1,16)
			M.box(head,Vector3(side*.39,-.06,.05),Vector3(.27,.44,.59),color)
			M.box(head,Vector3(side*.55,-.04,.16),Vector3(.16,.34,.40),metal)
			for z in [-.05,.02,.09]:M.box(head,Vector3(side*.48,.18,z),Vector3(.17,.025,.027),Color("131d23"))
			for x in [side*.20,side*.36]:M.cylinder(head,Vector3(x,-.03,-.48),.031,.67,Color("89999e"),Vector3(PI/2,0,0),-1,12)
			M.box(head,Vector3(side*.19,-.07,-.78),Vector3(.20,.13,.14),metal)
			M.cylinder(head,Vector3(side*.19,-.07,-.858),.047,.012,Color("11181c"),Vector3(PI/2,0,0),-1,12)
			M.box(parent,Vector3(side*.68,.12,.15),Vector3(.30,.20,.86),color,Vector3(0,side*.30,0))
		M.box(head,Vector3(0,.20,-.14),Vector3(.24,.22,.30),metal)
		var eye=M.sphere(head,Vector3(0,.21,-.301),Vector3(.13,.09,.018),accent);eye.material_override=glow(accent)
		M.box(parent,Vector3(0,.62,-.315),Vector3(.42,.20,.025),metal)
		for i in [-1,0,1]:
			var lamp=M.box(parent,Vector3(i*.095,.64,-.334),Vector3(.052,.060,.015),accent);lamp.material_override=glow(accent)
		M.merge_children(head)
	else:
		for x in [-1.3,1.3]:
			M.box(parent,Vector3(x,.11,0),Vector3(.38,.18,1.15),metal)
			M.box(parent,Vector3(x,.70,-.32),Vector3(.13,1.06,.08),accent)
			M.box(parent,Vector3(x,1.33,0),Vector3(.32,.07,.45),metal)
		for i in [-1,0,1]:
			M.box(parent,Vector3(i*.19,.79,-.344),Vector3(.10,.28,.028),accent,Vector3(0,0,-.40))
		M.box(parent,Vector3(0,1.04,-.35),Vector3(.40,.13,.032),metal)
	M.merge_children(parent)
func throw_item(from:Vector3,to:Vector3):
	var node=group(from);M.cylinder(node,Vector3.ZERO,.08,.22,Color("a4b8a7"));M.cylinder(node,Vector3(0,.13,0),.055,.05,Color("e7d197"))
	var tween=node.create_tween();tween.tween_method(func(t):
		if is_instance_valid(node):node.position=from.lerp(to,t)+Vector3.UP*sin(t*PI)*2.;node.rotation=Vector3(t*7,0,t*4),0.,1.,.35)
	finish(node,.36)

var casings:Array=[]
var scuffs:Array=[]
const MAX_CASINGS=72
const CASING_LIFETIME=8.0
const MAX_SCUFFS=36
func eject_case(origin:Vector3,right:Vector3,up:Vector3,ground_y:float,seed_value:int=0):
	while casings.size()>=[18,40,MAX_CASINGS][GraphicsOptions.detail]:
		var old=casings.pop_front()
		if is_instance_valid(old.node):old.node.queue_free()
	var node=Node3D.new();add_child(node);node.position=origin
	var mesh=M.cylinder(node,Vector3.ZERO,.012,.054,Color("b99449"),Vector3(0,0,PI/2),.010,12);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	M.cylinder(node,Vector3(-.027,0,0),.014,.004,Color("e0c784"),Vector3(0,0,PI/2),-1,12)
	M.cylinder(node,Vector3(.028,0,0),.009,.002,Color("453d2a"),Vector3(0,0,PI/2),-1,12)
	M.cylinder(node,Vector3(-.030,0,0),.005,.002,Color("716c57"),Vector3(0,0,PI/2),-1,10)
	M.merge_children(node)
	var variation=sin(float(seed_value)*2.31)
	casings.append({"node":node,"velocity":right*(1.55+variation*.22)+up*(1.15+variation*.12),"floor":ground_y+.025,"age":0.,"bounced":false,"spin":Vector3(8,12,9+variation*3)})
func _process(dt:float):
	update_healing(dt)
	for item in casings.duplicate():
		if not is_instance_valid(item.node):casings.erase(item);continue
		item.age+=dt
		if item.age>CASING_LIFETIME:item.node.queue_free();casings.erase(item);continue
		item.velocity.y-=7.5*dt;item.node.position+=item.velocity*dt;item.node.rotation+=item.spin*dt
		if item.node.position.y<float(item.floor):
			item.node.position.y=item.floor
			if item.bounced:item.node.rotation=Vector3(0,item.node.rotation.y,0)
			if not item.bounced:item.velocity=Vector3(item.velocity.x*.35,absf(item.velocity.y)*.28,item.velocity.z*.35);item.bounced=true;item.spin*=.2
			else:item.velocity=Vector3.ZERO;item.spin=Vector3.ZERO
		item.node.scale=Vector3.ONE*clampf((CASING_LIFETIME-float(item.age))/.7,0,1)
func armor_impact(pos:Vector3,push:Vector3,color:Color):
	var node=group(pos);var t=node.create_tween().set_parallel(true)
	for i in range(6):
		var spark=M.box(node,Vector3.ZERO,Vector3(.025,.025,.09),color)
		spark.material_override=glow(color);spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var direction=push*.22+Vector3(randf_range(-.35,.35),randf_range(.08,.4),randf_range(-.35,.35))
		t.tween_property(spark,"position",direction,.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);t.tween_property(spark,"scale",Vector3.ZERO,.25)
	finish(node,.27)
func scuff(pos:Vector3):
	# Neutral impact dust, never biological material. A small quad works in Compatibility.
	while scuffs.size()>=MAX_SCUFFS:
		var old=scuffs.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(.26,.19);node.mesh=plane;node.position=pos;node.rotation.y=randf()*TAU;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override=glow(Color(.22,.25,.25,.28));add_child(node);scuffs.append(node)
	var fade=node.create_tween();fade.tween_interval(3.5);fade.tween_property(node.material_override,"albedo_color:a",0.,1.);fade.tween_callback(node.queue_free)

func temporary_light(pos:Vector3,color:Color,energy:float,radius:float,seconds:float):
	if active_lights>=6:return
	var light=OmniLight3D.new();add_child(light);light.position=pos;light.light_color=color;light.light_energy=energy;light.omni_range=radius;light.omni_attenuation=1.5;light.shadow_enabled=false;active_lights+=1
	light.tree_exited.connect(func():active_lights=maxi(0,active_lights-1))
	var t=light.create_tween();t.tween_property(light,"light_energy",0.,seconds);t.tween_callback(light.queue_free)
func muzzle_light(pos:Vector3):temporary_light(pos,Color("ffc77b"),1.3,3.8,.075)
func explosion(pos:Vector3,fire:bool=true):
	transients=transients.filter(func(n):return is_instance_valid(n))
	while transients.size()>=96:
		var old=transients.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node=BurstVisual.new();add_child(node);node.position=pos;node.set_meta("explosion",true);node.build(fire)
	temporary_light(pos+Vector3.UP*.3,Color("ffc78a"),6.,10.,.20)
	transients.append(node)
func skill_burst(role:int,pos:Vector3,color:Color):
	var node=group(pos);var radius=[2.5,12.,2.2,2.,5.,2.4][role]
	for i in range(3):
		var halo=ring(node,.55,Color(color,.75));halo.position.y=.12+i*.35
		var t=node.create_tween().set_parallel(true);t.tween_property(halo,"scale",Vector3(radius,1.,radius),.75).set_delay(i*.08);t.tween_property(halo.material_override,"albedo_color:a",0.,.7).set_delay(i*.08)
	finish(node,1.05)
func healing_link(game:Node,from:Vector3,to:Vector3,owner:int,target:int,repairing:bool=false):
	if not healing.has(owner):
		var stream=HealingStream.new();add_child(stream);healing[owner]={"node":stream}
	var link=healing[owner];link.merge({"game":game,"from":from,"to":to,"target":target,"until":Time.get_ticks_msec()+350,"repair":repairing},true)
	# Populate the mesh on the event frame, including first shader compilation.
	link.node.draw_link(from,to,1./60.,repairing)
func update_healing(dt:float):
	for owner in healing.keys():
		var link=healing[owner]
		if Time.get_ticks_msec()>int(link.until) or not is_instance_valid(link.game):link.node.queue_free();healing.erase(owner);continue
		var from:Vector3=link.from;var to:Vector3=link.to;var game=link.game
		if game.actors.has(owner):from=game.actors[owner].visual_muzzle()
		if game.actors.has(link.target):
			var target=game.actors[link.target];to=target.position+Vector3.UP*(.90 if target.input_state.crouch else 1.15)*target.body_height/1.8
		if from.distance_squared_to(to)>.001:link.node.draw_link(from,to,dt,link.repair)
func sync_grenades(items:Array,now:float):
	var live={}
	for item in items:
		live[item.id]=true
		if not grenade_nodes.has(item.id):
			var node=Node3D.new();add_child(node);EquipmentPreview.grenade_model(node);M.merge_children(node);grenade_nodes[item.id]=node
		var node=grenade_nodes[item.id];node.position=item.pos-Vector3.UP*.17;node.rotation=Vector3.ZERO if item.held else Vector3(now*4.,now*3.,now*2.)
	for id in grenade_nodes.keys():
		if not live.has(id):grenade_nodes[id].queue_free();grenade_nodes.erase(id)
func sync_status(game:Node,now:float):
	var live={}
	for id in game.players:
		var p=game.players[id]
		if not p.alive or not game.actors.has(id):continue
		for status in ["shield","cleanse","mark","mounted"]:
			if float(p.get(status,0))<=now:continue
			var key=str(id)+status;live[key]=true
			if not status_nodes.has(key):
				var node=Node3D.new();add_child(node);status_nodes[key]=node
				var color=Color("67d4ff") if p.team==0 else Color("ffc36d")
				if status=="shield":
					var shield=M.sphere(node,Vector3(0,1.,-.3),Vector3(1.15,1.65,.28),color);shield.material_override=glow(Color(color,.22));shield.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				else:
					for y in [.14,1.1]:ring(node,.52,Color(color,.62)).position.y=y
			var node=status_nodes[key];node.position=game.actors[id].position;node.rotation.y=game.actors[id].aim_yaw
			if status!="shield":node.scale=Vector3.ONE*(1.+sin(now*5.)*.035)
	for key in status_nodes.keys():
		if not live.has(key):status_nodes[key].queue_free();status_nodes.erase(key)
func ragdoll(source:CharacterVisual,pos:Vector3,push:Vector3,role:int,team:int,facing:float,crouched:bool,velocity:Vector3,point:Vector3=Vector3.INF):
	while ragdolls.size()>=6:
		var old=ragdolls.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node=PhysicsRagdoll.new();add_child(node);node.build(source,pos,push,role,team,facing,crouched,velocity,point);ragdolls.append(node)
	return node
