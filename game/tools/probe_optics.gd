extends SceneTree
# Front-quarter and rear-quarter renders of every scoped gun (baked sniper
# scopes and the attached scope) to check the lens faces.
const NAMES=["MONOLITH","SCOUT","ECHO","KESTREL","ARC","ATLAS","LARK"]
func _initialize():call_deferred("run")
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,1000)
	Catalog.load_all()
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.6;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,40,0);scene.add_child(light)
	var camera=Camera3D.new();scene.add_child(camera);camera.fov=30;camera.current=true
	for name in NAMES:
		var spec={}
		for id in Catalog.weapons:
			if str(Catalog.weapons[id].get("name",""))==name:spec=Catalog.weapons[id]
		if spec.is_empty():print("missing ",name);continue
		var gun=GunModel.new();scene.add_child(gun);gun.build(spec,true)
		var centre=gun.aim_point.position*gun.base.scale
		var view=0
		for offset in [Vector3(.35,.18,-1.0),Vector3(.3,.15,.8),Vector3(1.2,.1,0)]:
			camera.position=centre+offset;camera.look_at(centre)
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../validation/optics/%s_%d.png"%[name,view]);view+=1
		gun.queue_free();await process_frame
	print("OPTICS_OK");quit()
