extends Node3D
class_name CombatFX
var field_nodes={}
var transients=[]
var healing={}
var grenade_nodes={}
var rocket_nodes=[]
var status_nodes={}
var ragdolls=[]
var explosion_pool:Array=[]
const MAX_EXPLOSIONS=8
var active_lights=0
const MAX_TRACERS=96
var tracers:Array=[]
var tracer_cursor=0
var tracer_mesh:CylinderMesh
var tracer_materials:Array=[]
var blood:BloodFX
static var cloud_shader:Shader
const M=preload("res://scripts/mesh_factory.gd")
func clear(keep_tracers:bool=false):
	var pooled={}
	if keep_tracers:
		for item in tracers:item.node.hide();item.until=0;pooled[item.node]=true
		for node in explosion_pool:node.retire();pooled[node]=true
	for child in get_children():
		if not pooled.has(child):child.queue_free()
	field_nodes.clear();transients.clear();casings.clear();scuffs.clear();healing.clear();grenade_nodes.clear();status_nodes.clear();ragdolls.clear();rocket_nodes.clear();active_lights=0
	if not keep_tracers:tracers.clear();explosion_pool.clear()
	tracer_cursor=0
	blood=null;bomb_visual=null;bomb_beep_at=0.
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
func beam(from:Vector3,to:Vector3,heal=false,laser=false):
	var length=from.distance_to(to)
	if length<.02:return
	# Fixed geometry and a bounded pool avoid per-shot mesh uploads and tweens.
	if tracer_mesh==null:
		tracer_mesh=CylinderMesh.new();tracer_mesh.height=1.;tracer_mesh.top_radius=1.;tracer_mesh.bottom_radius=1.;tracer_mesh.radial_segments=6
		tracer_materials=[glow(Color(1,.81,.40,.72)),glow(Color(.3,1,.73,.85)),glow(Color(.72,.16,1.,.94))]
	var now=Time.get_ticks_msec();var available=-1
	for offset in range(tracers.size()):
		var candidate=(tracer_cursor+offset)%tracers.size()
		if int(tracers[candidate].until)<=now:available=candidate;break
	if available>=0:tracer_cursor=available
	elif tracers.size()<MAX_TRACERS:
		var mesh=MeshInstance3D.new();mesh.mesh=tracer_mesh;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)
		tracers.append({"node":mesh,"until":0})
		tracer_cursor=tracers.size()-1
	var item=tracers[tracer_cursor];tracer_cursor=(tracer_cursor+1)%tracers.size()
	var node:MeshInstance3D=item.node
	node.position=(from+to)*.5;node.quaternion=Quaternion(Vector3.UP,(to-from)/length)
	var width=.024 if laser else .018 if heal else .010
	node.scale=Vector3(width,length,width);node.material_override=tracer_materials[2 if laser else 1 if heal else 0];node.show()
	item.until=now+(115 if laser else 100 if heal else 48)
