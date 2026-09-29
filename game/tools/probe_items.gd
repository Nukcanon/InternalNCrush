extends SceneTree
# Standalone render of the melee tools and held gadgets (visibility check).
func _initialize():call_deferred("run")
func describe(node:Node3D,label:String):
	var meshes=node.find_children("*","MeshInstance3D",true,false)
	var box=AABB()
	for m in meshes:
		var a:AABB=m.global_transform*m.get_aabb()
		box=a if box.size==Vector3.ZERO else box.merge(a)
	print("%s: %d meshes, visible=%s, aabb=%s"%[label,meshes.size(),node.visible,box])
	for m in meshes:print("   ",m.name," visible=",m.visible," vis_in_tree=",m.is_visible_in_tree()," mat=",m.material_override," surfaces=",m.mesh.get_surface_count() if m.mesh else -1)
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1200,600)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,30,0);scene.add_child(light)
	var wrench=MeleeVisual.new();scene.add_child(wrench);wrench.build(true,3,false);wrench.position=Vector3(-.6,0,0)
	var knife=MeleeVisual.new();scene.add_child(knife);knife.build(false,0,false);knife.position=Vector3(-.2,0,0)
	var frag=GadgetVisual.new();scene.add_child(frag);frag.build(0,1,true);frag.position=Vector3(.2,0,0)
	var smoke=GadgetVisual.new();scene.add_child(smoke);smoke.build(4,0,true);smoke.position=Vector3(.6,0,0)
	for i in range(3):await process_frame
	describe(wrench,"wrench");describe(knife,"knife");describe(frag,"frag");describe(smoke,"smoke")
	var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,.3,-1.4);camera.look_at(Vector3(0,.05,0));camera.current=true;camera.fov=50
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/items.png");quit()
