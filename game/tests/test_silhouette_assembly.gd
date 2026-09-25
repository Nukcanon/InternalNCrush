extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	var node=Node3D.new();root.add_child(node)
	var base=MeshFactory.box(node,Vector3(0,.4,0),Vector3(1,.8,1),Color.GRAY)
	var pivot=Node3D.new();node.add_child(pivot);pivot.position.y=1.
	var barrel=MeshFactory.box(pivot,Vector3(0,0,-.5),Vector3(.3,.3,1.5),Color.GRAY)
	for angle in [0.,.7,1.8,3.1]:
		pivot.rotation.y=angle
		DeploymentSilhouette.apply(node,{"owner":1,"team":0,"level":1},1)
		for mesh in [base,barrel]:
			var low:Vector3=mesh.material_overlay.get_shader_parameter("bounds_min")
			var high:Vector3=mesh.material_overlay.get_shader_parameter("bounds_max")
			var bounds=AABB(low,high-low)
			for other in [base,barrel]:
				for corner in range(8):
					var point=mesh.global_transform.affine_inverse()*other.global_transform*other.get_aabb().get_endpoint(corner)
					expect(bounds.has_point(point),"assembly covers every part during head rotation")
	DeploymentSilhouette.apply(node,{"owner":2,"team":0,"level":1},1)
	expect(base.material_overlay==null and barrel.material_overlay==null,"nonowner has no overlay")
	node.free();print("SILHOUETTE_ASSEMBLY_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
