extends SceneTree
var checks=0
var failures=0
var heard=[]
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false)
	await process_frame;await process_frame
	g.ui.clear_panel()
	g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(200,1,200),Color.GRAY)
	g.add_player(1,"Local","local");g.add_player(2,"Enemy","enemy");g.phase="combat";g.clock=100.
	g.players[1].team=0;g.players[2].team=1
	for id in [1,2]:g.players[id].protect=0.;g.players[id].armor=0.;g.players[id].hp=100.;g.players[id].alive=true
	g.audio_bank.played.connect(func(key,_world):heard.append(key))
	for key in ["hit","hurt","armor_hurt","deploy","confirm","melee_swing","knife_wall","wrench_wall","knife_flesh","wrench_flesh","wrench_repair"]:
		expect(g.audio_bank.streams.has(key) and g.audio_bank.streams[key].get_length()>.05,"full feedback sample present: "+key)
	var capture=AudioEffectCapture.new();AudioServer.add_bus_effect(0,capture);AudioServer.set_bus_mute(0,false);AudioServer.set_bus_volume_db(0,0.)
	g.damage(2,10.,1);expect("hit" in heard and g.ui.hit_until>Time.get_ticks_msec(),"player hit plays sample and shows marker")
	heard.clear();g.last_hurt_sound=-100.;g.damage(1,10.,2);expect("hurt" in heard,"local flesh damage plays hurt sample")
	heard.clear();g.players[1].armor=50.;g.last_hurt_sound=-100.;g.damage(1,10.,2);expect("armor_hurt" in heard,"local armor damage plays impact sample")
	heard.clear();var did=g.add_device("turret",Vector3(4,0,0),2,100.)
	g.ui.hit_until=0;g.damage_device(did,10.,1)
	expect("hit" in heard and g.ui.hit_until>Time.get_ticks_msec() and g.devices[did].hp==90.,"enemy turret damage has identical hit sound and marker")
	heard.clear();g.devices[did].team=0;g.damage_device(did,10.,1);expect(heard.is_empty() and g.devices[did].hp==90.,"blocked friendly damage produces no false hit feedback")
	for tool in [false,true]:
		g.players[1].role=3 if tool else 0;g.players[1].melee_hits={};g.players[2].hp=100.;g.players[2].armor=0.;heard.clear()
		MeleeCombat.contact(g,1,{"collider":g.actors[2],"position":g.actors[2].eye(),"zone":"torso"},g.actors[1].eye(),Vector3.FORWARD)
		expect(("wrench_flesh" if tool else "knife_flesh") in heard,"actual character contact plays the correct tool's body impact")
		g.players[1].melee_hits={};g.devices[did].team=1;heard.clear()
		var device=StaticBody3D.new();g.add_child(device);device.set_meta("device",did)
		MeleeCombat.contact(g,1,{"collider":device,"position":Vector3.ZERO},Vector3.ZERO,Vector3.FORWARD)
		expect(("wrench_wall" if tool else "knife_wall") in heard,"striking enemy equipment has an audible impact")
		device.free()
	g.players[1].role=3;g.players[1].melee_hits={};g.devices[did].team=0;g.devices[did].hp=40.;heard.clear()
	var repair_body=StaticBody3D.new();g.add_child(repair_body);repair_body.set_meta("device",did)
	MeleeCombat.contact(g,1,{"collider":repair_body,"position":Vector3.ZERO},Vector3.ZERO,Vector3.FORWARD)
	expect("wrench_repair" in heard and g.devices[did].hp==70.,"actual repair plays bright metallic strike and restores 30 per hit")
	repair_body.free();heard.clear()
	for key in ["knife_swing","wrench_swing","slide"]:
		expect(g.audio_bank.streams.has(key) and g.audio_bank.streams[key].get_length()>.1,"1.4.2 melee/slide sample present: "+key)
	expect(is_equal_approx(g.audio_bank.streams.knife_swing.get_length(),g.audio_bank.streams.wrench_swing.get_length()),"knife and wrench swings last equally long (same attack speed)")
	for tool in [false,true]:
		heard.clear();g.effect("melee_swing",Vector3.ZERO,Vector3.ZERO,1,g.clock-10.,{"wrench":tool})
		expect(heard==[("wrench_swing" if tool else "knife_swing")],"swing plays the held tool's own whoosh")
	heard.clear();g.players[1].melee_started=-100.
	g.effect("melee_flesh",Vector3.ZERO,Vector3.ZERO,2);g.effect("melee_wall",Vector3.ZERO,Vector3.ZERO,2)
	expect(heard.is_empty(),"other players' contact impacts remain private")
	g.players[1].role=3;g.players[1].skill_ready=0.;g.actors[1].position=Vector3(20,0,20);g.actors[1].reset_view(0.);g.players[1].placing="turret"
	await physics_frame;await physics_frame
	heard.clear();expect(Deployment.confirm(g,1) and "engineer_deploy" in heard,"confirmed placement plays deployment audio") # (1.5.4: its own machine start-up sound)
	await create_timer(.2).timeout
	var samples=capture.get_buffer(capture.get_frames_available());var peak=0.
	for sample in samples:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	expect(peak>.001,"audio mixer produces non-silent PCM for combat feedback")
	g.audio_bank.play("hurt",Vector3.ZERO,false)
	var reserved=g.audio_bank.feedback_voices.filter(func(v):return v.playing)
	for i in range(40):g.audio_bank.play("gun_a1",Vector3.ZERO,false)
	expect(not reserved.is_empty() and reserved[0].playing,"gunfire cannot steal reserved feedback voices")

	g.audio_bank.stop_all();heard.clear()
	g.audio_bank.play("step_stone_0",Vector3(0,0,-2),true)
	g.audio_bank.play("explosion",Vector3(0,0,-3),true)
	var steps=g.audio_bank.movement_voices.filter(func(v):return v.playing)
	var blasts=g.audio_bank.blast_voices.filter(func(v):return v.playing)
	for i in range(70):g.audio_bank.play("gun_a1",Vector3(0,0,-4),true)
	expect(not steps.is_empty() and steps[0].playing and not blasts.is_empty() and blasts[0].playing,"gunfire cannot steal footsteps or explosion audio")
	heard.clear();g.players[1].role=1;g.players[1].armor=0.;g.damage(1,1.,2)
	expect("hurt_female" in heard,"female operator receives vocal hurt cue")
	heard.clear();g.players[1].role=3;g.players[1].primary="e1";g.players[1].slot=0;g.players[1].mag.e1=3;g.players[1].reserve.e1=20;g.players[1].reload=0.
	g.begin_reload(1);var began=g.clock
	for i in range(1,101):g.clock=began+Catalog.get_weapon("e1").reload*i/100.;ReloadAudio.tick(g,1)
	expect(heard.count("shell_insert")==1 and heard.count("pump")==0 and heard.count("bolt")==0 and not "magazine" in heard,"one shell insert per loading cycle, no pump mid-loading")
	heard.clear();g.players[1].mag.e1=4;MagazineReload.finish(g,1)
	expect(heard.count("pump")==1,"the tube full, the pump sounds once (1.5.1: its own pump sound)")
	g.players[1].reload=0.;g.players[1].placing="";g.players[1].protect=0.;g.players[1].invulnerable=0.;g.players[1].alive=true
	g.players[2].alive=false;g.players[2].respawn=1e9
	var a=g.actors[1];a.position=Vector3(0,.02,0);a.velocity=Vector3.ZERO;a.input_state.crouch=false;a.input_state.z=-1.;a.input_state.sprint=false
	heard.clear()
	for i in range(100):g.clock+=1./60.;g.players[1].input_time=g.clock;g.server_tick(1./60.);await physics_frame
	expect(heard.any(func(k):return k.begins_with("step_")),"walking produces audible footstep events")
	heard.clear();a.input_state.crouch=true
	for i in range(100):g.clock+=1./60.;g.players[1].input_time=g.clock;g.server_tick(1./60.);await physics_frame
	expect(not heard.any(func(k):return k.begins_with("step_")),"crouch walking remains silent")
	heard.clear();a.input_state.crouch=false;g.players[1].slide_ready=0.
	for i in range(30):g.clock+=1./60.;g.players[1].input_time=g.clock;g.server_tick(1./60.);await physics_frame
	# The lone enemy is dead, so the round has ended; slides need live combat.
	heard.clear();g.phase="combat";var slid=g.begin_slide(1,true)
	expect(slid and "slide" in heard,"sliding plays the slide scrape")
	heard.clear()
	for i in range(int(Rules.SLIDE_DURATION*60.)-2):g.clock+=1./60.;g.players[1].input_time=g.clock;g.server_tick(1./60.);await physics_frame
	expect(not heard.any(func(k):return k.begins_with("step_")),"no footsteps are layered over the slide")
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	g.leave_game()
	for i in range(4):await process_frame
	g.queue_free();await process_frame
	HeroCharacter.scenes.clear();HeroCharacter.libraries.clear();GunModel.bases.clear()
	SurfaceFinish.clear_cache();ToonMaterials.clear_cache()
	# Allow deferred audio/render deletion to drain before shutting down the driver.
	await create_timer(.5).timeout
	print("AUDIO_FEEDBACK_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
