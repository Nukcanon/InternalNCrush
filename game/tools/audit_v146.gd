extends SceneTree
# 1.4.6 (the user): nothing in a map may overlap - windows and facade doors
# must not run into props, pillars or other walls; access doors must not cut
# into props; boats must lie clear of the quay; and a shot at any prop must
# strike the prop itself (the hit point lies on its visible surface).
# Builds each map live (as the bake does) and prints AUDIT146 lines.
# Args: map indices (default: all).
var failures=0
func _initialize():call_deferred("run")
func query(space:PhysicsDirectSpaceState3D,shape:Shape3D,xf:Transform3D,exclude:Array) -> Array:
	var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=xf;q.collision_mask=1;q.exclude=exclude
	return space.intersect_shape(q,16)
func tri_dist(p:Vector3,a:Vector3,b:Vector3,c:Vector3) -> float:
	var n=(b-a).cross(c-a)
	if n.length_squared()<1e-12:return INF
	n=n.normalized();var d=(p-a).dot(n);var q=p-n*d
	# inside the triangle (same side of every edge)?
	if (b-a).cross(q-a).dot(n)>=0. and (c-b).cross(q-b).dot(n)>=0. and (a-c).cross(q-c).dot(n)>=0.:return absf(d)
	return minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,a,b)),minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,b,c)),p.distance_to(Geometry3D.get_closest_point_to_segment(p,c,a))))
func label(collider:Object) -> String:
	if collider==null:return "?"
	var n:Node=collider as Node
	var p=n.get_parent() if n else null
	if p and p.has_meta("prop_asset"):return "prop:"+str(p.get_meta("prop_asset"))
	if p and p.has_meta("boat"):return "boat"
	if n and n.has_meta("door_id"):return "door"
	if n and OS.has_environment("AUDIT_ALL"):
		var s=""
		for cs in n.get_children():
			if cs is CollisionShape3D:s+="%s%s@%s "%[cs.shape.get_class().substr(0,4),str(cs.shape.size.snapped(Vector3.ONE*.1)) if cs.shape is BoxShape3D else "",str(cs.global_position.snapped(Vector3.ONE*.1))]
		return "%s<%s> %s"%[str(n.get_parent().name) if p else "",s.substr(0,120),str(n.get_meta_list())]
	return str(n.name) if n else "?"
