class_name WebMaterials
extends RefCounted
static var cache={}
static var flat_shader:Shader
static func simplify(material:Material) -> Material:
	if cache.has(material):return cache[material]
	if material is StandardMaterial3D:
		if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:return material
		var simple=material.duplicate();simple.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;simple.albedo_texture=null;simple.normal_enabled=false;simple.roughness_texture=null;simple.metallic_texture=null
		cache[material]=simple;return simple
	if not material is ShaderMaterial:return material
	var code=material.shader.code
	if not ("material_atlas" in code or "operator_atlas" in code or "finish_roughness" in code):return material
	if flat_shader==null:
		flat_shader=Shader.new()
		flat_shader.code="""shader_type spatial;
render_mode unshaded;
uniform vec4 tint:source_color=vec4(1.0);
uniform float vertex_color=1.0;
varying vec3 shaded_color;
void vertex(){float shade=.62+.38*max(dot(normalize(MODEL_NORMAL_MATRIX*NORMAL),normalize(vec3(.35,.85,.4))),0.0);shaded_color=mix(tint.rgb,COLOR.rgb,vertex_color)*shade;}
void fragment(){ALBEDO=shaded_color;}
"""
	var result=ShaderMaterial.new();result.shader=flat_shader
	if "uniform vec4 tint" in code:
		result.set_shader_parameter("tint",material.get_shader_parameter("tint"));result.set_shader_parameter("vertex_color",0.)
	cache[material]=result;return result
static func apply(root:Node):
	for node in root.find_children("*","MeshInstance3D",true,false):
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.material_override:node.material_override=simplify(node.material_override)
		elif node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var material=node.get_active_material(i)
				if material:node.set_surface_override_material(i,simplify(material))
