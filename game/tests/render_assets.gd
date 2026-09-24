extends SceneTree
var stage:Node3D
var camera:Camera3D
func _initialize():call_deferred("run")
func label(text:String,pos:Vector3):
	var l=Label3D.new();l.text=text;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.font_size=44;l.pixel_size=.003;l.position=pos;l.modulate=Color("d6e6eb");stage.add_child(l)
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/inc-"+name+".png")
func run():
	Catalog.load_all();stage=Node3D.new();root.add_child(stage)
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("182833");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.65;world.environment=env;stage.add_child(world)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-38,155,0);key.light_energy=1.1;stage.add_child(key)
	MeshFactory.box(stage,Vector3(0,-.14,0),Vector3(17,.15,7),Color("304653"))
	camera=Camera3D.new();stage.add_child(camera);camera.position=Vector3(0,2.1,-11);camera.look_at(Vector3(0,1.05,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.6;camera.current=true
	var models=[]
	for i in range(6):
		var c=CharacterVisual.new();stage.add_child(c);c.build(i,0);c.position=Vector3((i-2.5)*1.48,0,0);c.rotation.y=-.22
		var w=WeaponVisual.new();c.socket.add_child(w);w.build(Catalog.get_weapon(Catalog.first(i)),false);w.scale=Vector3.ONE*.75
		c.animator.play("idle");c.animator.seek(.3,true);models.append(c);label(CharacterVisual.ROLE_NAMES[i],c.position+Vector3(0,2.2,0))
	await capture("operators")
	for i in range(6):
		models[i].animator.play(["walk","run","crouch_walk","reload","fire","hit"][i]);models[i].animator.seek([.16,.18,.24,.9,.08,.12][i],true)
	await capture("motion")
	for c in models:c.queue_free()
	for c in stage.get_children():
		if c is Label3D:c.queue_free()
	await process_frame
	camera.size=7.4;camera.position=Vector3(3,4.6,-6);camera.look_at(Vector3(0,.1,0))
	var ids=["a1","r2","h1","e2","c2","m1"]
	for i in range(ids.size()):
		var w=WeaponVisual.new();stage.add_child(w);w.build(Catalog.get_weapon(ids[i]),false);w.rotation.y=PI/2;w.position=Vector3((i%3-1)*2.2,.45,(i/3-.5)*2.4);label(Catalog.get_weapon(ids[i]).name,w.position+Vector3(0,-.35,-.7))
	await capture("weapons");stage.queue_free();await process_frame;quit()