func run():
	var maps=Array(OS.get_cmdline_user_args()).map(func(x):return int(x))
	if maps.is_empty():maps=range(Rules.MAPS.size())
	Catalog.load_all()
	for index in maps:
		DistrictFacade.record=[]
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		for i in range(2):await physics_frame
		DistrictProps.settle_props(arena)
		for i in range(2):await physics_frame
		var space=arena.get_world_3d().direct_space_state
		# boats against the map (their own convex parts, before the exact swap)
		var boat_bad=[]
		for node in arena.architecture.get_children():
			if not node.has_meta("boat"):continue
			for body in node.get_children():
				if not body is StaticBody3D:continue
				for cs in body.get_children():
					if not cs is CollisionShape3D or cs.shape is ConcavePolygonShape3D:continue
					for h in query(space,cs.shape,cs.global_transform,[body.get_rid()]):
						var nm=label(h.collider)
						if nm!="door":boat_bad.append(nm)
		DistrictProps.exact_collision(arena)
		for i in range(2):await physics_frame
		# 1. windows and facade doors
		var bad=[]
		for w in DistrictFacade.record:
			var box=BoxShape3D.new();box.size=(Vector3(w.half)-Vector3(.03,.03,0.)).max(Vector3.ONE*.01)*2.
			var hits=query(space,box,Transform3D(Basis(w.basis).orthonormalized(),w.centre),[])
			for h in hits:
				var name=label(h.collider)
				if name.begins_with("prop:") or name=="boat" or name=="door" or OS.has_environment("AUDIT_ALL"):bad.append("%s %s at %s"%[w.kind,name,str(Vector3(w.centre).snapped(Vector3.ONE*.1))]);break
		# windows and doors against each other (fronts on the same or crossing walls)
		var boxes=[]
		for w in DistrictFacade.record:
			var xf=Transform3D(Basis(w.basis).orthonormalized(),w.centre);var h=Vector3(w.half)-Vector3(.1,.02,0.)
			boxes.append([xf,h,xf*AABB(-h,h*2.),w.kind])
		var pair_bad=0
		for i in range(boxes.size()):
			for j in range(i+1,boxes.size()):
				var a2=boxes[i];var b2=boxes[j]
				if not AABB(a2[2]).intersects(b2[2]):continue
				var inv=Transform3D(b2[0]).affine_inverse();var l=Vector3.INF;var hh=-Vector3.INF
				for x in [-1.,1.]:
					for y in [-1.,1.]:
						for z in [-1.,1.]:
							var p:Vector3=inv*(Transform3D(a2[0])*(Vector3(a2[1])*Vector3(x,y,z)));l=l.min(p);hh=hh.max(p)
				if AABB(l,hh-l).intersects(AABB(-Vector3(b2[1]),Vector3(b2[1])*2.)):
					pair_bad+=1
					if bad.size()<12:bad.append("%s meets %s at %s"%[a2[3],b2[3],str(Transform3D(a2[0]).origin.snapped(Vector3.ONE*.1))])
		print("AUDIT146 map %d facade=%d checked, %d skipped, %d blocked %s"%[index,DistrictFacade.record.size(),DistrictFacade.skipped,bad.size(),str(bad.slice(0,6))])
		failures+=bad.size()+maxi(0,pair_bad-mini(pair_bad,12))
		DistrictFacade.record=null
		# 2. access doors against props
		var door_bad=[]
		for door in arena.doors.values():
			for leaf in door.leaves:
				var own=[leaf.get_rid()]
				for cs in leaf.get_children():
					if not cs is CollisionShape3D:continue
					var shrunk=BoxShape3D.new();shrunk.size=(cs.shape.size-Vector3.ONE*.06).max(Vector3.ONE*.01)
					for h in query(space,shrunk,cs.global_transform,own):
						var name=label(h.collider)
						if name.begins_with("prop:") or name=="boat":door_bad.append("door %d %s"%[door.door_id,name])
		print("AUDIT146 map %d doors=%d blocked %s"%[index,arena.doors.size(),str(door_bad)])
		failures+=door_bad.size()
		# 3. boats clear of the map, 4. shots strike the visible prop
		var shots=0;var air=[]
		for node in arena.architecture.get_children():
			if not (node.has_meta("footprint") or node.has_meta("boat")):continue
			var body:StaticBody3D=null
			for c in node.get_children():
				if c is StaticBody3D:body=c
			if body==null:continue
			if str(node.get_meta("prop_asset","")).begins_with("tree_"):continue
			var centre=node.global_position+Vector3.UP*.7
			for k in range(8):
				var a=TAU*k/8.
				var from=centre+Vector3(cos(a),0,sin(a))*4.+Vector3.UP*(.3*(k%3)-.3)
				var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,centre,1))
				if hit.is_empty() or hit.collider!=body:continue
				shots+=1
				# the struck point must lie on a visible face of the prop
				var best=INF
				for m in node.get_children():
					if not m is MeshInstance3D or m.mesh==null:continue
					var faces:PackedVector3Array=m.mesh.get_faces();var xf:Transform3D=m.global_transform;var local=xf.affine_inverse()*Vector3(hit.position)
					for i in range(0,faces.size(),3):
						best=minf(best,tri_dist(local,faces[i],faces[i+1],faces[i+2]))
				if best>.03:air.append("%s %.2f"%[str(node.get_meta("prop_asset","boat")),best])
		print("AUDIT146 map %d boats_blocked=%s shots=%d off_surface=%d %s"%[index,str(boat_bad.slice(0,6)),shots,air.size(),str(air.slice(0,6))])
		failures+=boat_bad.size()+air.size()
		arena.queue_free()
		for i in range(3):await process_frame
	print("AUDIT146_FAILURES ",failures)
	quit(1 if failures>0 else 0)
