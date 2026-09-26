class_name MedicSelection
extends RefCounted
static var outline:ShaderMaterial
static var frame=-1
static var target=0
static func apply(actor:Node):
	var g=actor.game
	if frame!=Engine.get_process_frames():
		frame=Engine.get_process_frames();target=0
		var viewer=g.players.get(g.local_id,{})
		if not viewer.is_empty() and viewer.alive and viewer.get("invul_select",0)>g.clock:target=g.invulnerability_target(g.local_id)
	var selected=actor.pid==target
	if not selected and not actor.character.get_meta("medic_selected",false):return
	if outline==null:
		outline=ShaderMaterial.new();var shader=Shader.new()
		shader.code="shader_type spatial; render_mode unshaded, cull_front, depth_draw_never; void vertex(){VERTEX+=NORMAL*0.028;} void fragment(){ALBEDO=vec3(1.0);}"
		outline.shader=shader
	for mesh in actor.character.find_children("*","MeshInstance3D",true,false):
		if mesh.name=="ContinuousBody":mesh.material_overlay=outline if selected else null
	actor.character.set_meta("medic_selected",selected)
	if not selected:actor.character.set_meta("silhouette_state","")
