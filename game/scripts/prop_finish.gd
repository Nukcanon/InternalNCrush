class_name PropFinish
extends RefCounted
static var shader:Shader
static var cache={}
static func material(source:StandardMaterial3D,pack:String) -> ShaderMaterial:
	var key=str([source.albedo_color,source.albedo_texture,source.vertex_color_use_as_albedo,pack])
	if cache.has(key):return cache[key]
	if shader==null:
		shader=Shader.new();shader.code="""shader_type spatial;
#include "res://shaders/material_normal.gdshaderinc"
// authored_prop_finish: shared by native and Web, no extra geometry pass.
uniform vec4 tint:source_color=vec4(1.);
uniform sampler2D palette:source_color,filter_linear_mipmap;
uniform bool textured=false;
uniform bool vertex_paint=true;
varying vec3 p;varying vec3 n;
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 vec3 paint=tint.rgb*(vertex_paint?COLOR.rgb:vec3(1.));
 if(OUTPUT_IS_SRGB && vertex_paint)paint=pow(max(paint,vec3(0.)),vec3(.454545));
 if(textured)paint*=texture(palette,UV).rgb;
 vec3 a=abs(n);vec2 coords=(a.y>.65?p.xz:(a.x>a.z?p.zy:p.xy))*4.;
 ALBEDO=paint*.85;EMISSION=paint*.15;ROUGHNESS=.82;SPECULAR=.24;
 if(material_detail_enabled){
  NORMAL=detail_surface_normal(NORMAL,VERTEX,coords,texture(detail_normal,coords).rgb,.6);
  ROUGHNESS=.73;
 }
}
"""
	var mat=ShaderMaterial.new();mat.shader=shader;mat.set_meta("authored_world",true)
	mat.set_shader_parameter("tint",source.albedo_color);mat.set_shader_parameter("vertex_paint",source.vertex_color_use_as_albedo)
	mat.set_shader_parameter("textured",source.albedo_texture!=null)
	if source.albedo_texture:mat.set_shader_parameter("palette",source.albedo_texture)
	mat.set_shader_parameter("detail_normal",load("res://assets/textures/district/wood_normal.png" if pack in ["trees_original","windows_original","nature"] else "res://assets/textures/district/metal_normal.png"))
	cache[key]=mat;return mat
