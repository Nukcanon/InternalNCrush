extends SceneTree
var g:Node
var camera:Camera3D
var frames=0
var finishing=false
var which=5
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene-map="):which=int(arg.trim_prefix("--scene-map="))
	g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.options.map=which;g.options.mode=3;g.options.target=10000;g.options.bot_difficulty=1;g.server=true;g.phase="lobby";g.build_world()
	for i in range(1,13):
		g.add_player(-i,"BOT %02d"%i,"movie_bot_"+str(i));var p=g.players[-i];p.team=i%2;p.role=(i/2)%6;p.primary=Catalog.first(p.role);p.secondary=Rules.SECONDARIES[p.role];g.equip_ammo(p)
		var a=g.actors[-i];a.position=Vector3(18+(i%3)*4,.1,26+floor(i/3.)*2 if p.team==0 else -6-floor(i/3.)*2);a.reset_view(0 if p.team==0 else PI);p.protect=1.5;p.alive=true
	g.ui.clear_panel();g.ui.root.visible=false;g.phase="combat";g.remaining=600.;g.input_timer=1e6
	camera=Camera3D.new();g.add_child(camera);camera.fov=70;camera.far=300;camera.current=true;g.set_physics_process(true)
	process_frame.connect(frame)
func frame():
	if finishing:return
	frames+=1
	var t=frames/24.;camera.position=Vector3(29-t*.2,3.7,35-t*.2);camera.look_at(Vector3(20,1.25,8));camera.current=true
	if frames==108:root.get_texture().get_image().save_png("/tmp/inc-v05-action.png" if which==5 else "/tmp/inc-v05-foundry.png")
	if frames>=192:
		finishing=true;g.set_physics_process(false);print("MENU_RECORD_COMPLETE frames=",frames," bot_kills=",g.players.values().reduce(func(total,p):return total+p.kills,0));g.audio_bank.stop_all();await create_timer(.15).timeout;g.queue_free();await process_frame;await process_frame;quit()
