extends SceneTree
## 1.4.2 carried gear review: every hero with its primary slung, a holstered
## sidearm and a class kit (armour tiers mixed), from the back, front-right and
## left. Output: validation/carried-v142/.
const OUT="res://../validation/carried-v142/"
const KITS=[[["plates",3]],[["marker",1],["defuse",1]],[["frag",2]],[["covers1",3]],[["smoke",3]],[["medkit",1],["flash",2]]]
const ARMOR=[2,1,0,2,1,0]
func _initialize():call_deferred("run")
func shot(name:String):
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run():
	DirAccess.make_dir_recursive_absolute(OUT);Catalog.load_all()
	root.size=Vector2i(1500,760)
	var world=Node3D.new();root.add_child(world)
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("bfd8e6");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.5;env.environment=e;world.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=.9;world.add_child(sun)
	var cam=Camera3D.new();world.add_child(cam);cam.current=true;cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	var heroes=[]
	for role in range(6):
		var h=HeroCharacter.new();world.add_child(h);h.build(role,role%2,true);h.play("Idle",.3);h.set_armor(ARMOR[role])
		h.position=Vector3((role-2.5)*1.1,0,0);heroes.append(h)
		var started=Time.get_ticks_usec()
		CarriedGear.apply(h,{"primary":Catalog.first(role),"secondary":["pistol","heavy_pistol","auto_pistol","dual_pistols","pistol","heavy_pistol"][role],"primary_out":false,"secondary_out":false,"kit":KITS[role],"armor":ARMOR[role]})
		print("CARRIED role=",role," ms=",(Time.get_ticks_usec()-started)/1000.," pieces=",h.skeleton.find_children("*","MeshInstance3D",true,false).filter(func(n):return n.get_parent() is BoneAttachment3D).size())
	# One camera in front; the heroes turn (their right side is +X, facing -Z).
	cam.size=2.4
	for view in [["front",0.],["back",PI],["right",PI/2],["left",-PI/2],["back-right",PI*.75]]:
		for h in heroes:h.rotation.y=view[1]
		for group in range(2):
			var mid=(group*3+1-2.5)*1.1
			cam.position=Vector3(mid,1.15,-8);cam.look_at(Vector3(mid,1.05,0))
			await shot("%s-%d" % [view[0],group])
	# Drawn: the primary leaves the back, the holster empties.
	for h in heroes:
		h.rotation.y=PI
		var spec:Dictionary=h.get_meta("carried_spec").duplicate();spec.primary_out=true;spec.secondary_out=true;CarriedGear.apply(h,spec)
	cam.position=Vector3(-1.65,1.15,-8);cam.look_at(Vector3(-1.65,1.05,0));await shot("drawn-back")
	print("CARRIED_REVIEW_OK");quit()
