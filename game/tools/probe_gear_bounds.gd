extends SceneTree
# Bounds of held gear meshes (payload space) next to their grip points.
func _initialize():call_deferred("run")
func run():
	for spec in [[0,1,"frag"],[4,0,"smoke"],[4,1,"flash"],[5,0,"medkit"],[0,0,"plate"],[1,0,"tablet"]]:
		var holder=Node3D.new();root.add_child(holder)
		var h=GearModels.held(holder,spec[0],spec[1])
		var box=AABB();var first=true
		for m in h.node.find_children("*","MeshInstance3D",true,false):
			var xf=h.node.global_transform.affine_inverse()*m.global_transform
			var b=xf*m.get_aabb();box=b if first else box.merge(b);first=false
		print("GEAR %s bounds pos=%s size=%s centre=%s right=%s left=%s"%[spec[2],box.position,box.size,box.get_center(),h.right,h.left])
		holder.free()
	quit()
