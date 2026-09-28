class_name ToonMaterials
extends RefCounted
## One pass, no texture fetches or full-screen edge postprocess.
## Three ink/paint bands keep silhouettes legible on WebGL and native alike.
static var shader:Shader
static var vertex:ShaderMaterial
static var human:ShaderMaterial
static var colors={}
static var dynamic_lighting=false
static func configure(on:bool):
	if dynamic_lighting==on:return
	dynamic_lighting=on
	if shader!=null:update_shader()
static func update_shader():
	# Lighting changes update uniforms; never compile shaders during combat.
	if vertex:vertex.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	if human:human.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	for material in colors.values():material.set_shader_parameter("dynamic_lighting",dynamic_lighting)
static func make(color:Color=Color.WHITE,use_vertex:bool=true) -> ShaderMaterial:
	if shader==null:
		shader=Shader.new();shader.code="""shader_type spatial;
#include "res://shaders/material_normal.gdshaderinc"
// toon_surface
uniform vec4 tint : source_color = vec4(1.0);
uniform float vertex_color = 1.0;
uniform bool dynamic_lighting = false;
uniform bool organic=false;
uniform sampler2D skin_normal:hint_normal,filter_linear_mipmap,repeat_enable;
varying vec3 paint;
varying vec3 local_position;varying vec3 local_normal;
varying vec3 world_normal;
void vertex() {
    local_position=VERTEX;local_normal=NORMAL;
    paint = mix(tint.rgb, COLOR.rgb, vertex_color);
    if(OUTPUT_IS_SRGB && vertex_color > 0.5)paint=pow(max(paint,vec3(0.)),vec3(.454545));
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    vec3 a=abs(local_normal);vec2 coords=(a.y>.65?local_position.xz:(a.x>a.z?local_position.zy:local_position.xy))*8.;
    bool skin=organic && (UV2.y<.5 || UV2.y>3.5);
    if(material_detail_enabled)NORMAL=detail_surface_normal(NORMAL,VERTEX,coords,skin?texture(skin_normal,coords).rgb:texture(detail_normal,coords).rgb,skin?.18:.55);
    ROUGHNESS=.8;
    float light = dot(normalize(world_normal), normalize(vec3(0.35, 0.85, 0.4)));
    float band = light < 0.05 ? 0.70 : (light < 0.58 ? 0.86 : 1.0);
    // Grazing-angle ink darkened entire distant floors, not just silhouettes.
    // Keep paint independent of camera angle and guarantee ambient readability.
    ALBEDO = dynamic_lighting ? paint * 0.72 : vec3(0.0);
    EMISSION = dynamic_lighting ? paint * 0.28 : paint * band;
}
void light() {
    float d = max(dot(NORMAL, LIGHT), 0.0);
    float band = d < 0.15 ? 0.15 : (d < 0.60 ? 0.60 : 1.0);
    band=mix(band,d,.45);
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * band / 3.14159265;
}
"""
		update_shader()
	var result=ShaderMaterial.new();result.shader=shader;result.set_shader_parameter("detail_normal",load("res://assets/textures/district/cloth_normal.png"))
	result.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	result.set_shader_parameter("skin_normal",load("res://assets/textures/district/skin_normal.png"))
	result.set_shader_parameter("tint",color);result.set_shader_parameter("vertex_color",1. if use_vertex else 0.)
	return result
static func vertex_material() -> ShaderMaterial:
	if vertex==null:vertex=make()
	return vertex
static func human_material() -> ShaderMaterial:
	if human==null:
		human=make();human.set_shader_parameter("organic",true);human.set_meta("authored_world",true)
	return human
static func hand_material(color:Color,kind:int) -> ShaderMaterial:
	var key=str([color,kind])
	if not colors.has(key):
		MeshFactory.bound_cache(colors,256)
		var material=make(color,false);material.set_meta("authored_world",true)
		material.set_shader_parameter("detail_normal",load("res://assets/textures/district/skin_normal.png" if kind==0 else "res://assets/textures/district/cloth_normal.png"))
		colors[key]=material
	return colors[key]
static func color_material(color:Color) -> ShaderMaterial:
	if not colors.has(color):MeshFactory.bound_cache(colors,256);colors[color]=make(color,false)
	return colors[color]