func burst(kind:String,pos:Vector3,color:Color):
	if kind in ["explosion","turret_break","cover_break"]:explosion(pos,kind!="cover_break");return
	var node=group(pos+Vector3.UP*.15);var explosive=kind=="explosion";var radius=5.5 if explosive else 1.9 if kind=="flash" else 1.15
	var life=.85 if explosive else .48;var halo=ring(node,.5,color);halo.position.y=.04
	var tween=node.create_tween().set_parallel(true);tween.tween_property(halo,"scale",Vector3(radius,.6,radius),life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(halo.material_override,"albedo_color:a",0.,life)
	var count=(8 if explosive else 4) if OS.has_feature("web") else (16 if explosive else 8)
	for i in range(count):
		var angle=TAU*i/count;var dir=Vector3(cos(angle),randf_range(.3,1.5),sin(angle)).normalized()
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
				var color=Color(.2,.68,1,.8) if field.team==0 else Color(1,.54,.18,.8);ring(node,AbilityBalance.SLOW_RADIUS,color).position.y=.06;ring(node,AbilityBalance.SLOW_RADIUS-.3,Color(color,.32)).position.y=.065
				var disc=M.cylinder(node,Vector3(0,.025,0),AbilityBalance.SLOW_RADIUS-.1,.02,Color(color,.10),Vector3.ZERO,-1.,48);disc.material_override=glow(Color(color,.10))
				for i in range(12):
					var a=TAU*i/12.;M.sphere(node,Vector3(cos(a)*(AbilityBalance.SLOW_RADIUS-.3),.15,sin(a)*(AbilityBalance.SLOW_RADIUS-.3)),Vector3(.14,.3,.14),Color(color,1.))
		var node=field_nodes[key]
		if field.kind=="smoke":
			var fade=clampf(float(field.until)-now,0.,1.)*clampf((now-float(field.get("starts",now-1.)))/.35,0.,1.)
			for cloud_mesh in node.get_children():cloud_mesh.material_override.set_shader_parameter("opacity",float(cloud_mesh.get_meta("density"))*fade)
		else:node.rotation.y=sin(now*.6)*.015
	for key in field_nodes.keys():
		if not live.has(key):field_nodes[key].queue_free();field_nodes.erase(key)
static var device_templates={}
static func prepare_devices():
	# Build every deployable template while the map is loading.
	for kind in ["turret","cover"]:
		for team in range(2):
			for variant in ([0,1,2] if kind=="cover" else [1]):
				var probe=Node3D.new();device(probe,kind,team,variant);probe.free()
# 1.4 cartoon deployables (GearModels). Templates are cached per kind/team/tier;
# children are moved into `parent` so game code finds "TurretHead" directly.
static func device(parent:Node3D,kind:String,team:int,variant:int=1):
	var key=kind+"_"+str(team)+"_"+str(clampi(variant,0,2) if kind=="cover" else 0)
	if not device_templates.has(key):
		var source=Node3D.new();source.name="DeviceAssembly"
		build_device(source,kind,team,variant)
		MeshFactory.own_recursive(source,source)
		var packed=PackedScene.new();packed.pack(source);source.free();device_templates[key]=packed
	var copy=device_templates[key].instantiate()
	for child in copy.get_children():
		MeshFactory.own_recursive(child,null);child.owner=null
		copy.remove_child(child);parent.add_child(child)
	copy.free()
static func build_device(parent:Node3D,kind:String,team:int,variant:int=1):
	if kind=="cover":GearModels.cover(parent,team,clampi(variant,0,2))
	else:GearModels.turret(parent,team)
func throw_item(from:Vector3,to:Vector3):
	var node=group(from);M.cylinder(node,Vector3.ZERO,.08,.22,Color("a4b8a7"));M.cylinder(node,Vector3(0,.13,0),.055,.05,Color("e7d197"))
	var tween=node.create_tween();tween.tween_method(func(t):
		if is_instance_valid(node):node.position=from.lerp(to,t)+Vector3.UP*sin(t*PI)*2.;node.rotation=Vector3(t*7,0,t*4),0.,1.,.35)
	finish(node,.36)

# 1.5.1 (the user: the ARC from a laser-weld recording): the beam's sound is a held
# loop per shooter while its effects keep coming (every 0.08 s), not a short clip
# re-started on top of itself.
var laser_hums={}
func laser_hum(game:Node,owner:int,at:Vector3):
	var bank=game.get("audio_bank")
	if not is_instance_valid(bank) or DisplayServer.get_name()=="headless":return
	var near=owner==game.local_id
	var item:Dictionary=laser_hums.get(owner,{})
	if item.is_empty() or not is_instance_valid(item.player):
		var stream=bank.loop_stream("laser_loop")
		if stream==null:return
		var volume=float(bank.catalog.get("laser_loop",{}).get("gain_db",-6.))
		var player:Node
		if near:player=AudioStreamPlayer.new()
		else:player=AudioStreamPlayer3D.new();player.max_distance=GameAudio.audible_range("link_loop");player.unit_size=6.
		player.stream=stream;player.volume_db=volume;add_child(player);player.play()
		item={"player":player}
		laser_hums[owner]=item
	if item.player is AudioStreamPlayer3D:item.player.global_position=at
	item.until=Time.get_ticks_msec()+160
func update_laser_hums():
	var now=Time.get_ticks_msec()
	for owner in laser_hums.keys():
		var item=laser_hums[owner]
		if not is_instance_valid(item.player):laser_hums.erase(owner);continue
		if now>int(item.until):item.player.queue_free();laser_hums.erase(owner)
var casings:Array=[]
var scuffs:Array=[]
const MAX_CASINGS=72
const CASING_LIFETIME=8.0
const MAX_SCUFFS=36
static var casing_template:PackedScene
func eject_case(origin:Vector3,right:Vector3,up:Vector3,ground_y:float,seed_value:int=0):
	while casings.size()>=[18,40,MAX_CASINGS][GraphicsOptions.detail]:
		var old=casings.pop_front()
		if is_instance_valid(old.node):old.node.queue_free()
	if casing_template==null:
		var source=Node3D.new()
		M.cylinder(source,Vector3.ZERO,.012,.054,Color("b99449"),Vector3(0,0,PI/2),.010,12)
		M.cylinder(source,Vector3(-.027,0,0),.014,.004,Color("e0c784"),Vector3(0,0,PI/2),-1,12)
		M.cylinder(source,Vector3(.028,0,0),.009,.002,Color("453d2a"),Vector3(0,0,PI/2),-1,12)
		M.cylinder(source,Vector3(-.030,0,0),.005,.002,Color("716c57"),Vector3(0,0,PI/2),-1,10)
		M.merge_children(source)
		for mesh in source.get_children():mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		M.own_recursive(source,source);casing_template=PackedScene.new();casing_template.pack(source);source.free()
	var node=casing_template.instantiate();add_child(node);node.position=origin
	var variation=sin(float(seed_value)*2.31)
	casings.append({"node":node,"velocity":right*(1.55+variation*.22)+up*(1.15+variation*.12),"floor":ground_y+.025,"age":0.,"bounced":false,"spin":Vector3(8,12,9+variation*3)})
func _process(dt:float):
	var stamp=Time.get_ticks_msec()
	for item in tracers:
		if item.node.visible and stamp>=int(item.until):item.node.hide()
	update_healing(dt)
	update_laser_hums()
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

# 1.5.1 (the user): an explosion (rocket, grenade, planted bomb) leaves a black
# scorch on the floor and the walls close by, which fades away after a while.
# Flat quads (decals are not drawn by the Compatibility renderer).
var scorches:Array=[]
const MAX_SCORCHES=32
const SCORCH_HOLD=20.
const SCORCH_FADE=6.
static var scorch_texture:ImageTexture
static func scorch_image() -> ImageTexture:
	if scorch_texture!=null:return scorch_texture
	var n=128;var img=Image.create(n,n,false,Image.FORMAT_RGBA8);var noise=FastNoiseLite.new();noise.seed=1515;noise.frequency=.06;noise.fractal_octaves=3
	for y in range(n):
		for x in range(n):
			var v=Vector2(x-n*.5+.5,y-n*.5+.5)/(n*.5);var r=v.length();var ang=atan2(v.y,v.x)
			var edge=.62+.22*noise.get_noise_2d(cos(ang)*40.,sin(ang)*40.)+.1*sin(ang*7.)
			var a=1.-smoothstep(edge*.55,edge,r)
			a*=.78+.22*noise.get_noise_2d(x*1.6,y*1.6)
			var core=1.-smoothstep(0.,.35,r)
			img.set_pixel(x,y,Color(.05+.03*(1.-core),.045+.02*(1.-core),.04,clampf(a*(.72+.28*core),0.,1.)))
	scorch_texture=ImageTexture.create_from_image(img);return scorch_texture
func scorch(pos:Vector3,radius:float=6.):
	# (the floor mark's width follows the blast radius: a grenade's 8 m about 5.5 m across)
	var size=clampf(radius*.7,1.5,14.)
	var space=get_world_3d().direct_space_state
	var floor=space.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.6,pos+Vector3.DOWN*2.5,1))
	if not floor.is_empty():scorch_mark(floor.position,floor.normal,size)
	var walls=0;var placed=[];var reach=clampf(radius*.45,1.2,7.)
	for i in range(8):
		if walls>=3:break
		var dir=Vector3(cos(i*TAU/8.),0.,sin(i*TAU/8.));var from=pos+Vector3.UP*.5
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+dir*reach,1))
		if hit.is_empty() or absf(hit.normal.y)>.5 or placed.any(func(n):return n.dot(hit.normal)>.9):continue # (one mark per wall)
		var near=1.-from.distance_to(hit.position)/reach
		scorch_mark(hit.position,hit.normal,size*(.45+.4*near),.12);walls+=1;placed.append(hit.normal)
