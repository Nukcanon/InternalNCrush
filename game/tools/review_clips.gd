extends SceneTree
# Contact sheet of hero clips (native + retargeted). Args after "--": role clip...
const SETS={"core":["Idle_Gun","Crouch_Idle_Loop","Crouch_Fwd_Loop","Pistol_Aim_Neutral","Pistol_Reload","Jump_Loop","Slide_Loop","OverhandThrow","Death01","Fixing_Kneeling","Sprint_Loop","Hit_Knockback"],
	"gun":["Idle_Gun","Idle_Gun_Pointing","Idle_Gun_Shoot","Gun_Shoot","Run_Shoot","Run","Pistol_Idle_Loop","Pistol_Aim_Up","Pistol_Aim_Neutral","Pistol_Aim_Down","Pistol_Shoot","Pistol_Reload"]}
var CLIPS=[]
func _initialize():call_deferred("run")
func run():
	var args=OS.get_cmdline_user_args();var role=int(args[0]) if args.size()>0 else 0;var set_name=args[1] if args.size()>1 else "core";CLIPS=SETS[set_name]
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1800,900)
	var scene=Node3D.new();root.add_child(scene)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("c9d3dc");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;scene.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,150,0);scene.add_child(light)
	var labels=[]
	for i in range(CLIPS.size()):
		var hero=HeroCharacter.new();scene.add_child(hero);hero.build(role,0,true)
		hero.position=Vector3(-5.5+(i%6)*2.2,0,(i/6)*3.);hero.rotation.y=deg_to_rad(-60)
		var clip=CLIPS[i]
		if hero.player.has_animation(clip):hero.player.play(clip);hero.player.seek(hero.player.get_animation(clip).length*.45,true)
		var label=Label3D.new();label.text=clip;label.position=hero.position+Vector3(0,2.1+(i/6)*.35,0);label.font_size=40;label.pixel_size=.006;label.modulate=Color.BLACK;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;scene.add_child(label)
	var camera=Camera3D.new();camera.position=Vector3(0,3.,-7.5);camera.fov=55;scene.add_child(camera);camera.look_at(Vector3(0,.8,1.5));camera.current=true
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../validation/clips-%s-%d.png"%[set_name,role]);quit()
