extends SceneTree
# Bounds of props overlapping world bodies on one map (args: map index, prop kind).
func _initialize():call_deferred("run")
func world_aabb(body:CollisionObject3D) -> AABB:
	var out=AABB();var first=true
	for cs in body.get_children():
		if cs is CollisionShape3D and cs.shape:
			var b=cs.global_transform*cs.shape.get_debug_mesh().get_aabb();out=b if first else out.merge(b);first=false
	return out
func run():
	var args=OS.get_cmdline_user_args();var index=int(args[0]);var kind=args[1]
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
	g.build_world();for i in range(4):await physics_frame
	var a=g.arena;var space=a.get_world_3d().direct_space_state
	if kind=="direct":
		# Static bodies placed straight under the arena (practice range pieces).
		for body in a.get_children():
			if body is StaticBody3D and body.collision_layer&1:
				var box=world_aabb(body)
				if box.position.y>2.:
					var meshes=[];for m in body.find_children("*","MeshInstance3D",true,false):meshes.append(m.mesh.get_class() if m.mesh else "-")
					print("DIRECT ",body.name," aabb=",box," meshes=",meshes," script=",body.get_script())
		quit();return
	for node in a.architecture.get_children():
		if str(node.get_meta("prop_asset",""))!=kind:continue
		for body in node.get_children():
			if not body is StaticBody3D:continue
			print("PROP ",kind," at ",node.global_position.snapped(Vector3.ONE*.1)," yaw=",snappedf(node.rotation.y,.01)," col=",world_aabb(body))
			for cs in body.get_children():
				if not cs is CollisionShape3D:continue
				var q=PhysicsShapeQueryParameters3D.new();q.shape=cs.shape;q.transform=cs.global_transform;q.collision_mask=1;q.exclude=[body.get_rid()]
				for h in space.intersect_shape(q,8):
					var other=h.collider;var meshes=[]
					for m in other.find_children("*","MeshInstance3D",true,false):meshes.append(str(m.name))
					print("   hits ",other.name," parent=",other.get_parent().name," aabb=",world_aabb(other)," meshes=",meshes.slice(0,3)," meta=",other.get_parent().get_meta_list())
	quit()
