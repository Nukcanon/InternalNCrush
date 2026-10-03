extends Node3D
class_name HealingStream
## LINK / FIX beam (1.4.2): a medigun / caduceus style stream from the muzzle to
## the ally's torso. One draw call carries four strands: a soft glow sleeve, a
## bright core that sways gently, and two thin strands braided round it whose
## wave travels from the gun to the ally. The beam leaves the muzzle along the
## aim and bends toward the ally, trailing the aim like an elastic stream.
var mesh:MeshInstance3D
var aura:MeshInstance3D
var flare:MeshInstance3D
var crosses:CPUParticles3D
var hum:Node
var clock=0.
var lead=Vector3.ZERO
var sag=Vector3.ZERO
var started=false
static var beam_shader:Shader
static var aura_shader:Shader
static var flare_shader:Shader
static var ribbon:ArrayMesh
static var cross_texture:ImageTexture
const SEGMENTS=40
const STRANDS=4
func _ready():
	if beam_shader==null:
		beam_shader=Shader.new();beam_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never,blend_add,shadows_disabled;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
uniform vec3 endpoint=vec3(0.,0.,-1.);
uniform vec3 control1=vec3(0.,0.,-.3);
uniform vec3 control2=vec3(0.,0.,-.7);
uniform vec3 eye=vec3(0.,0.,1.);
uniform float beam_width=.1;
uniform float wave_amp=.06;
uniform float strength=1.;
varying float strand;
varying float along;
varying float phase;
void vertex(){
 float t=UV.x;float s=1.-t;strand=UV2.x;along=t;
 vec3 p=3.*s*s*t*control1+3.*s*t*t*control2+t*t*t*endpoint;
 vec3 tangent=normalize(3.*s*s*control1+6.*s*t*(control2-control1)+3.*t*t*(endpoint-control2)+vec3(.000001,0.,0.));
 vec3 side=cross(tangent,normalize(eye-p+vec3(0.,.000001,0.)));
 side=length(side)<.0001?vec3(1.,0.,0.):normalize(side);
 vec3 up=normalize(cross(side,tangent));
 float len=length(endpoint);
 // Ends stay pinned to the muzzle and the ally; about one wave per 1.4 m.
 float pin=sin(3.14159265*t);
 phase=t*6.2831853*max(1.,len/1.4)-TIME*10.;
 float open=smoothstep(0.,.12,t);
 float width=beam_width;vec3 offset=vec3(0.);
 if(strand<.5){width=beam_width*2.3*(.45+.55*open)*(.9+.1*sin(phase*.5));}
 else if(strand<1.5){width=beam_width*.42*(.5+.5*open);offset=side*sin(phase*.5)*wave_amp*.45*pin;}
 else{float turn=strand<2.5?0.:3.14159265;width=beam_width*.2;offset=(side*sin(phase+turn)+up*cos(phase+turn))*wave_amp*pin*(.35+.65*open);}
 VERTEX=p+offset+side*(UV.y*2.-1.)*width;
}
void fragment(){
 float across=abs(UV.y*2.-1.);
 // Smooth bands of light roll along the stream toward the ally (no dots).
 float roll=.5+.5*sin(phase*.5);
 float ends=smoothstep(0.,.03,along)*mix(1.,.55,smoothstep(.93,1.,along));
 vec3 color=tint.rgb;float alpha;
 if(strand<.5){alpha=pow(1.-across,2.2)*(.20+.12*roll);}
 else if(strand<1.5){alpha=pow(1.-across,1.4)*(.75+.25*roll);color=mix(tint.rgb,vec3(1.),.55);}
 else{alpha=pow(1.-across,1.1)*(.45+.35*roll);color=mix(tint.rgb,vec3(1.),.25);}
 ALBEDO=color;ALPHA=clamp(alpha*ends*strength,0.,1.);
}
"""
		aura_shader=Shader.new();aura_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never,blend_add,shadows_disabled;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
void fragment(){float rim=pow(1.-abs(dot(normalize(NORMAL),normalize(VIEW))),2.6);float wave=pow(.5+.5*sin(UV.y*14.-TIME*5.),4.);ALBEDO=tint.rgb;ALPHA=rim*(.10+wave*.20);}
"""
		flare_shader=Shader.new();flare_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never,blend_add,shadows_disabled;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
