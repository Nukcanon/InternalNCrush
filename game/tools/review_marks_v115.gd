extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720)
	var scene=Node3D.new();root.add_child(scene)
	var wall=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(2,1.2,.1);wall.mesh=box;scene.add_child(wall)
	var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color(.55,.56,.57);wall.material_override=material
	for row in range(2):
		for col in range(5):
			var mark=BulletMark.make(row==1);scene.add_child(mark);mark.position=Vector3((col-2)*.26,.2-row*.4,.054);mark.quaternion=Quaternion(Vector3.UP,Vector3.BACK);mark.rotate_object_local(Vector3.UP,col*.8)
	var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,0,1.5);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.05;camera.current=true
	for n in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var picture=root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://validation")
	if picture.save_png("res://validation/bullet-marks-native-top-web-bottom.png")!=OK:quit(1);return
	# The opaque crater centre must actually render darker than the concrete.
	var centre=picture.get_pixel(640,223);var concrete=picture.get_pixel(700,223)
	if centre.get_luminance()>=concrete.get_luminance()*.6:printerr("Bullet crater failed to render");quit(1);return
	print("BULLET_MARK_RENDER_OK native=5 web=5");quit()
