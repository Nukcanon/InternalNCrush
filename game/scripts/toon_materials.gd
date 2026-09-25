class_name ToonMaterials
extends RefCounted
## One pass, no texture fetches or full-screen edge postprocess.
## Three ink/paint bands keep silhouettes legible on WebGL and native alike.
static var shader:Shader
static var vertex:ShaderMaterial
static var colors={}
static var dynamic_lighting=false
static func configure(on:bool):
	if dynamic_lighting==on:return
	dynamic_lighting=on
	if shader!=null:update_shader()
static func update_shader():
	var code=shader.code
	code=code.replace("render_mode unshaded;","render_mode specular_disabled;" ) if dynamic_lighting else code.replace("render_mode specular_disabled;","render_mode unshaded;")
	if shader.code!=code:shader.code=code
	if vertex:vertex.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	for material in colors.values():material.set_shader_parameter("dynamic_lighting",dynamic_lighting)
static func make(color:Color=Color.WHITE,use_vertex:bool=true) -> ShaderMaterial:
	if shader==null:
		shader=Shader.new();shader.code="""shader_type spatial;
render_mode unshaded;
// toon_surface
uniform vec4 tint : source_color = vec4(1.0);
uniform float vertex_color = 1.0;
uniform bool dynamic_lighting = false;
varying vec3 paint;
varying vec3 world_normal;
void vertex() {
    paint = mix(tint.rgb, COLOR.rgb, vertex_color);
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    float light = dot(normalize(world_normal), normalize(vec3(0.35, 0.85, 0.4)));
    float band = light < 0.05 ? 0.52 : (light < 0.58 ? 0.76 : 1.0);
    float rim = abs(dot(normalize(NORMAL), normalize(VIEW)));
    float ink = smoothstep(0.08, 0.20, rim);
    ALBEDO = mix(paint * 0.20, paint * (dynamic_lighting ? 1.0 : band), ink);
}
void light() {
    float d = max(dot(NORMAL, LIGHT), 0.0);
    float band = d < 0.15 ? 0.15 : (d < 0.60 ? 0.60 : 1.0);
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * band / 3.14159265;
}
"""
		update_shader()
	var result=ShaderMaterial.new();result.shader=shader
	result.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	result.set_shader_parameter("tint",color);result.set_shader_parameter("vertex_color",1. if use_vertex else 0.)
	return result
static func vertex_material() -> ShaderMaterial:
	if vertex==null:vertex=make()
	return vertex
static func color_material(color:Color) -> ShaderMaterial:
	if not colors.has(color):colors[color]=make(color,false)
	return colors[color]
