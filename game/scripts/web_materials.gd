class_name WebMaterials
extends RefCounted
static var cache={}
static func simplify(material:Material) -> Material:
	if not material is ShaderMaterial:return material
	if cache.has(material):return cache[material]
	var code=material.shader.code
	if not ("material_atlas" in code or "operator_atlas" in code or "finish_roughness" in code):return material
	var shader=Shader.new()
	var human="skin_texture" in code
	var hand="uniform vec4 tint" in code
	shader.code="""shader_type spatial;
render_mode unshaded;
uniform sampler2D skin_texture:source_color,filter_linear_mipmap;
uniform vec4 tint:source_color=vec4(1.0);
varying float shade;
void vertex(){shade=.62+.38*max(dot(normalize(MODEL_NORMAL_MATRIX*NORMAL),normalize(vec3(.35,.85,.4))),0.0);}
void fragment(){ALBEDO=BASE_COLOR*shade;}
""".replace("BASE_COLOR","(UV2.y<1.0?texture(skin_texture,UV).rgb*.78:COLOR.rgb)" if human else "tint.rgb" if hand else "COLOR.rgb")
	var result=ShaderMaterial.new();result.shader=shader
	if human:result.set_shader_parameter("skin_texture",material.get_shader_parameter("skin_texture"))
	if hand:result.set_shader_parameter("tint",material.get_shader_parameter("tint"))
	cache[material]=result;return result
static func apply(root:Node):
	for node in root.find_children("*","MeshInstance3D",true,false):
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.material_override:node.material_override=simplify(node.material_override)
		elif node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var material=node.get_active_material(i)
				if material:node.set_surface_override_material(i,simplify(material))
