extends SceneTree
## Debug: node tree of the baked weapon bases (names, AABBs in base space).
func _initialize():call_deferred("run")
func run():
	for base in ["Revolver","Revolver_Small","Shotgun","ShortCannon","Pistol"]:
		var node:Node3D=GunModel.base_scene(base).instantiate();root.add_child(node)
		print("BASE ",base)
		for n in node.find_children("*","",true,false):
			var extra=""
			if n is MeshInstance3D and n.mesh:extra=str((GunModel.relative(n,node)*n.get_aabb()))+" surfaces="+str(n.mesh.get_surface_count())
			elif n is Node3D:extra=str(GunModel.relative(n,node).origin)
			print("  ",node.get_path_to(n)," ",n.get_class()," ",extra)
		node.queue_free()
	quit()