func scorch_mark(at:Vector3,normal:Vector3,size:float,lift:float=.012):
	while scorches.size()>=MAX_SCORCHES:
		var old=scorches.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(size,size);node.mesh=plane;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_texture=scorch_image();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.render_priority=1
	node.material_override=mat;add_child(node)
	var up=normal.normalized();var basis=Basis(Quaternion(Vector3.UP,up))*Basis(Vector3.UP,randf()*TAU)
	node.global_transform=Transform3D(basis,at+up*(lift+scorches.size()*.0006)) # (walls: a little off - props such as shutters stand just proud of their collision)
	scorches.append(node)
	var fade=node.create_tween();fade.tween_interval(SCORCH_HOLD);fade.tween_property(mat,"albedo_color:a",0.,SCORCH_FADE);fade.tween_callback(node.queue_free)
func temporary_light(pos:Vector3,color:Color,energy:float,radius:float,seconds:float):
	# Eleven fixed map lights + five transient lights fit the per-surface budget.
	# A muzzle flash must never evict a permanent light from a merged wall/floor.
	if GraphicsOptions.lighting<2 or OS.has_feature("web") or active_lights>=2:return
	var light=OmniLight3D.new();add_child(light);light.position=pos;light.light_color=color;light.light_energy=energy;light.omni_range=radius;light.omni_attenuation=1.5;light.shadow_enabled=false;active_lights+=1
	light.tree_exited.connect(func():active_lights=maxi(0,active_lights-1))
	var t=light.create_tween();t.tween_property(light,"light_energy",0.,seconds);t.tween_callback(light.queue_free)
