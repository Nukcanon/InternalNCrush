extends SceneTree
## Debug: side profile of each baked base (base-local units): for every z step
## the bottom/top of the model on the centre line and its half width there,
## plus the magazine box. Used to place support hands on real parts.
func _initialize():call_deferred("run")
func run():
	var space=get_root().world_3d.direct_space_state
	for base in ["Sniper_2","Shotgun","ShortCannon"]:
		var node:Node3D=GunModel.base_scene(base).instantiate();root.add_child(node)
		var body=StaticBody3D.new();root.add_child(body)
		for m in node.find_children("*","MeshInstance3D",true,false):
			if m.mesh==null:continue
			var shape=CollisionShape3D.new();shape.shape=m.mesh.create_trimesh_shape();shape.transform=GunModel.relative(m,node);body.add_child(shape)
		await physics_frame;await physics_frame
		var ray=func(from:Vector3,to:Vector3):
			var q=PhysicsRayQueryParameters3D.create(from,to);q.hit_back_faces=false
			return space.intersect_ray(q)
		var rows=[]
		for i in range(0,62):
			var z=-i*.02
			var up=ray.call(Vector3(0,-1,z),Vector3(0,1,z));var down=ray.call(Vector3(0,1,z),Vector3(0,-1,z))
			if up.is_empty() or down.is_empty():continue
			var lo=up.position.y;var hi=down.position.y;var mid=(lo+hi)*.5
			var side=ray.call(Vector3(-1,mid,z),Vector3(0,mid,z))
			rows.append("z=%.2f y[%.3f,%.3f] hx=%.3f" % [z,lo,hi,absf(side.position.x) if not side.is_empty() else 0.])
		var mag=node.get_node_or_null("Magazine");var mag_text="-"
		if mag:
			var box=AABB();var first=true
			for m in mag.find_children("*","MeshInstance3D",true,false)+([mag] if mag is MeshInstance3D else []):
				if m.mesh==null:continue
				var b=GunModel.relative(m,node)*m.get_aabb();box=b if first else box.merge(b);first=false
			mag_text=str(box)
		print("BASE ",base," magazine=",mag_text," muzzle=",node.get_node("Muzzle").position)
		for r in rows:print("  ",r)
		node.queue_free();body.queue_free();await process_frame
	quit()
