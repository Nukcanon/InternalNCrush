extends RefCounted
class_name BotNavigation
var grid=AStarGrid2D.new()
var layers=AStar3D.new()
var layer_cells={}
var layer_ground={}
var layer_dynamic={}
var static_solid={}
var dynamic_solid={}
var heat={}
var next_refresh=0.
var arena:Node
func build(world:Node):
	arena=world;grid.region=Rect2i(0,0,100,90);grid.cell_size=Vector2(2,2);grid.offset=Vector2(-99,-89);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE;grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE;grid.update()
	for rect in arena.obstacles:
		var lo=cell(Vector3(rect.position.x,0,rect.position.y));var hi=cell(Vector3(rect.end.x,0,rect.end.y))
		for x in range(lo.x,hi.x+1):
			for y in range(lo.y,hi.y+1):
				var id=Vector2i(x,y);grid.set_point_solid(id);static_solid[id]=true
	for x in range(100):
		for y in range(90):
			var id=Vector2i(x,y)
			var world_point=point(id)
			if arena.vertical_map:
				# Layer geometry already includes capsule clearance. Do not expand it
				# again by rounding the obstacle rectangle out to whole grid cells.
				var blocked=not arena.navigation_clear(Vector3(world_point.x,0.,world_point.z))
				grid.set_point_solid(id,blocked)
				if blocked:static_solid[id]=true
				else:static_solid.erase(id)
			if absf(world_point.x)>arena.bounds.x-2 or absf(world_point.z)>arena.bounds.y-2 or (not arena.playable_polygon.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(world_point.x,world_point.z),arena.playable_polygon)):grid.set_point_solid(id);static_solid[id]=true
			if not grid.is_point_solid(id):grid.set_point_weight_scale(id,1.3 if arena.wading(point(id)) else 1.)
	if arena.vertical_map:build_layers()
func build_layers():
	layers.clear();layer_cells.clear();layer_ground.clear()
	for x in range(100):
		for z in range(90):
			var cell_id=Vector2i(x,z);var horizontal=Vector3(-99+x*2,0,-89+z*2)
			for height in arena.navigation_heights(horizontal):
				var pos=Vector3(horizontal.x,height,horizontal.z)
				if not arena.navigation_clear(pos):continue
				var id=layers.get_available_point_id();layers.add_point(id,pos)
				if not layer_cells.has(cell_id):layer_cells[cell_id]=[]
				layer_cells[cell_id].append(id)
				if absf(height)<.1:layer_ground[id]=cell_id;layers.set_point_disabled(id,grid.is_point_solid(cell_id))
	for cell_id in layer_cells:
		for offset in [Vector2i(1,0),Vector2i(0,1)]:
			var other=cell_id+offset
			if not layer_cells.has(other):continue
			for id in layer_cells[cell_id]:
				for next in layer_cells[other]:
					var from=layers.get_point_position(id);var to=layers.get_point_position(next)
					if connects_surface(from,to):layers.connect_points(id,next)
func connects_surface(from:Vector3,to:Vector3) -> bool:
	if absf(from.y-to.y)>1.1:return false
	# Authored stairs slope along Z. Their sides are vertical slab edges, not
	# traversable steps; approach a flight through its landing instead.
	if absf(from.x-to.x)>.1 and absf(from.y-to.y)>.08:return false
	var previous=from.y
	for step in range(1,5):
		var point=from.lerp(to,step/4.);var height=INF;var best=INF
		for y in arena.navigation_heights(point):
			if absf(y-point.y)<best:best=absf(y-point.y);height=y
		if not is_finite(height) or absf(height-previous)>.38 or not arena.navigation_clear(Vector3(point.x,height,point.z)):return false
		previous=height
	return true
func cell(pos:Vector3) -> Vector2i:return Vector2i(clampi(int(round((pos.x+99)/2)),0,99),clampi(int(round((pos.z+89)/2)),0,89))
func point(id:Vector2i) -> Vector3:
	var pos=Vector3(-99+id.x*2,0,-89+id.y*2)
	if is_instance_valid(arena):pos.y=arena.walk_height(pos)
	return pos
func nearest(pos:Vector3) -> Vector2i:
	var start=cell(pos)
	if not grid.is_point_solid(start):return start
	for radius in range(1,12):
		var best=start;var distance=1e8
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var id=start+Vector2i(x,y)
				if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
					var d=point(id).distance_squared_to(pos)
					if d<distance:best=id;distance=d
		if best!=start:return best
	return start
