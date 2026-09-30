extends SceneTree
## 1.4.2 deployable / gear model review: cover tiers (front and back), turrets
## per team (front, side), medkit and armour plate close-ups. Output:
## validation/devices-v142/.
const OUT="res://../validation/devices-v142/"
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1200,800)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.5;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=.9;sun.shadow_enabled=true;world.add_child(sun)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(40,40);ground.mesh=plane;var gm=StandardMaterial3D.new();gm.albedo_color=Color("9a9486");ground.material_override=gm;world.add_child(ground)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.fov=40
	# Cover tiers side by side, enemy face (-Z) toward the camera.
	var covers=[]
	for tier in range(3):
		var holder=Node3D.new();world.add_child(holder);holder.position=Vector3(-4.+tier*4.,0,0);GearModels.cover(holder,0,tier);covers.append(holder)
	cam.position=Vector3(0,2.2,-8.5);cam.look_at(Vector3(0,.7,0));await shot("cover-front")
	cam.position=Vector3(0,2.4,8.);cam.look_at(Vector3(0,.7,0));await shot("cover-back")
	cam.position=Vector3(4.,1.6,-3.4);cam.look_at(Vector3(4.,.7,0));await shot("cover-heavy-close")
	for c in covers:c.queue_free()
	# Turrets, both teams.
	var turrets=[]
	for team in range(2):
		var holder=Node3D.new();world.add_child(holder);holder.position=Vector3(-1.2+team*2.4,0,0);GearModels.turret(holder,team);turrets.append(holder)
	cam.position=Vector3(0,2.4,-5.2);cam.look_at(Vector3(0,1.1,0));await shot("turret-front")
	cam.position=Vector3(4.2,2.,1.5);cam.look_at(Vector3(0,1.1,0));await shot("turret-side")
	cam.position=Vector3(-1.2,2.3,-1.6);cam.look_at(Vector3(-1.2,1.65,-.2));await shot("turret-head")
	for t in turrets:t.queue_free()
	# Held gear close-ups (medkit, plate) as the hand holds them.
	var kits=[]
	for spec in [[5,0,Vector3(-.3,1.2,0)],[0,0,Vector3(.3,1.2,0)]]:
		var holder=Node3D.new();world.add_child(holder);holder.position=spec[2];GearModels.held(holder,spec[0],spec[1]);kits.append(holder)
	cam.position=Vector3(0,1.3,-1.1);cam.look_at(Vector3(0,1.1,-.08));await shot("medkit-plate-front")
	cam.position=Vector3(.9,1.5,.7);cam.look_at(Vector3(0,1.1,-.08));await shot("medkit-plate-back")
	print("DEVICES_REVIEW_OK");quit()