func muzzle_light(pos:Vector3):temporary_light(pos,Color("ffc77b"),1.3,3.8,.075)
func explosion(pos:Vector3,fire:bool=true,blast_scale:float=1.,bomb:bool=false,ghost:bool=false):
	var node:BurstVisual
	for candidate in explosion_pool:
		if not candidate.active:node=candidate;break
	if node==null and explosion_pool.size()<MAX_EXPLOSIONS:
		node=BurstVisual.new();node.pooled=true;add_child(node);explosion_pool.append(node)
	if node==null:
		# Replace the oldest lingering smoke, keeping fresh detonations visible.
		node=explosion_pool[0]
		for candidate in explosion_pool:
			if candidate.age>node.age:node=candidate
		node.retire()
	node.position=pos;node.set_meta("explosion",true);node.blast_scale=blast_scale;node.bomb=bomb;node.ghost=ghost;node.build(fire)
	temporary_light(pos+Vector3.UP*.3,Color("ffc78a"),6.,10.,.20)
## First explosion of a match stalled a frame (~60 ms: the burst's shaders and
## the first point light's lit variants compile). Draw a tiny, faint one in
## view once during the buy/lobby phase so the real one is ready.
func warm_effects(camera:Camera3D):
	if not is_instance_valid(camera):return
	var at=camera.global_position-camera.global_basis.z*3.+Vector3.DOWN*1.1
	explosion(at,true,.02,false,true)
	# explosion() lit the scene briefly at full strength; keep its range (every
	# lit surface nearby compiles its light variant) but make it invisible.
	for child in get_children():
		if child is OmniLight3D and child.global_position.distance_to(at+Vector3.UP*.3)<.01:child.light_energy=.002
func skill_burst(role:int,pos:Vector3,color:Color):
	var node=group(pos);var radius=[2.5,12.,2.2,2.,5.,2.4][role]
	for i in range(3):
		var halo=ring(node,.55,Color(color,.75));halo.position.y=.12+i*.35
		var t=node.create_tween().set_parallel(true);t.tween_property(halo,"scale",Vector3(radius,1.,radius),.75).set_delay(i*.08);t.tween_property(halo.material_override,"albedo_color:a",0.,.7).set_delay(i*.08)
	finish(node,1.05)
