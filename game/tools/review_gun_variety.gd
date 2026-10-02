extends SceneTree
## 1.5.0: guns of one role side by side (left side, 3/4 view) to check they differ in shape.
const OUT="res://../validation/gun-variety/"
const GROUPS=[["SIDE","FEATHER","TRIO","RIVET","CHIME"],["VECTOR-24","RAPID-9","ATLAS","TRIAD"],["SCOUT","ECHO","KESTREL","LARK"],["ANCHOR","BASTION","SWIFT","FLUX"],["LINE","HIVE","PIPER","SIDE","SPARK"]]
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	root.size=Vector2i(1500,1000)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("d8e4ea");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.6;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-30,-60,0);world.add_child(sun)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.1
	var by_name={}
	for id in Catalog.weapons.keys():by_name[str(Catalog.get_weapon(id).name)]=id
	var sheet=0
	for group in GROUPS:
		var nodes=[]
		for k in range(group.size()):
			if not by_name.has(group[k]):print("MISSING ",group[k]);continue
			var w=Catalog.get_weapon(by_name[group[k]])
			var holder=Node3D.new();world.add_child(holder);nodes.append(holder)
			holder.position=Vector3(0,.8-k*.42,0);holder.rotation.y=-.35
			var gun=GunModel.new();holder.add_child(gun);gun.build(w,false)
			var label=Label3D.new();label.text=str(w.name);label.pixel_size=.0022;label.font_size=40;label.modulate=Color.BLACK;label.outline_size=0
			holder.add_child(label);label.position=Vector3(0,.12,.3);label.rotation.y=-PI/2
		cam.position=Vector3(-3,0,-.45);cam.look_at(Vector3(0,0,-.45))
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"variety-%d.png" % sheet);sheet+=1
		for n in nodes:n.queue_free()
		await process_frame
	print("GUN_VARIETY_OK");quit()
