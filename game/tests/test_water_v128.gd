extends SceneTree
# Water basins on the harbour (0, sea) and canal (5, river) maps.
# 1.4.6 (the user): every deep basin, sea or river, is 2 m and more and deadly
# (the 55 cm wading river is gone); the full rules live in test_v146_water.gd.
func _initialize():call_deferred("run")
func run():
	var failed=false
	for index in [0,5]:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		var plan=DistrictLayout.read_plan(index)
		if plan.water.is_empty():printerr("FAIL water map needs an actual basin");failed=true
		var poly:PackedVector2Array=arena.get_meta("district_water")
		var triangles=Geometry2D.triangulate_polygon(poly)
		var centre=(poly[triangles[0]]+poly[triangles[1]]+poly[triangles[2]])/3.
		var level=float(plan.water_height);var point=Vector3(centre.x,level-1.,centre.y)
		if not arena.wading(point):printerr("FAIL in the basin counts as in the water");failed=true
		if not arena.fatal_water(point):printerr("FAIL deep water kills (map %d)"%index);failed=true
		if arena.fatal_water(Vector3(centre.x,level+.1,centre.y)):printerr("FAIL above-water actors are safe");failed=true
		await physics_frame;await physics_frame
		var hit=arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(centre.x,level-.05,centre.y),Vector3(centre.x,level-6.,centre.y),1))
		if hit.is_empty():printerr("FAIL water needs a bed");failed=true
		elif level-hit.position.y<2.:printerr("FAIL deep water is 2 m and more (%.2f)"%(level-hit.position.y));failed=true
		arena.free();await process_frame
	if failed:quit(1);return
	print("WATER_V128_PASS");quit()
