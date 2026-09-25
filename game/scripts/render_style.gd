class_name RenderStyle
extends RefCounted
## The staging flag also selects Web assets when baking with a native editor.
static func web() -> bool:
	return OS.has_feature("web") or bool(ProjectSettings.get_setting("application/config/web_assets",false))
