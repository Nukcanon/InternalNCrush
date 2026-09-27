extends Control
class_name MapPlanView
signal activated
var map_index=-1
var plan={}
var level=0
var zoom=1.
var pan=Vector2.ZERO
var interactive=false
var fingers={}
var pinch_distance=0.
var dragging=false
var floor_meshes=[]
static var cache={}
func _ready():
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
func select_map(index:int):
	map_index=index
	if not cache.has(index):
		var path="res://assets/arenas/districts/plan_%02d.json"%index
		var data=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		var meshes=[]
		for key in ["ground","upper","lower"]:
			var vertices=PackedVector3Array()
			for p in data.get("triangles",{}).get(key,[]):vertices.append(Vector3(p[0],p[1],0))
			var mesh=ArrayMesh.new()
			if not vertices.is_empty():
				var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			meshes.append(mesh)
		cache[index]={"data":data,"meshes":meshes}
	plan=cache[index].data;floor_meshes=cache[index].meshes;reset_view()
func reset_view():zoom=1.;pan=Vector2.ZERO;queue_redraw()
func scale_factor() -> float:
	if plan.is_empty():return 1.
	return minf((size.x-24)/plan.dimensions[0],(size.y-24)/plan.dimensions[1])*zoom
func project(point:Array) -> Vector2:return Vector2(point[0],point[1])*scale_factor()+size*.5+pan
func polygon(points:Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for point in points:result.append(project(point))
	if result.size()>2 and result[0].is_equal_approx(result[-1]):result.remove_at(result.size()-1)
	return result
func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c1822"))
	if plan.is_empty():return
	var border=polygon(plan.border[0]);draw_colored_polygon(border,Color("263442"))
	var color=Color("94a8b5") if level==0 else Color("75bca7") if level==1 else Color("718bbe")
	if floor_meshes[level].get_surface_count()>0:draw_mesh(floor_meshes[level],null,Transform2D(0.,Vector2.ONE*scale_factor(),0.,size*.5+pan),color)
	for i in range(plan.targets.size()):
		var p=project(plan.targets[i]);draw_circle(p,7. if size.x>200 else 2.,Color("e6c676"))
		if size.x>200:
			var text_pos=p+Vector2(10,5);text_pos.x=clampf(text_pos.x,4.,size.x-18.);text_pos.y=clampf(text_pos.y,18.,size.y-30.)
			draw_string(ThemeDB.fallback_font,text_pos,(["A","C","B"] if plan.targets.size()==3 else ["A","B"])[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffe4a5"))
	for i in range(plan.spawns.size()):draw_circle(project(plan.spawns[i]),5. if size.x>200 else 2.,Color("55bfff") if i==0 else Color("ff9a54"))
	if size.x>200:draw_string(ThemeDB.fallback_font,Vector2(12,size.y-12),"%d × %d m"%[plan.dimensions[0],plan.dimensions[1]],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e5edf1"))
func zoom_at(factor:float,pivot:Vector2):
	var old=zoom;zoom=clampf(zoom*factor,1.,8.);pan=pivot-size*.5-(pivot-size*.5-pan)*(zoom/old);queue_redraw()
func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed
			if event.pressed and not interactive:activated.emit()
		elif interactive and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:zoom_at(1.18 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1./1.18,event.position)
	elif interactive and event is InputEventMouseMotion and dragging:pan+=event.relative;queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index]=event.position
			if not interactive:activated.emit()
		else:fingers.erase(event.index)
		pinch_distance=fingers.values()[0].distance_to(fingers.values()[1]) if fingers.size()==2 else 0.
	elif interactive and event is InputEventScreenDrag:
		fingers[event.index]=event.position
		if fingers.size()==2:
			var points=fingers.values();var distance=points[0].distance_to(points[1])
			if pinch_distance>1:zoom_at(distance/pinch_distance,(points[0]+points[1])*.5)
			pinch_distance=distance
		elif fingers.size()==1:pan+=event.relative;queue_redraw()
	accept_event()
