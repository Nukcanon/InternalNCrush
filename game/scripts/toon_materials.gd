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
	# Lighting changes update uniforms; never compile shaders during combat.
	if vertex:vertex.set_shader_parameter("dynamic_lighting",dynamic_lighting)
	for material in colors.values():material.set_shader_parameter("dynamic_lighting",dynamic_lighting)
static func make(color:Color=Color.WHITE,use_vertex:bool=true) -> ShaderMaterial:
	if shader==null:
		shader=Shader.new();shader.code="""shader_type spatial;
render_mode specular_disabled;
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
    float band = light < 0.05 ? 0.70 : (light < 0.58 ? 0.86 : 1.0);
    // Grazing-angle ink darkened entire distant floors, not just silhouettes.
    // Keep paint independent of camera angle and guarantee ambient readability.
    ALBEDO = dynamic_lighting ? paint * 0.72 : vec3(0.0);
    EMISSION = dynamic_lighting ? paint * 0.28 : paint * band;
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