func healing_link(game:Node,from:Vector3,to:Vector3,owner:int,target:int,repairing:bool=false):
	if healing.has(owner) and int(healing[owner].target)!=target:
		# Switching allies: release the old link (with its sound) and start fresh.
		var old=healing[owner];old.node.end(old.game,owner,int(old.target));old.node.queue_free();healing.erase(owner)
	var fresh=not healing.has(owner)
	if fresh:
		var stream=HealingStream.new();add_child(stream);healing[owner]={"node":stream}
	var link=healing[owner];link.merge({"game":game,"from":from,"to":to,"target":target,"until":Time.get_ticks_msec()+350,"repair":repairing},true)
	if game.actors.has(target):link.to=torso(game.actors[target])
	# Populate the mesh on the event frame, including first shader compilation.
	link.node.position=from;link.node.draw_link(from,link.to,1./60.,repairing,aim(game,owner))
	if fresh:link.node.begin(game,owner,target,repairing)
## Torso centre of a hero (standing or crouched), where the heal stream lands.
static func torso(actor:Node3D) -> Vector3:
	return actor.global_position+Vector3.UP*(.78 if actor.input_state.crouch else 1.08)*float(actor.body_height)/1.8
static func aim(game:Node,owner:int) -> Vector3:
	if not game.actors.has(owner):return Vector3.ZERO
	var a=game.actors[owner];return Basis.from_euler(Vector3(a.aim_pitch,a.aim_yaw,0.))*Vector3.FORWARD
func update_healing(dt:float):
	for owner in healing.keys():
		var link=healing[owner]
		if Time.get_ticks_msec()>int(link.until) or not is_instance_valid(link.game):
			link.node.end(link.game,owner,int(link.target));link.node.queue_free();healing.erase(owner);continue
		var from:Vector3=link.from;var to:Vector3=link.to;var game=link.game
		if game.actors.has(owner):from=game.actors[owner].visual_muzzle()
		if game.actors.has(link.target):to=torso(game.actors[link.target])
		if from.distance_squared_to(to)>.001:link.node.draw_link(from,to,dt,link.repair,aim(game,owner))
func sync_grenades(items:Array,now:float,viewer:int=0):
	var live={}
	for item in items:
		live[item.id]=true
		if not grenade_nodes.has(item.id):
			var node=Node3D.new();add_child(node)
			GearModels.grenade(node,str(item.get("kind","frag")))
			grenade_nodes[item.id]=node
		var node=grenade_nodes[item.id];node.position=item.pos-Vector3.UP*.08;node.rotation=Vector3.ZERO if item.held else Vector3(item.get("rotation",Vector3.ZERO))
		# 1.4.4: the thrower's own grenade stays in the first-person hand until
		# the release point of the throw motion (Actor.THROW_RELEASE); the flying
		# one is hidden from them until then.
		node.visible=int(item.owner)!=viewer or (not item.held and now-float(item.get("released",-100.))>=Actor.THROW_TIME*Actor.THROW_RELEASE)
	for id in grenade_nodes.keys():
		if not live.has(id):grenade_nodes[id].queue_free();grenade_nodes.erase(id)
func sync_status(game:Node,now:float):
	var live={}
	for id in game.players:
		var p=game.players[id]
		if not p.alive or not game.actors.has(id):continue
		for status in ["shield","mounted"]:
			if float(p.get(status,0))<=now:continue
			var key=str(id)+status;live[key]=true
			if not status_nodes.has(key):
				var node=Node3D.new();add_child(node);status_nodes[key]=node
				var color=Color("67d4ff") if p.team==0 else Color("ffc36d")
				if status=="shield":
					var shield=M.box(node,Vector3(0,1.36,-.78),Vector3(1.6,2.55,.10),color,Vector3.ZERO,.12);shield.material_override=glow(Color(color,.12));shield.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					for side in [-1,1]:
						var edge=M.box(node,Vector3(side*.8,1.36,-.78),Vector3(.022,2.55,.022),color);edge.material_override=glow(Color(color,.72))
					for y in [.085,2.635]:
						var edge=M.box(node,Vector3(0,y,-.78),Vector3(1.6,.022,.022),color);edge.material_override=glow(Color(color,.72))
				else:
					for y in [.14,1.1]:ring(node,.52,Color(color,.62)).position.y=y
			var node=status_nodes[key];node.position=game.actors[id].position;node.rotation.y=game.actors[id].aim_yaw
			if status!="shield":node.scale=Vector3.ONE*(1.+sin(now*5.)*.035)
	for key in status_nodes.keys():
		if not live.has(key):status_nodes[key].queue_free();status_nodes.erase(key)
