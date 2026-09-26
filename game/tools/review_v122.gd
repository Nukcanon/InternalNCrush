extends SceneTree
const OUT="res://../validation/v122/"
func _initialize():call_deferred("run")
func capture(name:String):
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(OUT+name+".jpg",.96)
func run():
	root.size=Vector2i(1100,800);DisplayServer.window_set_size(root.size);DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	var preview=EquipmentPreview.new();root.add_child(preview);preview.size=Vector2(1100,800)
	for web in [false,true]:
		ProjectSettings.set_setting("application/config/web_assets",web)
		for level in [1,2]:
			preview.display(3,0,0,"a1",level);await capture(("web" if web else "native")+"-armor"+str(level))
	ProjectSettings.set_setting("application/config/web_assets",false)
	for role in range(6):
		preview.display(0,role,0,Catalog.first(role),0,2);await capture("operator"+str(role))
	preview.display(2,4,0,"c1",1);await capture("flash-small")
	preview.free()
	var scene=Node3D.new();root.add_child(scene)
	var wall=MeshFactory.box(scene,Vector3.ZERO,Vector3(3,2,.08),Color("868680"))
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-25,-25,0);scene.add_child(light)
	for row in range(2):
		for col in range(3):
			var mark=BulletMark.make(row==1) if col==0 else MeleeMark.make(row==1,col==2)
			scene.add_child(mark);mark.position=Vector3((col-1)*.65,.3-row*.6,.045);mark.quaternion=Quaternion(Vector3.UP,Vector3.BACK)
	var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,0,2);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.6;camera.current=true
	await capture("marks-native-top-web-bottom");scene.free();print("V122_REVIEW_OK");quit()
