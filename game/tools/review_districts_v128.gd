extends SceneTree
var camera:Camera3D
func _initialize():call_deferred("run")
func shot(name:String):
	for frame in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/v128/"+name+".png")
func run():
	GraphicsOptions.shadows=0;GraphicsOptions.lighting=1
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
	DirAccess.make_dir_recursive_absolute("res://../validation/v128")
	camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.far=500.
	for index in [17,22,18,3,5,16,10,27]:
		var arena=Arena.new();arena.bake_geometry=true;root.add_child(arena);arena.build(index)
		var plan=DistrictLayout.read_plan(index)
		var target=arena.zones[0]+Vector3.UP*1.6
		camera.position=target+Vector3(4,3,7);camera.look_at(target);await shot("map-%02d-objective"%index)
		if not plan.props.is_empty():
			var p=plan.props[0];var origin=Vector3(p[0],p[2]+1.,p[1]);var forward=Vector3(-sin(p[3]),0,-cos(p[3]))
			camera.position=origin+forward*5.+Vector3.UP;camera.look_at(origin);await shot("map-%02d-props"%index)
		if not plan.facades.is_empty():
			var f=plan.facades[0];var origin=Vector3(f[0],f[4]+1.7,f[1]);var direction=Vector3(sin(f[2]),0,cos(f[2]))
			camera.position=origin+direction*7.;camera.look_at(origin);await shot("map-%02d-street"%index)
		print("V128_VISUAL ",index," meshes=",arena.find_children("*","MeshInstance3D",true,false).size()," props=",plan.props.size())
		arena.free();await process_frame
	print("V128_MAP_REVIEW_DONE");quit()
