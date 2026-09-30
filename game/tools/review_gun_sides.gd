extends SceneTree
## Every weapon from its left side (the support-hand side) with its grip markers:
## blue = firing hand, red = support hand, yellow = magazine centre.
## Output: validation/gun-sides/sides-N.png (8 weapons per sheet, to scale).
const OUT="res://../validation/gun-sides/"
func _initialize():call_deferred("run")
func dot(parent:Node3D,pos:Vector3,color:Color):
	var m=MeshInstance3D.new();var s=SphereMesh.new();s.radius=.014;s.height=.028;m.mesh=s
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.no_depth_test=true;m.material_override=mat
	parent.add_child(m);m.position=pos
func run():
	DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	root.size=Vector2i(1400,1000)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("d8e4ea");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.6;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-30,-60,0);world.add_child(sun)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.8
	var ids=Catalog.weapons.keys().filter(func(id):return Catalog.get_weapon(id).kind=="gun")
	var sheet=0
	for start in range(0,ids.size(),8):
		var nodes=[]
		for k in range(start,mini(start+8,ids.size())):
			var w=Catalog.get_weapon(ids[k])
			var holder=Node3D.new();world.add_child(holder);nodes.append(holder)
			holder.position=Vector3(0,1.2-(k-start)*.34,0)
			var gun=GunModel.new();holder.add_child(gun);gun.build(w,false)
			var s=gun.base.scale
			dot(holder,gun.right_grip.position*s,Color("2f6bff"));dot(holder,gun.left_grip.position*s,Color("ff3030"))
			if is_instance_valid(gun.magazine):dot(holder,ReloadMotion.magazine(gun,s,Vector3.ZERO)[0],Color("ffd21f"))
			var label=Label3D.new();label.text="%s %s" % [ids[k],w.name];label.pixel_size=.0022;label.font_size=40;label.modulate=Color.BLACK;label.outline_size=0
			holder.add_child(label);label.position=Vector3(0,.02,.35);label.rotation.y=-PI/2
		# Camera on the gun's left (-X), looking +X: muzzle (-Z) to the left of the image.
		cam.position=Vector3(-3,.02,-.45);cam.look_at(Vector3(0,.02,-.45))
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"sides-%d.png" % sheet);sheet+=1
		for n in nodes:n.queue_free()
		await process_frame
	print("GUN_SIDES_OK");quit()
