class_name WaterSurface
extends RefCounted
static var cache={}
static func material(sea:bool) -> ShaderMaterial:
	if cache.has(sea):return cache[sea]
	var shader=Shader.new();shader.code="""shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec3 water_colour:source_color=vec3(.06,.32,.39);
uniform float wave_size=1.;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 float a=sin(world.x*.65*wave_size+world.z*.31+TIME*.55);
 float b=sin(world.x*.17-world.z*.81*wave_size-TIME*.43);
 float detail=1.-smoothstep(30.,180.,length(VERTEX));a*=detail;b*=detail;
 float crest=smoothstep(.87,1.,a*.5+b*.5);
 vec3 colour=water_colour*(.88+.12*a)+vec3(.18,.25,.23)*crest;
 ALBEDO=colour*.7;EMISSION=colour*.3;ROUGHNESS=.68;
}
"""
	var result=ShaderMaterial.new();result.shader=shader
	result.set_shader_parameter("water_colour",Color("187d98") if sea else Color("409b8b"))
	result.set_shader_parameter("wave_size",.75 if sea else 1.5)
	cache[sea]=result;return result
