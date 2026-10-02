extends SceneTree
# 1.4.6 (the user): fall damage - none from about 3 m (one storey), 60 from
# 6 m, death from 9 m; it always comes off health (armour stays untouched),
# the heavy's guard does not reduce it, the medic's invulnerability ignores it.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func drop(g,a,height:float) -> float:
	var p=g.players[-1]
	p.alive=true;p.hp=100.;g.actors[-1].collision_layer=1
	a.position=Vector3(0,height+.02,0);a.velocity=Vector3.ZERO;a.input_state.z=0.;a.input_state.jump=false
	a.fall_peak=a.position.y;a.falling=false
	await physics_frame
	for i in range(240):
		g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
		if a.is_on_floor() and i>5:break
	for i in range(3):
		g.clock+=1./60.;a.simulate(1./60.,g.clock,true);await physics_frame
	return 100.-float(p.hp) if p.alive else 1000.
func run():
	expect(Actor.fall_damage(3.)==0. and Actor.fall_damage(3.2)==0.,"no damage from one storey (3 m)")
	expect(absf(Actor.fall_damage(6.)-60.)<.01,"60 damage from 6 m")
	expect(Actor.fall_damage(9.)>=1000.,"death from 9 m")
	expect(Actor.fall_damage(4.5)>0. and Actor.fall_damage(4.5)<60.,"in between it grows with the height")
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.dedicated=true;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.bounds=Vector2(100,100);g.arena.has_water=false
	g.arena.box(Vector3(0,-.5,0),Vector3(40,1,40),Color.GRAY)
	g.add_player(-1,"Faller","faller");g.phase="combat";g.clock=100.;var a=g.actors[-1];var p=g.players[-1]
	p.protect=0.;p.invulnerable=0.;p.shield=0.
	expect(await drop(g,a,3.)==0.,"a 3 m drop costs nothing")
	var lost=await drop(g,a,6.)
	expect(absf(lost-60.)<4.,"a 6 m drop costs about 60 (lost %.1f)"%lost)
	expect(await drop(g,a,9.2)>=1000.,"a 9 m drop kills")
	# armour is never worn by a fall: health only
	p.armor=50.;p.plate=30.
	lost=await drop(g,a,6.)
	expect(absf(lost-60.)<4. and p.armor==50. and float(p.plate)==30.,"armour does not absorb a fall (lost %.1f, armour %s)"%[lost,str(p.armor)])
	# the heavy's guard does not reduce falls
	p.role=2;p.shield=g.clock+60.
	lost=await drop(g,a,6.)
	expect(absf(lost-60.)<4.,"the heavy's guard takes nothing off a fall (lost %.1f)"%lost)
	expect(await drop(g,a,9.2)>=1000.,"the heavy's guard does not save a 9 m fall")
	p.shield=0.
	# the medic's invulnerability ignores falls - even from 9 m
	p.role=5;p.invulnerable=g.clock+60.
	lost=await drop(g,a,9.2)
	expect(lost==0. and p.alive,"invulnerability ignores a 9 m fall")
	p.invulnerable=0.
	# 1.4.6 (the user: a throwable sometimes stayed in the hand): two quick clicks -
	# each release counts (no rate limit on releases), and a click-started throw is
	# also released when the trigger is seen up after being held.
	p.role=0;p.alive=true;p.hp=100.;g.options.classes=true;p.gadget=1;p.gadget_count=3;p.slot=2;p.gadget_ready=0.;p.cooking=0;p.protect=0.
	expect(GrenadeLogic.equipped(p),"the frag is equipped for the throw checks")
	g.handle_command(-1,"trigger_press",{"seq":1});expect(int(p.cooking)>0,"a click pulls the pin")
	g.handle_command(-1,"trigger_release",{"seq":1});expect(int(p.cooking)==0,"releasing throws it")
	g.clock+=.55;p.gadget_ready=0.
	g.handle_command(-1,"trigger_press",{"seq":2});expect(int(p.cooking)>0,"a second click pulls the next pin")
	g.handle_command(-1,"trigger_release",{"seq":2});expect(int(p.cooking)==0,"a release right after another one still throws")
	g.clock+=.55;p.gadget_ready=0.
	g.handle_command(-1,"trigger_press",{"seq":3})
	a.input_state.fire=true;a.input_state.trigger_seq=3;g.process_trigger(-1)
	a.input_state.fire=false;g.process_trigger(-1)
	expect(int(p.cooking)==0,"trigger seen up after being held throws even without the release command")
	g.queue_free();await process_frame
	print("V146_FALL checks=%d failures=%d"%[checks,failures])
	if failures==0:print("V146_FALL_PASS")
	quit(1 if failures>0 else 0)