void fragment(){float core=pow(abs(dot(normalize(NORMAL),normalize(VIEW))),3.);ALBEDO=mix(tint.rgb,vec3(1.),core*.6);ALPHA=core*(.55+.25*sin(TIME*18.));}
"""
	if ribbon==null:
		var builder=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for strand in range(STRANDS):
			for i in range(SEGMENTS):
				var a=i/float(SEGMENTS);var b=(i+1)/float(SEGMENTS)
				for uv in [Vector2(a,0),Vector2(b,0),Vector2(a,1),Vector2(a,1),Vector2(b,0),Vector2(b,1)]:
					builder.set_uv(uv);builder.set_uv2(Vector2(strand,0));builder.set_normal(Vector3.UP);builder.add_vertex(Vector3(uv.x,uv.y,0))
		ribbon=builder.commit()
	if cross_texture==null:
		# Soft white "+" for the rising heal crosses (TF2 / Overwatch style).
		var image=Image.create(32,32,false,Image.FORMAT_RGBA8)
		for y in range(32):
			for x in range(32):
				var dx=absf(x-15.5);var dy=absf(y-15.5)
				# Distance inside the vertical or horizontal bar, softened over 1.5 px.
				var inside=maxf(minf(4.5-dx,13.5-dy),minf(4.5-dy,13.5-dx))
				image.set_pixel(x,y,Color(1,1,1,clampf(inside/1.5,0.,1.)))
		cross_texture=ImageTexture.create_from_image(image)
	mesh=MeshInstance3D.new();mesh.mesh=ribbon;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh);var mat=ShaderMaterial.new();mat.shader=beam_shader;mesh.material_override=mat
	aura=MeshFactory.sphere(self,Vector3.ZERO,Vector3(.66,.86,.48),Color.WHITE);aura.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;var glow=ShaderMaterial.new();glow.shader=aura_shader;aura.material_override=glow
	flare=MeshFactory.sphere(self,Vector3.ZERO,Vector3.ONE*.045,Color.WHITE);flare.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;var spark=ShaderMaterial.new();spark.shader=flare_shader;flare.material_override=spark
	crosses=CPUParticles3D.new();crosses.amount=7;crosses.lifetime=1.1;crosses.local_coords=false
	crosses.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;crosses.emission_sphere_radius=.34
	crosses.direction=Vector3.UP;crosses.spread=18.;crosses.gravity=Vector3.ZERO;crosses.initial_velocity_min=.45;crosses.initial_velocity_max=.7
	crosses.scale_amount_min=.8;crosses.scale_amount_max=1.2
	var quad=QuadMesh.new();quad.size=Vector2(.085,.085);crosses.mesh=quad
	var cross_mat=StandardMaterial3D.new();cross_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;cross_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	cross_mat.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES;cross_mat.vertex_color_use_as_albedo=true;cross_mat.albedo_texture=cross_texture;cross_mat.no_depth_test=false
	quad.material=cross_mat
	var ramp=Gradient.new();ramp.set_color(0,Color(1,1,1,0.));ramp.add_point(.18,Color(1,1,1,.95));ramp.set_color(ramp.get_point_count()-1,Color(1,1,1,0.));crosses.color_ramp=ramp
	crosses.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(crosses)
## The looping hum (the owner and the healed ally hear it
## unpositioned; everyone else hears it at the muzzle).
func begin(game:Node,owner:int,target:int,repairing:bool):
	if started:return
	started=true
	var bank=game.get("audio_bank")
	if not is_instance_valid(bank) or DisplayServer.get_name()=="headless":return
	var near=owner==game.local_id or target==game.local_id
	# (1.5.4, the user: no electronic "beep" on connecting - LINK and FIX start with the hum alone)
	var stream=bank.loop_stream("repair_loop" if repairing else "link_loop")
	if stream==null or bank.profile.get("gunfire_reduction",false):return
	var data=bank.catalog.get("repair_loop" if repairing else "link_loop",{})
	var volume=float(data.get("gain_db",-9.))-(6. if owner!=game.local_id and near else 0.)
	if near:
		var player=AudioStreamPlayer.new();player.stream=stream;player.volume_db=volume;hum=player
	else:
		var player=AudioStreamPlayer3D.new();player.stream=stream;player.volume_db=volume;player.max_distance=GameAudio.audible_range("repair_loop" if repairing else "link_loop");player.unit_size=5.;hum=player
	add_child(hum);hum.play()
func end(game:Node,owner:int,target:int):
	# (1.5.4, the user: no falling "pew" when a link ends either - the hum just stops with the node)
	pass
func draw_link(from:Vector3,to:Vector3,dt:float,repairing:bool,aim:Vector3=Vector3.ZERO):
	clock+=dt;var camera=get_viewport().get_camera_3d();var direction=(to-from).normalized();var distance=from.distance_to(to)
	var follow=1.-exp(-dt*9.)
	# Leave the muzzle along the aim, then bend toward the ally (a trailing stream).
	var wanted_lead=(aim.normalized() if aim.length_squared()>.01 else direction)*distance*.34
	lead=wanted_lead if lead==Vector3.ZERO else lead.lerp(wanted_lead,follow)
	sag=sag.lerp(Vector3.UP*clampf(distance*.025,.03,.25)+Vector3(sin(clock*1.7)*.05,0,cos(clock*1.3)*.04),follow)
	# Highest near the muzzle, easing into the ally (no hook at the end).
	var c1=from+lead+sag;var c2=to-direction*distance*.3+sag*.45
	var tint=Color("ffc978") if repairing else Color("5de3bb")
	for part in [mesh,aura,flare]:part.material_override.set_shader_parameter("tint",tint)
	crosses.color=tint.lightened(.35)
	position=from
	var beam:ShaderMaterial=mesh.material_override
	beam.set_shader_parameter("endpoint",to-from)
	beam.set_shader_parameter("control1",c1-from)
	beam.set_shader_parameter("control2",c2-from)
	beam.set_shader_parameter("eye",camera.global_position-from if camera else Vector3(0,0,1))
	beam.set_shader_parameter("beam_width",.05 if repairing else .075)
	beam.set_shader_parameter("wave_amp",.035 if repairing else .06)
	mesh.custom_aabb=AABB(Vector3.ZERO,Vector3.ZERO).expand(to-from).expand(c1-from).expand(c2-from).grow(.3)
	aura.position=to-from;aura.scale=Vector3(.66,.86,.48)*(1.+sin(clock*4.)*.03);aura.visible=not repairing
	crosses.position=to-from;crosses.emitting=not repairing
	flare.scale=Vector3.ONE*.045*(1.+sin(clock*21.)*.12)
