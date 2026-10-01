extends SceneTree
# 1.4.5: objects that sink into the map or into each other. Every collision
# shape of a placed object (props, cover, crates, pillars, trees - anything
# but the map's own triangle-mesh architecture) is shrunk by MARGIN on every
# side and tested against the world; whatever it still intersects overlaps it
# (touching is fine). Args: map indices (default all). Writes
# validation/overlaps.json and prints OVERLAP lines.
const MARGIN=.04
func _initialize():call_deferred("run")
func shrunk(shape:Shape3D) -> Shape3D:
	if shape is BoxShape3D:
		var b=BoxShape3D.new();b.size=(shape.size-Vector3.ONE*MARGIN*2.).max(Vector3.ONE*.01);return b
	if shape is CylinderShape3D:
		var c=CylinderShape3D.new();c.radius=maxf(.01,shape.radius-MARGIN);c.height=maxf(.01,shape.height-MARGIN*2.);return c
	if shape is CapsuleShape3D:
		var k=CapsuleShape3D.new();k.radius=maxf(.01,shape.radius-MARGIN);k.height=maxf(k.radius*2.+.01,shape.height-MARGIN*2.);return k
	if shape is SphereShape3D:
		var s=SphereShape3D.new();s.radius=maxf(.01,shape.radius-MARGIN);return s
	if shape is ConvexPolygonShape3D:
		# its own box, shrunk (a conservative stand-in)
		var pts:PackedVector3Array=shape.points;var box=AABB(pts[0],Vector3.ZERO)
		for p in pts:box=box.expand(p)
		var b=BoxShape3D.new();b.size=(box.size-Vector3.ONE*MARGIN*2.).max(Vector3.ONE*.01);return b
	return null
func shape_offset(shape:Shape3D) -> Vector3:
	if shape is ConvexPolygonShape3D:
		var pts:PackedVector3Array=shape.points;var box=AABB(pts[0],Vector3.ZERO)
		for p in pts:box=box.expand(p)
		return box.get_center()
	return Vector3.ZERO
func label(n:Node) -> String:
	# the object's own meshes (resource names or paths) say what it is
	var holder:Node=n.get_parent() if n.get_parent() and not n.get_parent() is Arena and str(n.get_parent().name)!="Architecture" else n
	var names={}
	for m in holder.find_children("*","MeshInstance3D",true,false):
		if m.mesh:
			var nm=m.mesh.resource_name if m.mesh.resource_name!="" else m.mesh.resource_path.get_file() if m.mesh.resource_path!="" else m.mesh.get_class()
			names[nm]=true
		if names.size()>=3:break
	var meta=""
	for k in ["prop_kind","kind","name"]:
		if holder.has_meta(k):meta=str(holder.get_meta(k))
	return "%s%s{%s}"%[n.get_class(),"("+meta+")" if meta!="" else "",",".join(names.keys())]
func run():
	var args=OS.get_cmdline_user_args();var maps=[]
	for a in args:maps.append(int(a))
	if maps.is_empty():maps=range(31)
	var report=[];var total=0
	for index in maps:
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		for i in range(3):await physics_frame
		var space=arena.get_world_3d().direct_space_state;var found=[];var seen={}
		var bodies=arena.find_children("*","CollisionObject3D",true,false)
		for body in bodies:
			for cs in body.get_children():
				if not cs is CollisionShape3D or cs.disabled or cs.shape==null or cs.shape is ConcavePolygonShape3D or cs.shape is HeightMapShape3D or cs.shape is WorldBoundaryShape3D:continue
				var small=shrunk(cs.shape)
				if small==null:continue
				var q=PhysicsShapeQueryParameters3D.new();q.shape=small;q.collision_mask=1|4|8;q.exclude=[body.get_rid()]
				var xf:Transform3D=cs.global_transform.orthonormalized();xf.origin=cs.global_transform*shape_offset(cs.shape)
				q.transform=xf
				for hit in space.intersect_shape(q,8):
					var other:Object=hit.collider
					if other==null:continue
					var key=str(min(body.get_instance_id(),other.get_instance_id()))+"-"+str(max(body.get_instance_id(),other.get_instance_id()))
					if seen.has(key):continue
					seen[key]=true
					# designed joints (a low wall into its end column, sandbag corners)
					var ka=str(body.get_parent().get_meta("prop_asset","")) if body.get_parent() else ""
					var kb=str(other.get_parent().get_meta("prop_asset","")) if other is Node and other.get_parent() else ""
					if ka!="" and kb!="" and DistrictProps.joint(ka,kb):continue
					var other_is_map=false
					for ocs in other.get_children():
						if ocs is CollisionShape3D and ocs.shape is ConcavePolygonShape3D:other_is_map=true
					found.append({"at":[snappedf(xf.origin.x,.01),snappedf(xf.origin.y,.01),snappedf(xf.origin.z,.01)],"object":label(body),"into":"map" if other_is_map else label(other),"size":str(cs.shape.size if cs.shape is BoxShape3D else "")})
		total+=found.size()
		report.append({"map":index,"overlaps":found})
		var line="OVERLAP map %d: %d"%[index,found.size()]
		for f in found.slice(0,6):line+="  [%s %s -> %s]"%[str(f.at),f.object,f.into]
		print(line)
		arena.free();await process_frame
	DirAccess.make_dir_recursive_absolute("res://../validation")
	FileAccess.open("res://../validation/overlaps.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("OVERLAP_TOTAL ",total)
	quit()
