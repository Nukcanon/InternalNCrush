class_name WebMaterials
extends RefCounted
static var cache={}
static func simplify(material:Material) -> Material:
	if cache.has(material):return cache[material]
	MeshFactory.bound_cache(cache,256)
	if material is StandardMaterial3D:
		if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:return material
		var simple=ToonMaterials.color_material(material.albedo_color)
		cache[material]=simple;return simple
	if not material is ShaderMaterial:return material
	var code=material.shader.code
	if "toon_surface" in code:
		return ToonMaterials.vertex_material() if float(material.get_shader_parameter("vertex_color"))>.5 else ToonMaterials.color_material(material.get_shader_parameter("tint"))
	if not ("material_atlas" in code or "operator_atlas" in code or "finish_roughness" in code):return material
	var result=ToonMaterials.color_material(material.get_shader_parameter("tint")) if "uniform vec4 tint" in code else ToonMaterials.vertex_material()
	cache[material]=result;return result
static func apply(root:Node):
	if not RenderStyle.web():return
	for node in root.find_children("*","MeshInstance3D",true,false):
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if GraphicsOptions.shadows>0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.material_override:node.material_override=simplify(node.material_override)
		elif node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var material=node.get_active_material(i)
				if material:node.set_surface_override_material(i,simplify(material))