func route(from:Vector3,to:Vector3) -> PackedVector3Array:
	if arena.vertical_map:
		if arena.building:
			for id in layer_ground:layers.set_point_disabled(id,grid.is_point_solid(layer_ground[id]) or layer_dynamic.has(id))
		if layers.get_point_count()==0:return PackedVector3Array()
		var start_id=reachable_entry(from);var end_id=layers.get_closest_point(to)
		if start_id<0:return PackedVector3Array()
		return layers.get_point_path(start_id,end_id)
	var start=nearest(from);var end=nearest(to);var out=PackedVector3Array()
	if grid.is_point_solid(start) or grid.is_point_solid(end):return out
	for id in grid.get_id_path(start,end,true):out.append(point(id))
	return out
func reachable_entry(from:Vector3) -> int:
	# Nearest in 3D can be on the side of a stair above the actor. Only join
	# the graph through a continuous walking surface at the actor's height.
	var center=cell(from);var best=-1;var distance=INF
	for radius in range(1,5):
		for x in range(-radius,radius+1):
			for z in range(-radius,radius+1):
				for id in layer_cells.get(center+Vector2i(x,z),[]):
					if layers.is_point_disabled(id):continue
					var to=layers.get_point_position(id);var d=from.distance_squared_to(to)
					if d<distance and continuous_entry(from,to):best=id;distance=d
		if best>=0:return best
	return -1
func continuous_entry(from:Vector3,to:Vector3) -> bool:
	var previous=arena.walk_height(from)
	if absf(previous-from.y)>.4:return false
	var count=maxi(1,ceili(Vector2(to.x-from.x,to.z-from.z).length()/.25))
	for step in range(1,count+1):
		var p=from.lerp(to,float(step)/count);var height=INF;var delta=INF
		for y in arena.navigation_heights(p):
			if absf(y-previous)<delta:delta=absf(y-previous);height=y
		if delta>.16 or not arena.navigation_clear(Vector3(p.x,height,p.z)):return false
		previous=height
	return absf(previous-to.y)<.1
func danger(pos:Vector3,amount=2.):
	var center=cell(pos)
	for x in range(-2,3):
		for y in range(-2,3):
			var id=center+Vector2i(x,y)
			if grid.is_in_boundsv(id):heat[id]=minf(8,heat.get(id,0.)+amount/(1.+Vector2(x,y).length()))
func refresh(devices:Dictionary,now:float,props:Dictionary={}):
	if now<next_refresh:return
	next_refresh=now+1.
	for id in layer_dynamic:layers.set_point_disabled(id,layer_ground.has(id) and static_solid.has(layer_ground[id]))
	layer_dynamic.clear()
	for id in dynamic_solid:
		grid.set_point_solid(id,static_solid.has(id))
		for point_id in layer_cells.get(id,[]):
			if layer_ground.has(point_id):layers.set_point_disabled(point_id,static_solid.has(id))
	dynamic_solid.clear()
	for d in devices.values():
		var extent=Vector2(2.4,1.3) if d.kind=="cover" else Vector2(1.1,1.1)
		var c=absf(cos(d.yaw));var s=absf(sin(d.yaw));extent=Vector2(extent.x*c+extent.y*s,extent.x*s+extent.y*c)
		var lo=cell(d.pos-Vector3(extent.x,0,extent.y));var hi=cell(d.pos+Vector3(extent.x,0,extent.y))
		for x in range(lo.x,hi.x+1):
			for y in range(lo.y,hi.y+1):
				var id=Vector2i(x,y)
				if not arena.vertical_map or absf(d.pos.y)<.5:grid.set_point_solid(id);dynamic_solid[id]=true
				block_layer(id,d.pos.y,1.8)
	for prop in props.values():
		var id=cell(prop.global_position)
		if not arena.vertical_map or absf(prop.global_position.y)<1.2:grid.set_point_solid(id);dynamic_solid[id]=true
		block_layer(id,prop.global_position.y,1.4)
	for id in heat.keys():
		heat[id]*=.92;grid.set_point_weight_scale(id,(1.3 if arena.wading(point(id)) else 1.)+heat[id])
		if heat[id]<.1:heat.erase(id)

func block_layer(cell_id:Vector2i,height:float,tolerance:float):
	for id in layer_cells.get(cell_id,[]):
		if absf(layers.get_point_position(id).y-height)<tolerance:layers.set_point_disabled(id,true);layer_dynamic[id]=true
