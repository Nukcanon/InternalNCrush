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
		var mesh=ImmediateMesh.new();var ring=MeshInstance3D.new();ring.mesh=mesh;add_child(ring)
		var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;ring.material_override=material
		entries.append({"origin":origin,"label":label,"mesh":mesh,"material":material,"index":i})
	call_deferred("place_markers")
func _remove_decorative_labels(node:Node):
	for child in node.get_children():
		if child is Label3D:
			if child.text not in ["AMMO","HEALTH"] and not child.text.ends_with(" m"):child.visible=false
		else:_remove_decorative_labels(child)
func place_markers():
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(game.arena):return
	var space=get_world_3d().direct_space_state
	for entry in entries:
		var origin:Vector3=entry.origin
		# Keep the full billboard below the first ceiling, including low indoor rooms.
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(origin+Vector3.UP*.25,origin+Vector3.UP*7.,1))
		var height=minf(4.5,float(hit.position.y-origin.y)-.85) if not hit.is_empty() else 4.5
		entry.label.position=origin+Vector3.UP*maxf(.7,height)
		entry.label.pixel_size=.006 if height<2.5 else .009
		var radius=7. if int(game.options.mode)==3 else 5.
		var mesh:ImmediateMesh=entry.mesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(96):
			var vertices=[]
			for pair in [[j,radius-.10],[j,radius+.10],[j+1,radius+.10],[j+1,radius-.10]]:
				var angle=float(pair[0])*TAU/96.;var p=origin+Vector3(cos(angle)*pair[1],0,sin(angle)*pair[1])
				var floor_hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.5,p-Vector3.UP*1.,1))
				p.y=float(floor_hit.position.y)+.045 if not floor_hit.is_empty() else origin.y+.045
				vertices.append(p)
			for k in [0,1,2,0,2,3]:mesh.surface_add_vertex(vertices[k])
		mesh.surface_end()
func _process(dt:float):
	elapsed+=dt
	if elapsed<.15:return
	elapsed=0.
	for entry in entries:
		var owner=int(game.zone_owner[entry.index]) if int(game.options.mode)==3 else -1
		var color=Color("69bdff") if owner==0 else Color("ffad68") if owner==1 else Color("f5dfa1")
		entry.label.modulate=color;entry.material.albedo_color=color
