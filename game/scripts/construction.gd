class_name Construction
extends RefCounted
static func active(g:Node,d:Dictionary) -> bool:return float(d.get("building_until",0))>g.clock
static func advance(g:Node,d:Dictionary):
	if float(d.get("build_growth",0))<=0.:return
	var progress=clampf((g.clock-float(d.building_started))/maxf(.01,float(d.building_until)-float(d.building_started)),0.,1.)
	var previous=float(d.get("build_progress",0))
	d.hp=minf(float(d.max_hp),float(d.hp)+float(d.build_growth)*maxf(0.,progress-previous));d.build_progress=progress
	if progress>=1.:d.build_growth=0.
static func bounds(d:Dictionary) -> AABB:
	var size=Vector3(3.4,1.25,.65) if d.kind=="cover" else Vector3(.85,2.,1.3)*TurretLogic.SCALES[int(d.level)-1]
	return AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
static func crossed(g:Node,from:Vector3,to:Vector3) -> Dictionary:
	var found={}
	for did in g.devices:
		var d=g.devices[did]
		if not active(g,d):continue
		var inverse=Transform3D(Basis(Vector3.UP,d.yaw),d.pos).affine_inverse()
		var hit=bounds(d).intersects_segment(inverse*from,inverse*to)
		if hit!=null:found[did]=inverse.affine_inverse()*hit
	return found
static func projectile(g:Node,rocket:Dictionary,from:Vector3,to:Vector3,amount:float):
	var seen:Dictionary=rocket.get("construction_hits",{})
	for did in crossed(g,from,to):
		if seen.has(did):continue
		seen[did]=true;g.damage_device(did,amount,int(rocket.owner))
	rocket.construction_hits=seen
static func visual(g:Node,node:Node3D,d:Dictionary):
	var building=active(g,d)
	node.collision_layer=0 if building else 4
	if building:
		var progress=clampf((g.clock-float(d.building_started))/(float(d.building_until)-float(d.building_started)),0.,1.)
		if not node.has_meta("construction_material"):
			var material=StandardMaterial3D.new();material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			material.cull_mode=BaseMaterial3D.CULL_BACK;material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_ALWAYS
			node.set_meta("construction_material",material)
		var material:StandardMaterial3D=node.get_meta("construction_material");material.albedo_color=Color(.64,.86,.96,lerpf(.06,.82,progress))
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			if mesh.get_meta("construction_edge",false):continue
			if not mesh.has_meta("construction_original"):mesh.set_meta("construction_original",{"material":mesh.material_override,"shadow":mesh.cast_shadow})
			if not mesh.has_node("ConstructionEdges"):add_edges(mesh,int(d.team))
			mesh.material_override=material;mesh.material_overlay=null;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.set_meta("silhouette_state","")
	elif node.has_meta("construction_material"):
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			if mesh.get_meta("construction_edge",false):mesh.queue_free();continue
			if not mesh.has_meta("construction_original"):continue
			var original=mesh.get_meta("construction_original");mesh.material_override=original.material;mesh.cast_shadow=original.shadow;mesh.remove_meta("construction_original")
		node.remove_meta("construction_material");node.set_meta("silhouette_state","")

static func labels(g:Node,node:Node3D,d:Dictionary):
	var viewer=g.players.get(g.local_id,{})
	var name_label=node.get_node("Label");var health=node.get_node("HealthLabel");var timer=node.get_node("BuildTimer")
	var aimed=false
	if not viewer.is_empty() and viewer.alive and g.actors.has(g.local_id):
		var a=g.actors[g.local_id];var point=d.pos+Vector3.UP*(.7 if d.kind=="cover" else 1.)
		var delta=point-a.eye()
		aimed=delta.length()<80. and delta.length()>.01 and a.direction().dot(delta.normalized())>cos(deg_to_rad(9.)) and g.clear_line(a.eye(),point,[a.get_rid(),node.get_rid()])
	name_label.visible=aimed;health.visible=aimed
	name_label.text=str(g.players.get(d.owner,{}).get("nick","Player"));name_label.modulate=Color.WHITE
	health.text="%d / %d"%[ceili(d.hp),roundi(d.max_hp)];health.modulate=Color("ff3434").lerp(Color.WHITE,clampf(float(d.hp)/maxf(1.,float(d.max_hp)),0.,1.))
	timer.visible=active(g,d) and not viewer.is_empty() and int(viewer.role)==3 and int(viewer.team)==int(d.team)
	timer.text="%.1f"%maxf(0.,float(d.get("building_until",0))-g.clock);timer.modulate=Color.WHITE

static func add_edges(mesh:MeshInstance3D,team:int):
	var edges={}
	for surface in range(mesh.mesh.get_surface_count()):
		if mesh.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
		var arrays=mesh.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
		var count=indices.size() if indices!=null and not indices.is_empty() else vertices.size()
		for triangle in range(0,count-2,3):
			var points=[]
			for corner in range(3):points.append(vertices[indices[triangle+corner] if indices!=null and not indices.is_empty() else triangle+corner])
			var normal=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
			for corner in range(3):
				var a:Vector3=points[corner];var b:Vector3=points[(corner+1)%3]
				var ka=str(a.snapped(Vector3.ONE*.0001));var kb=str(b.snapped(Vector3.ONE*.0001));var key=ka+kb if ka<kb else kb+ka
				if not edges.has(key):edges[key]={"a":a,"b":b,"normal":normal,"edge":true}
				else:
					var entry=edges[key];entry.edge=entry.normal.dot(normal)<.85;entry.normal=(entry.normal+normal).normalized()
	var lines=ImmediateMesh.new();lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for entry in edges.values():
		if entry.edge:lines.surface_add_vertex(entry.a+entry.normal*.003);lines.surface_add_vertex(entry.b+entry.normal*.003)
	lines.surface_end()
	var wire=MeshInstance3D.new();wire.name="ConstructionEdges";wire.mesh=lines;wire.set_meta("construction_edge",true);mesh.add_child(wire)
	var ink=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color("48baff") if team==0 else Color("ff983e");wire.material_override=ink;wire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
