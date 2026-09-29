class_name ObjectiveMarkers
extends Node3D
# Only control ownership is exposed here; bomb state is deliberately not read.
var game:Node
var entries=[]
var elapsed=0.
func setup(g:Node):
	game=g
	_remove_decorative_labels(game.arena)
	if int(game.options.mode) not in [3,4]:return
	var points=game.arena.zones if int(game.options.mode)==3 else game.arena.sites
	for i in range(points.size()):
		var origin:Vector3=points[i]
		var label=game.arena.text3d((["A","C","B"][i] if int(game.options.mode)==3 else ["A","B"][i])+"\n▼",origin+Vector3.UP*4.5,Color("f5dfa1"),80,self)
		label.visibility_range_end=180.;label.pixel_size=.009;label.outline_size=12
		var mesh=ImmediateMesh.new();var ring=MeshInstance3D.new();ring.mesh=mesh;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(ring)
		var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;ring.material_override=material
		entries.append({"origin":origin,"label":label,"mesh":mesh,"material":material,"index":i})
		if int(game.options.mode)==3:
			label.hide()
			var overlay=MeshInstance3D.new();overlay.mesh=ImmediateMesh.new();overlay.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(overlay);overlay.hide()
			var tint=StandardMaterial3D.new();tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;tint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;tint.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED;tint.cull_mode=BaseMaterial3D.CULL_DISABLED;overlay.material_override=tint
			entries[-1]["overlay"]=overlay;entries[-1]["tint"]=tint
			var badge=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(1.5,2.25);badge.mesh=quad
			badge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;badge.visibility_range_end=180.;add_child(badge)
			var shader=ShaderMaterial.new();shader.shader=preload("res://scripts/control_marker.gdshader")
			shader.set_shader_parameter("glyph",load("res://assets/ui/control_"+ControlCapture.LABELS[i].to_lower()+".png"));badge.material_override=shader
			entries[-1]["badge"]=badge;entries[-1]["shader"]=shader
	call_deferred("place_markers")
func _remove_decorative_labels(node:Node):
	for child in node.get_children():
		if child is Label3D:
			if child.text not in ["AMMO","HEALTH"] and not child.text.ends_with(" m"):child.visible=false
		else:_remove_decorative_labels(child)
func place_markers():
	# Newly added collision bodies must reach the physics server before ray tests.
	# The arena can be replaced before this deferred call runs.
	if not is_inside_tree():return
	await get_tree().physics_frame
	if not is_inside_tree():return
	await get_tree().process_frame
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(game.arena):return
	var space=get_world_3d().direct_space_state
	for entry in entries:
		var origin:Vector3=entry.origin
		# Keep the full billboard below the first ceiling, including low indoor rooms.
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(origin+Vector3.UP*.25,origin+Vector3.UP*7.,1))
		var height=minf(4.5,float(hit.position.y-origin.y)-.85) if not hit.is_empty() else 4.5
		entry.label.position=origin+Vector3.UP*maxf(.7,height)
		entry.label.pixel_size=.006 if height<2.5 else .009
		if entry.has("badge"):
			entry.badge.position=entry.label.position
			entry.badge.mesh.size=Vector2(1.,1.5) if height<2.5 else Vector2(1.5,2.25)
		var radius=7. if int(game.options.mode)==3 else 5.
		var mesh:ImmediateMesh=entry.mesh;mesh.clear_surfaces()
		var ring_vertices=PackedVector3Array()
		for j in range(96):
			var vertices=[]
			for pair in [[j,radius-.10],[j,radius+.10],[j+1,radius+.10],[j+1,radius-.10]]:
				var angle=float(pair[0])*TAU/96.;var p=origin+Vector3(cos(angle)*pair[1],0,sin(angle)*pair[1])
				vertices.append(floor_vertex(p,space))
			if not vertices.all(func(p):return p.is_finite()):continue
			var low=float(vertices[0].y);var high=low
			for p in vertices:low=minf(low,p.y);high=maxf(high,p.y)
			# Never stretch a quad across a wall, void, or different floor level.
			if high-low>.25:continue
			for k in [0,1,2,0,2,3]:ring_vertices.append(vertices[k])
		if not ring_vertices.is_empty():
			mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for vertex in ring_vertices:mesh.surface_add_vertex(vertex)
			mesh.surface_end()
		if entry.has("overlay"):build_floor_overlay(entry,space)
func floor_vertex(point:Vector3,space:PhysicsDirectSpaceState3D) -> Vector3:
	var levels=game.arena.navigation_heights(point);var best=INF;var floor_y=INF
	for level in levels:
		var distance=absf(float(level)-point.y)
		if distance<best and distance<1.85:best=distance;floor_y=float(level)
	if not is_finite(floor_y):return Vector3.INF
	var start=Vector3(point.x,floor_y+.15,point.z)
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3.UP*.3,1))
	if hit.is_empty() or hit.normal.y<.7:return Vector3.INF
	return hit.position+Vector3.UP*.035
func build_floor_overlay(entry:Dictionary,space:PhysicsDirectSpaceState3D):
	# Sample once when the map loads, keeping the overlay on actual walkable
	# floors. Missing floors / abrupt height changes leave gaps, not sky discs.
	var rows=[];var origin:Vector3=entry.origin
	for radial in range(8):
		var row=[]
		for angle in range(64):row.append(floor_vertex(origin+Vector3(cos(angle*TAU/64.),0,sin(angle*TAU/64.))*float(radial)*.98,space))
		rows.append(row)
	var vertices=PackedVector3Array()
	for radial in range(1,8):
		for angle in range(64):
			var next=(angle+1)%64
			for triangle in [[rows[radial-1][angle],rows[radial][angle],rows[radial][next]],[rows[radial-1][angle],rows[radial][next],rows[radial-1][next]]]:
				if not triangle.all(func(p):return p.is_finite()):continue
				if maxf(triangle[0].y,maxf(triangle[1].y,triangle[2].y))-minf(triangle[0].y,minf(triangle[1].y,triangle[2].y))>.55:continue
				for p in triangle:vertices.append(p)
	var mesh:ImmediateMesh=entry.overlay.mesh;mesh.clear_surfaces()
	if vertices.is_empty():return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in vertices:mesh.surface_add_vertex(p)
	mesh.surface_end()
func _process(dt:float):
	elapsed+=dt
	if elapsed<.15:return
	elapsed=0.
	for entry in entries:
		var owner=int(game.zone_owner[entry.index]) if int(game.options.mode)==3 else -1
		var color=Color("69bdff") if owner==0 else Color("ffad68") if owner==1 else Color("f5dfa1")
		entry.label.modulate=color;entry.material.albedo_color=color
		if entry.has("overlay"):
			entry.overlay.visible=owner>=0
			entry.tint.albedo_color=Color(color,.17)
		if entry.has("shader"):
			var state=ControlCapture.state(game,entry.index)
			entry.shader.set_shader_parameter("base_color",ControlCaptureHud.color_for(state.owner))
			entry.shader.set_shader_parameter("fill_color",ControlCaptureHud.color_for(state.team))
			entry.shader.set_shader_parameter("progress",float(state.progress))
