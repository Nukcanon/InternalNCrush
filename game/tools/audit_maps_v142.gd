extends SceneTree
## Map integrity audit (1.4.2), every map built through the game. From every
## spawn point the playable space is flood-filled on a 0.75 m grid the way a
## player moves (walk, climb steps / jumpable ledges up to 1.25 m, drop down),
## and only reachable ground is judged:
##  escape     reachable ground outside the playable area (the map is open)
##  falls      reachable spots with no floor below at all (a hole into the void)
##  invisible  reachable collision floor with no visible surface on it
##  fake       a visible floor a step above reachable ground with nothing solid
##             under it (looks walkable, the player sinks through)
##  ghosts     visible solid objects at chest height with no collision (walk-through)
##  overlaps   props, cover, dressing and doors sunk > 6 cm into walls or each other
##  spawns     spawn points / objectives whose standing capsule is inside geometry
## Args: map indices (default all 32). Output: MAP_AUDIT lines and a summary.
const WORLD=1
const PROPS=8
const VISUAL=1<<18
const STEP=.75
const CLIMB=1.25
const OUT="res://../validation/map-audit/"
var g:Node
var report={}
var capsule:CapsuleShape3D
var shots=false
func _initialize():call_deferred("run")
func ray(space,from:Vector3,to:Vector3,mask:int) -> Dictionary:
	var q=PhysicsRayQueryParameters3D.create(from,to,mask);q.hit_back_faces=true
	return space.intersect_ray(q)
func free_at(space,feet:Vector3) -> bool:
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.transform=Transform3D(Basis(),feet+Vector3.UP*.92);q.collision_mask=WORLD
	return space.intersect_shape(q,1).is_empty()
func in_area(a,p:Vector2,margin:float) -> bool:
	# Inside the playable polygon grown by `margin`.
	var poly:PackedVector2Array=a.playable_polygon
	if poly.size()<3:return absf(p.x)<a.bounds.x+margin and absf(p.y)<a.bounds.y+margin
	if Geometry2D.is_point_in_polygon(p,poly):return true
	for i in range(poly.size()):
		if Geometry2D.get_closest_point_to_segment(p,poly[i],poly[(i+1)%poly.size()]).distance_to(p)<margin:return true
	return false
func in_water(a,p:Vector2) -> bool:
	for basin in a.get_meta("district_waters",[a.get_meta("district_water")] if a.has_meta("district_water") else []):
		if Geometry2D.is_point_in_polygon(p,basin):return true
		for i in range(basin.size()):
			if Geometry2D.get_closest_point_to_segment(p,basin[i],basin[(i+1)%basin.size()]).distance_to(p)<1.:return true
	return false
func add_visual_colliders(a) -> Array:
	var bodies=[]
	for node in a.find_children("*","GeometryInstance3D",true,false):
		if not (node is MeshInstance3D or node is MultiMeshInstance3D) or not node.is_visible_in_tree():continue
		var skip=false;var n=node.get_parent()
		while n!=null and n!=a:
			if n is RigidBody3D or n is AnimatableBody3D or str(n.name).begins_with("AccessDoor"):skip=true;break
			n=n.get_parent()
		if skip:continue
		var mat=node.material_override
		if mat is StandardMaterial3D and (mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or mat.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED):continue
		if node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:continue
		var placements=[]
		if node is MeshInstance3D:
			if node.mesh:placements.append([node.mesh,node.global_transform])
		elif node.multimesh and node.multimesh.mesh:
			var mm:MultiMesh=node.multimesh
			for i in range(mm.visible_instance_count if mm.visible_instance_count>=0 else mm.instance_count):placements.append([mm.mesh,node.global_transform*mm.get_instance_transform(i)])
		for item in placements:
			var shape=item[0].create_trimesh_shape()
			if shape==null:continue
			var body=StaticBody3D.new();body.collision_layer=VISUAL;body.collision_mask=0;body.set_meta("source",node)
			var cs=CollisionShape3D.new();cs.shape=shape;body.add_child(cs);root.add_child(body);body.global_transform=item[1]
			bodies.append(body)
	return bodies
