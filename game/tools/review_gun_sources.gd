extends SceneTree
# Raw Toon Shooter (CC0) guns side by side, with +X (red) / +Y (green) axes.
const DIR="res://../../.tools/quaternius-toonshooter/guns/"
const GUNS=["AK","SMG","Pistol","Revolver","Revolver_Small","Shotgun","ShortCannon","Sniper","Sniper_2","RocketLauncher","GrenadeLauncher","Grenade","FireGrenade","Knife_1","Knife_2","Shovel"]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,1000)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d5dde4");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,20,0);scene.add_child(light)
	for i in range(GUNS.size()):
		var doc=GLTFDocument.new();var state=GLTFState.new()
		doc.append_from_file(ProjectSettings.globalize_path(DIR+GUNS[i]+".gltf"),state)
		var node:Node3D=doc.generate_scene(state);scene.add_child(node)
		var aabb=AABB();var first=true
		for m in node.find_children("*","MeshInstance3D",true,false):
			var box=m.global_transform*m.mesh.get_aabb()
			aabb=box if first else aabb.merge(box);first=false
		var fit=1.4/maxf(aabb.size.x,maxf(aabb.size.y,aabb.size.z))
		node.scale=Vector3.ONE*fit;node.position=Vector3(-6.+(i%4)*4.,4.5-(i/4)*3.,0)-aabb.get_center()*fit
		for axis in [[Vector3.RIGHT,Color.RED],[Vector3.UP,Color.GREEN]]:
			var bar=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3(.03,.03,.03)+axis[0]*.6;bar.mesh=mesh;var mat=StandardMaterial3D.new();mat.albedo_color=axis[1];mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;bar.material_override=mat
			bar.position=Vector3(-6.+(i%4)*4.,4.5-(i/4)*3.,.5)+axis[0]*.3-Vector3(1.4,1.,0);scene.add_child(bar)
		var label=Label3D.new();label.text=GUNS[i]+" %.2f"%(aabb.size.x);label.position=Vector3(-6.+(i%4)*4.,4.5-(i/4)*3.+1.,0);label.font_size=48;label.pixel_size=.008;label.modulate=Color.BLACK;scene.add_child(label)
	var camera=Camera3D.new();camera.position=Vector3(0,0,14);camera.fov=52;scene.add_child(camera);camera.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/gun-sources.png");quit()
