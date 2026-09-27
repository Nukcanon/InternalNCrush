extends Node3D
class_name HealingStream
var mesh:MeshInstance3D
var aura:MeshInstance3D
var clock=0.
var bend=Vector3.ZERO
static var beam_shader:Shader
static var aura_shader:Shader
static var ribbon:ArrayMesh
func _ready():
	if beam_shader==null:
		beam_shader=Shader.new();beam_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
uniform vec3 endpoint=vec3(0.,0.,-1.);
uniform vec3 control1=vec3(0.,0.,-.3);
uniform vec3 control2=vec3(0.,0.,-.7);
uniform vec3 eye=vec3(0.,0.,1.);
uniform float beam_width=.1;
void vertex(){
 float t=UV.x;float s=1.-t;
 vec3 p=3.*s*s*t*control1+3.*s*t*t*control2+t*t*t*endpoint;
 vec3 tangent=3.*s*s*control1+6.*s*t*(control2-control1)+3.*t*t*(endpoint-control2);
 vec3 side=cross(normalize(tangent+vec3(.000001,0.,0.)),normalize(eye-p+vec3(0.,.000001,0.)));
 if(length(side)<.0001){side=vec3(1.,0.,0.);}
 VERTEX=p+normalize(side)*(UV.y*2.-1.)*beam_width*(.62+sin(t*3.14159265)*.38);
}
void fragment(){float edge=pow(max(0.,1.-abs(UV.y*2.-1.)),2.5);float flow=pow(.5+.5*sin(UV.x*46.-TIME*18.),8.);ALBEDO=mix(tint.rgb,vec3(.90,1.,.96),flow*.72);ALPHA=edge*(.55+flow*.40);}
"""
		aura_shader=Shader.new();aura_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
void fragment(){float rim=pow(1.-abs(dot(normalize(NORMAL),normalize(VIEW))),2.8);float wave=pow(.5+.5*sin(UV.y*18.-TIME*7.),6.);ALBEDO=tint.rgb;ALPHA=rim*(.12+wave*.24);}
"""
	if ribbon==null:
		var builder=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(28):
			var a=i/28.;var b=(i+1)/28.
			for uv in [Vector2(a,0),Vector2(b,0),Vector2(a,1),Vector2(a,1),Vector2(b,0),Vector2(b,1)]:
				builder.set_uv(uv);builder.set_normal(Vector3.UP);builder.add_vertex(Vector3(uv.x,uv.y,0))
		ribbon=builder.commit()
	mesh=MeshInstance3D.new();mesh.mesh=ribbon;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh);var mat=ShaderMaterial.new();mat.shader=beam_shader;mesh.material_override=mat
	aura=MeshFactory.sphere(self,Vector3.ZERO,Vector3(.69,.88,.50),Color.WHITE);aura.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;var glow=ShaderMaterial.new();glow.shader=aura_shader;aura.material_override=glow
func draw_link(from:Vector3,to:Vector3,dt:float,repairing:bool):
	clock+=dt;var camera=get_viewport().get_camera_3d();var direction=(to-from).normalized();var distance=from.distance_to(to)
	bend=bend.lerp(Vector3.UP*clampf(distance*.10,.12,.55)+Vector3(sin(clock*1.7)*.10,0,cos(clock*1.3)*.06),1.-exp(-dt*8.))
	var c1=from+direction*distance*.30+bend*.4;var c2=to-direction*distance*.24+bend
	var tint=Color("ffd090") if repairing else Color("5de3bb");mesh.material_override.set_shader_parameter("tint",tint);aura.material_override.set_shader_parameter("tint",tint)
	position=from
	mesh.material_override.set_shader_parameter("endpoint",to-from)
	mesh.material_override.set_shader_parameter("control1",c1-from)
	mesh.material_override.set_shader_parameter("control2",c2-from)
	mesh.material_override.set_shader_parameter("eye",camera.global_position-from if camera else Vector3(0,0,1))
	mesh.material_override.set_shader_parameter("beam_width",.048 if repairing else .10)
	mesh.custom_aabb=AABB(Vector3.ZERO,Vector3.ZERO).expand(to-from).expand(c1-from).expand(c2-from).grow(.15)
	aura.position=to-from;aura.scale=Vector3(.69,.88,.50)*(1.+sin(clock*4.)*.025);aura.visible=not repairing
