extends SceneTree
# 1.4.9 (the user: in practice, throwing again and again at the entrance - where
# the gear refills - a throwable sometimes stays in the hand and kills the
# player). Clicks with varied timing (taps, holds, double clicks) through the
# server's own command and trigger paths; reports any grenade that goes off in
# the hand or any damage to the thrower.
var g:Node
func _initialize():call_deferred("run")
func run():
	g=load("res://scripts/game.gd").new();root.add_child(g)
	for i in range(10):await process_frame
	g.set_physics_process(false);g.ui.clear_panel()
	PracticeSession.start(g)
	for i in range(10):await process_frame
	var p=g.players[1];var a=g.actors[1]
	p.role=0;p.gadget=1 # frag (assault)
	print("PRACTICE_THROW equipped ",GrenadeLogic.equipped(p)," count ",p.gadget_count," label ",GadgetLoadout.label(p))
	var rng=RandomNumberGenerator.new();rng.seed=7
	var dt=1./60.;var held_bombs=0;var hurt=0;var thrown=0;var begun=0
	var step=func(n:int):
		for k in range(n):
			p.input_time=g.clock;a.position=PracticeSession.spawn_point(1)+Vector3(0,0,-1.)
			var hp=float(p.hp)
			var before={}
			for item in g.grenades:before[item.id]=item.held
			var held_ids=g.grenades.filter(func(it):return it.held).map(func(it):return it.id)
			g.clock+=dt;g.server_tick(dt)
			var now_held=g.grenades.filter(func(it):return it.held).map(func(it):return it.id)
			for id in now_held:
				if not id in held_ids:print("    became held ",id," at ",snappedf(g.clock,.01)," cooking ",p.get("cooking",0))
			if float(p.hp)<hp-.5:hurt+=1;print("  HURT at ",snappedf(g.clock,.01)," hp ",p.hp)
			for id in before:
				var still=false
				for item in g.grenades:if item.id==id:still=true
				if not still and before[id]:held_bombs+=1;print("  WENT OFF IN HAND id ",id," at ",snappedf(g.clock,.01))
	p.slot=2
	for cycle in range(120):
		var kind=rng.randi_range(0,3)
		g.trigger_seq+=1;a.input_state.trigger_seq=g.trigger_seq;a.input_state.fire=true
		var cooking_before=int(p.get("cooking",0))
		g.command("trigger_press",{"seq":g.trigger_seq});p.press_cook=int(p.get("cooking",0))
		if int(p.get("cooking",0))!=0 and cooking_before==0:begun+=1
		var hold=[0,1,rng.randi_range(4,40),rng.randi_range(40,90)][kind]
		step.call(hold)
		a.input_state.fire=false;g.command("trigger_release",{"seq":g.trigger_seq})
		if float(p.get("throw_until",-100.))>g.clock:thrown+=1
		print("    grenades ",g.grenades.map(func(it):return [it.id,it.held,snappedf(float(it.until),.01)]))
		print("  cycle %d kind %d hold %d clock %.2f cooking_before %d after_press %d input %s ready %.2f now cooking %d count %d"%[cycle,kind,hold,g.clock,cooking_before,int(p.get("press_cook",0)),str(p.get("cook_input","")),float(p.gadget_ready),int(p.get("cooking",0)),int(p.gadget_count)])
		step.call(rng.randi_range(2,45))
		if not p.alive:print("  DIED cycle ",cycle);break
	step.call(200)
	print("PRACTICE_THROW begun %d thrown %d off_in_hand %d hurt %d"%[begun,thrown,held_bombs,hurt])
	quit()
