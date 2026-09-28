extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	var g=load("res://scripts/game.gd").new();root.add_child(g);g.set_physics_process(false);g.ui.clear_panel()
	g.server=true;g.local_id=1;g.phase="lobby"
	g.arena=Arena.new();g.add_child(g.arena);g.arena.has_water=false
	g.add_player(1,"Tester","test");g.phase="combat";g.clock=100.
	var p=g.players[1];p.protect=0.;p.alive=true
	for rule in [1,2]:
		g.options.weapon_rule=rule;g.options.skills=true;g.options.classes=false;Rules.sanitize_room(g.options)
		expect(not g.options.skills and g.options.classes,"limited weapons retain gadgets and disable skills")
		expect(ModeOptions.network(g.options).weapon_rule==rule,"network options carry restriction")
		p.role=3;p.secondary="repair";p.slot=0;g.equip_ammo(p)
		expect(p.slot==(4 if rule==1 else 1) and p.secondary=="pistol","spawn/loadout obey rule")
		expect(not MeleeCombat.wrench(p) if rule==1 else not MeleeCombat.ready(g,p),"knife-only engineer uses knife; pistol mode blocks quick melee")
		for slot in [0,1,2,4]:
			g.clock+=1.;var previous=p.slot;g.handle_command(1,"slot",{"slot":slot})
			if not WeaponRules.allows_slot(g.options,slot):expect(p.slot==previous,"server rejects forbidden slot")
		p.primary="a1";p.mag[p.primary]=30;p.slot=0;p.fire_ready=0.;p.reload=0.;var ammo=p.mag[p.primary];g.fire(1)
		expect(p.mag[p.primary]==ammo,"direct forbidden fire consumes no ammunition")
		p.skill_ready=0.;g.use_skill(1);expect(p.skill_ready==0.,"restricted skill remains unused")
	g.leave_game();g.free();await process_frame
	print("ROOM_WEAPONS_V13_RESULT ",checks-failures,"/",checks);quit(1 if failures else 0)
