extends SceneTree
# Vertical extent (y) and width (x) of a baked gun base in z slices: where the
# stock wrist / grip really is. Args: base name, z from, z to.
func _initialize():call_deferred("run")
func run():
	var args=OS.get_cmdline_user_args()
	var base:Node3D=GunModel.base_scene(args[0]).instantiate();root.add_child(base)
	var z0=float(args[1]);var z1=float(args[2])
	for k in range(9):
		var za=lerpf(z0,z1,k/8.);var zb=za+(z1-z0)/8.
		var lo=INF;var hi=-INF;var xl=INF;var xh=-INF
		for m in base.find_children("*","MeshInstance3D",true,false):
			var xf=base.global_transform.affine_inverse()*m.global_transform
			for s in range(m.mesh.get_surface_count()):
				for v in m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					var p=xf*v
					if p.z>=minf(za,zb) and p.z<maxf(za,zb):lo=minf(lo,p.y);hi=maxf(hi,p.y);xl=minf(xl,p.x);xh=maxf(xh,p.x)
		print("SECTION z=%.3f..%.3f y=%.3f..%.3f x=%.3f..%.3f"%[za,zb,lo,hi,xl,xh])
	quit()
