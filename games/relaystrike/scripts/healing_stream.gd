extends Node3D
class_name HealingStream
var mesh:MeshInstance3D
var aura:MeshInstance3D
var clock=0.
var bend=Vector3.ZERO
static var beam_shader:Shader
static var aura_shader:Shader
func _ready():
	if beam_shader==null:
		beam_shader=Shader.new();beam_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
void fragment(){float edge=pow(max(0.,1.-abs(UV.y*2.-1.)),2.5);float flow=pow(.5+.5*sin(UV.x*46.-TIME*18.),8.);ALBEDO=mix(tint.rgb,vec3(.90,1.,.96),flow*.72);ALPHA=edge*(.55+flow*.40);}
"""
		aura_shader=Shader.new();aura_shader.code="""
shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 tint:source_color=vec4(.26,1.,.74,1.);
void fragment(){float rim=pow(1.-abs(dot(normalize(NORMAL),normalize(VIEW))),2.8);float wave=pow(.5+.5*sin(UV.y*18.-TIME*7.),6.);ALBEDO=tint.rgb;ALPHA=rim*(.12+wave*.24);}
"""
	mesh=MeshInstance3D.new();mesh.mesh=ImmediateMesh.new();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh);var mat=ShaderMaterial.new();mat.shader=beam_shader;mesh.material_override=mat
	aura=MeshFactory.sphere(self,Vector3.ZERO,Vector3(.69,.88,.50),Color.WHITE);aura.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;var glow=ShaderMaterial.new();glow.shader=aura_shader;aura.material_override=glow
func draw_link(from:Vector3,to:Vector3,dt:float,repairing:bool):
	clock+=dt;var camera=get_viewport().get_camera_3d();var direction=(to-from).normalized();var distance=from.distance_to(to)
	bend=bend.lerp(Vector3.UP*clampf(distance*.10,.12,.55)+Vector3(sin(clock*1.7)*.10,0,cos(clock*1.3)*.06),1.-exp(-dt*8.))
	var c1=from+direction*distance*.30+bend*.4;var c2=to-direction*distance*.24+bend
	var data:ImmediateMesh=mesh.mesh;data.clear_surfaces();data.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var tint=Color("ffd090") if repairing else Color("5de3bb");mesh.material_override.set_shader_parameter("tint",tint);aura.material_override.set_shader_parameter("tint",tint)
	for i in range(28):
		var a=i/28.;var b=(i+1)/28.;var p=from.bezier_interpolate(c1,c2,to,a);var q=from.bezier_interpolate(c1,c2,to,b)
		var view=(camera.global_position-(p+q)*.5).normalized() if camera else Vector3.FORWARD
		var side=(q-p).normalized().cross(view).normalized();var width=(.048 if repairing else .10)*( .62+sin(a*PI)*.38)
		for v in [[p-side*width,Vector2(a,0)],[q-side*width,Vector2(b,0)],[p+side*width,Vector2(a,1)],[p+side*width,Vector2(a,1)],[q-side*width,Vector2(b,0)],[q+side*width,Vector2(b,1)]]:data.surface_set_uv(v[1]);data.surface_add_vertex(v[0])
	data.surface_end();aura.position=to;aura.scale=Vector3(.69,.88,.50)*(1.+sin(clock*4.)*.025);aura.visible=not repairing
