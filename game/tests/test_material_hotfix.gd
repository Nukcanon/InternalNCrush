extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	g.set_process(false);g.ui.clear_panel();g.phase="combat"
	g.profile.graphics_auto=false;g.profile.menu_animation=false;g.profile.display_mode=0;g.profile.width=1280;g.profile.height=720;g.apply_display_settings();g.options.map_random=false;g.options.map=17;g.build_world()
	var camera=Camera3D.new();g.add_child(camera);camera.current=true
	var p=DistrictLayout.read_plan(17).facades[0];var target=Vector3(p[0],p[4]+1.6,p[1])
	camera.position=target+Vector3(sin(p[2]),0,cos(p[2]))*5.;camera.look_at(target)
	var before=Vector2i(g.profile.width,g.profile.height);var hashes=[]
	for quality in [0,1,2]:
		g.profile.merge(GraphicsOptions.PRESETS[quality],true);GraphicsOptions.apply(g)
		for i in range(12):await process_frame
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image();hashes.append(image.get_data().hex_encode().sha256_text())
		image.save_png("res://../validation/v128/hotfix-quality-%d.png"%quality)
		print("HOTFIX_QUALITY ",quality," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," resources=",Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)," vram=",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	assert(hashes[0]!=hashes[1] and hashes[1]!=hashes[2],"Quality settings must produce different rendered pixels")
	assert(before==Vector2i(g.profile.width,g.profile.height),"Effects must not change output resolution")
	g.free();await process_frame;print("MATERIAL_HOTFIX_PASS");quit()
