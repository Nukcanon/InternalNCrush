class_name ArenaCache
extends RefCounted
const REVISION=169 # 1.5.0: barred railings at deep water, lane walls out of spawns, triangular drowning signs, no furniture over openings, closed parapet ends; 168: 1.4.7: spawns moved out of each other's sight (no screen walls), coplanar facade/roof/prop faces separated; 167: 1.4.6: grates between shallow and deep water stay under the water; 166: fences, 165: gates, ditches along the outer walls; 164: 1.4.6: windows/doors clear of props and walls, flat shallow pools, fountain water, signs on every deep stretch; 162: water rules (deep 2.2 m deadly / shallow .22 m), boats, regional looks, prop catalog; before: 1.4.5: remodelled vehicles / drums / casks / cable drums / water tank (PropModels); before: spawn screens, pipes above window heads, broken panes rarer, laundry posts, pillars under covered-room masses
const FIELDS=["district_surfaces","water_rect","has_water","spawn_points","ffa_spawns","sites","zones","obstacles","map_index","indoors","bounds","playable_polygon","walk_surfaces","floor_holes","navigation_goals","navigation_blocks","vertical_map","chunk_count"]
static func restore(arena:Node,index:int) -> bool:
	var path="res://assets/arenas/complete/map_%02d.scn"%index
	if not ResourceLoader.exists(path):return false
	var packed=load(path) as PackedScene
	if not packed:return false
	var source=packed.instantiate()
	if int(source.get_meta("revision",0))!=REVISION:source.free();return false
	var state=source.get_meta("state")
	for key in FIELDS:arena.set(key,state[key])
	for key in state.metadata:arena.set_meta(key,state.metadata[key])
	for child in source.get_children():clear_owners(child);source.remove_child(child);arena.add_child(child)
	arena.architecture=arena.get_node("Architecture");arena.building=false
	for item in state.supplies:arena.supplies.append({"pos":item.pos,"ready":0.,"node":arena.get_node(item.path)})
	for item in state.props:
		var prop=InteractiveProp.new();prop.configure(item.id,item.kind,arena.props_authoritative);prop.transform=item.transform;arena.add_child(prop);arena.props[item.id]=prop
	for item in state.doors:arena.add_door(item.pos,item.yaw,float(item.get("opening",InteractiveDoor.WIDTH)))
	arena.set_meta("navigation_cache",source.get_meta("navigation_cache"))
	if arena.has_meta("district"):DistrictLayout.validate_spawns(arena)
	source.free();GraphicsOptions.apply_world(arena)
	if OS.has_feature("web"):
		var batch=WebPropBatch.new();arena.add_child(batch);batch.build(arena.props)
	return true
static func save(arena:Node,path:String) -> Error:
	var source=Node3D.new();source.name="CachedArena"
	var state={"metadata":{},"props":[],"doors":[],"supplies":[]}
	for key in FIELDS:state[key]=arena.get(key)
	for key in arena.get_meta_list():
		if not str(key).begins_with("facade_opening"):state.metadata[key]=arena.get_meta(key) # (bake-time only)
	for i in range(arena.supplies.size()):arena.supplies[i].node.name="Supply_%d"%i
	for item in arena.supplies:state.supplies.append({"pos":item.pos,"path":arena.get_path_to(item.node)})
	for prop in arena.props.values():state.props.append({"id":prop.prop_id,"kind":prop.kind,"transform":prop.transform})
	for door in arena.doors.values():state.doors.append({"pos":door.position,"yaw":door.rotation.y,"opening":door.opening_width})
	for child in arena.get_children():
		if child is InteractiveProp or child is InteractiveDoor or child.is_queued_for_deletion():continue
		source.add_child(child.duplicate())
	var navigation=BotNavigation.new();navigation.build(arena)
	var weights={}
	for x in range(navigation.grid.region.size.x):
		for y in range(navigation.grid.region.size.y):
			var cell=Vector2i(x,y);var weight=navigation.grid.get_point_weight_scale(cell)
			if weight!=1.:weights[cell]=weight
	var points=[]
	for id in navigation.layers.get_point_ids():points.append([id,navigation.layers.get_point_position(id),navigation.layers.get_point_connections(id),navigation.layers.is_point_disabled(id)])
	source.set_meta("navigation_cache",{"weights":weights,"solid":navigation.static_solid,"points":points,"cells":navigation.layer_cells,"ground":navigation.layer_ground})
	source.set_meta("state",state);source.set_meta("revision",REVISION)
	MeshFactory.own_recursive(source,source)
	var packed=PackedScene.new();var result=packed.pack(source)
	if result==OK:result=ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS)
	source.free();return result

static func clear_owners(node:Node):
	node.owner=null
	for child in node.get_children():clear_owners(child)
