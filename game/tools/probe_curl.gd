extends SceneTree
# Renders right/left hand close-ups with procedural finger curls about candidate
# local axes, to pick the flexion axis of the Quaternius hand rig.
func _initialize():call_deferred("run")
func curl(hero:HeroCharacter,side:String,axis:Vector3,amount:float,thumb_axis:Vector3=Vector3.RIGHT):
	var sk=hero.skeleton
	for i in range(sk.get_bone_count()):
		var n=sk.get_bone_name(i)
		if not n.ends_with("."+side):continue
		var finger=n.begins_with("Index") or n.begins_with("Middle") or n.begins_with("Ring") or n.begins_with("Pinky")
		var thumb=n.begins_with("Thumb")
		if not (finger or thumb):continue
		var joint=int(n.substr(n.length()-3,1))
		var a=amount*([0.,.15,1.,.9,.6][joint] if finger else [0.,.3,.6,.7][joint])
		sk.set_bone_pose_rotation(i,sk.get_bone_rest(i).basis.get_rotation_quaternion()*Quaternion((axis if finger else thumb_axis).normalized(),a))
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,700)
	var cases=[["rest",Vector3.RIGHT,0.],["-X",Vector3.RIGHT,-1.3],["+X",Vector3.RIGHT,1.3],["-Z",Vector3.BACK,-1.3],["+Z",Vector3.BACK,1.3]]
	for side in ["R","L"]:
		for view in ["front","top"]:
			var scene=Node3D.new();root.add_child(scene)
			var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
			var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,30,0);scene.add_child(light)
			for i in range(cases.size()):
				var hero=HeroCharacter.new();scene.add_child(hero);hero.build(0,0,false)
				hero.play("Idle_Loop",0.);hero.tree.active=false
				curl(hero,side,cases[i][1],float(cases[i][2]))
				hero.first_person_only()
				var x=-.9+i*.45
				var wrist=hero.bone_world(hero.skeleton.find_bone("Wrist."+side))
				hero.position+=Vector3(x,1.3,0)-wrist.origin
				var label=Label3D.new();label.text=cases[i][0];label.position=Vector3(x,1.58,0);label.rotation.y=PI;label.font_size=28;label.pixel_size=.004;label.modulate=Color.BLACK;scene.add_child(label)
			var camera=Camera3D.new();scene.add_child(camera);camera.fov=45
			if view=="front":camera.position=Vector3(0,1.3,-1.25);camera.look_at(Vector3(0,1.3,0))
			else:camera.position=Vector3(0,2.5,-.35);camera.look_at(Vector3(0,1.3,0))
			camera.current=true
			for i in range(3):await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../validation/curl-%s-%s.png"%[side,view])
			scene.queue_free();await process_frame
	quit()
