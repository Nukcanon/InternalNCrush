extends SceneTree
# Hand lab: one hero holding one item, close-ups of both hands from four sides
# (outside, inside, below-front, above-back) plus a full upper-body view.
# Usage: -- <case>[,<case>...]   case = weapon id[:reload phase][:left] | all
# Output: validation/hands/<case>.png (5 tiles of 480x480).
const ALL=["a1","c1","e1","e3","r1","r2","h1","h4","h5","h6","m1","pistol","heavy_pistol","eng_pistol","dual_pistols","a1:.2","a1:.45","a1:.9","pistol:.45","pistol:.9","e1:.5","h4:.45","h4:.65","h5:.45","h5:.65","h6:.5","a1:left","pistol:left"]
var out="res://../validation/hands/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(480,480)
	Catalog.load_all()
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("d4dbe2");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.55;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,30,0);scene.add_child(light)
	var cam=Camera3D.new();scene.add_child(cam);cam.fov=38;cam.near=.02;cam.current=true
	var args=OS.get_cmdline_user_args()
	var cases:Array=ALL if args.is_empty() or args[0]=="all" else Array(args[0].split(","))
	for c in cases:
		var parts=str(c).split(":")
		var id=parts[0];var phase=-1.;var hand=1
		for extra in parts.slice(1):
			if extra=="left":hand=-1
			else:phase=float(extra)
		var w=Catalog.get_weapon(id)
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(0 if int(w.get("role",0))<0 else int(w.get("role",0)),0,true)
		hero.scale.x=hand
		var gun=GunModel.new();gun.build(w,true);hero.hold(gun)
		var kind=GunLooks.hold_kind(w)
		if kind=="shoulder":kind="rifle"
		var s={"hold":kind,"hands":1.,"pitch":0.,"reload":phase,"reload_time":float(w.get("reload",2.)),"rounds":0 if phase>=0. else int(w.get("mag",1)),"reload_tactical":false,"velocity":Vector3.ZERO,"grounded":true,"shot":9.}
		if kind=="pistol":s.two_hands=bool(w.get("dual",false))
		gun.set_rounds(int(s.rounds),phase)
		gun.animate_reload(phase)
		for i in range(8):
			hero.drive(1./30.,s);await process_frame
		var tiles=[]
		# Close-ups show only the arms (as in first person) so the torso never blocks the view.
		hero.first_person_only()
		var hands=["R","L"] if kind!="pistol" or bool(w.get("dual",false)) or phase>=0. else ["R"]
		var facing=hero.facing_basis()
		for side in hands:
			var wrist=hero.bone_world(hero.bone["Wrist."+side])
			var palm:Vector3=wrist.origin+wrist.basis.orthonormalized().y*.08
			var outward=facing.x.normalized()*(1. if side=="R" else -1.)
			for view in [outward*.42+Vector3.UP*.05,-outward*.42+Vector3.UP*.06,facing.z*-.36+Vector3.DOWN*.25,facing.z*.35+Vector3.UP*.28]:
				cam.position=palm+view;cam.look_at(palm,Vector3.UP if absf(view.normalized().y)<.95 else facing.z)
				for i in range(2):await process_frame
				await RenderingServer.frame_post_draw
				tiles.append(root.get_texture().get_image())
		for mesh in hero.meshes():mesh.show()
		var arms=hero.skeleton.get_node_or_null("FPArms")
		if arms:arms.hide()
		var chest=hero.bone_world(hero.bone["Chest"]).origin
		cam.position=chest+facing.x*1.1+facing.z*-.9+Vector3.UP*.25;cam.look_at(chest+facing.z*-.25)
		for i in range(2):await process_frame
		await RenderingServer.frame_post_draw
		tiles.append(root.get_texture().get_image())
		var sheet=Image.create(480*tiles.size(),480,false,Image.FORMAT_RGBA8)
		for i in range(tiles.size()):
			tiles[i].convert(Image.FORMAT_RGBA8);sheet.blit_rect(tiles[i],Rect2i(0,0,480,480),Vector2i(480*i,0))
		sheet.save_png(out+str(c).replace(":","_").replace(".","")+".png")
		print("HAND ",c)
		hero.queue_free();await process_frame
	print("HAND_LAB_OK");quit()
