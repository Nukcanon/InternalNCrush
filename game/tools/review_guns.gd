extends SceneTree
# All game guns (GunModel) with grip markers (right = red, left = blue, muzzle = yellow).
func _initialize():call_deferred("run")
func dot(parent:Node3D,pos:Vector3,color:Color):
	var m=MeshInstance3D.new();var s=SphereMesh.new();s.radius=.018;s.height=.036;m.mesh=s;var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.no_depth_test=true;m.material_override=mat;parent.add_child(m);m.global_position=pos
func run():
	Catalog.load_all()
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,1000)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d5dde4");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,30,0);scene.add_child(light)
	var ids=[]
	for id in Catalog.weapons:
		if Catalog.weapons[id].get("kind","")=="gun":ids.append(id)
	for i in range(ids.size()):
		var w=Catalog.get_weapon(ids[i]);var gun=GunModel.new();scene.add_child(gun);gun.build(w,true)
		gun.rotation.y=-PI/2;gun.position=Vector3(-6.4+(i%6)*2.4,3.4-(i/6)*1.5,0)
		if GunLooks.hold_kind(w)=="pistol":gun.position.x-=.3
		await process_frame
		dot(scene,gun.right_grip.global_position,Color.RED);dot(scene,gun.left_grip.global_position,Color.BLUE);dot(scene,gun.muzzle.global_position,Color.YELLOW)
		var label=Label3D.new();label.text=str(w.name);label.position=gun.position+Vector3(-.3,.35,0);label.font_size=36;label.pixel_size=.006;label.modulate=Color.BLACK;scene.add_child(label)
	var camera=Camera3D.new();camera.position=Vector3(0,0,10.5);camera.fov=52;scene.add_child(camera);camera.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/guns.png");quit()
