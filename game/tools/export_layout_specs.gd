extends SceneTree
func _initialize():
	var out={}
	for index in range(19,31):
		var spec=DefusalLayout.spec(index);var points=[];var perimeter=[]
		for p in spec.points:points.append([p.x,p.y])
		for p in MapIdentity.perimeter(index,spec.size):perimeter.append([p.x,p.y])
		var radii=[]
		for radius in spec.radii:radii.append([radius.x,radius.y])
		out[str(index)]={"points":points,"links":spec.links,"radii":radii,"lane_width":spec.lane_width,"perimeter":perimeter,"style":spec.style}
	DirAccess.make_dir_recursive_absolute("res://assets/arenas");FileAccess.open("res://assets/arenas/defusal_specs.json",FileAccess.WRITE).store_string(JSON.stringify(out,"  "));quit()
