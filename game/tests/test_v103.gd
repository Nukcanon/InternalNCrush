extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run():
	Catalog.load_all()
	var signatures={}
	for id in Catalog.weapons:
		var w=Catalog.get_weapon(id)
		if w.kind!="gun":continue
		expect(CombatBalance.firing_dps(w)>CombatBalance.sustained_dps(w) and CombatBalance.sustained_dps(w)>0.,id+" reload reduces sustained DPS")
		var a=AimModel.spread(w,0.,false,false,false,true,0.);var b=AimModel.spread(w,3.7,false,false,false,true,0.);var c=AimModel.spread(w,7.4,false,false,false,true,0.)
		expect(is_equal_approx(b-a,(c-a)*.5),id+" speed-proportional spread")
		var spray=AimModel.spray_offset(w,ceili(w.spray_build_seconds/w.interval));signatures[str(spray)]=true
		var p={"bloom":float(w.shot_bloom)*3.,"spray_phase":3.,"shot_time":0.};var original=p.bloom
		for tick in range(60):AimModel.recover(p,w,1./120.,tick/120.)
		expect(p.bloom<original and p.spray_phase<3.,id+" short-burst accuracy recovers during a pause")
	expect(signatures.size()>18,"distinct weapon recoil curves")
	var burst=Catalog.get_weapon("a4");expect(absf(CombatBalance.magazine_seconds(burst)-((int(burst.mag)-1)/3*(burst.interval*2.+burst.burst_pause)+((int(burst.mag)-1)%3)*burst.interval))<.001,"burst DPS accounts for gaps between bursts")
	expect(AbilityBalance.flash_duration(3.,1.)>AbilityBalance.flash_duration(3.,-1.) and AbilityBalance.flash_duration(18.1,1.)==0.,"flash respects facing and maximum distance")
	expect(AbilityBalance.turret_dps(4)<=38.01 and AbilityBalance.turret_hp(4)==300.,"upgraded turret bounded at 38 bullet DPS / 300 HP")
	var image=Image.load_from_file("res://assets/textures/smoke_particle_v103.png")
	expect(image.detect_alpha()!=Image.ALPHA_NONE and image.get_pixel(0,0).a<.05,"explosion texture has a transparent edge")
	var skin=CharacterVisual.new();root.add_child(skin);skin.enable_physics=false;skin.build(0,0)
	expect(skin.deform.get_bone_count()==15 and skin.rig.get_node("ContinuousBody").skin.get_bind_count()==15,"rendered character has weighted GPU skin")
	expect(skin.rig.get_node("ContinuousBody").mesh.get_surface_count()==1,"continuous shoulder and torso surface is baked into the skin")
	skin.free()
	for index in range(19):
		var arena=Arena.new();root.add_child(arena);arena.build(index)
		print("DOOR_AUDIT ",index," doors=",arena.doors.size())
		expect(arena.doors.values().all(func(door):return door.leaves.size()==2),"map "+str(index)+" retained doors have complete paired leaves")
		arena.free();await process_frame
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel();g.server=true;g.local_id=1;g.options.map_random=false;g.options.map=0;g.build_world();g.phase="lobby";g.add_player(1,"TEST","v103");g.phase="combat";g.clock=100.
	var door=g.arena.doors.values()[0];var actor=g.actors[1];var p=g.players[1];p.protect=0.;p.armor=0.
	actor.position=door.global_position+door.basis*Vector3(0,.05,-2.5);actor.reset_view(door.rotation.y+PI)
	await physics_frame;await physics_frame
	expect(InteractiveDoor.target(g,1)==door,"E target is the nearby visible door")
	var from=door.global_position+door.basis*Vector3(0,1.,-2.);var to=door.global_position+door.basis*Vector3(0,1.,2.)
	expect(not g.ray(from,to,[],1).is_empty(),"closed door blocks shots")
	p.use_prev=false;g.interact(1,.016);p.use_prev=true;g.interact(1,.016)
	expect(door.opened,"held E cannot toggle a door twice")
	for frame in range(60):await physics_frame
	expect(g.ray(from,to,[],1).is_empty(),"open door leaves a clear physical passage")
	actor.position=door.global_position;expect(not door.toggle(g.actors) and door.opened,"door does not close through an actor")
	var states=g.arena.door_states();door.opened=false;g.arena.receive_doors(states);expect(door.opened,"door snapshot restores open state for joining clients")
	g.arena.reset_props();expect(not door.opened and door.progress==0.,"new round resets doors")
	p.use_prev=true;g.spawn(1);expect(not p.use_prev,"respawn resets interaction edge")
	var blood=BloodFX.new();g.add_child(blood);var point=Vector3(0,1.,g.arena.bounds.y-7.)
	blood.emit_hit(point,Vector3.DOWN,30.);expect(blood.drops.size()>=5 and blood.marks.size()>0,"hit emits droplets and a projected floor stain")
	for i in range(70):blood.stain(point,Vector3.UP,.15)
	expect(blood.marks.size()==BloodFX.MAX_MARKS,"blood marks have a fixed performance budget")
	var graph=StatGraph.new();root.add_child(graph);graph.configure(1,Catalog.get_weapon("a1"),0,0)
	expect(graph.rows.any(func(row):return row[0]=="DPS / 지속"),"equipment card displays DPS and reload-adjusted DPS")
	graph.free();g.leave_game();g.free();await process_frame
	print("V103_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