func ragdoll(source:HeroCharacter,pos:Vector3,push:Vector3,role:int,team:int,facing:float,crouched:bool,velocity:Vector3,point:Vector3=Vector3.INF):
	var physical=GraphicsOptions.physics_effects>0 and GraphicsOptions.corpse_quality>0 and not OS.has_feature("web")
	ragdolls=ragdolls.filter(func(item):return is_instance_valid(item) and not item.is_queued_for_deletion())
	while ragdolls.size()>=((4 if GraphicsOptions.corpse_quality==2 else 2) if physical else 3 if OS.has_feature("web") else 4):
		var old=ragdolls.pop_front()
		if is_instance_valid(old):old.queue_free()
	var node:Node3D=HeroRagdoll.new() if physical else HeroDeath.new()
	var _t=Prof.now();add_child(node);node.build(source,pos,push,role,team,facing,crouched,velocity,point);ragdolls.append(node);Prof.add("death_ragdoll",_t)
	return node

func sync_rockets(rockets:Array):
	while rocket_nodes.size()>rockets.size():
		var old=rocket_nodes.pop_back()
		if is_instance_valid(old):old.queue_free()
	for i in range(rockets.size()):
		if i>=rocket_nodes.size() or not is_instance_valid(rocket_nodes[i]):
			var n=Node3D.new();add_child(n)
			# Nose first: look_at points -Z along the flight, so the cone narrows
			# toward -Z and the exhaust flame trails at +Z.
			LauncherModels.parts(n,.05,.30,.13)
			var flame=M.sphere(n,Vector3(0,0,.27),Vector3(.12,.12,.26),Color("ffb143"));flame.material_override=glow(Color("ffb143"))
			if i>=rocket_nodes.size():rocket_nodes.append(n)
			else:rocket_nodes[i]=n
		var n=rocket_nodes[i];n.position=rockets[i].pos
		# 1.5.0 (the user: a launcher's rocket left from the middle of the screen):
		# the shooter sees his own rocket leave the drawn launcher's muzzle, joining
		# the true flight (from the eye-side muzzle point) over its first 6 m.
		var g=get_parent();var owner=int(rockets[i].get("owner",0))
		if rockets[i].has("origin") and bool(rockets[i].get("launcher",false)) and g.actors.has(owner):
			var origin:Vector3=rockets[i].origin
			if not n.has_meta("origin") or Vector3(n.get_meta("origin"))!=origin:n.set_meta("origin",origin);n.set_meta("drawn_from",g.actors[owner].visual_muzzle())
			var join=clampf(1.-Vector3(rockets[i].pos).distance_to(origin)/6.,0.,1.)
			n.position+=(Vector3(n.get_meta("drawn_from"))-origin)*smoothstep(0.,1.,join)
		n.look_at(n.position+rockets[i].velocity)
		if Time.get_ticks_msec()>=int(n.get_meta("flight_sound",0)):
			n.set_meta("flight_sound",Time.get_ticks_msec()+500)
			get_parent().play_sound("rocket_flight",n.global_position,true)

