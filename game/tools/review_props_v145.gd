extends SceneTree
# 1.4.5: map props one by one (as DistrictProps / InteractiveProp build them)
# for the remodel of the original procedural / generated pieces.
# Args: kinds to render (default: the list below); "loose" renders the
# interactive barrel and tyre.
const DEFAULT=["vehicle_pickup","vehicle_van","vehicle_delivery","vehicle_flatbed","vehicle_utility","vehicle_dump","vehicle_compact","vehicle_hatch","vehicle_tow",
	"drums","cask_pair","cable_drum","gastank","watertank_floor","debris_tires","pipes","loose_barrel","loose_tire","loose_tire_flat"]
func _initialize():call_deferred("run")
func run():
	DisplayServer.window_set_size(Vector2i(640,480));root.size=Vector2i(640,480)
	Catalog.load_all();var out="res://../validation/v145-props/";DirAccess.make_dir_recursive_absolute(out)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("bfe3f5")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.5;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,140,0);sun.shadow_enabled=true;world.add_child(sun)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(40,40);ground.mesh=plane;var gm=StandardMaterial3D.new();gm.albedo_color=Color("9a968c");ground.material_override=gm;world.add_child(ground)
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=40
	var kinds=Array(OS.get_cmdline_user_args()).filter(func(x):return not x.begins_with("-"))
	if kinds.is_empty():kinds=DEFAULT
	for kind in kinds:
		var node=Node3D.new();world.add_child(node)
		if kind.begins_with("loose_"):
			var item=kind.replace("loose_","").replace("_flat","")
			var prop=InteractiveProp.new();prop.configure(7,item,false);node.add_child(prop);prop.position.y={"barrel":.485,"tire":.365}[item]
			if kind=="loose_tire_flat":prop.rotation.x=PI/2;prop.position.y=.12
		elif kind.begins_with("doorleaf_"):
			var kit=DistrictFacade.Kit.new();DoorModels.leaf(kit,kind.replace("doorleaf_",""),3)
			var mi=MeshInstance3D.new();mi.mesh=kit.detail.commit();mi.material_override=WorldSurface.material("detail",13,true);node.add_child(mi);node.rotation.y=-.5
		elif kind.begins_with("door_"):ImportedWorldProp.build(node,kind,Vector3(1.15,2.8,.5),"doors_original",true)
		elif kind.begins_with("kenney_"):ImportedWorldProp.build(node,kind.replace("kenney_",""),Vector3.ONE,"car",true)
		else:DistrictProps.build(node,kind,13,3+kinds.find(kind))
		var bounds=AABB();var first=true
		for m in node.find_children("*","MeshInstance3D",true,false):
			var b=node.global_transform.affine_inverse()*m.global_transform*m.get_aabb();bounds=b if first else bounds.merge(b);first=false
		var c=bounds.get_center();var r=maxf(bounds.size.length()*.5,.5)
		camera.position=c+Vector3(1.,.55,1.3).normalized()*r*3.;camera.look_at(c)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+kind+".png")
		print("PROP ",kind," size ",bounds.size.snapped(Vector3.ONE*.01)," meshes ",node.find_children("*","MeshInstance3D",true,false).size())
		node.free()
	print("PROPS_OK");quit()
