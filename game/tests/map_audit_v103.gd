extends SceneTree
func _initialize():call_deferred("run")
func length_of(path:Array) -> float:
	var distance=0.
	for i in range(1,path.size()):distance+=path[i-1].distance_to(path[i])
	return snappedf(distance,.1)
func run():
	var report=[]
	for index in range(31):
		var a=Arena.new();root.add_child(a);a.build(index);var nav=BotNavigation.new();nav.build(a);await physics_frame;await physics_frame
		var distances=[]
		for x in range(-4,5):
			for z in range(-4,5):
				var pos=Vector3(x*a.bounds.x*.17,0,z*a.bounds.y*.17)
				if not a.point_clear(pos):continue
				pos.y=1.5
				for angle in range(8):
					var direction=Vector3(cos(angle*TAU/8.),0,sin(angle*TAU/8.));var hit=a.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos+direction*250.,1));distances.append(pos.distance_to(hit.position) if not hit.is_empty() else 250.)
		distances.sort();var routes=[]
		for team in [0,1]:
			var values=[]
			for site in a.sites:values.append(length_of(nav.route(a.spawn_points[team][0],site)))
			routes.append(values)
		report.append({"map":index,"name":Rules.MAPS[index],"capacity":Rules.MAP_PLAYERS[index],"rectangle":index in MapIdentity.RECTANGLES,"rays":distances.size(),"median_m":snappedf(distances[distances.size()/2],.1) if not distances.is_empty() else -1.,"over_50m":distances.filter(func(d):return d>50.).size(),"spawn_to_sites_m":routes,"removed_coplanar_faces":a.architecture.get_meta("coplanar_faces_removed",0)})
		a.free();await process_frame
	FileAccess.open("res://../validation/v103-map-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MAP_AUDIT_COMPLETE ",report.size());quit()