var bomb_visual:Node3D
var bomb_beep_at=0.
var bomb_defuse_at=0.
func sync_bomb(game:Node):
	var present=int(game.options.mode)==4 and not game.bomb.get("exploded",false) and (game.bomb.planted or game.bomb.get("dropped",false) or int(game.bomb.get("carrier",0))!=0)
	if not present:
		if is_instance_valid(bomb_visual):bomb_visual.hide()
		return
	if not is_instance_valid(bomb_visual):
		bomb_visual=Node3D.new();add_child(bomb_visual);BombLogic.model(bomb_visual)
	var carrier=int(game.bomb.get("carrier",0))
	bomb_visual.visible=carrier!=game.local_id or carrier==0
	bomb_visual.rotation=Vector3.ZERO
	bomb_visual.scale=Vector3.ONE*(.52 if carrier else .72)
	if carrier and game.actors.has(carrier):
		var actor=game.actors[carrier]
		var height=float(HeroCharacter.HEIGHTS[int(game.players[carrier].role)])/1.8
		bomb_visual.position=actor.position+Vector3.UP*(.95*height-(.42 if actor.input_state.crouch else 0.))+Basis(Vector3.UP,actor.aim_yaw)*Vector3(0,0,.24)
		# Flat underside against the back; the former upward beacon now faces out.
		bomb_visual.basis=(Basis(Vector3.UP,actor.aim_yaw)*Basis(Vector3.RIGHT,PI/2.)).scaled(Vector3.ONE*.52)
		if BombHandling.active(actor):
			bomb_visual.position=actor.position+Vector3.UP*.65+Basis(Vector3.UP,actor.aim_yaw)*Vector3(0,0,-.43);bomb_visual.rotation=Vector3(0,actor.aim_yaw,0)
	else:bomb_visual.position=game.bomb.position
	var interval=BombLogic.beep_interval(game.bomb.time,float(game.bomb.get("total_time",float(game.options.get("bomb_seconds",45))))) if game.bomb.planted else .6
	var lamp=bomb_visual.get_node("Beacon");lamp.visible=fmod(game.clock,interval)<interval*.4
	if game.bomb.planted and game.phase=="combat" and game.clock>=bomb_beep_at:
		bomb_beep_at=game.clock+interval;game.play_sound("bomb_beep",game.bomb.position,true)
	var worker=int(game.bomb.get("actor",0))
	if game.bomb.planted and game.phase=="combat" and worker!=0 and game.players.has(worker) and int(game.players[worker].team)!=MatchFlow.attackers(game) and game.clock>=bomb_defuse_at:
		bomb_defuse_at=game.clock+.38;game.play_sound("bomb_defuse",game.bomb.position,true)


# 1.4.5 PIPER / MENDER: a bold green "+" where a healing round lands on an
# ally, a little random in size and opacity, popping in, rising and fading.
func heal_plus(pos:Vector3):
	var node=group(pos+Vector3(randf_range(-.04,.04),randf_range(-.04,.04),randf_range(-.04,.04)))
	# (the user: each "+" turns slowly at its own speed, either way round, while
	# it rises and fades; size, rise speed and spin all random within bounds)
	var size=randf_range(.15,.22);var alpha=randf_range(.6,.95)
	var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test=true;mat.albedo_color=Color(.28,1.,.42,alpha);mat.render_priority=2
	for bar in [Vector2(size,size*.32),Vector2(size*.32,size)]:
		var quad=MeshInstance3D.new();var mesh=QuadMesh.new();mesh.size=bar;quad.mesh=mesh;quad.material_override=mat;quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.add_child(quad)
	var life=randf_range(.85,1.15);var start=node.position
	var rise=Vector3(randf_range(-.06,.06),randf_range(.32,.5),randf_range(-.06,.06))
	var spin=randf_range(1.,2.2)*(1. if randf()<.5 else -1.);var roll0=randf()*TAU
	var drive=func(t:float):
		if not is_instance_valid(node):return
		var camera=node.get_viewport().get_camera_3d() if node.is_inside_tree() else null
		var facing=camera.global_basis.orthonormalized() if camera else Basis.IDENTITY
		var grow=minf(1.,t*life/.12);var pop=.3+.7*(1.+.25*sin(PI*grow))*grow if grow<1. else 1.
		node.position=start+rise*t*life
		node.global_basis=facing*Basis(Vector3(0,0,1),roll0+spin*t*life).scaled(Vector3.ONE*pop)
		mat.albedo_color.a=alpha*(1. if t<.4 else 1.-(t-.4)/.6)
	drive.call(0.)
	var tween=node.create_tween();tween.tween_method(drive,0.,1.,life);tween.tween_callback(node.queue_free)
func heal_area(pos:Vector3):
	var node=group(pos)
	var ring=MeshInstance3D.new();var mesh=TorusMesh.new();mesh.inner_radius=3.92;mesh.outer_radius=4.;mesh.rings=24;mesh.ring_segments=6;ring.mesh=mesh;ring.material_override=glow(Color(.25,1.,.65,.6));ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.add_child(ring)
	var tween=node.create_tween();node.scale=Vector3.ONE*.1;tween.tween_property(node,"scale",Vector3.ONE,.25);tween.tween_interval(.35);tween.tween_callback(node.queue_free)
