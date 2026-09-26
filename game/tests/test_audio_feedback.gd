extends SceneTree
var checks=0
var failures=0
var heard=[]
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel()
	await process_frame;await process_frame
	g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(200,1,200),Color.GRAY)
	g.add_player(1,"Local","local");g.add_player(2,"Enemy","enemy");g.phase="combat";g.clock=100.
	g.players[1].team=0;g.players[2].team=1
	for id in [1,2]:g.players[id].protect=0.;g.players[id].armor=0.;g.players[id].hp=100.;g.players[id].alive=true
	g.audio_bank.played.connect(func(key,_world):heard.append(key))
	for key in ["hit","hurt","armor_hurt","deploy","confirm","melee_swing","knife_wall","wrench_wall"]:
		expect(g.audio_bank.streams.has(key) and g.audio_bank.streams[key].get_length()>.05,"full feedback sample present: "+key)
	var capture=AudioEffectCapture.new();AudioServer.add_bus_effect(0,capture);AudioServer.set_bus_mute(0,false);AudioServer.set_bus_volume_db(0,0.)
	g.damage(2,10.,1);expect("hit" in heard and g.ui.hit_until>Time.get_ticks_msec(),"player hit plays sample and shows marker")
	heard.clear();g.last_hurt_sound=-100.;g.damage(1,10.,2);expect("hurt" in heard,"local flesh damage plays hurt sample")
	heard.clear();g.players[1].armor=50.;g.last_hurt_sound=-100.;g.damage(1,10.,2);expect("armor_hurt" in heard,"local armor damage plays impact sample")
	heard.clear();var did=g.add_device("turret",Vector3(4,0,0),2,100.)
	g.ui.hit_until=0;g.damage_device(did,10.,1)
	expect("hit" in heard and g.ui.hit_until>Time.get_ticks_msec() and g.devices[did].hp==90.,"enemy turret damage has identical hit sound and marker")
	heard.clear();g.devices[did].team=0;g.damage_device(did,10.,1);expect(heard.is_empty() and g.devices[did].hp==90.,"blocked friendly damage produces no false hit feedback")
	g.players[1].role=3;g.players[1].skill_ready=0.;g.actors[1].position=Vector3(20,0,20);g.actors[1].reset_view(0.);g.players[1].placing="turret"
	await physics_frame;await physics_frame
	heard.clear();expect(Deployment.confirm(g,1) and "deploy" in heard,"confirmed placement plays deployment audio")
	await create_timer(.2).timeout
	var samples=capture.get_buffer(capture.get_frames_available());var peak=0.
	for sample in samples:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	expect(peak>.001,"audio mixer produces non-silent PCM for combat feedback")
	g.audio_bank.play("hurt",Vector3.ZERO,false)
	var reserved=g.audio_bank.feedback_voices.filter(func(v):return v.playing)
	for i in range(40):g.audio_bank.play("gun_a1",Vector3.ZERO,false)
	expect(not reserved.is_empty() and reserved[0].playing,"gunfire cannot steal reserved feedback voices")
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	g.free();await process_frame
	print("AUDIO_FEEDBACK_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
