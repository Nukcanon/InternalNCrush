extends SceneTree
func _initialize():call_deferred("run")
func run():
	for index in [0,5]:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		var plan=DistrictLayout.read_plan(index)
		assert(not plan.water.is_empty(),"Water map needs an actual basin")
		var poly:PackedVector2Array=arena.get_meta("district_water")
		var triangles=Geometry2D.triangulate_polygon(poly)
		assert(triangles.size()>=3)
		var centre=(poly[triangles[0]]+poly[triangles[1]]+poly[triangles[2]])/3.
		var level=float(plan.water_height);var point=Vector3(centre.x,level-1.,centre.y)
		assert(arena.wading(point))
		assert(arena.fatal_water(point)==(index==0),"Sea kills; river must remain safe")
		assert(not arena.fatal_water(Vector3(centre.x,level+.1,centre.y)),"Above-water actors are safe")
		await physics_frame;await physics_frame
		var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(centre.x,level+.05,centre.y),Vector3(centre.x,level-6.,centre.y),1))
		assert(not hit.is_empty(),"Water needs a bed")
		if index==5:assert(absf(hit.position.y-(level-.55))<.05,"River is only 55 cm deep")
		arena.free();await process_frame
	print("WATER_V128_PASS");quit()