# Probes sit a little off the grid so rays never run exactly along mesh seams.
const JITTER=Vector3(.037,0,.023)
func visible_floor(space,f:Vector3) -> bool:
	for o in [JITTER,-JITTER,Vector3(JITTER.z,0,-JITTER.x)]:
		if not ray(space,f+o+Vector3.UP*.3,f+o-Vector3.UP*.3,VISUAL).is_empty():return true
	return false
# Inside a closed visible solid: rays in six directions all leave through back faces within 1.5 m.
func inside_visual(space,p:Vector3) -> bool:
	for d in [Vector3.UP,Vector3.DOWN,Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		var h=ray(space,p,p+d*1.5,VISUAL)
		if h.is_empty() or h.normal.dot(d)<=0.:return false
	return true
func depth_of(space,shape:Shape3D,xf:Transform3D,mask:int,exclude:Array) -> Array:
	var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=xf;q.collision_mask=mask;q.exclude=exclude
	var hits=space.intersect_shape(q,8)
	var out=[]
	for h in hits:
		var q2=PhysicsShapeQueryParameters3D.new();q2.shape=shape;q2.transform=xf;q2.collision_mask=mask
		var others=[];for h2 in hits:if h2.rid!=h.rid:others.append(h2.rid)
		q2.exclude=exclude+others
		var pairs=space.collide_shape(q2,16);var deepest=0.
		for i in range(0,pairs.size(),2):deepest=maxf(deepest,pairs[i].distance_to(pairs[i+1]))
		out.append([h.collider,deepest])
	return out
func label_of(node:Node,a:Node) -> String:
	var holder=node.get_parent();var kind=str(holder.get_meta("prop_asset","")) if holder else ""
	return (kind+":" if kind!="" else "")+str(a.get_path_to(node)).replace("_StaticBody3D_","SB").left(60)
func snap(v:Vector3) -> Vector3:return Vector3(snappedf(v.x,.1),snappedf(v.y,.1),snappedf(v.z,.1))
func audit(index:int):
	var a=g.arena;var space=a.get_world_3d().direct_space_state
	var rec={"escape":[],"falls":[],"invisible":[],"fake":[],"ghosts":[],"mismatch":[],"overlaps":[],"spawns":[],"invisible_kinds":{},"overlap_points":[],"joints":0}
	var visual=add_visual_colliders(a)
	for i in range(3):await physics_frame
	# Seeds: spawns (and objectives).
	var points=[]
	for team in a.spawn_points:points.append_array(team)
	points.append_array(a.ffa_spawns)
	for s in a.sites:points.append(s.get("pos",Vector3.ZERO) if s is Dictionary else s)
	for p in points:
		if p is Vector3 and not free_at(space,p+Vector3.UP*.05):rec.spawns.append(snap(p))
	# Flood fill: key = cell + floor height (0.5 m bands) so stacked floors stay apart.
	var seen={};var queue=[]
	for p in points:
		if not p is Vector3:continue
		var hit=ray(space,p+Vector3.UP*1.2,p-Vector3.UP*3.,WORLD)
		if hit.is_empty():continue
		var c=Vector2i(roundi(p.x/STEP),roundi(p.z/STEP));var f=hit.position
		var key=Vector3i(c.x,roundi(f.y*2.),c.y)
		if not seen.has(key):seen[key]=f;queue.append(f)
	var head=0;var limit=200000
	while head<queue.size() and head<limit:
		var f:Vector3=queue[head];head+=1
		for d in [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]:
			var nx=f.x+d.x*STEP;var nz=f.z+d.y*STEP
			# Passage: nothing solid at chest height between the cells (from the higher floor).
			var from=Vector3(f.x,f.y+1.45,f.z);var to=Vector3(nx,f.y+1.45,nz)
			if not ray(space,from,to,WORLD).is_empty():continue
			var down=ray(space,Vector3(nx,f.y+CLIMB+.05,nz),Vector3(nx,f.y-60.,nz),WORLD)
			if down.is_empty():
				# A void only if nothing at all is below (the probe may start inside a thick slab).
				if in_area(a,Vector2(nx,nz),1.) and ray(space,Vector3(nx,f.y+60.,nz),Vector3(nx,f.y-60.,nz),WORLD).is_empty():rec.falls.append(snap(Vector3(nx,f.y,nz)))
				continue
			var n:Vector3=down.position
			if n.y>f.y+.3:
				# Up a step or a jumpable ledge: the path over it must be clear too.
				if not ray(space,Vector3(f.x,n.y+1.45,f.z),Vector3(nx,n.y+1.45,nz),WORLD).is_empty():continue
			if down.normal.y<.6 or not free_at(space,n+Vector3.UP*.03):continue
			var key=Vector3i(roundi(nx/STEP),roundi(n.y*2.),roundi(nz/STEP))
			if seen.has(key):continue
			seen[key]=n;queue.append(n)
			# Water basins (sea / river) lie outside the playable border by design.
			if not in_area(a,Vector2(nx,nz),1.2) and not in_water(a,Vector2(nx,nz)):rec.escape.append(snap(n))
	# Visual checks on reachable ground only.
	for f in seen.values():
		var fj=f+JITTER
		if not visible_floor(space,f):
			# Only surfaces a player can really stand on (not the edge of a thin rail).
			var wide=0
			for o in [Vector3(.15,0,.15),Vector3(-.15,0,.15),Vector3(.15,0,-.15),Vector3(-.15,0,-.15)]:
				if not ray(space,f+o+Vector3.UP*.1,f+o-Vector3.UP*.15,WORLD).is_empty():wide+=1
			if wide<3:continue
			rec.invisible.append(snap(f))
			var owner_hit=ray(space,f+Vector3.UP*.05+JITTER,f-Vector3.UP*.2+JITTER,WORLD)
			var kind="architecture"
			if not owner_hit.is_empty():
				var holder=owner_hit.collider.get_parent()
				kind=str(holder.get_meta("prop_asset",holder.get_meta("kind","body:"+str(holder.name).rstrip("0123456789_@"))))
			rec.invisible_kinds[kind]=int(rec.invisible_kinds.get(kind,0))+1
			if rec.invisible.size()<=6:
				var col=ray(space,f+Vector3.UP*.05+JITTER,f-Vector3.UP*.2+JITTER,WORLD)
				var vis=ray(space,f+Vector3.UP*2.+JITTER,f-Vector3.UP*2.+JITTER,VISUAL)
				print("   INVISIBLE detail at ",snap(f)," collider=",label_of(col.collider,a) if not col.is_empty() else "-"," visual_y=",snappedf(vis.position.y,.01) if not vis.is_empty() else "none"," visual=",str(vis.collider.get_meta("source").get_path()).right(60) if not vis.is_empty() and vis.collider.has_meta("source") else "-")
		var over=ray(space,fj+Vector3.UP*1.25,fj+Vector3.UP*.4,VISUAL)
		if not over.is_empty() and over.normal.y>.85:
			# A floor-sized surface (not a trim or sill): the same height 0.25 m around.
			var wide=true
			for o in [Vector3(.25,0,0),Vector3(-.25,0,0),Vector3(0,0,.25),Vector3(0,0,-.25)]:
				var h2=ray(space,over.position+o+Vector3.UP*.1,over.position+o-Vector3.UP*.1,VISUAL)
				if h2.is_empty():wide=false;break
			if wide and ray(space,over.position+Vector3.UP*.05,over.position-Vector3.UP*.35,WORLD).is_empty():
				rec.fake.append(snap(over.position))
				if rec.fake.size()<=3:
					var src=over.collider.get_meta("source") if over.collider.has_meta("source") else null
					var mat=src.material_override if src else null
					print("   FAKE detail at ",snap(over.position)," standing=",snap(f)," source=",str(src.get_path()).right(70) if src else "-"," class=",src.get_class() if src else "-"," mat=",mat.get_class() if mat else "-"," shader=",(mat.shader.code.left(60).replace("\n"," ") if mat is ShaderMaterial else "-"))
		for h in [.9,1.4]:
			if inside_visual(space,fj+Vector3.UP*h):rec.ghosts.append(snap(f+Vector3.UP*h));break
	# Collision bigger than the model it belongs to (invisible walls / ledges):
	# nodes holding both meshes and static bodies (dressing, cover, fixtures).
	for holder in a.find_children("*","Node3D",true,false):
		var meshes=[];var shapes=[]
		for c in holder.get_children():
			if c is MeshInstance3D and c.mesh:meshes.append(c)
			elif c is StaticBody3D:
				for cs in c.get_children():
					if cs is CollisionShape3D and cs.shape and not cs.disabled:shapes.append(cs)
		if meshes.is_empty() or shapes.is_empty() or holder==a.architecture:continue
		var vis=AABB();var first=true
		for m in meshes:
			var box=m.global_transform*m.get_aabb();vis=box if first else vis.merge(box);first=false
		for cs in shapes:
			var col:AABB=cs.global_transform*cs.shape.get_debug_mesh().get_aabb()
			var over=maxf(maxf(col.end.y-vis.end.y,vis.position.x-col.position.x),maxf(col.end.x-vis.end.x,maxf(vis.position.z-col.position.z,col.end.z-vis.end.z)))
			if over>.12:
				rec.mismatch.append(str(holder.get_meta("prop_asset",""))+" %s collision past model by %.2fm (col top %.2f / model top %.2f) @%s meta=%s"%[label_of(holder,a),over,col.end.y,vis.end.y,str(snap(col.get_center())),str(holder.get_meta_list())])
				break
	# Overlaps: movable props, cover / dressing bodies outside the architecture, doors.
	var checked={}
	for body in a.find_children("*","CollisionObject3D",true,false):
		if body.get_parent()==a.architecture or body is CharacterBody3D:continue
		if body.collision_layer & (WORLD|PROPS)==0:continue
		for cs in body.get_children():
			if not cs is CollisionShape3D or cs.shape==null or cs.disabled:continue
			for pair in depth_of(space,cs.shape,cs.global_transform,WORLD|PROPS,[body.get_rid()]):
				var other=pair[0];var dd=float(pair[1])
				if dd<.06 or not is_instance_valid(other):continue
				var key=str([mini(body.get_instance_id(),other.get_instance_id()),maxi(body.get_instance_id(),other.get_instance_id())])
				if checked.has(key):continue
				checked[key]=true
				var pair_kinds=[str(body.get_parent().get_meta("prop_asset","")),str(other.get_parent().get_meta("prop_asset","") if other.get_parent() else "")];pair_kinds.sort()
				# Designed joints: a low wall running into its end pillar, L-shaped sandbag corners.
				if pair_kinds in [["low_wall","pillar"],["sacktrench","sacktrench_small"],["sacktrench","sacktrench"],["sacktrench_small","sacktrench_small"]]:rec.joints+=1;continue
				rec.overlaps.append("%s <> %s %.2fm @%s"%[label_of(body,a),label_of(other,a),dd,str(snap(cs.global_position))]);rec.overlap_points.append(snap(cs.global_position))
	for body in visual:body.queue_free()
	report[index]=rec
	if not rec.escape.is_empty():
		# Plot data: playable polygon, reachable ground, escape spots (tools: plot_map_audit.py).
		DirAccess.make_dir_recursive_absolute(OUT)
		var ground=[];for f in seen.values():ground.append([snappedf(f.x,.01),snappedf(f.y,.01),snappedf(f.z,.01)])
		var outs=[];for e in rec.escape:outs.append([e.x,e.y,e.z])
		var poly=[];for v in a.playable_polygon:poly.append([v.x,v.y])
		var f2=FileAccess.open(OUT+"escape_%02d.json"%index,FileAccess.WRITE);f2.store_string(JSON.stringify({"bounds":[a.bounds.x,a.bounds.y],"polygon":poly,"ground":ground,"escape":outs}));f2.close()
	if shots:
		# Views of flagged spots (first 3 per kind) for review.
		var cam=Camera3D.new();root.add_child(cam);cam.current=true;cam.fov=60.
		var marker=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=.06;ball.height=.12;marker.mesh=ball
		var red=StandardMaterial3D.new();red.albedo_color=Color.RED;red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;red.no_depth_test=true;marker.material_override=red;root.add_child(marker)
		for kind in ["escape","falls","invisible","fake","ghosts","spawns","overlap_points"]:
			for i in range(mini(3,rec[kind].size())):
				var p:Vector3=rec[kind][i*maxi(1,rec[kind].size()/3)] if kind=="escape" else rec[kind][i];marker.global_position=p
				if kind=="escape":
					# Overview from high above: the playable edge and where the ground leads out.
					# Standing in the pocket, looking back toward the middle of the map.
					cam.global_position=p+Vector3.UP*1.6;cam.look_at(Vector3(0,p.y+1.2,0),Vector3.UP)
				elif kind=="overlap_points":
					cam.global_position=p+Vector3(.01,6.,3.);cam.look_at(p,Vector3.UP)
				else:
					cam.global_position=p+Vector3(1.6,1.8,1.6);cam.look_at(p,Vector3.UP)
				for k in range(4):await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"%02d-%s-%d.png"%[index,kind,i])
		cam.queue_free();marker.queue_free()
	print("MAP_AUDIT %02d reach=%d escape=%d falls=%d invisible=%d fake=%d ghosts=%d mismatch=%d overlaps=%d spawns=%d"%[index,seen.size(),rec.escape.size(),rec.falls.size(),rec.invisible.size(),rec.fake.size(),rec.ghosts.size(),rec.mismatch.size(),rec.overlaps.size(),rec.spawns.size()])
	for key in ["escape","falls","invisible","fake","ghosts","spawns"]:
		if not rec[key].is_empty():print("   ",key," e.g. ",rec[key].slice(0,8))
	for o in rec.overlaps.slice(0,12):print("   overlap ",o)
	for o in rec.mismatch.slice(0,12):print("   mismatch ",o)
	if not rec.invisible_kinds.is_empty():print("   invisible by owner ",rec.invisible_kinds)
func run():
	capsule=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	shots="shots" in OS.get_cmdline_user_args()
	if shots:DirAccess.make_dir_recursive_absolute(OUT);root.size=Vector2i(960,600)
	var indices=[]
	for arg in OS.get_cmdline_user_args():
		if arg.is_valid_int():indices.append(int(arg))
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false
	# 31 maps plus the practice range (PracticeLayout.INDEX).
	if indices.is_empty():indices=range(32)
	for index in indices:
		g.options.map=index;g.build_world()
		for i in range(4):await physics_frame
		await audit(index)
	var all_kinds={}
	var total={"escape":0,"falls":0,"invisible":0,"fake":0,"ghosts":0,"mismatch":0,"overlaps":0,"spawns":0}
	for rec in report.values():
		for k in total:total[k]+=rec[k].size()
		for k in rec.invisible_kinds:all_kinds[k]=int(all_kinds.get(k,0))+rec.invisible_kinds[k]
	print("MAP_AUDIT_TOTAL maps=",report.size()," ",total)
	print("MAP_AUDIT_INVISIBLE_OWNERS ",all_kinds)
	quit()
