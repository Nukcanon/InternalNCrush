extends RefCounted
class_name BotNavigation
var grid=AStarGrid2D.new()
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
			if absf(world_point.x)>arena.bounds.x-2 or absf(world_point.z)>arena.bounds.y-2 or (not arena.playable_polygon.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(world_point.x,world_point.z),arena.playable_polygon)):grid.set_point_solid(id);static_solid[id]=true
			if not grid.is_point_solid(id):grid.set_point_weight_scale(id,1.3 if arena.wading(point(id)) else 1.)
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
	var start=nearest(from);var end=nearest(to);var out=PackedVector3Array()
	if grid.is_point_solid(start) or grid.is_point_solid(end):return out
	for id in grid.get_id_path(start,end,true):out.append(point(id))
	return out
func danger(pos:Vector3,amount=2.):
	var center=cell(pos)
	for x in range(-2,3):
		for y in range(-2,3):
			var id=center+Vector2i(x,y)
			if grid.is_in_boundsv(id):heat[id]=minf(8,heat.get(id,0.)+amount/(1.+Vector2(x,y).length()))
func refresh(devices:Dictionary,now:float,props:Dictionary={}):
	if now<next_refresh:return
	next_refresh=now+1.
	for id in dynamic_solid: grid.set_point_solid(id,static_solid.has(id))
	dynamic_solid.clear()
	for d in devices.values():
		var extent=Vector2(2.4,1.3) if d.kind=="cover" else Vector2(1.1,1.1)
		var c=absf(cos(d.yaw));var s=absf(sin(d.yaw));extent=Vector2(extent.x*c+extent.y*s,extent.x*s+extent.y*c)
		var lo=cell(d.pos-Vector3(extent.x,0,extent.y));var hi=cell(d.pos+Vector3(extent.x,0,extent.y))
		for x in range(lo.x,hi.x+1):
			for y in range(lo.y,hi.y+1):var id=Vector2i(x,y);grid.set_point_solid(id);dynamic_solid[id]=true
	for prop in props.values():
		var id=cell(prop.global_position)
		grid.set_point_solid(id);dynamic_solid[id]=true
	for id in heat.keys():
		heat[id]*=.92;grid.set_point_weight_scale(id,(1.3 if arena.wading(point(id)) else 1.)+heat[id])
		if heat[id]<.1:heat.erase(id)
