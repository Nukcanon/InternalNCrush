extends SceneTree
# Arena node structure of one map (args: map index): top-level children, body
# kinds and counts, meta keys — groundwork for the 1.4.2 map audit.
func _initialize():call_deferred("run")
func run():
	var index=int(OS.get_cmdline_user_args()[0]) if not OS.get_cmdline_user_args().is_empty() else 3
	var g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.phase="lobby";g.options.map_random=false;g.options.map=index
	g.build_world();for i in range(4):await physics_frame
	var a=g.arena
	print("ARENA bounds=",a.bounds," indoors=",a.indoors," vertical=",a.vertical_map," polygon=",a.playable_polygon.size()," walk=",a.walk_surfaces.size()," obstacles=",a.obstacles.size()," props=",a.props.size()," doors=",a.doors.size())
	print("META ",a.get_meta_list())
	for child in a.get_children():
		var bodies=child.find_children("*","CollisionObject3D",true,false).size()+(1 if child is CollisionObject3D else 0)
		var meshes=child.find_children("*","MeshInstance3D",true,false).size()+(1 if child is MeshInstance3D else 0)
		print("CHILD ",child.name," ",child.get_class()," bodies=",bodies," meshes=",meshes," meta=",child.get_meta_list())
	var kinds={}
	for body in a.find_children("*","StaticBody3D",true,false):
		var k=str(body.get_parent().name)+"/"+str(body.name).rstrip("0123456789@")
		kinds[k]=int(kinds.get(k,0))+1
	var keys=kinds.keys();keys.sort()
	for k in keys.slice(0,40):print("BODY ",k," x",kinds[k])
	var sample=a.find_children("*","StaticBody3D",true,false).slice(0,5)
	for body in sample:print("SAMPLE ",body.get_path()," layer=",body.collision_layer," meta=",body.get_meta_list()," shapes=",body.get_child_count())
	quit()
