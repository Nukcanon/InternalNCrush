extends SceneTree
## 1.4.2 fitted armour review: every hero in tier 0/1/2, front and back
## (idle pose), plus the mesh sizes. Output: validation/armor-v142/.
const OUT="res://../validation/armor-v142/"
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1500,760)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.5;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=.9;world.add_child(sun)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.3
	for team in range(2):
		var heroes=[]
		for role in range(6):
			for level in range(3):
				var h=HeroCharacter.new();world.add_child(h);h.build(role,team,true);h.play("Idle")
				var started=Time.get_ticks_usec();h.set_armor(level)
				if level>0:print("ARMOR_BUILD role=",role," level=",level," team=",team," ms=",(Time.get_ticks_usec()-started)/1000.)
				h.position=Vector3((role*3+level-8.5)*.72,0,0);heroes.append(h)
				var fitted=h.skeleton.get_node_or_null("FittedArmor")
				if fitted and team==0:
					var tris=0
					for s in range(fitted.mesh.get_surface_count()):tris+=fitted.mesh.surface_get_array_len(s)/3
					print("ARMOR role=",role," level=",level," tris=",tris," aabb=",fitted.get_aabb())
				elif level>0 and team==0:print("ARMOR_MISSING role=",role," level=",level)
		cam.size=13.5
		cam.position=Vector3(0,1.,-6);cam.look_at(Vector3(0,1.,0));await shot("team%d-front" % team)
		cam.position=Vector3(0,1.,6);cam.look_at(Vector3(0,1.,0));await shot("team%d-back" % team)
		# Close-ups per hero (tiers 0, 1, 2 side by side, torso height).
		for role in range(6 if team==0 else 2):
			cam.size=1.2
			var mid=(role*3+1-8.5)*.72
			cam.position=Vector3(mid,1.2,-6);cam.look_at(Vector3(mid,1.2,0));await shot("team%d-role%d-front" % [team,role])
			cam.position=Vector3(mid,1.2,6);cam.look_at(Vector3(mid,1.2,0));await shot("team%d-role%d-back" % [team,role])
			cam.position=Vector3(mid+4.,1.9,-3.);cam.look_at(Vector3(mid,1.2,0));await shot("team%d-role%d-quarter" % [team,role])
		for h in heroes:h.queue_free()
		await process_frame
	print("ARMOR_REVIEW_OK");quit()
