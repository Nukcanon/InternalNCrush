extends SceneTree
func _initialize():call_deferred("run")
func run():
	var a=Arena.new();root.add_child(a);a.build(10)
	await physics_frame;await physics_frame
	var p=Vector3(.768,2.8,-28.9)
	for dx in [-.1,0.,.1]:
		for dz in [-.1,0.,.1]:
			var q=p+Vector3(dx,0,dz)
			print(q," ",a.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(q+Vector3.UP*.5,q-Vector3.UP*.5,1)).get("position","none"))
	a.free();quit()
