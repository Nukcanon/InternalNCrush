class_name MeleeMark
extends RefCounted
static var materials={}
static func make(web:bool,wrench:bool) -> MeshInstance3D:
	var key=str(web)+str(wrench)
	if not materials.has(key):
		var shader=Shader.new();shader.code=CODE
		var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("fine",not web);mat.set_shader_parameter("blunt",wrench);materials[key]=mat
	var mesh=PlaneMesh.new();mesh.size=Vector2(.20,.16) if wrench else Vector2(.48,.065)
	var mark=MeshInstance3D.new();mark.mesh=mesh;mark.material_override=materials[key];mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not web:
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Lit edges outline a long blade gouge, or an angular tool dent.
		for i in range(12):
			var x=-.20+i*.034 if not wrench else cos(i*TAU/12.)*.062
			var next_x=x+.034 if not wrench else cos((i+1)*TAU/12.)*.062
			var z=.007+sin(i*1.7)*.002 if not wrench else sin(i*TAU/12.)*.042
			var next_z=.007+sin((i+1)*1.7)*.002 if not wrench else sin((i+1)*TAU/12.)*.042
			for side in [-1,1]:
				for v in [Vector3(x,.001,z*side),Vector3(next_x,.004,next_z*side),Vector3(x,.004,(z+.006)*side)]:st.add_vertex(v)
		st.generate_normals();var edge=MeshFactory.instance(mark,st.commit(),Vector3.ZERO,Color("8c887d"));edge.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;edge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mark
const CODE="""
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform bool fine=true;
uniform bool blunt=false;
void fragment(){
 vec2 p=UV*2.0-1.0;
 float taper=pow(max(0.0,1.0-abs(p.x)),0.5);
 float groove=abs(p.y+sin(p.x*8.0)*0.045);
 float edge=groove/max(0.02,taper);
 float alpha=1.0-smoothstep(0.18,0.55,edge);
 vec3 color=mix(vec3(0.055),vec3(0.68,0.65,0.57),smoothstep(-0.1,0.18,p.y));
 if(blunt){
  float r=length(p*vec2(0.85,1.0))+sin(atan(p.y,p.x)*6.0)*0.07;
  alpha=1.0-smoothstep(fine?0.60:0.40,fine?0.71:0.85,r);
  color=mix(vec3(0.16),vec3(0.58),smoothstep(-0.25,0.4,p.y))*mix(0.8,1.0,smoothstep(0.25,0.50,r));
 }else if(fine){
  float scratch=(1.0-smoothstep(0.018,0.065,abs(p.y-0.48-sin(p.x*16.0)*0.03)))*taper;
  alpha=max(alpha,scratch*0.55);
  color*=0.85+0.15*sin(p.x*190.0+p.y*43.0);
 }
 ALBEDO=color;ALPHA=alpha;
}
"""
