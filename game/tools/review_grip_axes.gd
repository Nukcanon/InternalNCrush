extends SceneTree
# 1.4.5: side view (orthographic, from the gun's right) of one weapon per base
# with its firing-hand handle drawn on top: the handle's long axis (red) and
# its centre (yellow). Shows whether the hand is set along a pistol grip or a
# straight stock wrist. Output: validation/grip-axes/<base>.png
const WEAPONS={"AK":"a1","SMG":"a2","Pistol":"pistol","Revolver":"heavy_pistol","Revolver_Small":"dual_pistols","Shotgun":"e1","ShortCannon":"e3","Sniper":"r1","Sniper_2":"r2"}
func _initialize():call_deferred("run")
func run():
	Catalog.load_all()
	var out="res://../validation/grip-axes/";DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1200,600);DisplayServer.window_set_size(Vector2i(1200,600))
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e8e4dc");env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1.;root.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,60,0);root.add_child(sun)
	var cam=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;root.add_child(cam);cam.current=true
	for base_name in WEAPONS:
		var wid=WEAPONS[base_name]
		if not Catalog.weapons.has(wid):continue
		var gun=GunModel.new();root.add_child(gun);gun.build(Catalog.get_weapon(wid),false)
		var box=AABB();var first=true
		for m in gun.find_children("*","MeshInstance3D",true,false):
			var b:AABB=m.global_transform*m.get_aabb()
			box=b if first else box.merge(b);first=false
		var centre=box.get_center()
		cam.size=maxf(box.size.z,box.size.y*2.)*1.15
		cam.global_position=centre+Vector3(2.,0,0);cam.look_at(centre,Vector3.UP)
		var grip:Node3D=gun.right_grip
		var axis=MeshInstance3D.new();var cyl=CylinderMesh.new();cyl.top_radius=.004;cyl.bottom_radius=.004;cyl.height=.22;axis.mesh=cyl
		var red=StandardMaterial3D.new();red.albedo_color=Color.RED;red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;red.no_depth_test=true;axis.material_override=red
		root.add_child(axis);axis.global_transform=Transform3D(grip.global_basis.orthonormalized(),grip.global_position)
		var dot=MeshInstance3D.new();var sph=SphereMesh.new();sph.radius=.012;sph.height=.024;dot.mesh=sph
		var yel=StandardMaterial3D.new();yel.albedo_color=Color.YELLOW;yel.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;yel.no_depth_test=true;dot.material_override=yel
		root.add_child(dot);dot.global_position=grip.global_position
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+base_name+".png")
		print("GRIPAXIS %s (%s) tilt %.2f rad"%[base_name,wid,float(GunModel.HANDLES.get(base_name,{}).get("tilt",0.))])
		gun.queue_free();axis.queue_free();dot.queue_free();await process_frame
	quit()
