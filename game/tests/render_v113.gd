extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(640,480)
	var scene=Node3D.new();root.add_child(scene)
	var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,1,5);camera.look_at(Vector3(0,1,0));camera.current=true
	var target=Node3D.new();scene.add_child(target)
	var body=MeshFactory.box(target,Vector3(0,1,0),Vector3(2.,2.,.4),Color("ce765a"))
	body.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var wall=MeshFactory.box(scene,Vector3(-.8,1,2),Vector3(1.3,2.5,.3),Color("353d48"));wall.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var baseline=root.get_texture().get_image();baseline.save_png("res://../validation/v113-occlusion-base.png")
	DeploymentSilhouette.apply(target,{"owner":1,"team":0},1)
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var overlay=root.get_texture().get_image();overlay.save_png("res://../validation/v113-occlusion-overlay.png")
	var visible_delta=0.;var hidden_delta=0.
	for y in range(195,285):
		for x in range(345,380):visible_delta+=baseline.get_pixel(x,y).r-overlay.get_pixel(x,y).r
		for x in range(260,290):hidden_delta+=overlay.get_pixel(x,y).b-baseline.get_pixel(x,y).b
	DeploymentSilhouette.apply(target,{"owner":1,"team":0},2)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	var other=root.get_texture().get_image();var wrong_viewer_delta=0.
	for y in range(195,285):
		for x in range(260,380):wrong_viewer_delta+=absf(other.get_pixel(x,y).b-baseline.get_pixel(x,y).b)
	print("OCCLUSION_GPU visible_delta=",visible_delta," hidden_delta=",hidden_delta," other_delta=",wrong_viewer_delta)
	var ok=absf(visible_delta)<1. and hidden_delta>100. and wrong_viewer_delta<1.
	scene.free();await process_frame;quit(0 if ok else 1)
