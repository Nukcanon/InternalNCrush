extends RefCounted
class_name SurfaceFinish
# Shared comic paint; no photographic skin or procedural grain shaders.
static func human_material(_role:int=0) -> ShaderMaterial:return ToonMaterials.vertex_material()
static func hand_material(color:Color,_kind:int) -> ShaderMaterial:return ToonMaterials.color_material(color)
static func material_kind(color:Color) -> int:
	var hex=color.to_html(false)
	if hex in ["ae8b5d","dbc099","d0b186","c8a577","87745a","987851","b18b61"]:return 2
	if hex in ["536e7b","3a515b","47636c","354954","3faaa4","608e90","b06d57","839da2","4e646e","314c59"]:return 1
	if hex in ["a2acaa","738185","566268"]:return 3
	return 0
static func equipment_material() -> ShaderMaterial:return ToonMaterials.vertex_material()
static func world_material() -> ShaderMaterial:return ToonMaterials.vertex_material()
